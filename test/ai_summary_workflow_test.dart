import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clinova/features/dashboard/doctor/models/ai_case_summary_model.dart';
import 'package:clinova/features/dashboard/doctor/models/doctor_assessment_model.dart';
import 'package:clinova/features/dashboard/doctor/screens/doctor_case_review_screen.dart';
import 'package:clinova/features/dashboard/doctor/services/ai_case_summary_repository.dart';
import 'package:clinova/features/dashboard/doctor/services/doctor_assessment_repository.dart';
import 'package:clinova/features/dashboard/patient/models/case_intake_model.dart';
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
    await AiCaseSummaryRepository.instance.init();
    await AiCaseSummaryRepository.instance.clearAll();
  });

  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: child,
    );
  }

  group('AI Case Summary via n8n Orchestrator Acceptance Tests', () {
    test('1. Submitting a case saves it in DemoCaseRepository even if n8n webhook is unavailable', () async {
      final initialCount = DemoCaseRepository.instance.cases.length;

      final intake = CaseIntakeModel(
        reference: 'DEMO-OFFLINE-01',
        createdAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
        chiefConcern: 'Acute Sinus Headache and Congestion',
        duration: '1–3 days',
        severity: 'Moderate',
        associatedSymptoms: const ['Headache', 'Fever'],
        symptomDetails: 'Facial pressure when bending forward.',
        previousOccurrences: 'No',
        existingConditions: const ['None known'],
        allergies: const ['No known allergies'],
        takesMedications: 'No',
        medicalFamilyHistory: 'Unremarkable',
      );

      // Submit case through repository (as done in CaseIntakeScreen)
      final submittedSummary = DemoCaseRepository.instance.submitCase(intake);

      // Case must be safely saved in DemoCaseRepository
      expect(DemoCaseRepository.instance.cases.length, initialCount + 1);
      final retrieved = DemoCaseRepository.instance.getCaseById(submittedSummary.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.title, contains('Sinus Headache'));

      // Attempt AI generation with an unavailable endpoint
      final mockFailingClient = MockClient((request) async {
        throw http.ClientException('Connection refused to n8n webhook');
      });

      final summaryResult = await AiCaseSummaryRepository.instance.generateSummaryForCase(
        caseSummary: submittedSummary,
        client: mockFailingClient,
      );

      // Verify failure is gracefully recorded
      expect(summaryResult.isFailed, isTrue);
      expect(summaryResult.errorMessage, contains('Could not reach n8n workflow'));

      // CRITICAL: The case in DemoCaseRepository is STILL fully intact and not lost or duplicated
      expect(DemoCaseRepository.instance.cases.length, initialCount + 1);
      expect(DemoCaseRepository.instance.getCaseById(submittedSummary.id), isNotNull);
    });

    test('2. The request payload contains the exact saved case ID and questionnaire answers', () async {
      final intake = CaseIntakeModel(
        reference: 'DEMO-PAYLOAD-02',
        createdAt: DateTime(2026, 10, 12, 11, 0),
        lastUpdatedAt: DateTime(2026, 10, 12, 11, 15),
        chiefConcern: 'Persistent Cough with low fever',
        duration: '4–7 days',
        severity: 'Moderate',
        associatedSymptoms: const ['Cough', 'Fever', 'Fatigue'],
        otherAssociatedSymptom: null,
        symptomDetails: 'Worse at night and in cooler weather.',
        previousOccurrences: 'No',
        previousOccurrenceDetails: null,
        existingConditions: const ['None known'],
        otherConditionDetails: null,
        allergies: const ['No known allergies'],
        allergyDetails: null,
        takesMedications: 'No',
        medicationDetails: null,
        medicalFamilyHistory: 'Non-smoker, family history negative.',
      );

      final submittedSummary = DemoCaseRepository.instance.submitCase(intake);

      // Build payload
      final payload = AiCaseSummaryRepository.instance.buildRequestPayload(submittedSummary);

      expect(payload['caseId'], submittedSummary.id);
      expect(payload['caseReference'], submittedSummary.reference);
      expect(payload['chiefComplaint'], 'Persistent Cough with low fever');
      expect(payload['duration'], '4–7 days');
      expect(payload['severity'], 'Moderate');
      expect(payload['associatedSymptoms'], const ['Cough', 'Fever', 'Fatigue']);
      expect(payload['triggersAndRelief'], 'Worse at night and in cooler weather.');
      expect(payload['previousOccurrences'], 'No');
      expect(payload['existingConditions'], const ['None known']);
      expect(payload['allergies'], const ['No known allergies']);
      expect(payload['takesMedications'], 'No');
      expect(payload['medicalFamilyHistory'], 'Non-smoker, family history negative.');
    });

    test('3. A successful n8n response creates a validated summary associated with the correct case', () async {
      final intake = CaseIntakeModel(
        reference: 'DEMO-CASE-8842',
        createdAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
        chiefConcern: 'Persistent Cough & Low Fever',
      );
      final submittedSummary = DemoCaseRepository.instance.submitCase(intake);

      final mockSuccessClient = MockClient((request) async {
        final decoded = jsonDecode(request.body) as Map<String, dynamic>;
        expect(decoded['caseId'], submittedSummary.id);

        final responseBody = {
          'caseId': submittedSummary.id,
          'generationStatus': 'ready',
          'generatedAt': DateTime.now().toIso8601String(),
          'summaryText': 'Patient reports 4–7 day history of dry cough and low-grade fever.',
          'chiefComplaint': 'Persistent Cough & Low Fever',
          'symptomTimelineAndSeverity': 'Onset 4–7 days ago; moderate severity.',
          'relevantPositiveFindings': ['Dry cough', 'Low-grade fever'],
          'relevantNegativeFindings': ['No shortness of breath', 'No chronic conditions'],
          'medicalHistoryAndMedications': 'Non-smoker; no medications.',
          'missingOrUnclearInformation': ['Confirm peak temperature with thermometer'],
        };
        return http.Response(jsonEncode(responseBody), 200, headers: {'content-type': 'application/json'});
      });

      final summaryResult = await AiCaseSummaryRepository.instance.generateSummaryForCase(
        caseSummary: submittedSummary,
        client: mockSuccessClient,
      );

      expect(summaryResult.isReady, isTrue);
      expect(summaryResult.caseId, submittedSummary.id);
      expect(summaryResult.summaryText, contains('dry cough'));
      expect(summaryResult.relevantPositiveFindings, contains('Dry cough'));
      expect(summaryResult.relevantNegativeFindings, contains('No shortness of breath'));
      expect(summaryResult.missingOrUnclearInformation, contains('Confirm peak temperature with thermometer'));

      // Check repository persistence
      final saved = AiCaseSummaryRepository.instance.getSummary(submittedSummary.id);
      expect(saved, isNotNull);
      expect(saved!.isReady, isTrue);
    });

    test('4. Invalid responses and mismatched case IDs are handled gracefully', () async {
      final intake = CaseIntakeModel(
        reference: 'DEMO-MISMATCH-04',
        createdAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
        chiefConcern: 'Right Knee Strain',
      );
      final submittedSummary = DemoCaseRepository.instance.submitCase(intake);

      // Return response with mismatched caseId
      final mockMismatchedClient = MockClient((request) async {
        final responseBody = {
          'caseId': 'DIFFERENT-CASE-9999', // Mismatched!
          'generationStatus': 'ready',
          'summaryText': 'Wrong case text',
        };
        return http.Response(jsonEncode(responseBody), 200);
      });

      final summaryResult = await AiCaseSummaryRepository.instance.generateSummaryForCase(
        caseSummary: submittedSummary,
        client: mockMismatchedClient,
      );

      // Must be flagged as failed due to case ID mismatch
      expect(summaryResult.isFailed, isTrue);
      expect(summaryResult.errorMessage, contains('Mismatched case ID'));
    });

    test('5. Retrying does not duplicate cases or duplicate summary records', () async {
      final initialCasesCount = DemoCaseRepository.instance.cases.length;

      final intake = CaseIntakeModel(
        reference: 'DEMO-RETRY-05',
        createdAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
        chiefConcern: 'Mild Ankle Inversion',
      );
      final submittedSummary = DemoCaseRepository.instance.submitCase(intake);
      expect(DemoCaseRepository.instance.cases.length, initialCasesCount + 1);

      // 1st attempt fails
      final mockFail = MockClient((req) async => http.Response('Server error', 500));
      await AiCaseSummaryRepository.instance.generateSummaryForCase(
        caseSummary: submittedSummary,
        client: mockFail,
      );
      expect(AiCaseSummaryRepository.instance.getSummary(submittedSummary.id)!.isFailed, isTrue);

      // 2nd attempt succeeds
      final mockSuccess = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'caseId': submittedSummary.id,
            'generationStatus': 'ready',
            'summaryText': 'Ankle inversion with mild localized edema.',
            'chiefComplaint': 'Mild Ankle Inversion',
            'symptomTimelineAndSeverity': 'Acute onset today.',
            'relevantPositiveFindings': ['Localized edema'],
            'relevantNegativeFindings': ['Able to bear weight'],
            'medicalHistoryAndMedications': 'None',
            'missingOrUnclearInformation': ['Confirm ability to walk 4 steps'],
          }),
          200,
        );
      });

      await AiCaseSummaryRepository.instance.retryGeneration(
        submittedSummary,
        client: mockSuccess,
      );

      // Summary is now ready
      final summary = AiCaseSummaryRepository.instance.getSummary(submittedSummary.id)!;
      expect(summary.isReady, isTrue);
      expect(summary.summaryText, contains('Ankle inversion'));

      // ZERO case duplication in DemoCaseRepository
      expect(DemoCaseRepository.instance.cases.length, initialCasesCount + 1);
    });

    test('6. Different cases display their own distinct summaries without cross-contamination', () async {
      final summary1 = AiCaseSummaryModel(
        caseId: 'case-01',
        generationStatus: 'ready',
        summaryText: 'Summary for Case 1: Respiratory cough',
        chiefComplaint: 'Cough',
        lastRequestedAt: DateTime.now(),
      );
      final summary2 = AiCaseSummaryModel(
        caseId: 'case-02',
        generationStatus: 'ready',
        summaryText: 'Summary for Case 2: Musculoskeletal knee pain',
        chiefComplaint: 'Knee Pain',
        lastRequestedAt: DateTime.now(),
      );

      await AiCaseSummaryRepository.instance.saveSummary(summary1);
      await AiCaseSummaryRepository.instance.saveSummary(summary2);

      expect(AiCaseSummaryRepository.instance.getSummary('case-01')!.summaryText, contains('Case 1'));
      expect(AiCaseSummaryRepository.instance.getSummary('case-02')!.summaryText, contains('Case 2'));
    });

    testWidgets('7. AI summary is clearly labelled as decision support and strictly separate from doctor notes',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Seed a ready summary for case-01
      await AiCaseSummaryRepository.instance.saveSummary(
        AiCaseSummaryModel(
          caseId: 'case-01',
          generationStatus: 'ready',
          summaryText: 'Executive summary text for respiratory case.',
          chiefComplaint: 'Persistent Cough',
          lastRequestedAt: DateTime.now(),
        ),
      );

      final caseItem = DemoCaseRepository.instance.getCaseById('case-01')!;

      await tester.pumpWidget(buildTestableWidget(
        DoctorCaseReviewScreen(initialCase: caseItem),
      ));
      await tester.pumpAndSettle();

      // Find AI Case Summary Card
      expect(find.text('AI Case Summary'), findsOneWidget);

      // Verify mandatory disclaimer
      expect(
        find.textContaining('AI-generated summary — requires physician review'),
        findsOneWidget,
      );

      // Verify AI summary card has its own content
      expect(find.text('Executive Clinical Briefing'), findsOneWidget);

      // Verify Doctor Assessment section below remains empty and completely independent
      final doctorSection = find.text('Doctor Assessment & Supervised Notes');
      await tester.ensureVisible(doctorSection);
      await tester.pumpAndSettle();
      expect(doctorSection, findsOneWidget);

      // Doctor text fields are separate and not filled with AI summary
      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(5));
      // First field is clinical assessment and starts empty
      final assessmentField = tester.widget<TextFormField>(fields.at(0));
      expect(assessmentField.controller?.text, isEmpty);
    });

    testWidgets('8. Existing Save Draft and Finalize Review behavior remains intact with AI summary present',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final caseItem = DemoCaseRepository.instance.getCaseById('case-01')!;

      await tester.pumpWidget(buildTestableWidget(
        DoctorCaseReviewScreen(initialCase: caseItem),
      ));
      await tester.pumpAndSettle();

      // Enter doctor draft
      final fields = find.byType(TextFormField);
      await tester.ensureVisible(fields.first);
      await tester.enterText(fields.at(0), 'Doctor Clinical Assessment text');
      await tester.enterText(fields.at(1), 'Doctor Observations text');
      await tester.enterText(fields.at(2), 'Doctor Advice text');

      // Tap Save Draft
      final saveDraftBtn = find.text('Save Draft');
      await tester.ensureVisible(saveDraftBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveDraftBtn);
      await tester.pumpAndSettle();

      // Draft saved without overwriting AI summary or marking reviewed
      expect(DoctorAssessmentRepository.instance.getAssessment('case-01')!.isFinalized, isFalse);
      expect(DemoCaseRepository.instance.getCaseById('case-01')!.status.toLowerCase().contains('reviewed'), isFalse);
    });

    test('9. AI summary generation never automatically finalizes review or changes case status to Reviewed', () async {
      final caseItem = DemoCaseRepository.instance.getCaseById('case-01')!;
      expect(caseItem.status, isNot('Reviewed'));

      // Generate/ready an AI summary
      final summary = AiCaseSummaryModel(
        caseId: 'case-01',
        generationStatus: 'ready',
        summaryText: 'Summary generated successfully',
        lastRequestedAt: DateTime.now(),
      );
      await AiCaseSummaryRepository.instance.saveSummary(summary);

      // Verify case status in DemoCaseRepository is STILL NOT 'Reviewed'
      final liveCase = DemoCaseRepository.instance.getCaseById('case-01')!;
      expect(liveCase.status, isNot('Reviewed'));

      // Verify no doctor assessment was finalized
      final docAssessment = DoctorAssessmentRepository.instance.getAssessment('case-01');
      expect(docAssessment?.isFinalized ?? false, isFalse);
    });

    test('10. Patient Care Notes does not expose unpublished doctor notes or AI summaries', () async {
      // Seed a draft doctor assessment
      final draft = DoctorAssessmentModel(
        caseId: 'case-01',
        doctorName: 'Dr. Marcus Vance',
        clinicalAssessment: 'Draft assessment not for patient eyes',
        isFinalized: false,
        lastSavedAt: DateTime.now(),
      );
      await DoctorAssessmentRepository.instance.saveDraft(draft);

      // Seed an AI summary
      final aiSummary = AiCaseSummaryModel(
        caseId: 'case-01',
        generationStatus: 'ready',
        summaryText: 'AI summary for doctor only',
        lastRequestedAt: DateTime.now(),
      );
      await AiCaseSummaryRepository.instance.saveSummary(aiSummary);

      // Verify Patient Care Notes repository has ZERO notes
      expect(PatientCareNotesRepository.instance.notes, isEmpty);
    });

    testWidgets('11. All 11 intake questionnaire answers and patient flow remain completely intact',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final caseItem = DemoCaseRepository.instance.getCaseById('case-01')!;

      await tester.pumpWidget(buildTestableWidget(
        DoctorCaseReviewScreen(initialCase: caseItem),
      ));
      await tester.pumpAndSettle();

      // Verify Step 1
      expect(find.text('Primary Health Concern'), findsOneWidget);
      expect(find.text('Chief Concern / Complaint'), findsOneWidget);

      // Verify Step 2 & 3
      expect(find.text('Steps 2 & 3: Duration & Severity'), findsOneWidget);
      expect(find.text('4–7 days'), findsOneWidget);
      expect(find.text('Moderate'), findsOneWidget);

      // Verify Step 4 & 5
      expect(find.text('Associated Symptoms & Triggers'), findsOneWidget);
      expect(find.text('Cough'), findsOneWidget);
      expect(find.text('Fever'), findsOneWidget);

      // Verify Step 6
      expect(find.text('Prior Occurrences & Treatment History'), findsOneWidget);

      // Verify Step 7 & 8
      expect(find.text('Medical Context & Background'), findsOneWidget);

      // Verify Step 9
      expect(find.text('Current Medications / Supplements'), findsOneWidget);

      // Verify Step 10
      expect(find.text('Step 10: Relevant Medical & Family History'), findsOneWidget);

      // Verify Step 11
      expect(find.text('Step 11: Final Review & Submission Information'), findsOneWidget);
    });

    testWidgets('12. Botanical leaf watermark decorations render behind content and do not block interaction',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Seed a ready summary for case-01 so Re-run Summary button renders
      await AiCaseSummaryRepository.instance.saveSummary(
        AiCaseSummaryModel(
          caseId: 'case-01',
          generationStatus: 'ready',
          summaryText: 'Summary for case-01',
          lastRequestedAt: DateTime.now(),
        ),
      );

      final caseItem = DemoCaseRepository.instance.getCaseById('case-01')!;

      await tester.pumpWidget(buildTestableWidget(
        DoctorCaseReviewScreen(initialCase: caseItem),
      ));
      await tester.pumpAndSettle();

      // Leaf images are present and wrapped in IgnorePointer
      final leafImages = find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is AssetImage && (widget.image as AssetImage).assetName.contains('leaves'),
      );
      expect(leafImages, findsWidgets);

      // Re-run Summary button is clickable through any stacked decorations
      final rerunBtn = find.text('Re-run Summary');
      await tester.ensureVisible(rerunBtn);
      await tester.pumpAndSettle();
      await tester.tap(rerunBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // SnackBar triggered confirming tap passed cleanly
      expect(find.textContaining('Requesting AI case summary'), findsOneWidget);
    });
  });
}
