-- ==============================================================================
-- CLINOVA — MEDICAL DOCUMENT ATTACHMENTS MIGRATION
-- ==============================================================================
-- Additive migration for optional supporting medical documents (MRI, X-ray, lab
-- reports, prescriptions).
--
-- Features:
-- 1. Metadata table: public.case_attachments with dual column support
--    (case_id / patient_case_id, patient_id / patient_user_id)
-- 2. Constraints: Max 20 MB per file, permitted medical MIME types
-- 3. Row-Level Security (RLS) for patient case owners and authorized doctors
-- 4. Private Storage Bucket: case-medical-documents (20 MB limit, strict MIME types)
-- 5. Storage Access Policies on storage.objects
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 2. METADATA TABLE: public.case_attachments
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.case_attachments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Dual case reference columns to support both public.cases and public.patient_cases
    case_id UUID,
    patient_case_id UUID,

    -- Dual patient reference columns to support both patient_id and patient_user_id
    patient_id UUID,
    patient_user_id UUID,

    -- Identity of authenticated uploader
    uploaded_by UUID DEFAULT auth.uid(),

    -- Original filename shown to patient and clinician
    original_filename TEXT NOT NULL,

    -- Private storage path: patient_user_id/case_uuid/generated_filename
    storage_path TEXT NOT NULL,

    -- Validated MIME type
    mime_type TEXT NOT NULL,

    -- File size in bytes (strictly enforced up to 20 MB = 20971520 bytes)
    file_size_bytes BIGINT NOT NULL CHECK (file_size_bytes > 0 AND file_size_bytes <= 20971520),

    -- Timestamp
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Constraints
    CONSTRAINT chk_case_attachments_mime_type CHECK (
        mime_type IN (
            'application/pdf',
            'image/jpeg',
            'image/png',
            'image/webp',
            'image/heic',
            'image/heif'
        )
    )
);

-- Ensure all columns exist even if public.case_attachments was created previously without them
ALTER TABLE public.case_attachments ADD COLUMN IF NOT EXISTS case_id UUID;
ALTER TABLE public.case_attachments ADD COLUMN IF NOT EXISTS patient_case_id UUID;
ALTER TABLE public.case_attachments ADD COLUMN IF NOT EXISTS patient_id UUID;
ALTER TABLE public.case_attachments ADD COLUMN IF NOT EXISTS patient_user_id UUID;
ALTER TABLE public.case_attachments ADD COLUMN IF NOT EXISTS uploaded_by UUID DEFAULT auth.uid();
ALTER TABLE public.case_attachments ADD COLUMN IF NOT EXISTS original_filename TEXT;
ALTER TABLE public.case_attachments ADD COLUMN IF NOT EXISTS storage_path TEXT;
ALTER TABLE public.case_attachments ADD COLUMN IF NOT EXISTS mime_type TEXT;
ALTER TABLE public.case_attachments ADD COLUMN IF NOT EXISTS file_size_bytes BIGINT;
ALTER TABLE public.case_attachments ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ DEFAULT now();

-- Sync dual columns automatically via trigger if one is provided
CREATE OR REPLACE FUNCTION public.sync_case_attachment_columns()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.case_id IS NULL AND NEW.patient_case_id IS NOT NULL THEN
        NEW.case_id := NEW.patient_case_id;
    ELSIF NEW.patient_case_id IS NULL AND NEW.case_id IS NOT NULL THEN
        NEW.patient_case_id := NEW.case_id;
    END IF;

    IF NEW.patient_id IS NULL AND NEW.patient_user_id IS NOT NULL THEN
        NEW.patient_id := NEW.patient_user_id;
    ELSIF NEW.patient_user_id IS NULL AND NEW.patient_id IS NOT NULL THEN
        NEW.patient_user_id := NEW.patient_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_sync_case_attachment_columns ON public.case_attachments;
CREATE TRIGGER trg_sync_case_attachment_columns
BEFORE INSERT OR UPDATE ON public.case_attachments
FOR EACH ROW
EXECUTE FUNCTION public.sync_case_attachment_columns();

-- ==============================================================================
-- 3. INDEXES FOR HIGH-PERFORMANCE RETRIEVAL
-- ==============================================================================

CREATE INDEX IF NOT EXISTS idx_case_attachments_case_id 
    ON public.case_attachments(case_id);

CREATE INDEX IF NOT EXISTS idx_case_attachments_patient_case_id 
    ON public.case_attachments(patient_case_id);

CREATE INDEX IF NOT EXISTS idx_case_attachments_patient_id 
    ON public.case_attachments(patient_id);

CREATE INDEX IF NOT EXISTS idx_case_attachments_patient_user_id 
    ON public.case_attachments(patient_user_id);

CREATE INDEX IF NOT EXISTS idx_case_attachments_created_at 
    ON public.case_attachments(created_at DESC);

-- ==============================================================================
-- 4. ROW-LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

ALTER TABLE public.case_attachments ENABLE ROW LEVEL SECURITY;

-- Patients: Read own case attachments
DROP POLICY IF EXISTS "Patients can view own case attachments" ON public.case_attachments;
CREATE POLICY "Patients can view own case attachments"
ON public.case_attachments
FOR SELECT
USING (
    auth.uid() = patient_id 
    OR auth.uid() = patient_user_id 
    OR auth.uid() = uploaded_by
);

-- Patients: Insert attachments for own cases
DROP POLICY IF EXISTS "Patients can insert own case attachments" ON public.case_attachments;
CREATE POLICY "Patients can insert own case attachments"
ON public.case_attachments
FOR INSERT
WITH CHECK (
    auth.uid() = patient_id 
    OR auth.uid() = patient_user_id 
    OR auth.uid() = uploaded_by
);

-- Patients: Delete own case attachments before finalization
DROP POLICY IF EXISTS "Patients can delete own case attachments" ON public.case_attachments;
CREATE POLICY "Patients can delete own case attachments"
ON public.case_attachments
FOR DELETE
USING (
    auth.uid() = patient_id 
    OR auth.uid() = patient_user_id 
    OR auth.uid() = uploaded_by
);

-- Doctors: View attachments for clinical review
DROP POLICY IF EXISTS "Doctors can view case attachments" ON public.case_attachments;
CREATE POLICY "Doctors can view case attachments"
ON public.case_attachments
FOR SELECT
USING (
    EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() AND role = 'doctor'
    )
);

-- ==============================================================================
-- 5. SUPABASE STORAGE BUCKET: case-medical-documents
-- ==============================================================================

-- Create private storage bucket if not already present
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'case-medical-documents',
    'case-medical-documents',
    false,
    20971520, -- 20 MB in bytes
    ARRAY[
        'application/pdf',
        'image/jpeg',
        'image/png',
        'image/webp',
        'image/heic',
        'image/heif'
    ]::text[]
)
ON CONFLICT (id) DO UPDATE SET
    public = false,
    file_size_limit = 20971520,
    allowed_mime_types = ARRAY[
        'application/pdf',
        'image/jpeg',
        'image/png',
        'image/webp',
        'image/heic',
        'image/heif'
    ]::text[];

-- ==============================================================================
-- 6. STORAGE OBJECT ROW-LEVEL SECURITY POLICIES
-- ==============================================================================

-- Allow authenticated patients to upload attachments into their user folder
DROP POLICY IF EXISTS "Patients can upload medical documents" ON storage.objects;
CREATE POLICY "Patients can upload medical documents"
ON storage.objects
FOR INSERT
WITH CHECK (
    bucket_id = 'case-medical-documents'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow patients to view/download their own documents
DROP POLICY IF EXISTS "Patients can view own medical documents" ON storage.objects;
CREATE POLICY "Patients can view own medical documents"
ON storage.objects
FOR SELECT
USING (
    bucket_id = 'case-medical-documents'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
);

-- Allow authorized doctors to view/download medical documents
DROP POLICY IF EXISTS "Doctors can view medical documents" ON storage.objects;
CREATE POLICY "Doctors can view medical documents"
ON storage.objects
FOR SELECT
USING (
    bucket_id = 'case-medical-documents'
    AND auth.role() = 'authenticated'
    AND EXISTS (
        SELECT 1 FROM public.profiles 
        WHERE id = auth.uid() AND role = 'doctor'
    )
);

-- Allow patients to delete documents before final review
DROP POLICY IF EXISTS "Patients can delete own medical documents" ON storage.objects;
CREATE POLICY "Patients can delete own medical documents"
ON storage.objects
FOR DELETE
USING (
    bucket_id = 'case-medical-documents'
    AND auth.role() = 'authenticated'
    AND (storage.foldername(name))[1] = auth.uid()::text
);
