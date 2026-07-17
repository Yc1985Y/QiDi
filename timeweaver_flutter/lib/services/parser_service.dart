import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/parsed_notice.dart';
import '../models/source_info.dart';
import '../utils/notice_segment_extractor.dart';
import 'api_config.dart';
import 'ocr_service.dart';

class ParseOutcome {
  const ParseOutcome({
    required this.action,
    required this.notices,
    required this.confidence,
    required this.targetFound,
    this.feedback,
    this.speechText,
  });

  final String action;
  final List<ParsedNotice> notices;
  final double confidence;
  final bool targetFound;
  final String? feedback;
  final String? speechText;
}

class ParserService {
  ParserService({OcrService? ocrService})
    : _ocrService = ocrService ?? OcrService();

  final OcrService _ocrService;

  Future<ParseOutcome> parseNotice({
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

    final primary = await _parseWithVlm(
      mergedText: mergedText,
      source: source.copyWith(ocrText: ocrText),
      userInstruction: userInstruction,
    );
    if (primary.notices.length > 1) return primary;

    final segments = NoticeSegmentExtractor.extractIndependentScheduleSegments(
      mergedText,
    );
    if (segments.length < 2) return primary;

    final fallbackNotices = <ParsedNotice>[];
    for (final segment in segments) {
      try {
        final outcome = await _parseWithVlm(
          mergedText: segment,
          source: source.copyWith(rawText: segment, ocrText: ocrText),
          userInstruction: userInstruction,
        );
        fallbackNotices.addAll(outcome.notices);
      } catch (_) {
        // Keep successful segment results; the original complete response remains available.
      }
    }
    final unique = <String, ParsedNotice>{};
    for (final notice in fallbackNotices) {
      final key = [
        notice.action,
        notice.title.trim().toLowerCase(),
        notice.startTimeIso?.trim().toLowerCase() ?? '',
        notice.location?.trim().toLowerCase() ?? '',
      ].join('|');
      unique[key] = notice;
    }
    if (unique.length <= primary.notices.length) return primary;

    final notices = unique.values.toList();
    final hasClarification = notices.any(
      (notice) => notice.action == NoticeAction.clarification,
    );
    return ParseOutcome(
      action: hasClarification
          ? NoticeAction.clarification
          : NoticeAction.createEvent,
      notices: notices,
      confidence: notices
          .map((notice) => notice.confidence)
          .fold<double>(
            1.0,
            (lowest, value) => value < lowest ? value : lowest,
          ),
      targetFound: true,
      feedback: hasClarification ? '部分事项需要补充信息后再确认。' : null,
    );
  }

  Future<ParseOutcome> _parseWithVlm({
    required String mergedText,
    required SourceInfo source,
    String? userInstruction,
  }) async {
    final requestId = const Uuid().v4();
    final endpoint = Uri.parse(
      ApiConfig.apiEndpoint,
    ).replace(queryParameters: {'requestId': requestId});
    final now = DateTime.now();
    final payload = <String, dynamic>{
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
            '当前参考日期：${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}',
            '用户指令：${userInstruction ?? '帮我把这个校园通知加入日程'}',
            '输入来源：${source.label}',
            '通知文本：',
            mergedText,
          ].join('\n'),
        },
      ],
    };
    final normalizedModelName = ApiConfig.modelName.toLowerCase();
    if (normalizedModelName.contains('qwen')) {
      payload['enable_thinking'] = false;
    }
    if (normalizedModelName.contains('deepseek') ||
        normalizedModelName.contains('doubao') ||
        normalizedModelName.contains('seed')) {
      payload['thinking'] = {'type': 'disabled'};
    }

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
      throw ParserRequestException('智能解析请求失败：HTTP ${response.statusCode}');
    }

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map<String, dynamic>) {
      throw const ParserRequestException('智能解析响应格式异常');
    }
    final code = body['code'] as int?;
    final errorCode = body['error_code'] as int?;
    if ((code != null && code != 0) || (errorCode != null && errorCode != 0)) {
      throw ParserRequestException('智能解析响应错误：${code ?? errorCode}');
    }
    final choices = body['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const ParserRequestException('智能解析没有返回候选结果');
    }
    final message = choices.first['message'];
    final content = message is Map ? message['content'] as String? : null;
    if (content == null || content.trim().isEmpty) {
      throw const ParserRequestException('智能解析返回内容为空');
    }
    final cleaned = _extractJson(content);
    final parsed = jsonDecode(cleaned);
    if (parsed is! Map<String, dynamic>) {
      throw const ParserRequestException('智能解析的结构化 JSON 异常');
    }
    return interpretModelPayload(parsed, source: source, rawPayload: cleaned);
  }

  ParseOutcome interpretModelPayload(
    Map<String, dynamic> parsed, {
    required SourceInfo source,
    String? rawPayload,
  }) {
    final requestedAction = NoticeAction.normalize(parsed['action']);
    final targetFound = parsed['target_found'] as bool? ?? true;
    final topLevelConfidence = _confidence(parsed['confidence'], fallback: 0.0);
    final payload = parsed['payload'] is Map
        ? Map<String, dynamic>.from(parsed['payload'] as Map)
        : <String, dynamic>{};
    final fallbackQuery = _clean(parsed['fallback_query']);
    final feedback =
        fallbackQuery ??
        _clean(payload['answer']) ??
        _clean(parsed['answer']) ??
        _clean(payload['description']) ??
        _clean(parsed['description']);

    if (!targetFound && requestedAction != NoticeAction.clarification) {
      return ParseOutcome(
        action: NoticeAction.unknown,
        notices: const [],
        confidence: topLevelConfidence,
        targetFound: false,
        feedback: feedback ?? '未识别到可创建日程的校园通知',
      );
    }

    if (requestedAction == NoticeAction.ttsFeedback) {
      final speechText =
          _clean(payload['answer']) ??
          _clean(parsed['answer']) ??
          _clean(payload['description']) ??
          _clean(parsed['description']);
      return ParseOutcome(
        action: NoticeAction.ttsFeedback,
        notices: const [],
        confidence: topLevelConfidence,
        targetFound: targetFound,
        feedback: speechText ?? '接口没有返回可播报内容',
        speechText: speechText,
      );
    }

    if (requestedAction == NoticeAction.unknown) {
      return ParseOutcome(
        action: NoticeAction.unknown,
        notices: const [],
        confidence: topLevelConfidence,
        targetFound: targetFound,
        feedback: feedback ?? '未识别到可处理的校园事项',
      );
    }

    final candidates = _normalizeApiEvents(parsed, payload);
    if (requestedAction == NoticeAction.navigate) {
      final map = candidates.isEmpty ? payload : candidates.first;
      final hasLocation = _clean(map['location']) != null;
      final action = hasLocation
          ? NoticeAction.navigate
          : NoticeAction.clarification;
      final notice = _noticeFromMap(
        map,
        source,
        rawPayload,
        action: NoticeAction.navigate,
        fallbackQuery: fallbackQuery ?? (hasLocation ? null : '请补充需要导航的校园地点。'),
        confidenceFallback: topLevelConfidence,
      );
      return ParseOutcome(
        action: action,
        notices: [notice],
        confidence: notice.confidence,
        targetFound: targetFound,
        feedback: notice.fallbackQuery,
      );
    }

    if (requestedAction == NoticeAction.clarification) {
      final map = candidates.isEmpty ? payload : candidates.first;
      final notice = _noticeFromMap(
        map,
        source,
        rawPayload,
        action: NoticeAction.clarification,
        fallbackQuery: fallbackQuery ?? '通知信息还不完整，请补充标题、时间或地点。',
        confidenceFallback: topLevelConfidence,
      );
      return ParseOutcome(
        action: NoticeAction.clarification,
        notices: [notice],
        confidence: notice.confidence,
        targetFound: targetFound,
        feedback: notice.fallbackQuery,
      );
    }

    if (candidates.isEmpty) {
      final notice = _noticeFromMap(
        payload,
        source,
        rawPayload,
        action: NoticeAction.clarification,
        fallbackQuery: fallbackQuery ?? '接口没有返回完整的校园事项，请补充标题和时间。',
        confidenceFallback: topLevelConfidence,
      );
      return ParseOutcome(
        action: NoticeAction.clarification,
        notices: [notice],
        confidence: notice.confidence,
        targetFound: targetFound,
        feedback: notice.fallbackQuery,
      );
    }

    final notices = candidates.map((event) {
      final confidence = _confidence(
        event['confidence'],
        fallback: topLevelConfidence,
      );
      final hasTitle = _clean(event['title']) != null;
      final hasTime = _clean(event['time']) != null;
      final requiresClarification = !hasTitle || !hasTime || confidence < 0.7;
      return _noticeFromMap(
        event,
        source,
        rawPayload,
        action: requiresClarification
            ? NoticeAction.clarification
            : NoticeAction.createEvent,
        fallbackQuery: requiresClarification
            ? fallbackQuery ??
                  _clarificationPrompt(hasTitle: hasTitle, hasTime: hasTime)
            : null,
        confidenceFallback: topLevelConfidence,
      );
    }).toList();
    final hasClarification = notices.any(
      (notice) => notice.action == NoticeAction.clarification,
    );
    return ParseOutcome(
      action: hasClarification
          ? NoticeAction.clarification
          : NoticeAction.createEvent,
      notices: notices,
      confidence: notices
          .map((notice) => notice.confidence)
          .fold<double>(
            1.0,
            (lowest, value) => value < lowest ? value : lowest,
          ),
      targetFound: targetFound,
      feedback: hasClarification ? fallbackQuery : null,
    );
  }

  List<Map<String, dynamic>> _normalizeApiEvents(
    Map<String, dynamic> parsed,
    Map<String, dynamic> payload,
  ) {
    final nestedEvents = payload['events'];
    final rawEvents = parsed['events'] is List
        ? parsed['events'] as List
        : nestedEvents is List
        ? nestedEvents
        : const [];
    if (rawEvents.isNotEmpty) {
      return rawEvents
          .whereType<Map>()
          .map((item) {
            final event = Map<String, dynamic>.from(item);
            for (final key in const [
              'title',
              'time',
              'location',
              'description',
              'answer',
              'confidence',
            ]) {
              event[key] ??= payload[key] ?? parsed[key];
            }
            return event;
          })
          .where(_hasScheduleContent)
          .toList();
    }
    final merged = <String, dynamic>{...parsed, ...payload};
    return _hasScheduleContent(merged) ? [merged] : const [];
  }

  ParsedNotice _noticeFromMap(
    Map<String, dynamic> map,
    SourceInfo source,
    String? rawPayload, {
    required String action,
    required String? fallbackQuery,
    required double confidenceFallback,
  }) {
    final nowIso = DateTime.now().toIso8601String();
    final title = _clean(map['title']) ?? '';
    final time = _clean(map['time']);
    final location = _clean(map['location']);
    final description = _clean(map['description']) ?? _clean(map['answer']);
    final confidence = _confidence(
      map['confidence'],
      fallback: confidenceFallback,
    );
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
      confidence: confidence,
      reminderSuggestion: parsedTime == null ? '补充时间后提醒' : '提前1天 / 提前1小时',
      rawPayload: rawPayload,
      status: action == NoticeAction.createEvent
          ? '待确认'
          : action == NoticeAction.navigate
          ? '待导航'
          : '待补充',
      action: action,
      fallbackQuery: fallbackQuery,
      createdAtIso: nowIso,
    );
  }

  bool _hasScheduleContent(Map<String, dynamic> map) {
    return _clean(map['title']) != null ||
        _clean(map['time']) != null ||
        _clean(map['location']) != null ||
        _clean(map['description']) != null ||
        _clean(map['answer']) != null;
  }

  double _confidence(Object? value, {required double fallback}) {
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    return (parsed ?? fallback).clamp(0.0, 1.0);
  }

  String _clarificationPrompt({required bool hasTitle, required bool hasTime}) {
    if (!hasTitle) return '我还不能确定这是哪个活动，请补充活动名称。';
    if (!hasTime) return '我识别到了活动，但没有看清开始时间，请补充完整时间。';
    return '当前结果不够稳定，请复核标题、时间和地点后再确认。';
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
Allowed actions: create_event, navigate, tts_feedback, clarification, unknown.
Schema:
{
  "action": "create_event|navigate|tts_feedback|clarification|unknown",
  "confidence": 0.0,
  "payload": {
    "title": "",
    "time": "",
    "location": "",
    "phone_number": "",
    "description": "",
    "answer": ""
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
1. Always provide confidence between 0.0 and 1.0.
2. For create_event, title, time, and location are required. If any is missing or uncertain, use clarification.
3. Resolve relative Chinese dates using the reference time from the user message.
4. time should be ISO-like when possible.
5. If an exact date cannot be inferred, preserve the original phrase and use clarification.
6. Never invent absent details.
7. Return every independent schedule item in events and mirror the first item in payload.
8. If at least one valid schedule item can be extracted, prefer create_event with events.
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
