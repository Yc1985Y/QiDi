class AccountUser {
  const AccountUser({
    required this.id,
    required this.account,
    required this.nickname,
    required this.createdAt,
    required this.lastLoginAt,
    this.avatarUri = '',
    this.signature = '',
    this.birthday = '',
    this.school = '',
    this.age = '',
    this.gender = '',
    this.major = '',
    this.grade = '',
    this.hometown = '',
  });

  final int id;
  final String account;
  final String nickname;
  final String avatarUri;
  final String signature;
  final String birthday;
  final String school;
  final String age;
  final String gender;
  final String major;
  final String grade;
  final String hometown;
  final int createdAt;
  final int lastLoginAt;

  AccountUser copyWith({
    int? id,
    String? account,
    String? nickname,
    String? avatarUri,
    String? signature,
    String? birthday,
    String? school,
    String? age,
    String? gender,
    String? major,
    String? grade,
    String? hometown,
    int? createdAt,
    int? lastLoginAt,
  }) {
    return AccountUser(
      id: id ?? this.id,
      account: account ?? this.account,
      nickname: nickname ?? this.nickname,
      avatarUri: avatarUri ?? this.avatarUri,
      signature: signature ?? this.signature,
      birthday: birthday ?? this.birthday,
      school: school ?? this.school,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      major: major ?? this.major,
      grade: grade ?? this.grade,
      hometown: hometown ?? this.hometown,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
