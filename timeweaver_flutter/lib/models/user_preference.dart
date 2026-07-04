class UserPreference {
  const UserPreference({
    this.nickname = '织时用户',
    this.school = '',
    this.major = '',
    this.grade = '',
    this.avatarPath = '',
    this.signature = '',
    this.birthday = '',
    this.age = '',
    this.gender = '',
    this.hometown = '',
    this.reminderLeadMinutes = 60,
    this.dayReminderEnabled = true,
    this.hourReminderEnabled = true,
    this.blockHighRisk = true,
    this.muteLowConfidence = false,
    this.autoMapLink = true,
  });

  final String nickname;
  final String school;
  final String major;
  final String grade;
  final String avatarPath;
  final String signature;
  final String birthday;
  final String age;
  final String gender;
  final String hometown;
  final int reminderLeadMinutes;
  final bool dayReminderEnabled;
  final bool hourReminderEnabled;
  final bool blockHighRisk;
  final bool muteLowConfidence;
  final bool autoMapLink;

  UserPreference copyWith({
    String? nickname,
    String? school,
    String? major,
    String? grade,
    String? avatarPath,
    String? signature,
    String? birthday,
    String? age,
    String? gender,
    String? hometown,
    int? reminderLeadMinutes,
    bool? dayReminderEnabled,
    bool? hourReminderEnabled,
    bool? blockHighRisk,
    bool? muteLowConfidence,
    bool? autoMapLink,
  }) {
    return UserPreference(
      nickname: nickname ?? this.nickname,
      school: school ?? this.school,
      major: major ?? this.major,
      grade: grade ?? this.grade,
      avatarPath: avatarPath ?? this.avatarPath,
      signature: signature ?? this.signature,
      birthday: birthday ?? this.birthday,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      hometown: hometown ?? this.hometown,
      reminderLeadMinutes: reminderLeadMinutes ?? this.reminderLeadMinutes,
      dayReminderEnabled: dayReminderEnabled ?? this.dayReminderEnabled,
      hourReminderEnabled: hourReminderEnabled ?? this.hourReminderEnabled,
      blockHighRisk: blockHighRisk ?? this.blockHighRisk,
      muteLowConfidence: muteLowConfidence ?? this.muteLowConfidence,
      autoMapLink: autoMapLink ?? this.autoMapLink,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nickname': nickname,
      'school': school,
      'major': major,
      'grade': grade,
      'avatarPath': avatarPath,
      'signature': signature,
      'birthday': birthday,
      'age': age,
      'gender': gender,
      'hometown': hometown,
      'reminderLeadMinutes': reminderLeadMinutes,
      'dayReminderEnabled': dayReminderEnabled,
      'hourReminderEnabled': hourReminderEnabled,
      'blockHighRisk': blockHighRisk,
      'muteLowConfidence': muteLowConfidence,
      'autoMapLink': autoMapLink,
    };
  }

  factory UserPreference.fromJson(Map<String, dynamic> json) {
    return UserPreference(
      nickname: json['nickname'] as String? ?? '织时用户',
      school: json['school'] as String? ?? '',
      major: json['major'] as String? ?? '',
      grade: json['grade'] as String? ?? '',
      avatarPath: json['avatarPath'] as String? ?? '',
      signature: json['signature'] as String? ?? '',
      birthday: json['birthday'] as String? ?? '',
      age: json['age'] as String? ?? '',
      gender: json['gender'] as String? ?? '',
      hometown: json['hometown'] as String? ?? '',
      reminderLeadMinutes: (json['reminderLeadMinutes'] as num?)?.toInt() ?? 60,
      dayReminderEnabled: json['dayReminderEnabled'] as bool? ?? true,
      hourReminderEnabled: json['hourReminderEnabled'] as bool? ?? true,
      blockHighRisk: json['blockHighRisk'] as bool? ?? true,
      muteLowConfidence: json['muteLowConfidence'] as bool? ?? false,
      autoMapLink: json['autoMapLink'] as bool? ?? true,
    );
  }
}
