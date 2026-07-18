import 'package:flutter_test/flutter_test.dart';
import 'package:timeweaver_flutter/models/event_item.dart';
import 'package:timeweaver_flutter/models/parsed_notice.dart';
import 'package:timeweaver_flutter/models/source_info.dart';
import 'package:timeweaver_flutter/services/schedule_intelligence_service.dart';

void main() {
  const service = ScheduleIntelligenceService();
  const source = SourceInfo(
    type: SourceType.manualText,
    rawText: '人工智能讲座 7月20日上午九点在图书馆举行',
  );

  ParsedNotice notice({
    String id = 'notice',
    String title = '人工智能讲座',
    String? time = '2026-07-20T09:00:00',
    String action = NoticeAction.createEvent,
    String? location = '图书馆',
  }) {
    return ParsedNotice(
      id: id,
      title: title,
      eventType: '讲座',
      startTimeIso: time,
      location: location,
      action: action,
      source: source,
      createdAtIso: '2026-07-18T08:00:00',
    );
  }

  EventItem event({
    String id = 'event',
    String title = '人工智能讲座',
    String time = '2026-07-20T09:00:00',
  }) {
    return EventItem(
      id: id,
      title: title,
      eventType: '讲座',
      startTimeIso: time,
      source: source,
      status: '已加入时间线',
      createdAtIso: '2026-07-18T08:00:00',
      updatedAtIso: '2026-07-18T08:00:00',
    );
  }

  test('recognizes the same title and exact minute as a real duplicate', () {
    final duplicate = service.findConfirmedDuplicate(
      notice(title: ' 人工智能 讲座 '),
      [event(title: '人工智能讲座！')],
    );

    expect(duplicate?.id, 'event');
  });

  test('does not collapse different dates or similarly named events', () {
    expect(
      service.findConfirmedDuplicate(notice(time: '2026-07-21T09:00:00'), [
        event(),
      ]),
      isNull,
    );
    expect(
      service.findConfirmedDuplicate(notice(title: '人工智能竞赛'), [event()]),
      isNull,
    );
  });

  test(
    'deduplicates incomplete results only when real source text matches',
    () {
      final duplicate = service.findPendingDuplicate(
        notice(id: 'second', title: '', time: null),
        [notice(id: 'first', title: '', time: null)],
      );

      expect(duplicate?.id, 'first');
    },
  );

  test('allows an existing event to be updated by its original id', () {
    final duplicate = service.findConfirmedDuplicate(notice(id: 'event'), [
      event(),
    ], excludingEventId: 'event');

    expect(duplicate, isNull);
  });

  test('recognizes repeated navigation only by an exact normalized place', () {
    final duplicate = service.findPendingDuplicate(
      notice(
        id: 'second',
        title: '',
        time: null,
        action: NoticeAction.navigate,
        location: ' 东校区图书馆 ',
      ),
      [
        notice(
          id: 'first',
          title: '',
          time: null,
          action: NoticeAction.navigate,
          location: '东校区图书馆',
        ),
      ],
    );

    expect(duplicate?.id, 'first');
  });
}
