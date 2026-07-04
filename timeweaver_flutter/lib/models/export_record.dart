class ExportRecord {
  const ExportRecord({
    required this.id,
    required this.format,
    required this.path,
    required this.bytes,
    required this.eventCount,
    required this.createdAtMillis,
    this.ownerAccount = '',
  });

  final String id;
  final String format;
  final String path;
  final int bytes;
  final int eventCount;
  final int createdAtMillis;
  final String ownerAccount;

  ExportRecord copyWith({
    String? id,
    String? format,
    String? path,
    int? bytes,
    int? eventCount,
    int? createdAtMillis,
    String? ownerAccount,
  }) {
    return ExportRecord(
      id: id ?? this.id,
      format: format ?? this.format,
      path: path ?? this.path,
      bytes: bytes ?? this.bytes,
      eventCount: eventCount ?? this.eventCount,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      ownerAccount: ownerAccount ?? this.ownerAccount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'format': format,
      'path': path,
      'bytes': bytes,
      'eventCount': eventCount,
      'createdAtMillis': createdAtMillis,
      'ownerAccount': ownerAccount,
    };
  }

  factory ExportRecord.fromJson(Map<String, dynamic> json) {
    return ExportRecord(
      id: json['id'] as String,
      format: json['format'] as String? ?? 'PDF',
      path: json['path'] as String? ?? '',
      bytes: (json['bytes'] as num?)?.toInt() ?? 0,
      eventCount: (json['eventCount'] as num?)?.toInt() ?? 0,
      createdAtMillis:
          (json['createdAtMillis'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      ownerAccount: json['ownerAccount'] as String? ?? '',
    );
  }
}
