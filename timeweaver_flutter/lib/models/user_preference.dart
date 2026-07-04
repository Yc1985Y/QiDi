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
    this.reminderLeadDays = 1,
    this.reminderLeadMinutes = 60,
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
  final int reminderLeadDays;
  final int reminderLeadMinutes;
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
    int? reminderLeadDays,
    int? reminderLeadMinutes,
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
      reminderLeadDays: reminderLeadDays ?? this.reminderLeadDays,
      reminderLeadMinutes: reminderLeadMinutes ?? this.reminderLeadMinutes,
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
      'reminderLeadDays': reminderLeadDays,
      'reminderLeadMinutes': reminderLeadMinutes,
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
      reminderLeadDays: (json['reminderLeadDays'] as num?)?.toInt() ?? 1,
      reminderLeadMinutes: (json['reminderLeadMinutes'] as num?)?.toInt() ?? 60,
      blockHighRisk: json['blockHighRisk'] as bool? ?? true,
      muteLowConfidence: json['muteLowConfidence'] as bool? ?? false,
      autoMapLink: json['autoMapLink'] as bool? ?? true,
    );
  }
}
