/// Clinova AI Case Summary Model
///
/// Encapsulates structured clinical case summaries generated via n8n workflow.
/// Designed exclusively as physician decision-support material.
class AiCaseSummaryModel {
  final String caseId;
  final String generationStatus; // 'ready', 'generating', 'pending', 'failed'
  final String summaryText;
  final String chiefComplaint;
  final String symptomTimelineAndSeverity;
  final List<String> relevantPositiveFindings;
  final List<String> relevantNegativeFindings;
  final String medicalHistoryAndMedications;
  final List<String> missingOrUnclearInformation;
  final String? errorMessage;
  final DateTime? generatedAt;
  final DateTime lastRequestedAt;

  const AiCaseSummaryModel({
    required this.caseId,
    required this.generationStatus,
    this.summaryText = '',
    this.chiefComplaint = '',
    this.symptomTimelineAndSeverity = '',
    this.relevantPositiveFindings = const [],
    this.relevantNegativeFindings = const [],
    this.medicalHistoryAndMedications = '',
    this.missingOrUnclearInformation = const [],
    this.errorMessage,
    this.generatedAt,
    required this.lastRequestedAt,
  });

  bool get isReady => generationStatus.toLowerCase() == 'ready';
  bool get isGenerating => generationStatus.toLowerCase() == 'generating';
  bool get isFailed => generationStatus.toLowerCase() == 'failed';
  bool get isPending => generationStatus.toLowerCase() == 'pending';

  AiCaseSummaryModel copyWith({
    String? caseId,
    String? generationStatus,
    String? summaryText,
    String? chiefComplaint,
    String? symptomTimelineAndSeverity,
    List<String>? relevantPositiveFindings,
    List<String>? relevantNegativeFindings,
    String? medicalHistoryAndMedications,
    List<String>? missingOrUnclearInformation,
    String? errorMessage,
    DateTime? generatedAt,
    DateTime? lastRequestedAt,
  }) {
    return AiCaseSummaryModel(
      caseId: caseId ?? this.caseId,
      generationStatus: generationStatus ?? this.generationStatus,
      summaryText: summaryText ?? this.summaryText,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      symptomTimelineAndSeverity:
          symptomTimelineAndSeverity ?? this.symptomTimelineAndSeverity,
      relevantPositiveFindings:
          relevantPositiveFindings ?? this.relevantPositiveFindings,
      relevantNegativeFindings:
          relevantNegativeFindings ?? this.relevantNegativeFindings,
      medicalHistoryAndMedications:
          medicalHistoryAndMedications ?? this.medicalHistoryAndMedications,
      missingOrUnclearInformation:
          missingOrUnclearInformation ?? this.missingOrUnclearInformation,
      errorMessage: errorMessage ?? this.errorMessage,
      generatedAt: generatedAt ?? this.generatedAt,
      lastRequestedAt: lastRequestedAt ?? this.lastRequestedAt,
    );
  }

  factory AiCaseSummaryModel.pending(String caseId) {
    return AiCaseSummaryModel(
      caseId: caseId,
      generationStatus: 'pending',
      lastRequestedAt: DateTime.now(),
    );
  }

  factory AiCaseSummaryModel.generating(String caseId) {
    return AiCaseSummaryModel(
      caseId: caseId,
      generationStatus: 'generating',
      lastRequestedAt: DateTime.now(),
    );
  }

  factory AiCaseSummaryModel.failed(String caseId, String errorMessage) {
    return AiCaseSummaryModel(
      caseId: caseId,
      generationStatus: 'failed',
      errorMessage: errorMessage,
      lastRequestedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'caseId': caseId,
        'generationStatus': generationStatus,
        'summaryText': summaryText,
        'chiefComplaint': chiefComplaint,
        'symptomTimelineAndSeverity': symptomTimelineAndSeverity,
        'relevantPositiveFindings': relevantPositiveFindings,
        'relevantNegativeFindings': relevantNegativeFindings,
        'medicalHistoryAndMedications': medicalHistoryAndMedications,
        'missingOrUnclearInformation': missingOrUnclearInformation,
        'errorMessage': errorMessage,
        'generatedAt': generatedAt?.toIso8601String(),
        'lastRequestedAt': lastRequestedAt.toIso8601String(),
      };

  factory AiCaseSummaryModel.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
      } else if (value is String && value.trim().isNotEmpty) {
        return [value.trim()];
      }
      return const [];
    }

    return AiCaseSummaryModel(
      caseId: (json['caseId'] ?? json['case_id']) as String? ?? '',
      generationStatus: (json['generationStatus'] ?? json['generation_status']) as String? ?? 'ready',
      summaryText: (json['summaryText'] ?? json['summary_text']) as String? ?? '',
      chiefComplaint: (json['chiefComplaint'] ?? json['chief_complaint']) as String? ?? '',
      symptomTimelineAndSeverity:
          (json['symptomTimelineAndSeverity'] ?? json['symptom_timeline_and_severity']) as String? ?? '',
      relevantPositiveFindings:
          parseStringList(json['relevantPositiveFindings'] ?? json['relevant_positive_findings']),
      relevantNegativeFindings:
          parseStringList(json['relevantNegativeFindings'] ?? json['relevant_negative_findings']),
      medicalHistoryAndMedications:
          (json['medicalHistoryAndMedications'] ?? json['medical_history_and_medications']) as String? ?? '',
      missingOrUnclearInformation:
          parseStringList(json['missingOrUnclearInformation'] ?? json['missing_or_unclear_information']),
      errorMessage: (json['errorMessage'] ?? json['error_message']) as String?,
      generatedAt: (json['generatedAt'] ?? json['generated_at']) != null
          ? DateTime.tryParse((json['generatedAt'] ?? json['generated_at']) as String)
          : null,
      lastRequestedAt: (json['lastRequestedAt'] ?? json['last_requested_at']) != null
          ? DateTime.tryParse((json['lastRequestedAt'] ?? json['last_requested_at']) as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
