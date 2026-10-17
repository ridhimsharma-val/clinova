import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clinova/features/dashboard/patient/screens/patient_general_info_screen.dart';
import 'package:clinova/features/dashboard/patient/models/patient_profile_model.dart';
import 'package:clinova/features/dashboard/patient/services/patient_profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('PatientGeneralInfoScreen displays read-only profile information without editable fields',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1728, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // Save a known profile in the repository
    final testProfile = PatientProfileModel(
      fullName: "Rohan Verma",
      dateOfBirth: DateTime(1995, 5, 20),
      gender: "Male",
      bloodGroup: "O+",
      mobileNumber: "+91 91234 56789",
      email: "rohan.verma@example.com",
      homeAddress: "Flat 402, Green Meadows, Pune, India",
      heightCm: "175",
      weightKg: "70",
      emergencyContactName: "Priya Verma",
      emergencyContactRelationship: "Spouse",
      emergencyContactPhone: "+91 99887 76655",
      allergies: "Peanuts, Dust mites",
      conditions: "Mild asthma",
      medications: "Inhaler as needed",
    );
    await PatientProfileRepository.instance.saveProfile(testProfile);

    await tester.pumpWidget(
      const MaterialApp(
        home: PatientGeneralInfoScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Title & Top Navigation
    expect(find.text("General Information"), findsOneWidget);
    expect(find.byTooltip("Back to Dashboard"), findsOneWidget);

    // 2. Personal Information
    expect(find.text("Rohan Verma"), findsAtLeastNWidgets(1));
    expect(find.text("rohan.verma@example.com"), findsAtLeastNWidgets(1));
    expect(find.text("20 May 1995"), findsOneWidget);
    expect(find.text("Male"), findsOneWidget);
    expect(find.text("O+"), findsOneWidget);
    expect(find.text("${testProfile.age} years"), findsOneWidget);

    // 3. Contact Information
    expect(find.text("+91 91234 56789"), findsOneWidget);
    expect(find.text("Flat 402, Green Meadows, Pune, India"), findsOneWidget);

    // 4. Physical Information
    expect(find.text("175 cm"), findsOneWidget);
    expect(find.text("70 kg"), findsOneWidget);

    // 5. Emergency Contact
    expect(find.text("Priya Verma"), findsOneWidget);
    expect(find.text("Spouse"), findsOneWidget);
    expect(find.text("Phone Number".toUpperCase()), findsOneWidget);

    // 6. Medical Overview is REMOVED
    expect(find.text("Medical Overview"), findsNothing);
    expect(find.text("Known Allergies"), findsNothing);
    expect(find.text("Existing Conditions"), findsNothing);
    expect(find.text("Current Medications"), findsNothing);

    // 7. Strictly READ-ONLY check: No TextFormField, TextField, or action buttons
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.widgetWithText(ElevatedButton, "Save"), findsNothing);
    expect(find.widgetWithText(ElevatedButton, "Edit"), findsNothing);
    expect(find.widgetWithText(TextButton, "Save"), findsNothing);
    expect(find.widgetWithText(TextButton, "Edit"), findsNothing);

    // 8. Test live reactivity: changing profile in repository updates General Information page
    final updatedProfile = testProfile.copyWith(
      fullName: "Rohan V. Kumar",
      bloodGroup: "AB+",
    );
    await PatientProfileRepository.instance.saveProfile(updatedProfile);
    await tester.pumpAndSettle();

    expect(find.text("Rohan V. Kumar"), findsAtLeastNWidgets(1));
    expect(find.text("AB+"), findsOneWidget);
  });
}
