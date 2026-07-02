package com.vsa.visualsemanticagent.decision

import com.vsa.visualsemanticagent.plan.AgendaCardData
import com.vsa.visualsemanticagent.plan.scheduleDateTime
import java.time.Duration
import java.time.LocalDateTime

data class ScheduleConflict(
    val conflictItem: AgendaCardData,
    val conflictReason: String,
    val conflictWindowLabel: String
)

fun detectScheduleConflicts(
    intent: ExecutableIntent,
    agendaItems: List<AgendaCardData>,
    windowMinutes: Long = 60
): List<ScheduleConflict> {
    if (intent.action != com.vsa.visualsemanticagent.model.ModelConstants.ACTION_CREATE_EVENT) return emptyList()
    val targetTime = intent.time?.trim().orEmpty()
    val parsedTarget = parseDateTime(targetTime) ?: return emptyList()

    return agendaItems.mapNotNull { item ->
        if (item.id == intent.stabilityKey) return@mapNotNull null
        val existingTime = item.scheduleDateTime() ?: return@mapNotNull null
        val diffMinutes = kotlin.math.abs(Duration.between(existingTime, parsedTarget).toMinutes())
        if (diffMinutes > windowMinutes) return@mapNotNull null

        ScheduleConflict(
            conflictItem = item,
            conflictReason = when {
                existingTime.toLocalDate() == parsedTarget.toLocalDate() -> "同一天已有安排"
                else -> "时间接近已有安排"
            },
            conflictWindowLabel = "${existingTime.hour.toString().padStart(2, '0')}:${existingTime.minute.toString().padStart(2, '0')} · ${item.title}"
        )
    }
}

private fun parseDateTime(value: String): LocalDateTime? {
    val normalized = value.trim()
    if (normalized.isBlank()) return null
    return runCatching { LocalDateTime.parse(normalized) }.getOrNull()
}
