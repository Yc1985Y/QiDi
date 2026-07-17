import 'dart:io';

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
    return openLocation(location);
  }

  Future<bool> openLocation(String location) async {
    final normalized = location.trim();
    if (normalized.isEmpty) return false;
    if (Platform.isAndroid) {
      final nativeUri = Uri.parse(
        'geo:0,0?q=${Uri.encodeComponent(normalized)}',
      );
      if (await launchUrl(nativeUri, mode: LaunchMode.externalApplication)) {
        return true;
      }
      return launchUrl(
        Uri.https('www.google.com', '/maps/search/', {
          'api': '1',
          'query': normalized,
        }),
        mode: LaunchMode.externalApplication,
      );
    }
    final uri = Platform.isIOS
        ? Uri.https('maps.apple.com', '/', {'q': normalized})
        : Uri.https('www.google.com', '/maps/search/', {
            'api': '1',
            'query': normalized,
          });
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> shareEvent(EventItem event) async {
    await SharePlus.instance.share(
      ShareParams(subject: '分享织时时间线', text: buildShareText(event)),
    );
  }

  Future<void> copyEvent(EventItem event) async {
    await Clipboard.setData(ClipboardData(text: buildShareText(event)));
  }

  String buildShareText(EventItem event) {
    final title = event.title.trim().isEmpty ? '未命名事项' : event.title.trim();
    final location = event.location?.trim().isNotEmpty == true
        ? event.location!.trim()
        : '地点待补充';
    final reminderSummary = event.reminders
        .map((reminder) => reminder.label.trim())
        .where((label) => label.isNotEmpty)
        .join(' / ');
    return [
      '来自《织时》的校园日程',
      '事项：$title',
      '时间：${ZhishiDateUtils.formatDateTime(event.startTimeIso ?? event.deadlineIso)}',
      '地点：$location',
      '提醒：${reminderSummary.isEmpty ? '未设置' : reminderSummary}',
      if (event.description != null && event.description!.trim().isNotEmpty)
        '摘要：${event.description!.trim()}',
    ].join('\n');
  }
}

class CalendarIntegrationException implements Exception {
  const CalendarIntegrationException(this.message);

  final String message;

  @override
  String toString() => message;
}
