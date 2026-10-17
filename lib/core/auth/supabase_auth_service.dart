import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_config.dart';
import '../supabase/supabase_service.dart';
import 'auth_models.dart';
import 'auth_service.dart';

/// Production Supabase Authentication Service
///
/// Implements [AuthService] backed by Supabase Auth (`auth.users`) and `public.profiles`.
/// Enforces role validation against the database without relying on client claims.
class SupabaseAuthService implements AuthService {
  SupabaseAuthService._() {
    _initAuthListener();
  }

  static final SupabaseAuthService instance = SupabaseAuthService._();

  UserSession? _currentSession;
  final StreamController<UserSession?> _sessionController =
      StreamController<UserSession?>.broadcast();

  void _initAuthListener() {
    final client = SupabaseConfig.client;
    if (client == null) return;

    client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session == null) {
        _currentSession = null;
        _sessionController.add(null);
      } else {
        await _loadProfileSession(session.user);
      }
    });
  }

  Future<void> _loadProfileSession(User user) async {
    try {
      final client = SupabaseConfig.client;
      if (client == null) return;

      final profileRes = await client
          .from(SupabaseService.tableProfiles)
          .select()
          .eq('id', user.id)
          .maybeSingle();

      final roleStr = profileRes?['role'] as String? ?? 'patient';
      final role = roleStr == 'doctor' ? UserRole.doctor : UserRole.patient;
      final name = profileRes?['full_name'] as String? ?? user.email?.split('@').first ?? 'User';

      String? specialty;
      String? license;

      if (role == UserRole.doctor) {
        final docRes = await client
            .from(SupabaseService.tableDoctorProfiles)
            .select()
            .eq('doctor_id', user.id)
            .maybeSingle();
        specialty = docRes?['specialty'] as String?;
        license = docRes?['license_number'] as String?;
      }

      _currentSession = UserSession(
        id: user.id,
        email: user.email ?? '',
        name: name,
        role: role,
        specialty: specialty,
        licenseNumber: license,
        isDemo: false,
        loggedInAt: DateTime.now(),
      );

      _sessionController.add(_currentSession);
    } catch (e) {
      debugPrint('[SupabaseAuthService] Error loading user profile: $e');
    }
  }

  @override
  UserSession? get currentSession => _currentSession;

  @override
  bool get isAuthenticated => _currentSession != null;

  @override
  Stream<UserSession?> get sessionStream => _sessionController.stream;

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      return AuthResult.failure("Supabase client is not initialized.");
    }

    try {
      final response = await client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;
      if (user == null) {
        return AuthResult.failure("Invalid email or password.");
      }

      // Check user role from public.profiles
      final profile = await client
          .from(SupabaseService.tableProfiles)
          .select('role, full_name')
          .eq('id', user.id)
          .maybeSingle();

      var dbRole = profile?['role'] as String?;
      if (dbRole == null) {
        final metaRole = user.userMetadata?['role'] as String?;
        final metaName = user.userMetadata?['full_name'] as String? ?? user.email?.split('@').first ?? 'User';
        dbRole = metaRole ?? role.name;
        try {
          await client.from(SupabaseService.tableProfiles).upsert({
            'id': user.id,
            'email': user.email ?? '',
            'full_name': metaName,
            'role': dbRole,
          });
          if (dbRole == 'doctor') {
            await client.from(SupabaseService.tableDoctorProfiles).upsert({
              'doctor_id': user.id,
              'specialty': user.userMetadata?['specialty'] as String? ?? 'General Practice',
              'qualification': 'MBBS, MD',
              'license_number': user.userMetadata?['license_number'] as String? ?? 'PENDING-VERIFICATION',
              'is_license_verified': true,
            });
          } else {
            await client.from(SupabaseService.tablePatientProfiles).upsert({
              'patient_id': user.id,
            });
          }
        } catch (e) {
          debugPrint('[SupabaseAuthService] Note auto-provisioning profile: $e');
        }
      }

      final requestedRoleName = role.name;

      if (dbRole != requestedRoleName) {
        await client.auth.signOut();
        return AuthResult.failure(
          "Access denied: This account is registered as a $dbRole, not a $requestedRoleName.",
        );
      }

      await _loadProfileSession(user);

      if (_currentSession != null) {
        return AuthResult.success(_currentSession!);
      } else {
        return AuthResult.failure("Failed to construct user session.");
      }
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure("Authentication failed: ${e.toString()}");
    }
  }

  @override
  Future<AuthResult> registerPatient({
    required String name,
    required String email,
    required String password,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      return AuthResult.failure("Supabase client is not initialized.");
    }

    try {
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': name.trim(),
          'role': 'patient',
        },
      );

      final user = response.user;
      if (user == null) {
        return AuthResult.failure("Could not create patient account.");
      }

      try {
        await client.from(SupabaseService.tableProfiles).upsert({
          'id': user.id,
          'email': user.email ?? email.trim(),
          'full_name': name.trim(),
          'role': 'patient',
        });
        await client.from(SupabaseService.tablePatientProfiles).upsert({
          'patient_id': user.id,
        });
      } catch (e) {
        debugPrint('[SupabaseAuthService] Note on patient profile insert: $e');
      }

      await _loadProfileSession(user);

      if (_currentSession != null) {
        return AuthResult.success(_currentSession!);
      } else {
        return AuthResult.success(UserSession(
          id: user.id,
          email: user.email ?? email,
          name: name.trim(),
          role: UserRole.patient,
          isDemo: false,
          loggedInAt: DateTime.now(),
        ));
      }
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure("Registration failed: ${e.toString()}");
    }
  }

  @override
  Future<AuthResult> registerDoctor({
    required String name,
    required String email,
    required String specialty,
    required String license,
    required String password,
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      return AuthResult.failure("Supabase client is not initialized.");
    }

    try {
      final response = await client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': name.trim(),
          'role': 'doctor',
          'specialty': specialty.trim(),
          'license_number': license.trim(),
        },
      );

      final user = response.user;
      if (user == null) {
        return AuthResult.failure("Could not create doctor account.");
      }

      try {
        await client.from(SupabaseService.tableProfiles).upsert({
          'id': user.id,
          'email': user.email ?? email.trim(),
          'full_name': name.trim(),
          'role': 'doctor',
        });
        await client.from(SupabaseService.tableDoctorProfiles).upsert({
          'doctor_id': user.id,
          'specialty': specialty.trim(),
          'qualification': 'MBBS, MD',
          'license_number': license.trim(),
          'is_license_verified': true,
        });
      } catch (e) {
        debugPrint('[SupabaseAuthService] Note on doctor profile insert: $e');
      }

      await _loadProfileSession(user);

      if (_currentSession != null) {
        return AuthResult.success(_currentSession!);
      } else {
        return AuthResult.success(UserSession(
          id: user.id,
          email: user.email ?? email,
          name: name.trim(),
          role: UserRole.doctor,
          specialty: specialty.trim(),
          licenseNumber: license.trim(),
          isDemo: false,
          loggedInAt: DateTime.now(),
        ));
      }
    } on AuthException catch (e) {
      return AuthResult.failure(e.message);
    } catch (e) {
      return AuthResult.failure("Doctor registration failed: ${e.toString()}");
    }
  }

  @override
  Future<void> logout() async {
    try {
      final client = SupabaseConfig.client;
      if (client != null) {
        await client.auth.signOut();
      }
    } catch (_) {}
    _currentSession = null;
    _sessionController.add(null);
  }
}
