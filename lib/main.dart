import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/supabase/supabase_config.dart';
import 'features/dashboard/doctor/services/ai_case_summary_repository.dart';
import 'features/dashboard/doctor/services/doctor_assessment_repository.dart';
import 'features/dashboard/doctor/services/doctor_profile_repository.dart';
import 'features/dashboard/patient/services/demo_case_repository.dart';
import 'features/dashboard/patient/services/patient_care_notes_repository.dart';
import 'features/dashboard/patient/services/patient_profile_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase if configured (graceful fallback if in demo mode)
  await SupabaseConfig.init();

  // Load saved patient & doctor profile, care notes, case draft, doctor assessments, and AI summaries
  await PatientProfileRepository.instance.init();
  await DoctorProfileRepository.instance.init();
  await DemoCaseRepository.instance.init();
  await PatientCareNotesRepository.instance.init();
  await DoctorAssessmentRepository.instance.init();
  await AiCaseSummaryRepository.instance.init();

  // Set system UI overlay style to match Clinova soft mint / off-white palette
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFFF6FAF6),
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ClinovaApp());
}
