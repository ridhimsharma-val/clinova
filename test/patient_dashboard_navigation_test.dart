import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clinova/core/auth/auth_config.dart';
import 'package:clinova/core/auth/auth_models.dart';
import 'package:clinova/core/constants/app_constants.dart';
import 'package:clinova/core/routing/app_routes.dart';
import 'package:clinova/features/dashboard/patient/screens/case_intake_screen.dart';
import 'package:clinova/features/dashboard/patient/screens/patient_profile_details_screen.dart';
import 'package:clinova/features/dashboard/patient/screens/patient_general_info_screen.dart';
import 'package:clinova/features/dashboard/patient/screens/patient_anamnesis_screen.dart';
import 'package:clinova/features/dashboard/patient/widgets/patient_app_bar.dart';
import 'package:clinova/features/dashboard/patient/widgets/patient_bottom_nav_bar.dart';
import 'package:clinova/features/dashboard/patient/widgets/patient_notifications_sheet.dart';
import 'package:clinova/features/dashboard/patient/widgets/patient_side_drawer.dart';

void main() {
  group('Patient Dashboard Final Refinement Tests (Restored Original Sizing)', () {
    setUp(() async {
      await AuthConfig.authService.login(
        email: 'test.patient@example.com',
        password: 'password123',
        role: UserRole.patient,
      );
    });

    tearDown(() async {
      await AuthConfig.authService.logout();
    });

    testWidgets('App Bar has exact three-element layout: hamburger icon, centered symbol, notification bell',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.patientDashboard,
        ),
      );
      await tester.pumpAndSettle();

      // App bar widget is present
      expect(find.byType(PatientAppBar), findsOneWidget);

      // Left: Hamburger menu icon button
      expect(find.byIcon(Icons.menu), findsOneWidget);

      // Right: Notification bell icon button
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

      // Unread notification count badge "2"
      expect(find.text("2"), findsOneWidget);

      // NO text labels "MENU" or "Notifications" in app bar
      expect(find.text('MENU'), findsNothing);
      expect(find.text('Notifications'), findsNothing);

      // Centered standalone logo asset without "Clinova" text wordmark in app bar
      final images = tester.widgetList<Image>(find.byType(Image));
      final symbolImage = images.where((img) {
        final imageProvider = img.image;
        return imageProvider is AssetImage &&
            imageProvider.assetName == ClinovaConstants.symbolAsset;
      });
      expect(symbolImage, isNotEmpty);
      expect(find.text('Clinova'), findsNothing);
    });

    testWidgets('Start a New Case card has NO supporting sentence',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.patientDashboard,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Start a New Case'), findsOneWidget);
      expect(find.text('Start case'), findsOneWidget);
      expect(
        find.textContaining('Tell us about your health concerns'),
        findsNothing,
      );
    });

    testWidgets('Recent Cases shows exactly two records, third record is removed',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.patientDashboard,
        ),
      );
      await tester.pumpAndSettle();

      // Recent Cases heading and action
      expect(find.text('Recent Cases'), findsOneWidget);
      expect(find.text('View all'), findsOneWidget);

      // Retained 2 records
      expect(find.text('Persistent Cough & Low Fever'), findsOneWidget);
      expect(find.text('Right Knee Strain after Exercise'), findsOneWidget);

      // Removed 3rd record
      expect(find.text('Annual Wellness Intake'), findsNothing);
    });

    testWidgets('Desktop layout displays all 6 dashboard areas with original comfortable sizing',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.patientDashboard,
        ),
      );
      await tester.pumpAndSettle();

      // 1. App bar
      expect(find.byType(PatientAppBar), findsOneWidget);
      // 2. Demo banner
      expect(find.text('DEMO'), findsWidgets);
      // 3. Top summary cards (3 cards)
      expect(find.text('Patient Profile'), findsOneWidget);
      expect(find.text('General Information'), findsOneWidget);
      expect(find.text('Anamnesis'), findsOneWidget);
      // 4. Start a New Case
      expect(find.text('Start a New Case'), findsOneWidget);
      // 5. Recent Cases (both records)
      expect(find.text('Persistent Cough & Low Fever'), findsOneWidget);
      expect(find.text('Right Knee Strain after Exercise'), findsOneWidget);
      // 6. Patient Care Notes
      expect(find.text('Patient Care Notes'), findsOneWidget);
      expect(find.text('Important observations and follow-ups'), findsOneWidget);
    });

    testWidgets('Tapping hamburger icon opens overlay drawer and can be closed',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.patientDashboard,
        ),
      );
      await tester.pumpAndSettle();

      // Drawer is closed initially
      expect(find.byType(PatientSideDrawer), findsNothing);

      // Tap hamburger menu icon
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();

      // Drawer is now open as an overlay
      expect(find.byType(PatientSideDrawer), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('My Cases'), findsOneWidget);
      expect(find.text('AI Health Assistant'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);

      // Close drawer using Close text button
      final closeBtn = find.text('Close');
      expect(closeBtn, findsOneWidget);
      await tester.tap(closeBtn);
      await tester.pumpAndSettle();

      // Drawer is closed again
      expect(find.byType(PatientSideDrawer), findsNothing);
    });

    testWidgets('Tapping notification bell button opens notifications sheet',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.patientDashboard,
        ),
      );
      await tester.pumpAndSettle();

      final notifFinder = find.byKey(const Key('patient_notifications_button'));
      await tester.tap(notifFinder);
      await tester.pumpAndSettle();

      // Notifications sheet is visible
      expect(find.byType(PatientNotificationsSheet), findsOneWidget);
      expect(find.text('System Connected'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('Tapping "Start case" button opens CaseIntakeScreen route',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.patientDashboard,
        ),
      );
      await tester.pumpAndSettle();

      final startCaseButton = find.text('Start case');
      expect(startCaseButton, findsOneWidget);
      await tester.tap(startCaseButton);
      await tester.pumpAndSettle();

      // Navigated to CaseIntakeScreen
      expect(find.byType(CaseIntakeScreen), findsOneWidget);
      expect(find.text('New Case'), findsOneWidget);
    });

    testWidgets('Tapping summary cards opens their respective placeholder screens',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.patientDashboard,
        ),
      );
      await tester.pumpAndSettle();

      // 1. Patient Profile
      await tester.tap(find.text('Patient Profile'));
      await tester.pumpAndSettle();
      expect(find.byType(PatientProfileDetailsScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Back to Dashboard'));
      await tester.pumpAndSettle();

      // 2. General Information
      await tester.tap(find.text('General Information'));
      await tester.pumpAndSettle();
      expect(find.byType(PatientGeneralInfoScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Back to Dashboard'));
      await tester.pumpAndSettle();

      // 3. Anamnesis
      await tester.tap(find.text('Anamnesis'));
      await tester.pumpAndSettle();
      expect(find.byType(PatientAnamnesisScreen), findsOneWidget);
    });

    testWidgets('Mobile layout displays bottom nav with 4 destinations and hidden drawer',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          initialRoute: AppRoutes.patientDashboard,
        ),
      );
      await tester.pumpAndSettle();

      // Bottom nav is visible on mobile
      expect(find.byType(PatientBottomNavBar), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('My Cases'), findsOneWidget);
      expect(find.text('AI Assistant'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Drawer is closed initially
      expect(find.byType(PatientSideDrawer), findsNothing);

      // App bar has hamburger icon and notification bell
      expect(find.byType(PatientAppBar), findsOneWidget);
      expect(find.byIcon(Icons.menu), findsOneWidget);
      expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);

      // Summary cards and Start a New Case are visible
      expect(find.text('Patient Profile'), findsOneWidget);
      expect(find.text('Start a New Case'), findsOneWidget);
      expect(find.text('Recent Cases'), findsOneWidget);
    });
  });
}
