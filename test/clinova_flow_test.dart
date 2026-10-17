import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clinova/features/welcome/welcome_screen.dart';
import 'package:clinova/shared/widgets/clinova_logo.dart';
import 'package:clinova/shared/widgets/neumorphic_role_card.dart';
import 'package:clinova/features/authentication/patient/patient_login_screen.dart';
import 'package:clinova/features/authentication/patient/patient_signup_screen.dart';
import 'package:clinova/features/authentication/doctor/doctor_signup_screen.dart';
import 'package:clinova/shared/widgets/neumorphic_button.dart';

void main() {
  group('Clinova Phase 1 UI Foundation Tests', () {
    testWidgets('WelcomeScreen displays role cards and privacy notice',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Verify Welcome Headline & Supporting text
      expect(find.text('Healthcare starts with a conversation.'), findsOneWidget);
      expect(
        find.text(
            'Share your concerns. Organize your medical history. Connect with your doctor.'),
        findsOneWidget,
      );

      // Verify Role selection cards
      expect(find.text("I’m a Patient"), findsOneWidget);
      expect(find.text("I’m a Doctor"), findsOneWidget);
      expect(
        find.text('Your health information deserves care and privacy.'),
        findsOneWidget,
      );
    });

    testWidgets('PatientLoginScreen validates empty email & password',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PatientLoginScreen(),
        ),
      );

      // Tap Sign In button with empty fields
      final submitFinder = find.text('Sign in to Clinova');
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pump();

      // Expect validation error messages
      expect(find.text('Please enter your email address'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);
    });

    testWidgets('DoctorSignupScreen validates license placeholder and terms',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: DoctorSignupScreen(),
        ),
      );

      final submitFinder = find.widgetWithText(NeumorphicButton, 'Register as a doctor');
      await tester.ensureVisible(submitFinder);
      await tester.tap(submitFinder);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your doctor name and title'), findsOneWidget);
      expect(find.text('Please enter your email address'), findsOneWidget);
      expect(find.text('Please enter your license number placeholder'), findsOneWidget);
    });

    testWidgets('WelcomeScreen renders ClinovaLogo and NeumorphicRoleCards',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomeScreen(),
        ),
      );

      // Verify ClinovaLogo is rendered
      expect(find.byType(ClinovaLogo), findsOneWidget);
      expect(find.byType(NeumorphicRoleCard), findsNWidgets(2));
    });

    testWidgets('PatientSignupScreen fits in 1366x768 desktop viewport without scrolling',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PatientSignupScreen(),
        ),
      );

      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: find.byType(SingleChildScrollView), matching: find.byType(Scrollable)).first,
      );
      expect(scrollable.position.maxScrollExtent, 0.0);
    });

    testWidgets('DoctorSignupScreen fits in 1366x768 desktop viewport without scrolling',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1366, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: DoctorSignupScreen(),
        ),
      );

      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: find.byType(SingleChildScrollView), matching: find.byType(Scrollable)).first,
      );
      expect(scrollable.position.maxScrollExtent, 0.0);
    });
  });
}
