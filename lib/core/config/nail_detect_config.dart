import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Nail detection backend URL — local dev server now, Firebase/GCP later.
abstract final class NailDetectConfig {
  static const urlEnvName = 'NAIL_DETECT_URL';

  /// e.g. http://127.0.0.1:8765/detect or your Cloud Function URL.
  static String? get detectUrl {
    final fromDotEnv = dotenv.env[urlEnvName]?.trim();
    if (fromDotEnv != null && fromDotEnv.isNotEmpty) {
      return fromDotEnv;
    }
    const fromDefine = String.fromEnvironment(urlEnvName);
    if (fromDefine.isNotEmpty) {
      return fromDefine;
    }
    return null;
  }

  static bool get isConfigured => detectUrl != null;
}
