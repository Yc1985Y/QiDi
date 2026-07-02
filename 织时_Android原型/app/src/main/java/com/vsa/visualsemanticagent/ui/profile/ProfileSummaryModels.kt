package com.vsa.visualsemanticagent.ui.profile

internal fun buildProfileLine(
    account: String,
    school: String,
    major: String,
    grade: String
): String {
    val parts = listOfNotNull(
        account.takeIf { it.isNotBlank() },
        school.takeIf { it.isNotBlank() },
        major.takeIf { it.isNotBlank() },
        grade.takeIf { it.isNotBlank() }
    )
    return parts.joinToString(" · ").ifBlank { "请完善校园身份资料" }
}

internal fun buildProfileBrief(
    birthday: String,
    age: String,
    gender: String = "",
    hometown: String = ""
): String {
    val parts = listOfNotNull(
        birthday.takeIf { it.isNotBlank() }?.let { "生日 $it" },
        age.takeIf { it.isNotBlank() }?.let { "$it 岁" },
        gender.takeIf { it.isNotBlank() },
        hometown.takeIf { it.isNotBlank() }
    )
    return parts.joinToString(" · ").ifBlank { "请完善生日、年龄和学校资料" }
}
