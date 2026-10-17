# CLINOVA — COMPLETE CODEBASE AUDIT & ARCHITECTURAL REPORT

**Audit Date**: October 2026  
**Auditor**: Senior Software Architect, Flutter Code Auditor, & Database Specialist  
**Application**: Clinova (Flutter 3.13+, Dart 3.0+)  
**Workspace**: `c:\flutter\projects\Clinova`  

---

## 1. Executive Summary

Clinova is an AI-assisted patient case-taking and doctor consultation platform designed with an organic, calm botanical aesthetic (mint green palette `#28654F`, soft cream/off-white cards, neumorphic elevation, and layered leaf watermark decorations).

The application currently operates with **frontend-first architecture**:
1. State management and data persistence are backed by in-memory singleton repositories combined with `SharedPreferences` for local offline persistence.
2. An abstract authentication boundary (`AuthService` and `AuthConfig.useDemoAuth`) enables full frontend workflow testing while isolating the UI from backend implementation details.
3. An AI Case Summary orchestration module communicates with an **n8n workflow webhook**, validating payloads and responses while maintaining strict clinical boundaries (no medical fabrication, strict physician review disclaimer, zero contamination of doctor-authored notes).
4. No direct database or cloud backend is currently connected; however, models and serialization routines are already prepared for **Supabase (PostgreSQL + RLS)** and **n8n workflow orchestration**.

---

## 2. Directory Structure & Codebase Map

```
Clinova/
├── android/                         # Android platform host
├── ios/                             # iOS platform host
├── web/                             # Web platform host (tested on localhost:8080)
├── assets/
│   ├── images/                      # Botanical branding (leaves.png, heart.png, logo, etc.)
│   └── n8n/
│       └── clinova_case_summary_workflow.json # Existing n8n workflow definition
├── docs/
│   └── n8n_integration_guide.md     # Existing integration notes
├── lib/
│   ├── app.dart                     # MaterialApp, routes, theme
│   ├── main.dart                    # Entry point: initializes repositories & SystemUI
│   ├── core/
│   │   ├── auth/                    # AuthService, DemoAuthService, UserSession, UserRole
│   │   ├── config/                  # AiSummaryConfig (n8n webhook URL & timeouts)
│   │   ├── constants/               # AppConstants
│   │   ├── routing/                 # AppRoutes (16 named routes)
│   │   └── theme/                   # ClinovaTheme, ClinovaColors
│   ├── features/
│   │   ├── authentication/          # Login, Signup, Forgot Password (Patient & Doctor)
│   │   ├── dashboard/
│   │   │   ├── doctor/              # Doctor Dashboard, Case Queue, Case Review, Profile
│   │   │   │   ├── models/          # DoctorProfileModel, DoctorAssessmentModel, AiCaseSummaryModel
│   │   │   │   ├── screens/         # DoctorDashboardScreen, DoctorCaseQueueScreen, DoctorCaseReviewScreen, DoctorProfileScreen
│   │   │   │   ├── services/        # DoctorProfileRepository, DoctorAssessmentRepository, AiCaseSummaryRepository
│   │   │   │   └── widgets/         # DoctorSideDrawer
│   │   │   └── patient/             # Patient Dashboard, Case Intake (11 steps), Profile, Notes
│   │   │       ├── models/          # CaseIntakeModel, PatientProfileModel, PatientCareNoteModel
│   │   │       ├── screens/         # CaseIntakeScreen, PatientCaseDetailScreen, PatientCareNotesScreen, etc.
│   │   │       ├── services/        # DemoCaseRepository, PatientProfileRepository, PatientCareNotesRepository
│   │   │       └── widgets/         # PatientAppBar, PatientSideDrawer, PatientNotificationsSheet, etc.
│   │   ├── splash/                  # Animated splash screen
│   │   └── welcome/                 # Role selection (Patient vs. Doctor)
│   └── shared/                      # Reusable Neumorphic and botanical widgets
└── test/                            # Comprehensive Flutter test suite (121 passing tests)
```

---

## 3. Authentication & Role Handling

### 3.1 Existing Implementation
- **Interface**: `AuthService` (`lib/core/auth/auth_service.dart`) defines:
  - `currentSession`: active `UserSession?`
  - `sessionStream`: reactive stream of session changes
  - `login(email, password, role)`
  - `registerPatient(name, email, password)`
  - `registerDoctor(name, email, specialty, license, password)`
  - `logout()`
- **Active Provider**: `DemoAuthService` (`lib/core/auth/demo_auth_service.dart`).
- **Configuration Switch**: `AuthConfig.useDemoAuth` (`lib/core/auth/auth_config.dart`) determines whether `DemoAuthService` or a future `SupabaseAuthService` is invoked.

### 3.2 User Roles & Separation
- Two user roles are supported via `UserRole`: `patient` and `doctor`.
- **Patient Registration**: `lib/features/authentication/patient/patient_signup_screen.dart` captures Full Name, Email, Password, and Privacy Consent.
- **Doctor Registration**: `lib/features/authentication/doctor/doctor_signup_screen.dart` captures Full Name, Email, Medical Specialty, License Number, Password, and Terms Agreement.
- **Critical Security Finding**: In demo mode, role is client-selected during login/signup. In a production Supabase setup, **public signups must never be allowed to self-assign the `doctor` role** or set `is_license_verified = true`. Doctor roles must be provisioned or verified via an administrative review trigger.

---

## 4. Screen-to-Data & Model Mapping

| Screen / Feature | Location | Backing Model | Current Repository / Storage |
|---|---|---|---|
| **Welcome / Role Select** | `welcome_screen.dart` | N/A | Navigation to role-specific login |
| **Patient Login / Signup** | `patient_login_screen.dart`<br>`patient_signup_screen.dart` | `UserSession`<br>`UserRole.patient` | `DemoAuthService` |
| **Doctor Login / Signup** | `doctor_login_screen.dart`<br>`doctor_signup_screen.dart` | `UserSession`<br>`UserRole.doctor` | `DemoAuthService` |
| **Patient Dashboard** | `patient_dashboard_screen.dart` | `PatientProfileModel`<br>`PatientCaseSummary`<br>`PatientCareNote` | `PatientProfileRepository`<br>`DemoCaseRepository`<br>`PatientCareNotesRepository` |
| **Patient Profile & Anamnesis** | `patient_profile_details_screen.dart`<br>`patient_general_info_screen.dart`<br>`patient_anamnesis_screen.dart` | `PatientProfileModel` | `PatientProfileRepository`<br>(key: `clinova_saved_patient_profile`) |
| **Patient Case Intake (11 Steps)** | `case_intake_screen.dart` | `CaseIntakeModel` | `DemoCaseRepository`<br>(key: `clinova_active_case_draft`) |
| **Patient Case Detail** | `patient_case_detail_screen.dart` | `PatientCaseSummary` | `DemoCaseRepository` |
| **Patient Care Notes** | `patient_care_notes_screen.dart` | `PatientCareNote` | `PatientCareNotesRepository`<br>(key: `clinova_patient_care_notes`) |
| **Patient Notifications** | `patient_notifications_sheet.dart` | `PatientNotificationItem` | Hardcoded mock items in widget state |
| **Doctor Dashboard** | `doctor_dashboard_screen.dart` | `DoctorProfileModel`<br>`PatientCaseSummary` | `DoctorProfileRepository`<br>`DemoCaseRepository` |
| **Doctor Case Queue** | `doctor_case_queue_screen.dart` | `PatientCaseSummary` | `DemoCaseRepository` |
| **Doctor Case Review** | `doctor_case_review_screen.dart` | `PatientCaseSummary`<br>`CaseIntakeModel`<br>`AiCaseSummaryModel`<br>`DoctorAssessmentModel` | `DemoCaseRepository`<br>`AiCaseSummaryRepository`<br>`DoctorAssessmentRepository` |
| **Doctor Profile** | `doctor_profile_screen.dart` | `DoctorProfileModel` | `DoctorProfileRepository`<br>(key: `clinova_saved_doctor_profile`) |

---

## 5. Detailed Field Analysis of Existing Models

### 5.1 PatientProfileModel (`patient_profile_model.dart`)
- **Demographics / Contact**:
  - `fullName` (String, required)
  - `dateOfBirth` (DateTime?, optional; provides computed getter `age`)
  - `gender` (String?, optional)
  - `bloodGroup` (String?, optional)
  - `mobileNumber` (String, required)
  - `email` (String, required)
  - `homeAddress` (String, required)
  - `heightCm` (String?, optional)
  - `weightKg` (String?, optional)
  - `photoBytes` (Uint8List?, optional avatar)
- **Emergency Contact**:
  - `emergencyContactName` (String?)
  - `emergencyContactRelationship` (String?)
  - `emergencyContactPhone` (String?)
- **Clinical Anamnesis (Medical History)**:
  - `allergies` (String?)
  - `conditions` (String?)
  - `medications` (String?)
  - `pastMedicalHistory` (String?)
  - `surgicalHistory` (String?)
  - `familyHistory` (String?)
  - `lifestyle` (String?)
  - `additionalNotes` (String?)
  - `isAnamnesisCustomized` (bool, default `false`)

### 5.2 DoctorProfileModel (`doctor_profile_model.dart`)
- `fullName` (String, required)
- `specialty` (String, required)
- `qualification` (String, default: "MBBS, MD (Internal Medicine)")
- `yearsOfExperience` (String, default: "12")
- `licenseNumber` (String, default: "CLIN-8821-MD")
- `isLicenseVerified` (bool, default: `false`)
- `email` (String, required)
- `phone` (String, default: "+1 (555) 019-2834")
- `hospitalName` (String, default: "St. Jude Clinical Medical Center")
- `clinicAddress` (String, default: "Building 4B, Health Science Blvd, Suite 210")
- `dateOfBirth` (DateTime?)
- `doctorId` (String, default: "CLIN-DOC-DEMO-01")
- `accountEmail` (String, required)
- `practiceStatus` (String, default: "Active Demo Practitioner")
- `photoBytes` (Uint8List?, base64-encoded in JSON)

### 5.3 CaseIntakeModel (`case_intake_model.dart`)
Represents the complete 11-step clinical questionnaire:
- `reference` (String, e.g. `DEMO-CASE-8842`)
- `currentStep` (int, 1 to 11)
- `status` (String, `'draft'` or `'submitted'`)
- `createdAt` (DateTime)
- `lastUpdatedAt` (DateTime)
- **Step 1 — Chief Concern**: `chiefConcern` (String, required)
- **Step 2 — Duration**: `duration` (String, single choice: `'Less than 24 hours'`, `'1–3 days'`, `'4–7 days'`, `'1–2 weeks'`, `'More than 2 weeks'`, `'Comes and goes'`)
- **Step 3 — Severity**: `severity` (String, single choice: `'Mild'`, `'Moderate'`, `'Severe'`, `'Very severe'`)
- **Step 4 — Associated Symptoms**: `associatedSymptoms` (List<String>), `otherAssociatedSymptom` (String?)
- **Step 5 — Triggers & Relief**: `symptomDetails` (String?, multiline)
- **Step 6 — Previous Occurrences**: `previousOccurrences` (String, `'Yes'`, `'No'`, `'Not sure'`), `previousOccurrenceDetails` (String?)
- **Step 7 — Existing Conditions**: `existingConditions` (List<String>), `otherConditionDetails` (String?)
- **Step 8 — Allergies**: `allergies` (List<String>), `allergyDetails` (String?)
- **Step 9 — Medications**: `takesMedications` (String, `'Yes'`, `'No'`, `'Not sure'`), `medicationDetails` (String?)
- **Step 10 — Medical & Family History**: `medicalFamilyHistory` (String?, multiline)
- **Step 11 — Final Review**: Review & submit confirmation.

### 5.4 PatientCaseSummary (`demo_case_repository.dart`)
Lightweight summary representation used in Dashboard lists, Queues, and filtering:
- `id` (String, unique identifier, e.g. `case-01`, `case-1728849201923`)
- `reference` (String, human-friendly code)
- `title` (String, chief concern summary)
- `date` (String, formatted submission date)
- `status` (String, e.g. `'Summary ready'`, `'Awaiting doctor review'`, `'In review'`, `'Reviewed by Doctor'`, `'Archived'`)
- `category` (String, e.g. `'Respiratory'`, `'Musculoskeletal'`, `'General Health'`)
- `doctor` (String?, assigned doctor name)
- `notes` (String?, preview note)
- `patientName` (String)
- `patientId` (String)
- `submittedAt` (DateTime?)
- `reviewedAt` (DateTime?)
- `fullCase` (CaseIntakeModel?, embedded questionnaire responses)

### 5.5 AiCaseSummaryModel (`ai_case_summary_model.dart`)
Physician decision-support record generated via n8n:
- `caseId` (String, matching target case)
- `generationStatus` (String: `'pending'`, `'generating'`, `'ready'`, `'failed'`)
- `summaryText` (String, synthesized narrative)
- `chiefComplaint` (String)
- `symptomTimelineAndSeverity` (String)
- `relevantPositiveFindings` (List<String>, patient-reported symptoms)
- `relevantNegativeFindings` (List<String>, patient-supported denied symptoms)
- `medicalHistoryAndMedications` (String)
- `missingOrUnclearInformation` (List<String>, clarification points for physician)
- `errorMessage` (String?, on failure)
- `generatedAt` (DateTime?)
- `lastRequestedAt` (DateTime)

### 5.6 DoctorAssessmentModel (`doctor_assessment_model.dart`)
Physician-authored clinical assessment and supervised care plan:
- `caseId` (String, foreign reference to case)
- `doctorName` (String)
- `clinicalAssessment` (String, multiline diagnosis/impression)
- `observations` (String, clinical findings)
- `adviceAndRecommendations` (String, lifestyle/clinical guidance)
- `followUpInstructions` (String, action items)
- `followUpDate` (DateTime?, optional follow-up)
- `isFinalized` (bool, default `false`)
- `finalizedAt` (DateTime?)
- `lastSavedAt` (DateTime)

### 5.7 PatientCareNote (`patient_care_note_model.dart`)
Read-only note published to the patient upon physician finalization:
- `id` (String)
- `text` (String, formatted clinical instructions)
- `date` (DateTime?, publication timestamp)
- `author` (String?, attending doctor's name)
- `category` (String?, case category / title)

---

## 6. End-to-End Workflow Analysis

### 6.1 Patient Workflow
1. **Registration & Login**: Patient enters email/password. In demo mode, `DemoAuthService` creates a `UserSession`.
2. **Profile & Anamnesis**: Patient views and updates demographic information (`patient_general_info_screen.dart`) and clinical history (`patient_anamnesis_screen.dart`). Changes are broadcast through `PatientProfileRepository`.
3. **Drafting a Case**: Patient initiates a new case. Each answered step modifies the in-memory `CaseIntakeModel` and autosaves the draft to `SharedPreferences` via `DemoCaseRepository.instance.saveDraft()`.
4. **Case Submission**: At Step 11, the patient taps "Submit Case".
   - The case is converted into a `PatientCaseSummary` with status `"Awaiting doctor review"` and inserted into `DemoCaseRepository`.
   - The active draft is deleted.
   - Non-blocking asynchronous dispatch triggers `AiCaseSummaryRepository.instance.generateSummaryForCase(...)`.
   - The patient is navigated to the confirmation screen regardless of whether the n8n webhook succeeds or fails.
5. **Viewing Health History & Care Notes**: Patient can view submitted cases in `MyHealthCases` (`patient_cases_view.dart`) and read finalized clinical notes in `PatientCareNotesScreen`.

### 6.2 Doctor Workflow
1. **Doctor Dashboard**: Doctor views summary stats (Pending Cases, In Review, Completed Reviews, Total Patients) and a clickable Profile Card.
2. **Case Queue**: Doctor filters cases by status (`All`, `Pending`, `In Review`, `Reviewed`, `Archived`) or searches by complaint, patient name, or ID.
3. **Case Review**:
   - Displays patient demographics, risk tags, and full answers to all 11 questionnaire steps.
   - Embeds the **AI Decision Support Card** with generation status (`Ready`, `Generating`, `Pending`, `Failed`), clear amber physician disclaimers, and a single-click *Re-run Summary* retry action.
   - Embeds the **Doctor Assessment & Supervised Notes Editor** with separate inputs for Assessment, Observations, Advice, Follow-up, and Follow-up Date.
4. **Draft Saving**: Doctor clicks "Save Draft". The assessment is saved locally with `isFinalized = false`. Case status remains unfinalized, and notes are **not** published to the patient.
5. **Finalizing Review**: Doctor clicks "Finalize Review".
   - Assessment is saved with `isFinalized = true` and `finalizedAt = now`.
   - Case status in `DemoCaseRepository` transitions to `"Reviewed"`.
   - Structured care instructions are formatted and published to `PatientCareNotesRepository`, becoming visible to the patient.

---

## 7. Architectural Inconsistencies, Risks & Missing Integrations

| Area | Current Implementation | Identified Risk / Gap | Required Supabase & n8n Solution |
|---|---|---|---|
| **User Identity** | In-memory `DemoAuthService` | No persistent accounts, no password hashing, client controls role assignment. | Use `Supabase Auth` (`auth.users`) with a database trigger to create `public.profiles`. Enforce role-based access. |
| **Case Storage** | In-memory `_cases` list with static demo items (`case-01`, `case-02`, `case-03`) | Submissions vanish on application reload or cross-device access. | Create `public.cases` and `public.case_intake_responses` tables in PostgreSQL with RLS. |
| **Doctor Authorization** | Client-side filter without backend validation | Patients could theoretically view cases or queue endpoints if exposed without RLS. | Strict PostgreSQL Row-Level Security: Patients can only SELECT their own cases; Doctors can view authorized/assigned cases. |
| **Draft Security** | Doctor draft assessment stored in local `SharedPreferences` | If a doctor uses multiple devices or clears cache, drafts are lost. No cross-doctor assignment guard. | Store drafts in `public.doctor_assessments` with `is_finalized = false`. RLS policy prevents patients from reading unfinalized drafts. |
| **AI Webhook Security** | Direct HTTP POST from Flutter to n8n webhook without auth header | Public endpoint could be abused; client-side caller can alter payload. | Add API Key / HMAC Header validation in n8n; validate caller identity against Supabase session. |
| **Notifications** | Hardcoded mock items in `_PatientNotificationsSheetState` | Notifications are not dynamic or synced with actual case status transitions. | Create `public.notifications` table with triggers on case review finalization. |
| **Avatar Storage** | Base64 encoded byte strings inside JSON | Bloats database rows and `SharedPreferences`. | Use Supabase Storage bucket `clinova-avatars` with signed/public URLs. |

---

## 8. Preserved Application Features & Non-Negotiables

During database and backend integration, the following frontend elements must remain **100% untouched**:
- Clinova’s soft mint and neumorphic theme (`ClinovaColors.primary = Color(0xFF28654F)`).
- Watermark botanical leaf decorations positioned behind cards using `IgnorePointer`.
- The exact 11-step sequence and questions in `CaseIntakeScreen`.
- Strict separation between AI decision-support output and doctor-authored notes.
- Demo mode compatibility (`AuthConfig.useDemoAuth`) so the app can still be previewed offline without backend credentials.
