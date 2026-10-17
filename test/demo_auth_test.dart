import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clinova/core/auth/auth_config.dart';
import 'package:clinova/core/auth/auth_models.dart';
import 'package:clinova/core/routing/app_routes.dart';
import 'package:clinova/features/authentication/patient/patient_login_screen.dart';
import 'package:clinova/features/authentication/doctor/doctor_login_screen.dart';
import 'package:clinova/features/dashboard/patient/patient_dashboard_screen.dart';
import 'package:clinova/features/dashboard/doctor/doctor_dashboard_screen.dart';
import 'package:clinova/features/welcome/welcome_screen.dart';
import 'package:clinova/shared/widgets/demo_banner.dart';

void main() {
  group('DemoAuthService Unit Tests', () {
    setUp(() async {
      await AuthConfig.authService.logout();
    });

    test('Initial state is unauthenticated', () {
      expect(AuthConfig.authService.currentSession, isNull);
      expect(AuthConfig.authService.isAuthenticated, isFalse);
    });

    test('Patient login rejects invalid email format', () async {
      final result = await AuthConfig.authService.login(
        email: 'invalid-email',
        password: 'password123',
        role: UserRole.patient,
      );
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('valid email'));
      expect(AuthConfig.authService.isAuthenticated, isFalse);
    });

    test('Patient login rejects short password', () async {
      final result = await AuthConfig.authService.login(
        email: 'patient@example.com',
        password: '123',
        role: UserRole.patient,
      );
      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('at least 6 characters'));
      expect(AuthConfig.authService.isAuthenticated, isFalse);
    });

    test('Patient login succeeds with valid inputs and sets patient session', () async {
      final result = await AuthConfig.authService.login(
        email: 'sarah.jenkins@example.com',
        password: 'securePassword123',
        role: UserRole.patient,
      );
      expect(result.isSuccess, isTrue);
      expect(result.session, isNotNull);
      expect(result.session!.role, UserRole.patient);
      expect(result.session!.isPatient, isTrue);
      expect(result.session!.isDoctor, isFalse);
      expect(result.session!.isDemo, isTrue);
      expect(AuthConfig.authService.isAuthenticated, isTrue);
      expect(AuthConfig.authService.currentSession?.email, 'sarah.jenkins@example.com');
    });

    test('Doctor login succeeds with valid inputs and sets doctor session', () async {
      final result = await AuthConfig.authService.login(
        email: 'dr.marcus@hospital.org',
        password: 'doctorSecret456',
        role: UserRole.doctor,
      );
      expect(result.isSuccess, isTrue);
      expect(result.session, isNotNull);
      expect(result.session!.role, UserRole.doctor);
      expect(result.session!.isDoctor, isTrue);
      expect(result.session!.isPatient, isFalse);
      expect(result.session!.specialty, isNotNull);
      expect(result.session!.licenseNumber, isNotNull);
      expect(AuthConfig.authService.isAuthenticated, isTrue);
    });

    test('Patient registration creates valid patient session', () async {
      final result = await AuthConfig.authService.registerPatient(
        name: 'Elena Rostova',
        email: 'elena@example.com',
        password: 'password789',
      );
      expect(result.isSuccess, isTrue);
      expect(result.session?.name, 'Elena Rostova');
      expect(result.session?.role, UserRole.patient);
      expect(AuthConfig.authService.currentSession?.name, 'Elena Rostova');
    });

    test('Doctor registration creates valid doctor session with license details', () async {
      final result = await AuthConfig.authService.registerDoctor(
        name: 'Dr. Gregory House',
        email: 'ghouse@diagnostics.org',
        specialty: 'Internal Medicine / Infectious Disease',
        license: 'NJ-MED-449102',
        password: 'complexPassword123',
      );
      expect(result.isSuccess, isTrue);
      expect(result.session?.name, 'Dr. Gregory House');
      expect(result.session?.specialty, 'Internal Medicine / Infectious Disease');
      expect(result.session?.licenseNumber, 'NJ-MED-449102');
      expect(result.session?.role, UserRole.doctor);
    });

    test('Logout clears session state completely', () async {
      await AuthConfig.authService.login(
        email: 'test@example.com',
        password: 'password123',
        role: UserRole.patient,
      );
      expect(AuthConfig.authService.isAuthenticated, isTrue);

      await AuthConfig.authService.logout();
      expect(AuthConfig.authService.isAuthenticated, isFalse);
      expect(AuthConfig.authService.currentSession, isNull);
    });
  });

  group('Demo Mode UI & Routing Integration Tests', () {
    setUp(() async {
      await AuthConfig.authService.logout();
    });

    testWidgets('Patient Login screen displays DemoBanner and notice text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PatientLoginScreen(),
        ),
      );

      expect(find.byType(DemoBanner), findsOneWidget);
      expect(
        find.text(
          'Demo Mode — authentication is simulated. Real account security will be enabled with backend integration.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Doctor Login screen displays DemoBanner and notice text',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: DoctorLoginScreen(),
        ),
      );

      expect(find.byType(DemoBanner), findsOneWidget);
      expect(
        find.text(
          'Demo Mode — authentication is simulated. Real account security will be enabled with backend integration.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Unauthenticated user is redirected away from Patient Dashboard',
        (WidgetTester tester) async {
      await AuthConfig.authService.logout();

      await tester.pumpWidget(
        MaterialApp(
          home: const PatientDashboardScreen(),
          routes: {
            AppRoutes.welcome: (context) => const WelcomeScreen(),
          },
        ),
      );
      await tester.pumpAndSettle();

      // Guard redirects to Welcome screen
      expect(find.text('Healthcare starts with a conversation.'), findsOneWidget);
      expect(find.byType(PatientDashboardScreen), findsNothing);
    });

    testWidgets('Unauthenticated user is redirected away from Doctor Dashboard',
        (WidgetTester tester) async {
      await AuthConfig.authService.logout();

      await tester.pumpWidget(
        MaterialApp(
          home: const DoctorDashboardScreen(),
          routes: {
            AppRoutes.welcome: (context) => const WelcomeScreen(),
          },
        ),
      );
      await tester.pumpAndSettle();

      // Guard redirects to Welcome screen
      expect(find.text('Healthcare starts with a conversation.'), findsOneWidget);
      expect(find.byType(DoctorDashboardScreen), findsNothing);
    });

    testWidgets('Doctor session cannot access Patient Dashboard (Role Guard)',
        (WidgetTester tester) async {
      // Simulate doctor login
      await AuthConfig.authService.login(
        email: 'dr.marcus@hospital.org',
        password: 'password123',
        role: UserRole.doctor,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: const PatientDashboardScreen(),
          routes: {
            AppRoutes.welcome: (context) => const WelcomeScreen(),
          },
        ),
      );
      await tester.pumpAndSettle();

      // Should be blocked and redirected to Welcome screen
      expect(find.text('Healthcare starts with a conversation.'), findsOneWidget);
    });

    testWidgets('Patient session cannot access Doctor Dashboard (Role Guard)',
        (WidgetTester tester) async {
      // Simulate patient login
      await AuthConfig.authService.login(
        email: 'sarah@example.com',
        password: 'password123',
        role: UserRole.patient,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: const DoctorDashboardScreen(),
          routes: {
            AppRoutes.welcome: (context) => const WelcomeScreen(),
          },
        ),
      );
      await tester.pumpAndSettle();

      // Should be blocked and redirected to Welcome screen
      expect(find.text('Healthcare starts with a conversation.'), findsOneWidget);
    });

    testWidgets('Patient Dashboard renders active session info and module cards',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await AuthConfig.authService.login(
        email: 'alex.morgan@test.com',
        password: 'password123',
        role: UserRole.patient,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: PatientDashboardScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Patient Profile'), findsOneWidget);
      expect(find.text('Start a New Case'), findsOneWidget);
      expect(find.text('Recent Cases'), findsOneWidget);
      expect(find.text('Patient Care Notes'), findsOneWidget);
      expect(find.textContaining('Welcome back'), findsNothing);
      expect(find.textContaining('Good morning'), findsNothing);
      expect(find.byType(DemoBanner), findsOneWidget);
    });

    testWidgets('Doctor Dashboard renders active clinician session info and module cards',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await AuthConfig.authService.registerDoctor(
        name: 'Dr. Clara Oswald',
        email: 'clara@clinic.org',
        specialty: 'Neurology',
        license: 'NEURO-991',
        password: 'password123',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: DoctorDashboardScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Physician Portal'), findsOneWidget);
      expect(find.text('Dr. Clara Oswald'), findsOneWidget);
      expect(find.text('Neurology • License: NEURO-991 (Demo)'), findsOneWidget);
      expect(find.text('Pending Reviews'), findsOneWidget);
      expect(find.text('Reviewed Cases'), findsOneWidget);
      expect(find.text('Draft Reviews'), findsOneWidget);
      expect(find.text('Assigned Patients'), findsOneWidget);
      expect(find.byType(DemoBanner), findsOneWidget);
    });
  });
}
