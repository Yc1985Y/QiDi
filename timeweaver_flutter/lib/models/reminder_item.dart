class ReminderItem {
  const ReminderItem({
    required this.id,
    required this.eventId,
    required this.label,
    required this.minutesBefore,
    this.scheduledAtIso,
    this.notificationId,
    this.enabled = true,
  });

  final String id;
  final String eventId;
  final String label;
  final int minutesBefore;
  final String? scheduledAtIso;
  final int? notificationId;
  final bool enabled;

  ReminderItem copyWith({
    String? id,
    String? eventId,
    String? label,
    int? minutesBefore,
    String? scheduledAtIso,
    int? notificationId,
    bool? enabled,
  }) {
    return ReminderItem(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      label: label ?? this.label,
      minutesBefore: minutesBefore ?? this.minutesBefore,
      scheduledAtIso: scheduledAtIso ?? this.scheduledAtIso,
      notificationId: notificationId ?? this.notificationId,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'label': label,
      'minutesBefore': minutesBefore,
      'scheduledAtIso': scheduledAtIso,
      'notificationId': notificationId,
      'enabled': enabled,
    };
  }

  factory ReminderItem.fromJson(Map<String, dynamic> json) {
    return ReminderItem(
      id: json['id'] as String,
      eventId: json['eventId'] as String,
      label: json['label'] as String,
      minutesBefore: (json['minutesBefore'] as num).toInt(),
      scheduledAtIso: json['scheduledAtIso'] as String?,
      notificationId: (json['notificationId'] as num?)?.toInt(),
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}
