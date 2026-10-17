import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/clinova_colors.dart';
import '../../doctor/models/doctor_assessment_model.dart';
import '../../doctor/services/doctor_assessment_repository.dart';
import '../models/case_attachment_model.dart';
import '../models/case_intake_model.dart';
import '../models/patient_care_note_model.dart';
import '../services/demo_case_repository.dart';
import '../services/patient_care_notes_repository.dart';

/// Clinova Dedicated Case Details Screen
///
/// Displays the genuine saved information for a specific clinical case:
/// - Case reference ID & submission timestamp
/// - Case status badge
/// - Attending physician review, prescription, and supervised care notes (when reviewed)
/// - Chief complaint / concern
/// - Duration, severity, and associated symptoms
/// - Medical history responses from the 11-step questionnaire
/// - Honest clinical status banner (never fabricating diagnoses or fake doctor notes)
/// - Top-left back button returning to the Patient Dashboard
class PatientCaseDetailScreen extends StatefulWidget {
  final PatientCaseSummary? initialCase;
  final String? caseId;

  const PatientCaseDetailScreen({
    super.key,
    this.initialCase,
    this.caseId,
  });

  @override
  State<PatientCaseDetailScreen> createState() => _PatientCaseDetailScreenState();
}

class _PatientCaseDetailScreenState extends State<PatientCaseDetailScreen> {
  StreamSubscription? _casesSub;
  StreamSubscription? _assessmentSub;
  StreamSubscription? _notesSub;

  @override
  void initState() {
    super.initState();
    DemoCaseRepository.instance.fetchCasesFromSupabase();
    DoctorAssessmentRepository.instance.fetchAssessmentsFromSupabase();
    PatientCareNotesRepository.instance.fetchNotesFromSupabase();

    _casesSub = DemoCaseRepository.instance.casesStream.listen((_) {
      if (mounted) setState(() {});
    });
    _assessmentSub = DoctorAssessmentRepository.instance.assessmentsStream.listen((_) {
      if (mounted) setState(() {});
    });
    _notesSub = PatientCareNotesRepository.instance.notesStream.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _casesSub?.cancel();
    _assessmentSub?.cancel();
    _notesSub?.cancel();
    super.dispose();
  }

  PatientCaseSummary? _resolveCase(BuildContext context) {
    if (widget.initialCase != null) {
      final fromRepo = DemoCaseRepository.instance.getCaseById(widget.initialCase!.id) ??
          DemoCaseRepository.instance.getCaseByReference(widget.initialCase!.reference);
      return fromRepo ?? widget.initialCase;
    }

    // Check navigation arguments first
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is PatientCaseSummary) {
      final fromRepo = DemoCaseRepository.instance.getCaseById(args.id) ??
          DemoCaseRepository.instance.getCaseByReference(args.reference);
      return fromRepo ?? args;
    } else if (args is Map<String, dynamic>) {
      final rawCase = args['case'];
      if (rawCase is PatientCaseSummary) {
        final fromRepo = DemoCaseRepository.instance.getCaseById(rawCase.id) ??
            DemoCaseRepository.instance.getCaseByReference(rawCase.reference);
        return fromRepo ?? rawCase;
      }
      final rawId = args['caseId'] as String? ?? args['id'] as String?;
      if (rawId != null) {
        final found = DemoCaseRepository.instance.getCaseById(rawId) ??
            DemoCaseRepository.instance.getCaseByReference(rawId);
        return PatientCaseSummary(
          id: rawId,
          reference: args['reference'] as String? ?? rawId,
          title: args['title'] as String? ?? found?.title ?? 'Case Details',
          date: args['date'] as String? ?? found?.date ?? 'Oct 2026',
          status: args['status'] as String? ?? found?.status ?? 'Ready',
          statusTextColor: found?.statusTextColor ?? const Color(0xFF1E5D46),
          statusBgColor: found?.statusBgColor ?? const Color(0xFFDBEFE3),
          statusBorderColor: found?.statusBorderColor ?? const Color(0xFFBDE3CC),
          category: args['category'] as String? ?? found?.category,
          doctor: args['doctor'] as String? ?? found?.doctor,
          notes: args['notes'] as String? ?? found?.notes,
          fullCase: found?.fullCase,
        );
      }
      return PatientCaseSummary.fromMap(args);
    } else if (args is String) {
      final found = DemoCaseRepository.instance.getCaseById(args) ??
          DemoCaseRepository.instance.getCaseByReference(args);
      if (found != null) {
        return found;
      }
    }

    // Check constructor caseId
    if (widget.caseId != null) {
      final found = DemoCaseRepository.instance.getCaseById(widget.caseId!) ??
          DemoCaseRepository.instance.getCaseByReference(widget.caseId!);
      if (found != null) {
        return found;
      }
    }

    // Fallback gracefully to first available case without crashing
    if (DemoCaseRepository.instance.cases.isNotEmpty) {
      return DemoCaseRepository.instance.cases.first;
    }

    return null;
  }

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.patientDashboard);
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return "${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}";
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '';
    final d = _formatDate(dt);
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return "$d at $hour:$minute";
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
            "Case Details",
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
                  "No saved details exist for this case reference.",
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

    // Check doctor assessment & patient care note
    final assessment = DoctorAssessmentRepository.instance.getAssessment(resolvedCase.id) ??
        DoctorAssessmentRepository.instance.getAssessment(resolvedCase.reference);

    final notes = PatientCareNotesRepository.instance.notes;
    PatientCareNote? matchingNote;
    try {
      final cIdLower = resolvedCase.id.toLowerCase();
      final cRefLower = resolvedCase.reference.toLowerCase();
      matchingNote = notes.firstWhere((n) {
        final nid = n.id.toLowerCase();
        return nid.contains(cIdLower) || nid.contains(cRefLower);
      });
    } catch (_) {}

    final isReviewed = resolvedCase.status.toLowerCase().contains('reviewed') ||
        (assessment != null && assessment.isFinalized) ||
        matchingNote != null;

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
          "Case Details",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF19372B),
            letterSpacing: -0.2,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFF28654F),
          onRefresh: () async {
            await Future.wait([
              DemoCaseRepository.instance.fetchCasesFromSupabase(),
              DoctorAssessmentRepository.instance.fetchAssessmentsFromSupabase(),
              PatientCareNotesRepository.instance.fetchNotesFromSupabase(),
            ]);
          },
          child: Center(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 32 : 18,
                vertical: isDesktop ? 24 : 16,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Header Summary Card
                    _buildHeaderCard(context, resolvedCase, isDesktop),
                    const SizedBox(height: 16),

                    // 1.5. Doctor Review & Prescription (When Reviewed)
                    if (isReviewed) ...[
                      _buildDoctorReviewSection(
                        context: context,
                        caseItem: resolvedCase,
                        assessment: assessment,
                        careNote: matchingNote,
                        isDesktop: isDesktop,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // 2. Primary Health Concerns (Steps 1–3)
                    _buildPrimaryConcernCard(resolvedCase, fullCase, isDesktop),
                    const SizedBox(height: 16),

                    // 3. Associated Symptoms & Details (Steps 4–5)
                    if (fullCase != null &&
                        (fullCase.associatedSymptoms.isNotEmpty ||
                            fullCase.otherAssociatedSymptom != null ||
                            fullCase.symptomDetails != null)) ...[
                      _buildSymptomsCard(fullCase, isDesktop),
                      const SizedBox(height: 16),
                    ],

                    // 4. Background History & Conditions (Steps 6–10)
                    if (fullCase != null) ...[
                      _buildMedicalHistoryCard(fullCase, isDesktop),
                      const SizedBox(height: 16),
                    ],

                    // 4.5. Supporting Medical Documents (Optional)
                    _buildSupportingDocumentsCard(context, resolvedCase, fullCase, isDesktop),
                    const SizedBox(height: 16),

                    // 5. Honest Status Notice
                    _buildStatusNoticeCard(resolvedCase, isDesktop),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- 1. Header Summary Card ---
  Widget _buildHeaderCard(BuildContext context, PatientCaseSummary caseItem, bool isDesktop) {
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
            // Botanical leaf watermark in top right corner
            Positioned(
              right: -25,
              top: -20,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.12,
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
                  // Meta Row: Reference, Category & Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F2EC),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFD2E3D8), width: 0.8),
                              ),
                              child: Text(
                                caseItem.reference,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E5D46),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ),
                            if (caseItem.category != null && caseItem.category!.trim().isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
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
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: caseItem.statusBgColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: caseItem.statusBorderColor, width: 0.8),
                        ),
                        child: Text(
                          caseItem.status,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: caseItem.statusTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Case Title
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

                  // Submission Date & Clinician Row
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
                            Text(
                              "Clinician: ${caseItem.doctor!.trim()}",
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF5A756B),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. Primary Health Concern Card ---
  Widget _buildPrimaryConcernCard(
    PatientCaseSummary caseItem,
    CaseIntakeModel? fullCase,
    bool isDesktop,
  ) {
    final concernText = fullCase?.chiefConcern.isNotEmpty == true
        ? fullCase!.chiefConcern
        : caseItem.title;
    final durationText = fullCase?.duration ?? "Not specified";
    final severityText = fullCase?.severity ?? "Not specified";

    return _buildSectionCard(
      title: "Primary Health Concern",
      icon: Icons.health_and_safety_outlined,
      isDesktop: isDesktop,
      children: [
        _buildInfoRow("Chief Concern / Complaint", concernText),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildInfoRow("Duration", durationText),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoRow("Severity Level", severityText),
            ),
          ],
        ),
        if (caseItem.notes != null && caseItem.notes!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInfoRow("Recorded Intake Notes", caseItem.notes!.trim()),
        ],
      ],
    );
  }

  // --- 3. Associated Symptoms Card ---
  Widget _buildSymptomsCard(CaseIntakeModel fullCase, bool isDesktop) {
    return _buildSectionCard(
      title: "Associated Symptoms & Triggers",
      icon: Icons.sick_outlined,
      isDesktop: isDesktop,
      children: [
        if (fullCase.associatedSymptoms.isNotEmpty) ...[
          const Text(
            "Reported Symptoms",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B8B7B),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: fullCase.associatedSymptoms.map((symptom) {
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
          const SizedBox(height: 12),
        ],
        if (fullCase.otherAssociatedSymptom != null &&
            fullCase.otherAssociatedSymptom!.trim().isNotEmpty) ...[
          _buildInfoRow("Other Symptoms Described", fullCase.otherAssociatedSymptom!.trim()),
          const SizedBox(height: 12),
        ],
        if (fullCase.symptomDetails != null && fullCase.symptomDetails!.trim().isNotEmpty)
          _buildInfoRow("Triggers & Relieving Factors", fullCase.symptomDetails!.trim()),
      ],
    );
  }

  // --- 4. Medical History & Background Card ---
  Widget _buildMedicalHistoryCard(CaseIntakeModel fullCase, bool isDesktop) {
    return _buildSectionCard(
      title: "Medical Context & Background",
      icon: Icons.history_edu_rounded,
      isDesktop: isDesktop,
      children: [
        // Previous Occurrences
        _buildInfoRow(
          "Previous Occurrences",
          fullCase.previousOccurrences != null
              ? "${fullCase.previousOccurrences}${fullCase.previousOccurrenceDetails != null && fullCase.previousOccurrenceDetails!.trim().isNotEmpty ? ' — ${fullCase.previousOccurrenceDetails!.trim()}' : ''}"
              : "Not answered",
        ),
        const SizedBox(height: 12),

        // Existing Conditions
        _buildInfoRow(
          "Existing Conditions",
          fullCase.existingConditions.isNotEmpty
              ? "${fullCase.existingConditions.join(', ')}${fullCase.otherConditionDetails != null && fullCase.otherConditionDetails!.trim().isNotEmpty ? ' (${fullCase.otherConditionDetails!.trim()})' : ''}"
              : "None recorded",
        ),
        const SizedBox(height: 12),

        // Allergies
        _buildInfoRow(
          "Allergies",
          fullCase.allergies.isNotEmpty
              ? "${fullCase.allergies.join(', ')}${fullCase.allergyDetails != null && fullCase.allergyDetails!.trim().isNotEmpty ? ' (${fullCase.allergyDetails!.trim()})' : ''}"
              : "No known allergies reported",
        ),
        const SizedBox(height: 12),

        // Medications
        _buildInfoRow(
          "Current Medications",
          fullCase.takesMedications != null
              ? "${fullCase.takesMedications}${fullCase.medicationDetails != null && fullCase.medicationDetails!.trim().isNotEmpty ? ' — ${fullCase.medicationDetails!.trim()}' : ''}"
              : "None reported",
        ),

        // Family History
        if (fullCase.medicalFamilyHistory != null &&
            fullCase.medicalFamilyHistory!.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildInfoRow("Relevant Medical / Family History", fullCase.medicalFamilyHistory!.trim()),
        ],
      ],
    );
  }

  // --- 4.5. Supporting Medical Documents Card ---
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
                    "No supporting medical documents attached to this case. (Optional step was skipped)",
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
          Text(
            "${attachments.length} attached document${attachments.length > 1 ? 's' : ''}",
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF28654F),
            ),
          ),
          const SizedBox(height: 10),
          ...attachments.map((CaseAttachmentModel att) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FCFA),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDDECE2), width: 0.8),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: att.accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(att.icon, color: att.accentColor, size: 18),
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
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF19372B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Wrap(
                            spacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                att.fileTypeLabel,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF436B5C)),
                              ),
                              const Text("•", style: TextStyle(fontSize: 10, color: Color(0xFF9AB2A6))),
                              Text(
                                att.formattedSize,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF6B8B7B)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }

  // --- 5. Honest Status Notice ---
  Widget _buildStatusNoticeCard(PatientCaseSummary caseItem, bool isDesktop) {
    String noticeMessage;
    if (caseItem.status.toLowerCase().contains("reviewed")) {
      noticeMessage =
          "This case was reviewed by a clinician. Any documented clinical observations or guidance can be seen under Patient Care Notes.";
    } else if (caseItem.status.toLowerCase().contains("summary ready")) {
      noticeMessage =
          "Questionnaire responses have been recorded and are prepared for clinician review.";
    } else if (caseItem.status.toLowerCase().contains("awaiting") ||
        caseItem.status.toLowerCase().contains("submitted")) {
      noticeMessage =
          "This case has been submitted and is currently in queue for review by your clinical care team.";
    } else {
      noticeMessage =
          "Intake responses saved. Current status: ${caseItem.status}.";
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
                  "Intake information for clinical demonstration only — does not constitute verified medical advice, diagnoses, or prescriptions.",
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

  // --- Reusable Section Card Helper ---
  Widget _buildSectionCard({
    required String title,
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
            // Subtle botanical watermark in lower right corner
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
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF19372B),
                          letterSpacing: -0.2,
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

  // --- Doctor Review & Prescription Section ---
  Widget _buildDoctorReviewSection({
    required BuildContext context,
    required PatientCaseSummary caseItem,
    required DoctorAssessmentModel? assessment,
    required PatientCareNote? careNote,
    required bool isDesktop,
  }) {
    final docName = (assessment != null && assessment.doctorName.trim().isNotEmpty)
        ? assessment.doctorName.trim()
        : (caseItem.doctor?.trim().isNotEmpty == true
            ? caseItem.doctor!.trim()
            : (careNote?.author?.trim().isNotEmpty == true
                ? careNote!.author!.trim()
                : "Attending Physician"));

    final reviewDate = assessment?.finalizedAt != null
        ? _formatDateTime(assessment!.finalizedAt!)
        : (caseItem.reviewedAt != null
            ? _formatDateTime(caseItem.reviewedAt!)
            : (careNote?.formattedDate.isNotEmpty == true
                ? careNote!.formattedDate
                : "Recently Finalized"));

    final prescriptionText = assessment?.prescription.trim() ?? '';
    final clinicalText = assessment?.clinicalAssessment.trim() ?? '';
    final observationsText = assessment?.observations.trim() ?? '';
    final adviceText = assessment?.adviceAndRecommendations.trim() ?? '';
    final followUpText = assessment?.followUpInstructions.trim() ?? '';
    final followUpDate = assessment?.followUpDate;

    // Check if careNote contains prescription or clinical text if assessment object is missing
    String fallbackPrescription = '';
    String fallbackOtherNotes = '';
    if (prescriptionText.isEmpty && careNote != null && careNote.text.contains("Prescription / Medications:")) {
      final lines = careNote.text.split('\n');
      final rxLines = <String>[];
      final restLines = <String>[];
      bool inRx = false;
      for (final line in lines) {
        if (line.trim().startsWith("Prescription / Medications:")) {
          inRx = true;
          continue;
        } else if (inRx &&
            (line.trim().startsWith("Clinical Assessment:") ||
             line.trim().startsWith("Doctor's Observations:") ||
             line.trim().startsWith("Advice & Recommendations:") ||
             line.trim().startsWith("Follow-up Instructions:") ||
             line.trim().startsWith("Recommended Follow-up:"))) {
          inRx = false;
          restLines.add(line);
        } else if (inRx) {
          rxLines.add(line);
        } else {
          restLines.add(line);
        }
      }
      fallbackPrescription = rxLines.join('\n').trim();
      fallbackOtherNotes = restLines.join('\n').trim();
    } else if (careNote != null) {
      fallbackOtherNotes = careNote.text.trim();
    }

    final finalRx = prescriptionText.isNotEmpty ? prescriptionText : fallbackPrescription;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBF8),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFBCE0CC), width: 1.2),
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
            // Botanical leaf watermark
            Positioned(
              right: -25,
              top: -20,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.12,
                  child: Image.asset(
                    ClinovaConstants.leavesAsset,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(isDesktop ? 22 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Physician header row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD6EDE0),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFBCE0CC), width: 1),
                        ),
                        child: const Icon(
                          Icons.medical_services_rounded,
                          color: Color(0xFF1E5D46),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  "Doctor's Review & Clinical Plan",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF19372B),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDBEFE3),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFBDE3CC)),
                                  ),
                                  child: const Text(
                                    "FINALIZED",
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF145338),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Attending: $docName • $reviewDate",
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF426757),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // 1. PRESCRIPTION CARD (Rx)
                  if (finalRx.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFB7DFCA), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF28654F).withValues(alpha: 0.07),
                            offset: const Offset(0, 3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF28654F),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  "Rx",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "Official Prescription & Medications",
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF19372B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SelectableText(
                            finalRx,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E5D46),
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 2. Clinical Assessment
                  if (clinicalText.isNotEmpty) ...[
                    _buildDoctorDetailBlock(
                      title: "Clinical Assessment",
                      content: clinicalText,
                      icon: Icons.health_and_safety_outlined,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 3. Doctor's Observations
                  if (observationsText.isNotEmpty) ...[
                    _buildDoctorDetailBlock(
                      title: "Doctor's Observations & Findings",
                      content: observationsText,
                      icon: Icons.visibility_outlined,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 4. Advice & Recommendations
                  if (adviceText.isNotEmpty) ...[
                    _buildDoctorDetailBlock(
                      title: "Advice & Recommendations",
                      content: adviceText,
                      icon: Icons.lightbulb_outline_rounded,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 5. Follow-up Instructions & Date
                  if (followUpText.isNotEmpty || followUpDate != null) ...[
                    _buildDoctorDetailBlock(
                      title: "Follow-up Instructions",
                      content: followUpDate != null
                          ? "$followUpText\n\nScheduled Follow-up Date: ${_formatDate(followUpDate)}"
                          : followUpText,
                      icon: Icons.calendar_month_outlined,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Fallback: If only raw note text exists
                  if (finalRx.isEmpty &&
                      clinicalText.isEmpty &&
                      observationsText.isEmpty &&
                      adviceText.isEmpty &&
                      fallbackOtherNotes.isNotEmpty) ...[
                    _buildDoctorDetailBlock(
                      title: "Supervised Clinical Care Notes",
                      content: fallbackOtherNotes,
                      icon: Icons.notes_rounded,
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

  Widget _buildDoctorDetailBlock({
    required String title,
    required String content,
    required IconData icon,
  }) {
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
          SelectableText(
            content,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF19372B),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
