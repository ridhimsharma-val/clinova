/// User roles supported by Clinova
enum UserRole {
  patient,
  doctor,
}

/// Represents an authenticated user session in Clinova
class UserSession {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? specialty;
  final String? licenseNumber;
  final bool isDemo;
  final DateTime loggedInAt;

  const UserSession({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.specialty,
    this.licenseNumber,
    this.isDemo = true,
    required this.loggedInAt,
  });

  bool get isPatient => role == UserRole.patient;
  bool get isDoctor => role == UserRole.doctor;
}

/// Result of an authentication operation
class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final UserSession? session;

  const AuthResult._({
    required this.isSuccess,
    this.errorMessage,
    this.session,
  });

  factory AuthResult.success(UserSession session) {
    return AuthResult._(
      isSuccess: true,
      session: session,
    );
  }

  factory AuthResult.failure(String errorMessage) {
    return AuthResult._(
      isSuccess: false,
      errorMessage: errorMessage,
    );
  }
}
