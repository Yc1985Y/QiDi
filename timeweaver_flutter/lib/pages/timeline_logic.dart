import 'package:intl/intl.dart';

import '../models/event_item.dart';
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
  final firstOffset = firstDay.weekday % 7;
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
