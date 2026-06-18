import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img;

import '../constants/try_on_strings.dart';
import '../core/config/openai_config.dart';
import '../models/nail_style.dart';
import 'nail_prompt_builder.dart';

class NailGenerationException implements Exception {
  NailGenerationException(this.message);

  factory NailGenerationException.missingApiKey() =>
      NailGenerationException(TryOnStrings.missingApiKey);

  final String message;

  @override
  String toString() => message;
}

class NailGenerationService {
  const NailGenerationService();

  static const Duration _requestTimeout = Duration(seconds: 120);

  Future<Uint8List> generate({
    required Uint8List handImageBytes,
    required NailStyle style,
  }) async {
    final apiKey = OpenAiConfig.apiKey;
    if (apiKey == null) {
      throw NailGenerationException.missingApiKey();
    }

    final prepared = _prepareHandImage(handImageBytes);
    final prompt = NailPromptBuilder.build(style);

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${OpenAiConfig.baseUrl}/v1/images/edits'),
    )
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..fields['model'] = 'gpt-image-1'
      ..fields['prompt'] = prompt
      ..fields['quality'] = 'high'
      ..fields['input_fidelity'] = 'high'
      ..fields['size'] = 'auto'
      ..fields['output_format'] = 'jpeg'
      ..files.add(
        http.MultipartFile.fromBytes(
          'image',
          prepared.bytes,
          filename: prepared.filename,
          contentType: MediaType.parse(prepared.mimeType),
        ),
      );

    final streamed = await request.send().timeout(_requestTimeout);
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode < 200 || streamed.statusCode >= 300) {
      throw NailGenerationException(_apiErrorMessage(body, streamed.statusCode));
    }

    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final data = decoded['data'] as List<dynamic>?;
    if (data == null || data.isEmpty) {
      throw NailGenerationException(TryOnStrings.generationFailed);
    }

    final first = data.first as Map<String, dynamic>;
    final b64 = first['b64_json'] as String?;
    if (b64 != null && b64.isNotEmpty) {
      return base64Decode(b64);
    }

    final url = first['url'] as String?;
    if (url != null && url.isNotEmpty) {
      final imageResponse = await http.get(Uri.parse(url)).timeout(_requestTimeout);
      if (imageResponse.statusCode == 200) {
        return imageResponse.bodyBytes;
      }
    }

    throw NailGenerationException(TryOnStrings.generationFailed);
  }

  String _apiErrorMessage(String body, int statusCode) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final error = decoded['error'];
      if (error is Map<String, dynamic>) {
        final message = error['message'] as String?;
        if (message != null && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {
      // Fall through to generic message.
    }
    return '${TryOnStrings.generationFailed} ($statusCode)';
  }

  _PreparedImage _prepareHandImage(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return _PreparedImage(
        bytes: bytes,
        filename: 'hand.jpg',
        mimeType: 'image/jpeg',
      );
    }

    final oriented = img.bakeOrientation(decoded);
    final longEdge = oriented.width > oriented.height ? oriented.width : oriented.height;
    final targetLongEdge = longEdge.clamp(1024, 1536);

    final resized = img.copyResize(
      oriented,
      width: oriented.width >= oriented.height ? targetLongEdge : null,
      height: oriented.height > oriented.width ? targetLongEdge : null,
      interpolation: img.Interpolation.average,
    );

    return _PreparedImage(
      bytes: Uint8List.fromList(img.encodeJpg(resized, quality: 95)),
      filename: 'hand.jpg',
      mimeType: 'image/jpeg',
    );
  }
}

class _PreparedImage {
  const _PreparedImage({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String filename;
  final String mimeType;
}
