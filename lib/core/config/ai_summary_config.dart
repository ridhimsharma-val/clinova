/// Clinova AI Summary Configuration
///
/// Manages the n8n webhook endpoint configuration without hardcoding secrets
/// or credentials in client code.
class AiSummaryConfig {
  AiSummaryConfig._();

  /// Default n8n webhook URL.
  /// Can be overridden at build time via:
  /// `--dart-define=CLINOVA_N8N_WEBHOOK_URL=https://n8n.yourdomain.com/webhook/clinova-case-summary`
  static const String defaultWebhookUrl = String.fromEnvironment(
    'CLINOVA_N8N_WEBHOOK_URL',
    defaultValue: 'https://dynamo8.app.n8n.cloud/webhook/clinova-case-summary',
  );

  static String? _runtimeWebhookUrl;

  /// Returns the active webhook URL (runtime override if set, else environment/default)
  static String get webhookUrl => _runtimeWebhookUrl ?? defaultWebhookUrl;

  /// Allows setting a custom webhook URL at runtime (e.g. for testing or settings)
  static set runtimeWebhookUrl(String? url) {
    _runtimeWebhookUrl = url;
  }

  /// Request timeout in seconds
  static const int requestTimeoutSeconds = 30;

  /// Mandatory clinical disclaimer string
  static const String clinicalDisclaimer =
      'AI-generated summary — requires physician review.';
}
