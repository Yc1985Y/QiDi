package com.vsa.visualsemanticagent.ui.profile

import com.vsa.visualsemanticagent.plan.AgendaCardData
import com.vsa.visualsemanticagent.plan.displayDateLabel
import com.vsa.visualsemanticagent.plan.displayTimeLabel
import com.vsa.visualsemanticagent.plan.scheduleDate
import com.vsa.visualsemanticagent.plan.scheduleDateTime
import java.time.LocalDate
import java.time.LocalDateTime

private const val HISTORY_UNKNOWN_SOURCE = "未知来源"

internal fun historySourceOptions(agendaItems: List<AgendaCardData>): List<String> {
    return listOf("全部") + agendaItems
        .map { it.sourceLabel.ifBlank { HISTORY_UNKNOWN_SOURCE } }
        .distinct()
        .take(4)
}

internal fun filterHistoryItems(
    agendaItems: List<AgendaCardData>,
    query: String,
    dateFilter: String,
    statusFilter: String,
    sourceFilter: String,
    today: LocalDate
): List<AgendaCardData> {
    val keyword = query.trim()
    return agendaItems
        .asSequence()
        .filter { item ->
            keyword.isBlank() ||
                item.title.contains(keyword, ignoreCase = true) ||
                item.location.contains(keyword, ignoreCase = true) ||
                item.summary.contains(keyword, ignoreCase = true) ||
                item.sourceLabel.contains(keyword, ignoreCase = true)
        }
        .filter { item ->
            when (dateFilter) {
                "今日" -> item.scheduleDate() == today
                "本周" -> item.scheduleDate()?.let { date ->
                    !date.isBefore(today.minusDays(3)) && !date.isAfter(today.plusDays(7))
                } ?: false
                "待定" -> item.scheduleDate() == null
                else -> true
            }
        }
        .filter { item ->
            when (statusFilter) {
                "已确认" -> item.status.contains("已") || item.status.contains("确认")
                "待校验" -> item.status.contains("待")
                else -> true
            }
        }
        .filter { item ->
            sourceFilter == "全部" || item.sourceLabel.ifBlank { HISTORY_UNKNOWN_SOURCE } == sourceFilter
        }
        .sortedWith(
            compareByDescending<AgendaCardData> { it.scheduleDateTime() ?: LocalDateTime.MIN }
                .thenBy { it.title }
        )
        .toList()
}

internal fun buildHistoryRecordSummary(item: AgendaCardData): String {
    val time = runCatching { "${item.displayDateLabel()} ${item.displayTimeLabel()}" }
        .getOrElse { item.time }
        .ifBlank { "时间待校验" }
    val location = item.location.ifBlank { "地点待校验" }
    val summary = item.summary.ifBlank { "从校园碎片中沉淀的时间资产" }
    return "$time · $location · $summary"
}
