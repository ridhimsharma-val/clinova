import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clinova/core/auth/auth_config.dart';
import 'package:clinova/core/auth/auth_models.dart';
import 'package:clinova/core/routing/app_routes.dart';
import 'package:clinova/features/dashboard/patient/screens/case_intake_screen.dart';
import 'package:clinova/features/dashboard/patient/services/demo_case_repository.dart';

void main() {
  group('Case Intake Workflow Tests (13 Steps)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AuthConfig.authService.login(
        email: 'test.patient@example.com',
        password: 'password123',
        role: UserRole.patient,
      );
      DemoCaseRepository.instance.discardDraft();
    });

    tearDown(() async {
      await AuthConfig.authService.logout();
      DemoCaseRepository.instance.discardDraft();
    });

    testWidgets('Case Intake Screen displays header with Back, New Case title, and Save Draft',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.patientCaseIntake,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CaseIntakeScreen), findsOneWidget);
      expect(find.text('New Case'), findsOneWidget);
      expect(find.text('Save Draft'), findsOneWidget);
      expect(find.text('Step 1 of 13'), findsOneWidget);
      expect(find.text('What health concern would you like to discuss with your doctor?'), findsOneWidget);
    });

    testWidgets('Step 1 validation requires input before continuing and preserves input on Back',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.patientCaseIntake,
        ),
      );
      await tester.pumpAndSettle();

      final continueButton = find.widgetWithText(ElevatedButton, 'Continue');
      expect(continueButton, findsOneWidget);

      // Tapping continue with empty field triggers validation message
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      expect(find.text('Please describe your health concern to continue.'), findsOneWidget);

      // Enter chief concern
      await tester.enterText(find.byType(TextFormField).first, 'Dry cough and fever');
      await tester.pumpAndSettle();

      // Tap continue to go to Step 2
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      expect(find.text('Step 2 of 13'), findsOneWidget);
      expect(find.text('How long have you been experiencing this problem?'), findsOneWidget);

      // Navigate Back: original answer must still be present
      final prevBtn = find.widgetWithText(OutlinedButton, 'Previous');
      await tester.ensureVisible(prevBtn);
      await tester.tap(prevBtn);
      await tester.pumpAndSettle();

      expect(find.text('Step 1 of 13'), findsOneWidget);
      expect(find.text('Dry cough and fever'), findsOneWidget);
    });

    testWidgets('Step 6 conditional field appears when selecting Yes for previous occurrences',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.patientCaseIntake,
        ),
      );
      await tester.pumpAndSettle();

      final continueBtn = find.widgetWithText(ElevatedButton, 'Continue');

      // Step 1: Chief concern
      await tester.enterText(find.byType(TextFormField).first, 'Ear pain');
      await tester.pumpAndSettle();
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Step 2: Duration
      await tester.tap(find.text('1–3 days'));
      await tester.pumpAndSettle();
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Step 3: Severity
      await tester.tap(find.text('Moderate'));
      await tester.pumpAndSettle();
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Step 4: Associated symptoms
      await tester.tap(find.text('None of these'));
      await tester.pumpAndSettle();
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Step 5: Triggers (optional)
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Step 6: Previous occurrences
      expect(find.text('Step 6 of 13'), findsOneWidget);
      expect(find.text('Have you experienced this problem before?'), findsOneWidget);

      // Select 'No' -> conditional text input does not appear
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();
      expect(find.text('When did it happen, and how was it treated? (Optional)'), findsNothing);

      // Select 'Yes' -> conditional text input appears
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
      expect(find.text('When did it happen, and how was it treated? (Optional)'), findsOneWidget);
    });

    testWidgets('Full workflow: Steps 1-11 -> Question 12 (Documents) -> Step 13 Review and Submit',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.patientCaseIntake,
        ),
      );
      await tester.pumpAndSettle();

      final continueBtn = find.widgetWithText(ElevatedButton, 'Continue');

      // Step 1: Chief concern
      await tester.enterText(find.byType(TextFormField).first, 'Migraine and light sensitivity');
      await tester.pumpAndSettle();
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Step 2: Duration
      await tester.tap(find.text('1–3 days'));
      await tester.pumpAndSettle();
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Step 3: Severity
      await tester.tap(find.text('Severe'));
      await tester.pumpAndSettle();
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Step 4: Associated symptoms
      await tester.tap(find.text('Headache'));
      await tester.pumpAndSettle();
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Step 5: Symptom details (optional)
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Step 6: Previous occurrences
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Step 7: Existing conditions
      await tester.tap(find.text('None known'));
      await tester.pumpAndSettle();
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Step 8: Allergies
      await tester.tap(find.text('No known allergies'));
      await tester.pumpAndSettle();
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Step 9: Medications
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Step 10: Medical and family history (optional)
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Step 11: Consultation goals (optional)
      expect(find.text('Step 11 of 13'), findsOneWidget);
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Step 12: Supporting Medical Documents (optional)
      expect(find.text('Step 12 of 13'), findsOneWidget);
      expect(find.text('Supporting Medical Documents'), findsOneWidget);
      expect(find.text('Skip for now'), findsOneWidget);

      // Skip document upload and continue to review
      final skipBtn = find.widgetWithText(OutlinedButton, 'Skip for now');
      await tester.tap(skipBtn);
      await tester.pumpAndSettle();

      // Step 13: Review summary
      expect(find.text('Step 13 of 13'), findsOneWidget);
      expect(find.text('Review your case information'), findsOneWidget);
      expect(find.text('Migraine and light sensitivity'), findsOneWidget);
      expect(find.text('None attached (Skipped)'), findsOneWidget);

      // Submit Case button
      final submitBtn = find.widgetWithText(ElevatedButton, 'Submit Case');
      expect(submitBtn, findsOneWidget);
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      // Verify case added to repository
      final latestCase = DemoCaseRepository.instance.cases.first;
      expect(latestCase.title, contains('Migraine and light sensitivity'));
      expect(latestCase.status, equals('Awaiting doctor review'));
    });
  });
}
