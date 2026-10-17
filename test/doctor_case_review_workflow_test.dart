import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clinova/features/dashboard/doctor/screens/doctor_case_review_screen.dart';
import 'package:clinova/features/dashboard/patient/models/case_intake_model.dart';
import 'package:clinova/features/dashboard/patient/services/demo_case_repository.dart';

void main() {
  setUp(() {
    DemoCaseRepository.instance.resetToDemoDefaults();
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('Doctor Case Review Screen Workflows', () {
    testWidgets('1. Displays specific patient and case header with back button and reference',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final caseItem = DemoCaseRepository.instance.getCaseById('case-01')!;

      await tester.pumpWidget(buildTestableWidget(
        DoctorCaseReviewScreen(initialCase: caseItem),
      ));
      await tester.pumpAndSettle();

      // Top App Bar
      expect(find.text('Clinical Case Review'), findsOneWidget);
      expect(find.byTooltip('Back to Dashboard'), findsOneWidget);

      // Header card
      expect(find.text('DEMO-CASE-8842'), findsWidgets);
      expect(find.text('Summary ready'), findsOneWidget);
      expect(find.text('Persistent Cough & Low Fever'), findsWidgets);
      expect(find.text('Submitted: 08 Oct 2026'), findsOneWidget);

      // Overview Card
      expect(find.text('Patient & Case Overview'), findsOneWidget);
      expect(find.text('Aarav Sharma'), findsWidgets);
      expect(find.text('PAT-8842'), findsWidgets);
      expect(find.text('Respiratory'), findsWidgets);
    });

    testWidgets('2. Displays all 11 intake questionnaire steps in order with exact saved answers',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final caseItem = DemoCaseRepository.instance.getCaseById('case-01')!;

      await tester.pumpWidget(buildTestableWidget(
        DoctorCaseReviewScreen(initialCase: caseItem),
      ));
      await tester.pumpAndSettle();

      // Step 1: Chief Concern / Complaint
      expect(find.text('Primary Health Concern'), findsOneWidget);
      expect(find.text('Chief Concern / Complaint'), findsOneWidget);
      expect(find.text('Persistent Cough & Low Fever'), findsWidgets);

      // Step 2 & 3: Duration & Severity
      expect(find.text('Steps 2 & 3: Duration & Severity'), findsOneWidget);
      expect(find.text('Step 2: Duration'), findsOneWidget);
      expect(find.text('4–7 days'), findsOneWidget);
      expect(find.text('Step 3: Severity'), findsOneWidget);
      expect(find.text('Moderate'), findsOneWidget);

      // Step 4 & 5: Associated Symptoms, Triggers & Relief
      expect(find.text('Associated Symptoms & Triggers'), findsOneWidget);
      expect(find.text('Step 4: Associated Symptoms'), findsOneWidget);
      expect(find.text('Cough'), findsOneWidget);
      expect(find.text('Fever'), findsOneWidget);
      expect(find.text('Fatigue'), findsOneWidget);
      expect(find.text('Step 5: Triggers, Relief & Additional Details'), findsOneWidget);
      expect(find.text('Worse at night and in cooler weather. Warm drinks provide slight soothing.'), findsOneWidget);

      // Step 6: Previous Occurrences
      expect(find.text('Step 6: Previous Occurrences'), findsOneWidget);
      expect(find.text('Prior Occurrences & Treatment History'), findsOneWidget);

      // Step 7 & 8: Medical Conditions & Allergies
      expect(find.text('Medical Context & Background'), findsOneWidget);
      expect(find.text('Step 7: Existing Medical Conditions'), findsOneWidget);
      expect(find.text('None known'), findsOneWidget);
      expect(find.text('Step 8: Allergies'), findsOneWidget);
      expect(find.text('No known allergies'), findsOneWidget);

      // Step 9: Current Medications
      expect(find.text('Step 9: Current Medications'), findsOneWidget);
      expect(find.text('Current Medications / Supplements'), findsOneWidget);
      expect(find.text('No'), findsNWidgets(2)); // Step 6 answer and Step 9 answer are both 'No'

      // Step 10: Relevant Medical & Family History
      expect(find.text('Step 10: Relevant Medical & Family History'), findsOneWidget);
      expect(find.text('Medical & Family History Details'), findsOneWidget);
      expect(find.text('No relevant chronic history reported.'), findsOneWidget);

      // Step 11: Final Review & Submission Information
      expect(find.text('Step 11: Final Review & Submission Information'), findsOneWidget);
      expect(find.text('Submission Reference'), findsOneWidget);
      expect(find.text('DEMO-CASE-8842'), findsWidgets);
      expect(find.text('Submitted by patient after 11-step verification'), findsOneWidget);
    });

    testWidgets('3. Doctor Workflow: "Mark as In Review" updates case status reactively and repository',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final caseItem = DemoCaseRepository.instance.getCaseById('case-01')!;

      await tester.pumpWidget(buildTestableWidget(
        DoctorCaseReviewScreen(initialCase: caseItem),
      ));
      await tester.pumpAndSettle();

      // Ensure button exists for unreviewed case
      final markInReviewBtn = find.text('Mark as In Review');
      expect(markInReviewBtn, findsOneWidget);

      // Initial status
      expect(find.text('Summary ready'), findsOneWidget);

      // Tap button
      await tester.tap(markInReviewBtn);
      await tester.pumpAndSettle();

      // Verify status updated in UI
      expect(find.text('In Review'), findsOneWidget);

      // Verify repository updated
      final updatedRepoCase = DemoCaseRepository.instance.getCaseById('case-01')!;
      expect(updatedRepoCase.status, 'In Review');

      // Verify button is now gone since case is already In Review
      expect(find.text('Mark as In Review'), findsNothing);
    });

    testWidgets('4. Supports different cases distinctly without data cross-contamination',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Case 2: Knee Strain
      final caseItem2 = DemoCaseRepository.instance.getCaseById('case-02')!;

      await tester.pumpWidget(buildTestableWidget(
        DoctorCaseReviewScreen(initialCase: caseItem2),
      ));
      await tester.pumpAndSettle();

      expect(find.text('DEMO-CASE-7193'), findsWidgets);
      expect(find.text('Right Knee Strain after Exercise'), findsWidgets);
      expect(find.text('Musculoskeletal'), findsWidgets);
      expect(find.text('1–3 days'), findsOneWidget);
      expect(find.text('Mild'), findsOneWidget);
      expect(find.text('Pain'), findsOneWidget);
      expect(find.text('Yes — Similar strain 2 years ago after athletic activity.'), findsOneWidget);
    });

    testWidgets('5. Handles missing or empty optional fields gracefully with clear empty states',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Create a minimalist custom case
      final minimalCase = PatientCaseSummary(
        id: 'test-case-minimal',
        reference: 'DEMO-MINIMAL-01',
        title: 'Mild Headache',
        date: '12 Oct 2026',
        status: 'Pending',
        statusTextColor: const Color(0xFF1E5D46),
        statusBgColor: const Color(0xFFDBEFE3),
        statusBorderColor: const Color(0xFFBDE3CC),
        patientName: 'Kavita Rao',
        patientId: 'PAT-9912',
        fullCase: CaseIntakeModel(
          reference: 'DEMO-MINIMAL-01',
          createdAt: DateTime.now(),
          lastUpdatedAt: DateTime.now(),
          chiefConcern: 'Mild Headache',
          duration: null,
          severity: null,
          associatedSymptoms: const [],
          symptomDetails: null,
          previousOccurrences: null,
          existingConditions: const [],
          allergies: const [],
          takesMedications: null,
          medicalFamilyHistory: null,
        ),
      );

      await tester.pumpWidget(buildTestableWidget(
        DoctorCaseReviewScreen(initialCase: minimalCase),
      ));
      await tester.pumpAndSettle();

      expect(find.text('DEMO-MINIMAL-01'), findsWidgets);
      expect(find.text('Kavita Rao'), findsWidgets);
      // Optional defaults
      expect(find.text('None of these'), findsOneWidget);
      expect(find.text('None recorded'), findsWidgets);
      expect(find.text('None known'), findsOneWidget);
      expect(find.text('No known allergies'), findsOneWidget);
      expect(find.text('None provided'), findsOneWidget);
    });

    testWidgets('6. Responsive verification: renders cleanly on mobile viewport (390px) without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final caseItem = DemoCaseRepository.instance.getCaseById('case-01')!;

      await tester.pumpWidget(buildTestableWidget(
        DoctorCaseReviewScreen(initialCase: caseItem),
      ));
      await tester.pumpAndSettle();

      // Zero RenderFlex overflow errors thrown
      expect(tester.takeException(), isNull);

      expect(find.text('Clinical Case Review'), findsOneWidget);
      expect(find.text('DEMO-CASE-8842'), findsWidgets);
      expect(find.text('Aarav Sharma'), findsWidgets);

      // Verify "Ready to begin clinical evaluation?" text renders horizontally with adequate width
      final evalTextFinder = find.text('Ready to begin clinical evaluation?');
      expect(evalTextFinder, findsOneWidget);
      final RenderBox evalBox = tester.renderObject(evalTextFinder);
      // Width must be at least 150px, ensuring it is not squished into a narrow column of vertical single letters
      expect(evalBox.size.width, greaterThan(150.0));
      // Height should be standard 1-2 lines of text (under 60px), not a vertically stretched column of 30+ letters
      expect(evalBox.size.height, lessThan(60.0));
    });

    testWidgets('7. Desktop verification: "Ready to begin clinical evaluation?" and cards use full allocated width',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final caseItem = DemoCaseRepository.instance.getCaseById('case-01')!;

      await tester.pumpWidget(buildTestableWidget(
        DoctorCaseReviewScreen(initialCase: caseItem),
      ));
      await tester.pumpAndSettle();

      final evalTextFinder = find.text('Ready to begin clinical evaluation?');
      expect(evalTextFinder, findsOneWidget);
      final RenderBox evalBox = tester.renderObject(evalTextFinder);
      expect(evalBox.size.width, greaterThan(200.0));
      expect(evalBox.size.height, lessThan(40.0));
    });
  });
}
