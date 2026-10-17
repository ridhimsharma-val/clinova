-- ==============================================================================
-- CLINOVA HEALTHCARE PLATFORM — SUPABASE POSTGRESQL DATABASE SETUP
-- ==============================================================================
-- Architecture: 9 Relational Tables with Role-Based Access Control (RBAC),
--               Row-Level Security (RLS), and Clinical Safety Automation.
-- Engine: PostgreSQL 15+ (Compatible with Supabase Managed Database)
-- Documentation: See CLINOVA_DATABASE_DESIGN.md for detailed field analysis.
-- ==============================================================================

-- 1. EXTENSIONS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ==============================================================================
-- 2. HELPER FUNCTIONS & TRIGGERS
-- ==============================================================================

-- Maintain updated_at timestamp automatically
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Helper to retrieve current user's role securely (prevents recursive RLS evaluation)
CREATE OR REPLACE FUNCTION public.get_user_role(user_id UUID)
RETURNS TEXT AS $$
DECLARE
    user_role TEXT;
BEGIN
    SELECT role INTO user_role FROM public.profiles WHERE id = user_id;
    RETURN COALESCE(user_role, 'patient');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Check if current user is an authenticated doctor
CREATE OR REPLACE FUNCTION public.is_doctor(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN public.get_user_role(user_id) = 'doctor';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- Check if doctor has verified license credentials
CREATE OR REPLACE FUNCTION public.is_verified_doctor(user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    verified BOOLEAN;
BEGIN
    SELECT is_license_verified INTO verified
    FROM public.doctor_profiles
    WHERE doctor_id = user_id;
    RETURN COALESCE(verified, false);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER STABLE;

-- ==============================================================================
-- 3. CORE IDENTITY & USER PROFILES
-- ==============================================================================

-- TABLE 1: profiles (Base user account linked to Supabase Auth)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    role TEXT NOT NULL DEFAULT 'patient' CHECK (role IN ('patient', 'doctor')),
    email TEXT NOT NULL UNIQUE,
    full_name TEXT NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Trigger for profiles.updated_at
DROP TRIGGER IF EXISTS trg_profiles_updated_at ON public.profiles;
CREATE TRIGGER trg_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- TABLE 2: patient_profiles (Patient demographics and medical anamnesis)
CREATE TABLE IF NOT EXISTS public.patient_profiles (
    patient_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    date_of_birth DATE,
    gender TEXT,
    blood_group TEXT,
    mobile_number TEXT,
    home_address TEXT,
    height_cm TEXT,
    weight_kg TEXT,
    emergency_contact_name TEXT,
    emergency_contact_relationship TEXT,
    emergency_contact_phone TEXT,
    allergies TEXT,
    conditions TEXT,
    medications TEXT,
    past_medical_history TEXT,
    surgical_history TEXT,
    family_history TEXT,
    lifestyle TEXT,
    additional_notes TEXT,
    is_anamnesis_customized BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS trg_patient_profiles_updated_at ON public.patient_profiles;
CREATE TRIGGER trg_patient_profiles_updated_at
    BEFORE UPDATE ON public.patient_profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- TABLE 3: doctor_profiles (Physician credentials, license & practice facility)
CREATE TABLE IF NOT EXISTS public.doctor_profiles (
    doctor_id UUID PRIMARY KEY REFERENCES public.profiles(id) ON DELETE CASCADE,
    specialty TEXT NOT NULL,
    qualification TEXT NOT NULL DEFAULT 'MBBS, MD',
    years_of_experience TEXT DEFAULT '5',
    license_number TEXT NOT NULL,
    is_license_verified BOOLEAN NOT NULL DEFAULT FALSE,
    phone TEXT,
    hospital_name TEXT DEFAULT 'Clinova Medical Partner Center',
    clinic_address TEXT,
    practice_status TEXT NOT NULL DEFAULT 'Active Practitioner',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS trg_doctor_profiles_updated_at ON public.doctor_profiles;
CREATE TRIGGER trg_doctor_profiles_updated_at
    BEFORE UPDATE ON public.doctor_profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ==============================================================================
-- 4. CASE MANAGEMENT & CLINICAL QUESTIONNAIRE
-- ==============================================================================

-- TABLE 4: cases (Case lifecycle routing and queue management)
CREATE TABLE IF NOT EXISTS public.cases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_reference TEXT UNIQUE NOT NULL,
    patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'awaiting_review' 
        CHECK (status IN ('draft', 'submitted', 'awaiting_review', 'in_review', 'reviewed', 'archived')),
    assigned_doctor_id UUID REFERENCES public.doctor_profiles(doctor_id) ON DELETE SET NULL,
    submitted_at TIMESTAMPTZ,
    reviewed_at TIMESTAMPTZ,
    archived_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_cases_patient_id ON public.cases(patient_id);
CREATE INDEX IF NOT EXISTS idx_cases_status ON public.cases(status);
CREATE INDEX IF NOT EXISTS idx_cases_assigned_doctor ON public.cases(assigned_doctor_id);
CREATE INDEX IF NOT EXISTS idx_cases_created_at ON public.cases(created_at DESC);

DROP TRIGGER IF EXISTS trg_cases_updated_at ON public.cases;
CREATE TRIGGER trg_cases_updated_at
    BEFORE UPDATE ON public.cases
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- TABLE 5: case_intake_responses (The 11-step questionnaire data)
CREATE TABLE IF NOT EXISTS public.case_intake_responses (
    case_id UUID PRIMARY KEY REFERENCES public.cases(id) ON DELETE CASCADE,
    current_step INT NOT NULL DEFAULT 11 CHECK (current_step BETWEEN 1 AND 11),
    is_draft BOOLEAN NOT NULL DEFAULT FALSE,
    chief_concern TEXT NOT NULL,
    duration TEXT NOT NULL,
    severity TEXT NOT NULL,
    associated_symptoms TEXT[] NOT NULL DEFAULT '{}',
    other_associated_symptom TEXT,
    symptom_details TEXT,
    previous_occurrences TEXT,
    previous_occurrence_details TEXT,
    existing_conditions TEXT[] NOT NULL DEFAULT '{}',
    other_condition_details TEXT,
    allergies TEXT[] NOT NULL DEFAULT '{}',
    allergy_details TEXT,
    takes_medications TEXT,
    medication_details TEXT,
    medical_family_history TEXT,
    raw_responses JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

DROP TRIGGER IF EXISTS trg_intake_updated_at ON public.case_intake_responses;
CREATE TRIGGER trg_intake_updated_at
    BEFORE UPDATE ON public.case_intake_responses
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- ==============================================================================
-- 5. AI DECISION SUPPORT & CLINICAL SUPERVISION
-- ==============================================================================

-- TABLE 6: ai_case_summaries (Structured n8n-generated physician briefings)
CREATE TABLE IF NOT EXISTS public.ai_case_summaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID UNIQUE NOT NULL REFERENCES public.cases(id) ON DELETE CASCADE,
    generation_status TEXT NOT NULL DEFAULT 'pending'
        CHECK (generation_status IN ('pending', 'generating', 'ready', 'failed')),
    summary_text TEXT DEFAULT '',
    chief_complaint TEXT DEFAULT '',
    symptom_timeline_and_severity TEXT DEFAULT '',
    relevant_positive_findings TEXT[] NOT NULL DEFAULT '{}',
    relevant_negative_findings TEXT[] NOT NULL DEFAULT '{}',
    medical_history_and_medications TEXT DEFAULT '',
    missing_or_unclear_information TEXT[] NOT NULL DEFAULT '{}',
    error_message TEXT,
    disclaimer TEXT NOT NULL DEFAULT 'AI-generated summary — requires physician review. Not a diagnosis or prescription.',
    last_requested_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    generated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ai_summaries_case_id ON public.ai_case_summaries(case_id);

DROP TRIGGER IF EXISTS trg_ai_summaries_updated_at ON public.ai_case_summaries;
CREATE TRIGGER trg_ai_summaries_updated_at
    BEFORE UPDATE ON public.ai_case_summaries
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- TABLE 7: doctor_assessments (Physician clinical evaluations & private draft notes)
CREATE TABLE IF NOT EXISTS public.doctor_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID UNIQUE NOT NULL REFERENCES public.cases(id) ON DELETE CASCADE,
    doctor_id UUID NOT NULL REFERENCES public.profiles(id),
    clinical_assessment TEXT DEFAULT '',
    observations TEXT DEFAULT '',
    advice_and_recommendations TEXT DEFAULT '',
    follow_up_instructions TEXT DEFAULT '',
    follow_up_date DATE,
    is_finalized BOOLEAN NOT NULL DEFAULT FALSE,
    finalized_at TIMESTAMPTZ,
    last_saved_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_doctor_assessments_case_id ON public.doctor_assessments(case_id);
CREATE INDEX IF NOT EXISTS idx_doctor_assessments_doctor_id ON public.doctor_assessments(doctor_id);

DROP TRIGGER IF EXISTS trg_doctor_assessments_updated_at ON public.doctor_assessments;
CREATE TRIGGER trg_doctor_assessments_updated_at
    BEFORE UPDATE ON public.doctor_assessments
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- TABLE 8: patient_care_notes (Finalized consultation notes visible to patient)
CREATE TABLE IF NOT EXISTS public.patient_care_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID NOT NULL REFERENCES public.cases(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    doctor_id UUID NOT NULL REFERENCES public.profiles(id),
    author_name TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'Clinical Consultation',
    note_text TEXT NOT NULL,
    published_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_patient_care_notes_patient_id ON public.patient_care_notes(patient_id);
CREATE INDEX IF NOT EXISTS idx_patient_care_notes_case_id ON public.patient_care_notes(case_id);

-- TABLE 9: notifications (In-app alerts for status changes & reviews)
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    case_id UUID REFERENCES public.cases(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    category TEXT NOT NULL CHECK (category IN ('SYSTEM', 'CASE', 'DOCTOR')),
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_read ON public.notifications(user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);

-- ==============================================================================
-- 6. AUTOMATED CLINICAL WORKFLOW TRIGGERS
-- ==============================================================================

-- Automatically publish to patient_care_notes and notify patient when doctor finalizes review
CREATE OR REPLACE FUNCTION public.handle_assessment_finalization()
RETURNS TRIGGER AS $$
DECLARE
    case_record RECORD;
    doctor_record RECORD;
    combined_notes TEXT;
BEGIN
    -- Only trigger when transitioning from unfinalized to finalized
    IF NEW.is_finalized = TRUE AND (OLD.is_finalized IS NULL OR OLD.is_finalized = FALSE) THEN
        -- 1. Lookup case & patient details
        SELECT * INTO case_record FROM public.cases WHERE id = NEW.case_id;
        SELECT * INTO doctor_record FROM public.profiles WHERE id = NEW.doctor_id;

        -- 2. Format composite patient-facing note
        combined_notes := '';
        IF NEW.clinical_assessment IS NOT NULL AND trim(NEW.clinical_assessment) <> '' THEN
            combined_notes := combined_notes || E'Clinical Assessment:\n' || trim(NEW.clinical_assessment) || E'\n\n';
        END IF;
        IF NEW.observations IS NOT NULL AND trim(NEW.observations) <> '' THEN
            combined_notes := combined_notes || E'Doctor''s Observations:\n' || trim(NEW.observations) || E'\n\n';
        END IF;
        IF NEW.advice_and_recommendations IS NOT NULL AND trim(NEW.advice_and_recommendations) <> '' THEN
            combined_notes := combined_notes || E'Advice & Recommendations:\n' || trim(NEW.advice_and_recommendations) || E'\n\n';
        END IF;
        IF NEW.follow_up_instructions IS NOT NULL AND trim(NEW.follow_up_instructions) <> '' THEN
            combined_notes := combined_notes || E'Follow-up Instructions:\n' || trim(NEW.follow_up_instructions);
        END IF;

        -- 3. Insert into patient_care_notes
        INSERT INTO public.patient_care_notes (
            case_id,
            patient_id,
            doctor_id,
            author_name,
            category,
            note_text,
            published_at
        ) VALUES (
            NEW.case_id,
            case_record.patient_id,
            NEW.doctor_id,
            COALESCE(doctor_record.full_name, 'Attending Physician'),
            COALESCE(case_record.title, 'Clinical Consultation'),
            trim(combined_notes),
            now()
        );

        -- 4. Update parent case status
        UPDATE public.cases
        SET status = 'reviewed',
            reviewed_at = now(),
            assigned_doctor_id = NEW.doctor_id
        WHERE id = NEW.case_id;

        -- 5. Send notification to patient
        INSERT INTO public.notifications (
            user_id,
            case_id,
            title,
            message,
            category,
            is_read
        ) VALUES (
            case_record.patient_id,
            NEW.case_id,
            'Doctor Review Completed',
            'Dr. ' || COALESCE(doctor_record.full_name, 'Physician') || ' has finalized the clinical review for your consultation.',
            'DOCTOR',
            FALSE
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_assessment_finalized ON public.doctor_assessments;
CREATE TRIGGER trg_assessment_finalized
    AFTER UPDATE OR INSERT ON public.doctor_assessments
    FOR EACH ROW EXECUTE FUNCTION public.handle_assessment_finalization();

-- Automatically provision profile records on auth.users registration
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
    raw_role TEXT;
    raw_name TEXT;
BEGIN
    raw_role := COALESCE(NEW.raw_user_meta_data->>'role', 'patient');
    raw_name := COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.email);

    -- Security Guard: Disallow public registration from automatically gaining verified doctor status
    IF raw_role = 'doctor' THEN
        INSERT INTO public.profiles (id, email, full_name, role)
        VALUES (NEW.id, NEW.email, raw_name, 'doctor');

        INSERT INTO public.doctor_profiles (
            doctor_id,
            specialty,
            qualification,
            license_number,
            is_license_verified
        ) VALUES (
            NEW.id,
            COALESCE(NEW.raw_user_meta_data->>'specialty', 'General Practice'),
            COALESCE(NEW.raw_user_meta_data->>'qualification', 'Medical Practitioner'),
            COALESCE(NEW.raw_user_meta_data->>'license_number', 'PENDING-VERIFICATION'),
            FALSE -- Must be verified through trusted administrative review
        );
    ELSE
        INSERT INTO public.profiles (id, email, full_name, role)
        VALUES (NEW.id, NEW.email, raw_name, 'patient');

        INSERT INTO public.patient_profiles (patient_id)
        VALUES (NEW.id);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Connect trigger to Supabase auth.users table
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Prevent unauthorized doctors from verifying their own medical licenses
CREATE OR REPLACE FUNCTION public.prevent_self_license_verification()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_license_verified <> OLD.is_license_verified AND auth.role() <> 'service_role' THEN
        RAISE EXCEPTION 'Medical license verification can only be performed by an authorized system administrator.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_guard_license_verification ON public.doctor_profiles;
CREATE TRIGGER trg_guard_license_verification
    BEFORE UPDATE ON public.doctor_profiles
    FOR EACH ROW EXECUTE FUNCTION public.prevent_self_license_verification();

-- ==============================================================================
-- 7. ROW-LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

-- Enable RLS across all 9 tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctor_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cases ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.case_intake_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ai_case_summaries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.doctor_assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.patient_care_notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- ------------------------------------------------------------------------------
-- RLS: profiles
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "profiles_self_select" ON public.profiles;
CREATE POLICY "profiles_self_select" ON public.profiles
    FOR SELECT TO authenticated
    USING (id = auth.uid() OR public.is_doctor(auth.uid()));

DROP POLICY IF EXISTS "profiles_self_update" ON public.profiles;
CREATE POLICY "profiles_self_update" ON public.profiles
    FOR UPDATE TO authenticated
    USING (id = auth.uid())
    WITH CHECK (id = auth.uid() AND role = (SELECT role FROM public.profiles WHERE id = auth.uid()));

-- ------------------------------------------------------------------------------
-- RLS: patient_profiles
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "patient_profiles_self_access" ON public.patient_profiles;
CREATE POLICY "patient_profiles_self_access" ON public.patient_profiles
    FOR ALL TO authenticated
    USING (patient_id = auth.uid())
    WITH CHECK (patient_id = auth.uid());

DROP POLICY IF EXISTS "patient_profiles_doctor_read" ON public.patient_profiles;
CREATE POLICY "patient_profiles_doctor_read" ON public.patient_profiles
    FOR SELECT TO authenticated
    USING (public.is_doctor(auth.uid()));

-- ------------------------------------------------------------------------------
-- RLS: doctor_profiles
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "doctor_profiles_public_read" ON public.doctor_profiles;
CREATE POLICY "doctor_profiles_public_read" ON public.doctor_profiles
    FOR SELECT TO authenticated
    USING (true);

DROP POLICY IF EXISTS "doctor_profiles_self_update" ON public.doctor_profiles;
CREATE POLICY "doctor_profiles_self_update" ON public.doctor_profiles
    FOR UPDATE TO authenticated
    USING (doctor_id = auth.uid())
    WITH CHECK (doctor_id = auth.uid());

-- ------------------------------------------------------------------------------
-- RLS: cases
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "cases_patient_select" ON public.cases;
CREATE POLICY "cases_patient_select" ON public.cases
    FOR SELECT TO authenticated
    USING (patient_id = auth.uid());

DROP POLICY IF EXISTS "cases_patient_insert" ON public.cases;
CREATE POLICY "cases_patient_insert" ON public.cases
    FOR INSERT TO authenticated
    WITH CHECK (patient_id = auth.uid());

DROP POLICY IF EXISTS "cases_patient_update" ON public.cases;
CREATE POLICY "cases_patient_update" ON public.cases
    FOR UPDATE TO authenticated
    USING (patient_id = auth.uid() AND status IN ('draft', 'submitted'))
    WITH CHECK (patient_id = auth.uid());

DROP POLICY IF EXISTS "cases_doctor_select" ON public.cases;
CREATE POLICY "cases_doctor_select" ON public.cases
    FOR SELECT TO authenticated
    USING (public.is_doctor(auth.uid()));

DROP POLICY IF EXISTS "cases_doctor_update" ON public.cases;
CREATE POLICY "cases_doctor_update" ON public.cases
    FOR UPDATE TO authenticated
    USING (public.is_doctor(auth.uid()))
    WITH CHECK (public.is_doctor(auth.uid()));

-- ------------------------------------------------------------------------------
-- RLS: case_intake_responses
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "intake_patient_all" ON public.case_intake_responses;
CREATE POLICY "intake_patient_all" ON public.case_intake_responses
    FOR ALL TO authenticated
    USING (EXISTS (SELECT 1 FROM public.cases c WHERE c.id = case_id AND c.patient_id = auth.uid()))
    WITH CHECK (EXISTS (SELECT 1 FROM public.cases c WHERE c.id = case_id AND c.patient_id = auth.uid()));

DROP POLICY IF EXISTS "intake_doctor_select" ON public.case_intake_responses;
CREATE POLICY "intake_doctor_select" ON public.case_intake_responses
    FOR SELECT TO authenticated
    USING (public.is_doctor(auth.uid()));

-- ------------------------------------------------------------------------------
-- RLS: ai_case_summaries
-- ------------------------------------------------------------------------------
-- CRITICAL HEALTHCARE PRIVACY: AI summaries are STRICTLY physician decision support
DROP POLICY IF EXISTS "ai_summary_doctor_select" ON public.ai_case_summaries;
CREATE POLICY "ai_summary_doctor_select" ON public.ai_case_summaries
    FOR SELECT TO authenticated
    USING (public.is_doctor(auth.uid()));

DROP POLICY IF EXISTS "ai_summary_doctor_modify" ON public.ai_case_summaries;
CREATE POLICY "ai_summary_doctor_modify" ON public.ai_case_summaries
    FOR ALL TO authenticated
    USING (public.is_doctor(auth.uid()))
    WITH CHECK (public.is_doctor(auth.uid()));

DROP POLICY IF EXISTS "ai_summary_service_role" ON public.ai_case_summaries;
CREATE POLICY "ai_summary_service_role" ON public.ai_case_summaries
    FOR ALL TO service_role
    USING (true)
    WITH CHECK (true);

-- ------------------------------------------------------------------------------
-- RLS: doctor_assessments
-- ------------------------------------------------------------------------------
-- CRITICAL HEALTHCARE PRIVACY: Private drafts must NEVER be accessible to patients
DROP POLICY IF EXISTS "doctor_assessment_access" ON public.doctor_assessments;
CREATE POLICY "doctor_assessment_access" ON public.doctor_assessments
    FOR ALL TO authenticated
    USING (public.is_doctor(auth.uid()))
    WITH CHECK (public.is_doctor(auth.uid()) AND doctor_id = auth.uid());

-- ------------------------------------------------------------------------------
-- RLS: patient_care_notes
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "care_notes_patient_select" ON public.patient_care_notes;
CREATE POLICY "care_notes_patient_select" ON public.patient_care_notes
    FOR SELECT TO authenticated
    USING (patient_id = auth.uid());

DROP POLICY IF EXISTS "care_notes_doctor_select" ON public.patient_care_notes;
CREATE POLICY "care_notes_doctor_select" ON public.patient_care_notes
    FOR SELECT TO authenticated
    USING (public.is_doctor(auth.uid()));

DROP POLICY IF EXISTS "care_notes_doctor_insert" ON public.patient_care_notes;
CREATE POLICY "care_notes_doctor_insert" ON public.patient_care_notes
    FOR INSERT TO authenticated
    WITH CHECK (public.is_doctor(auth.uid()));

-- ------------------------------------------------------------------------------
-- RLS: notifications
-- ------------------------------------------------------------------------------
DROP POLICY IF EXISTS "notifications_self_access" ON public.notifications;
CREATE POLICY "notifications_self_access" ON public.notifications
    FOR ALL TO authenticated
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());
