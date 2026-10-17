import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/config/ai_summary_config.dart';
import '../../patient/services/demo_case_repository.dart';
import '../models/ai_case_summary_model.dart';

/// Clinova AI Case Summary Repository
///
/// Orchestrates AI summary requests to the configured n8n webhook,
/// validates structured responses, and persists case summaries locally.
class AiCaseSummaryRepository {
  AiCaseSummaryRepository._();

  static final AiCaseSummaryRepository instance = AiCaseSummaryRepository._();

  static const String _storageKey = 'clinova_ai_case_summaries_store';

  final Map<String, AiCaseSummaryModel> _summaries = {};
  final StreamController<Map<String, AiCaseSummaryModel>> _summariesController =
      StreamController<Map<String, AiCaseSummaryModel>>.broadcast();

  Stream<Map<String, AiCaseSummaryModel>> get summariesStream =>
      _summariesController.stream;

  Map<String, AiCaseSummaryModel> get summaries =>
      Map.unmodifiable(_summaries);

  /// Initializes repository from SharedPreferences and seeds initial demo summaries
  Future<void> init() async {
    _summaries.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_storageKey);
      if (savedJson != null && savedJson.trim().isNotEmpty) {
        final decoded = jsonDecode(savedJson) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          if (entry.value is Map<String, dynamic>) {
            _summaries[entry.key] = AiCaseSummaryModel.fromJson(
                entry.value as Map<String, dynamic>);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading saved AI summaries: $e');
    }

    // Seed faithful summary for demo case-01 (whose status is 'Summary ready')
    // if no summary is already stored
    _seedDefaultSummariesIfEmpty();

    _summariesController.add(_summaries);
  }

  void _seedDefaultSummariesIfEmpty() {
    if (!_summaries.containsKey('case-01') && !_summaries.containsKey('case-101')) {
      final demoSummary = AiCaseSummaryModel(
        caseId: 'case-01',
        generationStatus: 'ready',
        summaryText:
            'Patient reports a 4–7 day history of moderate dry cough accompanied by low-grade fever and fatigue, worse at night and in cooler weather. Warm drinks provide slight soothing. No prior occurrences, no chronic conditions, no known allergies, and no current medications reported. Family history is negative for chronic respiratory illness.',
        chiefComplaint: 'Persistent Cough & Low Fever',
        symptomTimelineAndSeverity:
            'Onset 4–7 days ago; moderate severity; worse at night and in cooler weather.',
        relevantPositiveFindings: const [
          'Dry cough for 4–7 days',
          'Low-grade fever',
          'Fatigue',
          'Night-time and cool-weather exacerbation',
          'Warm drinks provide mild symptom relief',
        ],
        relevantNegativeFindings: const [
          'No difficulty breathing reported',
          'No headache, nausea, or dizziness',
          'No prior history of similar episodes',
          'No chronic conditions (hypertension, asthma, diabetes)',
          'No known allergies reported',
          'No current medications',
        ],
        medicalHistoryAndMedications:
            'Non-smoker; no chronic medications; no known drug allergies.',
        missingOrUnclearInformation: const [
          'Exact maximum body temperature measured (if thermometer used)',
          'Presence of sputum or phlegm production',
          'Recent exposure to individuals with acute respiratory illness',
        ],
        generatedAt: DateTime(2026, 10, 8, 10, 32),
        lastRequestedAt: DateTime(2026, 10, 8, 10, 30),
      );
      _summaries['case-01'] = demoSummary;
      _summaries['case-101'] = demoSummary;
    }
  }

  /// Get the current AI summary for a case ID
  AiCaseSummaryModel? getSummary(String caseId) {
    if (caseId.trim().isEmpty) return null;
    final normalized = caseId.trim().toLowerCase();
    for (final entry in _summaries.entries) {
      if (entry.key.toLowerCase() == normalized) {
        return entry.value;
      }
    }
    // Handle demo aliases
    if (normalized == 'case-101' && _summaries.containsKey('case-01')) {
      return _summaries['case-01'];
    }
    if (normalized == 'case-01' && _summaries.containsKey('case-101')) {
      return _summaries['case-101'];
    }
    return null;
  }

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  /// Ensures an ID formatted as a valid UUID for database column compatibility.
  static String ensureValidUuid(String id) {
    final clean = id.trim();
    if (_uuidRegex.hasMatch(clean)) {
      return clean.toLowerCase();
    }
    // Existing Supabase case UUID fallback for demo cases
    return '54a7b273-1a7d-4034-83ad-069a09dbc9a0';
  }

  /// Builds the structured payload contract for n8n
  Map<String, dynamic> buildRequestPayload(PatientCaseSummary caseSummary) {
    final intake = caseSummary.fullCase;
    return {
      'caseId': ensureValidUuid(caseSummary.id),
      'originalCaseId': caseSummary.id,
      'caseReference': caseSummary.reference,
      'patientName': caseSummary.patientName ?? '',
      'patientId': caseSummary.patientId ?? '',
      'submissionTimestamp': (caseSummary.submittedAt ?? DateTime.now()).toIso8601String(),
      'chiefComplaint': intake?.chiefConcern.isNotEmpty == true
          ? intake!.chiefConcern
          : caseSummary.title,
      'duration': intake?.duration ?? '',
      'severity': intake?.severity ?? '',
      'associatedSymptoms': intake?.associatedSymptoms ?? const [],
      'otherAssociatedSymptom': intake?.otherAssociatedSymptom,
      'triggersAndRelief': intake?.symptomDetails,
      'previousOccurrences': intake?.previousOccurrences,
      'previousOccurrenceDetails': intake?.previousOccurrenceDetails,
      'existingConditions': intake?.existingConditions ?? const [],
      'otherConditionDetails': intake?.otherConditionDetails,
      'allergies': intake?.allergies ?? const [],
      'allergyDetails': intake?.allergyDetails,
      'takesMedications': intake?.takesMedications,
      'medicationDetails': intake?.medicationDetails,
      'medicalFamilyHistory': intake?.medicalFamilyHistory,
      'specificInquiries': intake?.additionalConcerns,
      'supportingDocuments': intake?.attachments.map((a) => {
        'fileName': a.fileName,
        'fileSizeBytes': a.fileSizeBytes,
        'mimeType': a.mimeType,
        'storagePath': a.storagePath,
      }).toList() ?? const [],
    };
  }

  /// Generates an AI summary for a submitted case via n8n webhook.
  ///
  /// CRITICAL ARCHITECTURAL CONSTRAINTS:
  /// - Case in DemoCaseRepository is NEVER modified or duplicated on error.
  /// - Idempotent: does not re-trigger if summary is already ready or generating, unless forceRetry is true.
  /// - Doctor assessment/notes are NEVER overwritten.
  Future<AiCaseSummaryModel> generateSummaryForCase({
    required PatientCaseSummary caseSummary,
    bool forceRetry = false,
    http.Client? client,
  }) async {
    final caseId = caseSummary.id;

    // Idempotency check: don't re-trigger if already completed or active
    final existing = getSummary(caseId);
    if (!forceRetry && existing != null && (existing.isReady || existing.isGenerating)) {
      return existing;
    }

    // Set status to generating
    final generatingModel = AiCaseSummaryModel.generating(caseId);
    _summaries[caseId] = generatingModel;
    _summariesController.add(_summaries);
    await _persist();

    final httpClient = client ?? http.Client();
    final shouldCloseClient = client == null;

    try {
      final webhookUri = Uri.parse(AiSummaryConfig.webhookUrl);
      final payload = buildRequestPayload(caseSummary);

      final response = await httpClient
          .post(
            webhookUri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(
            const Duration(seconds: AiSummaryConfig.requestTimeoutSeconds),
          );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);

        // Validate response
        final responseCaseId = ((responseJson['caseId'] ?? responseJson['case_id']) as String? ?? '').trim();
        final normalizedTarget = caseId.toLowerCase();
        final normalizedRef = caseSummary.reference.toLowerCase();
        final normalizedResp = responseCaseId.toLowerCase();

        final normalizedUuid = ensureValidUuid(caseId).toLowerCase();

        if (responseCaseId.isNotEmpty &&
            normalizedResp != normalizedTarget &&
            normalizedResp != normalizedRef &&
            normalizedResp != normalizedUuid) {
          throw FormatException(
            "Mismatched case ID in webhook response (expected $caseId, got $responseCaseId)",
          );
        }

        final readySummary = AiCaseSummaryModel.fromJson({
          ...responseJson,
          'caseId': caseId,
          'generationStatus': 'ready',
          'generatedAt': DateTime.now().toIso8601String(),
          'lastRequestedAt': DateTime.now().toIso8601String(),
        });

        _summaries[caseId] = readySummary;
        _summariesController.add(_summaries);
        await _persist();
        return readySummary;
      } else {
        final failedModel = AiCaseSummaryModel.failed(
          caseId,
          "n8n webhook returned HTTP ${response.statusCode}: ${response.body}",
        );
        _summaries[caseId] = failedModel;
        _summariesController.add(_summaries);
        await _persist();
        return failedModel;
      }
    } catch (e) {
      debugPrint("n8n webhook error: $e");
      final failedModel = AiCaseSummaryModel.failed(
        caseId,
        "Could not reach n8n workflow: $e",
      );
      _summaries[caseId] = failedModel;
      _summariesController.add(_summaries);
      await _persist();
      return failedModel;
    } finally {
      if (shouldCloseClient) {
        httpClient.close();
      }
    }
  }

  /// Synthesizes an intelligent, structured clinical summary directly from
  /// the patient's submitted 11-step questionnaire data.
  AiCaseSummaryModel synthesizeIntakeSummary(PatientCaseSummary caseSummary) {
    final intake = caseSummary.fullCase;
    final chief = intake?.chiefConcern.trim().isNotEmpty == true
        ? intake!.chiefConcern.trim()
        : caseSummary.title;
    final duration = intake?.duration ?? 'Not specified';
    final severity = intake?.severity ?? 'Not specified';

    // 1. Positive Findings
    final positiveFindings = <String>[];
    if (chief.isNotEmpty) {
      positiveFindings.add('Chief complaint: $chief');
    }
    if (intake != null) {
      for (final sym in intake.associatedSymptoms) {
        if (sym.toLowerCase() != 'none of these' && sym.toLowerCase() != 'other') {
          positiveFindings.add('Associated symptom: $sym');
        }
      }
      if (intake.otherAssociatedSymptom?.trim().isNotEmpty == true) {
        positiveFindings.add('Additional symptom reported: ${intake.otherAssociatedSymptom!.trim()}');
      }
      if (intake.symptomDetails?.trim().isNotEmpty == true) {
        positiveFindings.add('Aggravating/relieving factors: ${intake.symptomDetails!.trim()}');
      }
      if (intake.previousOccurrences == 'Yes') {
        final details = intake.previousOccurrenceDetails?.trim().isNotEmpty == true
            ? ' (${intake.previousOccurrenceDetails!.trim()})'
            : '';
        positiveFindings.add('Prior occurrences reported$details');
      }
    }

    // 2. Negative Findings (explicitly absent or denied)
    final negativeFindings = <String>[];
    if (intake != null) {
      final associated = intake.associatedSymptoms.map((s) => s.toLowerCase()).toSet();
      const standardSymptoms = [
        'Fever',
        'Headache',
        'Cough',
        'Fatigue',
        'Nausea or vomiting',
        'Dizziness',
        'Difficulty breathing',
      ];
      for (final std in standardSymptoms) {
        if (!associated.contains(std.toLowerCase())) {
          negativeFindings.add('No $std reported');
        }
      }

      if (intake.previousOccurrences == 'No') {
        negativeFindings.add('No prior history of similar episodes');
      }

      final conditions = intake.existingConditions.map((c) => c.toLowerCase()).toList();
      if (conditions.contains('none known') || intake.existingConditions.isEmpty) {
        negativeFindings.add('No chronic conditions (hypertension, asthma, diabetes)');
      }

      final allergies = intake.allergies.map((a) => a.toLowerCase()).toList();
      if (allergies.contains('no known allergies') || intake.allergies.isEmpty) {
        negativeFindings.add('No known drug or environmental allergies');
      }

      if (intake.takesMedications == 'No') {
        negativeFindings.add('No current daily medications reported');
      }
    } else {
      negativeFindings.add('No prior occurrences recorded');
      negativeFindings.add('No chronic conditions reported');
    }

    // 3. Medical History & Medications
    final historyParts = <String>[];
    if (intake != null) {
      if (intake.existingConditions.isNotEmpty &&
          !intake.existingConditions.any((c) => c.toLowerCase() == 'none known')) {
        var conds = intake.existingConditions.join(', ');
        if (intake.otherConditionDetails?.trim().isNotEmpty == true) {
          conds += ' (${intake.otherConditionDetails!.trim()})';
        }
        historyParts.add('Chronic conditions: $conds');
      } else {
        historyParts.add('No chronic medical conditions');
      }

      if (intake.allergies.isNotEmpty &&
          !intake.allergies.any((a) => a.toLowerCase() == 'no known allergies')) {
        var algs = intake.allergies.join(', ');
        if (intake.allergyDetails?.trim().isNotEmpty == true) {
          algs += ' (${intake.allergyDetails!.trim()})';
        }
        historyParts.add('Allergies: $algs');
      } else {
        historyParts.add('No known allergies');
      }

      if (intake.takesMedications == 'Yes' &&
          intake.medicationDetails?.trim().isNotEmpty == true) {
        historyParts.add('Medications: ${intake.medicationDetails!.trim()}');
      } else if (intake.takesMedications == 'No') {
        historyParts.add('Current medications: None reported');
      }

      if (intake.medicalFamilyHistory?.trim().isNotEmpty == true) {
        historyParts.add('Family/Medical history: ${intake.medicalFamilyHistory!.trim()}');
      }
    } else {
      historyParts.add('No chronic medical conditions reported');
      historyParts.add('No known allergies');
      historyParts.add('Current medications: None reported');
    }
    final medicalHistory = '${historyParts.join('; ')}.';

    // 4. Missing or Unclear Points
    final missingPoints = <String>[];
    if (intake?.symptomDetails == null || intake!.symptomDetails!.trim().isEmpty) {
      missingPoints.add('Specific triggers, relief measures, or diurnal variation');
    }
    if (intake?.medicalFamilyHistory == null || intake!.medicalFamilyHistory!.trim().isEmpty) {
      missingPoints.add('Detailed family medical history');
    }
    if (intake?.takesMedications == 'Not sure') {
      missingPoints.add('Confirmation of current active medications');
    }
    if (intake?.allergies.any((a) => a.toLowerCase() == 'not sure') == true) {
      missingPoints.add('Clarification on possible medication/environmental allergies');
    }

    // 5. Executive Summary Text
    final findingsPrefix = positiveFindings.isNotEmpty
        ? 'Key reported findings include: ${positiveFindings.take(4).join(", ")}. '
        : '';
    final summaryText =
        'Patient presents with "$chief" of $duration duration with $severity severity. $findingsPrefix$medicalHistory Physician clinical review and verification recommended.';

    final timelineSeverity = 'Onset $duration ago; $severity severity.';

    return AiCaseSummaryModel(
      caseId: caseSummary.id,
      generationStatus: 'ready',
      summaryText: summaryText,
      chiefComplaint: chief,
      symptomTimelineAndSeverity: timelineSeverity,
      relevantPositiveFindings: positiveFindings,
      relevantNegativeFindings: negativeFindings,
      medicalHistoryAndMedications: medicalHistory,
      missingOrUnclearInformation: missingPoints,
      generatedAt: DateTime.now(),
      lastRequestedAt: DateTime.now(),
    );
  }

  /// Retries summary generation for a failed case
  Future<AiCaseSummaryModel> retryGeneration(
    PatientCaseSummary caseSummary, {
    http.Client? client,
  }) {
    return generateSummaryForCase(
      caseSummary: caseSummary,
      forceRetry: true,
      client: client,
    );
  }

  /// Saves a summary directly (used for seeding, testing, or mock updates)
  Future<void> saveSummary(AiCaseSummaryModel summary) async {
    _summaries[summary.caseId] = summary;
    _summariesController.add(_summaries);
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapToSave = _summaries.map(
        (key, value) => MapEntry(key, value.toJson()),
      );
      await prefs.setString(_storageKey, jsonEncode(mapToSave));
    } catch (e) {
      debugPrint('Error saving AI case summaries: $e');
    }
  }

  /// Clears all stored summaries (used for testing isolation)
  Future<void> clearAll() async {
    _summaries.clear();
    _summariesController.add(_summaries);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }
}
