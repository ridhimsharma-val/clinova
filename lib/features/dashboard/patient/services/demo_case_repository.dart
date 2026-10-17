import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/auth/auth_config.dart';
import '../../../../core/supabase/supabase_config.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../models/case_attachment_model.dart';
import '../models/case_intake_model.dart';
import 'case_attachment_repository.dart';
import 'patient_profile_repository.dart';

/// Clinical case summary item used in Recent Cases lists
class PatientCaseSummary {
  final String id;
  final String reference;
  final String title;
  final String date;
  final String status;
  final Color statusTextColor;
  final Color statusBgColor;
  final Color statusBorderColor;
  final String? category;
  final String? doctor;
  final String? notes;
  final String? patientName;
  final String? patientId;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final CaseIntakeModel? fullCase;
  final List<CaseAttachmentModel> attachments;

  const PatientCaseSummary({
    required this.id,
    required this.reference,
    required this.title,
    required this.date,
    required this.status,
    required this.statusTextColor,
    required this.statusBgColor,
    required this.statusBorderColor,
    this.category,
    this.doctor,
    this.notes,
    this.patientName,
    this.patientId,
    this.submittedAt,
    this.reviewedAt,
    this.fullCase,
    this.attachments = const [],
  });

  bool matchesFilter(String filter) {
    final f = filter.trim().toLowerCase();
    if (f == 'all cases' || f == 'all') return true;
    final s = status.toLowerCase();
    switch (f) {
      case 'pending':
        return s.contains('ready') ||
            s.contains('pending') ||
            s.contains('awaiting') ||
            s.contains('submitted');
      case 'in review':
        return s.contains('in review') || s.contains('draft');
      case 'reviewed':
        return s.contains('reviewed');
      case 'archived':
        return s.contains('archive');
      default:
        return s == f;
    }
  }

  bool matchesSearch(String query) {
    if (query.trim().isEmpty) return true;
    final q = query.trim().toLowerCase();
    final matchesId = id.toLowerCase().contains(q) || reference.toLowerCase().contains(q);
    final matchesTitle = title.toLowerCase().contains(q);
    final matchesPatient = (patientName?.toLowerCase().contains(q) ?? false) ||
        (patientId?.toLowerCase().contains(q) ?? false);
    final matchesCategory = category?.toLowerCase().contains(q) ?? false;
    final matchesNotes = notes?.toLowerCase().contains(q) ?? false;
    final matchesConcern = fullCase?.chiefConcern.toLowerCase().contains(q) ?? false;
    return matchesId || matchesTitle || matchesPatient || matchesCategory || matchesNotes || matchesConcern;
  }

  factory PatientCaseSummary.fromMap(Map<String, dynamic> map, {CaseIntakeModel? fullCase}) {
    final status = map['status'] as String? ?? 'Ready';
    Color textColor = const Color(0xFF1E5D46);
    Color bgColor = const Color(0xFFDBEFE3);
    Color borderColor = const Color(0xFFBDE3CC);

    final statusLower = status.toLowerCase();
    if (statusLower.contains('reviewed')) {
      textColor = const Color(0xFF145338);
      bgColor = const Color(0xFFCEE9DD);
      borderColor = const Color(0xFFB3DCB6);
    } else if (statusLower.contains('archive')) {
      textColor = const Color(0xFF6C8278);
      bgColor = const Color(0xFFE2EAE5);
      borderColor = const Color(0xFFD2DFD6);
    }

    final id = map['id'] as String? ?? 'CASE-000';
    return PatientCaseSummary(
      id: id,
      reference: id,
      title: map['title'] as String? ?? 'Clinical Intake',
      date: map['date'] as String? ?? 'Oct 2026',
      status: status,
      statusTextColor: textColor,
      statusBgColor: bgColor,
      statusBorderColor: borderColor,
      category: map['category'] as String?,
      doctor: map['doctor'] as String?,
      notes: map['notes'] as String?,
      patientName: map['patientName'] as String? ?? "Aarav Sharma",
      patientId: map['patientId'] as String? ?? "PAT-8842",
      submittedAt: map['submittedAt'] as DateTime?,
      reviewedAt: map['reviewedAt'] as DateTime?,
      fullCase: fullCase,
      attachments: (map['case_attachments'] as List<dynamic>?)
              ?.map((e) => CaseAttachmentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          (fullCase?.attachments ?? const []),
    );
  }

  PatientCaseSummary copyWith({
    String? id,
    String? reference,
    String? title,
    String? date,
    String? status,
    Color? statusTextColor,
    Color? statusBgColor,
    Color? statusBorderColor,
    String? category,
    String? doctor,
    String? notes,
    String? patientName,
    String? patientId,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    CaseIntakeModel? fullCase,
    List<CaseAttachmentModel>? attachments,
  }) {
    return PatientCaseSummary(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      title: title ?? this.title,
      date: date ?? this.date,
      status: status ?? this.status,
      statusTextColor: statusTextColor ?? this.statusTextColor,
      statusBgColor: statusBgColor ?? this.statusBgColor,
      statusBorderColor: statusBorderColor ?? this.statusBorderColor,
      category: category ?? this.category,
      doctor: doctor ?? this.doctor,
      notes: notes ?? this.notes,
      patientName: patientName ?? this.patientName,
      patientId: patientId ?? this.patientId,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      fullCase: fullCase ?? this.fullCase,
      attachments: attachments ?? this.attachments,
    );
  }
}

/// In-memory Demo Repository for Phase 2B.
///
/// Fully backend-independent and prepared for future Supabase & n8n integration.
class DemoCaseRepository {
  DemoCaseRepository._() {
    _initDefaults();
  }

  static final DemoCaseRepository instance = DemoCaseRepository._();

  CaseIntakeModel? _activeDraft;
  final List<PatientCaseSummary> _cases = [];

  final StreamController<List<PatientCaseSummary>> _casesController =
      StreamController<List<PatientCaseSummary>>.broadcast();

  final StreamController<CaseIntakeModel?> _draftController =
      StreamController<CaseIntakeModel?>.broadcast();

  Stream<List<PatientCaseSummary>> get casesStream => _casesController.stream;
  Stream<CaseIntakeModel?> get draftStream => _draftController.stream;

  List<PatientCaseSummary> get cases => List.unmodifiable(_cases);
  CaseIntakeModel? get activeDraft => _activeDraft;

  void resetToDemoDefaults() {
    _cases.clear();
    _initDefaults(force: true);
    _casesController.add(List.unmodifiable(_cases));
  }

  @visibleForTesting
  void setCasesForTest(List<PatientCaseSummary> testCases) {
    _cases.clear();
    _cases.addAll(testCases);
    _casesController.add(List.unmodifiable(_cases));
  }

  List<PatientCaseSummary> get pendingCases {
    final list = _cases.where((c) => c.matchesFilter('Pending')).toList();
    list.sort((a, b) {
      if (a.submittedAt != null && b.submittedAt != null) {
        return a.submittedAt!.compareTo(b.submittedAt!); // oldest first
      }
      return 0;
    });
    return list;
  }

  List<PatientCaseSummary> get reviewedCases {
    final list = _cases.where((c) => c.matchesFilter('Reviewed')).toList();
    list.sort((a, b) {
      if (a.reviewedAt != null && b.reviewedAt != null) {
        return b.reviewedAt!.compareTo(a.reviewedAt!); // newest first
      }
      return 0;
    });
    return list;
  }

  List<PatientCaseSummary> get inReviewCases {
    return _cases.where((c) => c.matchesFilter('In Review')).toList();
  }

  int get distinctPatientCount {
    return _cases
        .map((c) => c.patientId ?? c.patientName)
        .where((p) => p != null && p.trim().isNotEmpty)
        .toSet()
        .length;
  }

  void _initDefaults({bool force = false}) {
    if (!force && SupabaseConfig.client != null && !AuthConfig.useDemoAuth) {
      return;
    }
    _cases.addAll([
      PatientCaseSummary(
        id: "case-01",
        reference: "DEMO-CASE-8842",
        title: "Persistent Cough & Low Fever",
        date: "08 Oct 2026",
        status: "Summary ready",
        statusTextColor: const Color(0xFF185A3C),
        statusBgColor: const Color(0xFFD6EDE0),
        statusBorderColor: const Color(0xFFBCE0CC),
        category: "Respiratory",
        doctor: "Pending review",
        notes: "4 days duration, evening dry cough. Vitals within normal limits.",
        patientName: "Aarav Sharma",
        patientId: "PAT-8842",
        submittedAt: DateTime(2026, 10, 8, 14, 30),
        fullCase: CaseIntakeModel(
          reference: "DEMO-CASE-8842",
          status: "submitted",
          createdAt: DateTime(2026, 10, 8, 14, 30),
          lastUpdatedAt: DateTime(2026, 10, 8, 14, 45),
          chiefConcern: "Persistent Cough & Low Fever",
          duration: "4–7 days",
          severity: "Moderate",
          associatedSymptoms: const ["Cough", "Fever", "Fatigue"],
          symptomDetails: "Worse at night and in cooler weather. Warm drinks provide slight soothing.",
          previousOccurrences: "No",
          existingConditions: const ["None known"],
          allergies: const ["No known allergies"],
          takesMedications: "No",
          medicalFamilyHistory: "No relevant chronic history reported.",
        ),
      ),
      PatientCaseSummary(
        id: "case-02",
        reference: "DEMO-CASE-7193",
        title: "Right Knee Strain after Exercise",
        date: "25 Sep 2026",
        status: "Reviewed by Doctor",
        statusTextColor: const Color(0xFF145338),
        statusBgColor: const Color(0xFFCEE9DD),
        statusBorderColor: const Color(0xFFB3DCB6),
        category: "Musculoskeletal",
        doctor: "Dr. Marcus Vance",
        notes: "Post-jogging discomfort. Doctor recommended ice compression.",
        patientName: "Aarav Sharma",
        patientId: "PAT-8842",
        submittedAt: DateTime(2026, 9, 25, 10, 15),
        reviewedAt: DateTime(2026, 9, 26, 11, 30),
        fullCase: CaseIntakeModel(
          reference: "DEMO-CASE-7193",
          status: "submitted",
          createdAt: DateTime(2026, 9, 25, 10, 15),
          lastUpdatedAt: DateTime(2026, 9, 25, 10, 25),
          chiefConcern: "Right Knee Strain after Exercise",
          duration: "1–3 days",
          severity: "Mild",
          associatedSymptoms: const ["Pain"],
          symptomDetails: "Mild swelling along the medial knee after a 5km run; improves with rest and cold compression.",
          previousOccurrences: "Yes",
          previousOccurrenceDetails: "Similar strain 2 years ago after athletic activity.",
          existingConditions: const ["None known"],
          allergies: const ["No known allergies"],
          takesMedications: "No",
          medicalFamilyHistory: "None reported.",
        ),
      ),
      PatientCaseSummary(
        id: "case-03",
        reference: "DEMO-CASE-6041",
        title: "Annual Wellness Intake",
        date: "12 Sep 2026",
        status: "Archived",
        statusTextColor: const Color(0xFF6C8278),
        statusBgColor: const Color(0xFFE2EAE5),
        statusBorderColor: const Color(0xFFD2DFD6),
        category: "General Health",
        doctor: "Dr. Elena Ramos",
        notes: "Routine annual health assessment and baseline vitals.",
        patientName: "Priya Patel",
        patientId: "PAT-6041",
        submittedAt: DateTime(2026, 9, 12, 9, 0),
        reviewedAt: DateTime(2026, 9, 13, 14, 0),
        fullCase: CaseIntakeModel(
          reference: "DEMO-CASE-6041",
          status: "submitted",
          createdAt: DateTime(2026, 9, 12, 9, 0),
          lastUpdatedAt: DateTime(2026, 9, 12, 9, 15),
          chiefConcern: "Annual Wellness Intake",
          duration: "Comes and goes",
          severity: "Mild",
          associatedSymptoms: const ["None of these"],
          symptomDetails: "Routine wellness checkup; no active acute distress.",
          previousOccurrences: "No",
          existingConditions: const ["None known"],
          allergies: const ["No known allergies"],
          takesMedications: "No",
          medicalFamilyHistory: "Family history unremarkable.",
        ),
      ),
    ]);
  }

  /// Get a case by its unique ID or reference
  PatientCaseSummary? getCaseById(String id) {
    try {
      final normalized = id.trim().toLowerCase();
      return _cases.firstWhere((c) {
        final cId = c.id.toLowerCase();
        final cRef = c.reference.toLowerCase();
        if (cId == normalized || cRef == normalized) return true;
        if (normalized == 'case-101' && (cId == 'case-01' || cRef == 'demo-case-8842' || c.title.toLowerCase().contains('cough'))) {
          return true;
        }
        if (normalized == 'case-102' && (cId == 'case-02' || cRef == 'demo-case-7193' || c.title.toLowerCase().contains('knee'))) {
          return true;
        }
        if (normalized == 'case-103' && (cId == 'case-03' || cRef == 'demo-case-6041' || c.title.toLowerCase().contains('annual'))) {
          return true;
        }
        return false;
      });
    } catch (_) {
      return null;
    }
  }

  /// Get a case by its reference number
  PatientCaseSummary? getCaseByReference(String reference) {
    return getCaseById(reference);
  }

  /// Update status of a case by its ID or reference
  bool updateCaseStatus(
    String caseId,
    String newStatus, {
    Color textColor = const Color(0xFF28654F),
    Color bgColor = const Color(0xFFE4F0E8),
    Color borderColor = const Color(0xFFBED4C6),
    String? assignedDoctor,
  }) {
    final normalized = caseId.trim().toLowerCase();
    final index = _cases.indexWhere((c) {
      final cId = c.id.toLowerCase();
      final cRef = c.reference.toLowerCase();
      if (cId == normalized || cRef == normalized) return true;
      if (normalized == 'case-101' && (cId == 'case-01' || cRef == 'demo-case-8842' || c.title.toLowerCase().contains('cough'))) {
        return true;
      }
      if (normalized == 'case-102' && (cId == 'case-02' || cRef == 'demo-case-7193' || c.title.toLowerCase().contains('knee'))) {
        return true;
      }
      if (normalized == 'case-103' && (cId == 'case-03' || cRef == 'demo-case-6041' || c.title.toLowerCase().contains('annual'))) {
        return true;
      }
      return false;
    });

    if (index != -1) {
      final existing = _cases[index];
      _cases[index] = existing.copyWith(
        status: newStatus,
        statusTextColor: textColor,
        statusBgColor: bgColor,
        statusBorderColor: borderColor,
        doctor: assignedDoctor ?? existing.doctor,
        reviewedAt: newStatus.toLowerCase().contains('reviewed') ? DateTime.now() : existing.reviewedAt,
      );
      _casesController.add(List.unmodifiable(_cases));

      final client = SupabaseConfig.client;
      if (client != null) {
        String dbStatus = 'awaiting_review';
        final sl = newStatus.toLowerCase();
        if (sl.contains('reviewed')) {
          dbStatus = 'reviewed';
        } else if (sl.contains('in review')) {
          dbStatus = 'in_review';
        } else if (sl.contains('archive')) {
          dbStatus = 'archived';
        }
        client.from(SupabaseService.tableCases).update({
          'status': dbStatus,
          'reviewed_at': DateTime.now().toIso8601String(),
        }).eq('id', existing.id).catchError((_) => null);
      }

      return true;
    }
    return false;
  }

  /// Reset cases to initial seeded demo defaults
  void resetDefaults() {
    _cases.clear();
    _initDefaults(force: true);
    _casesController.add(List.unmodifiable(_cases));
  }

  /// Clear all cases (useful for empty state testing)
  void clearCases() {
    _cases.clear();
    _casesController.add(List.unmodifiable(_cases));
  }

  static const String _draftStorageKey = 'clinova_active_case_draft';

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDraftJson = prefs.getString(_draftStorageKey);
      if (savedDraftJson != null && savedDraftJson.trim().isNotEmpty) {
        final decoded = jsonDecode(savedDraftJson) as Map<String, dynamic>;
        _activeDraft = CaseIntakeModel.fromJson(decoded);
        _draftController.add(_activeDraft);
      }
    } catch (e) {
      debugPrint('Error restoring saved case draft: $e');
    }

    final client = SupabaseConfig.client;
    if (client != null) {
      client.auth.onAuthStateChange.listen((_) {
        fetchCasesFromSupabase();
      });
      await fetchCasesFromSupabase();
    }
  }

  /// Fetches cases and associated questionnaire responses directly from Supabase
  Future<void> fetchCasesFromSupabase() async {
    final client = SupabaseConfig.client;
    if (client == null) return;
    try {
      final profilesMap = <String, String>{};
      try {
        final profilesRes = await client.from(SupabaseService.tableProfiles).select('id, full_name');
        for (final p in profilesRes as List) {
          final pid = p['id'] as String?;
          final pname = p['full_name'] as String?;
          if (pid != null && pname != null && pname.trim().isNotEmpty) {
            profilesMap[pid] = pname.trim();
          }
        }
      } catch (pe) {
        debugPrint('[DemoCaseRepository] Note fetching profiles: $pe');
      }

      // Safely fetch attachments if case_attachments table exists
      final Map<String, List<CaseAttachmentModel>> caseAttachmentsMap = {};
      try {
        final attRes = await client.from('case_attachments').select();
        for (final row in attRes as List) {
          final att = CaseAttachmentModel.fromJson(row as Map<String, dynamic>);
          if (att.caseId != null) {
            caseAttachmentsMap.putIfAbsent(att.caseId!, () => []).add(att);
          }
        }
      } catch (attErr) {
        debugPrint('[DemoCaseRepository] Note fetching case_attachments: $attErr');
      }

      final response = await client
          .from(SupabaseService.tableCases)
          .select('*, ${SupabaseService.tableCaseIntakeResponses}(*)')
          .order('created_at', ascending: false);

      final List<PatientCaseSummary> fetched = [];
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];

      for (final row in response as List) {
        final map = row as Map<String, dynamic>;
        final createdStr = map['created_at'] as String?;
        final createdDt = createdStr != null ? DateTime.tryParse(createdStr) : null;
        final rawIntake = map[SupabaseService.tableCaseIntakeResponses];
        Map<String, dynamic>? intakeMap;
        if (rawIntake is Map<String, dynamic>) {
          intakeMap = rawIntake;
        } else if (rawIntake is List && rawIntake.isNotEmpty && rawIntake.first is Map<String, dynamic>) {
          intakeMap = rawIntake.first as Map<String, dynamic>;
        }

        final caseUuid = map['id'] as String? ?? '';
        final caseRef = map['case_reference'] as String? ?? '';
        final attachments = caseAttachmentsMap[caseUuid] ?? caseAttachmentsMap[caseRef] ?? CaseAttachmentRepository.instance.getAttachmentsForCase(caseUuid);

        CaseIntakeModel? fullCase;
        if (intakeMap != null) {
          fullCase = CaseIntakeModel(
            reference: caseRef,
            status: map['status'] as String? ?? 'submitted',
            createdAt: createdDt ?? DateTime.now(),
            lastUpdatedAt: createdDt ?? DateTime.now(),
            chiefConcern: intakeMap['chief_concern'] as String? ?? '',
            duration: intakeMap['duration'] as String?,
            severity: intakeMap['severity'] as String?,
            associatedSymptoms: List<String>.from(intakeMap['associated_symptoms'] ?? []),
            otherAssociatedSymptom: intakeMap['other_associated_symptom'] as String?,
            symptomDetails: intakeMap['symptom_details'] as String?,
            previousOccurrences: intakeMap['previous_occurrences'] as String?,
            previousOccurrenceDetails: intakeMap['previous_occurrence_details'] as String?,
            existingConditions: List<String>.from(intakeMap['existing_conditions'] ?? []),
            otherConditionDetails: intakeMap['other_condition_details'] as String?,
            allergies: List<String>.from(intakeMap['allergies'] ?? []),
            allergyDetails: intakeMap['allergy_details'] as String?,
            takesMedications: intakeMap['takes_medications'] as String?,
            medicationDetails: intakeMap['medication_details'] as String?,
            medicalFamilyHistory: intakeMap['medical_family_history'] as String?,
            attachments: attachments,
          );
        }

        final dateFormatted = createdDt != null
            ? "${createdDt.day.toString().padLeft(2, '0')} ${months[createdDt.month - 1]} ${createdDt.year}"
            : 'Recent';

        final rawStatus = map['status'] as String? ?? 'awaiting_review';
        String displayStatus = 'Awaiting doctor review';
        Color textColor = const Color(0xFF1E5D46);
        Color bgColor = const Color(0xFFDBEFE3);
        Color borderColor = const Color(0xFFBDE3CC);

        if (rawStatus.toLowerCase().contains('reviewed')) {
          displayStatus = 'Reviewed';
          textColor = const Color(0xFF145338);
          bgColor = const Color(0xFFCEE9DD);
          borderColor = const Color(0xFFB3DCB6);
        } else if (rawStatus.toLowerCase().contains('in_review')) {
          displayStatus = 'In Review';
          textColor = const Color(0xFF854D0E);
          bgColor = const Color(0xFFFEF3C7);
          borderColor = const Color(0xFFFDE68A);
        } else if (rawStatus.toLowerCase().contains('archive')) {
          displayStatus = 'Archived';
          textColor = const Color(0xFF6C8278);
          bgColor = const Color(0xFFE2EAE5);
          borderColor = const Color(0xFFD2DFD6);
        }

        final pId = map['patient_id'] as String?;
        final pName = (pId != null && profilesMap.containsKey(pId))
            ? profilesMap[pId]!
            : (map['patientName'] as String? ?? "Patient");

        fetched.add(PatientCaseSummary(
          id: map['id'] as String? ?? '',
          reference: map['case_reference'] as String? ?? '',
          title: map['title'] as String? ?? 'Clinical Case',
          date: dateFormatted,
          status: displayStatus,
          statusTextColor: textColor,
          statusBgColor: bgColor,
          statusBorderColor: borderColor,
          category: map['category'] as String?,
          patientId: pId,
          patientName: pName,
          submittedAt: createdDt,
          fullCase: fullCase,
        ));
      }

      if (fetched.isNotEmpty || !AuthConfig.useDemoAuth) {
        _cases.clear();
        _cases.addAll(fetched);
        _casesController.add(List.unmodifiable(_cases));
      }
    } catch (e) {
      debugPrint('[DemoCaseRepository] Error fetching Supabase cases: $e');
    }
  }

  /// Get or create active draft
  CaseIntakeModel getOrCreateDraft() {
    if (_activeDraft != null) {
      return _activeDraft!;
    }
    _activeDraft = CaseIntakeModel.empty();
    _draftController.add(_activeDraft);
    return _activeDraft!;
  }

  /// Save draft updates
  Future<bool> saveDraft(CaseIntakeModel draft) async {
    _activeDraft = draft.copyWith(
      status: 'draft',
      lastUpdatedAt: DateTime.now(),
    );
    _draftController.add(_activeDraft);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_draftStorageKey, jsonEncode(_activeDraft!.toJson()));
      return true;
    } catch (e) {
      debugPrint('Error saving case draft to SharedPreferences: $e');
      return false;
    }
  }

  /// Discard active draft
  Future<void> discardDraft() async {
    _activeDraft = null;
    _draftController.add(null);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftStorageKey);
    } catch (e) {
      debugPrint('Error discarding case draft: $e');
    }
  }

  /// Generates a valid UUID v4 compliant string
  static String generateUuid() {
    final rnd = math.Random();
    final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // v4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  /// Submit a completed case
  PatientCaseSummary submitCase(CaseIntakeModel intake) {
    final now = DateTime.now();
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final formattedDate =
        "${now.day.toString().padLeft(2, '0')} ${months[now.month - 1]} ${now.year}";

    final title = intake.chiefConcern.trim().isNotEmpty
        ? (intake.chiefConcern.trim().length > 38
            ? "${intake.chiefConcern.trim().substring(0, 35)}..."
            : intake.chiefConcern.trim())
        : "Clinical Consultation";

    final client = SupabaseConfig.client;
    final user = client?.auth.currentUser;
    final savedProfileName = PatientProfileRepository.instance.profile.fullName;
    final patientName = (savedProfileName.isNotEmpty && savedProfileName != 'Ananya Sharma')
        ? savedProfileName
        : (user?.userMetadata?['full_name'] as String? ?? (user?.email?.split('@').first ?? "Patient"));
    final patientId = user?.id ?? "PAT-${now.millisecondsSinceEpoch.toString().substring(7)}";

    final ref = intake.reference.isNotEmpty
        ? intake.reference
        : "CLIN-${now.millisecondsSinceEpoch.toString().substring(7)}";

    final caseId = generateUuid();
    final submittedSummary = PatientCaseSummary(
      id: caseId,
      reference: ref,
      title: title,
      date: formattedDate,
      status: "Awaiting doctor review",
      statusTextColor: const Color(0xFF1E5D46),
      statusBgColor: const Color(0xFFDBEFE3),
      statusBorderColor: const Color(0xFFBDE3CC),
      category: intake.chiefConcern.toLowerCase().contains("back") || intake.chiefConcern.toLowerCase().contains("knee")
          ? "Musculoskeletal"
          : (intake.chiefConcern.toLowerCase().contains("cough") || intake.chiefConcern.toLowerCase().contains("fever")
              ? "Respiratory"
              : "General Health"),
      patientName: patientName,
      patientId: patientId,
      submittedAt: now,
      fullCase: intake.copyWith(status: 'submitted', reference: ref),
      attachments: intake.attachments,
    );

    // Cache attachments for this case reference and ID
    CaseAttachmentRepository.instance.setAttachmentsForCase(submittedSummary.id, intake.attachments);
    CaseAttachmentRepository.instance.setAttachmentsForCase(ref, intake.attachments);

    // Insert at top of list so it appears first
    _cases.insert(0, submittedSummary);
    _casesController.add(List.unmodifiable(_cases));

    // Clear active draft
    _activeDraft = null;
    _draftController.add(null);
    SharedPreferences.getInstance().then((prefs) => prefs.remove(_draftStorageKey)).catchError((_) => false);

    // Sync to Supabase in background
    _syncCaseToSupabase(submittedSummary, intake.copyWith(reference: ref));

    return submittedSummary;
  }

  void _syncCaseToSupabase(PatientCaseSummary summary, CaseIntakeModel intake) {
    final client = SupabaseConfig.client;
    if (client == null) return;

    Future(() async {
      try {
        final currentUser = client.auth.currentUser;
        final currentSession = AuthConfig.authService.currentSession;
        final userId = currentUser?.id ?? currentSession?.id;

        if (userId != null) {
          // Self-heal: ensure profiles and patient_profiles rows exist so foreign keys never fail
          try {
            await client.from(SupabaseService.tableProfiles).upsert({
              'id': userId,
              'email': currentUser?.email ?? currentSession?.email ?? '',
              'full_name': currentUser?.userMetadata?['full_name'] as String? ?? currentSession?.name ?? 'Patient',
              'role': 'patient',
            });
            await client.from(SupabaseService.tablePatientProfiles).upsert({
              'patient_id': userId,
            });
          } catch (pe) {
            debugPrint('[DemoCaseRepository] Note verifying profile: $pe');
          }
        }

        final caseInsert = {
          'id': summary.id,
          'case_reference': summary.reference,
          'title': summary.title,
          'category': summary.category ?? 'General Health',
          'status': 'awaiting_review',
          'submitted_at': summary.submittedAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
        };

        if (userId != null) {
          caseInsert['patient_id'] = userId;
        }

        final insertedCase = await client
            .from(SupabaseService.tableCases)
            .insert(caseInsert)
            .select()
            .maybeSingle();

        final createdCaseId = insertedCase?['id'] as String?;
        if (createdCaseId != null) {
          await client.from(SupabaseService.tableCaseIntakeResponses).insert({
            'case_id': createdCaseId,
            'current_step': 11,
            'chief_concern': intake.chiefConcern,
            'duration': intake.duration ?? 'Not specified',
            'severity': intake.severity ?? 'Not specified',
            'associated_symptoms': intake.associatedSymptoms,
            'other_associated_symptom': intake.otherAssociatedSymptom,
            'symptom_details': intake.symptomDetails,
            'previous_occurrences': intake.previousOccurrences,
            'previous_occurrence_details': intake.previousOccurrenceDetails,
            'existing_conditions': intake.existingConditions,
            'other_condition_details': intake.otherConditionDetails,
            'allergies': intake.allergies,
            'allergy_details': intake.allergyDetails,
            'takes_medications': intake.takesMedications,
            'medication_details': intake.medicationDetails,
            'medical_family_history': intake.medicalFamilyHistory,
          });

          // Upload any attached medical documents to Supabase Storage & case_attachments table
          if (intake.attachments.isNotEmpty) {
            for (final att in intake.attachments) {
              await CaseAttachmentRepository.instance.uploadAttachment(
                attachment: att,
                caseId: createdCaseId,
                patientId: userId ?? 'anonymous',
              );
            }
          }

          debugPrint('[Supabase] Case and questionnaire responses successfully synced: $createdCaseId');
          // Re-fetch to ensure all server-generated IDs and foreign relations are accurate
          await fetchCasesFromSupabase();
        } else {
          debugPrint('[Supabase] Warning: Case insert response: $insertedCase');
        }
      } catch (e, st) {
        debugPrint('[Supabase] Error syncing case to Supabase: $e\n$st');
      }
    });
  }
}
