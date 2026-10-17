# CLINOVA — FRESH SUPABASE TABLES & n8n QUERY REFERENCE

**Target Engine**: Supabase (PostgreSQL 15+)  
**Workflow Engine**: n8n v1+ (LangChain AI Agent)  
**Client Application**: Clinova Flutter Client  

---

## 1. Fresh Supabase Tables Summary

All 9 tables are defined with constraints and RLS in [`clinova_supabase_setup.sql`](./clinova_supabase_setup.sql):

```sql
-- 1. Base User Identity
public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id),
    role TEXT CHECK (role IN ('patient', 'doctor')),
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    avatar_url TEXT,
    created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ
);

-- 2. Patient Demographics & Anamnesis
public.patient_profiles (
    patient_id UUID PRIMARY KEY REFERENCES public.profiles(id),
    date_of_birth DATE, gender TEXT, blood_group TEXT, mobile_number TEXT,
    home_address TEXT, height_cm TEXT, weight_kg TEXT,
    emergency_contact_name TEXT, emergency_contact_relationship TEXT, emergency_contact_phone TEXT,
    allergies TEXT, conditions TEXT, medications TEXT,
    past_medical_history TEXT, surgical_history TEXT, family_history TEXT,
    lifestyle TEXT, additional_notes TEXT, is_anamnesis_customized BOOLEAN,
    updated_at TIMESTAMPTZ
);

-- 3. Doctor Credentials & Practice
public.doctor_profiles (
    doctor_id UUID PRIMARY KEY REFERENCES public.profiles(id),
    specialty TEXT NOT NULL, qualification TEXT NOT NULL, years_of_experience TEXT,
    license_number TEXT NOT NULL, is_license_verified BOOLEAN NOT NULL DEFAULT FALSE,
    phone TEXT, hospital_name TEXT, clinic_address TEXT, practice_status TEXT,
    updated_at TIMESTAMPTZ
);

-- 4. Case Lifecycle Routing & Queues
public.cases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_reference TEXT UNIQUE NOT NULL,
    patient_id UUID REFERENCES public.profiles(id),
    title TEXT NOT NULL, category TEXT NOT NULL,
    status TEXT CHECK (status IN ('draft', 'submitted', 'awaiting_review', 'in_review', 'reviewed', 'archived')),
    assigned_doctor_id UUID REFERENCES public.doctor_profiles(doctor_id),
    submitted_at TIMESTAMPTZ, reviewed_at TIMESTAMPTZ, archived_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ
);

-- 5. 11-Step Clinical Questionnaire Responses
public.case_intake_responses (
    case_id UUID PRIMARY KEY REFERENCES public.cases(id),
    current_step INT DEFAULT 11, is_draft BOOLEAN DEFAULT FALSE,
    chief_concern TEXT NOT NULL, duration TEXT NOT NULL, severity TEXT NOT NULL,
    associated_symptoms TEXT[], other_associated_symptom TEXT,
    symptom_details TEXT, previous_occurrences TEXT, previous_occurrence_details TEXT,
    existing_conditions TEXT[], other_condition_details TEXT,
    allergies TEXT[], allergy_details TEXT,
    takes_medications TEXT, medication_details TEXT,
    medical_family_history TEXT, raw_responses JSONB,
    created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ
);

-- 6. AI Clinical Decision Support Summaries
public.ai_case_summaries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID UNIQUE REFERENCES public.cases(id),
    generation_status TEXT CHECK (generation_status IN ('pending', 'generating', 'ready', 'failed')),
    summary_text TEXT, chief_complaint TEXT, symptom_timeline_and_severity TEXT,
    relevant_positive_findings TEXT[], relevant_negative_findings TEXT[],
    medical_history_and_medications TEXT, missing_or_unclear_information TEXT[],
    error_message TEXT, disclaimer TEXT,
    last_requested_at TIMESTAMPTZ, generated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ
);

-- 7. Physician Clinical Assessments & Private Drafts
public.doctor_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID UNIQUE REFERENCES public.cases(id),
    doctor_id UUID REFERENCES public.profiles(id),
    clinical_assessment TEXT, observations TEXT,
    advice_and_recommendations TEXT, follow_up_instructions TEXT,
    follow_up_date DATE, is_finalized BOOLEAN DEFAULT FALSE,
    finalized_at TIMESTAMPTZ, last_saved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ, updated_at TIMESTAMPTZ
);

-- 8. Published Clinical Care Notes (Visible to Patient)
public.patient_care_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    case_id UUID REFERENCES public.cases(id),
    patient_id UUID REFERENCES public.profiles(id),
    doctor_id UUID REFERENCES public.profiles(id),
    author_name TEXT NOT NULL, category TEXT NOT NULL,
    note_text TEXT NOT NULL, published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ
);

-- 9. In-App Notifications
public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id),
    case_id UUID REFERENCES public.cases(id),
    title TEXT NOT NULL, message TEXT NOT NULL,
    category TEXT CHECK (category IN ('SYSTEM', 'CASE', 'DOCTOR')),
    is_read BOOLEAN DEFAULT FALSE, created_at TIMESTAMPTZ
);
```

---

## 2. n8n Queries & Database Operations

### Query 1: n8n Upserting AI Summary into Supabase
Used by the **Persist Summary to Supabase** node in `clinova_ai_case_summary_workflow.json`:

```sql
INSERT INTO public.ai_case_summaries (
    case_id,
    generation_status,
    summary_text,
    chief_complaint,
    symptom_timeline_and_severity,
    relevant_positive_findings,
    relevant_negative_findings,
    medical_history_and_medications,
    missing_or_unclear_information,
    disclaimer,
    generated_at,
    last_requested_at
) VALUES (
    $1, -- case_id (UUID or reference)
    'ready',
    $2, -- summary_text
    $3, -- chief_complaint
    $4, -- symptom_timeline_and_severity
    $5, -- relevant_positive_findings (text array)
    $6, -- relevant_negative_findings (text array)
    $7, -- medical_history_and_medications
    $8, -- missing_or_unclear_information (text array)
    'AI-generated summary — requires physician review. Not a diagnosis or prescription.',
    now(),
    now()
)
ON CONFLICT (case_id) DO UPDATE SET
    generation_status = EXCLUDED.generation_status,
    summary_text = EXCLUDED.summary_text,
    chief_complaint = EXCLUDED.chief_complaint,
    symptom_timeline_and_severity = EXCLUDED.symptom_timeline_and_severity,
    relevant_positive_findings = EXCLUDED.relevant_positive_findings,
    relevant_negative_findings = EXCLUDED.relevant_negative_findings,
    medical_history_and_medications = EXCLUDED.medical_history_and_medications,
    missing_or_unclear_information = EXCLUDED.missing_or_unclear_information,
    disclaimer = EXCLUDED.disclaimer,
    generated_at = EXCLUDED.generated_at,
    updated_at = now();
```

---

### Query 2: Direct Case Data Fetch (Server-Side n8n Verification)
If n8n receives only a `caseId` and queries Supabase directly:

```sql
SELECT 
    c.id AS case_id,
    c.case_reference,
    c.title,
    c.category,
    c.status,
    c.submitted_at,
    p.full_name AS patient_name,
    p.id AS patient_id,
    r.chief_concern,
    r.duration,
    r.severity,
    r.associated_symptoms,
    r.other_associated_symptom,
    r.symptom_details,
    r.previous_occurrences,
    r.previous_occurrence_details,
    r.existing_conditions,
    r.other_condition_details,
    r.allergies,
    r.allergy_details,
    r.takes_medications,
    r.medication_details,
    r.medical_family_history
FROM public.cases c
JOIN public.profiles p ON p.id = c.patient_id
JOIN public.case_intake_responses r ON r.case_id = c.id
WHERE c.id = $1 OR c.case_reference = $1;
```

---

### Query 3: Flutter PostgREST Queries

#### A. Patient Submitting a Completed Case
```dart
// 1. Insert into cases
final caseRow = await supabase.from('cases').insert({
  'case_reference': 'CASE-2026-8842',
  'patient_id': supabase.auth.currentUser!.id,
  'title': 'Persistent Cough & Low Fever',
  'category': 'Respiratory',
  'status': 'awaiting_review',
  'submitted_at': DateTime.now().toIso8601String(),
}).select().single();

// 2. Insert into case_intake_responses
await supabase.from('case_intake_responses').insert({
  'case_id': caseRow['id'],
  'current_step': 11,
  'chief_concern': intake.chiefConcern,
  'duration': intake.duration,
  'severity': intake.severity,
  'associated_symptoms': intake.associatedSymptoms,
  'other_associated_symptom': intake.otherAssociatedSymptom,
  'symptom_details': intake.symptomDetails,
  'previous_occurrences': intake.previousOccurrences,
  'previous_occurrence_details': intake.previousOccurrenceDetails,
  'existing_conditions': intake.existingConditions,
  'other_condition_details': intake.otherConditionDetails,
  'allergies': intake.allergies,
  'allergy_details': intake.allergyDetails,
  'takes_medications': intake.takesMedications,
  'medication_details': intake.medicationDetails,
  'medical_family_history': intake.medicalFamilyHistory,
});
```

#### B. Doctor Saving a Draft Assessment
```dart
await supabase.from('doctor_assessments').upsert({
  'case_id': caseId,
  'doctor_id': supabase.auth.currentUser!.id,
  'clinical_assessment': assessment.clinicalAssessment,
  'observations': assessment.observations,
  'advice_and_recommendations': assessment.adviceAndRecommendations,
  'follow_up_instructions': assessment.followUpInstructions,
  'follow_up_date': assessment.followUpDate?.toIso8601String().split('T').first,
  'is_finalized': false,
  'last_saved_at': DateTime.now().toIso8601String(),
});
```

#### C. Doctor Finalizing a Review
```dart
// Setting is_finalized = true triggers the database automation trg_assessment_finalized,
// which automatically publishes to patient_care_notes and marks the case as 'reviewed'!
await supabase.from('doctor_assessments').upsert({
  'case_id': caseId,
  'doctor_id': supabase.auth.currentUser!.id,
  'clinical_assessment': assessment.clinicalAssessment,
  'observations': assessment.observations,
  'advice_and_recommendations': assessment.adviceAndRecommendations,
  'follow_up_instructions': assessment.followUpInstructions,
  'follow_up_date': assessment.followUpDate?.toIso8601String().split('T').first,
  'is_finalized': true,
  'finalized_at': DateTime.now().toIso8601String(),
  'last_saved_at': DateTime.now().toIso8601String(),
});
```

#### D. Patient Reading Finalized Care Notes
```dart
final notes = await supabase
    .from('patient_care_notes')
    .select()
    .eq('patient_id', supabase.auth.currentUser!.id)
    .order('published_at', ascending: false);
```
