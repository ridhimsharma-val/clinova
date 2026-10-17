import 'dart:convert';
import 'dart:typed_data';

/// Patient Profile Data Model
class PatientProfileModel {
  final String fullName;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? bloodGroup;
  final String mobileNumber;
  final String email;
  final String homeAddress;
  final String? heightCm;
  final String? weightKg;
  final String? emergencyContactName;
  final String? emergencyContactRelationship;
  final String? emergencyContactPhone;
  final String? allergies;
  final String? conditions;
  final String? medications;
  final String? pastMedicalHistory;
  final String? surgicalHistory;
  final String? familyHistory;
  final String? lifestyle;
  final String? additionalNotes;
  final bool isAnamnesisCustomized;
  final Uint8List? photoBytes;
  final bool isProfileCompleted;

  const PatientProfileModel({
    required this.fullName,
    this.dateOfBirth,
    this.gender,
    this.bloodGroup,
    required this.mobileNumber,
    required this.email,
    required this.homeAddress,
    this.heightCm,
    this.weightKg,
    this.emergencyContactName,
    this.emergencyContactRelationship,
    this.emergencyContactPhone,
    this.allergies,
    this.conditions,
    this.medications,
    this.pastMedicalHistory,
    this.surgicalHistory,
    this.familyHistory,
    this.lifestyle,
    this.additionalNotes,
    this.isAnamnesisCustomized = false,
    this.photoBytes,
    this.isProfileCompleted = false,
  });

  /// Factory constructor for a newly registered / un-onboarded patient
  factory PatientProfileModel.empty({String? fullName, String? email}) {
    return PatientProfileModel(
      fullName: fullName ?? '',
      dateOfBirth: null,
      gender: null,
      bloodGroup: null,
      mobileNumber: '',
      email: email ?? '',
      homeAddress: '',
      heightCm: null,
      weightKg: null,
      emergencyContactName: null,
      emergencyContactRelationship: 'Father',
      emergencyContactPhone: null,
      allergies: null,
      conditions: null,
      medications: null,
      pastMedicalHistory: null,
      surgicalHistory: null,
      familyHistory: null,
      lifestyle: null,
      additionalNotes: null,
      isAnamnesisCustomized: false,
      photoBytes: null,
      isProfileCompleted: false,
    );
  }

  /// Whether all mandatory patient onboarding fields have been completed
  bool get isProfileComplete {
    return isProfileCompleted ||
        (fullName.trim().isNotEmpty &&
            dateOfBirth != null &&
            (gender != null && gender!.trim().isNotEmpty) &&
            (mobileNumber.trim().isNotEmpty && mobileNumber.trim().length >= 8) &&
            email.trim().isNotEmpty &&
            homeAddress.trim().isNotEmpty &&
            (emergencyContactName != null &&
                emergencyContactName!.trim().isNotEmpty) &&
            (emergencyContactPhone != null &&
                emergencyContactPhone!.trim().isNotEmpty));
  }

  /// Calculates age accurately from Date of Birth
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age >= 0 ? age : 0;
  }

  PatientProfileModel copyWith({
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodGroup,
    String? mobileNumber,
    String? email,
    String? homeAddress,
    String? heightCm,
    String? weightKg,
    String? emergencyContactName,
    String? emergencyContactRelationship,
    String? emergencyContactPhone,
    String? allergies,
    String? conditions,
    String? medications,
    String? pastMedicalHistory,
    String? surgicalHistory,
    String? familyHistory,
    String? lifestyle,
    String? additionalNotes,
    bool? isAnamnesisCustomized,
    Uint8List? photoBytes,
    bool clearPhoto = false,
    bool? isProfileCompleted,
  }) {
    return PatientProfileModel(
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      homeAddress: homeAddress ?? this.homeAddress,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactRelationship: emergencyContactRelationship ?? this.emergencyContactRelationship,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      allergies: allergies ?? this.allergies,
      conditions: conditions ?? this.conditions,
      medications: medications ?? this.medications,
      pastMedicalHistory: pastMedicalHistory ?? this.pastMedicalHistory,
      surgicalHistory: surgicalHistory ?? this.surgicalHistory,
      familyHistory: familyHistory ?? this.familyHistory,
      lifestyle: lifestyle ?? this.lifestyle,
      additionalNotes: additionalNotes ?? this.additionalNotes,
      isAnamnesisCustomized: isAnamnesisCustomized ?? this.isAnamnesisCustomized,
      photoBytes: clearPhoto ? null : (photoBytes ?? this.photoBytes),
      isProfileCompleted: isProfileCompleted ?? this.isProfileCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'bloodGroup': bloodGroup,
      'mobileNumber': mobileNumber,
      'email': email,
      'homeAddress': homeAddress,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'emergencyContactName': emergencyContactName,
      'emergencyContactRelationship': emergencyContactRelationship,
      'emergencyContactPhone': emergencyContactPhone,
      'allergies': allergies,
      'conditions': conditions,
      'medications': medications,
      'pastMedicalHistory': pastMedicalHistory,
      'surgicalHistory': surgicalHistory,
      'familyHistory': familyHistory,
      'lifestyle': lifestyle,
      'additionalNotes': additionalNotes,
      'isAnamnesisCustomized': isAnamnesisCustomized,
      'photoBase64': photoBytes != null ? base64Encode(photoBytes!) : null,
      'isProfileCompleted': isProfileCompleted,
    };
  }

  factory PatientProfileModel.fromJson(Map<String, dynamic> json) {
    Uint8List? photo;
    if (json['photoBase64'] != null && (json['photoBase64'] as String).isNotEmpty) {
      try {
        photo = base64Decode(json['photoBase64'] as String);
      } catch (_) {
        photo = null;
      }
    }
    DateTime? dob;
    if (json['dateOfBirth'] != null) {
      try {
        dob = DateTime.parse(json['dateOfBirth'] as String);
      } catch (_) {
        dob = null;
      }
    }

    return PatientProfileModel(
      fullName: json['fullName'] as String? ?? '',
      dateOfBirth: dob,
      gender: json['gender'] as String?,
      bloodGroup: json['bloodGroup'] as String?,
      mobileNumber: json['mobileNumber'] as String? ?? '',
      email: json['email'] as String? ?? '',
      homeAddress: json['homeAddress'] as String? ?? '',
      heightCm: json['heightCm'] as String?,
      weightKg: json['weightKg'] as String?,
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactRelationship: json['emergencyContactRelationship'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
      allergies: json['allergies'] as String?,
      conditions: json['conditions'] as String?,
      medications: json['medications'] as String?,
      pastMedicalHistory: json['pastMedicalHistory'] as String?,
      surgicalHistory: json['surgicalHistory'] as String?,
      familyHistory: json['familyHistory'] as String?,
      lifestyle: json['lifestyle'] as String?,
      additionalNotes: json['additionalNotes'] as String?,
      isAnamnesisCustomized: json['isAnamnesisCustomized'] as bool? ?? false,
      photoBytes: photo,
      isProfileCompleted: json['isProfileCompleted'] as bool? ?? false,
    );
  }
}
