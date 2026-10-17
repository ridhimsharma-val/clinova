# CLINOVA — SHARED BACKEND & INTEGRATION CONTRACT

**Document Version**: 1.0  
**Tiers Governed**: Flutter Client <---> Supabase PostgreSQL <---> n8n Automation Engine  
**Status**: Production Specification  

---

## 1. Architectural Contract Overview

To ensure data integrity, privacy, and clinical safety, all communication between the **Flutter Client**, the **Supabase Database**, and the **n8n Orchestrator** adheres to a single unified contract.

```
┌─────────────────────────────────┐
│     Flutter Client (Clinova)    │
│  - CaseIntakeModel              │
│  - PatientCaseSummary           │
│  - AiCaseSummaryModel           │
│  - DoctorAssessmentModel        │
│  - PatientCareNote              │
└──────────────┬──────────────────┘
               │  ▲
    Supabase   │  │  Supabase PostgREST
    Client SDK │  │  (Protected by RLS)
               ▼  │
┌─────────────────────────────────┐           Webhook Trigger           ┌─────────────────────────────────┐
│      Supabase PostgreSQL        │ ──────────────────────────────────> │         n8n Orchestrator        │
│  - 9 Relational Tables          │                                     │  - Validates Case Payload       │
│  - Row-Level Security           │ <────────────────────────────────── │  - Synthesizes Decision Support │
│  - Clinical State Triggers      │      Server-Side Upsert (Admin)     │  - Responds with Schema JSON    │
└─────────────────────────────────┘                                     └─────────────────────────────────┘
```

---

## 2. Field-by-Field Entity Mapping

### 2.1 Profile Entities

| Flutter Model (`PatientProfileModel`) | Supabase Column (`patient_profiles` / `profiles`) | Type | Nullable | Notes |
|---|---|---|:---:|---|
| `fullName` | `profiles.full_name` | `TEXT` | No | Base user profile |
| `email` | `profiles.email` | `TEXT` | No | Synchronized with `auth.users` |
| `dateOfBirth` | `patient_profiles.date_of_birth` | `DATE` | Yes | YYYY-MM-DD |
| `gender` | `patient_profiles.gender` | `TEXT` | Yes | 'Male', 'Female', 'Other' |
| `bloodGroup` | `patient_profiles.blood_group` | `TEXT` | Yes | 'A+', 'B+', 'O+', etc. |
| `mobileNumber` | `patient_profiles.mobile_number` | `TEXT` | No | E.164 phone format |
| `homeAddress` | `patient_profiles.home_address` | `TEXT` | No | Street, City, Country |
| `heightCm` | `patient_profiles.height_cm` | `TEXT` | Yes | e.g. "172" |
| `weightKg` | `patient_profiles.weight_kg` | `TEXT` | Yes | e.g. "68" |
| `emergencyContactName` | `patient_profiles.emergency_contact_name` | `TEXT` | Yes | Contact full name |
| `emergencyContactRelationship` | `patient_profiles.emergency_contact_relationship` | `TEXT` | Yes | 'Spouse', 'Parent', etc. |
| `emergencyContactPhone` | `patient_profiles.emergency_contact_phone` | `TEXT` | Yes | Phone number |
| `allergies` | `patient_profiles.allergies` | `TEXT` | Yes | Baseline allergies |
| `conditions` | `patient_profiles.conditions` | `TEXT` | Yes | Chronic conditions |
| `medications` | `patient_profiles.medications` | `TEXT` | Yes | Current medications |
| `pastMedicalHistory` | `patient_profiles.past_medical_history` | `TEXT` | Yes | Free text history |
| `surgicalHistory` | `patient_profiles.surgical_history` | `TEXT` | Yes | Surgical history |
| `familyHistory` | `patient_profiles.family_history` | `TEXT` | Yes | Family history |
| `lifestyle` | `patient_profiles.lifestyle` | `TEXT` | Yes | Diet, exercise, habits |
| `additionalNotes` | `patient_profiles.additional_notes` | `TEXT` | Yes | General notes |

### 2.2 Case & Intake Entities

| Flutter Model (`CaseIntakeModel` & `PatientCaseSummary`) | Supabase Column (`cases` & `case_intake_responses`) | Type | Nullable | Notes |
|---|---|---|:---:|---|
| `id` / `reference` | `cases.case_reference` | `TEXT` | No | Unique (e.g. `CASE-2026-8842`) |
| `status` | `cases.status` | `TEXT` | No | 'draft', 'submitted', 'awaiting_review', 'in_review', 'reviewed', 'archived' |
| `title` | `cases.title` | `TEXT` | No | Headline description |
| `category` | `cases.category` | `TEXT` | No | 'Respiratory', 'Musculoskeletal', etc. |
| `submittedAt` | `cases.submitted_at` | `TIMESTAMPTZ` | Yes | Submission timestamp |
| `chiefConcern` | `case_intake_responses.chief_concern` | `TEXT` | No | Step 1 |
| `duration` | `case_intake_responses.duration` | `TEXT` | No | Step 2 (Single-choice) |
| `severity` | `case_intake_responses.severity` | `TEXT` | No | Step 3 (Single-choice) |
| `associatedSymptoms` | `case_intake_responses.associated_symptoms` | `TEXT[]` | No | Step 4 (Multi-choice array) |
| `otherAssociatedSymptom` | `case_intake_responses.other_associated_symptom` | `TEXT` | Yes | Step 4 text input |
| `symptomDetails` | `case_intake_responses.symptom_details` | `TEXT` | Yes | Step 5 (Triggers & Relief) |
| `previousOccurrences` | `case_intake_responses.previous_occurrences` | `TEXT` | Yes | Step 6 ('Yes', 'No', 'Not sure') |
| `previousOccurrenceDetails` | `case_intake_responses.previous_occurrence_details` | `TEXT` | Yes | Step 6 text input |
| `existingConditions` | `case_intake_responses.existing_conditions` | `TEXT[]` | No | Step 7 (Multi-choice array) |
| `otherConditionDetails` | `case_intake_responses.other_condition_details` | `TEXT` | Yes | Step 7 text input |
| `allergies` | `case_intake_responses.allergies` | `TEXT[]` | No | Step 8 (Multi-choice array) |
| `allergyDetails` | `case_intake_responses.allergy_details` | `TEXT` | Yes | Step 8 text input |
| `takesMedications` | `case_intake_responses.takes_medications` | `TEXT` | Yes | Step 9 ('Yes', 'No', 'Not sure') |
| `medicationDetails` | `case_intake_responses.medication_details` | `TEXT` | Yes | Step 9 text input |
| `medicalFamilyHistory` | `case_intake_responses.medical_family_history` | `TEXT` | Yes | Step 10 multiline text |

### 2.3 AI Summary Entity

| Flutter Model (`AiCaseSummaryModel`) | Supabase Column (`ai_case_summaries`) | n8n JSON Key | Type | Notes |
|---|---|---|---|---|
| `caseId` | `case_id` | `caseId` | `UUID` / `TEXT` | Foreign key to `cases(id)` |
| `generationStatus` | `generation_status` | `generationStatus` | `TEXT` | 'pending', 'generating', 'ready', 'failed' |
| `summaryText` | `summary_text` | `summaryText` | `TEXT` | Executive summary narrative |
| `chiefComplaint` | `chief_complaint` | `chiefComplaint` | `TEXT` | Primary complaint |
| `symptomTimelineAndSeverity` | `symptom_timeline_and_severity` | `symptomTimelineAndSeverity` | `TEXT` | Chronological progression |
| `relevantPositiveFindings` | `relevant_positive_findings` | `relevantPositiveFindings` | `TEXT[]` | Patient-supported positive findings |
| `relevantNegativeFindings` | `relevant_negative_findings` | `relevantNegativeFindings` | `TEXT[]` | Patient-supported denied findings |
| `medicalHistoryAndMedications` | `medical_history_and_medications` | `medicalHistoryAndMedications` | `TEXT` | Background synthesis |
| `missingOrUnclearInformation` | `missing_or_unclear_information` | `missingOrUnclearInformation` | `TEXT[]` | Clarification questions for doctor |
| `errorMessage` | `error_message` | `errorMessage` | `TEXT` | Error text if failed |
| `generatedAt` | `generated_at` | `generatedAt` | `TIMESTAMPTZ` | Timestamp of completion |

### 2.4 Doctor Assessment & Patient Care Notes Entities

| Flutter Model (`DoctorAssessmentModel`) | Supabase Column (`doctor_assessments`) | Type | Access Level |
|---|---|---|---|
| `caseId` | `case_id` | `UUID` | Doctor only |
| `clinicalAssessment` | `clinical_assessment` | `TEXT` | Doctor only |
| `observations` | `observations` | `TEXT` | Doctor only |
| `adviceAndRecommendations` | `advice_and_recommendations` | `TEXT` | Doctor only |
| `followUpInstructions` | `follow_up_instructions` | `TEXT` | Doctor only |
| `followUpDate` | `follow_up_date` | `DATE` | Doctor only |
| `isFinalized` | `is_finalized` | `BOOLEAN` | Doctor only |
| `finalizedAt` | `finalized_at` | `TIMESTAMPTZ` | Doctor only |

*When `is_finalized` transitions to `TRUE`, the database trigger automatically copies the formatted text into `patient_care_notes` (`note_text`, `author_name`, `published_at`), making it visible to the patient.*

---

## 3. Synthetic Request & Response Examples

### 3.1 Patient Submitting a Case (Flutter -> Supabase)
```json
{
  "case_reference": "CASE-2026-1049",
  "title": "Persistent Cough & Low Fever",
  "category": "Respiratory",
  "status": "awaiting_review",
  "chief_concern": "Persistent Cough & Low Fever",
  "duration": "4–7 days",
  "severity": "Moderate",
  "associated_symptoms": ["Cough", "Fever", "Fatigue"],
  "symptom_details": "Worse in cool weather and at night.",
  "previous_occurrences": "No",
  "existing_conditions": ["None known"],
  "allergies": ["No known allergies"],
  "takes_medications": "No",
  "medical_family_history": "No chronic respiratory history."
}
```

### 3.2 Doctor Saving a Draft (Flutter -> Supabase)
```json
{
  "case_id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
  "clinical_assessment": "Subacute non-productive cough, likely post-viral bronchospasm. No current signs of consolidation.",
  "observations": "Normal respiratory effort reported; low-grade temperature. Hydration and rest advised.",
  "advice_and_recommendations": "Hydration, honey in warm water, monitor temperature twice daily.",
  "follow_up_instructions": "Return if fever exceeds 38.5C or shortness of breath develops.",
  "follow_up_date": "2026-10-18",
  "is_finalized": false
}
```

### 3.3 Patient Care Note Record (Auto-Published by Trigger)
```json
{
  "id": "e3b0c442-98fc-1c14-9afb-4c8996fb9242",
  "case_id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
  "patient_id": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d",
  "author_name": "Dr. Marcus Vance",
  "category": "Persistent Cough & Low Fever",
  "note_text": "Clinical Assessment:\nSubacute non-productive cough, likely post-viral bronchospasm.\n\nAdvice & Recommendations:\nHydration, honey in warm water, monitor temperature twice daily.\n\nFollow-up Instructions:\nReturn if fever exceeds 38.5C or shortness of breath develops.",
  "published_at": "2026-10-12T14:22:00.000Z"
}
```

---

## 4. Transitioning from Demo Mode to Live Backend

1. **Authentication Layer**:
   - In `lib/core/auth/auth_config.dart`, change `useDemoAuth = false`.
   - Implement `SupabaseAuthService` adhering to `AuthService`.
2. **Repository Layer**:
   - `DemoCaseRepository` can be substituted with `SupabaseCaseRepository`.
   - In offline/demo mode, the repository continues using `SharedPreferences`. In connected mode, it syncs with `supabase.from('cases')`.
3. **Zero UI Disruption**:
   - Screens (`DoctorDashboardScreen`, `CaseIntakeScreen`, `DoctorCaseReviewScreen`, etc.) interact solely through repository streams and models. No widgets require refactoring.
