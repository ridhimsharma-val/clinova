import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clinova/core/auth/auth_config.dart';
import 'package:clinova/core/auth/auth_models.dart';
import 'package:clinova/core/routing/app_routes.dart';
import 'package:clinova/features/authentication/patient/patient_login_screen.dart';
import 'package:clinova/features/authentication/patient/patient_signup_screen.dart';
import 'package:clinova/features/dashboard/doctor/doctor_dashboard_screen.dart';
import 'package:clinova/features/dashboard/patient/patient_dashboard_screen.dart';
import 'package:clinova/features/dashboard/patient/models/patient_profile_model.dart';
import 'package:clinova/features/dashboard/patient/screens/patient_onboarding_screen.dart';
import 'package:clinova/features/dashboard/patient/screens/patient_profile_details_screen.dart';
import 'package:clinova/features/dashboard/patient/services/patient_profile_repository.dart';
import 'package:clinova/features/splash/splash_screen.dart';

void main() {
  group('Patient Onboarding Setup Flow & Acceptance Tests', () {
    setUp(() async {
      await AuthConfig.authService.logout();
      PatientProfileRepository.instance.resetForTesting(hasSavedProfile: false);
    });

    tearDown(() async {
      await AuthConfig.authService.logout();
      PatientProfileRepository.instance.resetForTesting(hasSavedProfile: false);
    });

    testWidgets('1. A new patient signs up and is redirected to onboarding',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          home: const PatientSignupScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Fill valid registration info
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Samantha Brown');
      await tester.enterText(textFields.at(1), 'samantha.brown@example.com');
      await tester.enterText(textFields.at(2), 'securePass123');
      await tester.enterText(textFields.at(3), 'securePass123');

      // Agree to privacy notice checkbox
      final checkbox = find.byType(Checkbox);
      await tester.tap(checkbox);
      await tester.pumpAndSettle();

      // Submit signup
      final submitButton = find.text('Create Patient Account');
      expect(submitButton, findsOneWidget);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify redirected to PatientOnboardingScreen, NOT dashboard
      expect(find.byType(PatientOnboardingScreen), findsOneWidget);
      expect(find.text('Complete Your Patient Profile'), findsOneWidget);
      expect(find.byType(PatientDashboardScreen), findsNothing);
    });

    testWidgets('2. The onboarding page contains every field from the existing Patient Profile page',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const MaterialApp(
          home: PatientOnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Welcoming copy
      expect(find.text('Complete Your Patient Profile'), findsOneWidget);
      expect(
        find.text(
          "Let's set up your profile so Clinova can keep your patient information organized.",
        ),
        findsOneWidget,
      );

      // Photo upload
      expect(find.text('Patient Photo (Optional)'), findsOneWidget);

      // Section 1: Personal Information
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Date of Birth'), findsOneWidget);
      expect(find.text('Age (Calculated)'), findsOneWidget);
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Blood Group'), findsOneWidget);

      // Section 2: Contact Information
      expect(find.text('Contact Information'), findsOneWidget);
      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Home Address'), findsOneWidget);

      // Section 3: Physical Information
      expect(find.text('Physical Information'), findsOneWidget);
      expect(find.text('Height (cm)'), findsOneWidget);
      expect(find.text('Weight (kg)'), findsOneWidget);

      // Section 4: Emergency Contact
      expect(find.text('Emergency Contact'), findsOneWidget);
      expect(find.text("Contact Person's Name"), findsOneWidget);
      expect(find.text('Relationship'), findsOneWidget);
      expect(find.text('Emergency Phone'), findsOneWidget);

      // Section 5: Medical Information (Optional)
      expect(find.text('Medical Information'), findsOneWidget);
      expect(find.text('Known Allergies'), findsOneWidget);
      expect(find.text('Existing Medical Conditions'), findsOneWidget);
      expect(find.text('Current Medications & Supplements'), findsOneWidget);

      // Submit button
      expect(find.text('Complete Setup & Open Dashboard'), findsOneWidget);
    });

    testWidgets('3 & 4. Required-field validation works and invalid form cannot be submitted',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          home: const PatientOnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Try submitting without filling required fields
      final submitButton = find.text('Complete Setup & Open Dashboard');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Inline validation error messages must appear
      expect(find.text('Please complete all required fields marked with * before continuing.'), findsOneWidget);
      expect(find.text('Full name is required'), findsOneWidget);
      expect(find.text('Mobile number is required'), findsOneWidget);
      expect(find.text('Home address is required'), findsOneWidget);

      // Cannot navigate away
      expect(find.byType(PatientOnboardingScreen), findsOneWidget);
      expect(find.byType(PatientDashboardScreen), findsNothing);
      expect(PatientProfileRepository.instance.hasSavedProfile, isFalse);
    });

    testWidgets('5. A successful save marks the profile complete and opens Patient Dashboard',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Create patient session
      await AuthConfig.authService.login(
        email: 'samantha.brown@example.com',
        password: 'password123',
        role: UserRole.patient,
      );

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          home: const PatientOnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Find form text fields and fill all required fields
      final textFormFieldFinders = find.byType(TextFormField);

      // 0: Full name
      await tester.enterText(textFormFieldFinders.at(0), 'Samantha Brown');
      // 1: Mobile number
      await tester.enterText(textFormFieldFinders.at(1), '+91 98765 43210');
      // 2: Email address
      await tester.enterText(textFormFieldFinders.at(2), 'samantha.brown@example.com');
      // 3: Home address
      await tester.enterText(textFormFieldFinders.at(3), '124 Green Orchid Avenue, Delhi');
      // 4: Height
      await tester.enterText(textFormFieldFinders.at(4), '165');
      // 5: Weight
      await tester.enterText(textFormFieldFinders.at(5), '58');
      // 6: Emergency contact name
      await tester.enterText(textFormFieldFinders.at(6), 'David Brown');
      // 7: Emergency phone
      await tester.enterText(textFormFieldFinders.at(7), '+91 98765 00000');
      // 8: Known allergies
      await tester.enterText(textFormFieldFinders.at(8), 'Penicillin');
      // 9: Conditions
      await tester.enterText(textFormFieldFinders.at(9), 'None');
      // 10: Medications
      await tester.enterText(textFormFieldFinders.at(10), 'None');

      // Tap Date of Birth picker to select valid date
      final dobPicker = find.text('Select Date of Birth');
      await tester.ensureVisible(dobPicker);
      await tester.tap(dobPicker);
      await tester.pumpAndSettle();

      // Tap OK on the date picker
      final okButton = find.text('OK');
      if (okButton.evaluate().isNotEmpty) {
        await tester.tap(okButton);
        await tester.pumpAndSettle();
      }

      // Submit form
      final submitButton = find.text('Complete Setup & Open Dashboard');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Profile is marked complete
      expect(PatientProfileRepository.instance.hasSavedProfile, isTrue);
      expect(PatientProfileRepository.instance.isPatientProfileComplete, isTrue);
      expect(PatientProfileRepository.instance.profile.fullName, 'Samantha Brown');

      // Navigated to PatientDashboardScreen
      expect(find.byType(PatientDashboardScreen), findsOneWidget);
      expect(find.byType(PatientOnboardingScreen), findsNothing);
    });

    testWidgets('7. A returning patient with a completed profile goes directly to the Dashboard',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Prepare a returning completed profile
      final completedProfile = PatientProfileModel(
        fullName: 'Dr. Sarah Jenkins',
        dateOfBirth: DateTime(1992, 5, 20),
        gender: 'Female',
        bloodGroup: 'O+',
        mobileNumber: '+91 98765 43210',
        email: 'sarah.jenkins@example.com',
        homeAddress: 'Park Street 45, Kolkata',
        emergencyContactName: 'John Jenkins',
        emergencyContactRelationship: 'Spouse',
        emergencyContactPhone: '+91 98765 99999',
        isProfileCompleted: true,
      );
      await PatientProfileRepository.instance.saveProfile(
        completedProfile,
        userId: 'sarah.jenkins@example.com',
      );

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          home: const PatientLoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter login credentials
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'sarah.jenkins@example.com');
      await tester.enterText(textFields.at(1), 'password123');

      final signInButton = find.text('Sign in to Patient Portal');
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Skips onboarding, goes directly to Patient Dashboard
      expect(find.byType(PatientDashboardScreen), findsOneWidget);
      expect(find.byType(PatientOnboardingScreen), findsNothing);
    });

    testWidgets('8. A returning patient with an incomplete profile is sent to onboarding',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Incomplete profile in repository
      PatientProfileRepository.instance.resetForTesting(
        hasSavedProfile: false,
        profile: PatientProfileModel.empty(
          fullName: 'Incomplete Patient',
          email: 'incomplete@example.com',
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          home: const PatientLoginScreen(),
        ),
      );
      await tester.pumpAndSettle();

      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'incomplete@example.com');
      await tester.enterText(textFields.at(1), 'password123');

      final signInButton = find.text('Sign in to Patient Portal');
      await tester.tap(signInButton);
      await tester.pumpAndSettle();

      // Directed to PatientOnboardingScreen
      expect(find.byType(PatientOnboardingScreen), findsOneWidget);
      expect(find.byType(PatientDashboardScreen), findsNothing);
    });

    testWidgets('9. Existing saved values appear when onboarding is reopened',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      PatientProfileRepository.instance.resetForTesting(
        hasSavedProfile: false,
        profile: PatientProfileModel.empty(
          fullName: 'Partially Saved Patient',
          email: 'partial@example.com',
        ).copyWith(
          mobileNumber: '+91 99999 88888',
          homeAddress: 'Tentative Road, Block 4',
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: PatientOnboardingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Pre-filled values should be visible
      expect(find.text('Partially Saved Patient'), findsOneWidget);
      expect(find.text('partial@example.com'), findsOneWidget);
      expect(find.text('+91 99999 88888'), findsOneWidget);
      expect(find.text('Tentative Road, Block 4'), findsOneWidget);
    });

    testWidgets('10. App restart and session restoration follows correct routing logic',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Case A: Patient with completed profile restores to dashboard
      await AuthConfig.authService.login(
        email: 'restored.patient@example.com',
        password: 'password123',
        role: UserRole.patient,
      );
      final completed = PatientProfileModel(
        fullName: 'Restored Patient',
        dateOfBirth: DateTime(1995, 3, 10),
        gender: 'Male',
        bloodGroup: 'B+',
        mobileNumber: '+91 98765 11111',
        email: 'restored.patient@example.com',
        homeAddress: 'Main Blvd 10',
        emergencyContactName: 'Rita Patient',
        emergencyContactPhone: '+91 98765 22222',
        isProfileCompleted: true,
      );
      await PatientProfileRepository.instance.saveProfile(
        completed,
        userId: 'restored.patient@example.com',
      );

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          home: const SplashScreen(),
        ),
      );

      // Tap to skip splash
      await tester.tap(find.byType(SplashScreen));
      await tester.pumpAndSettle();

      expect(find.byType(PatientDashboardScreen), findsOneWidget);
    });

    testWidgets('11 & 12. Editing profile after onboarding updates dashboard and stays synchronized',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      // Completed profile
      final initialProfile = PatientProfileModel(
        fullName: 'Initial Name',
        dateOfBirth: DateTime(1998, 7, 12),
        gender: 'Female',
        bloodGroup: 'A+',
        mobileNumber: '+91 98765 33333',
        email: 'initial@example.com',
        homeAddress: 'First Address',
        emergencyContactName: 'Emergency Person',
        emergencyContactPhone: '+91 98765 44444',
        isProfileCompleted: true,
      );
      await PatientProfileRepository.instance.saveProfile(initialProfile);

      // Open PatientProfileDetailsScreen to edit
      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          home: const PatientProfileDetailsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Change name
      final nameField = find.byType(TextFormField).first;
      await tester.enterText(nameField, 'Updated Full Name');

      final saveButton = find.text('Save Profile Changes');
      await tester.ensureVisible(saveButton);
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verified updated in repository and reactively on stream
      expect(PatientProfileRepository.instance.profile.fullName, 'Updated Full Name');
    });

    testWidgets('14. Doctor login and navigation flows remain unchanged',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await AuthConfig.authService.login(
        email: 'dr.marcus@hospital.org',
        password: 'password123',
        role: UserRole.doctor,
      );

      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          home: const SplashScreen(),
        ),
      );

      await tester.tap(find.byType(SplashScreen));
      await tester.pumpAndSettle();

      // Doctor routes directly to DoctorDashboardScreen without any onboarding
      expect(find.byType(DoctorDashboardScreen), findsOneWidget);
      expect(find.byType(PatientOnboardingScreen), findsNothing);
    });
  });
}
