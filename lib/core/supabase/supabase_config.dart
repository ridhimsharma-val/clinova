import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Clinova Supabase Configuration
///
/// Centralizes project URL, publishable anonymous key, and client initialization.
/// Designed for compile-time configuration via `--dart-define` or runtime injection,
/// without hardcoding secrets in source code.
class SupabaseConfig {
  SupabaseConfig._();

  /// Supabase Project URL.
  /// Override at build time:
  /// `--dart-define=SUPABASE_URL=https://your-project.supabase.co`
  static const String defaultUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dretfgxijowevvbayasy.supabase.co',
  );

  /// Supabase Publishable Key (safe for client-side use guarded by RLS).
  /// Override at build time:
  /// `--dart-define=SUPABASE_ANON_KEY=...`
  static const String defaultAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_bJSLWdc6KLPehuPFaOzULQ_TbHHCXDX',
  );

  static String? _runtimeUrl;
  static String? _runtimeAnonKey;
  static bool _isInitialized = false;

  /// Active project URL
  static String get url => _runtimeUrl ?? defaultUrl;

  /// Active publishable anon key
  static String get anonKey => _runtimeAnonKey ?? defaultAnonKey;

  /// Whether valid Supabase credentials have been supplied
  static bool get isConfigured =>
      url.trim().isNotEmpty &&
      anonKey.trim().isNotEmpty &&
      !url.contains('placeholder') &&
      url.startsWith('http');

  /// Whether Supabase client has been initialized
  static bool get isInitialized => _isInitialized;

  /// Sets credentials at runtime
  static void setCredentials({required String url, required String anonKey}) {
    _runtimeUrl = url.trim();
    _runtimeAnonKey = anonKey.trim();
  }

  /// Initializes the Supabase client safely if configured.
  /// Gracefully falls back to offline/demo simulation if credentials are not yet supplied.
  static Future<bool> init() async {
    if (!isConfigured) {
      debugPrint('[SupabaseConfig] Live credentials not set. Running in local/demo mode.');
      _isInitialized = false;
      return false;
    }

    try {
      await Supabase.initialize(
        url: url,
        // ignore: deprecated_member_use
        anonKey: anonKey,
        debug: kDebugMode,
      );
      _isInitialized = true;
      debugPrint('[SupabaseConfig] Successfully connected to Supabase: $url');
      return true;
    } catch (e) {
      debugPrint('[SupabaseConfig] Failed to initialize Supabase: $e');
      _isInitialized = false;
      return false;
    }
  }

  /// Returns the active Supabase client instance or null if uninitialized
  static SupabaseClient? get client {
    if (_isInitialized) {
      try {
        return Supabase.instance.client;
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
