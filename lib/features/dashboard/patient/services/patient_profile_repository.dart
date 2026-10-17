import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/auth/auth_config.dart';
import '../../../../core/supabase/supabase_config.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../models/patient_profile_model.dart';

/// Singleton repository managing Patient Profile state and local persistence.
class PatientProfileRepository {
  PatientProfileRepository._() {
    _profile = _createDefaultDemoProfile();
  }

  static final PatientProfileRepository instance =
      PatientProfileRepository._();

  static const String _storageKey = 'clinova_saved_patient_profile';

  bool _hasSavedProfile = false;
  late PatientProfileModel _profile;

  final StreamController<PatientProfileModel> _profileStreamController =
      StreamController<PatientProfileModel>.broadcast();

  Stream<PatientProfileModel> get profileStream =>
      _profileStreamController.stream;

  PatientProfileModel get profile => _profile;
  bool get hasSavedProfile => _hasSavedProfile;

  /// Returns true if the active patient has completed their profile setup
  bool get isPatientProfileComplete => _hasSavedProfile && _profile.isProfileComplete;

  static PatientProfileModel _createDefaultDemoProfile() {
    return PatientProfileModel(
      fullName: "Ananya Sharma",
      dateOfBirth: DateTime(2000, 8, 15),
      gender: "Female",
      bloodGroup: "B+",
      mobileNumber: "+91 98765 43210",
      email: "ananya.sharma@example.com",
      homeAddress: "Sector 62, Noida, Uttar Pradesh, India",
      heightCm: "158",
      weightKg: "54",
      emergencyContactName: "Rahul Sharma",
      emergencyContactRelationship: "Father",
      emergencyContactPhone: "+91 98765 12340",
      allergies: "No known allergies reported",
      conditions: "No known chronic conditions reported",
      medications: "No regular medications reported",
      pastMedicalHistory: "No significant past medical history reported",
      surgicalHistory: "No previous surgeries reported",
      familyHistory: "Sample entry — family history needs confirmation",
      lifestyle: "Sample entry — lifestyle details need confirmation",
      additionalNotes: "No additional notes provided",
      isAnamnesisCustomized: false,
      photoBytes: null,
      isProfileCompleted: true,
    );
  }

  /// Reset repository state (useful for unit and widget test isolation)
  void resetForTesting({bool hasSavedProfile = false, PatientProfileModel? profile}) {
    _hasSavedProfile = hasSavedProfile;
    _profile = profile ?? (hasSavedProfile ? _createDefaultDemoProfile() : PatientProfileModel.empty());
    _profileStreamController.add(_profile);
  }

  /// Load persisted profile from local storage if available
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_storageKey);
      if (savedJson != null && savedJson.trim().isNotEmpty) {
        final decoded = jsonDecode(savedJson) as Map<String, dynamic>;
        _profile = PatientProfileModel.fromJson(decoded);
        _hasSavedProfile = _profile.isProfileComplete;
      } else {
        _hasSavedProfile = false;
        _profile = _createDefaultDemoProfile();
      }

      // Check if separate anamnesis data was previously stored and merge
      final anamnesisRaw = prefs.getString('clinova_saved_anamnesis_data');
      if (anamnesisRaw != null && anamnesisRaw.trim().isNotEmpty) {
        try {
          final anamnesisMap = jsonDecode(anamnesisRaw) as Map<String, dynamic>;
          _profile = _profile.copyWith(
            conditions: anamnesisMap['conditions'] as String? ?? _profile.conditions,
            allergies: anamnesisMap['allergies'] as String? ?? _profile.allergies,
            medications: anamnesisMap['medications'] as String? ?? _profile.medications,
            pastMedicalHistory:
                anamnesisMap['pastMedicalHistory'] as String? ?? _profile.pastMedicalHistory,
            surgicalHistory:
                anamnesisMap['surgicalHistory'] as String? ?? _profile.surgicalHistory,
            familyHistory:
                anamnesisMap['familyHistory'] as String? ?? _profile.familyHistory,
            lifestyle:
                anamnesisMap['lifestyle'] as String? ?? _profile.lifestyle,
            additionalNotes:
                anamnesisMap['additionalNotes'] as String? ?? _profile.additionalNotes,
            isAnamnesisCustomized: true,
          );
        } catch (_) {}
      }

      _profileStreamController.add(_profile);
    } catch (_) {
      _hasSavedProfile = false;
      _profile = _createDefaultDemoProfile();
    }

    final client = SupabaseConfig.client;
    if (client != null) {
      client.auth.onAuthStateChange.listen((_) {
        fetchProfileFromSupabase();
      });
      await fetchProfileFromSupabase();
    }
  }

  /// Prepares or loads profile state tailored for the currently signed-in user session
  Future<void> loadForUser(dynamic session) async {
    if (session == null) return;
    final String userKey = (session.id != null && session.id.toString().isNotEmpty)
        ? session.id.toString()
        : (session.email?.toString() ?? 'patient');
    final prefs = await SharedPreferences.getInstance();

    // 1. Check user-scoped local storage
    final completedFlag = prefs.getBool('clinova_profile_completed_$userKey');
    final userJson = prefs.getString('${_storageKey}_$userKey');

    if (userJson != null && userJson.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(userJson) as Map<String, dynamic>;
        _profile = PatientProfileModel.fromJson(decoded);
        _hasSavedProfile = completedFlag ?? _profile.isProfileComplete;
        _profileStreamController.add(_profile);
        return;
      } catch (_) {}
    }

    // 2. If live Supabase client is configured, check database
    final client = SupabaseConfig.client;
    final bool isDemo = session.isDemo == true;
    if (client != null && !isDemo) {
      await fetchProfileFromSupabase();
      if (_hasSavedProfile && _profile.isProfileComplete) {
        return;
      }
    }

    // 3. New or incomplete patient: initialize fresh profile prefilled with registration/session info
    final sName = session.name as String? ?? '';
    final sEmail = session.email as String? ?? '';
    _hasSavedProfile = false;
    _profile = PatientProfileModel.empty(
      fullName: sName.isNotEmpty && !sName.toLowerCase().contains('patient') ? sName : '',
      email: sEmail,
    );
    _profileStreamController.add(_profile);
  }

  /// Fetches patient profile and medical anamnesis directly from Supabase
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

      final ppRes = await client
          .from(SupabaseService.tablePatientProfiles)
          .select()
          .eq('patient_id', user.id)
          .maybeSingle();

      if (pRes != null || ppRes != null) {
        final dobStr = ppRes?['date_of_birth'] as String?;
        DateTime? dob;
        if (dobStr != null) {
          dob = DateTime.tryParse(dobStr);
        }

        final address = ppRes?['home_address'] as String?;
        final mobile = ppRes?['mobile_number'] as String?;
        final emergName = ppRes?['emergency_contact_name'] as String?;
        final emergPhone = ppRes?['emergency_contact_phone'] as String?;
        final gender = ppRes?['gender'] as String?;

        final isCompleteInDb = dob != null &&
            address != null && address.trim().isNotEmpty &&
            mobile != null && mobile.trim().isNotEmpty &&
            emergName != null && emergName.trim().isNotEmpty &&
            emergPhone != null && emergPhone.trim().isNotEmpty &&
            gender != null && gender.trim().isNotEmpty;

        _profile = _profile.copyWith(
          fullName: pRes?['full_name'] as String? ?? _profile.fullName,
          email: pRes?['email'] as String? ?? user.email ?? _profile.email,
          dateOfBirth: dob ?? _profile.dateOfBirth,
          gender: gender ?? _profile.gender,
          bloodGroup: ppRes?['blood_group'] as String? ?? _profile.bloodGroup,
          mobileNumber: mobile ?? _profile.mobileNumber,
          homeAddress: address ?? _profile.homeAddress,
          heightCm: ppRes?['height_cm'] as String? ?? _profile.heightCm,
          weightKg: ppRes?['weight_kg'] as String? ?? _profile.weightKg,
          emergencyContactName: emergName ?? _profile.emergencyContactName,
          emergencyContactRelationship: ppRes?['emergency_contact_relationship'] as String? ?? _profile.emergencyContactRelationship,
          emergencyContactPhone: emergPhone ?? _profile.emergencyContactPhone,
          allergies: ppRes?['allergies'] as String? ?? _profile.allergies,
          conditions: ppRes?['conditions'] as String? ?? _profile.conditions,
          medications: ppRes?['medications'] as String? ?? _profile.medications,
          pastMedicalHistory: ppRes?['past_medical_history'] as String? ?? _profile.pastMedicalHistory,
          surgicalHistory: ppRes?['surgical_history'] as String? ?? _profile.surgicalHistory,
          familyHistory: ppRes?['family_history'] as String? ?? _profile.familyHistory,
          lifestyle: ppRes?['lifestyle'] as String? ?? _profile.lifestyle,
          additionalNotes: ppRes?['additional_notes'] as String? ?? _profile.additionalNotes,
          isAnamnesisCustomized: ppRes?['is_anamnesis_customized'] as bool? ?? false,
          isProfileCompleted: isCompleteInDb,
        );
        _hasSavedProfile = isCompleteInDb;
        _profileStreamController.add(_profile);
      }
    } catch (e) {
      debugPrint('[PatientProfileRepository] Error fetching profile from Supabase: $e');
    }
  }

  /// Save profile to memory and persist to local storage (preserves medical history)
  Future<bool> saveProfile(PatientProfileModel updatedProfile, {String? userId}) async {
    _profile = _profile.copyWith(
      fullName: updatedProfile.fullName,
      dateOfBirth: updatedProfile.dateOfBirth,
      gender: updatedProfile.gender,
      bloodGroup: updatedProfile.bloodGroup,
      mobileNumber: updatedProfile.mobileNumber,
      email: updatedProfile.email,
      homeAddress: updatedProfile.homeAddress,
      heightCm: updatedProfile.heightCm,
      weightKg: updatedProfile.weightKg,
      emergencyContactName: updatedProfile.emergencyContactName,
      emergencyContactRelationship: updatedProfile.emergencyContactRelationship,
      emergencyContactPhone: updatedProfile.emergencyContactPhone,
      photoBytes: updatedProfile.photoBytes,
      allergies: (updatedProfile.allergies != null && updatedProfile.allergies!.trim().isNotEmpty)
          ? updatedProfile.allergies
          : _profile.allergies,
      conditions: (updatedProfile.conditions != null && updatedProfile.conditions!.trim().isNotEmpty)
          ? updatedProfile.conditions
          : _profile.conditions,
      medications: (updatedProfile.medications != null && updatedProfile.medications!.trim().isNotEmpty)
          ? updatedProfile.medications
          : _profile.medications,
      isProfileCompleted: true,
    );
    _hasSavedProfile = true;
    _profileStreamController.add(_profile);

    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_profile.toJson());
      await prefs.setString(_storageKey, encoded);

      final activeUserId = userId ??
          SupabaseConfig.client?.auth.currentUser?.id ??
          AuthConfig.authService.currentSession?.id ??
          AuthConfig.authService.currentSession?.email;

      if (activeUserId != null && activeUserId.isNotEmpty) {
        await prefs.setString('${_storageKey}_$activeUserId', encoded);
        await prefs.setBool('clinova_profile_completed_$activeUserId', true);
      }

      // Also keep clinova_saved_anamnesis_data in sync
      final anamnesisMap = {
        'conditions': _profile.conditions ?? '',
        'allergies': _profile.allergies ?? '',
        'medications': _profile.medications ?? '',
        'pastMedicalHistory': _profile.pastMedicalHistory ?? '',
        'surgicalHistory': _profile.surgicalHistory ?? '',
        'familyHistory': _profile.familyHistory ?? '',
        'lifestyle': _profile.lifestyle ?? '',
        'additionalNotes': _profile.additionalNotes ?? '',
      };
      await prefs.setString('clinova_saved_anamnesis_data', jsonEncode(anamnesisMap));
    } catch (e) {
      debugPrint('[PatientProfileRepository] Local storage note: $e');
    }

    if (SupabaseConfig.client != null && AuthConfig.authService.currentSession?.isDemo != true) {
      await _syncToSupabaseAsync();
    }

    return true;
  }

  /// Save Anamnesis medical history to memory and persist to local storage (preserves personal details)
  Future<void> saveAnamnesis({
    required String conditions,
    required String allergies,
    required String medications,
    required String pastMedicalHistory,
    required String surgicalHistory,
    required String familyHistory,
    required String lifestyle,
    required String additionalNotes,
  }) async {
    _profile = _profile.copyWith(
      conditions: conditions,
      allergies: allergies,
      medications: medications,
      pastMedicalHistory: pastMedicalHistory,
      surgicalHistory: surgicalHistory,
      familyHistory: familyHistory,
      lifestyle: lifestyle,
      additionalNotes: additionalNotes,
      isAnamnesisCustomized: true,
    );
    _profileStreamController.add(_profile);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(_profile.toJson()));

      // Also persist to clinova_saved_anamnesis_data for complete backwards compatibility
      final anamnesisMap = {
        'conditions': conditions,
        'allergies': allergies,
        'medications': medications,
        'pastMedicalHistory': pastMedicalHistory,
        'surgicalHistory': surgicalHistory,
        'familyHistory': familyHistory,
        'lifestyle': lifestyle,
        'additionalNotes': additionalNotes,
      };
      await prefs.setString('clinova_saved_anamnesis_data', jsonEncode(anamnesisMap));
    } catch (_) {
      // Fallback
    }

    _syncToSupabase();
  }

  Future<void> _syncToSupabaseAsync() async {
    final client = SupabaseConfig.client;
    final user = client?.auth.currentUser;
    if (client == null || user == null) return;

    try {
      await client.from(SupabaseService.tableProfiles).update({
        'full_name': _profile.fullName,
      }).eq('id', user.id);

      await client.from(SupabaseService.tablePatientProfiles).upsert({
        'patient_id': user.id,
        'date_of_birth': _profile.dateOfBirth?.toIso8601String().split('T').first,
        'gender': _profile.gender,
        'blood_group': _profile.bloodGroup,
        'mobile_number': _profile.mobileNumber,
        'home_address': _profile.homeAddress,
        'height_cm': _profile.heightCm,
        'weight_kg': _profile.weightKg,
        'emergency_contact_name': _profile.emergencyContactName,
        'emergency_contact_relationship': _profile.emergencyContactRelationship,
        'emergency_contact_phone': _profile.emergencyContactPhone,
        'allergies': _profile.allergies,
        'conditions': _profile.conditions,
        'medications': _profile.medications,
        'past_medical_history': _profile.pastMedicalHistory,
        'surgical_history': _profile.surgicalHistory,
        'family_history': _profile.familyHistory,
        'lifestyle': _profile.lifestyle,
        'additional_notes': _profile.additionalNotes,
        'is_anamnesis_customized': _profile.isAnamnesisCustomized,
      });
    } catch (e) {
      debugPrint('[PatientProfileRepository] Error syncing profile to Supabase: $e');
      rethrow;
    }
  }

  void _syncToSupabase() {
    _syncToSupabaseAsync().catchError((e) {
      debugPrint('[PatientProfileRepository] Background sync note: $e');
    });
  }

  /// Update photo directly
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
}
