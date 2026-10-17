import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clinova/core/routing/app_routes.dart';
import 'package:clinova/features/dashboard/patient/screens/case_intake_screen.dart';
import 'package:clinova/features/dashboard/patient/screens/patient_case_detail_screen.dart';
import 'package:clinova/features/dashboard/patient/services/demo_case_repository.dart';
import 'package:clinova/features/dashboard/patient/views/patient_cases_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DemoCaseRepository.instance.init();
    DemoCaseRepository.instance.resetDefaults();
  });

  Widget buildMyCasesScreen() {
    final testRoutes = Map<String, WidgetBuilder>.from(AppRoutes.routes)..remove('/');
    testRoutes['/cases'] = (context) => const Scaffold(
          body: SingleChildScrollView(
            child: PatientCasesView(),
          ),
        );

    return MaterialApp(
      initialRoute: '/cases',
      routes: testRoutes,
    );
  }

  group('My Health Cases Screen Navigation & Details Tests', () {
    testWidgets('1. Tapping the first case (CASE-101) opens its specific details',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildMyCasesScreen());
      await tester.pumpAndSettle();

      // Check header and cards
      expect(find.text('My Health Cases'), findsOneWidget);
      expect(find.text('Persistent Cough & Low Fever'), findsOneWidget);
      expect(find.text('CASE-101 • Respiratory • Oct 8, 2026'), findsOneWidget);

      // Tap first case card
      await tester.tap(find.text('Persistent Cough & Low Fever'));
      await tester.pumpAndSettle();

      // Opens PatientCaseDetailScreen for CASE-101
      expect(find.byType(PatientCaseDetailScreen), findsOneWidget);
      expect(find.text('CASE-101'), findsOneWidget);
      expect(find.text('Respiratory'), findsOneWidget);
      expect(find.text('Ready'), findsOneWidget);
      expect(find.text('Persistent Cough & Low Fever'), findsAtLeastNWidgets(1));
      expect(find.text('4–7 days'), findsOneWidget);
      expect(find.text('Moderate'), findsOneWidget);
      expect(find.text('Cough'), findsOneWidget);
      expect(find.text('Fever'), findsOneWidget);
      expect(find.text('Fatigue'), findsOneWidget);
      expect(find.textContaining('evening dry cough'), findsOneWidget);

      // Back action returns to My Health Cases
      final backBtn = find.byTooltip('Back to Dashboard');
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.byType(PatientCaseDetailScreen), findsNothing);
      expect(find.text('My Health Cases'), findsOneWidget);
    });

    testWidgets('2. Tapping the second case (CASE-102) opens its specific details',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildMyCasesScreen());
      await tester.pumpAndSettle();

      expect(find.text('Right Knee Strain after Exercise'), findsOneWidget);

      // Tap second case card
      await tester.tap(find.text('Right Knee Strain after Exercise'));
      await tester.pumpAndSettle();

      // Opens PatientCaseDetailScreen for CASE-102
      expect(find.byType(PatientCaseDetailScreen), findsOneWidget);
      expect(find.text('CASE-102'), findsOneWidget);
      expect(find.text('Musculoskeletal'), findsOneWidget);
      expect(find.text('Reviewed'), findsOneWidget);
      expect(find.text('Right Knee Strain after Exercise'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Dr. Marcus Vance'), findsOneWidget);
      expect(find.text('1–3 days'), findsOneWidget);
      expect(find.text('Mild'), findsOneWidget);
      expect(find.text('Pain'), findsOneWidget);
      expect(find.textContaining('Post-jogging discomfort'), findsOneWidget);

      // Back action returns to My Health Cases
      final backBtn = find.byTooltip('Back to Dashboard');
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.byType(PatientCaseDetailScreen), findsNothing);
      expect(find.text('My Health Cases'), findsOneWidget);
    });

    testWidgets('3. Tapping the third case (CASE-103) opens its specific details',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildMyCasesScreen());
      await tester.pumpAndSettle();

      expect(find.text('Annual Wellness Intake'), findsOneWidget);

      // Tap third case card
      await tester.tap(find.text('Annual Wellness Intake'));
      await tester.pumpAndSettle();

      // Opens PatientCaseDetailScreen for CASE-103
      expect(find.byType(PatientCaseDetailScreen), findsOneWidget);
      expect(find.text('CASE-103'), findsOneWidget);
      expect(find.text('General Health'), findsOneWidget);
      expect(find.text('Archived'), findsOneWidget);
      expect(find.text('Annual Wellness Intake'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Dr. Elena Ramos'), findsOneWidget);
      expect(find.text('Comes and goes'), findsOneWidget);
      expect(find.text('Mild'), findsOneWidget);
      expect(find.textContaining('Routine annual health assessment'), findsOneWidget);

      // Back action returns to My Health Cases
      final backBtn = find.byTooltip('Back to Dashboard');
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      expect(find.byType(PatientCaseDetailScreen), findsNothing);
      expect(find.text('My Health Cases'), findsOneWidget);
    });

    testWidgets('4. Tapping different parts of each card (icon, metadata, notes) works',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildMyCasesScreen());
      await tester.pumpAndSettle();

      // Tap on the notes text of CASE-101
      await tester.tap(find.textContaining('4 days duration, evening dry cough'));
      await tester.pumpAndSettle();

      expect(find.byType(PatientCaseDetailScreen), findsOneWidget);
      expect(find.text('CASE-101'), findsOneWidget);

      await tester.tap(find.byTooltip('Back to Dashboard'));
      await tester.pumpAndSettle();

      // Tap on the metadata text of CASE-102
      await tester.tap(find.text('CASE-102 • Musculoskeletal • Sep 25, 2026'));
      await tester.pumpAndSettle();

      expect(find.byType(PatientCaseDetailScreen), findsOneWidget);
      expect(find.text('CASE-102'), findsOneWidget);

      await tester.tap(find.byTooltip('Back to Dashboard'));
      await tester.pumpAndSettle();

      // Tap on the icon container of the third card
      final folderIcons = find.byIcon(Icons.folder_outlined);
      expect(folderIcons, findsNWidgets(3));
      await tester.tap(folderIcons.at(2));
      await tester.pumpAndSettle();

      expect(find.byType(PatientCaseDetailScreen), findsOneWidget);
      expect(find.text('CASE-103'), findsOneWidget);
    });

    testWidgets('5. Filters (All, Ready, Reviewed, Archived) filter cards and remain clickable',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildMyCasesScreen());
      await tester.pumpAndSettle();

      // Filter: Ready
      await tester.tap(find.widgetWithText(ChoiceChip, 'Ready'));
      await tester.pumpAndSettle();

      expect(find.text('Persistent Cough & Low Fever'), findsOneWidget);
      expect(find.text('Right Knee Strain after Exercise'), findsNothing);
      expect(find.text('Annual Wellness Intake'), findsNothing);

      // Tap card while filtered
      await tester.tap(find.text('Persistent Cough & Low Fever'));
      await tester.pumpAndSettle();

      expect(find.byType(PatientCaseDetailScreen), findsOneWidget);
      expect(find.text('CASE-101'), findsOneWidget);

      await tester.tap(find.byTooltip('Back to Dashboard'));
      await tester.pumpAndSettle();

      // Filter: Reviewed
      await tester.tap(find.widgetWithText(ChoiceChip, 'Reviewed'));
      await tester.pumpAndSettle();

      expect(find.text('Persistent Cough & Low Fever'), findsNothing);
      expect(find.text('Right Knee Strain after Exercise'), findsOneWidget);
      expect(find.text('Annual Wellness Intake'), findsNothing);

      // Tap card while filtered
      await tester.tap(find.text('Right Knee Strain after Exercise'));
      await tester.pumpAndSettle();

      expect(find.byType(PatientCaseDetailScreen), findsOneWidget);
      expect(find.text('CASE-102'), findsOneWidget);

      await tester.tap(find.byTooltip('Back to Dashboard'));
      await tester.pumpAndSettle();

      // Filter: Archived
      await tester.tap(find.widgetWithText(ChoiceChip, 'Archived'));
      await tester.pumpAndSettle();

      expect(find.text('Persistent Cough & Low Fever'), findsNothing);
      expect(find.text('Right Knee Strain after Exercise'), findsNothing);
      expect(find.text('Annual Wellness Intake'), findsOneWidget);

      // Tap card while filtered
      await tester.tap(find.text('Annual Wellness Intake'));
      await tester.pumpAndSettle();

      expect(find.byType(PatientCaseDetailScreen), findsOneWidget);
      expect(find.text('CASE-103'), findsOneWidget);

      await tester.tap(find.byTooltip('Back to Dashboard'));
      await tester.pumpAndSettle();

      // Filter: All restores all 3
      await tester.tap(find.widgetWithText(ChoiceChip, 'All'));
      await tester.pumpAndSettle();

      expect(find.text('Persistent Cough & Low Fever'), findsOneWidget);
      expect(find.text('Right Knee Strain after Exercise'), findsOneWidget);
      expect(find.text('Annual Wellness Intake'), findsOneWidget);
    });

    testWidgets('6. + New Case button still opens the 11-step questionnaire',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildMyCasesScreen());
      await tester.pumpAndSettle();

      expect(find.text('+ New Case'), findsOneWidget);
      await tester.tap(find.text('+ New Case'));
      await tester.pumpAndSettle();

      // Opens CaseIntakeScreen
      expect(find.byType(CaseIntakeScreen), findsOneWidget);
      expect(find.text('New Case'), findsOneWidget);
      expect(find.text('Step 1 of 11'), findsOneWidget);
    });
  });
}
