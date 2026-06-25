import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Roboflow workflow credentials — load from `.env` or `--dart-define`.
abstract final class RoboflowConfig {
  static const apiKeyEnvName = 'ROBOFLOW_API_KEY';
  static const workspaceEnvName = 'ROBOFLOW_WORKSPACE';
  static const workflowEnvName = 'ROBOFLOW_WORKFLOW_ID';

  static const defaultWorkspace = 'oluwaseun-ogunmolu';
  static const defaultWorkflowId = 'general-segmentation-api-3';
  static const inferUrl = 'https://serverless.roboflow.com';

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

  static String get workspace =>
      dotenv.env[workspaceEnvName]?.trim().isNotEmpty == true
          ? dotenv.env[workspaceEnvName]!.trim()
          : defaultWorkspace;

  static String get workflowId =>
      dotenv.env[workflowEnvName]?.trim().isNotEmpty == true
          ? dotenv.env[workflowEnvName]!.trim()
          : defaultWorkflowId;

  static bool get isConfigured => apiKey != null;

  static Uri get workflowInferUri => Uri.parse(
        '$inferUrl/infer/workflows/$workspace/$workflowId',
      );
}
