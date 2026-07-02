import 'package:add_2_calendar/add_2_calendar.dart' as calendar;
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/event_item.dart';
import '../utils/date_utils.dart';

class IntegrationService {
  Future<bool> addEventToCalendar(EventItem event) async {
    final start = event.startTime;
    if (start == null) {
      throw const CalendarIntegrationException('事项缺少可识别的开始时间，无法打开系统日历');
    }
    final end = event.deadline?.isAfter(start) == true
        ? event.deadline!
        : start.add(const Duration(hours: 1));
    final added = await calendar.Add2Calendar.addEvent2Cal(
      calendar.Event(
        title: event.title,
        description: event.description ?? buildShareText(event),
        location: event.location,
        startDate: start,
        endDate: end,
        timeZone: 'Asia/Shanghai',
        iosParams: const calendar.IOSParams(reminder: Duration(hours: 1)),
      ),
    );
    if (!added) {
      throw const CalendarIntegrationException('系统日历没有确认本次添加');
    }
    return added;
  }

  Future<bool> openMap(EventItem event) async {
    final location = event.location?.trim();
    if (location == null || location.isEmpty) return false;
    final uri = Uri.parse(
      'https://maps.apple.com/?q=${Uri.encodeComponent(location)}',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> shareEvent(EventItem event) async {
    await SharePlus.instance.share(ShareParams(text: buildShareText(event)));
  }

  Future<void> copyEvent(EventItem event) async {
    await Clipboard.setData(ClipboardData(text: buildShareText(event)));
  }

  String buildShareText(EventItem event) {
    return [
      '【织时事项】${event.title}',
      '类型：${event.eventType}',
      '时间：${ZhishiDateUtils.formatDateTime(event.startTimeIso)}',
      if (event.location != null && event.location!.trim().isNotEmpty)
        '地点：${event.location}',
      if (event.description != null && event.description!.trim().isNotEmpty)
        '说明：${event.description}',
    ].join('\n');
  }
}

class CalendarIntegrationException implements Exception {
  const CalendarIntegrationException(this.message);

  final String message;

  @override
  String toString() => message;
}
