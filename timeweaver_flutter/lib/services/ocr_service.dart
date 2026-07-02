import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'api_config.dart';

class OcrService {
  Future<String?> recognizeImage(String imagePath) async {
    if (!ApiConfig.hasOcrConfig) {
      throw const OcrConfigException();
    }

    final bytes = await File(imagePath).readAsBytes();
    final base64Image = base64Encode(bytes);
    final requestId = const Uuid().v4();
    final endpoint = Uri.parse(
      ApiConfig.ocrEndpoint,
    ).replace(queryParameters: {'requestId': requestId});

    final response = await http
        .post(
          endpoint,
          headers: {
            'Authorization': 'Bearer ${ApiConfig.apiKey}',
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body: {
            'image': base64Image,
            'pos': '2',
            'businessid': 'aigc${ApiConfig.appId}',
            'sessid': const Uuid().v4(),
          },
        )
        .timeout(const Duration(seconds: 18));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw OcrRequestException('OCR 请求失败：HTTP ${response.statusCode}');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map<String, dynamic>) {
      throw const OcrRequestException('OCR 响应格式异常');
    }
    final errorCode = body['error_code'] as int? ?? -1;
    if (errorCode != 0) {
      throw OcrRequestException('OCR 识别失败：${body['error_msg'] ?? errorCode}');
    }

    final result = body['result'];
    if (result is! Map<String, dynamic>) return null;
    final words = <String>[];
    _collectWords(result['words'], words);
    _collectWords(result['OCR'], words);
    final text = words
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toSet()
        .join('\n');
    return text.isEmpty ? null : text;
  }

  void _collectWords(Object? raw, List<String> target) {
    if (raw is! List) return;
    for (final item in raw) {
      if (item is Map && item['words'] is String) {
        target.add(item['words'] as String);
      }
    }
  }
}

class OcrConfigException implements Exception {
  const OcrConfigException();

  @override
  String toString() {
    return '图片 OCR 需要配置 VLM_APP_ID 和 VLM_API_KEY，或在图片旁补充通知文字。';
  }
}

class OcrRequestException implements Exception {
  const OcrRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}
