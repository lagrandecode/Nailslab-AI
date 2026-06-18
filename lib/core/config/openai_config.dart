import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Loads OpenAI credentials from `.env` or `--dart-define` (never hardcoded).
abstract final class OpenAiConfig {
  static const String apiKeyEnvName = 'OPENAI_API_KEY';
  static const String baseUrl = 'https://api.openai.com';

  static String? get apiKey {
    final fromDotEnv = dotenv.env[apiKeyEnvName]?.trim();
    if (fromDotEnv != null && fromDotEnv.isNotEmpty) {
      return fromDotEnv;
    }

    const fromDefine = String.fromEnvironment(apiKeyEnvName);
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }

    return null;
  }

  static bool get isConfigured => apiKey != null;
}
