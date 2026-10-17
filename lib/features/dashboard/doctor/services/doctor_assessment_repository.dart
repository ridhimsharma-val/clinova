import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/supabase/supabase_config.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../../patient/models/patient_care_note_model.dart';
import '../../patient/services/demo_case_repository.dart';
import '../../patient/services/patient_care_notes_repository.dart';
import '../models/doctor_assessment_model.dart';

/// Clinova Doctor Assessment Repository
///
/// Manages draft and finalized doctor assessments, observations, and care notes.
/// Handles persistence, draft state management, and updates to the Patient Care Notes repository
/// only when explicitly finalized by the physician.
class DoctorAssessmentRepository {
  DoctorAssessmentRepository._();

  static final DoctorAssessmentRepository instance =
      DoctorAssessmentRepository._();

  static const String _storageKey = 'clinova_doctor_assessments_store';

  final Map<String, DoctorAssessmentModel> _assessments = {};
  final StreamController<Map<String, DoctorAssessmentModel>> _assessmentsController =
      StreamController<Map<String, DoctorAssessmentModel>>.broadcast();

  Stream<Map<String, DoctorAssessmentModel>> get assessmentsStream =>
      _assessmentsController.stream;

  Map<String, DoctorAssessmentModel> get assessments =>
      Map.unmodifiable(_assessments);

  /// Initializes the repository from SharedPreferences and Supabase
  Future<void> init() async {
    _assessments.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_storageKey);
      if (savedJson != null && savedJson.trim().isNotEmpty) {
        final decoded = jsonDecode(savedJson) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          if (entry.value is Map<String, dynamic>) {
            _assessments[entry.key] = DoctorAssessmentModel.fromJson(
                entry.value as Map<String, dynamic>);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading saved doctor assessments: $e');
    }
    _assessmentsController.add(_assessments);

    final client = SupabaseConfig.client;
    if (client != null) {
      client.auth.onAuthStateChange.listen((_) {
        fetchAssessmentsFromSupabase();
      });
      await fetchAssessmentsFromSupabase();
    }
  }

  /// Fetches doctor assessments from Supabase
  Future<void> fetchAssessmentsFromSupabase() async {
    final client = SupabaseConfig.client;
    if (client == null) return;
    try {
      final response = await client
          .from(SupabaseService.tableDoctorAssessments)
          .select();

      for (final row in response as List) {
        final map = row as Map<String, dynamic>;
        final caseId = map['case_id'] as String?;
        if (caseId != null && caseId.isNotEmpty) {
          _assessments[caseId] = DoctorAssessmentModel(
            caseId: caseId,
            doctorName: 'Attending Physician',
            clinicalAssessment: map['clinical_assessment'] as String? ?? '',
            prescription: map['prescription'] as String? ?? '',
            observations: map['observations'] as String? ?? '',
            adviceAndRecommendations: map['advice_and_recommendations'] as String? ?? '',
            followUpInstructions: map['follow_up_instructions'] as String? ?? '',
            followUpDate: map['follow_up_date'] != null
                ? DateTime.tryParse(map['follow_up_date'] as String)
                : null,
            isFinalized: map['is_finalized'] as bool? ?? false,
            finalizedAt: map['finalized_at'] != null
                ? DateTime.tryParse(map['finalized_at'] as String)
                : null,
            lastSavedAt: map['updated_at'] != null
                ? DateTime.tryParse(map['updated_at'] as String) ?? DateTime.now()
                : DateTime.now(),
          );
        }
      }
      _assessmentsController.add(Map.unmodifiable(_assessments));
    } catch (e) {
      debugPrint('[DoctorAssessmentRepository] Error fetching assessments: $e');
    }
  }

  /// Get the current assessment (draft or finalized) for a given case ID
  DoctorAssessmentModel? getAssessment(String caseId) {
    if (caseId.trim().isEmpty) return null;
    final normalized = caseId.trim().toLowerCase();
    for (final entry in _assessments.entries) {
      if (entry.key.toLowerCase() == normalized) {
        return entry.value;
      }
    }
    return null;
  }

  /// Saves or updates a draft assessment for a case.
  ///
  /// CRITICAL: Drafts are strictly private to the doctor:
  /// - Does NOT publish to PatientCareNotesRepository
  /// - Does NOT mark case as "Reviewed" in DemoCaseRepository
  Future<bool> saveDraft(DoctorAssessmentModel assessment) async {
    final updated = assessment.copyWith(
      isFinalized: false,
      lastSavedAt: DateTime.now(),
    );
    _assessments[assessment.caseId] = updated;
    _assessmentsController.add(_assessments);

    return _persist();
  }

  /// Finalizes the doctor's review:
  /// 1. Persists assessment with isFinalized = true and finalized timestamp
  /// 2. Updates case status in DemoCaseRepository to 'Reviewed'
  /// 3. Publishes structured note into PatientCareNotesRepository visible to the patient
  Future<bool> finalizeAssessment(
    DoctorAssessmentModel assessment, {
    String? caseReference,
  }) async {
    final now = DateTime.now();
    final finalized = assessment.copyWith(
      isFinalized: true,
      finalizedAt: assessment.finalizedAt ?? now,
      lastSavedAt: now,
    );

    _assessments[assessment.caseId] = finalized;
    _assessmentsController.add(_assessments);

    // 1. Update Case Status in DemoCaseRepository
    DemoCaseRepository.instance.updateCaseStatus(
      assessment.caseId,
      "Reviewed",
      assignedDoctor: assessment.doctorName,
    );

    // 2. Publish to Patient Care Notes
    await _publishToPatientCareNotes(finalized, caseReference: caseReference);

    // 3. Sync assessment and case status to Supabase
    final client = SupabaseConfig.client;
    final doctorUser = client?.auth.currentUser;
    if (client != null && doctorUser != null) {
      Future(() async {
        try {
          final payload = <String, dynamic>{
            'case_id': assessment.caseId,
            'doctor_id': doctorUser.id,
            'clinical_assessment': assessment.clinicalAssessment,
            'observations': assessment.observations,
            'advice_and_recommendations': assessment.adviceAndRecommendations,
            'follow_up_instructions': assessment.followUpInstructions,
            'follow_up_date': assessment.followUpDate?.toIso8601String(),
            'is_finalized': true,
            'finalized_at': finalized.finalizedAt?.toIso8601String(),
          };
          if (assessment.prescription.isNotEmpty) {
            payload['prescription'] = assessment.prescription;
          }

          try {
            await client.from(SupabaseService.tableDoctorAssessments).upsert(payload);
          } catch (_) {
            // If table doesn't have 'prescription' column yet, upsert without it
            payload.remove('prescription');
            await client.from(SupabaseService.tableDoctorAssessments).upsert(payload);
          }

          await client.from(SupabaseService.tableCases).update({
            'status': 'reviewed',
            'assigned_doctor_id': doctorUser.id,
            'reviewed_at': finalized.finalizedAt?.toIso8601String(),
          }).eq('id', assessment.caseId);
        } catch (e) {
          debugPrint('[DoctorAssessmentRepository] Error syncing assessment to Supabase: $e');
        }
      });
    }

    return _persist();
  }

  /// Formats and publishes finalized notes to the patient care notes repository
  Future<void> _publishToPatientCareNotes(
    DoctorAssessmentModel assessment, {
    String? caseReference,
  }) async {
    final buffer = StringBuffer();

    if (assessment.prescription.trim().isNotEmpty) {
      buffer.writeln("Prescription / Medications:");
      buffer.writeln(assessment.prescription.trim());
    }

    if (assessment.clinicalAssessment.trim().isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln("Clinical Assessment:");
      buffer.writeln(assessment.clinicalAssessment.trim());
    }

    if (assessment.observations.trim().isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln("Doctor's Observations:");
      buffer.writeln(assessment.observations.trim());
    }

    if (assessment.adviceAndRecommendations.trim().isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln("Advice & Recommendations:");
      buffer.writeln(assessment.adviceAndRecommendations.trim());
    }

    if (assessment.followUpInstructions.trim().isNotEmpty) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln("Follow-up Instructions:");
      buffer.writeln(assessment.followUpInstructions.trim());
    }

    if (assessment.followUpDate != null) {
      final date = assessment.followUpDate!;
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final formattedDate =
          "${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}";
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.writeln("Recommended Follow-up: $formattedDate");
    }

    final note = PatientCareNote(
      id: "care-note-${assessment.caseId}",
      text: buffer.toString().trim(),
      date: assessment.finalizedAt ?? DateTime.now(),
      author: assessment.doctorName.isNotEmpty
          ? assessment.doctorName
          : "Attending Physician",
      category: "Doctor Review",
    );

    await PatientCareNotesRepository.instance.saveNote(note);

    // Sync to Supabase public.patient_care_notes
    final client = SupabaseConfig.client;
    final doctorUser = client?.auth.currentUser;
    if (client != null && doctorUser != null) {
      try {
        final caseItem = DemoCaseRepository.instance.getCaseById(assessment.caseId);
        final patientId = caseItem?.patientId;
        if (patientId != null && patientId.isNotEmpty) {
          await client.from(SupabaseService.tablePatientCareNotes).insert({
            'case_id': assessment.caseId,
            'patient_id': patientId,
            'doctor_id': doctorUser.id,
            'author_name': assessment.doctorName.isNotEmpty ? assessment.doctorName : 'Attending Physician',
            'category': 'Doctor Review',
            'note_text': buffer.toString().trim(),
            'published_at': (assessment.finalizedAt ?? DateTime.now()).toIso8601String(),
          });
        }
      } catch (e) {
        debugPrint('[DoctorAssessmentRepository] Error writing care note to Supabase: $e');
      }
    }
  }

  /// Persists current assessments map to SharedPreferences
  Future<bool> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapToSave = _assessments.map(
        (key, value) => MapEntry(key, value.toJson()),
      );
      await prefs.setString(_storageKey, jsonEncode(mapToSave));
      return true;
    } catch (e) {
      debugPrint('Error saving doctor assessments: $e');
      return false;
    }
  }

  /// Clears all assessments (used primarily for test isolation)
  Future<void> clearAll() async {
    _assessments.clear();
    _assessmentsController.add(_assessments);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }
}
