import '../supabase/supabase_config.dart';
import 'auth_service.dart';
import 'demo_auth_service.dart';
import 'supabase_auth_service.dart';

/// Global authentication configuration for Clinova.
///
/// Toggle [useDemoAuth] or set `--dart-define=CLINOVA_USE_DEMO_AUTH=false` to switch
/// between offline frontend simulation and Supabase backend authentication without touching UI screens.
class AuthConfig {
  AuthConfig._();

  static const bool _forceDemoEnv = bool.fromEnvironment(
    'CLINOVA_USE_DEMO_AUTH',
    defaultValue: false,
  );

  /// Flag indicating whether demo authentication mode is active.
  /// Automatically uses live Supabase when client is initialized and configured,
  /// or falls back to demo auth when in test environment without live client.
  static bool get useDemoAuth {
    if (_forceDemoEnv) return true;
    if (SupabaseConfig.client == null) {
      return true;
    }
    return false;
  }

  /// Retrieves the active [AuthService] implementation according to configuration.
  static AuthService get authService {
    if (useDemoAuth) {
      return DemoAuthService.instance;
    }
    return SupabaseAuthService.instance;
  }
}

