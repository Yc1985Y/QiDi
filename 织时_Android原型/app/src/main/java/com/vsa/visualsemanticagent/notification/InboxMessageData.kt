package com.vsa.visualsemanticagent.notification

import java.time.Instant
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

data class InboxMessageData(
    val id: String,
    val type: String,
    val title: String,
    val summary: String,
    val status: String = "未读",
    val createdAtMillis: Long = System.currentTimeMillis(),
    val ownerAccount: String = ""
)

fun InboxMessageData.displayTimeLabel(): String {
    return runCatching {
        Instant.ofEpochMilli(createdAtMillis)
            .atZone(ZoneId.systemDefault())
            .format(DateTimeFormatter.ofPattern("M月d日 HH:mm", Locale.CHINA))
    }.getOrDefault("刚刚")
}
