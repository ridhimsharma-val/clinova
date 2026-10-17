import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';

/// Clinova Central Supabase Service
///
/// Provides strongly-typed access to the 9 public PostgreSQL tables and common queries.
class SupabaseService {
  SupabaseService._();

  static final SupabaseService instance = SupabaseService._();

  // Table name constants matching clinova_supabase_setup.sql exactly
  static const String tableProfiles = 'profiles';
  static const String tablePatientProfiles = 'patient_profiles';
  static const String tableDoctorProfiles = 'doctor_profiles';
  static const String tableCases = 'cases';
  static const String tableCaseIntakeResponses = 'case_intake_responses';
  static const String tableAiCaseSummaries = 'ai_case_summaries';
  static const String tableDoctorAssessments = 'doctor_assessments';
  static const String tablePatientCareNotes = 'patient_care_notes';
  static const String tableNotifications = 'notifications';

  /// Returns the underlying SupabaseClient or null if offline
  SupabaseClient? get client => SupabaseConfig.client;

  /// Whether a live authenticated user exists
  bool get hasActiveAuthSession =>
      client?.auth.currentSession != null &&
      client?.auth.currentUser != null;

  /// Active User UUID in Supabase Auth
  String? get currentUserId => client?.auth.currentUser?.id;

  // Convenient Table Query Builders
  SupabaseQueryBuilder? get profiles => client?.from(tableProfiles);
  SupabaseQueryBuilder? get patientProfiles => client?.from(tablePatientProfiles);
  SupabaseQueryBuilder? get doctorProfiles => client?.from(tableDoctorProfiles);
  SupabaseQueryBuilder? get cases => client?.from(tableCases);
  SupabaseQueryBuilder? get caseIntakeResponses => client?.from(tableCaseIntakeResponses);
  SupabaseQueryBuilder? get aiCaseSummaries => client?.from(tableAiCaseSummaries);
  SupabaseQueryBuilder? get doctorAssessments => client?.from(tableDoctorAssessments);
  SupabaseQueryBuilder? get patientCareNotes => client?.from(tablePatientCareNotes);
  SupabaseQueryBuilder? get notifications => client?.from(tableNotifications);
}
