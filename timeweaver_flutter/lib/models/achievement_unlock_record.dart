class AchievementUnlockRecord {
  const AchievementUnlockRecord({
    required this.achievementId,
    required this.unlockedAtMillis,
    required this.ownerAccount,
  });

  final String achievementId;
  final int unlockedAtMillis;
  final String ownerAccount;

  DateTime get unlockedAt =>
      DateTime.fromMillisecondsSinceEpoch(unlockedAtMillis);

  AchievementUnlockRecord copyWith({
    String? achievementId,
    int? unlockedAtMillis,
    String? ownerAccount,
  }) {
    return AchievementUnlockRecord(
      achievementId: achievementId ?? this.achievementId,
      unlockedAtMillis: unlockedAtMillis ?? this.unlockedAtMillis,
      ownerAccount: ownerAccount ?? this.ownerAccount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'achievementId': achievementId,
      'unlockedAtMillis': unlockedAtMillis,
      'ownerAccount': ownerAccount,
    };
  }

  factory AchievementUnlockRecord.fromJson(Map<String, dynamic> json) {
    return AchievementUnlockRecord(
      achievementId: json['achievementId'] as String? ?? '',
      unlockedAtMillis:
          (json['unlockedAtMillis'] as num?)?.toInt() ??
          DateTime.now().millisecondsSinceEpoch,
      ownerAccount: json['ownerAccount'] as String? ?? '',
    );
  }
}
