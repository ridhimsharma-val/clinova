import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clinova/features/dashboard/doctor/models/doctor_assessment_model.dart';
import 'package:clinova/features/dashboard/doctor/screens/doctor_case_review_screen.dart';
import 'package:clinova/features/dashboard/doctor/services/doctor_assessment_repository.dart';
import 'package:clinova/features/dashboard/doctor/services/doctor_profile_repository.dart';
import 'package:clinova/features/dashboard/patient/screens/patient_care_notes_screen.dart';
import 'package:clinova/features/dashboard/patient/services/demo_case_repository.dart';
import 'package:clinova/features/dashboard/patient/services/patient_care_notes_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    DemoCaseRepository.instance.resetToDemoDefaults();
    await PatientCareNotesRepository.instance.init();
    await PatientCareNotesRepository.instance.clearNotes();
    await DoctorAssessmentRepository.instance.init();
    await DoctorAssessmentRepository.instance.clearAll();
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('Doctor Assessment and Supervised Notes Editor Workflows', () {
    testWidgets('1. Doctor Assessment section renders with empty fields initially and no fabricated data',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final caseItem = DemoCaseRepository.instance.getCaseById('case-01')!;

      await tester.pumpWidget(buildTestableWidget(
        DoctorCaseReviewScreen(initialCase: caseItem),
      ));
      await tester.pumpAndSettle();

      // Scroll to doctor assessment section
      final sectionTitleFinder = find.text('Doctor Assessment & Supervised Notes');
      await tester.ensureVisible(sectionTitleFinder);
      await tester.pumpAndSettle();

      // Verify section title and description
      expect(sectionTitleFinder, findsOneWidget);
      expect(
        find.text('Physician observations, diagnostic impressions, advice, and patient follow-up guidance.'),
        findsOneWidget,
      );

      // Verify "New" status badge
      expect(find.text('New'), findsOneWidget);

      // Verify all field labels are present
      expect(find.text('Clinical Assessment *'), findsOneWidget);
      expect(find.text("Doctor's Observations *"), findsOneWidget);
      expect(find.text('Prescription & Medications (Rx)'), findsOneWidget);
      expect(find.text('Advice & Recommendations *'), findsOneWidget);
      expect(find.text('Follow-up Instructions (Optional)'), findsOneWidget);
      expect(find.text('Follow-up Date (Optional)'), findsOneWidget);

      // Verify action buttons
      expect(find.text('Save Draft'), findsOneWidget);
      expect(find.text('Finalize Review'), findsOneWidget);

      // Ensure no care notes exist on the patient side
      expect(PatientCareNotesRepository.instance.notes, isEmpty);
    });

    testWidgets('2. Save Draft persists doctor notes, shows saved state, but does NOT publish to patient',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final caseItem = DemoCaseRepository.instance.getCaseById('case-01')!;

      await tester.pumpWidget(buildTestableWidget(
        DoctorCaseReviewScreen(initialCase: caseItem),
      ));
      await tester.pumpAndSettle();

      // Scroll to fields
      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(5));
      await tester.ensureVisible(textFields.first);

      // Field 1: Clinical Assessment
      await tester.enterText(textFields.at(0), 'Acute viral upper respiratory tract infection with low-grade fever.');
      // Field 2: Doctor's Observations
      await tester.enterText(textFields.at(1), 'Clear breath sounds bilaterally, mild pharyngeal erythema, no wheezing.');
      // Field 3: Prescription
      await tester.enterText(textFields.at(2), 'Paracetamol 650mg TDS x 3 days.');
      // Field 4: Advice & Recommendations
      await tester.enterText(textFields.at(3), 'Adequate oral hydration, steam inhalation, and paracetamol as needed.');
      // Field 5: Follow-up Instructions
      await tester.enterText(textFields.at(4), 'Seek immediate evaluation if temperature exceeds 38.5C or dyspnea develops.');

      // Scroll to Save Draft button and tap
      final saveDraftBtn = find.text('Save Draft');
      await tester.ensureVisible(saveDraftBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveDraftBtn);
      await tester.pumpAndSettle();

      // Verify draft SnackBar appeared
      expect(find.textContaining('Draft assessment saved'), findsOneWidget);
      expect(find.textContaining('Not published to patient'), findsOneWidget);

      // Verify draft status banner in UI
      expect(find.textContaining('Draft saved'), findsWidgets);
      expect(find.text('Draft'), findsOneWidget);

      // CRITICAL: Verify Draft is NOT marked as Reviewed in DemoCaseRepository
      final liveCase = DemoCaseRepository.instance.getCaseById('case-01')!;
      expect(liveCase.status.toLowerCase().contains('reviewed'), isFalse);

      // CRITICAL: Verify notes are NOT published to PatientCareNotesRepository
      expect(PatientCareNotesRepository.instance.notes, isEmpty);

      // Verify draft is persisted in DoctorAssessmentRepository
      final savedAssessment = DoctorAssessmentRepository.instance.getAssessment('case-01');
      expect(savedAssessment, isNotNull);
      expect(savedAssessment!.isFinalized, isFalse);
      expect(savedAssessment.clinicalAssessment, 'Acute viral upper respiratory tract infection with low-grade fever.');
      expect(savedAssessment.observations, 'Clear breath sounds bilaterally, mild pharyngeal erythema, no wheezing.');
      expect(savedAssessment.adviceAndRecommendations, 'Adequate oral hydration, steam inhalation, and paracetamol as needed.');
    });

    testWidgets('3. Finalize Review validates required fields before submission',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final caseItem = DemoCaseRepository.instance.getCaseById('case-01')!;

      await tester.pumpWidget(buildTestableWidget(
        DoctorCaseReviewScreen(initialCase: caseItem),
      ));
      await tester.pumpAndSettle();

      // Scroll to Finalize Review button and tap with empty fields
      final finalizeBtn = find.text('Finalize Review');
      await tester.ensureVisible(finalizeBtn);
      await tester.pumpAndSettle();
      await tester.tap(finalizeBtn);
      await tester.pumpAndSettle();

      // Verify validation error messages are displayed
      expect(find.text('Clinical assessment is required'), findsOneWidget);
      expect(find.text("Doctor's observations are required"), findsOneWidget);
      expect(find.text('Advice and recommendations are required'), findsOneWidget);

      // Confirmation dialog should NOT appear
      expect(find.text('Finalize Clinical Review'), findsNothing);

      // Status should remain unchanged
      final liveCase = DemoCaseRepository.instance.getCaseById('case-01')!;
      expect(liveCase.status.toLowerCase().contains('reviewed'), isFalse);
    });

    testWidgets('4. Finalize Review confirmation dialog allows canceling without changing status',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final caseItem = DemoCaseRepository.instance.getCaseById('case-01')!;

      await tester.pumpWidget(buildTestableWidget(
        DoctorCaseReviewScreen(initialCase: caseItem),
      ));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.ensureVisible(textFields.first);
      await tester.enterText(textFields.at(0), 'Acute viral bronchitis.');
      await tester.enterText(textFields.at(1), 'Mild chest wall soreness.');
      await tester.enterText(textFields.at(2), 'Syrup Ambroxol 10ml BD.');
      await tester.enterText(textFields.at(3), 'Rest and warm fluids.');

      // Tap Finalize Review
      final finalizeBtn = find.text('Finalize Review');
      await tester.ensureVisible(finalizeBtn);
      await tester.pumpAndSettle();
      await tester.tap(finalizeBtn);
      await tester.pumpAndSettle();

      // Confirmation dialog is shown
      expect(find.text('Finalize Clinical Review'), findsOneWidget);
      expect(find.text('Notice on Patient Visibility'), findsOneWidget);
      expect(find.textContaining('Finalized observations, advice, and follow-up instructions will immediately become visible to the patient'), findsOneWidget);

      // Tap Cancel in the dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.text('Finalize Clinical Review'), findsNothing);

      // Status is still NOT reviewed
      final liveCase = DemoCaseRepository.instance.getCaseById('case-01')!;
      expect(liveCase.status.toLowerCase().contains('reviewed'), isFalse);
      expect(PatientCareNotesRepository.instance.notes, isEmpty);
    });

    testWidgets('5. Confirming Finalize updates case status to Reviewed, saves assessment, and publishes to Patient Care Notes',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final caseItem = DemoCaseRepository.instance.getCaseById('case-01')!;

      await tester.pumpWidget(buildTestableWidget(
        DoctorCaseReviewScreen(initialCase: caseItem),
      ));
      await tester.pumpAndSettle();

      final textFields = find.byType(TextFormField);
      await tester.ensureVisible(textFields.first);
      await tester.enterText(textFields.at(0), 'Upper Respiratory Viral Syndrome with dry cough.');
      await tester.enterText(textFields.at(1), 'Normal oxygen saturation (98%), throat clear, chest resonant.');
      await tester.enterText(textFields.at(2), 'Paracetamol 650mg SOS.');
      await tester.enterText(textFields.at(3), 'Hydrate with warm water, avoid cold air triggers, take honey lozenges.');
      await tester.enterText(textFields.at(4), 'Return for review if high fever or productive cough develops.');

      // Tap Finalize Review
      final finalizeBtn = find.text('Finalize Review');
      await tester.ensureVisible(finalizeBtn);
      await tester.pumpAndSettle();
      await tester.tap(finalizeBtn);
      await tester.pumpAndSettle();

      // Tap Confirm in dialog
      await tester.tap(find.text('Finalize & Publish'));
      await tester.pumpAndSettle();

      // 1. Verify case status in DemoCaseRepository is updated to Reviewed
      final liveCase = DemoCaseRepository.instance.getCaseById('case-01')!;
      expect(liveCase.status, 'Reviewed');

      // 2. Verify DoctorAssessmentRepository has finalized assessment
      final savedAssessment = DoctorAssessmentRepository.instance.getAssessment('case-01');
      expect(savedAssessment, isNotNull);
      expect(savedAssessment!.isFinalized, isTrue);
      expect(savedAssessment.finalizedAt, isNotNull);

      // 3. Verify PatientCareNotesRepository now contains the published note
      expect(PatientCareNotesRepository.instance.notes.length, 1);
      final publishedNote = PatientCareNotesRepository.instance.notes.first;
      expect(publishedNote.category, 'Doctor Review');
      expect(publishedNote.author, DoctorProfileRepository.instance.profile.fullName);
      expect(publishedNote.text, contains('Upper Respiratory Viral Syndrome'));
      expect(publishedNote.text, contains("Doctor's Observations:"));
      expect(publishedNote.text, contains('Advice & Recommendations:'));
      expect(publishedNote.text, contains('Follow-up Instructions:'));

      // 4. Verify UI transitioned to read-only Finalized state
      expect(find.text('Finalized'), findsOneWidget);
      expect(find.textContaining('Review Finalized by'), findsOneWidget);
      expect(find.text('Edit Finalized Notes'), findsOneWidget);
      // Editable text fields should be replaced by finalized block views
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets('6. Finalized notes are visible on the Patient Care Notes screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Finalize an assessment directly in repository
      final assessment = DoctorAssessmentModel(
        caseId: 'case-01',
        doctorName: 'Dr. Marcus Vance',
        clinicalAssessment: 'Mild acute bronchitis.',
        observations: 'Lungs clear, respiratory rate normal.',
        adviceAndRecommendations: 'Rest and hydration.',
        followUpInstructions: 'Check back in 5 days if unimproved.',
        followUpDate: DateTime(2026, 10, 20),
        isFinalized: true,
        finalizedAt: DateTime(2026, 10, 12),
        lastSavedAt: DateTime(2026, 10, 12),
      );
      await DoctorAssessmentRepository.instance.finalizeAssessment(assessment);

      // Render PatientCareNotesScreen
      await tester.pumpWidget(buildTestableWidget(
        const PatientCareNotesScreen(),
      ));
      await tester.pumpAndSettle();

      // Verify the note is displayed to the patient
      expect(find.text('Doctor Review'), findsOneWidget);
      expect(find.text('Dr. Marcus Vance'), findsOneWidget);
      expect(find.textContaining('Mild acute bronchitis'), findsOneWidget);
      expect(find.textContaining("Doctor's Observations"), findsOneWidget);
      expect(find.textContaining('Advice & Recommendations'), findsOneWidget);
      expect(find.textContaining('Follow-up Instructions'), findsOneWidget);
      expect(find.textContaining('Recommended Follow-up: 20 Oct 2026'), findsOneWidget);
    });

    testWidgets('7. Explicit edit of finalized notes preserves integrity and syncs updates to patient',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Finalize an initial review
      final assessment = DoctorAssessmentModel(
        caseId: 'case-01',
        doctorName: 'Dr. Marcus Vance',
        clinicalAssessment: 'Initial clinical assessment.',
        observations: 'Initial observations.',
        adviceAndRecommendations: 'Initial advice.',
        isFinalized: true,
        finalizedAt: DateTime(2026, 10, 12),
        lastSavedAt: DateTime(2026, 10, 12),
      );
      await DoctorAssessmentRepository.instance.finalizeAssessment(assessment);

      final caseItem = DemoCaseRepository.instance.getCaseById('case-01')!;

      await tester.pumpWidget(buildTestableWidget(
        DoctorCaseReviewScreen(initialCase: caseItem),
      ));
      await tester.pumpAndSettle();

      // Verify we are in finalized read-only view
      final editBtn = find.text('Edit Finalized Notes');
      await tester.ensureVisible(editBtn);
      await tester.pumpAndSettle();
      expect(editBtn, findsOneWidget);

      // Tap Edit Finalized Notes
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // Warning banner is displayed
      expect(find.textContaining('You are editing a finalized review'), findsOneWidget);
      final updateBtn = find.text('Update & Publish Changes');
      expect(updateBtn, findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Modify advice
      final textFields = find.byType(TextFormField);
      await tester.ensureVisible(textFields.at(3));
      await tester.enterText(textFields.at(3), 'Updated advice: Added prescription inhalation therapy.');

      // Save changes
      await tester.ensureVisible(updateBtn);
      await tester.pumpAndSettle();
      await tester.tap(updateBtn);
      await tester.pumpAndSettle();

      // Confirm dialog
      await tester.tap(find.text('Finalize & Publish'));
      await tester.pumpAndSettle();

      // Verify updated note in PatientCareNotesRepository
      expect(PatientCareNotesRepository.instance.notes.length, 1);
      final updatedNote = PatientCareNotesRepository.instance.notes.first;
      expect(updatedNote.text, contains('Added prescription inhalation therapy'));
    });
  });
}
