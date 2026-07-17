import 'package:flutter_test/flutter_test.dart';
import 'package:timeweaver_flutter/models/event_item.dart';
import 'package:timeweaver_flutter/models/parsed_notice.dart';
import 'package:timeweaver_flutter/models/source_info.dart';
import 'package:timeweaver_flutter/pages/review_logic.dart';

void main() {
  test('review promotes a completed clarification to a real event', () {
    expect(
      reviewedNoticeAction(
        currentAction: NoticeAction.clarification,
        title: '人工智能前沿讲座',
        startTimeIso: '2026-08-18T19:00:00',
      ),
      NoticeAction.createEvent,
    );
    expect(
      reviewedNoticeAction(
        currentAction: NoticeAction.clarification,
        title: '人工智能前沿讲座',
        startTimeIso: null,
      ),
      NoticeAction.clarification,
    );
  });

  const source = SourceInfo(type: SourceType.manualText);

  ParsedNotice notice({
    String action = NoticeAction.createEvent,
    String title = '讲座',
    String? time = '2026-07-20T09:00:00',
    String? location = '教一',
    double confidence = 0.9,
    String? fallbackQuery,
  }) {
    return ParsedNotice(
      id: 'n1',
      title: title,
      eventType: '校园安排',
      startTimeIso: time,
      location: location,
      confidence: confidence,
      fallbackQuery: fallbackQuery,
      action: action,
      source: source,
      createdAtIso: '2026-07-01T08:00:00',
    );
  }

  test(
    'review validation mirrors Android required fields and expiry grace',
    () {
      final issues = buildReviewValidationIssues(
        notice(title: '', time: '2026-07-16T09:45:00', location: null),
        now: DateTime(2026, 7, 16, 10),
      );

      expect(issues, ['missing title']);
    },
  );

  test('review create event does not require location', () {
    expect(buildReviewValidationIssues(notice(location: null)), isEmpty);
  });

  test('review prompt uses Android clarification wording', () {
    final draft = notice(title: '', time: null);
    final issues = buildReviewValidationIssues(draft);

    expect(buildReviewPrompt(draft, issues), '我还不能确定这是什么活动，请换个角度重拍，或直接补充活动名称。');
  });

  test('review conflict label mirrors Android reason and window label', () {
    final event = EventItem(
      id: 'e1',
      title: '高数课',
      eventType: '校园安排',
      startTimeIso: '2026-07-20T09:30:00',
      source: source,
      createdAtIso: '2026-07-01T08:00:00',
      updatedAtIso: '2026-07-01T08:00:00',
    );

    expect(
      buildReviewConflictLabel(event, DateTime(2026, 7, 20, 10)),
      '同一天已有安排 路 09:30 · 高数课',
    );
  });
}
