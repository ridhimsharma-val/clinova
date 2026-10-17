# Clinova — n8n AI Case Summaries Integration Guide

This guide details the architecture, JSON contract, configuration, and n8n workflow setup for generating AI case summaries in Clinova.

---

## 1. Architecture Overview

```
[Patient Intake 11-Step Questionnaire]
                  │
                  ▼
         [DemoCaseRepository]  (Case saved locally)
                  │
                  ▼
      [AiCaseSummaryRepository]
                  │
    (HTTP POST JSON Webhook Request)
                  │
                  ▼
         ┌──────────────────┐
         │   n8n Workflow   │
         │ (Webhook Trigger)│
         └────────┬─────────┘
                  │
         (Validate Request)
                  │
         (AI Provider Node: OpenAI / Gemini / Anthropic / Ollama)
                  │
         (Validate & Format Output)
                  │
                  ▼
    (HTTP 200 Structured Response)
                  │
                  ▼
      [AiCaseSummaryRepository] (Persisted to SharedPreferences)
                  │
                  ▼
       [Doctor Case Review]  (Executive Clinical Briefing & Timeline)
```

---

## 2. Environment Configuration

The n8n webhook endpoint is fully configurable without embedding any private secrets or API keys in the Flutter client code:

1. **Default Webhook URL**:
   `http://localhost:5678/webhook/clinova-case-summary`

2. **Custom URL via Dart Define**:
   When launching or building the Flutter app, provide your self-hosted or cloud n8n webhook URL:
   ```bash
   flutter run -d chrome --dart-define=CLINOVA_N8N_WEBHOOK_URL=https://n8n.yourclinic.org/webhook/clinova-case-summary
   ```

3. **Runtime Configuration**:
   Use `AiSummaryConfig.runtimeWebhookUrl = 'https://...'` to dynamically adjust the endpoint.

---

## 3. Webhook Request Contract (Clinova -> n8n)

**HTTP Method**: `POST`  
**Headers**: `Content-Type: application/json`, `Accept: application/json`  
**Payload**:

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
  "medicalFamilyHistory": "Non-smoker, no chronic respiratory illnesses in immediate family."
}
```

---

## 4. Webhook Response Contract (n8n -> Clinova)

### Success Response (`HTTP 200 OK`)

```json
{
  "caseId": "case-01",
  "generationStatus": "ready",
  "generatedAt": "2026-10-08T10:30:15.000Z",
  "summaryText": "Patient reports a 4–7 day history of moderate dry cough accompanied by low-grade fever and fatigue, worse at night and in cooler weather. Warm drinks provide slight soothing. No prior occurrences, chronic medical conditions, known allergies, or active medications reported. Family history is negative for chronic respiratory illness.",
  "chiefComplaint": "Persistent Cough & Low Fever",
  "symptomTimelineAndSeverity": "Onset 4–7 days ago; moderate severity; worse at night and in cooler weather.",
  "relevantPositiveFindings": [
    "Dry cough for 4–7 days",
    "Reported low-grade fever",
    "General fatigue",
    "Nocturnal worsening and sensitivity to cooler weather",
    "Warm drinks provide mild symptom relief"
  ],
  "relevantNegativeFindings": [
    "No difficulty breathing reported",
    "No headache, nausea, or dizziness",
    "No prior history of similar episodes",
    "No chronic conditions (hypertension, asthma, diabetes)",
    "No known medication or environmental allergies",
    "No current medications"
  ],
  "medicalHistoryAndMedications": "Non-smoker. No chronic medications. No known drug allergies.",
  "missingOrUnclearInformation": [
    "Exact maximum body temperature measured (if thermometer used)",
    "Presence of sputum or phlegm production",
    "Recent exposure to individuals with acute respiratory illness"
  ]
}
```

### Error Response (`HTTP 400 Bad Request` or `HTTP 500 Internal Error`)

```json
{
  "caseId": "case-01",
  "generationStatus": "failed",
  "errorMessage": "Missing or invalid required field: chiefComplaint"
}
```

---

## 5. How to Import and Run the n8n Workflow

1. Open your n8n instance (local `http://localhost:5678` or cloud).
2. Click **Add workflow** -> **Import from file...**.
3. Select `assets/n8n/clinova_case_summary_workflow.json`.
4. Connect the **AI / LLM Node** to your preferred AI Provider (e.g. OpenAI GPT-4o-mini, Anthropic Claude 3.5 Sonnet, Google Gemini 1.5 Flash, or local Ollama).
5. Add your provider credential securely in n8n's Credential Manager.
6. Toggle the workflow to **Active**.

---

## 6. Safety & Clinical Integrity Guarantees

1. **No Data Fabrication**: The AI summary only synthesizes patient-reported data. It never generates vitals, physical exam findings, definitive diagnoses, or prescriptions.
2. **Explicit Negative Findings**: Negative findings are strictly included only when explicitly denied or absent in the patient's questionnaire answers.
3. **Strict Separation**: The AI summary is completely isolated from doctor-authored assessment notes. Doctor notes are never overwritten.
4. **Resilient Failure Handling**: If n8n is unreachable or fails, the patient's submitted case remains saved and intact. Doctors can retry generation at any time with a single tap.
5. **Patient Privacy**: The AI summary is not automatically exposed to the patient. It serves purely as clinical decision support for the attending physician.
