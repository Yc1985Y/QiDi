package com.vsa.visualsemanticagent.account

data class AccountUser(
    val id: Long,
    val account: String,
    val nickname: String,
    val avatarUri: String = "",
    val signature: String = "",
    val birthday: String = "",
    val school: String = "",
    val age: String = "",
    val gender: String = "",
    val major: String = "",
    val grade: String = "",
    val hometown: String = "",
    val createdAt: Long,
    val lastLoginAt: Long
)

data class AccountAuthResult(
    val user: AccountUser? = null,
    val message: String
) {
    val success: Boolean get() = user != null
}
