/// Clinova Doctor Assessment and Supervised Notes Model
///
/// Contains clinical assessment, observations, recommendations, follow-up instructions,
/// and follow-up date authored by the attending physician for a specific case.
class DoctorAssessmentModel {
  final String caseId;
  final String doctorName;
  final String clinicalAssessment;
  final String prescription;
  final String observations;
  final String adviceAndRecommendations;
  final String followUpInstructions;
  final DateTime? followUpDate;
  final bool isFinalized;
  final DateTime? finalizedAt;
  final DateTime lastSavedAt;

  const DoctorAssessmentModel({
    required this.caseId,
    required this.doctorName,
    this.clinicalAssessment = '',
    this.prescription = '',
    this.observations = '',
    this.adviceAndRecommendations = '',
    this.followUpInstructions = '',
    this.followUpDate,
    this.isFinalized = false,
    this.finalizedAt,
    required this.lastSavedAt,
  });

  bool get isEmpty =>
      clinicalAssessment.trim().isEmpty &&
      prescription.trim().isEmpty &&
      observations.trim().isEmpty &&
      adviceAndRecommendations.trim().isEmpty &&
      followUpInstructions.trim().isEmpty &&
      followUpDate == null;

  bool get isNotEmpty => !isEmpty;

  DoctorAssessmentModel copyWith({
    String? caseId,
    String? doctorName,
    String? clinicalAssessment,
    String? prescription,
    String? observations,
    String? adviceAndRecommendations,
    String? followUpInstructions,
    DateTime? followUpDate,
    bool? isFinalized,
    DateTime? finalizedAt,
    DateTime? lastSavedAt,
  }) {
    return DoctorAssessmentModel(
      caseId: caseId ?? this.caseId,
      doctorName: doctorName ?? this.doctorName,
      clinicalAssessment: clinicalAssessment ?? this.clinicalAssessment,
      prescription: prescription ?? this.prescription,
      observations: observations ?? this.observations,
      adviceAndRecommendations:
          adviceAndRecommendations ?? this.adviceAndRecommendations,
      followUpInstructions:
          followUpInstructions ?? this.followUpInstructions,
      followUpDate: followUpDate ?? this.followUpDate,
      isFinalized: isFinalized ?? this.isFinalized,
      finalizedAt: finalizedAt ?? this.finalizedAt,
      lastSavedAt: lastSavedAt ?? this.lastSavedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'caseId': caseId,
        'doctorName': doctorName,
        'clinicalAssessment': clinicalAssessment,
        'prescription': prescription,
        'observations': observations,
        'adviceAndRecommendations': adviceAndRecommendations,
        'followUpInstructions': followUpInstructions,
        'followUpDate': followUpDate?.toIso8601String(),
        'isFinalized': isFinalized,
        'finalizedAt': finalizedAt?.toIso8601String(),
        'lastSavedAt': lastSavedAt.toIso8601String(),
      };

  factory DoctorAssessmentModel.fromJson(Map<String, dynamic> json) =>
      DoctorAssessmentModel(
        caseId: json['caseId'] as String? ?? '',
        doctorName: json['doctorName'] as String? ?? '',
        clinicalAssessment: json['clinicalAssessment'] as String? ?? '',
        prescription: json['prescription'] as String? ?? '',
        observations: json['observations'] as String? ?? '',
        adviceAndRecommendations:
            json['adviceAndRecommendations'] as String? ?? '',
        followUpInstructions: json['followUpInstructions'] as String? ?? '',
        followUpDate: json['followUpDate'] != null
            ? DateTime.tryParse(json['followUpDate'] as String)
            : null,
        isFinalized: json['isFinalized'] as bool? ?? false,
        finalizedAt: json['finalizedAt'] != null
            ? DateTime.tryParse(json['finalizedAt'] as String)
            : null,
        lastSavedAt: json['lastSavedAt'] != null
            ? DateTime.tryParse(json['lastSavedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}
