# CLINOVA — n8n WORKFLOW IMPLEMENTATION & CONFIGURATION GUIDE

**Workflow File**: `clinova_ai_case_summary_workflow.json`  
**Target Environment**: n8n (Self-hosted Docker, Cloud, or Desktop)  
**Database Target**: Supabase Managed PostgreSQL (`public.ai_case_summaries`)  
**Client Consumer**: Clinova Flutter Client (`AiCaseSummaryRepository`)  

---

## 1. Workflow Architecture & Node-by-Node Breakdown

```
[Flutter App / Backend Service]
              │
              ▼ (POST HTTP Request)
    ┌───────────────────────────┐
    │ 1. Webhook Trigger Node   │ Path: /webhook/clinova-case-summary
    └─────────────┬─────────────┘
                  │
                  ▼
    ┌───────────────────────────┐
    │ 2. Validate Request Node  │ Checks caseId, chiefComplaint, array fields
    └─────────────┬─────────────┘
                  │
                  ▼
    ┌───────────────────────────┐
    │ 3. Is Request Valid? (IF) ├──────────────┐ (Invalid)
    └─────────────┬─────────────┘              │
                  │ (Valid)                    ▼
                  │              ┌───────────────────────────┐
                  │              │ 4. Respond 400 Bad Request│
                  │              └───────────────────────────┘
                  ▼
    ┌───────────────────────────┐
    │ 5. Synthesize Summary     │ Extracts positive/negative findings,
    │    (Clinical AI Synthesis)│ timeline, and clarification questions
    └─────────────┬─────────────┘
                  │
                  ▼
    ┌───────────────────────────┐
    │ 6. Persist to Supabase    │ Upsert into public.ai_case_summaries
    └─────────────┬─────────────┘
                  │
                  ▼
    ┌───────────────────────────┐
    │ 7. Respond 200 OK         │ Returns structured JSON to Flutter
    └───────────────────────────┘
```

### Detailed Node Specifications

| Node Name | Node Type | Purpose & Logic |
|---|---|---|
| **Webhook Trigger** | `n8n-nodes-base.webhook` | Receives incoming HTTP POST requests from the Clinova application at path `clinova-case-summary`. Configured with `responseMode: "responseNode"` to allow downstream validation nodes to return customized HTTP status codes (200, 400, 500). |
| **Validate Request Payload** | `n8n-nodes-base.code` | Validates that `caseId` and `chiefComplaint` are non-empty strings. Normalizes arrays (`associatedSymptoms`, `existingConditions`, `allergies`). Guards against missing properties. |
| **Is Request Valid?** | `n8n-nodes-base.if` | Evaluates `$json.isValid === true`. Routes valid payloads to clinical processing and invalid payloads directly to the 400 error responder. |
| **Respond Bad Request (400)** | `n8n-nodes-base.respondToWebhook` | Returns HTTP 400 with `{ caseId, generationStatus: 'failed', errorMessage }`. |
| **Synthesize Clinical Summary** | `n8n-nodes-base.code` (or AI Provider) | Formulates patient-supported positive findings, strictly patient-supported negative findings, timeline narrative, and consultation clarification questions. Adds mandatory disclaimer. |
| **Persist Summary to Supabase** | `n8n-nodes-base.supabase` | Performs an idempotent `upsert` into `public.ai_case_summaries` on `case_id`. Ensures the database is updated with the synthesized briefing. |
| **Respond Success (200)** | `n8n-nodes-base.respondToWebhook` | Transmits the final structured JSON payload back to Clinova, satisfying `AiCaseSummaryModel.fromJson()`. |

---

## 2. Payload Contracts

### 2.1 Webhook Request Schema (Clinova Flutter -> n8n)
Matches `AiCaseSummaryRepository.buildRequestPayload()`:

```json
{
  "caseId": "case-01",
  "caseReference": "DEMO-CASE-8842",
  "patientName": "Aarav Sharma",
  "patientId": "PAT-8842",
  "submissionTimestamp": "2026-10-08T10:30:00.000Z",
  "chiefComplaint": "Persistent Cough & Low Fever",
  "duration": "4–7 days",
  "severity": "Moderate",
  "associatedSymptoms": [
    "Cough",
    "Fever",
    "Fatigue"
  ],
  "otherAssociatedSymptom": null,
  "triggersAndRelief": "Worse at night and in cooler weather. Warm drinks provide slight soothing.",
  "previousOccurrences": "No",
  "previousOccurrenceDetails": null,
  "existingConditions": [
    "None known"
  ],
  "otherConditionDetails": null,
  "allergies": [
    "No known allergies"
  ],
  "allergyDetails": null,
  "takesMedications": "No",
  "medicationDetails": null,
  "medicalFamilyHistory": "No chronic respiratory illnesses reported."
}
```

### 2.2 Webhook Response Schema (n8n -> Clinova Flutter)
Matches `AiCaseSummaryModel.fromJson()`:

```json
{
  "caseId": "case-01",
  "generationStatus": "ready",
  "generatedAt": "2026-10-08T10:30:15.000Z",
  "summaryText": "Patient presents with Persistent Cough & Low Fever (duration: 4–7 days, severity: Moderate). Associated symptoms reported: Cough, Fever, Fatigue. Triggers / relieving factors: Worse at night and in cooler weather. Warm drinks provide slight soothing. Medical history: None known; Allergies: No known allergies; Medications: None reported.",
  "chiefComplaint": "Persistent Cough & Low Fever",
  "symptomTimelineAndSeverity": "Onset: 4–7 days; Severity: Moderate.",
  "relevantPositiveFindings": [
    "Persistent Cough & Low Fever",
    "Cough",
    "Fever",
    "Fatigue",
    "Triggers/Relief: Worse at night and in cooler weather. Warm drinks provide slight soothing."
  ],
  "relevantNegativeFindings": [
    "No prior history of similar episodes reported",
    "No chronic pre-existing medical conditions reported",
    "No known medication or environmental allergies reported",
    "No active prescription or OTC medications reported"
  ],
  "medicalHistoryAndMedications": "Conditions: None known. Allergies: No known allergies. Meds: None. Family History: No chronic respiratory illnesses reported.",
  "missingOrUnclearInformation": [
    "Clarify precise onset date and progression of symptoms",
    "Assess quantitative severity score and impact on daily routines"
  ],
  "disclaimer": "AI-generated summary — requires physician review. Not a diagnosis or prescription."
}
```

---

## 3. How to Import and Configure in n8n

### Step 1: Import Workflow File
1. Open your n8n workspace (e.g. `http://localhost:5678` or hosted cloud instance).
2. Click the **Workflows** menu -> **Add Workflow**.
3. In the top right overflow menu (`...`), select **Import from File...**.
4. Choose `clinova_ai_case_summary_workflow.json` from your project directory.

### Step 2: Configure Supabase Credentials
1. In n8n, navigate to **Credentials** -> **New Credential** -> Select **Supabase**.
2. Enter the configuration values (to be supplied when your Supabase project is created):
   - **Host / URL**: `https://<YOUR-PROJECT-REF>.supabase.co`
   - **Service Role Secret**: Your private `service_role` key (Required for server-side persistence into `public.ai_case_summaries`).
3. Save the credential as `Clinova Supabase Admin`.
4. Open the **Persist Summary to Supabase** node in the workflow canvas and link this credential.

### Step 3 (Optional): Connect External LLM Provider
If you want to use an LLM provider (such as OpenAI GPT-4o-mini, Anthropic Claude 3.5 Sonnet, or Google Gemini 1.5 Flash) instead of the built-in deterministic clinical parser:
1. Drag the corresponding LangChain or Provider Model node onto the canvas.
2. Provide your AI Provider API key in n8n Credential Manager.
3. Feed the validated prompt from the **Validate Request Payload** node into the model.
4. Ensure the output parser outputs the exact schema defined in Section 2.2.

### Step 4: Activate the Workflow
Toggle the workflow from **Inactive** to **Active** in the top right header.

---

## 4. Testing with Synthetic Clinical Data

You can verify the workflow using `curl` or Postman without opening the Flutter app:

```bash
curl -X POST "http://localhost:5678/webhook/clinova-case-summary" \
  -H "Content-Type: application/json" \
  -d '{
    "caseId": "TEST-CASE-99",
    "caseReference": "REF-99",
    "patientName": "Synthetic Test Patient",
    "patientId": "PAT-99",
    "chiefComplaint": "Acute migraine with visual aura",
    "duration": "1–3 days",
    "severity": "Severe",
    "associatedSymptoms": ["Headache", "Nausea or vomiting"],
    "existingConditions": ["None known"],
    "allergies": ["No known allergies"],
    "takesMedications": "No"
  }'
```

### Expected Test Result
- HTTP status: `200 OK`.
- JSON body containing `generationStatus: "ready"`, populated `relevantPositiveFindings`, and patient-verified `relevantNegativeFindings`.
- A matching row exists in `public.ai_case_summaries` with `case_id = 'TEST-CASE-99'`.

---

## 5. Clinical Safety & Error Guarantees

1. **Idempotent Upserts**: Repeated requests for the same `caseId` update the existing summary row without creating orphan duplicate records.
2. **Failure Isolation**: If an LLM or network timeout occurs, n8n responds with a descriptive error. The patient's submitted case in `public.cases` remains completely unharmed.
3. **No Clinical Overwriting**: The workflow touches **only** `public.ai_case_summaries`. It has no permissions or mechanisms to modify `public.doctor_assessments` or `public.patient_care_notes`.
4. **Physician Disclaimer**: Every generated payload includes the immutable disclaimer banner:  
   *"AI-generated summary — requires physician review. Not a diagnosis or prescription."*
