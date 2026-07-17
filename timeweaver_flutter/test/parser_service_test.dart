import 'package:flutter_test/flutter_test.dart';
import 'package:timeweaver_flutter/models/parsed_notice.dart';
import 'package:timeweaver_flutter/models/source_info.dart';
import 'package:timeweaver_flutter/services/parser_service.dart';
import 'package:timeweaver_flutter/utils/validators.dart';
import 'package:timeweaver_flutter/utils/notice_segment_extractor.dart';

void main() {
  const source = SourceInfo(type: SourceType.manualText, rawText: '校园通知原文');

  test('expands every real event returned by a batch response', () {
    final outcome = ParserService().interpretModelPayload({
      'action': 'create_event',
      'confidence': 0.92,
      'target_found': true,
      'payload': {
        'title': '第一场活动',
        'time': '2099-07-16T09:00:00',
        'location': '院楼',
      },
      'events': [
        {
          'title': '第一场活动',
          'time': '2099-07-16T09:00:00',
          'location': '院楼',
          'confidence': 0.91,
        },
        {
          'title': '第二场活动',
          'time': '2099-07-17T14:00:00',
          'location': '图书馆',
          'confidence': 0.89,
        },
      ],
    }, source: source);

    expect(outcome.action, NoticeAction.createEvent);
    expect(outcome.notices.map((notice) => notice.title), ['第一场活动', '第二场活动']);
    expect(
      outcome.notices.every(
        (notice) => notice.action == NoticeAction.createEvent,
      ),
      isTrue,
    );
  });

  test('keeps missing fields empty and requires clarification', () {
    final outcome = ParserService().interpretModelPayload({
      'action': 'clarification',
      'confidence': 0.46,
      'payload': {'time': '下周二晚上七点'},
      'fallback_query': '请补充活动名称和地点。',
    }, source: source);

    expect(outcome.action, NoticeAction.clarification);
    expect(outcome.notices.single.title, isEmpty);
    expect(outcome.notices.single.fallbackQuery, '请补充活动名称和地点。');
    expect(Validators.confirmBlocker(outcome.notices.single), '请补充标题');
  });

  test('preserves navigation as a confirmation action', () {
    final outcome = ParserService().interpretModelPayload({
      'action': 'navigate',
      'confidence': 0.9,
      'payload': {'location': '东校区图书馆'},
    }, source: source);

    expect(outcome.action, NoticeAction.navigate);
    expect(outcome.notices.single.action, NoticeAction.navigate);
    expect(outcome.notices.single.location, '东校区图书馆');
    expect(Validators.confirmBlocker(outcome.notices.single), isNull);
  });

  test('does not manufacture a pending item when target is absent', () {
    final outcome = ParserService().interpretModelPayload({
      'action': 'unknown',
      'confidence': 0.2,
      'target_found': false,
      'payload': {'answer': '没有识别到校园事项'},
    }, source: source);

    expect(outcome.action, NoticeAction.unknown);
    expect(outcome.notices, isEmpty);
    expect(outcome.feedback, '没有识别到校园事项');
  });

  test('blocks an expired event before it reaches the system calendar', () {
    final notice = ParsedNotice(
      id: 'expired',
      title: '已经结束的活动',
      eventType: '活动',
      startTimeIso: '2000-01-01T09:00:00',
      source: source,
      createdAtIso: '2000-01-01T08:00:00',
    );

    expect(Validators.confirmBlocker(notice), '事项时间已经过期，请核对后再确认');
  });

  test('splits independent inline schedules for real secondary parsing', () {
    final segments = NoticeSegmentExtractor.extractIndependentScheduleSegments(
      '志愿服务安排：周二12点院楼集合，周三11点图书馆读书会',
    );

    expect(segments, hasLength(2));
    expect(segments.first, contains('周二12点'));
    expect(segments.last, contains('周三11点'));
  });
}
