import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clinova/core/auth/auth_config.dart';
import 'package:clinova/core/auth/auth_models.dart';
import 'package:clinova/core/routing/app_routes.dart';
import 'package:clinova/features/dashboard/patient/models/case_intake_model.dart';
import 'package:clinova/features/dashboard/patient/screens/patient_case_detail_screen.dart';
import 'package:clinova/features/dashboard/patient/services/demo_case_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Patient Recent Cases & Case Details Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      DemoCaseRepository.instance.resetDefaults();
      await AuthConfig.authService.login(
        email: 'test.patient@example.com',
        password: 'password123',
        role: UserRole.patient,
      );
    });

    tearDown(() async {
      DemoCaseRepository.instance.resetDefaults();
      await AuthConfig.authService.logout();
    });

    testWidgets('1. Clicking the first Recent Case anywhere on the card opens Case 1 details',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.patientDashboard,
        ),
      );
      await tester.pumpAndSettle();

      // Check Recent Cases section title and both cases are visible
      expect(find.text('Recent Cases'), findsOneWidget);
      expect(find.text('Persistent Cough & Low Fever'), findsOneWidget);
      expect(find.text('Right Knee Strain after Exercise'), findsOneWidget);

      // Tap the title area of the first case
      await tester.tap(find.text('Persistent Cough & Low Fever'));
      await tester.pumpAndSettle();

      // Opens PatientCaseDetailScreen for Case 1
      expect(find.byType(PatientCaseDetailScreen), findsOneWidget);
      expect(find.text('Case Details'), findsOneWidget);
      expect(find.text('DEMO-CASE-8842'), findsOneWidget);
      expect(find.text('Persistent Cough & Low Fever'), findsAtLeastNWidgets(1));
      expect(find.text('Summary ready'), findsOneWidget);
      expect(find.text('4–7 days'), findsOneWidget);
      expect(find.text('Moderate'), findsOneWidget);
      expect(find.text('Cough'), findsOneWidget);
      expect(find.text('Fever'), findsOneWidget);
      expect(find.text('Fatigue'), findsOneWidget);

      // Back action returns to Patient Dashboard
      final backButton = find.byTooltip('Back to Dashboard');
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Successfully back on dashboard
      expect(find.byType(PatientCaseDetailScreen), findsNothing);
      expect(find.text('Start a New Case'), findsOneWidget);
    });

    testWidgets('2. Clicking the second Recent Case anywhere on the card opens Case 2 details',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.patientDashboard,
        ),
      );
      await tester.pumpAndSettle();

      // Tap on the date area of the second case to verify non-title tap works
      await tester.tap(find.text('25 Sep 2026'));
      await tester.pumpAndSettle();

      // Opens PatientCaseDetailScreen for Case 2
      expect(find.byType(PatientCaseDetailScreen), findsOneWidget);
      expect(find.text('Case Details'), findsOneWidget);
      expect(find.text('DEMO-CASE-7193'), findsOneWidget);
      expect(find.text('Right Knee Strain after Exercise'), findsAtLeastNWidgets(1));
      expect(find.text('Reviewed by Doctor'), findsOneWidget);
      expect(find.text('1–3 days'), findsOneWidget);
      expect(find.text('Mild'), findsOneWidget);
      expect(find.text('Pain'), findsOneWidget);
      expect(find.textContaining('Similar strain 2 years ago'), findsOneWidget);

      // Verify Case 1 specific values are NOT shown here
      expect(find.text('DEMO-CASE-8842'), findsNothing);
      expect(find.text('4–7 days'), findsNothing);

      // Back action returns to Patient Dashboard
      await tester.tap(find.byTooltip('Back to Dashboard'));
      await tester.pumpAndSettle();

      expect(find.byType(PatientCaseDetailScreen), findsNothing);
    });

    testWidgets('3. Clicking the View button on a Recent Case card also opens its specific details',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.patientDashboard,
        ),
      );
      await tester.pumpAndSettle();

      // Find all "View" pill buttons in the recent cases list
      final viewButtons = find.text('View');
      expect(viewButtons, findsNWidgets(2));

      // Tap the second "View" button
      await tester.tap(viewButtons.at(1));
      await tester.pumpAndSettle();

      // Opens Case 2
      expect(find.byType(PatientCaseDetailScreen), findsOneWidget);
      expect(find.text('DEMO-CASE-7193'), findsOneWidget);
      expect(find.text('Right Knee Strain after Exercise'), findsAtLeastNWidgets(1));
    });

    testWidgets('4. Newly submitted case from New Case flow opens with exact submitted answers',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Submit a fresh custom case via repository
      final customIntake = CaseIntakeModel(
        reference: "DEMO-CASE-9999",
        status: "submitted",
        createdAt: DateTime(2026, 10, 12),
        lastUpdatedAt: DateTime(2026, 10, 12),
        chiefConcern: "Sudden Sharp Lower Back Pain",
        duration: "Less than 24 hours",
        severity: "Very severe",
        associatedSymptoms: const ["Pain", "Difficulty breathing"],
        symptomDetails: "Sharp spasms when trying to stand upright.",
        previousOccurrences: "No",
        existingConditions: const ["None known"],
        allergies: const ["No known allergies"],
        takesMedications: "No",
        medicalFamilyHistory: "Father had lumbar disc herniation.",
      );

      DemoCaseRepository.instance.submitCase(customIntake);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.patientDashboard,
        ),
      );
      await tester.pumpAndSettle();

      // Freshly submitted case is at the top of recent cases
      expect(find.text('Sudden Sharp Lower Back Pain'), findsOneWidget);

      // Tap custom case
      await tester.tap(find.text('Sudden Sharp Lower Back Pain'));
      await tester.pumpAndSettle();

      // Opens custom case details
      expect(find.byType(PatientCaseDetailScreen), findsOneWidget);
      expect(find.text('DEMO-CASE-9999'), findsOneWidget);
      expect(find.text('Awaiting doctor review'), findsOneWidget);
      expect(find.text('Less than 24 hours'), findsOneWidget);
      expect(find.text('Very severe'), findsOneWidget);
      expect(find.text('Difficulty breathing'), findsOneWidget);
      expect(find.text('Sharp spasms when trying to stand upright.'), findsOneWidget);
      expect(find.text('Father had lumbar disc herniation.'), findsOneWidget);

      // Notice message states in queue for review
      expect(
        find.textContaining('in queue for review by your clinical care team'),
        findsOneWidget,
      );
    });

    testWidgets('5. Graceful handling of null/missing fields without crashes or fake data',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Direct rendering with a case having minimal/sparse data
      const minimalCase = PatientCaseSummary(
        id: "case-sparse",
        reference: "DEMO-CASE-MIN",
        title: "Brief Consultation Note",
        date: "01 Jan 2026",
        status: "Archived",
        statusTextColor: Colors.grey,
        statusBgColor: Colors.white,
        statusBorderColor: Colors.grey,
        fullCase: null, // No 11-step questionnaire answers recorded
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: PatientCaseDetailScreen(initialCase: minimalCase),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PatientCaseDetailScreen), findsOneWidget);
      expect(find.text('Case Details'), findsOneWidget);
      expect(find.text('DEMO-CASE-MIN'), findsOneWidget);
      expect(find.text('Brief Consultation Note'), findsAtLeastNWidgets(1));
      expect(find.text('Not specified'), findsNWidgets(2)); // Duration & severity fallback
      expect(find.text('Archived'), findsOneWidget);

      // Does NOT fabricate diagnoses or doctor notes
      expect(find.textContaining('Diagnosed with'), findsNothing);
      expect(find.textContaining('Prescription'), findsNothing);
    });

    testWidgets('6. Invalid/null case ID shows graceful fallback without crash',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PatientCaseDetailScreen(caseId: "non-existent-case-id-12345"),
        ),
      );
      await tester.pumpAndSettle();

      // Gracefully falls back to existing case or shows clean screen
      expect(find.text('Case Details'), findsOneWidget);
    });

    testWidgets('7. Dashboard displays graceful empty state when no cases exist',
        (tester) async {
      DemoCaseRepository.instance.clearCases();

      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.patientDashboard,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Recent Cases'), findsOneWidget);
      expect(find.text('No recent cases yet.'), findsOneWidget);
      expect(
        find.text('When you start and submit a health intake, your cases will be organized here.'),
        findsOneWidget,
      );
    });
  });
}

