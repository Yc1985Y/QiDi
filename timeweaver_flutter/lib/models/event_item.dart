import 'parsed_notice.dart';
import 'reminder_item.dart';
import 'source_info.dart';
import 'user_preference.dart';
import '../utils/date_utils.dart';

class EventItem {
  const EventItem({
    required this.id,
    required this.title,
    required this.eventType,
    required this.source,
    required this.createdAtIso,
    required this.updatedAtIso,
    this.ownerAccount = '',
    this.startTimeIso,
    this.deadlineIso,
    this.location,
    this.description,
    this.confidence = 0.0,
    this.status = '已加入时间线',
    this.reminders = const [],
  });

  final String id;
  final String title;
  final String eventType;
  final String? startTimeIso;
  final String? deadlineIso;
  final String? location;
  final String? description;
  final SourceInfo source;
  final double confidence;
  final String status;
  final List<ReminderItem> reminders;
  final String createdAtIso;
  final String updatedAtIso;
  final String ownerAccount;

  DateTime? get startTime =>
      startTimeIso == null ? null : ZhishiDateUtils.parse(startTimeIso!);

  DateTime? get deadline =>
      deadlineIso == null ? null : ZhishiDateUtils.parse(deadlineIso!);

  bool get isConfirmed => status.contains('已加入') || status.contains('已确认');

  EventItem copyWith({
    String? id,
    String? title,
    String? eventType,
    String? startTimeIso,
    String? deadlineIso,
    String? location,
    String? description,
    SourceInfo? source,
    double? confidence,
    String? status,
    List<ReminderItem>? reminders,
    String? createdAtIso,
    String? updatedAtIso,
    String? ownerAccount,
  }) {
    return EventItem(
      id: id ?? this.id,
      title: title ?? this.title,
      eventType: eventType ?? this.eventType,
      startTimeIso: startTimeIso ?? this.startTimeIso,
      deadlineIso: deadlineIso ?? this.deadlineIso,
      location: location ?? this.location,
      description: description ?? this.description,
      source: source ?? this.source,
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
      reminders: reminders ?? this.reminders,
      createdAtIso: createdAtIso ?? this.createdAtIso,
      updatedAtIso: updatedAtIso ?? this.updatedAtIso,
      ownerAccount: ownerAccount ?? this.ownerAccount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'eventType': eventType,
      'startTimeIso': startTimeIso,
      'deadlineIso': deadlineIso,
      'location': location,
      'description': description,
      'source': source.toJson(),
      'confidence': confidence,
      'status': status,
      'reminders': reminders.map((item) => item.toJson()).toList(),
      'createdAtIso': createdAtIso,
      'updatedAtIso': updatedAtIso,
      'ownerAccount': ownerAccount,
    };
  }

  factory EventItem.fromJson(Map<String, dynamic> json) {
    return EventItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? '新的校园事项',
      eventType: json['eventType'] as String? ?? '校园安排',
      startTimeIso: json['startTimeIso'] as String?,
      deadlineIso: json['deadlineIso'] as String?,
      location: json['location'] as String?,
      description: json['description'] as String?,
      source: SourceInfo.fromJson(
        Map<String, dynamic>.from(json['source'] as Map),
      ),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? '已加入时间线',
      reminders: (json['reminders'] as List<dynamic>? ?? [])
          .map((item) => ReminderItem.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      createdAtIso:
          json['createdAtIso'] as String? ?? DateTime.now().toIso8601String(),
      updatedAtIso:
          json['updatedAtIso'] as String? ?? DateTime.now().toIso8601String(),
      ownerAccount: json['ownerAccount'] as String? ?? '',
    );
  }

  factory EventItem.fromParsedNotice(
    ParsedNotice notice,
    UserPreference preference,
    String ownerAccount,
  ) {
    final nowIso = DateTime.now().toIso8601String();
    final reminders = <ReminderItem>[
      if (preference.dayReminderEnabled)
        ReminderItem(
          id: '${notice.id}-1440',
          eventId: notice.id,
          label: '提前1天',
          minutesBefore: 24 * 60,
        ),
      if (preference.hourReminderEnabled)
        ReminderItem(
          id: '${notice.id}-${preference.reminderLeadMinutes}',
          eventId: notice.id,
          label: preference.reminderLeadMinutes == 60
              ? '提前1小时'
              : '提前${preference.reminderLeadMinutes}分钟',
          minutesBefore: preference.reminderLeadMinutes,
        ),
    ];

    return EventItem(
      id: notice.id,
      title: notice.title.trim(),
      eventType: notice.eventType,
      startTimeIso: notice.startTimeIso,
      deadlineIso: notice.deadlineIso,
      location: notice.location,
      description: notice.description,
      source: notice.source,
      confidence: notice.confidence,
      reminders: reminders,
      createdAtIso: notice.createdAtIso,
      updatedAtIso: nowIso,
      ownerAccount: ownerAccount,
    );
  }
}
