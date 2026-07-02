package com.vsa.visualsemanticagent.ui.profile

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.CalendarMonth
import androidx.compose.material.icons.rounded.LocationOn
import androidx.compose.material.icons.rounded.NotificationsActive
import androidx.compose.material.icons.rounded.QueryStats
import androidx.compose.material.icons.rounded.Security
import androidx.compose.material.icons.rounded.Shield
import androidx.compose.material.icons.rounded.Storage
import androidx.compose.material.icons.rounded.Timeline
import androidx.compose.ui.graphics.Color
import com.vsa.visualsemanticagent.notification.InboxMessageData
import com.vsa.visualsemanticagent.plan.AgendaCardData
import com.vsa.visualsemanticagent.plan.scheduleDateTime
import com.vsa.visualsemanticagent.ui.AppColors
import java.time.Duration

internal fun buildAgentCheckupItems(
    agendaItems: List<AgendaCardData>,
    inboxMessages: List<InboxMessageData>,
    pendingAgendaCount: Int,
    scheduledReminderCount: Int,
    blockHighRisk: Boolean,
    muteLowConfidence: Boolean,
    autoMapLink: Boolean
): List<AgentCheckupItem> {
    val confirmedItems = agendaItems.filter { it.status.contains("已") || it.status.contains("确认") }
    val missingTimeCount = agendaItems.count { it.scheduleDateTime() == null }
    val missingLocationCount = agendaItems.count { it.location.isBlank() || it.location.contains("待") || it.location.contains("未知") }
    val conflictCount = countNearbyAgendaPairs(agendaItems)
    val pendingInboxCount = inboxMessages.count {
        it.status.contains("待") || it.status.contains("未读") || it.type.contains("error", ignoreCase = true)
    }
    val reminderCoverageLow = confirmedItems.isNotEmpty() && scheduledReminderCount < confirmedItems.size

    return listOf(
        AgentCheckupItem(
            icon = Icons.Rounded.Shield,
            title = "待确认池",
            summary = if (pendingAgendaCount == 0) {
                "当前没有待校验日程，人在回路链路保持干净。"
            } else {
                "还有 $pendingAgendaCount 条事项等待复核，建议先处理再进入答辩演示。"
            },
            level = if (pendingAgendaCount == 0) CheckupLevel.Ready else CheckupLevel.Action,
            route = ProfileRoute.NotificationInbox
        ),
        AgentCheckupItem(
            icon = Icons.Rounded.CalendarMonth,
            title = "时间字段",
            summary = if (missingTimeCount == 0) {
                "已沉淀事项均有可解析时间，时间线排序稳定。"
            } else {
                "$missingTimeCount 条记录缺少精确时间，可能影响提醒和日历展示。"
            },
            level = if (missingTimeCount == 0) CheckupLevel.Ready else CheckupLevel.Action,
            route = ProfileRoute.History
        ),
        AgentCheckupItem(
            icon = Icons.Rounded.LocationOn,
            title = "地点字段",
            summary = if (missingLocationCount == 0 && autoMapLink) {
                "地点线索完整，地图联动已开启。"
            } else if (!autoMapLink) {
                "地图联动未开启，地点识别不会自动生成导航兜底。"
            } else {
                "$missingLocationCount 条记录地点不完整，可在历史记录中回看补齐。"
            },
            level = when {
                !autoMapLink -> CheckupLevel.Watch
                missingLocationCount == 0 -> CheckupLevel.Ready
                else -> CheckupLevel.Watch
            },
            route = if (autoMapLink) ProfileRoute.History else ProfileRoute.Preferences
        ),
        AgentCheckupItem(
            icon = Icons.Rounded.NotificationsActive,
            title = "提醒覆盖",
            summary = if (!reminderCoverageLow) {
                "提醒托管状态正常，关键时间点已有系统守护。"
            } else {
                "已确认事项多于提醒数，建议检查默认提醒策略。"
            },
            level = if (reminderCoverageLow) CheckupLevel.Watch else CheckupLevel.Ready,
            route = ProfileRoute.ReminderCenter
        ),
        AgentCheckupItem(
            icon = Icons.Rounded.Security,
            title = "安全边界",
            summary = if (blockHighRisk && muteLowConfidence) {
                "高风险拦截与低置信度静默均已开启，适合正式演示。"
            } else if (blockHighRisk) {
                "高风险拦截已开启，低置信度静默可按演示需要打开。"
            } else {
                "高风险拦截未开启，建议答辩前恢复人在回路防线。"
            },
            level = when {
                blockHighRisk && muteLowConfidence -> CheckupLevel.Ready
                blockHighRisk -> CheckupLevel.Watch
                else -> CheckupLevel.Action
            },
            route = ProfileRoute.PrivacySecurity
        ),
        AgentCheckupItem(
            icon = Icons.Rounded.Timeline,
            title = "时间冲突",
            summary = if (conflictCount == 0) {
                "未发现 90 分钟内的密集冲突，时间线节奏清晰。"
            } else {
                "发现 $conflictCount 组相近安排，建议进入时间线资产复核。"
            },
            level = if (conflictCount == 0) CheckupLevel.Ready else CheckupLevel.Watch,
            route = ProfileRoute.TimelineAssets
        ),
        AgentCheckupItem(
            icon = Icons.Rounded.NotificationsActive,
            title = "消息收纳",
            summary = if (pendingInboxCount == 0) {
                "通知中心没有未处理消息，系统状态清爽。"
            } else {
                "通知中心还有 $pendingInboxCount 条待处理记录，可集中清理。"
            },
            level = if (pendingInboxCount == 0) CheckupLevel.Ready else CheckupLevel.Watch,
            route = ProfileRoute.NotificationInbox
        ),
        AgentCheckupItem(
            icon = Icons.Rounded.Storage,
            title = "数据沉淀",
            summary = if (confirmedItems.isNotEmpty()) {
                "已有 ${confirmedItems.size} 条专属时间资产，可用于导出和复盘。"
            } else {
                "还没有确认资产，建议先从群聊截图或通知文本导入一条。"
            },
            level = if (confirmedItems.isNotEmpty()) CheckupLevel.Ready else CheckupLevel.Watch,
            route = ProfileRoute.TimelineAssets
        )
    )
}

internal fun calculateCheckupScore(items: List<AgentCheckupItem>): Int {
    var penalty = 0
    items.forEach { item ->
        penalty += when (item.level) {
            CheckupLevel.Ready -> 0
            CheckupLevel.Watch -> 6
            CheckupLevel.Action -> 14
        }
    }
    return (100 - penalty).coerceIn(0, 100)
}

internal fun buildCheckupConclusion(score: Int, actionCount: Int, watchCount: Int): String {
    return when {
        score >= 92 -> "可直接演示"
        actionCount > 0 -> "先处理 $actionCount 项"
        watchCount > 0 -> "建议微调 $watchCount 项"
        else -> "状态稳定"
    }
}

internal fun checkupLevelLabel(level: CheckupLevel): String {
    return when (level) {
        CheckupLevel.Ready -> "正常"
        CheckupLevel.Watch -> "观察"
        CheckupLevel.Action -> "处理"
    }
}

internal fun checkupLevelColor(level: CheckupLevel): Color {
    return when (level) {
        CheckupLevel.Ready -> AppColors.MintAccent
        CheckupLevel.Watch -> AppColors.GoldSoft
        CheckupLevel.Action -> AppColors.CoralSoft
    }
}

internal fun countNearbyAgendaPairs(items: List<AgendaCardData>): Int {
    val times = items
        .mapNotNull { item ->
            item.scheduleDateTime()?.let { dateTime -> item.id to dateTime }
        }
        .sortedBy { it.second }
    var count = 0
    for (index in 0 until times.lastIndex) {
        val current = times[index]
        val next = times[index + 1]
        val minutesBetween = kotlin.math.abs(Duration.between(current.second, next.second).toMinutes())
        if (current.first != next.first && minutesBetween in 0L..90L) {
            count += 1
        }
    }
    return count
}

internal fun endpointTail(endpoint: String): String {
    return endpoint
        .removePrefix("https://")
        .removePrefix("http://")
        .takeLast(36)
        .ifBlank { "未配置" }
}
