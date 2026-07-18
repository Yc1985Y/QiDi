import '../models/event_item.dart';
import '../models/parsed_notice.dart';
import '../utils/date_utils.dart';

class ScheduleIntelligenceService {
  const ScheduleIntelligenceService();

  ParsedNotice? findPendingDuplicate(
    ParsedNotice candidate,
    Iterable<ParsedNotice> pending,
  ) {
    for (final existing in pending) {
      if (existing.id == candidate.id) continue;
      if (noticesRepresentSameAction(candidate, existing)) return existing;
    }
    return null;
  }

  EventItem? findConfirmedDuplicate(
    ParsedNotice candidate,
    Iterable<EventItem> events, {
    String? excludingEventId,
  }) {
    if (candidate.action != NoticeAction.createEvent) return null;
    for (final event in events) {
      if (event.id == excludingEventId || !event.isConfirmed) continue;
      if (_sameEvent(candidate, event)) return event;
    }
    return null;
  }

  bool noticesRepresentSameAction(ParsedNotice left, ParsedNotice right) {
    if (left.action != right.action) return false;
    if (left.action == NoticeAction.navigate) {
      final leftLocation = _normalizeText(left.location);
      return leftLocation.isNotEmpty &&
          leftLocation == _normalizeText(right.location);
    }
    if (left.action != NoticeAction.createEvent &&
        left.action != NoticeAction.clarification) {
      return false;
    }
    return _sameTitleAndTime(
          left.title,
          left.startTimeIso ?? left.deadlineIso,
          right.title,
          right.startTimeIso ?? right.deadlineIso,
        ) ||
        _sameIncompleteSource(left, right);
  }

  bool _sameEvent(ParsedNotice notice, EventItem event) {
    return _sameTitleAndTime(
      notice.title,
      notice.startTimeIso ?? notice.deadlineIso,
      event.title,
      event.startTimeIso ?? event.deadlineIso,
    );
  }

  bool _sameTitleAndTime(
    String leftTitle,
    String? leftTime,
    String rightTitle,
    String? rightTime,
  ) {
    final normalizedTitle = _normalizeText(leftTitle);
    if (normalizedTitle.isEmpty ||
        normalizedTitle != _normalizeText(rightTitle)) {
      return false;
    }
    final parsedLeft = ZhishiDateUtils.parse(leftTime);
    final parsedRight = ZhishiDateUtils.parse(rightTime);
    if (parsedLeft == null || parsedRight == null) return false;
    return parsedLeft.year == parsedRight.year &&
        parsedLeft.month == parsedRight.month &&
        parsedLeft.day == parsedRight.day &&
        parsedLeft.hour == parsedRight.hour &&
        parsedLeft.minute == parsedRight.minute;
  }

  bool _sameIncompleteSource(ParsedNotice left, ParsedNotice right) {
    final leftTime = ZhishiDateUtils.parse(
      left.startTimeIso ?? left.deadlineIso,
    );
    final rightTime = ZhishiDateUtils.parse(
      right.startTimeIso ?? right.deadlineIso,
    );
    if (leftTime != null || rightTime != null) return false;
    final leftRaw = _normalizeSource(left.source.rawText);
    final rightRaw = _normalizeSource(right.source.rawText);
    return leftRaw.isNotEmpty && leftRaw == rightRaw;
  }

  String _normalizeText(String? value) {
    return (value ?? '').trim().toLowerCase().replaceAll(
      RegExp(r'''[\s\u3000，。！？、；：,.!?;:（）()【】\[\]“”"'《》<>·…—_-]+'''),
      '',
    );
  }

  String _normalizeSource(String? value) {
    return (value ?? '').trim().replaceAll(RegExp(r'\s+'), ' ');
  }
}
