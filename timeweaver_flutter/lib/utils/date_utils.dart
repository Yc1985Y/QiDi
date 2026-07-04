import 'package:intl/intl.dart';

class ZhishiDateUtils {
  static final DateFormat _full = DateFormat('yyyy年M月d日 HH:mm', 'zh_CN');
  static final DateFormat _day = DateFormat('M月d日 EEEE', 'zh_CN');
  static final DateFormat _time = DateFormat('HH:mm', 'zh_CN');
  static final DateFormat _export = DateFormat('yyyy-MM-dd HH:mm', 'zh_CN');
  static final List<DateFormat> _formatsWithYear = [
    DateFormat('yyyy-MM-dd HH:mm', 'zh_CN'),
    DateFormat('yyyy/M/d HH:mm', 'zh_CN'),
  ];
  static final List<DateFormat> _formatsWithoutYear = [
    DateFormat('yyyy年M月d日 HH:mm', 'zh_CN'),
    DateFormat('yyyy年M月d日 H:mm', 'zh_CN'),
    DateFormat('yyyy年M月d日 HH点mm分', 'zh_CN'),
    DateFormat('yyyy年M月d日 H点m分', 'zh_CN'),
  ];
  static final RegExp _explicitTimePattern = RegExp(r'\d{1,2}(?:[:点时])\d{0,2}');
  static final RegExp _monthDayPattern = RegExp(
    r'(\d{1,2})月(\d{1,2})日(?:\s*(\d{1,2})[:点时](\d{1,2}))?',
  );

  static String formatDateTime(String? iso) {
    final date = parse(iso);
    if (date == null) return '待补充';
    return _full.format(date);
  }

  static String formatDay(DateTime date) => _day.format(date);

  static String formatTime(DateTime date) => _time.format(date);

  static String formatExport(DateTime date) => _export.format(date);

  static DateTime? parse(String? iso) {
    if (iso == null || iso.trim().isEmpty) return null;
    final normalized = iso.trim();
    final direct = DateTime.tryParse(normalized.replaceFirst(' ', 'T'));
    if (direct != null) return direct;

    for (final format in _formatsWithYear) {
      try {
        return format.parseStrict(normalized);
      } catch (_) {
        // Try the next pattern.
      }
    }

    final withCurrentYear = '${DateTime.now().year}年$normalized';
    for (final format in _formatsWithoutYear) {
      try {
        return format.parseStrict(withCurrentYear);
      } catch (_) {
        // Try the next pattern.
      }
    }

    final match = _monthDayPattern.firstMatch(normalized);
    if (match == null) return null;
    final month = int.tryParse(match.group(1) ?? '');
    final day = int.tryParse(match.group(2) ?? '');
    final hour = int.tryParse(match.group(3) ?? '') ?? 9;
    final minute = int.tryParse(match.group(4) ?? '') ?? 0;
    if (month == null || day == null) return null;
    try {
      return DateTime(DateTime.now().year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  static bool isToday(String? iso) {
    final date = parse(iso);
    if (date == null) return false;
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static String relativeReminder(DateTime triggerAt) {
    final minutes = triggerAt.difference(DateTime.now()).inMinutes;
    if (minutes <= 0) return '即将提醒';
    if (minutes < 60) return '$minutes 分钟后提醒';
    if (minutes < 24 * 60) return '${minutes ~/ 60} 小时后提醒';
    return '${minutes ~/ (24 * 60)} 天后提醒';
  }

  static bool hasExplicitTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return false;
    return _explicitTimePattern.hasMatch(raw);
  }
}
