import 'dart:async';
import 'auth_models.dart';

/// Abstract authentication interface separating UI from authentication provider.
///
/// Implementations include [DemoAuthService] for offline/frontend testing and
/// future [SupabaseAuthService] for production backend authentication.
abstract class AuthService {
  /// The current active user session, or null if unauthenticated.
  UserSession? get currentSession;

  /// Whether a user is currently authenticated.
  bool get isAuthenticated => currentSession != null;

  /// Stream of user session changes (useful for reactive UI and route guards).
  Stream<UserSession?> get sessionStream;

  /// Authenticate an existing user by email and password with role validation.
  Future<AuthResult> login({
    required String email,
    required String password,
    required UserRole role,
  });

  /// Register a new patient account.
  Future<AuthResult> registerPatient({
    required String name,
    required String email,
    required String password,
  });

  /// Register a new doctor account with clinical credentials.
  Future<AuthResult> registerDoctor({
    required String name,
    required String email,
    required String specialty,
    required String license,
    required String password,
  });

  /// Terminate the active session and clear credentials from memory.
  Future<void> logout();
}
