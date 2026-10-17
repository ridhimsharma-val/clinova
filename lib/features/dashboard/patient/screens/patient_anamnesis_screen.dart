import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/clinova_colors.dart';
import '../../../../core/routing/app_routes.dart';
import '../models/patient_profile_model.dart';
import '../services/patient_profile_repository.dart';

/// Clinical Medical History Data Model for Anamnesis
class AnamnesisData {
  final String conditions;
  final String allergies;
  final String medications;
  final String pastMedicalHistory;
  final String surgicalHistory;
  final String familyHistory;
  final String lifestyle;
  final String additionalNotes;

  const AnamnesisData({
    required this.conditions,
    required this.allergies,
    required this.medications,
    required this.pastMedicalHistory,
    required this.surgicalHistory,
    required this.familyHistory,
    required this.lifestyle,
    required this.additionalNotes,
  });

  /// Default realistic sample records (demo placeholders)
  static const defaultSample = AnamnesisData(
    conditions: "No known chronic conditions reported",
    allergies: "No known allergies reported",
    medications: "No regular medications reported",
    pastMedicalHistory: "No significant past medical history reported",
    surgicalHistory: "No previous surgeries reported",
    familyHistory: "Sample entry — family history needs confirmation",
    lifestyle: "Sample entry — lifestyle details need confirmation",
    additionalNotes: "No additional notes provided",
  );

  Map<String, dynamic> toJson() => {
        'conditions': conditions,
        'allergies': allergies,
        'medications': medications,
        'pastMedicalHistory': pastMedicalHistory,
        'surgicalHistory': surgicalHistory,
        'familyHistory': familyHistory,
        'lifestyle': lifestyle,
        'additionalNotes': additionalNotes,
      };

  factory AnamnesisData.fromJson(Map<String, dynamic> json) => AnamnesisData(
        conditions: json['conditions'] as String? ?? defaultSample.conditions,
        allergies: json['allergies'] as String? ?? defaultSample.allergies,
        medications: json['medications'] as String? ?? defaultSample.medications,
        pastMedicalHistory:
            json['pastMedicalHistory'] as String? ?? defaultSample.pastMedicalHistory,
        surgicalHistory:
            json['surgicalHistory'] as String? ?? defaultSample.surgicalHistory,
        familyHistory:
            json['familyHistory'] as String? ?? defaultSample.familyHistory,
        lifestyle: json['lifestyle'] as String? ?? defaultSample.lifestyle,
        additionalNotes:
            json['additionalNotes'] as String? ?? defaultSample.additionalNotes,
      );

  AnamnesisData copyWith({
    String? conditions,
    String? allergies,
    String? medications,
    String? pastMedicalHistory,
    String? surgicalHistory,
    String? familyHistory,
    String? lifestyle,
    String? additionalNotes,
  }) {
    return AnamnesisData(
      conditions: conditions ?? this.conditions,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      pastMedicalHistory: pastMedicalHistory ?? this.pastMedicalHistory,
      surgicalHistory: surgicalHistory ?? this.surgicalHistory,
      familyHistory: familyHistory ?? this.familyHistory,
      lifestyle: lifestyle ?? this.lifestyle,
      additionalNotes: additionalNotes ?? this.additionalNotes,
    );
  }
}

/// Clinova Anamnesis (Patient Medical History) Screen
///
/// Displays populated medical history records (with a clear "Demo data — please verify" indicator)
/// and supports explicit Edit, Save Changes, and Cancel actions following Clinova's design patterns.
class PatientAnamnesisScreen extends StatefulWidget {
  const PatientAnamnesisScreen({super.key});

  static const String storageKey = 'clinova_saved_anamnesis_data';

  @override
  State<PatientAnamnesisScreen> createState() => _PatientAnamnesisScreenState();
}

class _PatientAnamnesisScreenState extends State<PatientAnamnesisScreen> {
  bool _isEditing = false;
  AnamnesisData _savedData = AnamnesisData.defaultSample;

  late final TextEditingController _conditionsController;
  late final TextEditingController _allergiesController;
  late final TextEditingController _medicationsController;
  late final TextEditingController _pastMedicalHistoryController;
  late final TextEditingController _surgicalHistoryController;
  late final TextEditingController _familyHistoryController;
  late final TextEditingController _lifestyleController;
  late final TextEditingController _additionalNotesController;

  @override
  void initState() {
    super.initState();
    _conditionsController = TextEditingController();
    _allergiesController = TextEditingController();
    _medicationsController = TextEditingController();
    _pastMedicalHistoryController = TextEditingController();
    _surgicalHistoryController = TextEditingController();
    _familyHistoryController = TextEditingController();
    _lifestyleController = TextEditingController();
    _additionalNotesController = TextEditingController();

    _loadAnamnesisData();
  }

  @override
  void dispose() {
    _conditionsController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    _pastMedicalHistoryController.dispose();
    _surgicalHistoryController.dispose();
    _familyHistoryController.dispose();
    _lifestyleController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadAnamnesisData() async {
    final profile = PatientProfileRepository.instance.profile;
    _savedData = AnamnesisData(
      conditions: profile.conditions ?? AnamnesisData.defaultSample.conditions,
      allergies: profile.allergies ?? AnamnesisData.defaultSample.allergies,
      medications: profile.medications ?? AnamnesisData.defaultSample.medications,
      pastMedicalHistory:
          profile.pastMedicalHistory ?? AnamnesisData.defaultSample.pastMedicalHistory,
      surgicalHistory:
          profile.surgicalHistory ?? AnamnesisData.defaultSample.surgicalHistory,
      familyHistory:
          profile.familyHistory ?? AnamnesisData.defaultSample.familyHistory,
      lifestyle: profile.lifestyle ?? AnamnesisData.defaultSample.lifestyle,
      additionalNotes:
          profile.additionalNotes ?? AnamnesisData.defaultSample.additionalNotes,
    );

    _syncControllersFromSaved();
    if (mounted) setState(() {});
  }

  void _syncControllersFromSaved() {
    _conditionsController.text = _savedData.conditions;
    _allergiesController.text = _savedData.allergies;
    _medicationsController.text = _savedData.medications;
    _pastMedicalHistoryController.text = _savedData.pastMedicalHistory;
    _surgicalHistoryController.text = _savedData.surgicalHistory;
    _familyHistoryController.text = _savedData.familyHistory;
    _lifestyleController.text = _savedData.lifestyle;
    _additionalNotesController.text = _savedData.additionalNotes;
  }

  void _startEditing() {
    _loadAnamnesisData();
    setState(() {
      _isEditing = true;
    });
  }

  void _cancelEditing() {
    _loadAnamnesisData();
    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF5A756B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: const Text("Unsaved changes discarded."),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveMedicalHistory() async {
    final updated = AnamnesisData(
      conditions: _conditionsController.text.trim().isNotEmpty
          ? _conditionsController.text.trim()
          : AnamnesisData.defaultSample.conditions,
      allergies: _allergiesController.text.trim().isNotEmpty
          ? _allergiesController.text.trim()
          : AnamnesisData.defaultSample.allergies,
      medications: _medicationsController.text.trim().isNotEmpty
          ? _medicationsController.text.trim()
          : AnamnesisData.defaultSample.medications,
      pastMedicalHistory: _pastMedicalHistoryController.text.trim().isNotEmpty
          ? _pastMedicalHistoryController.text.trim()
          : AnamnesisData.defaultSample.pastMedicalHistory,
      surgicalHistory: _surgicalHistoryController.text.trim().isNotEmpty
          ? _surgicalHistoryController.text.trim()
          : AnamnesisData.defaultSample.surgicalHistory,
      familyHistory: _familyHistoryController.text.trim().isNotEmpty
          ? _familyHistoryController.text.trim()
          : AnamnesisData.defaultSample.familyHistory,
      lifestyle: _lifestyleController.text.trim().isNotEmpty
          ? _lifestyleController.text.trim()
          : AnamnesisData.defaultSample.lifestyle,
      additionalNotes: _additionalNotesController.text.trim().isNotEmpty
          ? _additionalNotesController.text.trim()
          : AnamnesisData.defaultSample.additionalNotes,
    );

    _savedData = updated;

    await PatientProfileRepository.instance.saveAnamnesis(
      conditions: updated.conditions,
      allergies: updated.allergies,
      medications: updated.medications,
      pastMedicalHistory: updated.pastMedicalHistory,
      surgicalHistory: updated.surgicalHistory,
      familyHistory: updated.familyHistory,
      lifestyle: updated.lifestyle,
      additionalNotes: updated.additionalNotes,
    );

    setState(() {
      _isEditing = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF28654F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text("Medical history saved successfully."),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _displayValue(String? value, {String fallback = "Not provided"}) {
    if (value == null || value.trim().isEmpty) return fallback;
    return value.trim();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;

    return StreamBuilder<PatientProfileModel>(
      stream: PatientProfileRepository.instance.profileStream,
      initialData: PatientProfileRepository.instance.profile,
      builder: (context, profileSnapshot) {
        final profile =
            profileSnapshot.data ?? PatientProfileRepository.instance.profile;

        return Scaffold(
          backgroundColor: ClinovaColors.background,
          appBar: AppBar(
            backgroundColor: ClinovaColors.background,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E5D46)),
              tooltip: "Back to Dashboard",
              onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  Navigator.of(context).pushReplacementNamed(AppRoutes.patientDashboard);
                }
              },
            ),
            title: const Text(
              "Anamnesis",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF19372B),
                letterSpacing: -0.2,
              ),
            ),
            actions: [
              if (!_isEditing)
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Center(
                    child: OutlinedButton.icon(
                      onPressed: _startEditing,
                      icon: const Icon(Icons.edit_outlined, size: 15, color: Color(0xFF28654F)),
                      label: const Text(
                        "Edit",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF28654F),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFFE7F0E9),
                        side: const BorderSide(color: Color(0xFFCCE0D4)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: _cancelEditing,
                        child: const Text(
                          "Cancel",
                          style: TextStyle(
                            color: Color(0xFF5A756B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      ElevatedButton(
                        onPressed: _saveMedicalHistory,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF28654F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Save",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : 18,
                  vertical: isDesktop ? 24 : 16,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 880),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header Card with Avatar, Summary Badges, and Medical History Title
                      _buildHeaderCard(context, profile, isDesktop),
                      const SizedBox(height: 12),

                      // Subtle Demo Data / Confirmed Record Banner
                      _buildDemoDataIndicatorBanner(isCustomized: profile.isAnamnesisCustomized),
                      const SizedBox(height: 14),

                      // Section Cards: 2-column on desktop, single column on mobile
                      if (isDesktop) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildConditionsCard(isDesktop, profile)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildAllergiesCard(isDesktop, profile)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildMedicationsCard(isDesktop, profile)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildPastMedicalHistoryCard(isDesktop, profile)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildSurgicalHistoryCard(isDesktop, profile)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildFamilyHistoryCard(isDesktop, profile)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildLifestyleCard(isDesktop, profile)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildAdditionalNotesCard(isDesktop, profile)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildEmergencyContactCard(profile, isDesktop),
                      ] else ...[
                        _buildConditionsCard(isDesktop, profile),
                        const SizedBox(height: 14),
                        _buildAllergiesCard(isDesktop, profile),
                        const SizedBox(height: 14),
                        _buildMedicationsCard(isDesktop, profile),
                        const SizedBox(height: 14),
                        _buildPastMedicalHistoryCard(isDesktop, profile),
                        const SizedBox(height: 14),
                        _buildSurgicalHistoryCard(isDesktop, profile),
                        const SizedBox(height: 14),
                        _buildFamilyHistoryCard(isDesktop, profile),
                        const SizedBox(height: 14),
                        _buildLifestyleCard(isDesktop, profile),
                        const SizedBox(height: 14),
                        _buildAdditionalNotesCard(isDesktop, profile),
                        const SizedBox(height: 14),
                        _buildEmergencyContactCard(profile, isDesktop),
                      ],

                      // Bottom Action Buttons in Edit Mode
                      if (_isEditing) ...[
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _cancelEditing,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF5A756B),
                                  backgroundColor: const Color(0xFFE7F0E9),
                                  side: const BorderSide(
                                    color: Color(0xFFDCEBE2),
                                    width: 1.2,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: _saveMedicalHistory,
                                icon: const Icon(Icons.check_rounded, size: 18),
                                label: const Text(
                                  "Save Changes",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF28654F),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 15),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  elevation: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Subtle "Demo data — please verify" Banner ---
  Widget _buildDemoDataIndicatorBanner({required bool isCustomized}) {
    if (isCustomized) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3FAF6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC7E5D4), width: 1.0),
        ),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(
                Icons.check_circle_outline_rounded,
                size: 16,
                color: Color(0xFF28654F),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Confirmed patient record: Clinical medical history has been updated and saved for this patient profile.",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E5D46),
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD4E7DC), width: 1.0),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: Color(0xFF28654F),
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Medical Anamnesis: Please review and update your clinical history and health records below.",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF355245),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Profile Summary Header Card ---
  Widget _buildHeaderCard(
    BuildContext context,
    PatientProfileModel profile,
    bool isDesktop,
  ) {
    return _buildCardWrapper(
      borderRadius: 20,
      isDesktop: isDesktop,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular Avatar with fallback
          Container(
            width: isDesktop ? 64 : 54,
            height: isDesktop ? 64 : 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE8F2EC),
              border: Border.all(color: const Color(0xFFC8DEC0), width: 1.8),
            ),
            child: ClipOval(
              child: profile.photoBytes != null
                  ? Image.memory(
                      profile.photoBytes!,
                      fit: BoxFit.cover,
                    )
                  : const Icon(
                      Icons.person_rounded,
                      size: 32,
                      color: Color(0xFF28654F),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _displayValue(profile.fullName),
                        style: TextStyle(
                          fontSize: isDesktop ? 19 : 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF19372B),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (!_isEditing)
                      ElevatedButton.icon(
                        onPressed: _startEditing,
                        icon: const Icon(Icons.edit_outlined, size: 14),
                        label: const Text("Edit"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF28654F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                          textStyle: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE9F4EE),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFCCE4D4), width: 0.8),
                        ),
                        child: const Text(
                          "Editing Mode",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E5D46),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  "Comprehensive patient medical history, recorded conditions, and allergies",
                  style: TextStyle(
                    fontSize: isDesktop ? 12.5 : 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF637D71),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildPillTag(
                      "Blood: ${_displayValue(profile.bloodGroup)}",
                      bgColor: const Color(0xFFF2F7F4),
                      textColor: const Color(0xFF2B5745),
                    ),
                    if (profile.age != null)
                      _buildPillTag(
                        "${profile.age} yrs",
                        bgColor: const Color(0xFFF2F7F4),
                        textColor: const Color(0xFF2B5745),
                      ),
                    _buildPillTag(
                      profile.isAnamnesisCustomized ? "Clinical record saved" : "Demo data — please verify",
                      bgColor: const Color(0xFFF3FAF6),
                      textColor: const Color(0xFF1E5D46),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Section 1: Existing Medical Conditions ---
  Widget _buildConditionsCard(bool isDesktop, PatientProfileModel profile) {
    return _buildCardWrapper(
      borderRadius: 18,
      isDesktop: isDesktop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            title: "Existing Medical Conditions",
            icon: Icons.health_and_safety_outlined,
          ),
          const SizedBox(height: 12),
          if (!_isEditing)
            _buildRecordedDataBox(
              label: "Reported Conditions",
              content: profile.conditions ?? AnamnesisData.defaultSample.conditions,
            )
          else
            _buildTextField(
              label: "Existing Medical Conditions",
              controller: _conditionsController,
              maxLines: 2,
              hintText: "Enter existing medical conditions",
            ),
        ],
      ),
    );
  }

  // --- Section 2: Allergies ---
  Widget _buildAllergiesCard(bool isDesktop, PatientProfileModel profile) {
    return _buildCardWrapper(
      borderRadius: 18,
      isDesktop: isDesktop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            title: "Allergies",
            icon: Icons.warning_amber_rounded,
          ),
          const SizedBox(height: 12),
          if (!_isEditing)
            _buildRecordedDataBox(
              label: "Allergy Details",
              content: profile.allergies ?? AnamnesisData.defaultSample.allergies,
            )
          else
            _buildTextField(
              label: "Known Allergies",
              controller: _allergiesController,
              maxLines: 2,
              hintText: "Enter known allergies",
            ),
        ],
      ),
    );
  }

  // --- Section 3: Current Medications ---
  Widget _buildMedicationsCard(bool isDesktop, PatientProfileModel profile) {
    return _buildCardWrapper(
      borderRadius: 18,
      isDesktop: isDesktop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            title: "Current Medications",
            icon: Icons.medication_outlined,
          ),
          const SizedBox(height: 12),
          if (!_isEditing)
            _buildRecordedDataBox(
              label: "Medication Regimen & Supplements",
              content: profile.medications ?? AnamnesisData.defaultSample.medications,
            )
          else
            _buildTextField(
              label: "Current Medications & Supplements",
              controller: _medicationsController,
              maxLines: 2,
              hintText: "Enter current medications and dosages",
            ),
        ],
      ),
    );
  }

  // --- Section 4: Past Medical History ---
  Widget _buildPastMedicalHistoryCard(bool isDesktop, PatientProfileModel profile) {
    return _buildCardWrapper(
      borderRadius: 18,
      isDesktop: isDesktop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            title: "Past Medical History",
            icon: Icons.history_edu_outlined,
          ),
          const SizedBox(height: 12),
          if (!_isEditing)
            _buildRecordedDataBox(
              label: "Prior Illnesses & Medical Episodes",
              content: profile.pastMedicalHistory ?? AnamnesisData.defaultSample.pastMedicalHistory,
            )
          else
            _buildTextField(
              label: "Past Medical History",
              controller: _pastMedicalHistoryController,
              maxLines: 3,
              hintText: "Enter past medical history and prior illnesses",
            ),
        ],
      ),
    );
  }

  // --- Section 5: Surgical History ---
  Widget _buildSurgicalHistoryCard(bool isDesktop, PatientProfileModel profile) {
    return _buildCardWrapper(
      borderRadius: 18,
      isDesktop: isDesktop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            title: "Surgical History",
            icon: Icons.local_hospital_outlined,
          ),
          const SizedBox(height: 12),
          if (!_isEditing)
            _buildRecordedDataBox(
              label: "Prior Surgeries & Hospitalizations",
              content: profile.surgicalHistory ?? AnamnesisData.defaultSample.surgicalHistory,
            )
          else
            _buildTextField(
              label: "Surgical & Hospitalization History",
              controller: _surgicalHistoryController,
              maxLines: 2,
              hintText: "Enter surgical history or hospitalizations",
            ),
        ],
      ),
    );
  }

  // --- Section 6: Family History ---
  Widget _buildFamilyHistoryCard(bool isDesktop, PatientProfileModel profile) {
    return _buildCardWrapper(
      borderRadius: 18,
      isDesktop: isDesktop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            title: "Family History",
            icon: Icons.family_restroom_outlined,
          ),
          const SizedBox(height: 12),
          if (!_isEditing)
            _buildRecordedDataBox(
              label: "Family Health Details",
              content: profile.familyHistory ?? AnamnesisData.defaultSample.familyHistory,
            )
          else
            _buildTextField(
              label: "Family Medical History",
              controller: _familyHistoryController,
              maxLines: 2,
              hintText: "Enter family medical history",
            ),
        ],
      ),
    );
  }

  // --- Section 7: Lifestyle ---
  Widget _buildLifestyleCard(bool isDesktop, PatientProfileModel profile) {
    return _buildCardWrapper(
      borderRadius: 18,
      isDesktop: isDesktop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            title: "Lifestyle",
            icon: Icons.spa_outlined,
          ),
          const SizedBox(height: 12),
          if (!_isEditing)
            _buildRecordedDataBox(
              label: "Habits, Diet & Physical Activity",
              content: profile.lifestyle ?? AnamnesisData.defaultSample.lifestyle,
            )
          else
            _buildTextField(
              label: "Lifestyle Details",
              controller: _lifestyleController,
              maxLines: 2,
              hintText: "Enter lifestyle details, diet, or habits",
            ),
        ],
      ),
    );
  }

  // --- Section 8: Additional Notes ---
  Widget _buildAdditionalNotesCard(bool isDesktop, PatientProfileModel profile) {
    return _buildCardWrapper(
      borderRadius: 18,
      isDesktop: isDesktop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            title: "Additional Notes",
            icon: Icons.notes_rounded,
          ),
          const SizedBox(height: 12),
          if (!_isEditing)
            _buildRecordedDataBox(
              label: "Other Health Remarks",
              content: profile.additionalNotes ?? AnamnesisData.defaultSample.additionalNotes,
            )
          else
            _buildTextField(
              label: "Additional Notes",
              controller: _additionalNotesController,
              maxLines: 2,
              hintText: "Enter additional clinical or health notes",
            ),
        ],
      ),
    );
  }

  // --- Section 9: Emergency Information ---
  Widget _buildEmergencyContactCard(
    PatientProfileModel profile,
    bool isDesktop,
  ) {
    return _buildCardWrapper(
      borderRadius: 18,
      isDesktop: isDesktop,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(
            title: "Emergency Information",
            icon: Icons.emergency_outlined,
          ),
          const SizedBox(height: 12),
          _buildKeyValueRow(
            "Contact Person",
            _displayValue(profile.emergencyContactName),
          ),
          const SizedBox(height: 8),
          _buildKeyValueRow(
            "Relationship",
            _displayValue(profile.emergencyContactRelationship),
          ),
          const SizedBox(height: 8),
          _buildKeyValueRow(
            "Emergency Phone",
            _displayValue(profile.emergencyContactPhone),
          ),
          const SizedBox(height: 8),
          _buildKeyValueRow(
            "Blood Group",
            _displayValue(profile.bloodGroup),
          ),
        ],
      ),
    );
  }

  // --- Reusable Text Field for Edit Mode ---
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF4A6B5D),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF19372B),
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              fontSize: 13,
              color: Color(0xFF8CA196),
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: const Color(0xFFFAFCFA),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            isDense: true,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFDCECE1),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF28654F),
                width: 1.8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Reusable Card Shell with Botanical Leaf Decoration ---
  Widget _buildCardWrapper({
    required Widget child,
    required double borderRadius,
    required bool isDesktop,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0xFFDCECE1), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            offset: Offset(0, 3),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Botanical leaf decoration positioned along bottom-right edge matching Patient Profile
            Positioned(
              right: -25,
              bottom: -20,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.075,
                  child: Image.asset(
                    ClinovaConstants.leavesAsset,
                    height: 135,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 20 : 16,
                vertical: isDesktop ? 18 : 15,
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }

  // --- Reusable Card Header Row ---
  Widget _buildCardHeader({
    required String title,
    required IconData icon,
    Widget? badge,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F4EE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: const Color(0xFF28654F)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF19372B),
                  letterSpacing: -0.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ?badge,
          ],
        ),
        const SizedBox(height: 10),
        Container(height: 1.0, color: const Color(0xFFEEF5F0)),
      ],
    );
  }

  // --- Recorded Data Content Box ---
  Widget _buildRecordedDataBox({
    required String label,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6FAF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFDCECE1),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5A756B),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF19372B),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // --- Key-Value Data Display Row ---
  Widget _buildKeyValueRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF738E82),
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF19372B),
          ),
        ),
      ],
    );
  }

  // --- Pill Tag Helper ---
  Widget _buildPillTag(
    String text, {
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}
