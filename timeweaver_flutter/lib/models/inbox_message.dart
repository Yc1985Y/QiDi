class InboxMessage {
  const InboxMessage({
    required this.id,
    required this.type,
    required this.title,
    required this.summary,
    required this.createdAtMillis,
    this.status = '未读',
    this.ownerAccount = '',
  });

  final String id;
  final String type;
  final String title;
  final String summary;
  final String status;
  final int createdAtMillis;
  final String ownerAccount;

  InboxMessage copyWith({
    String? id,
    String? type,
    String? title,
    String? summary,
    String? status,
    int? createdAtMillis,
    String? ownerAccount,
  }) {
    return InboxMessage(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      status: status ?? this.status,
      createdAtMillis: createdAtMillis ?? this.createdAtMillis,
      ownerAccount: ownerAccount ?? this.ownerAccount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'summary': summary,
      'status': status,
      'createdAtMillis': createdAtMillis,
      'ownerAccount': ownerAccount,
    };
  }

  factory InboxMessage.fromJson(Map<String, dynamic> json) {
    return InboxMessage(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'system',
      title: json['title'] as String? ?? '织时消息',
      summary: json['summary'] as String? ?? '',
      status: json['status'] as String? ?? '未读',
      createdAtMillis:
          (json['createdAtMillis'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      ownerAccount: json['ownerAccount'] as String? ?? '',
    );
  }
}
