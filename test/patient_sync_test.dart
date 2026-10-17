import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clinova/features/dashboard/patient/models/patient_nav_destination.dart';
import 'package:clinova/features/dashboard/patient/models/patient_profile_model.dart';
import 'package:clinova/features/dashboard/patient/screens/patient_anamnesis_screen.dart';
import 'package:clinova/features/dashboard/patient/screens/patient_general_info_screen.dart';
import 'package:clinova/features/dashboard/patient/services/patient_profile_repository.dart';
import 'package:clinova/features/dashboard/patient/views/patient_home_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await PatientProfileRepository.instance.init();
  });

  group('Patient Cross-Screen Data Synchronization Tests', () {
    test('1. Repository preserves Anamnesis medical history when saving Patient Profile', () async {
      // First, save Anamnesis medical history
      await PatientProfileRepository.instance.saveAnamnesis(
        conditions: "Hypertension Stage 1",
        allergies: "Penicillin, Latex",
        medications: "Amlodipine 5mg OD",
        pastMedicalHistory: "Childhood pneumonia in 2010",
        surgicalHistory: "Appendectomy in 2018",
        familyHistory: "Father has Type 2 Diabetes",
        lifestyle: "Sedentary, vegetarian diet",
        additionalNotes: "Follow up in 3 months",
      );

      final beforeProfile = PatientProfileRepository.instance.profile;
      expect(beforeProfile.conditions, "Hypertension Stage 1");
      expect(beforeProfile.allergies, "Penicillin, Latex");
      expect(beforeProfile.medications, "Amlodipine 5mg OD");
      expect(beforeProfile.pastMedicalHistory, "Childhood pneumonia in 2010");
      expect(beforeProfile.isAnamnesisCustomized, isTrue);

      // Now edit Personal Details on Patient Profile
      final updatedProfile = PatientProfileModel(
        fullName: "Vikram Malhotra",
        dateOfBirth: DateTime(1990, 3, 14),
        gender: "Male",
        bloodGroup: "B+",
        mobileNumber: "+91 98765 43210",
        email: "vikram.m@example.com",
        homeAddress: "Sector 14, Gurgaon, Haryana",
        heightCm: "182",
        weightKg: "78",
        emergencyContactName: "Anjali Malhotra",
        emergencyContactRelationship: "Spouse",
        emergencyContactPhone: "+91 98765 11111",
      );

      await PatientProfileRepository.instance.saveProfile(updatedProfile);

      final afterProfile = PatientProfileRepository.instance.profile;

      // Personal fields must be updated
      expect(afterProfile.fullName, "Vikram Malhotra");
      expect(afterProfile.email, "vikram.m@example.com");
      expect(afterProfile.mobileNumber, "+91 98765 43210");
      expect(afterProfile.heightCm, "182");
      expect(afterProfile.weightKg, "78");
      expect(afterProfile.bloodGroup, "B+");

      // Medical history must be 100% PRESERVED
      expect(afterProfile.conditions, "Hypertension Stage 1");
      expect(afterProfile.allergies, "Penicillin, Latex");
      expect(afterProfile.medications, "Amlodipine 5mg OD");
      expect(afterProfile.pastMedicalHistory, "Childhood pneumonia in 2010");
      expect(afterProfile.surgicalHistory, "Appendectomy in 2018");
      expect(afterProfile.familyHistory, "Father has Type 2 Diabetes");
      expect(afterProfile.lifestyle, "Sedentary, vegetarian diet");
      expect(afterProfile.additionalNotes, "Follow up in 3 months");
      expect(afterProfile.isAnamnesisCustomized, isTrue);
    });

    test('2. Repository preserves Personal details when saving Anamnesis', () async {
      // Save personal profile details first
      final personalProfile = PatientProfileModel(
        fullName: "Dr. Sunita Rao",
        dateOfBirth: DateTime(1985, 11, 28),
        gender: "Female",
        bloodGroup: "AB+",
        mobileNumber: "+91 99112 23344",
        email: "sunita.rao@example.com",
        homeAddress: "Jubilee Hills, Hyderabad",
        heightCm: "165",
        weightKg: "58",
        emergencyContactName: "Rajesh Rao",
        emergencyContactRelationship: "Spouse",
        emergencyContactPhone: "+91 99112 55555",
      );

      await PatientProfileRepository.instance.saveProfile(personalProfile);

      // Save Anamnesis medical history
      await PatientProfileRepository.instance.saveAnamnesis(
        conditions: "Migraine with aura",
        allergies: "Sulfa drugs",
        medications: "Sumatriptan PRN",
        pastMedicalHistory: "No prior chronic illnesses",
        surgicalHistory: "None",
        familyHistory: "Maternal migraine history",
        lifestyle: "Regular exercise, balanced diet",
        additionalNotes: "Avoid prolonged screen strain",
      );

      final profile = PatientProfileRepository.instance.profile;

      // Personal details must remain intact
      expect(profile.fullName, "Dr. Sunita Rao");
      expect(profile.dateOfBirth, DateTime(1985, 11, 28));
      expect(profile.gender, "Female");
      expect(profile.bloodGroup, "AB+");
      expect(profile.mobileNumber, "+91 99112 23344");
      expect(profile.email, "sunita.rao@example.com");
      expect(profile.homeAddress, "Jubilee Hills, Hyderabad");
      expect(profile.heightCm, "165");
      expect(profile.weightKg, "58");
      expect(profile.emergencyContactName, "Rajesh Rao");
      expect(profile.emergencyContactRelationship, "Spouse");
      expect(profile.emergencyContactPhone, "+91 99112 55555");

      // Medical history must be updated
      expect(profile.conditions, "Migraine with aura");
      expect(profile.allergies, "Sulfa drugs");
      expect(profile.medications, "Sumatriptan PRN");
      expect(profile.pastMedicalHistory, "No prior chronic illnesses");
    });

    testWidgets('3. General Information screen reactively reflects saved Patient Profile updates',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testProfile = PatientProfileModel(
        fullName: "Karan Johar",
        dateOfBirth: DateTime(1992, 7, 10),
        gender: "Male",
        bloodGroup: "O-",
        mobileNumber: "+91 94444 12345",
        email: "karan.j@example.com",
        homeAddress: "Bandra West, Mumbai",
        heightCm: "178",
        weightKg: "74",
        emergencyContactName: "Hiroo Johar",
        emergencyContactRelationship: "Mother",
        emergencyContactPhone: "+91 94444 99999",
      );

      await PatientProfileRepository.instance.saveProfile(testProfile);

      await tester.pumpWidget(
        const MaterialApp(
          home: PatientGeneralInfoScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check all synchronized fields on General Information screen
      expect(find.text("Karan Johar"), findsAtLeastNWidgets(1));
      expect(find.text("10 Jul 1992"), findsOneWidget);
      expect(find.text("Male"), findsOneWidget);
      expect(find.text("O-"), findsOneWidget);
      expect(find.text("+91 94444 12345"), findsOneWidget);
      expect(find.text("karan.j@example.com"), findsAtLeastNWidgets(1));
      expect(find.text("Bandra West, Mumbai"), findsOneWidget);
      expect(find.text("178 cm"), findsOneWidget);
      expect(find.text("74 kg"), findsOneWidget);
      expect(find.text("Hiroo Johar"), findsOneWidget);
      expect(find.text("Mother"), findsOneWidget);
      expect(find.text("+91 94444 99999"), findsOneWidget);
    });

    testWidgets('4. Patient Dashboard reactively reflects saved profile and anamnesis updates',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1400, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // 1. Initial pump of Dashboard
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PatientHomeView(
              onNavigate: (PatientNavDestination dest) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Default name check
      expect(find.text("Ananya Sharma"), findsAtLeastNWidgets(1));

      // 2. Update Profile via repository
      await PatientProfileRepository.instance.saveProfile(
        PatientProfileModel(
          fullName: "Aarav Singhania",
          dateOfBirth: DateTime(1998, 4, 25),
          gender: "Male",
          bloodGroup: "A+",
          mobileNumber: "+91 98111 22233",
          email: "aarav.s@example.com",
          homeAddress: "Connaught Place, New Delhi",
        ),
      );

      // 3. Update Anamnesis via repository
      await PatientProfileRepository.instance.saveAnamnesis(
        conditions: "Asthma Bronchiale",
        allergies: "Pollen allergy",
        medications: "Salbutamol inhaler",
        pastMedicalHistory: "Childhood allergy episodes",
        surgicalHistory: "None",
        familyHistory: "Atopic dermatitis in siblings",
        lifestyle: "Active runner",
        additionalNotes: "Carry inhaler during exercise",
      );

      // Pump to let streams update
      await tester.pumpAndSettle();

      // Check updated name on dashboard
      expect(find.text("Aarav Singhania"), findsAtLeastNWidgets(1));

      // Check updated General Information card summary on dashboard
      expect(find.text("25 Apr 1998"), findsOneWidget);
      expect(find.text("A+"), findsOneWidget);
      expect(find.text("+91 98111 22233"), findsOneWidget);

      // Check updated Anamnesis card summary on dashboard (Quick History replaced by Patient Care Notes)
      expect(find.text("Pollen allergy"), findsOneWidget);
      expect(find.text("Asthma Bronchiale"), findsOneWidget);
      expect(find.text("Salbutamol inhaler"), findsOneWidget);
    });

    testWidgets('5. Anamnesis screen reactively displays updated clinical records',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Save custom anamnesis data
      await PatientProfileRepository.instance.saveAnamnesis(
        conditions: "Type 2 Diabetes Mellitus",
        allergies: "No known food allergies",
        medications: "Metformin 500mg BD",
        pastMedicalHistory: "Diagnosed in 2021 during routine checkup",
        surgicalHistory: "No prior surgeries",
        familyHistory: "Mother has hypertension",
        lifestyle: "Low glycemic diet, daily 30m brisk walking",
        additionalNotes: "HbA1c target < 6.5%",
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: PatientAnamnesisScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify custom values are displayed in view mode
      expect(find.text("Type 2 Diabetes Mellitus"), findsOneWidget);
      expect(find.text("No known food allergies"), findsOneWidget);
      expect(find.text("Metformin 500mg BD"), findsOneWidget);
      expect(find.text("Diagnosed in 2021 during routine checkup"), findsOneWidget);
      expect(find.text("No prior surgeries"), findsOneWidget);
      expect(find.text("Mother has hypertension"), findsOneWidget);
      expect(find.text("Low glycemic diet, daily 30m brisk walking"), findsOneWidget);
      expect(find.text("HbA1c target < 6.5%"), findsOneWidget);

      // Verify banner reflects confirmed patient record
      expect(find.text("Clinical record saved"), findsOneWidget);
      expect(find.textContaining("Confirmed patient record"), findsOneWidget);
    });

    test('6. Persistence: Local storage correctly preserves and reloads all synchronized data',
        () async {
      // 1. Save both Profile and Anamnesis
      await PatientProfileRepository.instance.saveProfile(
        PatientProfileModel(
          fullName: "Meera Krishnan",
          dateOfBirth: DateTime(1988, 12, 5),
          gender: "Female",
          bloodGroup: "O+",
          mobileNumber: "+91 97777 88888",
          email: "meera.k@example.com",
          homeAddress: "Anna Nagar, Chennai",
          heightCm: "160",
          weightKg: "55",
          emergencyContactName: "Suresh Krishnan",
          emergencyContactRelationship: "Spouse",
          emergencyContactPhone: "+91 97777 00000",
        ),
      );

      await PatientProfileRepository.instance.saveAnamnesis(
        conditions: "Hypothyroidism",
        allergies: "Iodine contrast dye",
        medications: "Levothyroxine 50mcg OD fasting",
        pastMedicalHistory: "Thyroiditis in 2019",
        surgicalHistory: "None",
        familyHistory: "Maternal thyroid disorder",
        lifestyle: "Yoga practitioner",
        additionalNotes: "Annual TSH evaluation",
      );

      // 2. Simulate complete app restart by re-initializing repository
      await PatientProfileRepository.instance.init();

      final reloaded = PatientProfileRepository.instance.profile;

      // Personal Details reloaded
      expect(reloaded.fullName, "Meera Krishnan");
      expect(reloaded.dateOfBirth, DateTime(1988, 12, 5));
      expect(reloaded.gender, "Female");
      expect(reloaded.bloodGroup, "O+",);
      expect(reloaded.mobileNumber, "+91 97777 88888");
      expect(reloaded.email, "meera.k@example.com");
      expect(reloaded.homeAddress, "Anna Nagar, Chennai");
      expect(reloaded.heightCm, "160");
      expect(reloaded.weightKg, "55");
      expect(reloaded.emergencyContactName, "Suresh Krishnan");
      expect(reloaded.emergencyContactRelationship, "Spouse");
      expect(reloaded.emergencyContactPhone, "+91 97777 00000");

      // Anamnesis Medical History reloaded
      expect(reloaded.conditions, "Hypothyroidism");
      expect(reloaded.allergies, "Iodine contrast dye");
      expect(reloaded.medications, "Levothyroxine 50mcg OD fasting");
      expect(reloaded.pastMedicalHistory, "Thyroiditis in 2019");
      expect(reloaded.surgicalHistory, "None");
      expect(reloaded.familyHistory, "Maternal thyroid disorder");
      expect(reloaded.lifestyle, "Yoga practitioner");
      expect(reloaded.additionalNotes, "Annual TSH evaluation");
      expect(reloaded.isAnamnesisCustomized, isTrue);
    });
  });
}
