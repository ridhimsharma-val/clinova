import 'package:flutter/material.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/welcome/welcome_screen.dart';
import '../../features/authentication/patient/patient_login_screen.dart';
import '../../features/authentication/patient/patient_signup_screen.dart';
import '../../features/authentication/doctor/doctor_login_screen.dart';
import '../../features/authentication/doctor/doctor_signup_screen.dart';
import '../../features/authentication/forgot_password_screen.dart';
import '../../features/dashboard/patient/patient_dashboard_screen.dart';
import '../../features/dashboard/patient/screens/case_intake_screen.dart';
import '../../features/dashboard/patient/screens/patient_onboarding_screen.dart';
import '../../features/dashboard/patient/screens/patient_profile_details_screen.dart';
import '../../features/dashboard/patient/screens/patient_general_info_screen.dart';
import '../../features/dashboard/patient/screens/patient_anamnesis_screen.dart';
import '../../features/dashboard/patient/screens/patient_care_notes_screen.dart';
import '../../features/dashboard/patient/screens/patient_case_detail_screen.dart';
import '../../features/dashboard/patient/services/demo_case_repository.dart';
import '../../features/dashboard/doctor/doctor_dashboard_screen.dart';
import '../../features/dashboard/doctor/screens/doctor_case_queue_screen.dart';
import '../../features/dashboard/doctor/screens/doctor_case_review_screen.dart';
import '../../features/dashboard/doctor/screens/doctor_profile_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String welcome = '/welcome';

  // Patient Auth & Workspace
  static const String patientLogin = '/auth/patient/login';
  static const String patientSignup = '/auth/patient/signup';
  static const String patientOnboarding = '/patient/onboarding';
  static const String patientDashboard = '/patient/dashboard';
  static const String patientCaseIntake = '/patient/case-intake';
  static const String patientProfileDetails = '/patient/profile-details';
  static const String patientGeneralInfo = '/patient/general-info';
  static const String patientAnamnesis = '/patient/anamnesis';
  static const String patientCareNotes = '/patient/care-notes';
  static const String patientCaseDetail = '/patient/case-detail';

  // Doctor Auth & Workspace
  static const String doctorLogin = '/auth/doctor/login';
  static const String doctorSignup = '/auth/doctor/signup';
  static const String doctorDashboard = '/doctor/dashboard';
  static const String doctorCaseQueue = '/doctor/case-queue';
  static const String doctorCaseReview = '/doctor/case-review';
  static const String doctorProfile = '/doctor/profile';

  // Shared Auth
  static const String forgotPassword = '/auth/forgot-password';

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),
        welcome: (context) => const WelcomeScreen(),
        patientLogin: (context) => const PatientLoginScreen(),
        patientSignup: (context) => const PatientSignupScreen(),
        patientOnboarding: (context) => const PatientOnboardingScreen(),
        patientDashboard: (context) => const PatientDashboardScreen(),
        patientCaseIntake: (context) => const CaseIntakeScreen(),
        patientProfileDetails: (context) => const PatientProfileDetailsScreen(),
        patientGeneralInfo: (context) => const PatientGeneralInfoScreen(),
        patientAnamnesis: (context) => const PatientAnamnesisScreen(),
        patientCareNotes: (context) => const PatientCareNotesScreen(),
        patientCaseDetail: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is PatientCaseSummary) {
            return PatientCaseDetailScreen(initialCase: args);
          } else if (args is String) {
            return PatientCaseDetailScreen(caseId: args);
          } else if (args is Map<String, dynamic>) {
            return PatientCaseDetailScreen(
              initialCase: args['case'] as PatientCaseSummary?,
              caseId: args['caseId'] as String? ?? args['id'] as String?,
            );
          }
          return const PatientCaseDetailScreen();
        },
        doctorLogin: (context) => const DoctorLoginScreen(),
        doctorSignup: (context) => const DoctorSignupScreen(),
        doctorDashboard: (context) => const DoctorDashboardScreen(),
        doctorCaseQueue: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final initialFilter = args is String ? args : 'All Cases';
          return DoctorCaseQueueScreen(initialFilter: initialFilter);
        },
        doctorCaseReview: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is PatientCaseSummary) {
            return DoctorCaseReviewScreen(initialCase: args);
          } else if (args is String) {
            return DoctorCaseReviewScreen(caseId: args);
          } else if (args is Map<String, dynamic>) {
            return DoctorCaseReviewScreen(
              initialCase: args['case'] as PatientCaseSummary?,
              caseId: args['caseId'] as String? ?? args['id'] as String?,
            );
          }
          return const DoctorCaseReviewScreen();
        },
        doctorProfile: (context) => const DoctorProfileScreen(),
        forgotPassword: (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          return ForgotPasswordScreen(
            role: args?['role'] as String? ?? 'User',
          );
        },
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final builder = routes[settings.name];
    if (builder != null) {
      return PageRouteBuilder(
        settings: settings,
        pageBuilder: (context, animation, secondaryAnimation) => builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOutCubic,
            ),
            child: child,
          );
        },
      );
    }
    return null;
  }
}
