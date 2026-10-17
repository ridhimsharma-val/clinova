import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clinova/features/dashboard/patient/screens/patient_anamnesis_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PatientAnamnesisScreen Tests', () {
    testWidgets('1. Displays populated sample records instead of empty states', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: PatientAnamnesisScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header & Title
      expect(find.text("Anamnesis"), findsOneWidget);

      // Verify all 8 realistic sample medical-history values
      expect(find.text("No known chronic conditions reported"), findsOneWidget);
      expect(find.text("No known allergies reported"), findsOneWidget);
      expect(find.text("No regular medications reported"), findsOneWidget);
      expect(find.text("No significant past medical history reported"), findsOneWidget);
      expect(find.text("No previous surgeries reported"), findsOneWidget);
      expect(find.text("Sample entry — family history needs confirmation"), findsOneWidget);
      expect(find.text("Sample entry — lifestyle details need confirmation"), findsOneWidget);
      expect(find.text("No additional notes provided"), findsOneWidget);

      // Verify Section Headings
      expect(find.text("Existing Medical Conditions"), findsOneWidget);
      expect(find.text("Allergies"), findsOneWidget);
      expect(find.text("Current Medications"), findsOneWidget);
      expect(find.text("Past Medical History"), findsOneWidget);
      expect(find.text("Surgical History"), findsOneWidget);
      expect(find.text("Family History"), findsOneWidget);
      expect(find.text("Lifestyle"), findsOneWidget);
      expect(find.text("Additional Notes"), findsOneWidget);
      expect(find.text("Emergency Information"), findsOneWidget);
    });

    testWidgets('2. Displays visible "Demo data — please verify" indicator', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: PatientAnamnesisScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining("Demo data — please verify"), findsAtLeastNWidgets(1));
    });

    testWidgets('3. Read-only by default, Edit button switches to editable mode', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: PatientAnamnesisScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // In view mode: no TextFormField
      expect(find.byType(TextFormField), findsNothing);

      // Edit button is present
      final editBtn = find.widgetWithText(ElevatedButton, "Edit");
      expect(editBtn, findsOneWidget);

      // Tap Edit
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // In edit mode: TextFormFields are present for all fields
      expect(find.byType(TextFormField), findsNWidgets(8));

      // Action buttons Save Changes and Cancel are present
      expect(find.widgetWithText(ElevatedButton, "Save Changes"), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, "Cancel"), findsOneWidget);
    });

    testWidgets('4. Cancel discards unsaved edits', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: PatientAnamnesisScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter edit mode
      await tester.tap(find.widgetWithText(ElevatedButton, "Edit"));
      await tester.pumpAndSettle();

      // Change text in first field
      final conditionsField = find.byType(TextFormField).first;
      await tester.enterText(conditionsField, "Modified temporary condition");
      await tester.pumpAndSettle();

      // Tap Cancel
      final cancelBtn = find.widgetWithText(OutlinedButton, "Cancel");
      await tester.ensureVisible(cancelBtn);
      await tester.pumpAndSettle();
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      // Confirms view mode restored with original sample record
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text("No known chronic conditions reported"), findsOneWidget);
      expect(find.text("Modified temporary condition"), findsNothing);
      expect(find.text("Unsaved changes discarded."), findsOneWidget);
    });

    testWidgets('5. Save Changes persists edited values across reloads', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        const MaterialApp(
          home: PatientAnamnesisScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter edit mode
      await tester.tap(find.widgetWithText(ElevatedButton, "Edit"));
      await tester.pumpAndSettle();

      // Edit conditions and allergies
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), "Type 1 Diabetes Mellitus");
      await tester.enterText(textFields.at(1), "Penicillin allergy (severe)");
      await tester.pumpAndSettle();

      // Tap Save Changes
      final saveBtn = find.widgetWithText(ElevatedButton, "Save Changes");
      await tester.ensureVisible(saveBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Confirms view mode displays new values and success message
      expect(find.byType(TextFormField), findsNothing);
      expect(find.text("Type 1 Diabetes Mellitus"), findsOneWidget);
      expect(find.text("Penicillin allergy (severe)"), findsOneWidget);
      expect(find.text("Medical history saved successfully."), findsOneWidget);

      // Re-create the widget to test persistence across page reload/navigation
      await tester.pumpWidget(
        const MaterialApp(
          home: PatientAnamnesisScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Saved values are restored from storage
      expect(find.text("Type 1 Diabetes Mellitus"), findsOneWidget);
      expect(find.text("Penicillin allergy (severe)"), findsOneWidget);
    });

    testWidgets('6. Back arrow navigates back to Dashboard', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      bool popped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            onDidRemovePage: (page) {
              popped = true;
            },
            pages: const [
              MaterialPage(child: Scaffold(body: Text("Dashboard Home"))),
              MaterialPage(child: PatientAnamnesisScreen()),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final backButton = find.byTooltip("Back to Dashboard");
      expect(backButton, findsOneWidget);

      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(popped, isTrue);
    });
  });
}
