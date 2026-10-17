import 'dart:convert';
import 'dart:typed_data';

/// Doctor Profile Data Model
class DoctorProfileModel {
  final String fullName;
  final String specialty;
  final String qualification;
  final String yearsOfExperience;
  final String licenseNumber;
  final bool isLicenseVerified;
  final String email;
  final String phone;
  final String hospitalName;
  final String clinicAddress;
  final DateTime? dateOfBirth;
  final String doctorId;
  final String accountEmail;
  final String practiceStatus;
  final Uint8List? photoBytes;

  const DoctorProfileModel({
    required this.fullName,
    required this.specialty,
    this.qualification = 'MBBS, MD (Internal Medicine)',
    this.yearsOfExperience = '12',
    this.licenseNumber = 'CLIN-8821-MD',
    this.isLicenseVerified = false,
    required this.email,
    this.phone = '+1 (555) 019-2834',
    this.hospitalName = 'St. Jude Clinical Medical Center',
    this.clinicAddress = 'Building 4B, Health Science Blvd, Suite 210',
    this.dateOfBirth,
    this.doctorId = 'CLIN-DOC-DEMO-01',
    required this.accountEmail,
    this.practiceStatus = 'Active Demo Practitioner',
    this.photoBytes,
  });

  DoctorProfileModel copyWith({
    String? fullName,
    String? specialty,
    String? qualification,
    String? yearsOfExperience,
    String? licenseNumber,
    bool? isLicenseVerified,
    String? email,
    String? phone,
    String? hospitalName,
    String? clinicAddress,
    DateTime? dateOfBirth,
    String? doctorId,
    String? accountEmail,
    String? practiceStatus,
    Uint8List? photoBytes,
    bool clearPhoto = false,
  }) {
    return DoctorProfileModel(
      fullName: fullName ?? this.fullName,
      specialty: specialty ?? this.specialty,
      qualification: qualification ?? this.qualification,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      isLicenseVerified: isLicenseVerified ?? this.isLicenseVerified,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      hospitalName: hospitalName ?? this.hospitalName,
      clinicAddress: clinicAddress ?? this.clinicAddress,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      doctorId: doctorId ?? this.doctorId,
      accountEmail: accountEmail ?? this.accountEmail,
      practiceStatus: practiceStatus ?? this.practiceStatus,
      photoBytes: clearPhoto ? null : (photoBytes ?? this.photoBytes),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'specialty': specialty,
      'qualification': qualification,
      'yearsOfExperience': yearsOfExperience,
      'licenseNumber': licenseNumber,
      'isLicenseVerified': isLicenseVerified,
      'email': email,
      'phone': phone,
      'hospitalName': hospitalName,
      'clinicAddress': clinicAddress,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'doctorId': doctorId,
      'accountEmail': accountEmail,
      'practiceStatus': practiceStatus,
      'photoBase64': photoBytes != null ? base64Encode(photoBytes!) : null,
    };
  }

  factory DoctorProfileModel.fromJson(Map<String, dynamic> json) {
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

    return DoctorProfileModel(
      fullName: json['fullName'] as String? ?? 'Dr. Marcus Vance',
      specialty: json['specialty'] as String? ?? 'General Internal Medicine',
      qualification: json['qualification'] as String? ?? 'MBBS, MD (Internal Medicine)',
      yearsOfExperience: json['yearsOfExperience'] as String? ?? '12',
      licenseNumber: json['licenseNumber'] as String? ?? 'CLIN-8821-MD',
      isLicenseVerified: json['isLicenseVerified'] as bool? ?? false,
      email: json['email'] as String? ?? 'dr.marcus@hospital.org',
      phone: json['phone'] as String? ?? '+1 (555) 019-2834',
      hospitalName: json['hospitalName'] as String? ?? 'St. Jude Clinical Medical Center',
      clinicAddress: json['clinicAddress'] as String? ?? 'Building 4B, Health Science Blvd, Suite 210',
      dateOfBirth: dob,
      doctorId: json['doctorId'] as String? ?? 'CLIN-DOC-DEMO-01',
      accountEmail: json['accountEmail'] as String? ?? (json['email'] as String? ?? 'dr.marcus@hospital.org'),
      practiceStatus: json['practiceStatus'] as String? ?? 'Active Demo Practitioner',
      photoBytes: photo,
    );
  }
}
