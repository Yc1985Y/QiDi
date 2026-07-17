import 'dart:convert';

class VivoAsrEvent {
  const VivoAsrEvent({
    this.resultId,
    this.text = '',
    this.isLast = false,
    this.isFinish = false,
    this.error,
  });

  final int? resultId;
  final String text;
  final bool isLast;
  final bool isFinish;
  final String? error;

  bool get isError => error != null;
}

Uri buildVivoAsrUri({
  required String endpoint,
  required String engineId,
  required String requestId,
  required String packageName,
  required String model,
  required String systemVersion,
  required int systemTimeMillis,
}) {
  final base = Uri.parse(endpoint);
  return base.replace(
    queryParameters: {
      ...base.queryParameters,
      'client_version': '1.0.0',
      'model': model,
      'system_version': systemVersion,
      'package': packageName,
      'sdk_version': 'unknown',
      'user_id': requestId.padRight(32, '0').substring(0, 32),
      'android_version': systemVersion,
      'system_time': '$systemTimeMillis',
      'net_type': '1',
      'engineid': engineId,
      'requestId': requestId,
    },
  );
}

String buildVivoAsrStartFrame({
  required String requestId,
  String languageTag = 'zh-CN',
}) {
  return jsonEncode({
    'type': 'started',
    'request_id': requestId,
    'asr_info': {
      'end_vad_time': 1200,
      'audio_type': 'pcm',
      'chinese2digital': 1,
      'punctuation': 1,
      'lang': languageTag.toLowerCase().startsWith('en') ? 'en' : 'cn',
    },
    'business_info': 'TimeWeaver voice input',
  });
}

VivoAsrEvent parseVivoAsrMessage(String message) {
  final decoded = jsonDecode(message);
  if (decoded is! Map<String, dynamic>) {
    return const VivoAsrEvent(error: 'Vivo ASR returned an invalid response');
  }
  final action = decoded['action']?.toString() ?? '';
  final code = _asInt(decoded['code']) ?? 0;
  if (action == 'error' || !const {0, 8, 9}.contains(code)) {
    final description = decoded['desc']?.toString() ?? '';
    return VivoAsrEvent(error: 'Vivo ASR error $code: $description');
  }
  if (action == 'started') return const VivoAsrEvent();

  final rawData = decoded['data'];
  final data = rawData is Map<String, dynamic> ? rawData : null;
  final text =
      data?['text']?.toString() ??
      data?['onebest']?.toString() ??
      data?['var']?.toString() ??
      '';
  return VivoAsrEvent(
    resultId: _asInt(data?['result_id']) ?? _asInt(data?['bg']),
    text: text,
    isLast: data?['is_last'] == true || code == 9,
    isFinish: decoded['is_finish'] == true || code == 9,
  );
}

String mergeVivoAsrSegments(Iterable<String> segments) {
  var merged = '';
  for (final raw in segments) {
    final next = raw.trim();
    if (next.isEmpty) continue;
    merged = mergeVivoAsrText(merged, next);
  }
  return merged;
}

String mergeVivoAsrText(String current, String next) {
  if (current.isEmpty) return next;
  if (next == current) return current;
  if (next.startsWith(current)) return next;
  if (current.startsWith(next) || current.contains(next)) return current;
  if (next.contains(current)) return next;

  final maxOverlap = current.length < next.length
      ? current.length
      : next.length;
  for (var size = maxOverlap; size >= 1; size--) {
    if (current.substring(current.length - size) == next.substring(0, size)) {
      return current + next.substring(size);
    }
  }
  return current + next;
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '');
}
