import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/clinova_colors.dart';
import '../models/case_attachment_model.dart';
import '../models/case_intake_model.dart';
import '../services/case_attachment_repository.dart';
import '../services/demo_case_repository.dart';
import '../../doctor/services/ai_case_summary_repository.dart';

/// Clinova 13-Step New Case Intake Screen
///
/// Features:
/// - 11 clinical intake questions
/// - Question 12: Optional supporting medical documents upload
/// - Step 13: Comprehensive final review with per-step jump-to-edit
/// - Always-rendered forest-green "Continue →" / "Submit Case" button on bottom right
/// - Step validation with clear inline/card error messages
/// - Dynamic progress indicator ("Step X of 13" and percentage)
/// - Single-choice cards, multi-choice pills with mutually exclusive logic
/// - Conditional fields for occurrences, medications, and allergies
/// - Save Draft action in AppBar header with persistence
/// - Case submission integrating with DemoCaseRepository and redirecting to Patient Dashboard
class CaseIntakeScreen extends StatefulWidget {
  const CaseIntakeScreen({super.key});

  @override
  State<CaseIntakeScreen> createState() => _CaseIntakeScreenState();
}

class _CaseIntakeScreenState extends State<CaseIntakeScreen> {
  late CaseIntakeModel _intake;
  int _currentStep = 1;
  static const int _totalSteps = 13;
  String? _stepErrorMessage;
  bool _isSavingDraft = false;
  bool _isSubmitting = false;
  bool _isPickingFiles = false;

  // Controllers for text inputs
  late final TextEditingController _concernController;
  late final TextEditingController _otherSymptomController;
  late final TextEditingController _symptomDetailsController;
  late final TextEditingController _previousOccurrenceDetailsController;
  late final TextEditingController _otherConditionController;
  late final TextEditingController _allergyDetailsController;
  late final TextEditingController _medicationDetailsController;
  late final TextEditingController _medicalFamilyHistoryController;
  late final TextEditingController _additionalConcernsController;

  // Focus nodes
  final FocusNode _concernFocus = FocusNode();
  final FocusNode _otherSymptomFocus = FocusNode();
  final FocusNode _symptomDetailsFocus = FocusNode();
  final FocusNode _previousDetailsFocus = FocusNode();
  final FocusNode _otherConditionFocus = FocusNode();
  final FocusNode _allergyDetailsFocus = FocusNode();
  final FocusNode _medicationDetailsFocus = FocusNode();
  final FocusNode _historyFocus = FocusNode();
  final FocusNode _additionalConcernsFocus = FocusNode();

  // State variables for selections
  String? _duration;
  String? _severity;
  List<String> _associatedSymptoms = [];
  String? _previousOccurrences;
  List<String> _existingConditions = [];
  List<String> _allergies = [];
  String? _takesMedications;
  List<CaseAttachmentModel> _attachments = [];

  @override
  void initState() {
    super.initState();
    _intake = DemoCaseRepository.instance.getOrCreateDraft();
    _currentStep = _intake.currentStep.clamp(1, 13);

    // Initialize text controllers with saved values
    _concernController = TextEditingController(text: _intake.chiefConcern);
    _otherSymptomController = TextEditingController(text: _intake.otherAssociatedSymptom);
    _symptomDetailsController = TextEditingController(text: _intake.symptomDetails);
    _previousOccurrenceDetailsController = TextEditingController(text: _intake.previousOccurrenceDetails);
    _otherConditionController = TextEditingController(text: _intake.otherConditionDetails);
    _allergyDetailsController = TextEditingController(text: _intake.allergyDetails);
    _medicationDetailsController = TextEditingController(text: _intake.medicationDetails);
    _medicalFamilyHistoryController = TextEditingController(text: _intake.medicalFamilyHistory);
    _additionalConcernsController = TextEditingController(text: _intake.additionalConcerns);

    // Initialize selection states & attachments
    _duration = _intake.duration;
    _severity = _intake.severity;
    _associatedSymptoms = List.from(_intake.associatedSymptoms);
    _previousOccurrences = _intake.previousOccurrences;
    _existingConditions = List.from(_intake.existingConditions);
    _allergies = List.from(_intake.allergies);
    _takesMedications = _intake.takesMedications;
    _attachments = List.from(_intake.attachments);

    _concernController.addListener(_onConcernChanged);
  }

  void _onConcernChanged() {
    if (_stepErrorMessage != null && _concernController.text.trim().isNotEmpty) {
      setState(() {
        _stepErrorMessage = null;
      });
    }
  }

  void _clearStepErrorIfPresent() {
    if (_stepErrorMessage != null) {
      setState(() {
        _stepErrorMessage = null;
      });
    }
  }

  @override
  void dispose() {
    _concernController.removeListener(_onConcernChanged);
    _concernController.dispose();
    _otherSymptomController.dispose();
    _symptomDetailsController.dispose();
    _previousOccurrenceDetailsController.dispose();
    _otherConditionController.dispose();
    _allergyDetailsController.dispose();
    _medicationDetailsController.dispose();
    _medicalFamilyHistoryController.dispose();
    _additionalConcernsController.dispose();

    _concernFocus.dispose();
    _otherSymptomFocus.dispose();
    _symptomDetailsFocus.dispose();
    _previousDetailsFocus.dispose();
    _otherConditionFocus.dispose();
    _allergyDetailsFocus.dispose();
    _medicationDetailsFocus.dispose();
    _historyFocus.dispose();
    _additionalConcernsFocus.dispose();

    super.dispose();
  }

  CaseIntakeModel _buildCurrentDraft() {
    return _intake.copyWith(
      currentStep: _currentStep,
      chiefConcern: _concernController.text.trim(),
      duration: _duration,
      severity: _severity,
      associatedSymptoms: _associatedSymptoms,
      otherAssociatedSymptom: _associatedSymptoms.contains("Other") ? _otherSymptomController.text.trim() : null,
      symptomDetails: _symptomDetailsController.text.trim().isNotEmpty ? _symptomDetailsController.text.trim() : null,
      previousOccurrences: _previousOccurrences,
      previousOccurrenceDetails: _previousOccurrences == "Yes" ? _previousOccurrenceDetailsController.text.trim() : null,
      existingConditions: _existingConditions,
      otherConditionDetails: _existingConditions.contains("Other") ? _otherConditionController.text.trim() : null,
      allergies: _allergies,
      allergyDetails: _allergies.isNotEmpty && !_allergies.contains("No known allergies") && _allergyDetailsController.text.trim().isNotEmpty
          ? _allergyDetailsController.text.trim()
          : null,
      takesMedications: _takesMedications,
      medicationDetails: _takesMedications == "Yes" ? _medicationDetailsController.text.trim() : null,
      medicalFamilyHistory: _medicalFamilyHistoryController.text.trim().isNotEmpty
          ? _medicalFamilyHistoryController.text.trim()
          : null,
      additionalConcerns: _additionalConcernsController.text.trim().isNotEmpty
          ? _additionalConcernsController.text.trim()
          : null,
      attachments: _attachments,
    );
  }

  Future<void> _handleSaveDraft() async {
    setState(() {
      _isSavingDraft = true;
    });

    final currentDraft = _buildCurrentDraft();
    final success = await DemoCaseRepository.instance.saveDraft(currentDraft);
    _intake = currentDraft;

    if (!mounted) return;
    setState(() {
      _isSavingDraft = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Draft saved successfully. You can return anytime to complete it.",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF28654F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Failed to save draft. Please try again."),
          backgroundColor: ClinovaColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 1:
        if (_concernController.text.trim().isEmpty) {
          setState(() {
            _stepErrorMessage = "Please describe your health concern to continue.";
          });
          _concernFocus.requestFocus();
          return false;
        }
        break;
      case 2:
        if (_duration == null) {
          setState(() {
            _stepErrorMessage = "Please select how long you have experienced this problem.";
          });
          return false;
        }
        break;
      case 3:
        if (_severity == null) {
          setState(() {
            _stepErrorMessage = "Please select the severity of your problem.";
          });
          return false;
        }
        break;
      case 4:
        if (_associatedSymptoms.isEmpty) {
          setState(() {
            _stepErrorMessage = "Please select at least one option (or 'None of these').";
          });
          return false;
        }
        if (_associatedSymptoms.contains("Other") && _otherSymptomController.text.trim().isEmpty) {
          setState(() {
            _stepErrorMessage = "Please specify the other symptom.";
          });
          _otherSymptomFocus.requestFocus();
          return false;
        }
        break;
      case 5:
        // Optional
        break;
      case 6:
        if (_previousOccurrences == null) {
          setState(() {
            _stepErrorMessage = "Please indicate if you have experienced this problem before.";
          });
          return false;
        }
        break;
      case 7:
        if (_existingConditions.isEmpty) {
          setState(() {
            _stepErrorMessage = "Please select your medical conditions (or 'None known').";
          });
          return false;
        }
        if (_existingConditions.contains("Other") && _otherConditionController.text.trim().isEmpty) {
          setState(() {
            _stepErrorMessage = "Please specify your other medical condition.";
          });
          _otherConditionFocus.requestFocus();
          return false;
        }
        break;
      case 8:
        if (_allergies.isEmpty) {
          setState(() {
            _stepErrorMessage = "Please select your known allergies (or 'No known allergies').";
          });
          return false;
        }
        break;
      case 9:
        if (_takesMedications == null) {
          setState(() {
            _stepErrorMessage = "Please indicate if you are currently taking any medicines.";
          });
          return false;
        }
        if (_takesMedications == "Yes" && _medicationDetailsController.text.trim().isEmpty) {
          setState(() {
            _stepErrorMessage = "Please enter medication names or dosages.";
          });
          _medicationDetailsFocus.requestFocus();
          return false;
        }
        break;
      case 10:
        // Optional
        break;
      case 11:
        // Optional (Specific Inquiries & Goals)
        break;
      case 12:
        // Optional (Supporting Medical Documents)
        break;
      case 13:
        // Final review validation
        if (_concernController.text.trim().isEmpty) {
          setState(() {
            _stepErrorMessage = "Step 1 (Chief Concern) is required.";
            _currentStep = 1;
          });
          return false;
        }
        break;
    }

    setState(() {
      _stepErrorMessage = null;
    });
    return true;
  }

  void _handleContinue() {
    if (!_validateCurrentStep()) return;

    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
        _intake = _buildCurrentDraft();
      });
      DemoCaseRepository.instance.saveDraft(_intake);
    } else {
      _handleSubmitCase();
    }
  }

  bool _hasUnsavedChanges() {
    final current = _buildCurrentDraft();
    final saved = DemoCaseRepository.instance.activeDraft;
    if (saved == null) {
      // If no draft was ever saved, check if user has entered anything at all
      return current.chiefConcern.isNotEmpty ||
          current.duration != null ||
          current.severity != null ||
          current.associatedSymptoms.isNotEmpty ||
          (current.symptomDetails != null && current.symptomDetails!.isNotEmpty) ||
          current.previousOccurrences != null ||
          current.existingConditions.isNotEmpty ||
          current.allergies.isNotEmpty ||
          current.takesMedications != null ||
          (current.medicalFamilyHistory != null && current.medicalFamilyHistory!.isNotEmpty) ||
          (current.additionalConcerns != null && current.additionalConcerns!.isNotEmpty) ||
          current.attachments.isNotEmpty;
    }

    // Compare meaningful form fields
    return current.chiefConcern != saved.chiefConcern ||
        current.duration != saved.duration ||
        current.severity != saved.severity ||
        current.associatedSymptoms.join(',') != saved.associatedSymptoms.join(',') ||
        current.otherAssociatedSymptom != saved.otherAssociatedSymptom ||
        current.symptomDetails != saved.symptomDetails ||
        current.previousOccurrences != saved.previousOccurrences ||
        current.previousOccurrenceDetails != saved.previousOccurrenceDetails ||
        current.existingConditions.join(',') != saved.existingConditions.join(',') ||
        current.otherConditionDetails != saved.otherConditionDetails ||
        current.allergies.join(',') != saved.allergies.join(',') ||
        current.allergyDetails != saved.allergyDetails ||
        current.takesMedications != saved.takesMedications ||
        current.medicationDetails != saved.medicationDetails ||
        current.medicalFamilyHistory != saved.medicalFamilyHistory ||
        current.additionalConcerns != saved.additionalConcerns ||
        current.attachments.length != saved.attachments.length ||
        current.currentStep != saved.currentStep;
  }

  Future<void> _handleTopLeftBackArrow() async {
    if (_hasUnsavedChanges()) {
      final shouldLeave = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              "Discard unsaved changes?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF19372B),
              ),
            ),
            content: const Text(
              "You have unsaved changes in this case questionnaire. If you leave now without saving draft, your new inputs will be lost.",
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF5A756B),
                height: 1.45,
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text(
                  "Stay",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF28654F),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB43B2A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                child: const Text(
                  "Leave & Discard",
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (shouldLeave != true) return;
    }

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.patientDashboard,
      (route) => false,
    );
  }

  void _handleBack() {
    if (_currentStep > 1) {
      setState(() {
        _stepErrorMessage = null;
        _currentStep--;
        _intake = _buildCurrentDraft();
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  void _jumpToStep(int step) {
    setState(() {
      _stepErrorMessage = null;
      _currentStep = step;
      _intake = _buildCurrentDraft();
    });
  }

  Future<void> _handleSubmitCase() async {
    setState(() {
      _isSubmitting = true;
    });

    final completeCase = _buildCurrentDraft();
    final summary = DemoCaseRepository.instance.submitCase(completeCase);

    // Trigger AI summary generation via n8n workflow.
    // Preserves saved case even if webhook is offline or errors.
    AiCaseSummaryRepository.instance.generateSummaryForCase(caseSummary: summary);

    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
    });

    // Pop or navigate to patient dashboard with confirmation
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.patientDashboard,
      (route) => false,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Case submitted successfully!",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Reference: ${summary.reference} — Awaiting doctor review",
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFFD6EDE0),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF28654F),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;

    return Scaffold(
      backgroundColor: ClinovaColors.background,
      appBar: AppBar(
        backgroundColor: ClinovaColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E5D46)),
          tooltip: "Back to Dashboard",
          onPressed: _handleTopLeftBackArrow,
        ),
        title: const Text(
          "New Case",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF19372B),
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              onPressed: _isSavingDraft || _isSubmitting ? null : _handleSaveDraft,
              icon: _isSavingDraft
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF28654F)),
                      ),
                    )
                  : const Icon(Icons.bookmark_border_rounded, size: 18),
              label: Text(
                _isSavingDraft ? "Saving..." : "Save Draft",
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.1,
                ),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF28654F),
                backgroundColor: const Color(0xFFE4EFE7),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFBED7C7), width: 1.0),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 18,
              vertical: isDesktop ? 28 : 20,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 780),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildProgressHeader(),
                  const SizedBox(height: 24),
                  _buildQuestionCard(isDesktop),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),

    );
  }

  Widget _buildProgressHeader() {
    final progressFraction = _currentStep / _totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Step $_currentStep of $_totalSteps",
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF28654F),
                letterSpacing: 0.1,
              ),
            ),
            Text(
              "${(progressFraction * 100).toInt()}% completed",
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5A756B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Container(
                height: 7,
                width: double.infinity,
                color: const Color(0xFFDFEDE4),
              ),
              AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                widthFactor: progressFraction.clamp(0.0, 1.0),
                child: Container(
                  height: 7,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF3B9B79),
                        Color(0xFF28654F),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFDCECE1), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            offset: Offset(0, 10),
            blurRadius: 28,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Color(0x05000000),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Soft botanical leaf watermark in top right corner (subtle 8% opacity)
            Positioned(
              top: -20,
              right: -20,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.08,
                  child: Image.asset(
                    ClinovaConstants.leavesAsset,
                    width: isDesktop ? 150 : 125,
                    height: isDesktop ? 150 : 125,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),

            // Soft botanical leaf watermark in bottom left corner (subtle 7% opacity, flipped/rotated for organic aesthetic)
            Positioned(
              bottom: -25,
              left: -20,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.07,
                  child: Transform.rotate(
                    angle: 3.14159, // 180 degrees
                    child: Image.asset(
                      ClinovaConstants.leavesAsset,
                      width: isDesktop ? 140 : 115,
                      height: isDesktop ? 140 : 115,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 34 : 22,
                vertical: isDesktop ? 32 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCurrentStepContent(isDesktop: isDesktop),
                  if (_stepErrorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF2F0),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF1CDC6), width: 0.8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, size: 16, color: ClinovaColors.error),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _stepErrorMessage!,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: ClinovaColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Container(height: 1.0, color: const Color(0xFFE9F2EC)),
                  const SizedBox(height: 20),
                  _buildBottomActionRow(isDesktop: isDesktop),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDocuments() async {
    setState(() {
      _isPickingFiles = true;
      _stepErrorMessage = null;
    });

    try {
      final pickedFiles = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'],
      );

      if (pickedFiles.isNotEmpty) {
        final List<String> errorMessages = [];
        final List<CaseAttachmentModel> newAttachments = [];

        for (final file in pickedFiles) {
          final filename = file.name;
          final bytes = await file.readAsBytes();
          final size = file.lengthSync() ?? (await file.length()) ?? bytes.length;

          final validation = CaseAttachmentRepository.instance.validateFile(
            filename: filename,
            sizeBytes: size,
            existingAttachments: [..._attachments, ...newAttachments],
          );

          if (!validation.isValid) {
            errorMessages.add(validation.errorMessage ?? "Invalid file: $filename");
            continue;
          }

          final uniqueId = "att_${DateTime.now().millisecondsSinceEpoch}_${newAttachments.length}";
          newAttachments.add(
            CaseAttachmentModel(
              id: uniqueId,
              caseId: _intake.reference,
              originalFilename: filename,
              fileSizeBytes: size,
              mimeType: validation.mimeType,
              bytes: bytes,
              uploadStatus: AttachmentUploadStatus.selected,
              createdAt: DateTime.now(),
            ),
          );
        }

        if (newAttachments.isNotEmpty) {
          setState(() {
            _attachments.addAll(newAttachments);
            _intake = _buildCurrentDraft();
          });
          DemoCaseRepository.instance.saveDraft(_intake);
        }

        if (errorMessages.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessages.join('\n')),
              backgroundColor: ClinovaColors.error,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to select files: $e"),
            backgroundColor: ClinovaColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingFiles = false;
        });
      }
    }
  }

  void _removeAttachment(CaseAttachmentModel item) {
    setState(() {
      _attachments.removeWhere((a) => a.id == item.id || (a.originalFilename == item.originalFilename && a.fileSizeBytes == item.fileSizeBytes));
      _intake = _buildCurrentDraft();
    });
    DemoCaseRepository.instance.saveDraft(_intake);
  }

  Widget _buildCurrentStepContent({required bool isDesktop}) {
    switch (_currentStep) {
      case 1:
        return _buildStep1ChiefComplaint();
      case 2:
        return _buildStep2Duration();
      case 3:
        return _buildStep3Severity();
      case 4:
        return _buildStep4AssociatedSymptoms();
      case 5:
        return _buildStep5SymptomDetails();
      case 6:
        return _buildStep6PreviousOccurrences();
      case 7:
        return _buildStep7ExistingConditions();
      case 8:
        return _buildStep8Allergies();
      case 9:
        return _buildStep9Medications();
      case 10:
        return _buildStep10History();
      case 11:
        return _buildStep11QuestionsForDoctor();
      case 12:
        return _buildStep12Documents(isDesktop);
      case 13:
        return _buildStep13Review();
      default:
        return const SizedBox.shrink();
    }
  }

  // --- STEP 1: CHIEF COMPLAINT ---
  Widget _buildStep1ChiefComplaint() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildQuestionHeader(
          "What health concern would you like to discuss with your doctor?",
          isRequired: true,
        ),
        const SizedBox(height: 10),
        _buildQuestionDescription(
          "Describe your main symptoms or health concern in your own words. Be as clear and specific as you can.",
        ),
        const SizedBox(height: 18),
        _buildTextInputContainer(
          child: TextFormField(
            controller: _concernController,
            focusNode: _concernFocus,
            minLines: 4,
            maxLines: 7,
            keyboardType: TextInputType.multiline,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF233A32), height: 1.5),
            decoration: const InputDecoration(
              hintText: "Describe your main symptoms or health concern...",
              hintStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Color(0xFF8DA39A)),
              contentPadding: EdgeInsets.all(18),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  // --- STEP 2: DURATION ---
  Widget _buildStep2Duration() {
    final options = [
      "Less than 24 hours",
      "1–3 days",
      "4–7 days",
      "1–2 weeks",
      "More than 2 weeks",
      "Comes and goes",
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildQuestionHeader(
          "How long have you been experiencing this problem?",
          isRequired: true,
        ),
        const SizedBox(height: 10),
        _buildQuestionDescription("Select the option that best matches when your symptoms began."),
        const SizedBox(height: 18),
        ...options.map((option) => _buildRadioOptionCard(
              title: option,
              isSelected: _duration == option,
              onTap: () {
                setState(() {
                  _duration = option;
                  _clearStepErrorIfPresent();
                });
              },
            )),
      ],
    );
  }

  // --- STEP 3: SEVERITY ---
  Widget _buildStep3Severity() {
    final options = [
      {"label": "Mild", "desc": "Noticeable, but does not interfere with daily activities."},
      {"label": "Moderate", "desc": "Uncomfortable and interferes somewhat with routine."},
      {"label": "Severe", "desc": "Significantly impairs ability to work or carry out daily tasks."},
      {"label": "Very severe", "desc": "Incapacitating or unbearable discomfort requiring urgent attention."},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildQuestionHeader(
          "How severe is your problem right now?",
          isRequired: true,
        ),
        const SizedBox(height: 10),
        _buildQuestionDescription("Choose the level that best describes how intense the symptoms are today."),
        const SizedBox(height: 18),
        ...options.map((item) => _buildRadioOptionCard(
              title: item["label"]!,
              subtitle: item["desc"],
              isSelected: _severity == item["label"],
              onTap: () {
                setState(() {
                  _severity = item["label"];
                  _clearStepErrorIfPresent();
                });
              },
            )),
      ],
    );
  }

  // --- STEP 4: ASSOCIATED SYMPTOMS ---
  Widget _buildStep4AssociatedSymptoms() {
    final options = [
      "Fever",
      "Headache",
      "Cough",
      "Fatigue",
      "Nausea or vomiting",
      "Dizziness",
      "Pain",
      "Difficulty breathing",
      "Other",
      "None of these",
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildQuestionHeader(
          "Are you experiencing any other symptoms?",
          isRequired: true,
        ),
        const SizedBox(height: 10),
        _buildQuestionDescription("Select all that apply. If you have no other symptoms, select 'None of these'."),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((opt) {
            final isSelected = _associatedSymptoms.contains(opt);
            return _buildFilterPill(
              label: opt,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _clearStepErrorIfPresent();
                  if (opt == "None of these") {
                    _associatedSymptoms = ["None of these"];
                  } else {
                    _associatedSymptoms.remove("None of these");
                    if (isSelected) {
                      _associatedSymptoms.remove(opt);
                    } else {
                      _associatedSymptoms.add(opt);
                    }
                  }
                });
              },
            );
          }).toList(),
        ),
        if (_associatedSymptoms.contains("Other")) ...[
          const SizedBox(height: 16),
          _buildTextInputContainer(
            child: TextFormField(
              controller: _otherSymptomController,
              focusNode: _otherSymptomFocus,
              decoration: const InputDecoration(
                hintText: "Please describe other symptoms...",
                hintStyle: TextStyle(fontSize: 14, color: Color(0xFF8DA39A)),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // --- STEP 5: SYMPTOM DETAILS ---
  Widget _buildStep5SymptomDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildQuestionHeader(
          "What makes your symptoms better or worse?",
          isRequired: false,
        ),
        const SizedBox(height: 10),
        _buildQuestionDescription(
          "Mention triggers, relief, patterns, or other details. You can leave this blank if you're unsure.",
        ),
        const SizedBox(height: 18),
        _buildTextInputContainer(
          child: TextFormField(
            controller: _symptomDetailsController,
            focusNode: _symptomDetailsFocus,
            minLines: 4,
            maxLines: 7,
            keyboardType: TextInputType.multiline,
            decoration: const InputDecoration(
              hintText: "Mention triggers, relief, patterns, or other details...",
              hintStyle: TextStyle(fontSize: 14, color: Color(0xFF8DA39A)),
              contentPadding: EdgeInsets.all(18),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  // --- STEP 6: PREVIOUS OCCURRENCES ---
  Widget _buildStep6PreviousOccurrences() {
    final options = ["Yes", "No", "Not sure"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildQuestionHeader(
          "Have you experienced this problem before?",
          isRequired: true,
        ),
        const SizedBox(height: 10),
        _buildQuestionDescription("Indicate whether you have had similar symptoms in the past."),
        const SizedBox(height: 18),
        Row(
          children: options.map((opt) {
            final isSelected = _previousOccurrences == opt;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildChoiceCard(
                  title: opt,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _previousOccurrences = opt;
                      _clearStepErrorIfPresent();
                    });
                  },
                ),
              ),
            );
          }).toList(),
        ),
        if (_previousOccurrences == "Yes") ...[
          const SizedBox(height: 18),
          _buildQuestionDescription("When did it happen, and how was it treated? (Optional)"),
          const SizedBox(height: 8),
          _buildTextInputContainer(
            child: TextFormField(
              controller: _previousOccurrenceDetailsController,
              focusNode: _previousDetailsFocus,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "e.g., Happened last winter, treated with antibiotics...",
                hintStyle: TextStyle(fontSize: 14, color: Color(0xFF8DA39A)),
                contentPadding: EdgeInsets.all(16),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // --- STEP 7: EXISTING MEDICAL CONDITIONS ---
  Widget _buildStep7ExistingConditions() {
    final options = [
      "None known",
      "Diabetes",
      "High blood pressure",
      "Asthma",
      "Heart condition",
      "Thyroid condition",
      "Other",
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildQuestionHeader(
          "Do you have any existing medical conditions?",
          isRequired: true,
        ),
        const SizedBox(height: 10),
        _buildQuestionDescription("Select any ongoing conditions. Select 'None known' if you have none."),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((cond) {
            final isSelected = _existingConditions.contains(cond);
            return _buildFilterPill(
              label: cond,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _clearStepErrorIfPresent();
                  if (cond == "None known") {
                    _existingConditions = ["None known"];
                  } else {
                    _existingConditions.remove("None known");
                    if (isSelected) {
                      _existingConditions.remove(cond);
                    } else {
                      _existingConditions.add(cond);
                    }
                  }
                });
              },
            );
          }).toList(),
        ),
        if (_existingConditions.contains("Other")) ...[
          const SizedBox(height: 16),
          _buildTextInputContainer(
            child: TextFormField(
              controller: _otherConditionController,
              focusNode: _otherConditionFocus,
              decoration: const InputDecoration(
                hintText: "Please specify other medical condition...",
                hintStyle: TextStyle(fontSize: 14, color: Color(0xFF8DA39A)),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // --- STEP 8: ALLERGIES ---
  Widget _buildStep8Allergies() {
    final options = [
      "No known allergies",
      "Medicines",
      "Food",
      "Environmental",
      "Other",
      "Not sure",
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildQuestionHeader(
          "Do you have any known allergies?",
          isRequired: true,
        ),
        const SizedBox(height: 10),
        _buildQuestionDescription("Select all categories that apply to you."),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((item) {
            final isSelected = _allergies.contains(item);
            return _buildFilterPill(
              label: item,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  _clearStepErrorIfPresent();
                  if (item == "No known allergies" || item == "Not sure") {
                    _allergies = [item];
                  } else {
                    _allergies.remove("No known allergies");
                    _allergies.remove("Not sure");
                    if (isSelected) {
                      _allergies.remove(item);
                    } else {
                      _allergies.add(item);
                    }
                  }
                });
              },
            );
          }).toList(),
        ),
        if (_allergies.isNotEmpty && !_allergies.contains("No known allergies") && !_allergies.contains("Not sure")) ...[
          const SizedBox(height: 16),
          _buildTextInputContainer(
            child: TextFormField(
              controller: _allergyDetailsController,
              focusNode: _allergyDetailsFocus,
              decoration: const InputDecoration(
                hintText: "Allergy details (e.g., Penicillin, Peanuts, Pollen)...",
                hintStyle: TextStyle(fontSize: 14, color: Color(0xFF8DA39A)),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // --- STEP 9: CURRENT MEDICATIONS ---
  Widget _buildStep9Medications() {
    final options = ["Yes", "No", "Not sure"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildQuestionHeader(
          "Are you currently taking any medicines or supplements?",
          isRequired: true,
        ),
        const SizedBox(height: 10),
        _buildQuestionDescription("Include prescription pills, over-the-counter medicine, herbal supplements, or vitamins."),
        const SizedBox(height: 18),
        Row(
          children: options.map((opt) {
            final isSelected = _takesMedications == opt;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildChoiceCard(
                  title: opt,
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _takesMedications = opt;
                      _clearStepErrorIfPresent();
                    });
                  },
                ),
              ),
            );
          }).toList(),
        ),
        if (_takesMedications == "Yes") ...[
          const SizedBox(height: 18),
          _buildQuestionDescription("List medication names and dosages if known:"),
          const SizedBox(height: 8),
          _buildTextInputContainer(
            child: TextFormField(
              controller: _medicationDetailsController,
              focusNode: _medicationDetailsFocus,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: "e.g., Metformin 500mg daily, Paracetamol as needed...",
                hintStyle: TextStyle(fontSize: 14, color: Color(0xFF8DA39A)),
                contentPadding: EdgeInsets.all(16),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // --- STEP 10: MEDICAL AND FAMILY HISTORY ---
  Widget _buildStep10History() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildQuestionHeader(
          "Is there any other medical or family history your doctor should know?",
          isRequired: false,
        ),
        const SizedBox(height: 10),
        _buildQuestionDescription(
          "Only provide information you know. You may mention surgeries, major hospitalizations, or family conditions.",
        ),
        const SizedBox(height: 18),
        _buildTextInputContainer(
          child: TextFormField(
            controller: _medicalFamilyHistoryController,
            focusNode: _historyFocus,
            minLines: 4,
            maxLines: 7,
            decoration: const InputDecoration(
              hintText: "e.g., Father had heart disease, previous appendix surgery in 2020...",
              hintStyle: TextStyle(fontSize: 14, color: Color(0xFF8DA39A)),
              contentPadding: EdgeInsets.all(18),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  // --- STEP 11: SPECIFIC INQUIRIES & CONSULTATION GOALS ---
  Widget _buildStep11QuestionsForDoctor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildQuestionHeader(
          "Do you have any specific inquiries or consultation goals?",
          isRequired: false,
          badgeText: "OPTIONAL",
        ),
        const SizedBox(height: 10),
        _buildQuestionDescription(
          "Share questions you'd like your doctor to answer or outcomes you hope to achieve (e.g. non-drowsy alternatives, lifestyle recommendations).",
        ),
        const SizedBox(height: 18),
        _buildTextInputContainer(
          child: TextFormField(
            controller: _additionalConcernsController,
            focusNode: _additionalConcernsFocus,
            minLines: 4,
            maxLines: 7,
            decoration: const InputDecoration(
              hintText: "e.g., I would like to clarify if my symptoms could be stress-related, and explore dietary adjustments...",
              hintStyle: TextStyle(fontSize: 14, color: Color(0xFF8DA39A)),
              contentPadding: EdgeInsets.all(18),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  // --- STEP 12: SUPPORTING MEDICAL DOCUMENTS (OPTIONAL) ---
  Widget _buildStep12Documents(bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildQuestionHeader(
          "Supporting Medical Documents",
          isRequired: false,
          badgeText: "OPTIONAL",
        ),
        const SizedBox(height: 10),
        _buildQuestionDescription(
          "Attach any relevant medical reports or scans to help your doctor understand your case better.",
        ),
        const SizedBox(height: 16),
        const Text(
          "Supported examples:",
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF233A32),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _ExampleChip(label: "MRI scans"),
            _ExampleChip(label: "X-ray images"),
            _ExampleChip(label: "Laboratory reports"),
            _ExampleChip(label: "Medical prescriptions"),
            _ExampleChip(label: "Other relevant medical documents"),
          ],
        ),
        const SizedBox(height: 20),

        // Upload Area Card
        InkWell(
          onTap: _isPickingFiles ? null : _pickDocuments,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAF8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFCBE0D3),
                width: 1.4,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5F1E9),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFBEDBC7), width: 1.0),
                  ),
                  child: const Icon(
                    Icons.cloud_upload_outlined,
                    color: Color(0xFF28654F),
                    size: 26,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Upload medical documents",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF19372B),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "PDF, JPEG, PNG, WebP, or HEIC up to 20 MB each",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF6B8B7B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isPickingFiles ? null : _pickDocuments,
                  icon: _isPickingFiles
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.attach_file_rounded, size: 16),
                  label: Text(
                    _isPickingFiles ? "Selecting files..." : "Attach Documents",
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28654F),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),
        const Text(
          "You can attach multiple files. This step is optional, and you can continue without uploading anything.",
          style: TextStyle(
            fontSize: 12.5,
            fontStyle: FontStyle.italic,
            color: Color(0xFF5A756B),
            height: 1.4,
          ),
        ),

        if (_attachments.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Attached Files (${_attachments.length})",
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF233A32),
                ),
              ),
              TextButton.icon(
                onPressed: _pickDocuments,
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text(
                  "Attach More",
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF28654F),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._attachments.map((att) => _buildAttachmentItemCard(att)),
        ],
      ],
    );
  }

  Widget _buildAttachmentItemCard(CaseAttachmentModel att) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FCFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDECE2), width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: att.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(att.icon, color: att.accentColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  att.originalFilename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF19372B),
                  ),
                ),
                const SizedBox(height: 3),
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      att.fileTypeLabel,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF436B5C)),
                    ),
                    const Text("•", style: TextStyle(fontSize: 10, color: Color(0xFF9AB2A6))),
                    Text(
                      att.formattedSize,
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B8B7B)),
                    ),
                    const Text("•", style: TextStyle(fontSize: 10, color: Color(0xFF9AB2A6))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F4EC),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        "Ready for upload",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF28654F),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFB43B2A)),
            tooltip: "Remove file",
            onPressed: () => _removeAttachment(att),
          ),
        ],
      ),
    );
  }

  // --- STEP 13: FINAL REVIEW ---
  Widget _buildStep13Review() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildQuestionHeader("Review your case information", isRequired: false),
        const SizedBox(height: 8),
        _buildQuestionDescription(
          "Please review your answers before submitting. Tap 'Edit' on any section to make changes.",
        ),
        const SizedBox(height: 20),
        _buildReviewSection(
          stepNumber: 1,
          title: "Chief Complaint",
          content: _concernController.text.trim().isNotEmpty ? _concernController.text.trim() : "Not provided",
          onEdit: () => _jumpToStep(1),
        ),
        _buildReviewSection(
          stepNumber: 2,
          title: "Duration",
          content: _duration ?? "Not specified",
          onEdit: () => _jumpToStep(2),
        ),
        _buildReviewSection(
          stepNumber: 3,
          title: "Severity",
          content: _severity ?? "Not specified",
          onEdit: () => _jumpToStep(3),
        ),
        _buildReviewSection(
          stepNumber: 4,
          title: "Associated Symptoms",
          content: _associatedSymptoms.isNotEmpty
              ? "${_associatedSymptoms.join(', ')}${_associatedSymptoms.contains('Other') && _otherSymptomController.text.trim().isNotEmpty ? ' (${_otherSymptomController.text.trim()})' : ''}"
              : "None selected",
          onEdit: () => _jumpToStep(4),
        ),
        _buildReviewSection(
          stepNumber: 5,
          title: "Triggers & Relief",
          content: _symptomDetailsController.text.trim().isNotEmpty
              ? _symptomDetailsController.text.trim()
              : "None recorded",
          onEdit: () => _jumpToStep(5),
        ),
        _buildReviewSection(
          stepNumber: 6,
          title: "Previous Occurrences",
          content: _previousOccurrences != null
              ? "$_previousOccurrences${_previousOccurrences == 'Yes' && _previousOccurrenceDetailsController.text.trim().isNotEmpty ? ' — ${_previousOccurrenceDetailsController.text.trim()}' : ''}"
              : "Not answered",
          onEdit: () => _jumpToStep(6),
        ),
        _buildReviewSection(
          stepNumber: 7,
          title: "Medical Conditions",
          content: _existingConditions.isNotEmpty
              ? "${_existingConditions.join(', ')}${_existingConditions.contains('Other') && _otherConditionController.text.trim().isNotEmpty ? ' (${_otherConditionController.text.trim()})' : ''}"
              : "None recorded",
          onEdit: () => _jumpToStep(7),
        ),
        _buildReviewSection(
          stepNumber: 8,
          title: "Allergies",
          content: _allergies.isNotEmpty
              ? "${_allergies.join(', ')}${_allergyDetailsController.text.trim().isNotEmpty ? ' (${_allergyDetailsController.text.trim()})' : ''}"
              : "None recorded",
          onEdit: () => _jumpToStep(8),
        ),
        _buildReviewSection(
          stepNumber: 9,
          title: "Current Medications",
          content: _takesMedications != null
              ? "$_takesMedications${_takesMedications == 'Yes' && _medicationDetailsController.text.trim().isNotEmpty ? ' — ${_medicationDetailsController.text.trim()}' : ''}"
              : "Not answered",
          onEdit: () => _jumpToStep(9),
        ),
        _buildReviewSection(
          stepNumber: 10,
          title: "Medical & Family History",
          content: _medicalFamilyHistoryController.text.trim().isNotEmpty
              ? _medicalFamilyHistoryController.text.trim()
              : "None provided",
          onEdit: () => _jumpToStep(10),
        ),
        _buildReviewSection(
          stepNumber: 11,
          title: "Specific Inquiries & Goals",
          content: _additionalConcernsController.text.trim().isNotEmpty
              ? _additionalConcernsController.text.trim()
              : "None provided",
          onEdit: () => _jumpToStep(11),
        ),
        _buildReviewSection(
          stepNumber: 12,
          title: "Supporting Medical Documents",
          content: _attachments.isNotEmpty
              ? "${_attachments.length} document(s) attached (${_attachments.map((a) => a.originalFilename).join(', ')})"
              : "None attached (Skipped)",
          onEdit: () => _jumpToStep(12),
        ),
      ],
    );
  }

  Widget _buildReviewSection({
    required int stepNumber,
    required String title,
    required String content,
    required VoidCallback onEdit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2EFE7), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Step $stepNumber: $title",
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF28654F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF19372B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onEdit,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF28654F),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Edit", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // --- REUSABLE UI HELPERS ---
  Widget _buildQuestionHeader(String title, {required bool isRequired, String? badgeText}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF19372B),
              height: 1.35,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 10),
          Container(
            margin: const EdgeInsets.only(top: 3),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: const Color(0xFFFBF1EE),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFECCFC6), width: 0.8),
            ),
            child: const Text(
              "Required",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFC04B37),
              ),
            ),
          ),
        ] else if (badgeText != null) ...[
          const SizedBox(width: 10),
          Container(
            margin: const EdgeInsets.only(top: 3),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF4EE),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFC6E2D0), width: 0.8),
            ),
            child: Text(
              badgeText,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF28654F),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuestionDescription(String description) {
    return Text(
      description,
      style: const TextStyle(
        fontSize: 14.5,
        color: Color(0xFF5A756B),
        height: 1.5,
      ),
    );
  }

  Widget _buildTextInputContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCFE1D6), width: 1.2),
        boxShadow: ClinovaColors.recessedShadow,
      ),
      child: child,
    );
  }

  Widget _buildRadioOptionCard({
    required String title,
    String? subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEDF6F0) : const Color(0xFFF7FAF8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? const Color(0xFF28654F) : const Color(0xFFD6E6DB),
              width: isSelected ? 1.6 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF28654F) : const Color(0xFF9FB6AA),
                    width: isSelected ? 6.0 : 1.5,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected ? const Color(0xFF19372B) : const Color(0xFF2D4B3E),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 12.5, color: Color(0xFF658074), height: 1.3),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEDF6F0) : const Color(0xFFF7FAF8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF28654F) : const Color(0xFFD6E6DB),
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? const Color(0xFF19372B) : const Color(0xFF385749),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF28654F) : const Color(0xFFF1F6F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF28654F) : const Color(0xFFCFE1D6),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : const Color(0xFF28654F),
          ),
        ),
      ),
    );
  }

  // --- STEP NAVIGATION ACTION ROW ---
  // Kept directly beneath the current step inside the scrollable question card.
  Widget _buildBottomActionRow({required bool isDesktop}) {
    final isFinalStep = _currentStep == _totalSteps;

    // Dedicated navigation row for Question 12: Supporting Medical Documents
    if (_currentStep == 12) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 480;
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = 13;
                      _intake = _buildCurrentDraft();
                    });
                    DemoCaseRepository.instance.saveDraft(_intake);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28654F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                    shadowColor: const Color(0xFF28654F).withValues(alpha: 0.35),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Continue to Review",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting ? null : _handleBack,
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: const Text(
                          "Previous",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF28654F),
                          backgroundColor: const Color(0xFFF1F6F2),
                          side: const BorderSide(color: Color(0xFFBDD9C9), width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                          minimumSize: const Size(0, 46),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _currentStep = 13;
                            _intake = _buildCurrentDraft();
                          });
                          DemoCaseRepository.instance.saveDraft(_intake);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF5A756B),
                          backgroundColor: Colors.transparent,
                          side: const BorderSide(color: Color(0xFFCFDFD6), width: 1.0),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0,
                          minimumSize: const Size(0, 46),
                        ),
                        child: const Text(
                          "Skip for now",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _handleBack,
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: const Text(
                    "Previous",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: -0.1),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF28654F),
                    backgroundColor: const Color(0xFFF1F6F2),
                    side: const BorderSide(color: Color(0xFFBDD9C9), width: 1.2),
                    padding: EdgeInsets.symmetric(horizontal: isDesktop ? 22 : 10, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                    minimumSize: const Size(0, 48),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = 13;
                    _intake = _buildCurrentDraft();
                  });
                  DemoCaseRepository.instance.saveDraft(_intake);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF5A756B),
                  backgroundColor: Colors.transparent,
                  side: const BorderSide(color: Color(0xFFCFDFD6), width: 1.0),
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? 16 : 8, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                  minimumSize: const Size(0, 48),
                ),
                child: const Text(
                  "Skip for now",
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _currentStep = 13;
                      _intake = _buildCurrentDraft();
                    });
                    DemoCaseRepository.instance.saveDraft(_intake);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28654F),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: isDesktop ? 20 : 10, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                    shadowColor: const Color(0xFF28654F).withValues(alpha: 0.35),
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          "Continue to Review",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isSubmitting ? null : _handleBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: Text(
              _currentStep == 1 ? "Back" : "Previous",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: -0.1),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF28654F),
              backgroundColor: const Color(0xFFF1F6F2),
              side: const BorderSide(color: Color(0xFFBDD9C9), width: 1.2),
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 22 : 10, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
              minimumSize: const Size(0, 48),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF28654F),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 12, vertical: 13),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 3,
              shadowColor: const Color(0xFF28654F).withValues(alpha: 0.35),
              minimumSize: const Size(0, 48),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          isFinalStep ? "Submit Case" : "Continue",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isFinalStep ? Icons.check_circle_outline_rounded : Icons.arrow_forward_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _ExampleChip extends StatelessWidget {
  final String label;

  const _ExampleChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6F3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD4E5DB), width: 0.8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF28654F),
        ),
      ),
    );
  }
}