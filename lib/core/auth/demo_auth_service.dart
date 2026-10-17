import 'dart:async';
import 'auth_models.dart';
import 'auth_service.dart';

/// Temporary in-memory demo authentication service.
///
/// Designed for offline frontend workflow testing without backend dependencies.
/// No passwords or sensitive credentials are ever persisted.
class DemoAuthService implements AuthService {
  DemoAuthService._();
  static final DemoAuthService instance = DemoAuthService._();

  /// Configurable simulated latency for realistic UI feel (default: Duration.zero for fast testing)
  Duration simulationDelay = Duration.zero;

  UserSession? _currentSession;
  final StreamController<UserSession?> _sessionController =
      StreamController<UserSession?>.broadcast();

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
    if (simulationDelay > Duration.zero) {
      await Future.delayed(simulationDelay);
    }

    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      return AuthResult.failure("Please enter a valid email address.");
    }

    if (password.length < 6) {
      return AuthResult.failure("Password must be at least 6 characters.");
    }

    // Derive a clean display name from email (e.g. "marcus" from "dr.marcus@hospital.org" -> "Marcus Vance")
    final namePart = trimmedEmail.split('@').first;
    String formattedName;
    if (trimmedEmail.toLowerCase().contains("marcus")) {
      formattedName = "Dr. Marcus Vance";
    } else if (namePart.isNotEmpty) {
      final cleaned = namePart.replaceAll(RegExp(r'^(dr\.|dr)'), '').trim();
      final words = cleaned.split(RegExp(r'[\._\s]+')).where((w) => w.isNotEmpty).map((w) => w[0].toUpperCase() + w.substring(1)).toList();
      formattedName = role == UserRole.doctor ? "Dr. ${words.join(' ')}" : words.join(' ');
    } else {
      formattedName = role == UserRole.doctor ? "Doctor" : "Patient";
    }

    final session = UserSession(
      id: "demo_${role.name}_${DateTime.now().millisecondsSinceEpoch}",
      email: trimmedEmail,
      name: formattedName,
      role: role,
      specialty: role == UserRole.doctor ? "General Practice" : null,
      licenseNumber: role == UserRole.doctor ? "DEMO-LIC-8821" : null,
      isDemo: true,
      loggedInAt: DateTime.now(),
    );

    _currentSession = session;
    _sessionController.add(_currentSession);
    return AuthResult.success(session);
  }

  @override
  Future<AuthResult> registerPatient({
    required String name,
    required String email,
    required String password,
  }) async {
    if (simulationDelay > Duration.zero) {
      await Future.delayed(simulationDelay);
    }

    final trimmedEmail = email.trim();
    final trimmedName = name.trim();

    if (trimmedName.isEmpty) {
      return AuthResult.failure("Please enter your full name.");
    }
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      return AuthResult.failure("Please enter a valid email address.");
    }
    if (password.length < 6) {
      return AuthResult.failure("Password must be at least 6 characters.");
    }

    final session = UserSession(
      id: "demo_patient_${DateTime.now().millisecondsSinceEpoch}",
      email: trimmedEmail,
      name: trimmedName,
      role: UserRole.patient,
      isDemo: true,
      loggedInAt: DateTime.now(),
    );

    _currentSession = session;
    _sessionController.add(_currentSession);
    return AuthResult.success(session);
  }

  @override
  Future<AuthResult> registerDoctor({
    required String name,
    required String email,
    required String specialty,
    required String license,
    required String password,
  }) async {
    if (simulationDelay > Duration.zero) {
      await Future.delayed(simulationDelay);
    }

    final trimmedEmail = email.trim();
    final trimmedName = name.trim();
    final trimmedSpecialty = specialty.trim();
    final trimmedLicense = license.trim();

    if (trimmedName.isEmpty) {
      return AuthResult.failure("Please enter your doctor name and title.");
    }
    if (trimmedEmail.isEmpty || !trimmedEmail.contains('@')) {
      return AuthResult.failure("Please enter a valid email address.");
    }
    if (trimmedSpecialty.isEmpty) {
      return AuthResult.failure("Please enter your medical specialty.");
    }
    if (trimmedLicense.isEmpty) {
      return AuthResult.failure("Please enter your license number placeholder.");
    }
    if (password.length < 6) {
      return AuthResult.failure("Password must be at least 6 characters.");
    }

    final session = UserSession(
      id: "demo_doctor_${DateTime.now().millisecondsSinceEpoch}",
      email: trimmedEmail,
      name: trimmedName,
      role: UserRole.doctor,
      specialty: trimmedSpecialty,
      licenseNumber: trimmedLicense,
      isDemo: true,
      loggedInAt: DateTime.now(),
    );

    _currentSession = session;
    _sessionController.add(_currentSession);
    return AuthResult.success(session);
  }

  @override
  Future<void> logout() async {
    if (simulationDelay > Duration.zero) {
      await Future.delayed(simulationDelay);
    }
    _currentSession = null;
    _sessionController.add(null);
  }
}
