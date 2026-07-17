import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/event_item.dart';
import '../models/reminder_item.dart';
import '../utils/date_utils.dart';

class ReminderService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings: settings);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'campus_schedule_reminders',
            '织时校园提醒',
            description: '织时为讲座、考试、班会等安排生成的本地提醒',
            importance: Importance.high,
          ),
        );
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    await initialize();
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    final android = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    return ios ?? android ?? true;
  }

  Future<List<ReminderItem>> scheduleForEvent(EventItem event) async {
    await initialize();
    final eventTime = event.startTime;
    if (eventTime == null) return event.reminders;
    final scheduled = <ReminderItem>[];
    for (final reminder in event.reminders) {
      final trigger = eventTime.subtract(
        Duration(minutes: reminder.minutesBefore),
      );
      if (!trigger.isAfter(DateTime.now())) {
        scheduled.add(reminder.copyWith(enabled: false));
        continue;
      }
      final notificationId = _notificationId(event.id, reminder.minutesBefore);
      await _plugin.zonedSchedule(
        id: notificationId,
        title: event.title,
        body: _notificationBody(event, reminder),
        scheduledDate: tz.TZDateTime.from(trigger, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'campus_schedule_reminders',
            '织时校园提醒',
            channelDescription: '校园事项本地提醒',
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      scheduled.add(
        reminder.copyWith(
          scheduledAtIso: trigger.toIso8601String(),
          notificationId: notificationId,
          enabled: true,
        ),
      );
    }
    return scheduled;
  }

  Future<void> cancelForEvent(EventItem event) async {
    await initialize();
    for (final reminder in event.reminders) {
      final id =
          reminder.notificationId ??
          _notificationId(event.id, reminder.minutesBefore);
      await _plugin.cancel(id: id);
    }
  }

  String nextReminderSummary(List<EventItem> events) {
    final candidates = <DateTime>[];
    for (final event in events) {
      for (final reminder in event.reminders) {
        final scheduledAt = ZhishiDateUtils.parse(reminder.scheduledAtIso);
        if (scheduledAt != null && scheduledAt.isAfter(DateTime.now())) {
          candidates.add(scheduledAt);
        }
      }
    }
    candidates.sort();
    if (candidates.isEmpty) return '暂无即将触发的提醒';
    return ZhishiDateUtils.relativeReminder(candidates.first);
  }

  int upcomingReminderCount(List<EventItem> events) {
    var count = 0;
    for (final event in events) {
      for (final reminder in event.reminders) {
        final scheduledAt = ZhishiDateUtils.parse(reminder.scheduledAtIso);
        if (scheduledAt != null && scheduledAt.isAfter(DateTime.now())) {
          count++;
        }
      }
    }
    return count;
  }

  String _notificationBody(EventItem event, ReminderItem reminder) {
    final parts = [
      reminder.label,
      ZhishiDateUtils.formatDateTime(event.startTimeIso),
      if (event.location != null && event.location!.trim().isNotEmpty)
        event.location!,
    ];
    return parts.join(' · ');
  }

  int _notificationId(String eventId, int minutesBefore) {
    return '$eventId-$minutesBefore'.hashCode & 0x7fffffff;
  }
}
