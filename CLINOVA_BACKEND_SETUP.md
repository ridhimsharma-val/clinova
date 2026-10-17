# CLINOVA — STEP-BY-STEP BACKEND SETUP & VERIFICATION GUIDE

**Document Version**: 1.0  
**Target Systems**: Supabase (Database & Auth) & n8n (Workflow Orchestration)  
**Client Project**: Clinova Flutter Application (`c:\flutter\projects\Clinova`)  

---

## 1. Overview & Preparation

This guide explains how to apply the generated SQL schema and import the n8n automation workflow when you are ready to configure live credentials.

### Configuration Placeholders Required Later
When you set up your cloud or local instances, you will supply these values:
- `SUPABASE_URL`: e.g. `https://xyzcompany.supabase.co`
- `SUPABASE_ANON_KEY`: Supabase Public Publishable Anon Key (used in Flutter client)
- `SUPABASE_SERVICE_ROLE_KEY`: Supabase Private Service Role Secret (used **exclusively** inside n8n)
- `N8N_BASE_URL`: e.g. `https://n8n.yourclinic.org` or `http://localhost:5678`
- `N8N_WEBHOOK_URL`: e.g. `https://n8n.yourclinic.org/webhook/clinova-case-summary`
- `AI_PROVIDER_API_KEY`: OpenAI / Gemini / Anthropic API Key (configured **exclusively** in n8n)

> [!CAUTION]
> **Never put the Supabase Service Role Key or AI Provider API Keys inside Flutter client code.**
> Only the Supabase `anon` publishable key is permitted in the client, guarded by PostgreSQL Row-Level Security (RLS).

---

## 2. Step-by-Step Backend Deployment Instructions

### Step 1: Review Database Design
Open and review [`CLINOVA_DATABASE_DESIGN.md`](./CLINOVA_DATABASE_DESIGN.md) to familiarize yourself with the 9 relational tables:
1. `profiles`
2. `patient_profiles`
3. `doctor_profiles`
4. `cases`
5. `case_intake_responses`
6. `ai_case_summaries`
7. `doctor_assessments`
8. `patient_care_notes`
9. `notifications`

---

### Step 2: Execute SQL in Supabase
1. Log in to your [Supabase Dashboard](https://supabase.com/dashboard).
2. Create a new development project or select an existing project.
3. In the left-hand navigation, click **SQL Editor**.
4. Click **New Query**.
5. Open the local file [`clinova_supabase_setup.sql`](./clinova_supabase_setup.sql) in your code editor.
6. Copy its entire contents, paste it into the Supabase SQL Editor, and click **Run**.
7. Confirm that the query executes with `Success. No rows returned`.

---

### Step 3: Verify Tables, Triggers & RLS Policies
1. In Supabase, navigate to **Table Editor**:
   - Verify that all **9 tables** appear under the `public` schema.
2. Navigate to **Authentication** -> **Policies**:
   - Confirm that Row-Level Security (RLS) is **Enabled** on all 9 tables.
   - Confirm that policies exist for `profiles`, `patient_profiles`, `doctor_profiles`, `cases`, `case_intake_responses`, `ai_case_summaries`, `doctor_assessments`, `patient_care_notes`, and `notifications`.
3. Navigate to **Database** -> **Triggers**:
   - Verify `trg_assessment_finalized` on `public.doctor_assessments`.
   - Verify `on_auth_user_created` on `auth.users`.
   - Verify `trg_guard_license_verification` on `public.doctor_profiles`.

---

### Step 4: Import and Configure n8n Workflow
1. Start your local n8n instance (`npx n8n` or Docker) or log in to your n8n Cloud instance.
2. In n8n, click **Workflows** -> **Add workflow**.
3. In the canvas menu (`...`), click **Import from File...**.
4. Select [`clinova_ai_case_summary_workflow.json`](./clinova_ai_case_summary_workflow.json).
5. In n8n, go to **Credentials** -> **New Credential** -> **Supabase**:
   - **Host**: Enter your `SUPABASE_URL`.
   - **Service Role Secret**: Enter your `SUPABASE_SERVICE_ROLE_KEY`.
   - Save credential as `Clinova Supabase Admin`.
6. Open the **Persist Summary to Supabase** node on the canvas and attach the credential.
7. Click **Save** and toggle the workflow to **Active**.

---

### Step 5: Configure Flutter Client

When you are ready to connect the Flutter application to the live backend:

1. **Provide Environment Variables at Build/Run Time**:
   Launch Flutter with compile-time defines:
   ```bash
   flutter run -d chrome \
     --dart-define=SUPABASE_URL=https://your-project.supabase.co \
     --dart-define=SUPABASE_ANON_KEY=eyJhbGciOi... \
     --dart-define=CLINOVA_N8N_WEBHOOK_URL=http://localhost:5678/webhook/clinova-case-summary
   ```

2. **Toggle Demo Mode**:
   In `lib/core/auth/auth_config.dart`, update:
   ```dart
   static const bool useDemoAuth = false;
   ```

---

## 3. End-to-End Verification Checklist

Perform these tests once credentials are wired:

### Test A: Patient Intake & Case Submission
1. Register or log in as a patient.
2. Fill out the 11-step case intake questionnaire.
3. Submit the case at Step 11.
4. **Verification**:
   - A new row appears in `public.cases` with `status = 'awaiting_review'`.
   - A matching row appears in `public.case_intake_responses` with the 11 questionnaire answers.
   - An n8n execution log triggers and succeeds.
   - A new row appears in `public.ai_case_summaries` with `generation_status = 'ready'`.

### Test B: Doctor Review, Drafts & Finalization
1. Log in as a verified doctor.
2. Open the newly submitted case in **Doctor Case Review**.
3. **Verification**:
   - The AI Summary card shows the synthesized findings, timeline, and amber decision-support disclaimer.
   - Enter assessment notes and click **Save Draft**.
   - Inspect `public.doctor_assessments`: the row is saved with `is_finalized = false`.
   - Inspect `public.patient_care_notes`: no note is visible to the patient yet.
4. Click **Finalize Review**:
   - `public.doctor_assessments.is_finalized` becomes `true`.
   - `public.cases.status` becomes `'reviewed'`.
   - A new row is automatically created in `public.patient_care_notes`.
   - A notification is inserted into `public.notifications` for the patient.

### Test C: Patient Privacy & RLS Verification
1. Log in as a different patient.
2. Query `public.cases` or `public.patient_care_notes` via the Supabase client:
   - Verify that the other patient's records return 0 rows.
3. Query `public.ai_case_summaries`:
   - Verify that non-doctor users receive an empty result set (RLS blocks patient access).
