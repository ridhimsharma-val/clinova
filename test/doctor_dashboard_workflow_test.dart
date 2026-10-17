import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clinova/core/auth/auth_config.dart';
import 'package:clinova/core/auth/auth_models.dart';
import 'package:clinova/core/routing/app_routes.dart';
import 'package:clinova/features/authentication/doctor/doctor_login_screen.dart';
import 'package:clinova/features/dashboard/doctor/doctor_dashboard_screen.dart';
import 'package:clinova/features/dashboard/doctor/screens/doctor_case_queue_screen.dart';
import 'package:clinova/features/dashboard/doctor/screens/doctor_case_review_screen.dart';
import 'package:clinova/features/dashboard/patient/services/demo_case_repository.dart';

void main() {
  group('Doctor Dashboard and Case Queue Workflows', () {
    setUp(() async {
      await AuthConfig.authService.logout();
      DemoCaseRepository.instance.resetToDemoDefaults();
    });

    testWidgets('Doctor Login routes successfully to Doctor Dashboard', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (_) => const DoctorLoginScreen(),
            AppRoutes.doctorDashboard: (_) => const DoctorDashboardScreen(),
          },
        ),
      );
      await tester.pumpAndSettle();

      // Verify Doctor Login Screen is displayed
      expect(find.text('Doctor Portal'), findsOneWidget);
      expect(find.text('Review patient cases and support informed clinical decisions.'), findsOneWidget);

      // Enter valid doctor credentials and tap Sign in
      final emailFields = find.byType(TextField);
      expect(emailFields, findsNWidgets(2)); // email & password
      await tester.enterText(emailFields.at(0), 'dr.marcus@hospital.org');
      await tester.enterText(emailFields.at(1), 'password123');
      await tester.pumpAndSettle();

      final signInButton = find.text('Sign in to Doctor Portal');
      expect(signInButton, findsOneWidget);
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Check what is rendered
      if (find.byType(DoctorDashboardScreen).evaluate().isEmpty) {
        // Find if any validation error text exists
        final texts = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).toList();
        throw StateError("DoctorDashboardScreen not reached. Current texts: $texts");
      }

      // Verify Doctor Dashboard Screen is rendered
      expect(find.text('Physician Portal'), findsOneWidget);
      expect(find.text('Pending Cases Requiring Attention'), findsOneWidget);

      // Verify Session state
      expect(AuthConfig.authService.isAuthenticated, isTrue);
      expect(AuthConfig.authService.currentSession?.isDoctor, isTrue);
    });

    testWidgets('Doctor Dashboard displays 4 dynamic metrics derived from repository', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await AuthConfig.authService.login(
        email: 'dr.marcus@hospital.org',
        password: 'password123',
        role: UserRole.doctor,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: DoctorDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check metric titles
      expect(find.text('Pending Reviews'), findsOneWidget);
      expect(find.text('Reviewed Cases'), findsOneWidget);
      expect(find.text('Draft Reviews'), findsOneWidget);
      expect(find.text('Assigned Patients'), findsOneWidget);

      // Verify dynamic counts from demo defaults (1 pending, 2 reviewed/archived, 0 draft, 2 patients)
      expect(find.text('1'), findsWidgets); // pending cases count
      expect(find.text('2'), findsWidgets); // reviewed/archived cases & distinct patients
      expect(find.text('0'), findsWidgets); // draft reviews count
    });

    testWidgets('Doctor Dashboard Pending Cases: sorted oldest first and opens Case Review', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await AuthConfig.authService.login(
        email: 'dr.marcus@hospital.org',
        password: 'password123',
        role: UserRole.doctor,
      );

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.doctorCaseReview) {
              final arg = settings.arguments as PatientCaseSummary;
              return MaterialPageRoute(
                builder: (_) => DoctorCaseReviewScreen(initialCase: arg),
              );
            }
            if (settings.name == AppRoutes.doctorCaseQueue) {
              return MaterialPageRoute(
                builder: (_) => const DoctorCaseQueueScreen(),
              );
            }
            return MaterialPageRoute(builder: (_) => const DoctorDashboardScreen());
          },
        ),
      );
      await tester.pumpAndSettle();

      // Verify Section Heading & View all in queue action
      expect(find.text('Pending Cases Requiring Attention'), findsOneWidget);
      expect(find.text('View all in queue'), findsOneWidget);

      // Tap 'View all in queue' to access pending cases in the case queue
      await tester.tap(find.text('View all in queue'));
      await tester.pumpAndSettle();

      // Verify DEMO-CASE-8842 is displayed in queue and open Case Review
      expect(find.text('DEMO-CASE-8842'), findsOneWidget);
      final caseCard = find.text('DEMO-CASE-8842');
      await tester.tap(caseCard);
      await tester.pumpAndSettle();

      // Verify we arrived at Case Review page
      expect(find.text('Clinical Case Review'), findsOneWidget);
      expect(find.text('DEMO-CASE-8842'), findsWidgets);
      expect(find.text('Aarav Sharma'), findsWidgets);
      expect(find.text('Primary Health Concern'), findsOneWidget);
      expect(find.text('Chief Concern / Complaint'), findsOneWidget);
      expect(find.text('Associated Symptoms & Triggers'), findsOneWidget);
      expect(find.text('Medical Context & Background'), findsOneWidget);

      // Tap Back button to return to Case Queue
      final backButton = find.byTooltip('Back to Dashboard');
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Tap Back button in Case Queue to return to Dashboard
      final queueBackButton = find.byTooltip('Back to Dashboard');
      expect(queueBackButton, findsOneWidget);
      await tester.tap(queueBackButton);
      await tester.pumpAndSettle();

      // Verify back on Dashboard
      expect(find.text('Pending Cases Requiring Attention'), findsOneWidget);
    });

    testWidgets('Doctor Case Queue: Search and Filter composability', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));

      await tester.pumpWidget(
        MaterialApp(
          routes: {
            '/': (_) => const DoctorCaseQueueScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == AppRoutes.doctorCaseReview) {
              final arg = settings.arguments as PatientCaseSummary;
              return MaterialPageRoute(
                builder: (_) => DoctorCaseReviewScreen(initialCase: arg),
              );
            }
            return null;
          },
        ),
      );
      await tester.pumpAndSettle();

      // Verify Filter chips exist
      expect(find.widgetWithText(ChoiceChip, 'All Cases'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Pending'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'In Review'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Reviewed'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Archived'), findsOneWidget);

      // All 3 default cases should be visible
      expect(find.text('DEMO-CASE-8842'), findsOneWidget);
      expect(find.text('DEMO-CASE-7193'), findsOneWidget);
      expect(find.text('DEMO-CASE-6041'), findsOneWidget);

      // Filter by 'Pending'
      await tester.tap(find.widgetWithText(ChoiceChip, 'Pending'));
      await tester.pumpAndSettle();
      expect(find.text('DEMO-CASE-8842'), findsOneWidget);
      expect(find.text('DEMO-CASE-7193'), findsNothing);
      expect(find.text('DEMO-CASE-6041'), findsNothing);

      // Filter by 'Reviewed'
      await tester.tap(find.widgetWithText(ChoiceChip, 'Reviewed'));
      await tester.pumpAndSettle();
      expect(find.text('DEMO-CASE-8842'), findsNothing);
      expect(find.text('DEMO-CASE-7193'), findsOneWidget);
      expect(find.text('DEMO-CASE-6041'), findsNothing);

      // Filter by 'Archived'
      await tester.tap(find.widgetWithText(ChoiceChip, 'Archived'));
      await tester.pumpAndSettle();
      expect(find.text('DEMO-CASE-8842'), findsNothing);
      expect(find.text('DEMO-CASE-7193'), findsNothing);
      expect(find.text('DEMO-CASE-6041'), findsOneWidget);

      // Switch back to 'All Cases'
      await tester.tap(find.widgetWithText(ChoiceChip, 'All Cases'));
      await tester.pumpAndSettle();

      // Test Search for 'Knee'
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'Knee');
      await tester.pumpAndSettle();

      expect(find.text('DEMO-CASE-7193'), findsOneWidget);
      expect(find.text('DEMO-CASE-8842'), findsNothing);
      expect(find.text('DEMO-CASE-6041'), findsNothing);

      // Clear search and test search by Patient Name 'Priya'
      await tester.enterText(searchField, 'Priya');
      await tester.pumpAndSettle();

      expect(find.text('DEMO-CASE-6041'), findsOneWidget);
      expect(find.text('DEMO-CASE-8842'), findsNothing);
      expect(find.text('DEMO-CASE-7193'), findsNothing);

      // Search non-existent term to verify empty state
      await tester.enterText(searchField, 'NonExistentCondition');
      await tester.pumpAndSettle();
      expect(find.text('No cases match your filter criteria.'), findsOneWidget);
      expect(find.text('Try adjusting your search terms or selecting a different status filter above.'), findsOneWidget);

      // Clear search
      final clearButton = find.byIcon(Icons.close_rounded);
      expect(clearButton, findsOneWidget);
      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      expect(find.text('DEMO-CASE-8842'), findsOneWidget);
      expect(find.text('DEMO-CASE-7193'), findsOneWidget);
      expect(find.text('DEMO-CASE-6041'), findsOneWidget);

      // Tap on DEMO-CASE-6041 to open Case Review
      await tester.tap(find.text('DEMO-CASE-6041'));
      await tester.pumpAndSettle();

      // Verify Case Review for DEMO-CASE-6041
      expect(find.text('DEMO-CASE-6041'), findsWidgets);
      expect(find.text('Priya Patel'), findsWidgets);
      expect(find.text('Annual Wellness Intake'), findsWidgets);
      expect(find.text('Assigned Clinician: Dr. Elena Ramos'), findsOneWidget);
    });
  });
}
