import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clinova/core/auth/auth_config.dart';
import 'package:clinova/core/constants/app_constants.dart';
import 'package:clinova/core/routing/app_routes.dart';
import 'package:clinova/features/dashboard/doctor/screens/doctor_profile_screen.dart';
import 'package:clinova/features/dashboard/doctor/services/doctor_profile_repository.dart';
import 'package:clinova/features/dashboard/doctor/widgets/doctor_side_drawer.dart';

void main() {
  group('Doctor Dashboard Profile Card & Profile Screen Workflows', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await AuthConfig.authService.logout();
      await AuthConfig.authService.registerDoctor(
        name: 'Dr. Marcus Vance',
        email: 'dr.marcus@hospital.org',
        specialty: 'General Internal Medicine',
        license: 'CLIN-8821-MD',
        password: 'password123',
      );
      DoctorProfileRepository.instance.resetToDefaults();
    });

    tearDown(() async {
      await AuthConfig.authService.logout();
    });

    testWidgets(
        '1. Welcome banner is replaced with clickable Doctor Profile card with botanical leaves',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.doctorDashboard,
        ),
      );
      await tester.pumpAndSettle();

      // Verify old welcome banner elements are completely absent
      expect(find.text("Welcome, Dr. Marcus Vance"), findsNothing);
      expect(find.byIcon(Icons.medical_services_rounded), findsNothing);

      // Verify new Doctor Profile Card elements are present
      final profileCard = find.byKey(const Key('doctor_dashboard_profile_card'));
      expect(profileCard, findsOneWidget);

      expect(find.text("Dr. Marcus Vance"), findsWidgets);
      expect(find.text("General Internal Medicine • License: CLIN-8821-MD (Demo)"), findsOneWidget);
      expect(find.text("Physician Portal"), findsOneWidget);
      expect(find.text("Demo Credential"), findsOneWidget);
      expect(find.text("View & Edit Profile"), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios_rounded), findsWidgets);

      // Verify initials avatar fallback "MV"
      expect(find.text("MV"), findsWidgets);

      // Verify botanical leaf decoration exists within profile card
      final leavesFinder = find.descendant(
        of: profileCard,
        matching: find.byWidgetPredicate((w) =>
            w is Image &&
            w.image is AssetImage &&
            (w.image as AssetImage).assetName == ClinovaConstants.leavesAsset),
      );
      expect(leavesFinder, findsOneWidget);

      // Tapping the card navigates directly to Doctor Profile Screen
      await tester.tap(profileCard);
      await tester.pumpAndSettle();

      expect(find.byType(DoctorProfileScreen), findsOneWidget);
      expect(find.text("Doctor Profile"), findsOneWidget);
    });

    testWidgets(
        '2. Doctor Profile Screen renders all sections, credentials, and demo disclaimers',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.doctorProfile,
        ),
      );
      await tester.pumpAndSettle();

      // Section A: Header & Photo
      expect(find.text("Dr. Marcus Vance"), findsWidgets);
      expect(find.text("General Internal Medicine"), findsWidgets);
      expect(find.text("LICENSED PHYSICIAN"), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Text && (w.data == "Pending Verification" || w.data == "Demo / Unverified Placeholder")), findsWidgets);

      // Section B: Personal Information
      expect(find.text("Personal Information"), findsOneWidget);
      expect(find.text("Full Name"), findsOneWidget);
      expect(find.text("Date of Birth"), findsOneWidget);

      // Section C: Clinical Credentials
      expect(find.text("Clinical Credentials"), findsOneWidget);
      expect(find.text("Specialty"), findsOneWidget);
      expect(find.text("Medical Qualification"), findsOneWidget);
      expect(find.text("Years of Experience"), findsOneWidget);
      expect(find.text("Medical License"), findsOneWidget);
      expect(find.text("CLIN-8821-MD"), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Text && (w.data == "Pending Verification" || w.data == "Unverified / Demo placeholder")), findsWidgets);

      // Section D: Contact & Workplace
      expect(find.text("Contact & Workplace"), findsOneWidget);
      expect(find.text("Professional Email"), findsOneWidget);
      expect(find.text("dr.marcus@hospital.org"), findsWidgets);
      expect(find.text("Contact Phone"), findsOneWidget);
      expect(find.text("Primary Hospital / Clinic"), findsOneWidget);

      // Section E: Account & Practice
      expect(find.text("Account & Practice Information"), findsOneWidget);
      expect(find.text("Doctor System ID"), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Text && (w.data == "Active Practitioner" || w.data == "Active Demo Practitioner")), findsWidgets);
    });

    testWidgets(
        '3. Edit mode toggle and Cancel action restores original snapshot',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.doctorProfile,
        ),
      );
      await tester.pumpAndSettle();

      // Initially in View mode: "Edit Profile" button is visible
      final editBtn = find.byKey(const Key('edit_doctor_profile_btn_top'));
      expect(editBtn, findsOneWidget);

      // Enter Edit mode
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      // In edit mode: Save and Cancel buttons appear
      final cancelBtnTop = find.byKey(const Key('cancel_doctor_profile_btn_top'));
      final saveBtnTop = find.byKey(const Key('save_doctor_profile_btn_top'));
      expect(cancelBtnTop, findsOneWidget);
      expect(saveBtnTop, findsOneWidget);

      // Modify Full Name field
      final nameField = find.widgetWithText(TextFormField, 'Dr. Marcus Vance');
      expect(nameField, findsOneWidget);
      await tester.enterText(nameField, 'Dr. Marcus Vance Edited');
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(cancelBtnTop);
      await tester.pumpAndSettle();

      // View mode is restored with original name intact
      expect(find.byKey(const Key('edit_doctor_profile_btn_top')), findsOneWidget);
      expect(find.text("Dr. Marcus Vance"), findsWidgets);
      expect(find.text("Dr. Marcus Vance Edited"), findsNothing);
    });

    testWidgets(
        '4. Edit, Save, and Persistence: updates Doctor Profile and reactively updates Doctor Dashboard & Drawer',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.doctorDashboard,
        ),
      );
      await tester.pumpAndSettle();

      // Open Doctor Profile from Dashboard Profile Card
      await tester.tap(find.byKey(const Key('doctor_dashboard_profile_card')));
      await tester.pumpAndSettle();

      // Tap Edit Profile
      await tester.tap(find.byKey(const Key('edit_doctor_profile_btn_top')));
      await tester.pumpAndSettle();

      // Edit Name and Specialty
      final nameField = find.widgetWithText(TextFormField, 'Dr. Marcus Vance');
      await tester.enterText(nameField, 'Dr. Alexandra Chen');

      final specialtyField = find.widgetWithText(TextFormField, 'General Internal Medicine');
      await tester.enterText(specialtyField, 'Cardiology & Intensive Care');
      await tester.pumpAndSettle();

      // Save via Save Changes button (top action)
      final saveTopBtn = find.byKey(const Key('save_doctor_profile_btn_top'));
      await tester.tap(saveTopBtn);
      await tester.pumpAndSettle();

      // Verify success SnackBar
      expect(find.text("Doctor profile updated successfully."), findsOneWidget);

      // Verify updated name and specialty on Doctor Profile screen
      expect(find.text("Dr. Alexandra Chen"), findsWidgets);
      expect(find.text("Cardiology & Intensive Care"), findsWidgets);

      // Pop back to Doctor Dashboard
      await tester.tap(find.byTooltip("Back to Dashboard"));
      await tester.pumpAndSettle();

      // Verify Doctor Dashboard profile card reactively displays updated doctor name & specialty
      expect(find.text("Dr. Alexandra Chen"), findsOneWidget);
      expect(find.text("Cardiology & Intensive Care • License: CLIN-8821-MD (Demo)"), findsOneWidget);
      expect(find.text("AC"), findsWidgets);

      // Open Drawer to verify drawer identity is also reactively updated
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.byType(DoctorSideDrawer), findsOneWidget);
      expect(find.text("Dr. Alexandra Chen"), findsWidgets);
      expect(find.text("AC"), findsWidgets);
    });

    testWidgets('5. Form validation prevents saving empty doctor full name',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.doctorProfile,
        ),
      );
      await tester.pumpAndSettle();

      // Enter edit mode
      await tester.tap(find.byKey(const Key('edit_doctor_profile_btn_top')));
      await tester.pumpAndSettle();

      // Clear full name
      final nameField = find.widgetWithText(TextFormField, 'Dr. Marcus Vance');
      await tester.enterText(nameField, '   ');
      await tester.pumpAndSettle();

      // Attempt to save
      await tester.tap(find.byKey(const Key('save_doctor_profile_btn_top')));
      await tester.pumpAndSettle();

      // Validation error message displayed and stays in edit mode
      expect(find.text("Full name is required"), findsOneWidget);
      expect(find.byKey(const Key('save_doctor_profile_btn_top')), findsOneWidget);
    });

    testWidgets('6. Responsive layout works cleanly on narrow mobile viewport without overflow',
        (WidgetTester tester) async {
      const mobileSize = Size(390, 844);
      tester.view.physicalSize = mobileSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.doctorDashboard,
        ),
      );
      await tester.pumpAndSettle();

      // Verify Profile card renders and is clickable without overflow
      final profileCard = find.byKey(const Key('doctor_dashboard_profile_card'));
      expect(profileCard, findsOneWidget);
      await tester.tap(profileCard);
      await tester.pumpAndSettle();

      expect(find.byType(DoctorProfileScreen), findsOneWidget);
      expect(find.text("Doctor Profile"), findsOneWidget);
    });
  });
}
