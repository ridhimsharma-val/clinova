import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/auth/auth_config.dart';
import '../../../../core/supabase/supabase_config.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../models/doctor_profile_model.dart';

/// Singleton repository managing Doctor Profile state and local persistence.
class DoctorProfileRepository {
  DoctorProfileRepository._() {
    _profile = _createDefaultProfile();
  }

  static final DoctorProfileRepository instance = DoctorProfileRepository._();

  static const String _storageKey = 'clinova_saved_doctor_profile';

  bool _hasSavedProfile = false;
  late DoctorProfileModel _profile;

  final StreamController<DoctorProfileModel> _profileStreamController =
      StreamController<DoctorProfileModel>.broadcast();

  Stream<DoctorProfileModel> get profileStream =>
      _profileStreamController.stream;

  DoctorProfileModel get profile {
    if (!_hasSavedProfile) {
      final session = AuthConfig.authService.currentSession;
      if (session != null &&
          (session.name != _profile.fullName ||
              session.email != _profile.email ||
              (session.specialty != null && session.specialty != _profile.specialty) ||
              (session.licenseNumber != null && session.licenseNumber != _profile.licenseNumber))) {
        _profile = _createDefaultProfile();
      }
    }
    return _profile;
  }

  bool get hasSavedProfile => _hasSavedProfile;

  static DoctorProfileModel _createDefaultProfile() {
    final session = AuthConfig.authService.currentSession;
    final name = session?.name.isNotEmpty == true ? session!.name : "Dr. Marcus Vance";
    final email = session?.email.isNotEmpty == true ? session!.email : "dr.marcus@hospital.org";
    final specialty = session?.specialty?.isNotEmpty == true ? session!.specialty! : "General Internal Medicine";
    final license = session?.licenseNumber?.isNotEmpty == true ? session!.licenseNumber! : "CLIN-8821-MD";

    return DoctorProfileModel(
      fullName: name,
      specialty: specialty,
      qualification: "MBBS, MD (Internal Medicine)",
      yearsOfExperience: "12",
      licenseNumber: license,
      isLicenseVerified: session?.isDemo == false,
      email: email,
      phone: "+1 (555) 019-2834",
      hospitalName: "Clinova Health Academic Medical Center",
      clinicAddress: "Building 4B, Health Science Blvd, Suite 210",
      dateOfBirth: DateTime(1982, 4, 18),
      doctorId: session?.id ?? "DOC-8821",
      accountEmail: email,
      practiceStatus: "Active Practitioner",
      photoBytes: null,
    );
  }

  /// Initialize and load saved profile from Supabase and SharedPreferences
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_storageKey);
      if (savedJson != null && savedJson.trim().isNotEmpty) {
        final decoded = jsonDecode(savedJson) as Map<String, dynamic>;
        _profile = DoctorProfileModel.fromJson(decoded);
        _hasSavedProfile = true;
      } else {
        _hasSavedProfile = false;
        _profile = _createDefaultProfile();
      }
      _profileStreamController.add(_profile);
    } catch (_) {
      _hasSavedProfile = false;
      _profile = _createDefaultProfile();
      _profileStreamController.add(_profile);
    }

    final client = SupabaseConfig.client;
    if (client != null) {
      client.auth.onAuthStateChange.listen((_) {
        fetchProfileFromSupabase();
      });
      await fetchProfileFromSupabase();
    }
  }

  /// Fetch doctor profile directly from Supabase
  Future<void> fetchProfileFromSupabase() async {
    final client = SupabaseConfig.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;

    try {
      final pRes = await client
          .from(SupabaseService.tableProfiles)
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final dpRes = await client
          .from(SupabaseService.tableDoctorProfiles)
          .select()
          .eq('doctor_id', user.id)
          .maybeSingle();

      if (pRes != null || dpRes != null) {
        _profile = _profile.copyWith(
          fullName: pRes?['full_name'] as String? ?? _profile.fullName,
          email: pRes?['email'] as String? ?? user.email ?? _profile.email,
          accountEmail: user.email ?? _profile.accountEmail,
          doctorId: user.id,
          specialty: dpRes?['specialty'] as String? ?? _profile.specialty,
          qualification: dpRes?['qualification'] as String? ?? _profile.qualification,
          yearsOfExperience: dpRes?['years_of_experience'] as String? ?? _profile.yearsOfExperience,
          licenseNumber: dpRes?['license_number'] as String? ?? _profile.licenseNumber,
          isLicenseVerified: dpRes?['is_license_verified'] as bool? ?? true,
          phone: dpRes?['phone'] as String? ?? _profile.phone,
          hospitalName: dpRes?['hospital_name'] as String? ?? _profile.hospitalName,
          clinicAddress: dpRes?['clinic_address'] as String? ?? _profile.clinicAddress,
          practiceStatus: dpRes?['practice_status'] as String? ?? 'Active Practitioner',
        );
        _hasSavedProfile = true;
        _profileStreamController.add(_profile);
      }
    } catch (e) {
      debugPrint('[DoctorProfileRepository] Error fetching doctor profile: $e');
    }
  }

  /// Save updated profile to memory and persistent storage
  Future<void> saveProfile(DoctorProfileModel updated) async {
    _profile = updated;
    _hasSavedProfile = true;
    _profileStreamController.add(_profile);

    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_profile.toJson());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {
      // Memory state is updated even if storage fails
    }

    final client = SupabaseConfig.client;
    final user = client?.auth.currentUser;
    if (client != null && user != null) {
      Future(() async {
        try {
          await client.from(SupabaseService.tableProfiles).update({
            'full_name': _profile.fullName,
          }).eq('id', user.id);

          await client.from(SupabaseService.tableDoctorProfiles).upsert({
            'doctor_id': user.id,
            'specialty': _profile.specialty,
            'qualification': _profile.qualification,
            'years_of_experience': _profile.yearsOfExperience,
            'license_number': _profile.licenseNumber,
            'phone': _profile.phone,
            'hospital_name': _profile.hospitalName,
            'clinic_address': _profile.clinicAddress,
            'practice_status': _profile.practiceStatus,
          });
        } catch (e) {
          debugPrint('[DoctorProfileRepository] Error syncing doctor profile to Supabase: $e');
        }
      });
    }
  }

  /// Update doctor photo directly
  Future<void> updatePhoto(Uint8List? bytes) async {
    if (bytes == null) {
      _profile = _profile.copyWith(clearPhoto: true);
    } else {
      _profile = _profile.copyWith(photoBytes: bytes);
    }
    _hasSavedProfile = true;
    _profileStreamController.add(_profile);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_profile.toJson()));
    } catch (_) {}
  }

  /// Reset to defaults (useful in tests or on user session changes)
  void resetToDefaults() {
    _profile = _createDefaultProfile();
    _hasSavedProfile = false;
    _profileStreamController.add(_profile);
  }
}
