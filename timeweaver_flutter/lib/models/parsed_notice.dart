import 'source_info.dart';

class ParsedNotice {
  const ParsedNotice({
    required this.id,
    required this.title,
    required this.eventType,
    required this.source,
    required this.createdAtIso,
    this.startTimeIso,
    this.deadlineIso,
    this.location,
    this.description,
    this.confidence = 0.0,
    this.reminderSuggestion = '提前1天 / 提前1小时',
    this.rawPayload,
    this.status = '待确认',
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
  final String reminderSuggestion;
  final String? rawPayload;
  final String status;
  final String createdAtIso;

  ParsedNotice copyWith({
    String? id,
    String? title,
    String? eventType,
    String? startTimeIso,
    String? deadlineIso,
    String? location,
    String? description,
    SourceInfo? source,
    double? confidence,
    String? reminderSuggestion,
    String? rawPayload,
    String? status,
    String? createdAtIso,
  }) {
    return ParsedNotice(
      id: id ?? this.id,
      title: title ?? this.title,
      eventType: eventType ?? this.eventType,
      startTimeIso: startTimeIso ?? this.startTimeIso,
      deadlineIso: deadlineIso ?? this.deadlineIso,
      location: location ?? this.location,
      description: description ?? this.description,
      source: source ?? this.source,
      confidence: confidence ?? this.confidence,
      reminderSuggestion: reminderSuggestion ?? this.reminderSuggestion,
      rawPayload: rawPayload ?? this.rawPayload,
      status: status ?? this.status,
      createdAtIso: createdAtIso ?? this.createdAtIso,
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
      'reminderSuggestion': reminderSuggestion,
      'rawPayload': rawPayload,
      'status': status,
      'createdAtIso': createdAtIso,
    };
  }

  factory ParsedNotice.fromJson(Map<String, dynamic> json) {
    return ParsedNotice(
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
      reminderSuggestion:
          json['reminderSuggestion'] as String? ?? '提前1天 / 提前1小时',
      rawPayload: json['rawPayload'] as String?,
      status: json['status'] as String? ?? '待确认',
      createdAtIso:
          json['createdAtIso'] as String? ?? DateTime.now().toIso8601String(),
    );
  }
}
