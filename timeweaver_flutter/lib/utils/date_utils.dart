import 'package:intl/intl.dart';

class ZhishiDateUtils {
  static final DateFormat _full = DateFormat('yyyy年M月d日 HH:mm', 'zh_CN');
  static final DateFormat _day = DateFormat('M月d日 EEEE', 'zh_CN');
  static final DateFormat _time = DateFormat('HH:mm', 'zh_CN');

  static String formatDateTime(String? iso) {
    final date = parse(iso);
    if (date == null) return '待补充';
    return _full.format(date);
  }

  static String formatDay(DateTime date) => _day.format(date);

  static String formatTime(DateTime date) => _time.format(date);

  static DateTime? parse(String? iso) {
    if (iso == null || iso.trim().isEmpty) return null;
    return DateTime.tryParse(iso.replaceFirst(' ', 'T'));
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
}
