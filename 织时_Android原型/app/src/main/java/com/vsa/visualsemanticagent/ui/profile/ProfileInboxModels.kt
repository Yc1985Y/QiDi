package com.vsa.visualsemanticagent.ui.profile

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.Delete
import androidx.compose.material.icons.rounded.Edit
import androidx.compose.material.icons.rounded.Map
import androidx.compose.material.icons.rounded.NotificationsActive
import androidx.compose.material.icons.rounded.QueryStats
import androidx.compose.material.icons.rounded.Replay
import androidx.compose.material.icons.rounded.Security
import androidx.compose.material.icons.rounded.Shield
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import com.vsa.visualsemanticagent.notification.InboxMessageData
import com.vsa.visualsemanticagent.ui.AppColors

internal enum class InboxFilter {
    ALL,
    PENDING,
    FEEDBACK
}

internal fun filterInboxMessages(
    inboxMessages: List<InboxMessageData>,
    filter: InboxFilter
): List<InboxMessageData> {
    return when (filter) {
        InboxFilter.ALL -> inboxMessages
        InboxFilter.PENDING -> inboxMessages.filter { it.status.contains("待") || it.status.contains("未读") }
        InboxFilter.FEEDBACK -> inboxMessages.filter {
            it.type.contains("clarification", ignoreCase = true) ||
                it.type.contains("error", ignoreCase = true) ||
                it.type.contains("blocked", ignoreCase = true) ||
                it.type.contains("tts", ignoreCase = true)
        }
    }
}

internal fun inboxSectionTitle(filter: InboxFilter): String {
    return when (filter) {
        InboxFilter.ALL -> "最近消息"
        InboxFilter.PENDING -> "待处理消息"
        InboxFilter.FEEDBACK -> "解析反馈"
    }
}

internal fun inboxEmptySummary(filter: InboxFilter): String {
    return when (filter) {
        InboxFilter.ALL -> "暂时没有待处理消息，新的解析、确认、拦截和错误会自动收纳在这里。"
        InboxFilter.PENDING -> "当前没有待处理消息，待确认和待补充事项会自动回流到这里。"
        InboxFilter.FEEDBACK -> "当前没有新的解析反馈，低置信度和失败结果会保留在这里。"
    }
}

internal fun inboxMessageIcon(type: String, status: String): ImageVector {
    return when {
        type.contains("error", ignoreCase = true) -> Icons.Rounded.Security
        type.contains("blocked", ignoreCase = true) -> Icons.Rounded.Shield
        type.contains("confirm", ignoreCase = true) -> Icons.Rounded.CheckCircle
        type.contains("edit", ignoreCase = true) -> Icons.Rounded.Edit
        type.contains("delete", ignoreCase = true) -> Icons.Rounded.Delete
        type.contains("navigate", ignoreCase = true) -> Icons.Rounded.Map
        type.contains("duplicate", ignoreCase = true) -> Icons.Rounded.Replay
        status.contains("待") -> Icons.Rounded.Shield
        else -> Icons.Rounded.NotificationsActive
    }
}

internal fun inboxMessageBackground(type: String, status: String): Color {
    return when {
        type.contains("error", ignoreCase = true) || type.contains("blocked", ignoreCase = true) -> AppColors.CoralSoft
        status.contains("待") || status.contains("补充") -> AppColors.CoralSoft
        type.contains("confirm", ignoreCase = true) || status.contains("已处理") -> AppColors.MintAccent
        type.contains("navigate", ignoreCase = true) || type.contains("duplicate", ignoreCase = true) -> AppColors.GoldSoft
        else -> AppColors.SurfaceContainer
    }
}
