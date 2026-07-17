class UserPersonaSummary {
  const UserPersonaSummary({
    required this.title,
    required this.description,
    required this.tags,
    required this.evidence,
    required this.completedProfileFields,
    required this.totalProfileFields,
  });

  final String title;
  final String description;
  final List<String> tags;
  final List<String> evidence;
  final int completedProfileFields;
  final int totalProfileFields;
}

class UserAchievement {
  const UserAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.current,
    required this.target,
    required this.progressLabel,
    this.unlockedAt,
  });

  final String id;
  final String title;
  final String description;
  final int current;
  final int target;
  final String progressLabel;
  final DateTime? unlockedAt;

  bool get isUnlocked => current >= target;

  double get progress {
    if (target <= 0) return 0;
    return (current / target).clamp(0.0, 1.0);
  }
}

class UserInsightResult {
  const UserInsightResult({required this.persona, required this.achievements});

  final UserPersonaSummary persona;
  final List<UserAchievement> achievements;

  int get unlockedAchievementCount =>
      achievements.where((achievement) => achievement.isUnlocked).length;
}
