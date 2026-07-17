import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timeweaver_flutter/models/event_item.dart';
import 'package:timeweaver_flutter/models/reminder_item.dart';
import 'package:timeweaver_flutter/models/parsed_notice.dart';
import 'package:timeweaver_flutter/models/source_info.dart';
import 'package:timeweaver_flutter/pages/timeline_logic.dart';
import 'package:timeweaver_flutter/utils/date_utils.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('zh_CN');
  });

  test('ZhishiDateUtils parses Android-style month-day time text', () {
    final parsed = ZhishiDateUtils.parse('7月3日 14:20');

    expect(parsed, isNotNull);
    expect(parsed!.month, 7);
    expect(parsed.day, 3);
    expect(parsed.hour, 14);
    expect(parsed.minute, 20);
  });

  test('timeline groups and filters events by selected mode', () {
    final source = SourceInfo(type: SourceType.manualText);
    final events = [
      EventItem(
        id: 'a',
        title: '本周事项',
        eventType: '校园安排',
        startTimeIso: '2026-07-06 09:00',
        source: source,
        createdAtIso: '2026-07-01T08:00:00',
        updatedAtIso: '2026-07-01T08:00:00',
      ),
      EventItem(
        id: 'b',
        title: '同周事项',
        eventType: '校园安排',
        startTimeIso: '2026-07-08 15:00',
        source: source,
        createdAtIso: '2026-07-01T08:00:00',
        updatedAtIso: '2026-07-01T08:00:00',
      ),
      EventItem(
        id: 'c',
        title: '下月事项',
        eventType: '校园安排',
        startTimeIso: '2026-08-02 10:00',
        source: source,
        createdAtIso: '2026-07-01T08:00:00',
        updatedAtIso: '2026-07-01T08:00:00',
      ),
    ];

    final grouped = groupEventsByDay(events);
    final weekly = buildVisibleBuckets(
      groupedItems: grouped,
      activeMode: TimelineMode.week,
      activeDate: DateTime(2026, 7, 6),
      activeMonth: DateTime(2026, 7),
    );
    final monthly = buildVisibleBuckets(
      groupedItems: grouped,
      activeMode: TimelineMode.month,
      activeDate: DateTime(2026, 7, 6),
      activeMonth: DateTime(2026, 7),
    );

    expect(weekly.length, 2);
    expect(monthly.length, 2);
    expect(monthly.expand((item) => item.items).map((item) => item.id), [
      'a',
      'b',
    ]);
  });

  test('timeline detail helpers preserve reminder summary and export time', () {
    final event = EventItem(
      id: 'a',
      title: '汇报',
      eventType: '校园安排',
      startTimeIso: '2026-07-10 18:30',
      source: const SourceInfo(type: SourceType.manualText),
      reminders: const [
        ReminderItem(
          id: 'r1',
          eventId: 'a',
          label: '提前1天',
          minutesBefore: 1440,
        ),
        ReminderItem(id: 'r2', eventId: 'a', label: '提前1小时', minutesBefore: 60),
      ],
      createdAtIso: '2026-07-01T08:00:00',
      updatedAtIso: '2026-07-01T08:00:00',
    );

    expect(eventReminderSummary(event), '提前1天 / 提前1小时');
    expect(eventExportTimeLabel(event), '2026-07-10 18:30');
    expect(eventDisplayTimeLabel(event), '18:30');
  });

  test('timeline follows Android ordering when finding the next event', () {
    final source = const SourceInfo(type: SourceType.manualText);
    EventItem event(String id, String time) => EventItem(
      id: id,
      title: id,
      eventType: '校园安排',
      startTimeIso: time,
      source: source,
      createdAtIso: '2026-07-01T08:00:00',
      updatedAtIso: '2026-07-01T08:00:00',
    );

    final next = findNextTimelineEvent([
      event('later', '2026-07-20 09:00'),
      event('next', '2026-07-18 09:00'),
    ], now: DateTime(2026, 7, 17));

    expect(next?.id, 'next');
  });

  test('timeline month matrix uses the Android Monday-first offset', () {
    final matrix = timelineMonthMatrix(DateTime(2026, 7));

    expect(matrix.take(2), everyElement(isNull));
    expect(matrix[2], DateTime(2026, 7, 1));
  });

  test('timeline pending prompt matches Android confirmation wording', () {
    final notice = ParsedNotice(
      id: 'n1',
      title: '毕业答辩',
      eventType: '校园安排',
      startTimeIso: '2026-07-20 09:00',
      location: '教一 101',
      source: const SourceInfo(type: SourceType.manualText),
      createdAtIso: '2026-07-01T08:00:00',
    );

    expect(
      buildTimelinePendingPrompt(notice),
      '识别到校园日程：毕业答辩，时间 2026-07-20 09:00，地点 教一 101。'
      '是否织入你的专属时间线？',
    );
  });

  test(
    'timeline edit preserves blank fields and Android status transition',
    () {
      final original = EventItem(
        id: 'a',
        title: '原标题',
        eventType: '校园安排',
        startTimeIso: '2026-07-10 18:30',
        location: '图书馆',
        description: '原摘要',
        status: '待确认',
        source: const SourceInfo(type: SourceType.manualText),
        createdAtIso: '2026-07-01T08:00:00',
        updatedAtIso: '2026-07-01T08:00:00',
      );

      final edited = buildEditedTimelineEvent(
        original: original,
        title: ' ',
        time: ' ',
        location: ' ',
        summary: ' ',
        updatedAt: DateTime(2026, 7, 2),
      );

      expect(edited.title, '原标题');
      expect(edited.location, '图书馆');
      expect(edited.description, '原摘要');
      expect(edited.status, '待校验');
    },
  );
}
