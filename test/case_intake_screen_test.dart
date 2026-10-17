import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clinova/features/dashboard/patient/screens/case_intake_screen.dart';
import 'package:clinova/features/dashboard/patient/services/demo_case_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DemoCaseRepository.instance.discardDraft();
  });

  testWidgets('New Case questionnaire flow: Questions 1-11 -> Question 12 Documents -> Step 13 Review & Submission',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1728, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: const CaseIntakeScreen(),
        routes: {
          '/patient/dashboard': (context) => const Scaffold(body: Text("Mock Patient Dashboard")),
        },
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Step 1 header and progress
    expect(find.text("Step 1 of 13"), findsOneWidget);
    expect(find.text("Save Draft"), findsOneWidget);

    // 2. Verify Question heading & Required badge
    final headingFinder = find.text("What health concern would you like to discuss with your doctor?");
    expect(headingFinder, findsOneWidget);
    expect(find.text("Required"), findsOneWidget);

    // 3. Verify Bottom Action Row buttons: Back on left, Continue on right (both always rendered)
    final backFinder = find.widgetWithText(OutlinedButton, "Back");
    expect(backFinder, findsOneWidget);

    final continueFinder = find.widgetWithText(ElevatedButton, "Continue");
    expect(continueFinder, findsOneWidget);

    // 4. Test validation: clicking Continue with empty answer shows message and stays on Step 1
    await tester.tap(continueFinder);
    await tester.pumpAndSettle();
    expect(find.text("Please describe your health concern to continue."), findsOneWidget);
    expect(find.text("Step 1 of 13"), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, "Continue"), findsOneWidget);

    // 5. Enter answer for Step 1
    final textFieldFinder = find.byType(TextFormField).first;
    await tester.enterText(textFieldFinder, "Persistent fever and headache");
    await tester.pumpAndSettle();

    // 6. Click Continue -> Step 2
    await tester.tap(continueFinder);
    await tester.pumpAndSettle();
    expect(find.text("Step 2 of 13"), findsOneWidget);
    expect(find.text("How long have you been experiencing this problem?"), findsOneWidget);

    // 7. Step 2 validation & selection
    await tester.tap(continueFinder);
    await tester.pumpAndSettle();
    expect(find.text("Please select how long you have experienced this problem."), findsOneWidget);

    await tester.tap(find.text("1–3 days"));
    await tester.pumpAndSettle();

    // Advance to Step 3
    await tester.tap(continueFinder);
    await tester.pumpAndSettle();
    expect(find.text("Step 3 of 13"), findsOneWidget);
    expect(find.text("How severe is your problem right now?"), findsOneWidget);

    // Step 3 selection
    await tester.tap(find.text("Moderate"));
    await tester.pumpAndSettle();

    // Advance to Step 4
    await tester.tap(continueFinder);
    await tester.pumpAndSettle();
    expect(find.text("Step 4 of 13"), findsOneWidget);
    expect(find.text("Are you experiencing any other symptoms?"), findsOneWidget);

    // Step 4 selection (multi-select)
    await tester.tap(find.text("Fever"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Fatigue"));
    await tester.pumpAndSettle();

    // Advance to Step 5
    await tester.tap(continueFinder);
    await tester.pumpAndSettle();
    expect(find.text("Step 5 of 13"), findsOneWidget);
    expect(find.text("What makes your symptoms better or worse?"), findsOneWidget);

    // Advance to Step 6 (Step 5 is optional)
    await tester.tap(continueFinder);
    await tester.pumpAndSettle();
    expect(find.text("Step 6 of 13"), findsOneWidget);
    expect(find.text("Have you experienced this problem before?"), findsOneWidget);

    // Step 6 selection
    await tester.tap(find.text("No"));
    await tester.pumpAndSettle();

    // Advance to Step 7
    await tester.tap(continueFinder);
    await tester.pumpAndSettle();
    expect(find.text("Step 7 of 13"), findsOneWidget);
    expect(find.text("Do you have any existing medical conditions?"), findsOneWidget);

    // Step 7 selection
    await tester.tap(find.text("None known"));
    await tester.pumpAndSettle();

    // Advance to Step 8
    await tester.tap(continueFinder);
    await tester.pumpAndSettle();
    expect(find.text("Step 8 of 13"), findsOneWidget);
    expect(find.text("Do you have any known allergies?"), findsOneWidget);

    // Step 8 selection
    await tester.tap(find.text("No known allergies"));
    await tester.pumpAndSettle();

    // Advance to Step 9
    await tester.tap(continueFinder);
    await tester.pumpAndSettle();
    expect(find.text("Step 9 of 13"), findsOneWidget);
    expect(find.text("Are you currently taking any medicines or supplements?"), findsOneWidget);

    // Step 9 selection
    await tester.tap(find.text("No"));
    await tester.pumpAndSettle();

    // Advance to Step 10
    await tester.tap(continueFinder);
    await tester.pumpAndSettle();
    expect(find.text("Step 10 of 13"), findsOneWidget);
    expect(find.text("Is there any other medical or family history your doctor should know?"), findsOneWidget);

    // Advance to Step 11: Specific Inquiries & Goals (Optional)
    await tester.tap(continueFinder);
    await tester.pumpAndSettle();
    expect(find.text("Step 11 of 13"), findsOneWidget);
    expect(find.text("Do you have any specific inquiries or consultation goals?"), findsOneWidget);
    expect(find.text("OPTIONAL"), findsOneWidget);

    // Advance to Step 12: Supporting Medical Documents (Optional)
    await tester.tap(continueFinder);
    await tester.pumpAndSettle();
    expect(find.text("Step 12 of 13"), findsOneWidget);
    expect(find.text("Supporting Medical Documents"), findsOneWidget);
    expect(find.text("Upload medical documents"), findsOneWidget);
    expect(find.text("Attach Documents"), findsOneWidget);
    expect(find.text("Skip for now"), findsOneWidget);
    expect(find.text("Continue to Review"), findsOneWidget);

    // Advance from Step 12 to Step 13 (Review Screen) via Continue to Review
    final continueToReviewBtn = find.widgetWithText(ElevatedButton, "Continue to Review");
    expect(continueToReviewBtn, findsOneWidget);
    await tester.tap(continueToReviewBtn);
    await tester.pumpAndSettle();

    // Verify Step 13 Final Review
    expect(find.text("Step 13 of 13"), findsOneWidget);
    expect(find.text("100% completed"), findsOneWidget);
    expect(find.text("Review your case information"), findsOneWidget);

    // Verify answers rendered in review summary
    expect(find.text("Persistent fever and headache"), findsOneWidget);
    expect(find.text("1–3 days"), findsOneWidget);
    expect(find.text("Moderate"), findsOneWidget);
    expect(find.text("Fever, Fatigue"), findsOneWidget);
    expect(find.text("None attached (Skipped)"), findsOneWidget);

    // Verify Action button changes to "Submit Case"
    expect(find.widgetWithText(ElevatedButton, "Submit Case"), findsOneWidget);

    // Test Back navigation preserving answers
    final previousFinder = find.widgetWithText(OutlinedButton, "Previous");
    await tester.ensureVisible(previousFinder);
    await tester.pumpAndSettle();
    await tester.tap(previousFinder);
    await tester.pumpAndSettle();
    expect(find.text("Step 12 of 13"), findsOneWidget);

    // Return to Step 13
    await tester.tap(find.widgetWithText(ElevatedButton, "Continue to Review"));
    await tester.pumpAndSettle();
    expect(find.text("Step 13 of 13"), findsOneWidget);

    // Test jump to Edit on Step 1 from review
    final editButtons = find.widgetWithText(TextButton, "Edit");
    await tester.ensureVisible(editButtons.first);
    await tester.pumpAndSettle();
    await tester.tap(editButtons.first);
    await tester.pumpAndSettle();
    expect(find.text("Step 1 of 13"), findsOneWidget);
    expect(find.text("Persistent fever and headache"), findsOneWidget);

    // Test top-left back arrow confirmation and navigation to Dashboard
    final topLeftArrow = find.byTooltip("Back to Dashboard");
    expect(topLeftArrow, findsOneWidget);
    await tester.tap(topLeftArrow);
    await tester.pumpAndSettle();

    // Confirmation dialog appears because answers have unsaved edits
    expect(find.text("Discard unsaved changes?"), findsOneWidget);
    // Tap "Leave & Discard"
    await tester.tap(find.text("Leave & Discard"));
    await tester.pumpAndSettle();

    // Navigates directly to AppRoutes.patientDashboard
    expect(find.text("Step 1 of 13"), findsNothing);
  });
}
