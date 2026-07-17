import '../models/event_item.dart';
import '../models/parsed_notice.dart';

String reviewedNoticeAction({
  required String currentAction,
  required String title,
  required String? startTimeIso,
}) {
  final hasMinimumScheduleFields =
      title.trim().isNotEmpty && (startTimeIso ?? '').trim().isNotEmpty;
  if (currentAction == NoticeAction.clarification && hasMinimumScheduleFields) {
    return NoticeAction.createEvent;
  }
  return currentAction;
}

List<String> buildReviewValidationIssues(ParsedNotice notice, {DateTime? now}) {
  final issues = <String>[];
  switch (notice.action) {
    case NoticeAction.createEvent:
      if (notice.title.trim().isEmpty) issues.add('missing title');
      final rawTime = (notice.startTimeIso ?? '').trim();
      if (rawTime.isEmpty) issues.add('missing time');
      final parsed = _parseAndroidIsoDateTime(rawTime);
      if (rawTime.isNotEmpty &&
          parsed != null &&
          parsed.isBefore(
            (now ?? DateTime.now()).subtract(const Duration(minutes: 30)),
          )) {
        issues.add('time is already expired');
      }
    case NoticeAction.navigate:
      if ((notice.location ?? '').trim().isEmpty) {
        issues.add('missing location');
      }
    case NoticeAction.ttsFeedback:
      if ((notice.description ?? '').trim().isEmpty) {
        issues.add('missing speech text');
      }
    default:
      break;
  }
  return issues;
}

String buildReviewPrompt(ParsedNotice notice, List<String> issues) {
  final fallbackQuery = notice.fallbackQuery?.trim() ?? '';
  if (issues.isNotEmpty) {
    if (fallbackQuery.isNotEmpty) return fallbackQuery;
    if (issues.any((issue) => issue.contains('expired'))) {
      return '识别到的日期已经早于当前时间，可能是过期事项。'
          '请确认输入是否正确，或改成新的安排时间。';
    }
    if (issues.any((issue) => issue.contains('missing title'))) {
      return '我还不能确定这是什么活动，请换个角度重拍，或直接补充活动名称。';
    }
    if (issues.any((issue) => issue.contains('missing time'))) {
      return '我识别到了活动，但没有看清开始时间，请补充完整时间。';
    }
    if (issues.any((issue) => issue.contains('missing location'))) {
      return '我识别到了活动时间，但地点不清晰，请补充地点。';
    }
    return '当前通知信息还不够完整。请调整角度，确保标题、时间和地点都在内容中。';
  }

  if (notice.action == NoticeAction.clarification) {
    return fallbackQuery.isNotEmpty ? fallbackQuery : '我还不够确定，请再补充一点信息。';
  }
  final threshold = notice.action == NoticeAction.ttsFeedback ? 0.5 : 0.7;
  if (notice.confidence < threshold) {
    if (fallbackQuery.isNotEmpty) return fallbackQuery;
    return switch (notice.action) {
      NoticeAction.createEvent =>
        '我识别到了一条可能的校园日程，但还不够确定。'
            '请再靠近海报，或补充活动时间和地点。',
      NoticeAction.navigate => '我识别到了一个可能的校园地点，但还不够稳定。请对准地点文字再试。',
      _ => '当前画面还不够清晰，暂时无法生成稳定结果。请调整角度后重试。',
    };
  }

  return switch (notice.action) {
    NoticeAction.createEvent =>
      '识别到校园日程：${notice.title.trim().isEmpty ? '新的校园日程' : notice.title.trim()}，'
          '时间 ${(notice.startTimeIso ?? '').trim().isEmpty ? '未确认时间' : notice.startTimeIso!.trim()}，'
          '地点 ${(notice.location ?? '').trim().isEmpty ? '无地点' : notice.location!.trim()}。'
          '是否织入你的专属时间线？',
    NoticeAction.navigate =>
      '识别到校园地点：${(notice.location ?? '').trim().isEmpty ? '校园地点' : notice.location!.trim()}。'
          '是否打开地图导航？',
    NoticeAction.ttsFeedback =>
      (notice.description ?? '').trim().isEmpty
          ? '已生成语音反馈。是否继续播报？'
          : notice.description!.trim(),
    _ => '当前结果暂不适合执行，请重试。',
  };
}

String reviewIssueLabel(String issue) {
  if (issue.toLowerCase().contains('expired')) return '日期已过，请确认输入是否正确';
  if (issue.toLowerCase().contains('missing title')) return '缺少事项标题';
  if (issue.toLowerCase().contains('missing time')) return '缺少时间信息';
  if (issue.toLowerCase().contains('missing location')) return '缺少地点信息';
  return issue;
}

bool canConfirmReview(ParsedNotice notice) {
  return switch (notice.action) {
    NoticeAction.createEvent =>
      notice.title.trim().isNotEmpty &&
          (notice.startTimeIso ?? '').trim().isNotEmpty,
    NoticeAction.navigate => (notice.location ?? '').trim().isNotEmpty,
    NoticeAction.clarification || NoticeAction.ttsFeedback => true,
    _ => false,
  };
}

String buildReviewConflictLabel(EventItem event, DateTime targetTime) {
  final eventTime = event.startTime ?? event.deadline;
  if (eventTime == null) return event.title;
  final sameDay =
      eventTime.year == targetTime.year &&
      eventTime.month == targetTime.month &&
      eventTime.day == targetTime.day;
  final reason = sameDay ? '同一天已有安排' : '时间接近已有安排';
  final hour = eventTime.hour.toString().padLeft(2, '0');
  final minute = eventTime.minute.toString().padLeft(2, '0');
  return '$reason 路 $hour:$minute · ${event.title}';
}

DateTime? _parseAndroidIsoDateTime(String value) {
  if (value.isEmpty || !value.contains('T')) return null;
  return DateTime.tryParse(value);
}
