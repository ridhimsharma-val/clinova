import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clinova/core/auth/auth_config.dart';
import 'package:clinova/core/auth/auth_models.dart';
import 'package:clinova/core/constants/app_constants.dart';
import 'package:clinova/core/routing/app_routes.dart';
import 'package:clinova/features/dashboard/doctor/doctor_dashboard_screen.dart';
import 'package:clinova/features/dashboard/doctor/screens/doctor_case_queue_screen.dart';
import 'package:clinova/features/dashboard/doctor/screens/doctor_profile_screen.dart';
import 'package:clinova/features/dashboard/doctor/widgets/doctor_side_drawer.dart';
import 'package:clinova/features/dashboard/patient/patient_dashboard_screen.dart';
import 'package:clinova/features/dashboard/patient/widgets/patient_app_bar.dart';

void main() {
  group('Doctor App Bar and Navigation Drawer Acceptance Tests', () {
    setUp(() async {
      await AuthConfig.authService.logout();
      await AuthConfig.authService.registerDoctor(
        name: 'Dr. Marcus Vance',
        email: 'dr.marcus@hospital.org',
        specialty: 'General Internal Medicine',
        license: 'CLIN-8821-MD',
        password: 'password123',
      );
    });

    tearDown(() async {
      await AuthConfig.authService.logout();
    });

    testWidgets('1. Doctor Dashboard app bar matches Patient Dashboard layout & geometry',
        (WidgetTester tester) async {
      const desktopSize = Size(1440, 900);
      tester.view.physicalSize = desktopSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.doctorDashboard,
        ),
      );
      await tester.pumpAndSettle();

      // App bar present as PatientAppBar
      final appBarFinder = find.byType(PatientAppBar);
      expect(appBarFinder, findsOneWidget);

      final appBarRect = tester.getRect(appBarFinder);
      expect(appBarRect.height, equals(80.0));
      expect(appBarRect.width, equals(desktopSize.width));

      // Centered Clinova heart-and-ECG logo symbol at horizontal center
      final symbolFinder = find.byWidgetPredicate((w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName == ClinovaConstants.symbolAsset);
      expect(symbolFinder, findsOneWidget);
      final symbolRect = tester.getRect(symbolFinder);
      final expectedCenterX = desktopSize.width / 2.0;
      expect((symbolRect.center.dx - expectedCenterX).abs(), lessThan(1.0));

      // Left: Hamburger menu icon button
      final menuFinder = find.byIcon(Icons.menu);
      expect(menuFinder, findsOneWidget);
      final menuRect = tester.getRect(menuFinder);
      expect(menuRect.left, lessThan(100.0));

      // Right: Notifications icon button with unread count "2"
      final notifFinder = find.byIcon(Icons.notifications_none_rounded);
      expect(notifFinder, findsOneWidget);
      final notifRect = tester.getRect(notifFinder);
      expect(notifRect.right, greaterThan(desktopSize.width - 100.0));
      expect(
        find.descendant(
          of: find.byType(PatientAppBar),
          matching: find.text("2"),
        ),
        findsOneWidget,
      );
    });

    testWidgets('2. Hamburger menu opens DoctorSideDrawer with correct styling and doctor identity',
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

      // Drawer is closed initially
      expect(find.byType(DoctorSideDrawer), findsNothing);

      // Tap hamburger menu
      final menuButton = find.byIcon(Icons.menu);
      await tester.tap(menuButton);
      await tester.pumpAndSettle();

      // Drawer is open
      expect(find.byType(DoctorSideDrawer), findsOneWidget);

      // Verify Drawer Width is 300px
      final drawerBox = tester.getRect(find.byType(DoctorSideDrawer));
      expect(drawerBox.width, equals(300.0));

      // Verify Doctor initials & credentials in Drawer
      expect(
        find.descendant(
          of: find.byType(DoctorSideDrawer),
          matching: find.text("MV"),
        ),
        findsOneWidget,
      );
      expect(find.text("Dr. Marcus Vance"), findsWidgets);
      expect(find.text("Physician Portal"), findsWidgets);

      // Verify Destinations: Doctor Dashboard, Case Queue, Doctor Profile, Notifications, Sign Out
      expect(find.text("Doctor Dashboard"), findsOneWidget);
      expect(find.text("Case Queue"), findsOneWidget);
      expect(find.text("Doctor Profile"), findsOneWidget);
      expect(find.text("Notifications"), findsOneWidget);
      expect(find.text("Sign Out"), findsOneWidget);

      // Verify Active pill on Doctor Dashboard destination
      expect(find.text("Active"), findsOneWidget);

      // Verify text Close button works
      final closeButton = find.text("Close");
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pumpAndSettle();

      // Drawer is closed
      expect(find.byType(DoctorSideDrawer), findsNothing);
    });

    testWidgets('3. Navigating to Case Queue closes drawer and opens Case Queue screen',
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

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Tap Case Queue
      final queueItem = find.text("Case Queue");
      await tester.tap(queueItem);
      await tester.pumpAndSettle();

      // Verify Case Queue Screen is displayed
      expect(find.byType(DoctorCaseQueueScreen), findsOneWidget);
      expect(find.text("Clinical Case Queue"), findsOneWidget);

      // Pop back to dashboard
      final backButton = find.byTooltip("Back to Dashboard");
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(DoctorDashboardScreen), findsOneWidget);
    });

    testWidgets('4. Navigating to Doctor Profile closes drawer and opens Doctor Profile screen',
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

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Tap Doctor Profile
      final profileItem = find.text("Doctor Profile");
      await tester.tap(profileItem);
      await tester.pumpAndSettle();

      // Verify Doctor Profile screen is displayed
      expect(find.byType(DoctorProfileScreen), findsOneWidget);
      expect(find.text("Doctor Profile"), findsOneWidget);
      expect(find.text("Clinical Credentials"), findsOneWidget);
      expect(find.text("LICENSED PHYSICIAN"), findsOneWidget);
      expect(find.text("CLIN-8821-MD"), findsOneWidget);

      // Pop back to dashboard
      final backButton = find.byTooltip("Back to Dashboard");
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.byType(DoctorDashboardScreen), findsOneWidget);
    });

    testWidgets('5. Notifications destination opens clinical notifications sheet',
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

      // Open drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Tap Notifications
      await tester.tap(find.text("Notifications"));
      await tester.pumpAndSettle();

      // Notifications sheet is visible
      expect(find.text("Clinical Notifications"), findsOneWidget);
      expect(find.text("New Case Received"), findsOneWidget);
    });

    testWidgets('6. Botanical leaf artwork is preserved and non-blocking on Doctor Dashboard',
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

      // Check leaf asset is rendered in Doctor Welcome Card
      final leavesFinder = find.byWidgetPredicate((w) =>
          w is Image &&
          w.image is AssetImage &&
          (w.image as AssetImage).assetName == ClinovaConstants.leavesAsset);
      expect(leavesFinder, findsWidgets);

      // Verify pending cases and metrics intact
      expect(find.text('Pending Reviews'), findsOneWidget);
      expect(find.text('Reviewed Cases'), findsOneWidget);
      expect(find.text('Draft Reviews'), findsOneWidget);
      expect(find.text('Assigned Patients'), findsOneWidget);
      expect(find.text('Pending Cases Requiring Attention'), findsOneWidget);
      expect(find.text('Recently Reviewed Cases'), findsOneWidget);
    });

    testWidgets('7. Narrow screen / mobile layout works cleanly without overflow',
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

      // App bar preferred height on mobile is 66px
      final appBarBox = tester.getRect(find.byType(PatientAppBar));
      expect(appBarBox.height, equals(66.0));

      // Hamburger menu button still works
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      expect(find.byType(DoctorSideDrawer), findsOneWidget);
      await tester.tap(find.text("Close"));
      await tester.pumpAndSettle();
      expect(find.byType(DoctorSideDrawer), findsNothing);
    });

    testWidgets('8. Patient Dashboard still operates normally (zero regressions)',
        (WidgetTester tester) async {
      await AuthConfig.authService.login(
        email: 'sarah.jenkins@example.com',
        password: 'securePassword123',
        role: UserRole.patient,
      );

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.patientDashboard,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PatientDashboardScreen), findsOneWidget);
      expect(find.byType(PatientAppBar), findsOneWidget);
      expect(find.text("Patient Profile"), findsOneWidget);
    });
  });
}
