class UserPreference {
  const UserPreference({
    this.nickname = '织时用户',
    this.school = '',
    this.major = '',
    this.grade = '',
    this.reminderLeadMinutes = 60,
    this.dayReminderEnabled = true,
    this.hourReminderEnabled = true,
    this.blockHighRisk = true,
    this.muteLowConfidence = false,
    this.autoMapLink = true,
    this.performanceLiteMode = false,
  });

  final String nickname;
  final String school;
  final String major;
  final String grade;
  final int reminderLeadMinutes;
  final bool dayReminderEnabled;
  final bool hourReminderEnabled;
  final bool blockHighRisk;
  final bool muteLowConfidence;
  final bool autoMapLink;
  final bool performanceLiteMode;

  UserPreference copyWith({
    String? nickname,
    String? school,
    String? major,
    String? grade,
    int? reminderLeadMinutes,
    bool? dayReminderEnabled,
    bool? hourReminderEnabled,
    bool? blockHighRisk,
    bool? muteLowConfidence,
    bool? autoMapLink,
    bool? performanceLiteMode,
  }) {
    return UserPreference(
      nickname: nickname ?? this.nickname,
      school: school ?? this.school,
      major: major ?? this.major,
      grade: grade ?? this.grade,
      reminderLeadMinutes: reminderLeadMinutes ?? this.reminderLeadMinutes,
      dayReminderEnabled: dayReminderEnabled ?? this.dayReminderEnabled,
      hourReminderEnabled: hourReminderEnabled ?? this.hourReminderEnabled,
      blockHighRisk: blockHighRisk ?? this.blockHighRisk,
      muteLowConfidence: muteLowConfidence ?? this.muteLowConfidence,
      autoMapLink: autoMapLink ?? this.autoMapLink,
      performanceLiteMode: performanceLiteMode ?? this.performanceLiteMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nickname': nickname,
      'school': school,
      'major': major,
      'grade': grade,
      'reminderLeadMinutes': reminderLeadMinutes,
      'dayReminderEnabled': dayReminderEnabled,
      'hourReminderEnabled': hourReminderEnabled,
      'blockHighRisk': blockHighRisk,
      'muteLowConfidence': muteLowConfidence,
      'autoMapLink': autoMapLink,
      'performanceLiteMode': performanceLiteMode,
    };
  }

  factory UserPreference.fromJson(Map<String, dynamic> json) {
    return UserPreference(
      nickname: json['nickname'] as String? ?? '织时用户',
      school: json['school'] as String? ?? '',
      major: json['major'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
      reminderLeadMinutes: (json['reminderLeadMinutes'] as num?)?.toInt() ?? 60,
      dayReminderEnabled: json['dayReminderEnabled'] as bool? ?? true,
      hourReminderEnabled: json['hourReminderEnabled'] as bool? ?? true,
      blockHighRisk: json['blockHighRisk'] as bool? ?? true,
      muteLowConfidence: json['muteLowConfidence'] as bool? ?? false,
      autoMapLink: json['autoMapLink'] as bool? ?? true,
      performanceLiteMode: json['performanceLiteMode'] as bool? ?? false,
    );
  }
}
