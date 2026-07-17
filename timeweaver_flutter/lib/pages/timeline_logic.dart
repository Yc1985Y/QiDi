import 'package:intl/intl.dart';

import '../models/event_item.dart';
import '../models/parsed_notice.dart';
import '../utils/date_utils.dart';

enum TimelineMode { day, week, month }

extension TimelineModeExtension on TimelineMode {
  String get key => switch (this) {
    TimelineMode.day => 'day',
    TimelineMode.week => 'week',
    TimelineMode.month => 'month',
  };

  String get label => switch (this) {
    TimelineMode.day => '本日',
    TimelineMode.week => '本周',
    TimelineMode.month => '本月',
  };
}

class TimelineDayBucket {
  const TimelineDayBucket({required this.date, required this.items});

  final DateTime date;
  final List<EventItem> items;
}

List<TimelineDayBucket> groupEventsByDay(List<EventItem> items) {
  final grouped = <DateTime, List<EventItem>>{};
  for (final item in items) {
    final scheduled = timelineScheduleTime(item);
    if (scheduled == null) continue;
    final key = DateTime(scheduled.year, scheduled.month, scheduled.day);
    grouped.putIfAbsent(key, () => []).add(item);
  }
  final entries = grouped.entries.toList()
    ..sort((left, right) => left.key.compareTo(right.key));
  return entries
      .map(
        (entry) => TimelineDayBucket(
          date: entry.key,
          items: [...entry.value]
            ..sort((left, right) {
              final leftTime = timelineScheduleTime(left) ?? DateTime(9999);
              final rightTime = timelineScheduleTime(right) ?? DateTime(9999);
              return leftTime.compareTo(rightTime);
            }),
        ),
      )
      .toList();
}

DateTime? timelineScheduleTime(EventItem item) {
  return item.startTime ?? item.deadline;
}

List<TimelineDayBucket> buildVisibleBuckets({
  required List<TimelineDayBucket> groupedItems,
  required TimelineMode activeMode,
  required DateTime activeDate,
  required DateTime activeMonth,
}) {
  return switch (activeMode) {
    TimelineMode.day =>
      groupedItems.where((item) => _isSameDay(item.date, activeDate)).toList(),
    TimelineMode.month =>
      groupedItems
          .where(
            (item) =>
                item.date.year == activeMonth.year &&
                item.date.month == activeMonth.month,
          )
          .toList(),
    TimelineMode.week =>
      groupedItems
          .where(
            (item) => timelineWeekWindow(
              activeDate,
            ).any((date) => _isSameDay(item.date, date)),
          )
          .toList(),
  };
}

List<DateTime> timelineWeekWindow(DateTime anchor) {
  final start = anchor.subtract(Duration(days: anchor.weekday - 1));
  return List<DateTime>.generate(
    7,
    (index) => DateTime(start.year, start.month, start.day + index),
  );
}

List<DateTime?> timelineMonthMatrix(DateTime month) {
  final firstDay = DateTime(month.year, month.month, 1);
  final firstOffset = (firstDay.weekday + 6) % 7;
  final totalDays = DateTime(month.year, month.month + 1, 0).day;
  final cells = <DateTime?>[];
  for (var index = 0; index < firstOffset; index++) {
    cells.add(null);
  }
  for (var day = 1; day <= totalDays; day++) {
    cells.add(DateTime(month.year, month.month, day));
  }
  while (cells.length % 7 != 0) {
    cells.add(null);
  }
  return cells;
}

EventItem? findNextTimelineEvent(List<EventItem> items, {DateTime? now}) {
  final ordered = [...items]
    ..sort((left, right) {
      final leftTime = timelineScheduleTime(left) ?? DateTime(9999);
      final rightTime = timelineScheduleTime(right) ?? DateTime(9999);
      return leftTime.compareTo(rightTime);
    });
  final reference = now ?? DateTime.now();
  for (final item in ordered) {
    final schedule = timelineScheduleTime(item) ?? DateTime(9999);
    if (!schedule.isBefore(reference)) return item;
  }
  return ordered.firstOrNull;
}

String buildTimelinePendingPrompt(ParsedNotice notice) {
  final fallbackQuery = notice.fallbackQuery?.trim() ?? '';
  if (fallbackQuery.isNotEmpty) return fallbackQuery;
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

EventItem buildEditedTimelineEvent({
  required EventItem original,
  required String title,
  required String time,
  required String location,
  required String summary,
  DateTime? updatedAt,
}) {
  final cleanTitle = title.trim().isEmpty ? original.title : title.trim();
  final originalTime = original.startTimeIso ?? original.deadlineIso ?? '';
  final cleanTime = time.trim().isEmpty ? originalTime : time.trim();
  final cleanLocation = location.trim().isEmpty
      ? (original.location ?? '')
      : location.trim();
  final cleanSummary = summary.trim().isEmpty
      ? (original.description ?? '')
      : summary.trim();
  final timeChanged = cleanTime != originalTime;
  final normalizedTime = timeChanged
      ? ZhishiDateUtils.parse(cleanTime)?.toIso8601String() ?? originalTime
      : originalTime;
  return original.copyWith(
    title: cleanTitle,
    startTimeIso: normalizedTime,
    location: cleanLocation,
    description: cleanSummary,
    status: original.status.contains('已') ? original.status : '待校验',
    updatedAtIso: (updatedAt ?? DateTime.now()).toIso8601String(),
  );
}

String timelineHeaderTitle([DateTime? now]) {
  return DateFormat('M月d日 HH:mm', 'zh_CN').format(now ?? DateTime.now());
}

String timelineMonthTitle(DateTime month) {
  return DateFormat('yyyy年M月', 'zh_CN').format(month);
}

String timelineDayTitle(DateTime date) {
  return DateFormat('M月d日 EEEE', 'zh_CN').format(date);
}

String eventDisplayTimeLabel(EventItem item) {
  final scheduled = timelineScheduleTime(item);
  if (scheduled == null) return '待补时间';
  final raw = [
    item.startTimeIso,
    item.deadlineIso,
  ].whereType<String>().join(' ').trim();
  if (scheduled.hour == 0 &&
      scheduled.minute == 0 &&
      !ZhishiDateUtils.hasExplicitTime(raw)) {
    return '全天';
  }
  return ZhishiDateUtils.formatTime(scheduled);
}

String eventExportTimeLabel(EventItem item) {
  final scheduled = timelineScheduleTime(item);
  if (scheduled == null) return '待补时间';
  return ZhishiDateUtils.formatExport(scheduled);
}

String eventReminderSummary(EventItem item) {
  if (item.reminders.isEmpty) return '未设置';
  return item.reminders.map((item) => item.label).join(' / ');
}

bool _isSameDay(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

extension _FirstOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
