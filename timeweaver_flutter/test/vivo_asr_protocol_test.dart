import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:timeweaver_flutter/services/vivo_asr_protocol.dart';

void main() {
  test('start frame matches the Android vivo realtime ASR contract', () {
    final payload =
        jsonDecode(buildVivoAsrStartFrame(requestId: 'request-id'))
            as Map<String, dynamic>;

    expect(payload['type'], 'started');
    expect(payload['request_id'], 'request-id');
    expect((payload['asr_info'] as Map<String, dynamic>)['audio_type'], 'pcm');
    expect((payload['asr_info'] as Map<String, dynamic>)['lang'], 'cn');
  });

  test('response parser keeps result identifiers and final state', () {
    final event = parseVivoAsrMessage(
      jsonEncode({
        'code': 9,
        'is_finish': true,
        'data': {'result_id': 3, 'text': '明天下午开会'},
      }),
    );

    expect(event.resultId, 3);
    expect(event.text, '明天下午开会');
    expect(event.isLast, isTrue);
    expect(event.isFinish, isTrue);
    expect(event.isError, isFalse);
  });

  test('incremental cumulative segments do not duplicate speech text', () {
    expect(mergeVivoAsrSegments(['明天早上', '明天早上九点', '九点西区上课']), '明天早上九点西区上课');
  });

  test('request URI contains the original Android protocol parameters', () {
    final uri = buildVivoAsrUri(
      endpoint: 'wss://api-ai.vivo.com.cn/asr/v2',
      engineId: 'shortasrinput',
      requestId: '1234567890abcdef1234567890abcdef',
      packageName: 'com.zhishi.timeweaver',
      model: 'device',
      systemVersion: '17.0',
      systemTimeMillis: 123,
    );

    expect(uri.queryParameters['engineid'], 'shortasrinput');
    expect(
      uri.queryParameters['requestId'],
      '1234567890abcdef1234567890abcdef',
    );
    expect(uri.queryParameters['package'], 'com.zhishi.timeweaver');
  });
}
