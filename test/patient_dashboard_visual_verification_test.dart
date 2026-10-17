import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clinova/core/auth/auth_config.dart';
import 'package:clinova/core/auth/auth_models.dart';
import 'package:clinova/core/constants/app_constants.dart';
import 'package:clinova/core/routing/app_routes.dart';
import 'package:clinova/features/dashboard/patient/widgets/patient_app_bar.dart';

import 'package:clinova/features/dashboard/patient/models/patient_profile_model.dart';
import 'package:clinova/features/dashboard/patient/services/patient_profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Patient Dashboard Visual Verification (Restored Sizing)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await PatientProfileRepository.instance.init();
      await PatientProfileRepository.instance.saveProfile(
        PatientProfileModel(
          fullName: 'Aarav Sharma',
          dateOfBirth: DateTime(DateTime.now().year - 24, 1, 1),
          gender: 'Male',
          bloodGroup: 'B+',
          mobileNumber: '+91 98765 43210',
          email: 'aarav.sharma@example.com',
          homeAddress: 'Sector 62, Noida, Uttar Pradesh, India',
        ),
      );
      await AuthConfig.authService.login(
        email: 'test.patient@example.com',
        password: 'password123',
        role: UserRole.patient,
      );
    });

    tearDown(() async {
      await AuthConfig.authService.logout();
    });

    testWidgets('Verify app bar exact three elements and centered symbol at 1440x900',
        (WidgetTester tester) async {
      const size = Size(1440, 900);
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.patientDashboard,
        ),
      );
      await tester.pumpAndSettle();

      // 1. App Bar
      final appBarFinder = find.byType(PatientAppBar);
      expect(appBarFinder, findsOneWidget);
      final appBarBox = tester.getRect(appBarFinder);
      expect(appBarBox.height, equals(80.0));
      expect(appBarBox.width, equals(size.width));

      // 2. Centered Logo Symbol is exactly at viewport horizontal center
      final symbolFinder = find.byWidgetPredicate((w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName == ClinovaConstants.symbolAsset);
      expect(symbolFinder, findsOneWidget);
      final symbolRect = tester.getRect(symbolFinder);
      final expectedCenterX = size.width / 2.0;
      expect((symbolRect.center.dx - expectedCenterX).abs(), lessThan(1.0),
          reason: 'Clinova logo symbol must be at exact horizontal center of the viewport');

      // 3. Hamburger Menu button is on the left
      final menuFinder = find.byIcon(Icons.menu);
      expect(menuFinder, findsOneWidget);
      final menuRect = tester.getRect(menuFinder);
      expect(menuRect.left, lessThan(100.0));

      // 4. Notification button is on the right
      final notifFinder = find.byIcon(Icons.notifications_none_rounded);
      expect(notifFinder, findsOneWidget);
      final notifRect = tester.getRect(notifFinder);
      expect(notifRect.right, greaterThan(size.width - 100.0));

      // 5. Check all 6 main areas are present
      expect(find.text('Patient Profile'), findsOneWidget);
      expect(find.text('General Information'), findsOneWidget);
      expect(find.text('Anamnesis'), findsOneWidget);
      expect(find.text('Start a New Case'), findsOneWidget);
      expect(find.text('Recent Cases'), findsOneWidget);
      expect(find.text('Patient Care Notes'), findsOneWidget);

      // 6. Verify Patient Profile Illustration is rendered
      final illustrationFinder = find.byWidgetPredicate((w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName == ClinovaConstants.patientIllustrationAsset);
      expect(illustrationFinder, findsOneWidget, reason: 'Patient portrait illustration must be rendered in Patient Profile card');

      // 7. Verify Patient Profile alignments
      final patientProfileFinder = find.ancestor(
        of: find.text('Patient Profile'),
        matching: find.byType(Container),
      ).first;
      final generalInfoFinder = find.ancestor(
        of: find.text('General Information'),
        matching: find.byType(Container),
      ).first;
      final anamnesisFinder = find.ancestor(
        of: find.text('Anamnesis'),
        matching: find.byType(Container),
      ).first;

      final patientProfileRect = tester.getRect(patientProfileFinder);
      final generalInfoRect = tester.getRect(generalInfoFinder);
      final anamnesisRect = tester.getRect(anamnesisFinder);

      // Top edges match
      expect((patientProfileRect.top - generalInfoRect.top).abs(), lessThan(1.5),
          reason: 'Patient Profile top edge must align with General Information top edge');
      // Bottom edges match combined right-hand column
      expect((patientProfileRect.bottom - anamnesisRect.bottom).abs(), lessThan(1.5),
          reason: 'Patient Profile bottom edge must align with Anamnesis bottom edge');
      // 8. Verify all existing patient details and actions remain visible and intact
      expect(find.text('AS'), findsOneWidget);
      expect(find.text('Aarav Sharma'), findsOneWidget);
      expect(find.text('24 years   |   Male'), findsOneWidget);
      expect(find.text('Active patient'), findsOneWidget);
      expect(find.text('Patient ID'), findsOneWidget);
      expect(find.text('DEMO'), findsWidgets);
      expect(find.text('CL-P-20481'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Details'), findsNWidgets(3)); // Profile, General Info, Anamnesis

      // 9. Both retained cases and patient care notes
      expect(find.text('Persistent Cough & Low Fever'), findsOneWidget);
      expect(find.text('Right Knee Strain after Exercise'), findsOneWidget);
      expect(find.text('Annual Wellness Intake'), findsNothing);
      expect(find.text('Important observations and follow-ups'), findsOneWidget);

      // 10. Start case button
      expect(find.text('Start case'), findsOneWidget);
    });
  });
}
