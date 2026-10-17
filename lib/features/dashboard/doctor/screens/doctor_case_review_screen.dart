import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/clinova_colors.dart';
import '../../patient/models/case_attachment_model.dart';
import '../../patient/models/case_intake_model.dart';
import '../../patient/services/case_attachment_repository.dart';
import '../../patient/services/demo_case_repository.dart';
import '../../patient/services/patient_profile_repository.dart';
import '../models/ai_case_summary_model.dart';
import '../models/doctor_assessment_model.dart';
import '../services/ai_case_summary_repository.dart';
import '../services/doctor_assessment_repository.dart';
import '../services/doctor_profile_repository.dart';

/// Clinova Doctor Case Review Screen
///
/// Comprehensive clinical case review screen for physicians to inspect
/// a patient's submitted intake responses, clinical history, and questionnaire answers.
///
/// Displays:
/// 1. Top Header: Back navigation, Chief Complaint / Title, Case Reference ID, Submission Date,
///    Dynamic Status Badge, and "Mark as In Review" action (updates state only on explicit user action).
/// 2. Patient & Case Overview: Patient name, ID, category, duration, severity, submission timestamp,
///    and matched demographic profile details (age, gender) without data fabrication.
/// 3. All 11 intake questionnaire steps presented in canonical order:
///    - Step 1: Chief Complaint
///    - Step 2: Duration
///    - Step 3: Severity
///    - Step 4: Associated Symptoms (multi-choice pills + other text)
///    - Step 5: Triggers, Relief & Additional Details
///    - Step 6: Previous Occurrences (Yes/No/Not sure + details)
///    - Step 7: Existing Medical Conditions (multi-choice pills + other text)
///    - Step 8: Allergies (multi-choice pills + other text)
///    - Step 9: Current Medications (Yes/No/Not sure + medication details)
///    - Step 10: Relevant Medical & Family History
///    - Step 11: Final Review & Submission Verification
/// 4. Doctor Assessment & Supervised Notes:
///    - Clinical assessment, doctor's observations, advice & recommendations,
///      follow-up instructions, and optional follow-up date picker.
///    - Save Draft: retains content locally without marking case reviewed or notifying patient.
///    - Finalize Review: validates required fields, prompts confirmation, updates status to Reviewed,
///      and publishes notes to Patient Care Notes.
/// 5. Clinova Botanical Aesthetic: Layered pale sage/mint leaves watermark (`ClinovaConstants.leavesAsset`),
///    non-blocking (`IgnorePointer`), clipped to rounded cards (`ClipRRect`), soft neumorphism palette.
/// 6. Responsive design: Seamlessly supports narrow mobile (390px) up to desktop.
class DoctorCaseReviewScreen extends StatefulWidget {
  final PatientCaseSummary? initialCase;
  final String? caseId;

  const DoctorCaseReviewScreen({
    super.key,
    this.initialCase,
    this.caseId,
  });

  @override
  State<DoctorCaseReviewScreen> createState() => _DoctorCaseReviewScreenState();
}

class _DoctorCaseReviewScreenState extends State<DoctorCaseReviewScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _clinicalAssessmentController;
  late final TextEditingController _prescriptionController;
  late final TextEditingController _observationsController;
  late final TextEditingController _adviceController;
  late final TextEditingController _followUpInstructionsController;
  DateTime? _followUpDate;

  bool _isFinalized = false;
  bool _isEditingFinalized = false;
  DateTime? _finalizedAt;
  DateTime? _lastSavedAt;
  String? _finalizedDoctorName;
  bool _isSavingDraft = false;
  bool _isFinalizing = false;
  String? _loadedCaseId;

  StreamSubscription<List<PatientCaseSummary>>? _caseSubscription;
  StreamSubscription<Map<String, DoctorAssessmentModel>>? _assessmentSubscription;
  StreamSubscription<Map<String, AiCaseSummaryModel>>? _summarySubscription;
  String? _targetCaseId;

  @override
  void initState() {
    super.initState();
    _clinicalAssessmentController = TextEditingController();
    _prescriptionController = TextEditingController();
    _observationsController = TextEditingController();
    _adviceController = TextEditingController();
    _followUpInstructionsController = TextEditingController();

    _targetCaseId = widget.initialCase?.id ?? widget.initialCase?.reference ?? widget.caseId;
    if (_targetCaseId != null) {
      _loadedCaseId = _targetCaseId;
      _loadAssessment(_targetCaseId!);
    }

    _caseSubscription = DemoCaseRepository.instance.casesStream.listen((_) {
      if (mounted) setState(() {});
    });

    _assessmentSubscription = DoctorAssessmentRepository.instance.assessmentsStream.listen((_) {
      if (mounted) setState(() {});
    });

    _summarySubscription = AiCaseSummaryRepository.instance.summariesStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final resolved = _resolveCase(context);
    if (resolved != null && _loadedCaseId != resolved.id) {
      _loadedCaseId = resolved.id;
      _loadAssessment(resolved.id);
      _ensureAiSummary(resolved);
    }
  }

  void _ensureAiSummary(PatientCaseSummary caseItem) {
    final summary = AiCaseSummaryRepository.instance.getSummary(caseItem.id) ??
        AiCaseSummaryRepository.instance.getSummary(caseItem.reference);
    if (summary == null || summary.isPending || summary.isFailed) {
      AiCaseSummaryRepository.instance.generateSummaryForCase(caseSummary: caseItem);
    }
  }

  @override
  void dispose() {
    _caseSubscription?.cancel();
    _assessmentSubscription?.cancel();
    _summarySubscription?.cancel();
    _clinicalAssessmentController.dispose();
    _prescriptionController.dispose();
    _observationsController.dispose();
    _adviceController.dispose();
    _followUpInstructionsController.dispose();
    super.dispose();
  }

  void _loadAssessment(String caseId) {
    final assessment = DoctorAssessmentRepository.instance.getAssessment(caseId);
    if (assessment != null) {
      _clinicalAssessmentController.text = assessment.clinicalAssessment;
      _prescriptionController.text = assessment.prescription;
      _observationsController.text = assessment.observations;
      _adviceController.text = assessment.adviceAndRecommendations;
      _followUpInstructionsController.text = assessment.followUpInstructions;
      _followUpDate = assessment.followUpDate;
      _isFinalized = assessment.isFinalized;
      _finalizedAt = assessment.finalizedAt;
      _lastSavedAt = assessment.lastSavedAt;
      _finalizedDoctorName = assessment.doctorName;
      _isEditingFinalized = false;
    } else {
      _clinicalAssessmentController.clear();
      _prescriptionController.clear();
      _observationsController.clear();
      _adviceController.clear();
      _followUpInstructionsController.clear();
      _followUpDate = null;
      _isFinalized = false;
      _finalizedAt = null;
      _lastSavedAt = null;
      _finalizedDoctorName = null;
      _isEditingFinalized = false;
    }
  }

  PatientCaseSummary? _resolveCase(BuildContext context) {
    // 1. If we have a targetCaseId, resolve from repository for latest live data
    if (_targetCaseId != null) {
      final found = DemoCaseRepository.instance.getCaseById(_targetCaseId!) ??
          DemoCaseRepository.instance.getCaseByReference(_targetCaseId!);
      if (found != null) return found;
    }

    if (widget.initialCase != null) {
      final found = DemoCaseRepository.instance.getCaseById(widget.initialCase!.id) ??
          DemoCaseRepository.instance.getCaseByReference(widget.initialCase!.reference);
      if (found != null) return found;
      return widget.initialCase;
    }

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is PatientCaseSummary) {
      _targetCaseId ??= args.id;
      final found = DemoCaseRepository.instance.getCaseById(args.id) ??
          DemoCaseRepository.instance.getCaseByReference(args.reference);
      return found ?? args;
    } else if (args is Map<String, dynamic>) {
      final rawCase = args['case'];
      if (rawCase is PatientCaseSummary) {
        _targetCaseId ??= rawCase.id;
        final found = DemoCaseRepository.instance.getCaseById(rawCase.id) ??
            DemoCaseRepository.instance.getCaseByReference(rawCase.reference);
        return found ?? rawCase;
      }
      final rawId = args['caseId'] as String? ?? args['id'] as String? ?? args['reference'] as String?;
      if (rawId != null) {
        _targetCaseId ??= rawId;
        final found = DemoCaseRepository.instance.getCaseById(rawId) ??
            DemoCaseRepository.instance.getCaseByReference(rawId);
        if (found != null) return found;
        return PatientCaseSummary.fromMap(args);
      }
      return PatientCaseSummary.fromMap(args);
    } else if (args is String) {
      _targetCaseId ??= args;
      final found = DemoCaseRepository.instance.getCaseById(args) ??
          DemoCaseRepository.instance.getCaseByReference(args);
      if (found != null) return found;
    }

    if (widget.caseId != null) {
      _targetCaseId ??= widget.caseId;
      final found = DemoCaseRepository.instance.getCaseById(widget.caseId!) ??
          DemoCaseRepository.instance.getCaseByReference(widget.caseId!);
      if (found != null) return found;
    }

    if (DemoCaseRepository.instance.cases.isNotEmpty) {
      return DemoCaseRepository.instance.cases.first;
    }

    return null;
  }

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.doctorDashboard);
    }
  }

  void _markAsInReview(PatientCaseSummary caseItem) {
    final currentDocName = DoctorProfileRepository.instance.profile.fullName;
    DemoCaseRepository.instance.updateCaseStatus(
      caseItem.id,
      "In Review",
      textColor: const Color(0xFF28654F),
      bgColor: const Color(0xFFE4F0E8),
      borderColor: const Color(0xFFBED4C6),
      assignedDoctor: currentDocName,
    );

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "Case status updated to 'In Review' for ${caseItem.reference}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF28654F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 768;
    final resolvedCase = _resolveCase(context);

    if (resolvedCase == null) {
      return Scaffold(
        backgroundColor: ClinovaColors.background,
        appBar: AppBar(
          backgroundColor: ClinovaColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E5D46)),
            tooltip: "Back to Dashboard",
            onPressed: () => _handleBack(context),
          ),
          title: const Text(
            "Case Review",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF19372B),
              letterSpacing: -0.2,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.folder_off_outlined, size: 48, color: Color(0xFF8DA39A)),
                const SizedBox(height: 16),
                const Text(
                  "Case not found",
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF19372B)),
                ),
                const SizedBox(height: 8),
                const Text(
                  "No saved records exist for this case reference.",
                  style: TextStyle(fontSize: 13, color: Color(0xFF5A756B)),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => _handleBack(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28654F),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Return to Dashboard"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final fullCase = resolvedCase.fullCase;

    return Scaffold(
      backgroundColor: ClinovaColors.background,
      appBar: AppBar(
        backgroundColor: ClinovaColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E5D46)),
          tooltip: "Back to Dashboard",
          onPressed: () => _handleBack(context),
        ),
        title: const Text(
          "Clinical Case Review",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF19372B),
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 32 : 18,
            vertical: isDesktop ? 24 : 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Header Summary & Actions Card
                  _buildHeaderCard(context, resolvedCase, isDesktop),
                  const SizedBox(height: 16),

                  // 2. Patient Demographics & Profile Card
                  _buildPatientOverviewCard(resolvedCase, fullCase, isDesktop),
                  const SizedBox(height: 16),

                  // 3. AI Case Summary (Clinical Decision-Support via n8n Orchestrator)
                  _buildAiSummarySection(context, resolvedCase, isDesktop),
                  const SizedBox(height: 16),

                  // 4. Step 1: Chief Complaint
                  _buildStep1Card(resolvedCase, fullCase, isDesktop),
                  const SizedBox(height: 16),

                  // 4. Steps 2 & 3: Duration & Severity
                  _buildStep2And3Card(resolvedCase, fullCase, isDesktop),
                  const SizedBox(height: 16),

                  // 5. Steps 4 & 5: Associated Symptoms, Triggers & Relief
                  _buildStep4And5Card(fullCase, isDesktop),
                  const SizedBox(height: 16),

                  // 6. Step 6: Previous Occurrences
                  _buildStep6Card(fullCase, isDesktop),
                  const SizedBox(height: 16),

                  // 7. Steps 7 & 8: Medical Conditions & Allergies
                  _buildStep7And8Card(fullCase, isDesktop),
                  const SizedBox(height: 16),

                  // 8. Step 9: Current Medications
                  _buildStep9Card(fullCase, isDesktop),
                  const SizedBox(height: 16),

                  // 9. Step 10: Relevant Medical & Family History
                  _buildStep10Card(fullCase, isDesktop),
                  const SizedBox(height: 16),

                  // 10. Step 11: Specific Inquiries & Consultation Goals (Optional)
                  _buildInquiriesCard(fullCase, isDesktop),
                  if (fullCase?.additionalConcerns?.trim().isNotEmpty == true)
                    const SizedBox(height: 16),

                  // 11. Step 12: Supporting Medical Documents (Optional)
                  _buildSupportingDocumentsCard(context, resolvedCase, fullCase, isDesktop),
                  const SizedBox(height: 16),

                  // 12. Final Review & Submission Information
                  _buildStep11Card(resolvedCase, fullCase, isDesktop),
                  const SizedBox(height: 18),

                  // 11. Doctor Assessment & Supervised Notes Section
                  _buildDoctorAssessmentSection(context, resolvedCase, isDesktop),
                  const SizedBox(height: 16),

                  // 12. Clinical Review Notice
                  _buildStatusNoticeCard(resolvedCase, isDesktop),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. Header Summary Card ---
  Widget _buildHeaderCard(BuildContext context, PatientCaseSummary caseItem, bool isDesktop) {
    final statusLower = caseItem.status.toLowerCase();
    final isInReview = statusLower.contains('in review');
    final isReviewed = statusLower.contains('reviewed');
    final canMarkInReview = !isInReview && !isReviewed;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCECE1), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(-3, -3),
            blurRadius: 7,
          ),
          BoxShadow(
            color: Color(0xFFBED4C6),
            offset: Offset(4, 5),
            blurRadius: 12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Botanical leaf watermark in top right corner (opacity 11%)
            Positioned(
              right: -25,
              top: -20,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.11,
                  child: Image.asset(
                    ClinovaConstants.leavesAsset,
                    height: 140,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isDesktop ? 22 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta Row: Reference, Category, and Current Status Badge
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F2EC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFD2E3D8), width: 0.8),
                            ),
                            child: Text(
                              caseItem.reference,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E5D46),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                          if (caseItem.category != null && caseItem.category!.trim().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F5F2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFDBE7E0), width: 0.8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.category_outlined, size: 12, color: Color(0xFF436B5C)),
                                  const SizedBox(width: 4),
                                  Text(
                                    caseItem.category!.trim(),
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF325749),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: caseItem.statusBgColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: caseItem.statusBorderColor, width: 0.8),
                        ),
                        child: Text(
                          caseItem.status,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: caseItem.statusTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Case Title / Chief Complaint
                  Text(
                    caseItem.title,
                    style: TextStyle(
                      fontSize: isDesktop ? 20 : 17.5,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF19372B),
                      letterSpacing: -0.3,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Submission Date & Assigned Clinician Row
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF6B8B7B)),
                          const SizedBox(width: 6),
                          Text(
                            "Submitted: ${caseItem.date}",
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF5A756B),
                            ),
                          ),
                        ],
                      ),
                      if (caseItem.doctor != null && caseItem.doctor!.trim().isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.medical_services_outlined, size: 14, color: Color(0xFF6B8B7B)),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                "Assigned Clinician: ${caseItem.doctor!.trim()}",
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF5A756B),
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  // Doctor Workflow Controls: Mark as In Review
                  if (canMarkInReview) ...[
                    const SizedBox(height: 16),
                    Container(height: 1, color: const Color(0xFFE2EFE7)),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 16,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 200),
                          child: Text(
                            "Ready to begin clinical evaluation?",
                            style: TextStyle(
                              fontSize: isDesktop ? 13.5 : 12.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF436B5C),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _markAsInReview(caseItem),
                          icon: const Icon(Icons.assignment_outlined, size: 16),
                          label: const Text(
                            "Mark as In Review",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF28654F),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. Patient & Case Overview Card ---
  Widget _buildPatientOverviewCard(
    PatientCaseSummary caseItem,
    CaseIntakeModel? fullCase,
    bool isDesktop,
  ) {
    final patientName = caseItem.patientName ?? "Aarav Sharma";
    final patientId = caseItem.patientId ?? "PAT-8842";
    final profile = PatientProfileRepository.instance.profile;

    // Check if profile matches patient name
    final bool matchesProfile = profile.fullName.trim().toLowerCase() == patientName.trim().toLowerCase();
    final String? ageDisplay = matchesProfile && profile.age != null ? "${profile.age} yrs" : null;
    final String? genderDisplay = matchesProfile && profile.gender?.trim().isNotEmpty == true ? profile.gender!.trim() : null;

    final duration = fullCase?.duration ?? "Not specified";
    final severity = fullCase?.severity ?? "Not specified";
    final category = caseItem.category ?? "General Health";

    return _buildSectionCard(
      title: "Patient & Case Overview",
      icon: Icons.person_outline_rounded,
      isDesktop: isDesktop,
      children: [
        // Name & ID Row
        Row(
          children: [
            Expanded(
              child: _buildInfoRow("Patient Name", patientName),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoRow("Patient Identifier", patientId),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Demographics row if available
        if (ageDisplay != null || genderDisplay != null) ...[
          Row(
            children: [
              if (ageDisplay != null)
                Expanded(
                  child: _buildInfoRow("Age", ageDisplay),
                ),
              if (ageDisplay != null && genderDisplay != null)
                const SizedBox(width: 16),
              if (genderDisplay != null)
                Expanded(
                  child: _buildInfoRow("Gender", genderDisplay),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],

        // Overview clinical tags
        Row(
          children: [
            Expanded(
              child: _buildInfoRow("Clinical Category", category),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoRow("Duration & Severity", "$duration • $severity"),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F7F3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFD4E6DB), width: 0.8),
          ),
          child: const Row(
            children: [
              Icon(Icons.shield_outlined, size: 14, color: Color(0xFF28654F)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Patient verified. Intake submitted under clinical privacy consent.",
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF233A32),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- AI Case Summary Section (via n8n Orchestrator) ---
  Widget _buildAiSummarySection(
    BuildContext context,
    PatientCaseSummary caseItem,
    bool isDesktop,
  ) {
    final summary = AiCaseSummaryRepository.instance.getSummary(caseItem.id) ??
        AiCaseSummaryRepository.instance.getSummary(caseItem.reference);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCECE1), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(-3, -3),
            blurRadius: 7,
          ),
          BoxShadow(
            color: Color(0xFFBED4C6),
            offset: Offset(4, 5),
            blurRadius: 12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Layered botanical leaf watermark in lower right corner (opacity 8%)
            Positioned(
              right: -20,
              bottom: -20,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.08,
                  child: Image.asset(
                    ClinovaConstants.leavesAsset,
                    height: 130,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isDesktop ? 22 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Sparkles Icon, Title & Status Badge
                  _buildAiSummaryHeader(summary, isDesktop),
                  const SizedBox(height: 14),

                  // Mandatory Clinical Review Disclaimer Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F2EC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFCCE2D5), width: 0.8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_outlined, size: 15, color: Color(0xFF1E5D46)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "AI-generated summary — requires physician review. Clinical decision support only.",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E5D46),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Body Content based on Summary State
                  if (summary != null && summary.isReady)
                    _buildAiSummaryReadyContent(context, caseItem, summary, isDesktop)
                  else if (summary != null && summary.isGenerating)
                    _buildAiSummaryGeneratingContent(isDesktop)
                  else if (summary != null && summary.isFailed)
                    _buildAiSummaryFailedContent(caseItem, summary, isDesktop)
                  else
                    _buildAiSummaryPendingContent(caseItem, isDesktop),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiSummaryHeader(AiCaseSummaryModel? summary, bool isDesktop) {
    Widget statusBadge;
    if (summary != null && summary.isReady) {
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFD6EDE0),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFB5DCBF), width: 0.8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF1E5D46)),
            SizedBox(width: 4),
            Text(
              "Ready",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E5D46),
              ),
            ),
          ],
        ),
      );
    } else if (summary != null && summary.isGenerating) {
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFBBDEFB), width: 0.8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFF1976D2)),
            ),
            SizedBox(width: 6),
            Text(
              "Generating...",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1976D2),
              ),
            ),
          ],
        ),
      );
    } else if (summary != null && summary.isFailed) {
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFFBE9E7),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFFFCCBC), width: 0.8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 12, color: Color(0xFFD84315)),
            SizedBox(width: 4),
            Text(
              "Failed",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFD84315),
              ),
            ),
          ],
        ),
      );
    } else {
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F4F1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD5E2D9), width: 0.8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty_rounded, size: 12, color: Color(0xFF5A756B)),
            SizedBox(width: 4),
            Text(
              "Pending",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF5A756B),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFFE4F0E8),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            size: 18,
            color: Color(0xFF28654F),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "AI Case Summary",
                style: TextStyle(
                  fontSize: isDesktop ? 16 : 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF19372B),
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                "Automated intake synthesis via n8n orchestrator.",
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF5A756B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        statusBadge,
      ],
    );
  }

  Widget _buildAiSummaryReadyContent(
    BuildContext context,
    PatientCaseSummary caseItem,
    AiCaseSummaryModel summary,
    bool isDesktop,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Clinical Narrative Summary Block
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F8F4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFD4E8DC), width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.notes_rounded, size: 15, color: Color(0xFF28654F)),
                  SizedBox(width: 6),
                  Text(
                    "Executive Clinical Briefing",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF28654F),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                summary.summaryText.isNotEmpty
                    ? summary.summaryText
                    : "No narrative summary provided.",
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF19372B),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Timeline & Severity
        if (summary.symptomTimelineAndSeverity.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF5F1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDCE9E1), width: 0.8),
            ),
            child: Row(
              children: [
                const Icon(Icons.timeline_rounded, size: 15, color: Color(0xFF436B5C)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: "Timeline & Severity: ",
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF28654F),
                      ),
                      children: [
                        TextSpan(
                          text: summary.symptomTimelineAndSeverity,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF19372B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // 3. Relevant Positive Findings (bullet list)
        if (summary.relevantPositiveFindings.isNotEmpty) ...[
          _buildFindingsCard(
            title: "Relevant Positive Findings",
            icon: Icons.check_circle_outline_rounded,
            iconColor: const Color(0xFF28654F),
            items: summary.relevantPositiveFindings,
            badgeLabel: "Reported Present",
            badgeColor: const Color(0xFFD6EDE0),
            badgeTextColor: const Color(0xFF1E5D46),
          ),
          const SizedBox(height: 12),
        ],

        // 4. Relevant Negative Findings (bullet list - only patient-supported)
        if (summary.relevantNegativeFindings.isNotEmpty) ...[
          _buildFindingsCard(
            title: "Relevant Negative Findings",
            subtitle: "Explicitly reported absent or denied by patient in questionnaire",
            icon: Icons.remove_circle_outline_rounded,
            iconColor: const Color(0xFF5A756B),
            items: summary.relevantNegativeFindings,
            badgeLabel: "Explicitly Denied",
            badgeColor: const Color(0xFFE8EEEC),
            badgeTextColor: const Color(0xFF436B5C),
          ),
          const SizedBox(height: 12),
        ],

        // 5. Medical History & Medications
        if (summary.medicalHistoryAndMedications.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7F5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFDFECE4), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.medical_information_outlined, size: 14, color: Color(0xFF28654F)),
                    SizedBox(width: 6),
                    Text(
                      "Medical History & Medications",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF28654F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  summary.medicalHistoryAndMedications,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF233A32),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 6. Clarification Points for Attending Physician
        if (summary.missingOrUnclearInformation.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE4E8D3), width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.help_outline_rounded, size: 15, color: Color(0xFF7A6B28)),
                    SizedBox(width: 6),
                    Text(
                      "Points for Physician Clarification",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B5C1C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final item in summary.missingOrUnclearInformation) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 5),
                          child: Icon(Icons.circle, size: 5, color: Color(0xFF8A7932)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF383318),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // 7. Footer Row: Generation timestamp & Re-run action
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.schedule_rounded, size: 13, color: Color(0xFF6B8B7B)),
                const SizedBox(width: 5),
                Text(
                  summary.generatedAt != null
                      ? "Generated: ${_formatDateTime(summary.generatedAt)}"
                      : "Generated via n8n",
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF5A756B),
                  ),
                ),
              ],
            ),
            TextButton.icon(
              onPressed: () => _retryAiSummary(caseItem),
              icon: const Icon(Icons.refresh_rounded, size: 14),
              label: const Text(
                "Re-run Summary",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF28654F),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFindingsCard({
    required String title,
    String? subtitle,
    required IconData icon,
    required Color iconColor,
    required List<String> items,
    required String badgeLabel,
    required Color badgeColor,
    required Color badgeTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8F5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFD6EAE0), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 15, color: iconColor),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: iconColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: badgeTextColor,
                  ),
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5A756B),
              ),
            ),
          ],
          const SizedBox(height: 8),
          for (final item in items) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Icon(Icons.circle, size: 5, color: iconColor),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF19372B),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAiSummaryGeneratingContent(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD3E7DC), width: 1.0),
      ),
      child: const Center(
        child: Column(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Color(0xFF28654F),
              ),
            ),
            SizedBox(height: 12),
            Text(
              "Generating AI Case Summary...",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF19372B),
              ),
            ),
            SizedBox(height: 4),
            Text(
              "Contacting n8n orchestration workflow to synthesize timeline and clinical findings.",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF5A756B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiSummaryFailedContent(
    PatientCaseSummary caseItem,
    AiCaseSummaryModel summary,
    bool isDesktop,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF5F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF5CFCA), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBE3E0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 18,
                  color: Color(0xFFB33A2B),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Summary Generation Failed",
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF90281B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            summary.errorMessage ??
                "Unable to connect to the n8n webhook. Please ensure the workflow is running.",
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5A4441),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Note: The patient's case and intake questionnaire answers are fully preserved.",
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B8B7B),
            ),
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: () => _retryAiSummary(caseItem),
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text(
              "Retry Summary Generation",
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF28654F),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiSummaryPendingContent(
    PatientCaseSummary caseItem,
    bool isDesktop,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD3E7DC), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "AI summary has not been generated for this case yet.",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF233A32),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Trigger n8n workflow to generate an executive briefing, timeline, and findings.",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF5A756B),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _retryAiSummary(caseItem),
            icon: const Icon(Icons.auto_awesome_rounded, size: 15),
            label: const Text(
              "Generate AI Summary",
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF28654F),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _retryAiSummary(PatientCaseSummary caseItem) async {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Requesting AI case summary via n8n orchestrator...",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Color(0xFF28654F),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );

    await AiCaseSummaryRepository.instance.retryGeneration(caseItem);
  }

  // --- Step 1: Chief Complaint ---
  Widget _buildStep1Card(
    PatientCaseSummary caseItem,
    CaseIntakeModel? fullCase,
    bool isDesktop,
  ) {
    final complaintText = fullCase?.chiefConcern.trim().isNotEmpty == true
        ? fullCase!.chiefConcern.trim()
        : caseItem.title;

    return _buildSectionCard(
      title: "Primary Health Concern",
      subtitle: "Step 1: Chief Complaint — What health concern would you like to discuss?",
      icon: Icons.health_and_safety_outlined,
      isDesktop: isDesktop,
      children: [
        _buildInfoRow("Chief Concern / Complaint", complaintText),
      ],
    );
  }

  // --- Steps 2 & 3: Duration & Severity ---
  Widget _buildStep2And3Card(
    PatientCaseSummary caseItem,
    CaseIntakeModel? fullCase,
    bool isDesktop,
  ) {
    final durationText = fullCase?.duration ?? "Not provided";
    final severityText = fullCase?.severity ?? "Not provided";

    return _buildSectionCard(
      title: "Steps 2 & 3: Duration & Severity",
      subtitle: "Symptom timeline and intensity assessed by patient",
      icon: Icons.timer_outlined,
      isDesktop: isDesktop,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoRow("Step 2: Duration", durationText),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoRow("Step 3: Severity", severityText),
            ),
          ],
        ),
      ],
    );
  }

  // --- Steps 4 & 5: Associated Symptoms & Details ---
  Widget _buildStep4And5Card(CaseIntakeModel? fullCase, bool isDesktop) {
    final symptoms = fullCase?.associatedSymptoms ?? const [];
    final otherSymptom = fullCase?.otherAssociatedSymptom?.trim();
    final triggersRelief = fullCase?.symptomDetails?.trim();

    return _buildSectionCard(
      title: "Associated Symptoms & Triggers",
      subtitle: "Steps 4 & 5: Associated symptoms, triggers, and relieving factors",
      icon: Icons.sick_outlined,
      isDesktop: isDesktop,
      children: [
        const Text(
          "Step 4: Associated Symptoms",
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B8B7B),
          ),
        ),
        const SizedBox(height: 8),
        if (symptoms.isEmpty)
          const Text(
            "None of these",
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF19372B),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: symptoms.map((symptom) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4EE),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCCE2D5), width: 0.8),
                ),
                child: Text(
                  symptom,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E5D46),
                  ),
                ),
              );
            }).toList(),
          ),
        if (otherSymptom != null && otherSymptom.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInfoRow("Other Symptoms Specified", otherSymptom),
        ],
        const SizedBox(height: 14),
        _buildInfoRow(
          "Step 5: Triggers, Relief & Additional Details",
          (triggersRelief != null && triggersRelief.isNotEmpty) ? triggersRelief : "None recorded",
        ),
      ],
    );
  }

  // --- Step 6: Previous Occurrences ---
  Widget _buildStep6Card(CaseIntakeModel? fullCase, bool isDesktop) {
    final previousOccurrences = fullCase?.previousOccurrences ?? "Not provided";
    final details = fullCase?.previousOccurrenceDetails?.trim();

    String displayVal = previousOccurrences;
    if (details != null && details.isNotEmpty) {
      displayVal += " — $details";
    }

    return _buildSectionCard(
      title: "Step 6: Previous Occurrences",
      subtitle: "Have you experienced this problem before?",
      icon: Icons.replay_rounded,
      isDesktop: isDesktop,
      children: [
        _buildInfoRow("Prior Occurrences & Treatment History", displayVal),
      ],
    );
  }

  // --- Steps 7 & 8: Medical Conditions & Allergies ---
  Widget _buildStep7And8Card(CaseIntakeModel? fullCase, bool isDesktop) {
    final conditions = fullCase?.existingConditions ?? const [];
    final otherCondition = fullCase?.otherConditionDetails?.trim();
    final allergies = fullCase?.allergies ?? const [];
    final allergyDetails = fullCase?.allergyDetails?.trim();

    return _buildSectionCard(
      title: "Medical Context & Background",
      subtitle: "Steps 7 & 8: Ongoing conditions and documented allergies",
      icon: Icons.medical_information_outlined,
      isDesktop: isDesktop,
      children: [
        const Text(
          "Step 7: Existing Medical Conditions",
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B8B7B),
          ),
        ),
        const SizedBox(height: 8),
        if (conditions.isEmpty)
          const Text(
            "None known",
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF19372B),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: conditions.map((cond) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F6F3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD4E5DB), width: 0.8),
                ),
                child: Text(
                  cond,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF28654F),
                  ),
                ),
              );
            }).toList(),
          ),
        if (otherCondition != null && otherCondition.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildInfoRow("Other Medical Condition Details", otherCondition),
        ],
        const SizedBox(height: 14),
        const Text(
          "Step 8: Allergies",
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B8B7B),
          ),
        ),
        const SizedBox(height: 8),
        if (allergies.isEmpty)
          const Text(
            "No known allergies",
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF19372B),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allergies.map((allergy) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F6F3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD4E5DB), width: 0.8),
                ),
                child: Text(
                  allergy,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF28654F),
                  ),
                ),
              );
            }).toList(),
          ),
        if (allergyDetails != null && allergyDetails.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildInfoRow("Allergy Details", allergyDetails),
        ],
      ],
    );
  }

  // --- Step 9: Current Medications ---
  Widget _buildStep9Card(CaseIntakeModel? fullCase, bool isDesktop) {
    final takesMeds = fullCase?.takesMedications ?? "Not provided";
    final medDetails = fullCase?.medicationDetails?.trim();

    String displayVal = takesMeds;
    if (medDetails != null && medDetails.isNotEmpty) {
      displayVal += " — $medDetails";
    }

    return _buildSectionCard(
      title: "Step 9: Current Medications",
      subtitle: "Are you currently taking any medicines or supplements?",
      icon: Icons.medication_outlined,
      isDesktop: isDesktop,
      children: [
        _buildInfoRow("Current Medications / Supplements", displayVal),
      ],
    );
  }

  // --- Step 10: Relevant Medical & Family History ---
  Widget _buildStep10Card(CaseIntakeModel? fullCase, bool isDesktop) {
    final history = fullCase?.medicalFamilyHistory?.trim();

    return _buildSectionCard(
      title: "Step 10: Relevant Medical & Family History",
      subtitle: "Surgeries, hospitalizations, or family conditions",
      icon: Icons.history_edu_rounded,
      isDesktop: isDesktop,
      children: [
        _buildInfoRow(
          "Medical & Family History Details",
          (history != null && history.isNotEmpty) ? history : "None provided",
        ),
      ],
    );
  }

  // --- Step 11: Specific Inquiries & Consultation Goals ---
  Widget _buildInquiriesCard(CaseIntakeModel? fullCase, bool isDesktop) {
    final inquiries = fullCase?.additionalConcerns?.trim();
    if (inquiries == null || inquiries.isEmpty) {
      return const SizedBox.shrink();
    }
    return _buildSectionCard(
      title: "Step 11: Consultation Goals & Questions",
      subtitle: "Specific inquiries the patient asked the doctor to address",
      icon: Icons.help_outline_rounded,
      isDesktop: isDesktop,
      children: [
        _buildInfoRow("Patient Goals & Questions", inquiries),
      ],
    );
  }

  // --- Step 12: Supporting Medical Documents ---
  Widget _buildSupportingDocumentsCard(
    BuildContext context,
    PatientCaseSummary caseItem,
    CaseIntakeModel? fullCase,
    bool isDesktop,
  ) {
    final attachments = fullCase?.attachments.isNotEmpty == true
        ? fullCase!.attachments
        : caseItem.attachments;

    return _buildSectionCard(
      title: "Supporting Medical Documents",
      subtitle: "Step 12: Attached medical reports, scans, and laboratory documentation",
      icon: Icons.attach_file_rounded,
      isDesktop: isDesktop,
      children: [
        if (attachments.isEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAF8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCECE1), width: 0.8),
            ),
            child: Row(
              children: const [
                Icon(Icons.folder_open_rounded, size: 18, color: Color(0xFF6B8B7B)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "No supporting medical documents attached to this case (Optional step was skipped by patient).",
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5A756B),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${attachments.length} document${attachments.length > 1 ? 's' : ''} available for clinical inspection",
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF28654F),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4EFE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 12, color: Color(0xFF28654F)),
                    SizedBox(width: 4),
                    Text(
                      "Secure • Private",
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF28654F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...attachments.map((att) => _buildDoctorAttachmentRow(context, att, caseItem)),
        ],
      ],
    );
  }

  Widget _buildDoctorAttachmentRow(
    BuildContext context,
    CaseAttachmentModel att,
    PatientCaseSummary caseItem,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FCFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDECE2), width: 1.0),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 440;
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: att.accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(att.icon, color: att.accentColor, size: 19),
                    ),
                    const SizedBox(width: 10),
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
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF436B5C),
                                ),
                              ),
                              const Text("•", style: TextStyle(fontSize: 10, color: Color(0xFF9AB2A6))),
                              Text(
                                att.formattedSize,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6B8B7B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _handleViewAttachment(context, att, caseItem),
                      icon: const Icon(Icons.visibility_outlined, size: 14),
                      label: const Text(
                        "View",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF28654F),
                        side: const BorderSide(color: Color(0xFFC4DCCF), width: 1.0),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _handleDownloadAttachment(context, att, caseItem),
                      icon: const Icon(Icons.download_rounded, size: 14),
                      label: const Text(
                        "Download",
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF28654F),
                        side: const BorderSide(color: Color(0xFFC4DCCF), width: 1.0),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
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
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF436B5C),
                          ),
                        ),
                        const Text("•", style: TextStyle(fontSize: 10, color: Color(0xFF9AB2A6))),
                        Text(
                          att.formattedSize,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF6B8B7B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _handleViewAttachment(context, att, caseItem),
                icon: const Icon(Icons.visibility_outlined, size: 14),
                label: const Text(
                  "View",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF28654F),
                  side: const BorderSide(color: Color(0xFFC4DCCF), width: 1.0),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.download_rounded, size: 18, color: Color(0xFF28654F)),
                tooltip: "Download Document",
                onPressed: () => _handleDownloadAttachment(context, att, caseItem),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _handleViewAttachment(
    BuildContext context,
    CaseAttachmentModel att,
    PatientCaseSummary caseItem,
  ) async {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text("Accessing secure preview for: ${att.originalFilename}"),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF28654F),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    if (att.storagePath.isNotEmpty) {
      await CaseAttachmentRepository.instance.getSignedUrl(att.storagePath);
    }
  }

  Future<void> _handleDownloadAttachment(
    BuildContext context,
    CaseAttachmentModel att,
    PatientCaseSummary caseItem,
  ) async {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.downloading_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text("Downloading secure attachment: ${att.originalFilename}"),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF28654F),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );

    if (att.storagePath.isNotEmpty) {
      await CaseAttachmentRepository.instance.downloadAttachment(att.storagePath);
    }
  }
  Widget _buildStep11Card(
    PatientCaseSummary caseItem,
    CaseIntakeModel? fullCase,
    bool isDesktop,
  ) {
    final submissionDate = caseItem.submittedAt != null
        ? "${caseItem.submittedAt!.day.toString().padLeft(2, '0')}/${caseItem.submittedAt!.month.toString().padLeft(2, '0')}/${caseItem.submittedAt!.year} ${caseItem.submittedAt!.hour.toString().padLeft(2, '0')}:${caseItem.submittedAt!.minute.toString().padLeft(2, '0')}"
        : caseItem.date;

    return _buildSectionCard(
      title: "Step 11: Final Review & Submission Information",
      subtitle: "Intake submission metadata and verified consent",
      icon: Icons.verified_outlined,
      isDesktop: isDesktop,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoRow("Submission Timestamp", submissionDate),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoRow("Submission Reference", caseItem.reference),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          "Submission Status",
          fullCase?.status == 'submitted'
              ? "Submitted by patient after 11-step verification"
              : "Completed intake recorded on file",
        ),
      ],
    );
  }

  // --- Helper Date Formatting ---
  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year} at $hour:$min';
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _pickFollowUpDate() async {
    final now = DateTime.now();
    final initialDate = _followUpDate ?? now.add(const Duration(days: 7));
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(now) ? now : initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF28654F),
              onPrimary: Colors.white,
              onSurface: Color(0xFF19372B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _followUpDate = picked);
    }
  }

  Future<void> _saveDraft(PatientCaseSummary caseItem) async {
    if (_isSavingDraft) return;
    setState(() => _isSavingDraft = true);

    final currentDocName = DoctorProfileRepository.instance.profile.fullName;
    final now = DateTime.now();
    final assessment = DoctorAssessmentModel(
      caseId: caseItem.id,
      doctorName: currentDocName.isNotEmpty ? currentDocName : "Attending Physician",
      clinicalAssessment: _clinicalAssessmentController.text.trim(),
      prescription: _prescriptionController.text.trim(),
      observations: _observationsController.text.trim(),
      adviceAndRecommendations: _adviceController.text.trim(),
      followUpInstructions: _followUpInstructionsController.text.trim(),
      followUpDate: _followUpDate,
      isFinalized: false,
      lastSavedAt: now,
    );

    final success = await DoctorAssessmentRepository.instance.saveDraft(assessment);

    if (!mounted) return;
    setState(() {
      _isSavingDraft = false;
      _lastSavedAt = now;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    if (success) {
      final timeStr = _formatDateTime(now);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Draft assessment saved ($timeStr). Not published to patient.",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF28654F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _finalizeReview(PatientCaseSummary caseItem) async {
    if (_isFinalizing) return;

    // Validate required fields
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Please complete all required fields (Clinical Assessment, Observations, Advice) before finalizing.",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF9E4738),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    // Require explicit confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _buildFinalizeConfirmationDialog(ctx, caseItem),
    );

    if (confirmed != true) return;

    setState(() => _isFinalizing = true);

    final currentDocName = DoctorProfileRepository.instance.profile.fullName;
    final now = DateTime.now();
    final assessment = DoctorAssessmentModel(
      caseId: caseItem.id,
      doctorName: currentDocName.isNotEmpty ? currentDocName : "Attending Physician",
      clinicalAssessment: _clinicalAssessmentController.text.trim(),
      prescription: _prescriptionController.text.trim(),
      observations: _observationsController.text.trim(),
      adviceAndRecommendations: _adviceController.text.trim(),
      followUpInstructions: _followUpInstructionsController.text.trim(),
      followUpDate: _followUpDate,
      isFinalized: true,
      finalizedAt: _finalizedAt ?? now,
      lastSavedAt: now,
    );

    final success = await DoctorAssessmentRepository.instance.finalizeAssessment(
      assessment,
      caseReference: caseItem.reference,
    );

    if (!mounted) return;
    setState(() {
      _isFinalizing = false;
      _isFinalized = true;
      _isEditingFinalized = false;
      _finalizedAt = assessment.finalizedAt;
      _lastSavedAt = assessment.lastSavedAt;
      _finalizedDoctorName = assessment.doctorName;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.verified_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "Review finalized! Case status updated to 'Reviewed' and published to Patient Care Notes.",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF28654F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _buildFinalizeConfirmationDialog(BuildContext context, PatientCaseSummary caseItem) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color(0xFFF7FBF8),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      elevation: 6,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned(
                right: -15,
                bottom: -15,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.08,
                    child: Image.asset(
                      ClinovaConstants.leavesAsset,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCEFE3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.verified_user_outlined,
                            size: 22,
                            color: Color(0xFF1E5D46),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            "Finalize Clinical Review",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF19372B),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      "You are about to finalize the clinical evaluation for ${caseItem.reference} (${caseItem.title}).",
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF233A32),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF4EE),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFD2E6DA), width: 0.8),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.visibility_outlined, size: 15, color: Color(0xFF28654F)),
                              SizedBox(width: 6),
                              Text(
                                "Notice on Patient Visibility",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF28654F),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          Text(
                            "Finalized observations, advice, and follow-up instructions will immediately become visible to the patient on their Care Notes & Case Details screen. Prescription and medications will also be issued. Case review status will be updated to 'Reviewed'.",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF3B574B),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 10,
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF4A685B),
                            side: const BorderSide(color: Color(0xFFC7DBD0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                          child: const Text(
                            "Cancel",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).pop(true),
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                          label: const Text(
                            "Finalize & Publish",
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF28654F),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    String? helperText,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF3F8F5),
      hintText: hintText,
      hintStyle: const TextStyle(
        fontSize: 13,
        color: Color(0xFF8BA698),
        fontWeight: FontWeight.w400,
      ),
      helperText: helperText,
      helperStyle: const TextStyle(
        fontSize: 11,
        color: Color(0xFF6B8B7B),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD2E3D8), width: 1.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD2E3D8), width: 1.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF28654F), width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC04E40), width: 1.2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFC04E40), width: 1.6),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool isRequired = false}) {
    return Text.rich(
      TextSpan(
        text: label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1E5D46),
        ),
        children: [
          if (isRequired)
            const TextSpan(
              text: " *",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFFB03D30),
              ),
            ),
        ],
      ),
    );
  }

  // --- Doctor Assessment & Supervised Notes Section ---
  Widget _buildDoctorAssessmentSection(BuildContext context, PatientCaseSummary caseItem, bool isDesktop) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDCECE1), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(-3, -3),
            blurRadius: 7,
          ),
          BoxShadow(
            color: Color(0xFFBED4C6),
            offset: Offset(4, 5),
            blurRadius: 12,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            // Subtle botanical watermark in lower right corner
            Positioned(
              right: -20,
              bottom: -20,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.08,
                  child: Image.asset(
                    ClinovaConstants.leavesAsset,
                    height: 130,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isDesktop ? 24 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row: Icon, Title & Status Pill
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE4F0E8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.rate_review_outlined,
                          size: 20,
                          color: Color(0xFF28654F),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Doctor Assessment & Supervised Notes",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF19372B),
                                letterSpacing: -0.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              "Physician observations, diagnostic impressions, advice, and patient follow-up guidance.",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF5A756B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status Badge
                      if (_isFinalized && !_isEditingFinalized)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD6EDE0),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFB5DCBF), width: 0.8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF1E5D46)),
                              SizedBox(width: 4),
                              Text(
                                "Finalized",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1E5D46),
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_lastSavedAt != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F2EC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFD2E3D8), width: 0.8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_note_rounded, size: 13, color: Color(0xFF28654F)),
                              SizedBox(width: 4),
                              Text(
                                "Draft",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF28654F),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F7F3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFDCECE1), width: 0.8),
                          ),
                          child: const Text(
                            "New",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF5A756B),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(height: 1, color: const Color(0xFFE5EFE8)),
                  const SizedBox(height: 18),

                  if (_isFinalized && !_isEditingFinalized)
                    _buildFinalizedView(context, caseItem, isDesktop)
                  else
                    _buildEditableForm(context, caseItem, isDesktop),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Finalized Read-Only View ---
  Widget _buildFinalizedView(BuildContext context, PatientCaseSummary caseItem, bool isDesktop) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Finalized Status Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE5F3EB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFE0CE), width: 1.0),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 20,
                color: Color(0xFF1B6349),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Review Finalized by ${_finalizedDoctorName ?? 'Attending Physician'}",
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF145338),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _finalizedAt != null
                          ? "Finalized on ${_formatDateTime(_finalizedAt)}. Visible in Patient Care Notes."
                          : "Visible in Patient Care Notes.",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF28654F),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        _buildFinalizedBlock(
          "Clinical Assessment",
          _clinicalAssessmentController.text,
          Icons.health_and_safety_outlined,
        ),
        const SizedBox(height: 12),

        if (_prescriptionController.text.trim().isNotEmpty) ...[
          _buildFinalizedBlock(
            "Prescription & Medications (Rx)",
            _prescriptionController.text,
            Icons.medication_outlined,
          ),
          const SizedBox(height: 12),
        ],

        _buildFinalizedBlock(
          "Doctor's Observations",
          _observationsController.text,
          Icons.visibility_outlined,
        ),
        const SizedBox(height: 12),

        _buildFinalizedBlock(
          "Advice & Recommendations",
          _adviceController.text,
          Icons.lightbulb_outline_rounded,
        ),
        if (_followUpInstructionsController.text.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildFinalizedBlock(
            "Follow-up Instructions",
            _followUpInstructionsController.text,
            Icons.notification_important_outlined,
          ),
        ],
        if (_followUpDate != null) ...[
          const SizedBox(height: 12),
          _buildFinalizedBlock(
            "Recommended Follow-up Date",
            _formatDate(_followUpDate),
            Icons.calendar_month_outlined,
          ),
        ],
        const SizedBox(height: 18),

        // Edit button requiring explicit clinician action
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _isEditingFinalized = true);
              },
              icon: const Icon(Icons.edit_note_rounded, size: 18),
              label: const Text(
                "Edit Finalized Notes",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF1E5D46),
                side: const BorderSide(color: Color(0xFF28654F), width: 1.2),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinalizedBlock(String title, String content, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7F3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDBECE1), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: const Color(0xFF28654F)),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF28654F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content.trim().isNotEmpty ? content.trim() : "None provided",
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF19372B),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  // --- Editable Form (Draft / New / Editing Finalized) ---
  Widget _buildEditableForm(BuildContext context, PatientCaseSummary caseItem, bool isDesktop) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isEditingFinalized) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7E6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFD591), width: 1.0),
              ),
              child: const Row(
                children: [
                  Icon(Icons.edit_attributes_outlined, color: Color(0xFFD46B08), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "You are editing a finalized review. Saving updates will sync modifications to the patient's care notes.",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF873800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else if (_lastSavedAt != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFE9F4EE),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFCFE4D7), width: 0.8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bookmark_outline_rounded, size: 15, color: Color(0xFF28654F)),
                  const SizedBox(width: 6),
                  Text(
                    "Draft saved ${_formatDateTime(_lastSavedAt)} • Private to clinician",
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF28654F),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 1. Clinical Assessment
          _buildFieldLabel("Clinical Assessment", isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _clinicalAssessmentController,
            maxLines: 4,
            minLines: 2,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF19372B), height: 1.45),
            decoration: _inputDecoration(
              hintText: "Enter diagnosis, primary clinical impression, or diagnostic summary...",
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Clinical assessment is required";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 2. Doctor's Observations
          _buildFieldLabel("Doctor's Observations", isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _observationsController,
            maxLines: 4,
            minLines: 2,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF19372B), height: 1.45),
            decoration: _inputDecoration(
              hintText: "Document physical exam findings, symptom evaluation, or vital findings...",
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Doctor's observations are required";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 3. Prescription & Medications (Rx)
          _buildFieldLabel("Prescription & Medications (Rx)"),
          const SizedBox(height: 6),
          TextFormField(
            controller: _prescriptionController,
            maxLines: 4,
            minLines: 2,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF19372B), height: 1.45),
            decoration: _inputDecoration(
              hintText: "Enter medications, strength, dosage, frequency, and duration (e.g., Tab Paracetamol 650mg TDS x 3 days, Syrup Ambroxol 10ml BD)...",
            ),
          ),
          const SizedBox(height: 16),

          // 4. Advice and Recommendations
          _buildFieldLabel("Advice & Recommendations", isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _adviceController,
            maxLines: 4,
            minLines: 2,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF19372B), height: 1.45),
            decoration: _inputDecoration(
              hintText: "Patient guidance, home care measures, activity guidance, or therapy recommendations...",
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return "Advice and recommendations are required";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // 4. Follow-up Instructions
          _buildFieldLabel("Follow-up Instructions (Optional)"),
          const SizedBox(height: 6),
          TextFormField(
            controller: _followUpInstructionsController,
            maxLines: 3,
            minLines: 2,
            style: const TextStyle(fontSize: 13.5, color: Color(0xFF19372B), height: 1.45),
            decoration: _inputDecoration(
              hintText: "Next steps, warning signs, or when to seek immediate medical attention...",
            ),
          ),
          const SizedBox(height: 16),

          // 5. Follow-up Date Picker
          _buildFieldLabel("Follow-up Date (Optional)"),
          const SizedBox(height: 6),
          InkWell(
            onTap: _pickFollowUpDate,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F8F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD2E3D8), width: 1.0),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF28654F)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _followUpDate != null
                          ? "Follow-up: ${_formatDate(_followUpDate)}"
                          : "Select scheduled follow-up date (optional)",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: _followUpDate != null ? FontWeight.w600 : FontWeight.w400,
                        color: _followUpDate != null ? const Color(0xFF19372B) : const Color(0xFF8BA698),
                      ),
                    ),
                  ),
                  if (_followUpDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 16, color: Color(0xFF6B8B7B)),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: "Clear follow-up date",
                      onPressed: () => setState(() => _followUpDate = null),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),

          // Action Buttons
          if (_isEditingFinalized)
            Row(
              children: [
                OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _isEditingFinalized = false;
                      _loadAssessment(caseItem.id);
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF5A756B),
                    side: const BorderSide(color: Color(0xFFC7DBD0)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Cancel"),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isFinalizing ? null : () => _finalizeReview(caseItem),
                    icon: _isFinalizing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.sync_rounded, size: 16),
                    label: const Text(
                      "Update & Publish Changes",
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF28654F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 10,
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Save Draft Action
                OutlinedButton.icon(
                  onPressed: _isSavingDraft ? null : () => _saveDraft(caseItem),
                  icon: _isSavingDraft
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF28654F)),
                        )
                      : const Icon(Icons.save_outlined, size: 16),
                  label: const Text(
                    "Save Draft",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF28654F),
                    side: const BorderSide(color: Color(0xFF28654F), width: 1.2),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                // Finalize Review Action
                ElevatedButton.icon(
                  onPressed: _isFinalizing ? null : () => _finalizeReview(caseItem),
                  icon: _isFinalizing
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check_circle_outline_rounded, size: 16),
                  label: const Text(
                    "Finalize Review",
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28654F),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // --- Status Notice Card ---
  Widget _buildStatusNoticeCard(PatientCaseSummary caseItem, bool isDesktop) {
    String noticeMessage;
    final statusLower = caseItem.status.toLowerCase();
    if (statusLower.contains("reviewed") || _isFinalized) {
      noticeMessage =
          "Clinical assessment and supervised care notes have been finalized and recorded.";
    } else if (statusLower.contains("in review")) {
      noticeMessage =
          "Case is currently under active clinical review. Complete your assessment and supervised notes above.";
    } else if (statusLower.contains("summary ready") || statusLower.contains("ready")) {
      noticeMessage =
          "Patient intake questionnaire responses are complete and ready for physician review.";
    } else if (statusLower.contains("awaiting") || statusLower.contains("submitted")) {
      noticeMessage =
          "This case was recently submitted by the patient and is in queue for review.";
    } else {
      noticeMessage =
          "Patient intake recorded. Current status: ${caseItem.status}.";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F7F3),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD4E6DB), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Color(0xFF28654F),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  noticeMessage,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF233A32),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Supervised notes entered by the attending clinician are stored securely and sync with patient care records upon finalization.",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF5A756B),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required IconData icon,
    required bool isDesktop,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDCECE1), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.white,
            offset: Offset(-2, -2),
            blurRadius: 5,
          ),
          BoxShadow(
            color: Color(0xFFBED4C6),
            offset: Offset(3, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Subtle botanical watermark in lower right corner (opacity 8%)
            Positioned(
              right: -15,
              bottom: -15,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.08,
                  child: Image.asset(
                    ClinovaConstants.leavesAsset,
                    height: 110,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isDesktop ? 22 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE4F0E8),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 16, color: const Color(0xFF28654F)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF19372B),
                                letterSpacing: -0.2,
                              ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF5A756B),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...children,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B8B7B),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF19372B),
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
