import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/parsed_notice.dart';
import '../models/source_info.dart';
import 'api_config.dart';
import 'ocr_service.dart';

class ParserService {
  ParserService({OcrService? ocrService})
    : _ocrService = ocrService ?? OcrService();

  final OcrService _ocrService;

  Future<List<ParsedNotice>> parseNotice({
    required SourceInfo source,
    String? userInstruction,
  }) async {
    String? ocrText = source.ocrText;
    if ((ocrText == null || ocrText.trim().isEmpty) &&
        source.imagePath != null) {
      ocrText = await _ocrService.recognizeImage(source.imagePath!);
    }

    final mergedText = [
      if (ocrText != null && ocrText.trim().isNotEmpty) ocrText,
      if (source.rawText != null && source.rawText!.trim().isNotEmpty)
        source.rawText,
    ].join('\n').trim();

    if (mergedText.isEmpty) {
      throw const ParserInputException('没有可解析的通知文字');
    }

    if (!ApiConfig.hasChatConfig) {
      throw const ParserConfigException();
    }

    final apiResult = await _parseWithVlm(
      mergedText: mergedText,
      source: source.copyWith(ocrText: ocrText),
      userInstruction: userInstruction,
    );
    if (apiResult.isEmpty) {
      throw const ParserRequestException('接口没有返回可确认的校园事项');
    }
    return apiResult;
  }

  Future<List<ParsedNotice>> _parseWithVlm({
    required String mergedText,
    required SourceInfo source,
    String? userInstruction,
  }) async {
    final requestId = const Uuid().v4();
    final endpoint = Uri.parse(
      ApiConfig.apiEndpoint,
    ).replace(queryParameters: {'requestId': requestId});
    final now = DateTime.now();
    final payload = {
      'model': ApiConfig.modelName,
      'temperature': 0.2,
      'stream': false,
      'max_tokens': 768,
      'reasoning_effort': 'minimal',
      'messages': [
        {'role': 'system', 'content': _systemPrompt},
        {
          'role': 'user',
          'content': [
            '当前设备时区：Asia/Shanghai',
            '当前参考时间：${now.toIso8601String()}',
            '用户指令：${userInstruction ?? '帮我把这个校园通知加入日程'}',
            '输入来源：${source.label}',
            '通知文本：',
            mergedText,
          ].join('\n'),
        },
      ],
    };

    final response = await http
        .post(
          endpoint,
          headers: {
            'Authorization': 'Bearer ${ApiConfig.apiKey}',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ParserRequestException('大模型请求失败：HTTP ${response.statusCode}');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map<String, dynamic>) {
      throw const ParserRequestException('大模型响应格式异常');
    }
    final code = body['code'] as int?;
    final errorCode = body['error_code'] as int?;
    if ((code != null && code != 0) || (errorCode != null && errorCode != 0)) {
      throw ParserRequestException('大模型响应错误：${code ?? errorCode}');
    }
    final choices = body['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const ParserRequestException('大模型没有返回候选结果');
    }
    final message = choices.first['message'];
    final content = message is Map ? message['content'] as String? : null;
    if (content == null || content.trim().isEmpty) {
      throw const ParserRequestException('大模型返回内容为空');
    }
    final cleaned = _extractJson(content);
    final parsed = jsonDecode(cleaned);
    if (parsed is! Map<String, dynamic>) {
      throw const ParserRequestException('大模型结构化 JSON 异常');
    }

    final events = _normalizeApiEvents(parsed);
    return events
        .map((event) => _noticeFromMap(event, source, cleaned))
        .toList();
  }

  List<Map<String, dynamic>> _normalizeApiEvents(Map<String, dynamic> parsed) {
    final rawEvents = parsed['events'];
    if (rawEvents is List && rawEvents.isNotEmpty) {
      return rawEvents
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    final payload = parsed['payload'];
    if (payload is Map) {
      return [Map<String, dynamic>.from(payload)];
    }
    return [parsed];
  }

  ParsedNotice _noticeFromMap(
    Map<String, dynamic> map,
    SourceInfo source,
    String rawPayload,
  ) {
    final nowIso = DateTime.now().toIso8601String();
    final title = _clean(map['title']) ?? '新的校园事项';
    final time = _clean(map['time']);
    final location = _clean(map['location']);
    final description = _clean(map['description']) ?? _clean(map['answer']);
    final confidence = (map['confidence'] as num?)?.toDouble() ?? 0.72;
    final parsedTime = _parseDateTime(time);
    return ParsedNotice(
      id: const Uuid().v4(),
      title: title,
      eventType: _detectEventType('$title $description'),
      startTimeIso: parsedTime?.toIso8601String() ?? time,
      deadlineIso: _looksLikeDeadline('$title $description')
          ? parsedTime?.toIso8601String()
          : null,
      location: location,
      description: description,
      source: source,
      confidence: confidence.clamp(0.0, 1.0),
      reminderSuggestion: parsedTime == null ? '补充时间后提醒' : '提前1天 / 提前1小时',
      rawPayload: rawPayload,
      createdAtIso: nowIso,
    );
  }

  String _detectEventType(String text) {
    if (text.contains(RegExp(r'考试|测验|补考'))) return '考试';
    if (text.contains(RegExp(r'讲座|报告|论坛|分享'))) return '讲座';
    if (text.contains(RegExp(r'会议|班会|例会'))) return '会议';
    if (text.contains(RegExp(r'报名|提交|截止|ddl|DDL|作业'))) return '截止事项';
    if (text.contains(RegExp(r'志愿|活动|比赛|竞赛'))) return '活动';
    return '校园安排';
  }

  bool _looksLikeDeadline(String text) {
    return text.contains(RegExp(r'截止|提交|报名|ddl|DDL|前'));
  }

  DateTime? _parseDateTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final text = raw.replaceFirst(' ', 'T').trim();
    final direct = DateTime.tryParse(text);
    if (direct != null) return direct;

    final now = DateTime.now();
    DateTime? day;
    final yearDate = RegExp(
      r'(\d{4})[./-](\d{1,2})[./-](\d{1,2})',
    ).firstMatch(raw);
    if (yearDate != null) {
      day = DateTime(
        int.parse(yearDate.group(1)!),
        int.parse(yearDate.group(2)!),
        int.parse(yearDate.group(3)!),
      );
    }
    final monthDate = RegExp(r'(\d{1,2})月(\d{1,2})日').firstMatch(raw);
    if (day == null && monthDate != null) {
      day = DateTime(
        now.year,
        int.parse(monthDate.group(1)!),
        int.parse(monthDate.group(2)!),
      );
    }
    if (day == null) {
      if (raw.contains('今天')) day = DateTime(now.year, now.month, now.day);
      if (raw.contains('明天')) {
        final next = now.add(const Duration(days: 1));
        day = DateTime(next.year, next.month, next.day);
      }
      if (raw.contains('后天')) {
        final next = now.add(const Duration(days: 2));
        day = DateTime(next.year, next.month, next.day);
      }
    }
    day ??= _parseWeekday(raw, now);
    if (day == null) return null;

    final time =
        RegExp(r'(\d{1,2})[:：](\d{2})').firstMatch(raw) ??
        RegExp(r'(\d{1,2})[点时](\d{1,2})?分?').firstMatch(raw);
    var hour = 9;
    var minute = 0;
    if (time != null) {
      hour = int.parse(time.group(1)!);
      minute = int.tryParse(time.group(2) ?? '') ?? 0;
      if (raw.contains('下午') || raw.contains('晚上')) {
        if (hour < 12) hour += 12;
      }
    }
    return DateTime(day.year, day.month, day.day, hour, minute);
  }

  DateTime? _parseWeekday(String raw, DateTime now) {
    final match = RegExp(r'(本周|下周)?(?:周|星期)([一二三四五六日天])').firstMatch(raw);
    if (match == null) return null;
    const values = {
      '一': 1,
      '二': 2,
      '三': 3,
      '四': 4,
      '五': 5,
      '六': 6,
      '日': 7,
      '天': 7,
    };
    final target = values[match.group(2)!]!;
    final current = now.weekday;
    var delta = target - current;
    if (match.group(1) == '下周') delta += 7;
    if (match.group(1) == null && delta < 0) delta += 7;
    final date = now.add(Duration(days: delta));
    return DateTime(date.year, date.month, date.day);
  }

  String? _clean(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  String _extractJson(String content) {
    final fenced = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(content);
    if (fenced != null) return fenced.group(1)!.trim();
    final start = content.indexOf('{');
    final end = content.lastIndexOf('}');
    if (start >= 0 && end > start) return content.substring(start, end + 1);
    return content.trim();
  }
}

const _systemPrompt = '''
You are the structured decision engine for a campus schedule assistant.
Return compact strict JSON only. Do not add explanations outside JSON.
Schema:
{
  "action": "create_event|clarification|unknown",
  "confidence": 0.0,
  "payload": {
    "title": "",
    "time": "",
    "location": "",
    "description": ""
  },
  "events": [
    {
      "title": "",
      "time": "",
      "location": "",
      "description": "",
      "confidence": 0.0
    }
  ],
  "fallback_query": "",
  "target_found": true
}
Rules:
1. Resolve relative Chinese dates using the reference time from user message.
2. time should be ISO-like when possible.
3. Never invent absent details.
4. Return multiple independent schedule items in events.
''';

class ParserInputException implements Exception {
  const ParserInputException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ParserConfigException implements Exception {
  const ParserConfigException();

  @override
  String toString() {
    return '通知解析需要配置真实 VLM_API_KEY。请通过 --dart-define 传入原项目同源接口凭据。';
  }
}

class ParserRequestException implements Exception {
  const ParserRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}
