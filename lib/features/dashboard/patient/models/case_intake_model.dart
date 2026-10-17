import 'case_attachment_model.dart';

class CaseIntakeModel {
  final String reference;
  final int currentStep; // 1 to 12
  final String status; // 'draft' or 'submitted'
  final DateTime createdAt;
  final DateTime lastUpdatedAt;

  // Step 1: Chief Concern / Complaint (required)
  final String chiefConcern;

  // Step 2: Symptom Duration (required single-choice)
  // Options: 'Less than 24 hours', '1–3 days', '4–7 days', '1–2 weeks', 'More than 2 weeks', 'Comes and goes'
  final String? duration;

  // Step 3: Symptom Severity (required single-choice)
  // Options: 'Mild', 'Moderate', 'Severe', 'Very severe'
  final String? severity;

  // Step 4: Associated Symptoms (multi-choice, required)
  // Options: 'Fever', 'Headache', 'Cough', 'Fatigue', 'Nausea or vomiting', 'Dizziness', 'Pain', 'Difficulty breathing', 'Other', 'None of these'
  final List<String> associatedSymptoms;
  final String? otherAssociatedSymptom;

  // Step 5: Symptom Details / Triggers (optional multiline)
  final String? symptomDetails;

  // Step 6: Previous Occurrences (required single-choice: 'Yes', 'No', 'Not sure')
  final String? previousOccurrences;
  final String? previousOccurrenceDetails;

  // Step 7: Existing Medical Conditions (multi-choice)
  // Options: 'None known', 'Diabetes', 'High blood pressure', 'Asthma', 'Heart condition', 'Thyroid condition', 'Other'
  final List<String> existingConditions;
  final String? otherConditionDetails;

  // Step 8: Allergies (multi-choice)
  // Options: 'No known allergies', 'Medicines', 'Food', 'Environmental', 'Other', 'Not sure'
  final List<String> allergies;
  final String? allergyDetails;

  // Step 9: Current Medications (required single-choice: 'Yes', 'No', 'Not sure')
  final String? takesMedications;
  final String? medicationDetails;

  // Step 10: Relevant Medical & Family History (optional multiline)
  final String? medicalFamilyHistory;

  // Step 11: Specific Inquiries & Additional Concerns (optional multiline)
  final String? additionalConcerns;

  // Step 12: Supporting Medical Documents (optional attachments)
  final List<CaseAttachmentModel> attachments;

  const CaseIntakeModel({
    required this.reference,
    this.currentStep = 1,
    this.status = 'draft',
    required this.createdAt,
    required this.lastUpdatedAt,
    this.chiefConcern = '',
    this.duration,
    this.severity,
    this.associatedSymptoms = const [],
    this.otherAssociatedSymptom,
    this.symptomDetails,
    this.previousOccurrences,
    this.previousOccurrenceDetails,
    this.existingConditions = const [],
    this.otherConditionDetails,
    this.allergies = const [],
    this.allergyDetails,
    this.takesMedications,
    this.medicationDetails,
    this.medicalFamilyHistory,
    this.additionalConcerns,
    this.attachments = const [],
  });

  factory CaseIntakeModel.empty({String? reference}) {
    final now = DateTime.now();
    return CaseIntakeModel(
      reference: reference ?? 'CLIN-CASE-${now.millisecondsSinceEpoch.toString().substring(7)}',
      currentStep: 1,
      status: 'draft',
      createdAt: now,
      lastUpdatedAt: now,
      attachments: const [],
    );
  }

  CaseIntakeModel copyWith({
    String? reference,
    int? currentStep,
    String? status,
    DateTime? createdAt,
    DateTime? lastUpdatedAt,
    String? chiefConcern,
    String? duration,
    String? severity,
    List<String>? associatedSymptoms,
    String? otherAssociatedSymptom,
    String? symptomDetails,
    String? previousOccurrences,
    String? previousOccurrenceDetails,
    List<String>? existingConditions,
    String? otherConditionDetails,
    List<String>? allergies,
    String? allergyDetails,
    String? takesMedications,
    String? medicationDetails,
    String? medicalFamilyHistory,
    String? additionalConcerns,
    List<CaseAttachmentModel>? attachments,
  }) {
    return CaseIntakeModel(
      reference: reference ?? this.reference,
      currentStep: currentStep ?? this.currentStep,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastUpdatedAt: lastUpdatedAt ?? DateTime.now(),
      chiefConcern: chiefConcern ?? this.chiefConcern,
      duration: duration ?? this.duration,
      severity: severity ?? this.severity,
      associatedSymptoms: associatedSymptoms ?? this.associatedSymptoms,
      otherAssociatedSymptom: otherAssociatedSymptom ?? this.otherAssociatedSymptom,
      symptomDetails: symptomDetails ?? this.symptomDetails,
      previousOccurrences: previousOccurrences ?? this.previousOccurrences,
      previousOccurrenceDetails: previousOccurrenceDetails ?? this.previousOccurrenceDetails,
      existingConditions: existingConditions ?? this.existingConditions,
      otherConditionDetails: otherConditionDetails ?? this.otherConditionDetails,
      allergies: allergies ?? this.allergies,
      allergyDetails: allergyDetails ?? this.allergyDetails,
      takesMedications: takesMedications ?? this.takesMedications,
      medicationDetails: medicationDetails ?? this.medicationDetails,
      medicalFamilyHistory: medicalFamilyHistory ?? this.medicalFamilyHistory,
      additionalConcerns: additionalConcerns ?? this.additionalConcerns,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toJson() => {
        'reference': reference,
        'currentStep': currentStep,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
        'chiefConcern': chiefConcern,
        'duration': duration,
        'severity': severity,
        'associatedSymptoms': associatedSymptoms,
        'otherAssociatedSymptom': otherAssociatedSymptom,
        'symptomDetails': symptomDetails,
        'previousOccurrences': previousOccurrences,
        'previousOccurrenceDetails': previousOccurrenceDetails,
        'existingConditions': existingConditions,
        'otherConditionDetails': otherConditionDetails,
        'allergies': allergies,
        'allergyDetails': allergyDetails,
        'takesMedications': takesMedications,
        'medicationDetails': medicationDetails,
        'medicalFamilyHistory': medicalFamilyHistory,
        'additionalConcerns': additionalConcerns,
        'attachments': attachments.map((a) => a.toJson()).toList(),
      };

  factory CaseIntakeModel.fromJson(Map<String, dynamic> json) => CaseIntakeModel(
        reference: json['reference'] as String? ?? 'DEMO-CASE-0000',
        currentStep: json['currentStep'] as int? ?? 1,
        status: json['status'] as String? ?? 'draft',
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        lastUpdatedAt: json['lastUpdatedAt'] != null
            ? DateTime.tryParse(json['lastUpdatedAt'] as String) ?? DateTime.now()
            : DateTime.now(),
        chiefConcern: json['chiefConcern'] as String? ?? '',
        duration: json['duration'] as String?,
        severity: json['severity'] as String?,
        associatedSymptoms: (json['associatedSymptoms'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        otherAssociatedSymptom: json['otherAssociatedSymptom'] as String?,
        symptomDetails: json['symptomDetails'] as String?,
        previousOccurrences: json['previousOccurrences'] as String?,
        previousOccurrenceDetails: json['previousOccurrenceDetails'] as String?,
        existingConditions: (json['existingConditions'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        otherConditionDetails: json['otherConditionDetails'] as String?,
        allergies: (json['allergies'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        allergyDetails: json['allergyDetails'] as String?,
        takesMedications: json['takesMedications'] as String?,
        medicationDetails: json['medicationDetails'] as String?,
        medicalFamilyHistory: json['medicalFamilyHistory'] as String?,
        additionalConcerns: json['additionalConcerns'] as String?,
        attachments: (json['attachments'] as List<dynamic>?)
                ?.map((e) => CaseAttachmentModel.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  // Compatibility getters for legacy screens
  String? get onsetChoice => duration;
  String? get onsetDetails => null;
  String get symptomsDescription => chiefConcern;
  String? get patternChoice => null;
  String? get patternDetails => null;
  String? get aggravatingFactors => symptomDetails;
  String? get relievingFactors => null;
  String? get associatedSymptomsDetails => otherAssociatedSymptom;
  String? get hasConditions => existingConditions.isNotEmpty ? existingConditions.join(", ") : null;
  String? get conditionsDetails => otherConditionDetails;
  List<dynamic> get medications => const [];
  String? get hasAllergies => allergies.isNotEmpty ? allergies.join(", ") : null;
  String? get allergiesDetails => allergyDetails;
  String? get medicalHistoryDetails => medicalFamilyHistory;
}
