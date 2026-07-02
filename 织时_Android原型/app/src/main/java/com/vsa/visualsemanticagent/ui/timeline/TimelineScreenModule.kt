package com.vsa.visualsemanticagent.ui.timeline

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowForwardIos
import androidx.compose.material.icons.rounded.CalendarMonth
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.vsa.visualsemanticagent.decision.ExecutableIntent
import com.vsa.visualsemanticagent.decision.ExecutionSuggestion
import com.vsa.visualsemanticagent.plan.AgendaCardData
import com.vsa.visualsemanticagent.plan.AgendaDayBucket
import com.vsa.visualsemanticagent.plan.agendaDayTitle
import com.vsa.visualsemanticagent.plan.agendaWeekWindow
import com.vsa.visualsemanticagent.plan.displayTimeLabel
import com.vsa.visualsemanticagent.plan.groupAgendasByDay
import com.vsa.visualsemanticagent.plan.isConfirmedStatus
import com.vsa.visualsemanticagent.plan.scheduleDateTime
import com.vsa.visualsemanticagent.ui.AppColors
import com.vsa.visualsemanticagent.ui.AppShapes
import com.vsa.visualsemanticagent.ui.AppSpacing
import com.vsa.visualsemanticagent.ui.AppTypography
import com.vsa.visualsemanticagent.ui.common.EmptyStateCard
import com.vsa.visualsemanticagent.ui.common.WeavingBackground
import com.vsa.visualsemanticagent.ui.common.WeavingGlassCard
import com.vsa.visualsemanticagent.ui.common.WeavingInteractionStyle
import com.vsa.visualsemanticagent.ui.common.WeavingPrimaryButton
import com.vsa.visualsemanticagent.ui.common.WeavingSectionTitle
import com.vsa.visualsemanticagent.ui.common.rememberWeavingInteractionSource
import com.vsa.visualsemanticagent.ui.common.weavingClickable
import com.vsa.visualsemanticagent.ui.common.weavingPressFeedback
import java.time.LocalDate
import java.time.LocalDateTime
import java.time.YearMonth
import java.time.format.DateTimeFormatter
import java.util.Locale

@Composable
fun TimelineScreenModule(
    modifier: Modifier = Modifier,
    confirmationIntent: ExecutableIntent?,
    confirmationSuggestion: ExecutionSuggestion?,
    showConfirmationCard: Boolean,
    agendaItems: List<AgendaCardData>,
    selectedPlanMode: String,
    selectedPlanDate: LocalDate?,
    calendarPreviewMonth: YearMonth,
    nextReminderText: String,
    scheduledReminderCount: Int,
    confirmedAgendaCount: Int,
    onConfirmExecution: () -> Unit,
    onCancelExecution: () -> Unit,
    onGoHome: () -> Unit,
    onUpdateAgendaItem: (AgendaCardData) -> Unit = {},
    onDeleteAgendaItem: (AgendaCardData) -> Unit = {},
    onDuplicateAgendaItem: (AgendaCardData) -> Unit = {},
    onNavigateAgendaItem: (AgendaCardData) -> Unit = {}
) {
    val confirmedAgendaItems = agendaItems.filter { it.isConfirmedStatus() }
    val groupedItems = groupAgendasByDay(confirmedAgendaItems)
    val activeModeState = remember(selectedPlanMode) { mutableStateOf(selectedPlanMode.ifBlank { "week" }) }
    val activeDateState = remember(selectedPlanDate, groupedItems) {
        mutableStateOf(selectedPlanDate ?: groupedItems.firstOrNull()?.date ?: LocalDate.now())
    }
    val activeMonthState = remember(calendarPreviewMonth) { mutableStateOf(calendarPreviewMonth) }
    val showCalendarPageState = rememberSaveable { mutableStateOf(false) }
    val detailItemState = remember { mutableStateOf<AgendaCardData?>(null) }

    val activeMode = activeModeState.value
    val activeDate = activeDateState.value
    val activeMonth = activeMonthState.value
    val showCalendarPage = showCalendarPageState.value
    val detailItem = detailItemState.value

    val visibleBuckets = buildVisibleBuckets(
        groupedItems = groupedItems,
        activeMode = activeMode,
        activeDate = activeDate,
        activeMonth = activeMonth
    )
    val reminderHeadline = buildReminderHeadline(
        nextReminderText = nextReminderText,
        nextAgenda = findNextAgenda(confirmedAgendaItems),
        confirmedAgendaCount = confirmedAgendaCount,
        scheduledReminderCount = scheduledReminderCount
    )

    BackHandler(enabled = detailItem != null) {
        detailItemState.value = null
    }
    BackHandler(enabled = detailItem == null && showCalendarPage) {
        showCalendarPageState.value = false
    }

    if (showCalendarPage) {
        CalendarOverviewPage(
            month = activeMonth,
            selectedDate = activeDate,
            buckets = groupedItems,
            onPrev = { activeMonthState.value = activeMonth.minusMonths(1) },
            onNext = { activeMonthState.value = activeMonth.plusMonths(1) },
            onDateSelected = { activeDateState.value = it },
            onBack = { showCalendarPageState.value = false },
            onItemClick = { detailItemState.value = it }
        )
        detailItem?.let { item ->
            TimelineDetailCard(
                item = item,
                onDismiss = { detailItemState.value = null },
                onUpdateAgendaItem = {
                    detailItemState.value = it
                    onUpdateAgendaItem(it)
                },
                onDeleteAgendaItem = {
                    detailItemState.value = null
                    onDeleteAgendaItem(it)
                },
                onDuplicateAgendaItem = onDuplicateAgendaItem,
                onNavigateAgendaItem = onNavigateAgendaItem
            )
        }
        return
    }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(AppColors.Background)
    ) {
        WeavingBackground()

        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .testTag("timeline-main-list")
                .windowInsetsPadding(WindowInsets.statusBars)
                .windowInsetsPadding(WindowInsets.navigationBars),
            contentPadding = PaddingValues(
                start = AppSpacing.lg,
                end = AppSpacing.lg,
                top = AppSpacing.lg,
                bottom = 120.dp
            ),
            verticalArrangement = Arrangement.spacedBy(AppSpacing.gutter)
        ) {
            item {
                WeavingSectionTitle(
                    title = buildTimelineHeaderTitle(),
                    subtitle = null
                )
            }

            item {
                RecentReminderHeroCard(reminderText = reminderHeadline)
            }

            item {
                TimelineActionBar(
                    activeMode = activeMode,
                    onModeSelected = { activeModeState.value = it },
                    onOpenCalendar = { showCalendarPageState.value = true }
                )
            }

            if (showConfirmationCard && confirmationIntent != null && confirmationSuggestion != null) {
                item {
                    PendingTimelineCard(
                        suggestion = confirmationSuggestion.prompt,
                        onConfirmExecution = onConfirmExecution,
                        onGoHome = onGoHome,
                        onCancelExecution = onCancelExecution
                    )
                }
            }

            if (visibleBuckets.isEmpty()) {
                item {
                    EmptyStateCard(
                        title = "这一段时间还没有安排",
                        summary = "从首页导入截图、拍照、语音或文本后，确认过的事项会按时间顺序沉淀到这里。"
                    )
                }
            } else {
                items(
                    items = visibleBuckets,
                    key = { it.date.toString() }
                ) { bucket ->
                    TimelineDayGroup(
                        bucket = bucket,
                        onItemClick = { detailItemState.value = it }
                    )
                }
            }
        }
    }

    detailItem?.let { item ->
        TimelineDetailCard(
            item = item,
            onDismiss = { detailItemState.value = null },
            onUpdateAgendaItem = {
                detailItemState.value = it
                onUpdateAgendaItem(it)
            },
            onDeleteAgendaItem = {
                detailItemState.value = null
                onDeleteAgendaItem(it)
            },
            onDuplicateAgendaItem = onDuplicateAgendaItem,
            onNavigateAgendaItem = onNavigateAgendaItem
        )
    }
}

private fun buildTimelineHeaderTitle(): String {
    return LocalDateTime.now().format(DateTimeFormatter.ofPattern("M月d日 HH:mm", Locale.CHINA))
}

private fun findNextAgenda(items: List<AgendaCardData>): AgendaCardData? {
    val sorted = items.sortedBy { it.scheduleDateTime() ?: LocalDateTime.MAX }
    val now = LocalDateTime.now()
    return sorted.firstOrNull { (it.scheduleDateTime() ?: LocalDateTime.MAX) >= now } ?: sorted.firstOrNull()
}

private fun buildVisibleBuckets(
    groupedItems: List<AgendaDayBucket>,
    activeMode: String,
    activeDate: LocalDate,
    activeMonth: YearMonth
): List<AgendaDayBucket> {
    return when (activeMode) {
        "day" -> groupedItems.filter { it.date == activeDate }
        "month" -> groupedItems.filter { it.date.year == activeMonth.year && it.date.month == activeMonth.month }
        else -> {
            val weekDates = agendaWeekWindow(activeDate)
            groupedItems.filter { it.date in weekDates }
        }
    }
}

private fun buildReminderHeadline(
    nextReminderText: String,
    nextAgenda: AgendaCardData?,
    confirmedAgendaCount: Int,
    scheduledReminderCount: Int
): String {
    if (nextAgenda != null) {
        val dateText = nextAgenda.scheduleDateTime()
            ?.format(DateTimeFormatter.ofPattern("M月d日 HH:mm", Locale.CHINA))
            ?: nextAgenda.displayTimeLabel()
        return "$dateText · ${nextAgenda.title} · ${nextAgenda.location.ifBlank { "地点待补充" }}"
    }
    if (nextReminderText.isNotBlank()) {
        return nextReminderText
    }
    return if (confirmedAgendaCount > 0) {
        "已沉淀 $confirmedAgendaCount 条安排，其中 $scheduledReminderCount 项仍有后续提醒。"
    } else {
        "还没有新的提醒，确认一条校园通知后会在这里出现。"
    }
}

@Composable
private fun RecentReminderHeroCard(
    reminderText: String
) {
    WeavingGlassCard(
        containerColor = AppColors.SurfaceContainerHigh.copy(alpha = 0.92f)
    ) {
        Text(
            text = reminderText,
            style = AppTypography.HeadlineMedium,
            color = AppColors.Primary
        )
    }
}

@Composable
private fun PendingTimelineCard(
    suggestion: String,
    onConfirmExecution: () -> Unit,
    onGoHome: () -> Unit,
    onCancelExecution: () -> Unit
) {
    WeavingGlassCard(containerColor = AppColors.SurfaceContainer) {
        Text(
            text = "还有一条待确认事项",
            style = AppTypography.HeadlineMedium,
            color = AppColors.Primary
        )
        Text(
            text = suggestion,
            style = AppTypography.BodyMedium,
            color = AppColors.OnSurfaceVariant
        )
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(AppSpacing.md)
        ) {
            WeavingPrimaryButton(
                text = "确认写入",
                onClick = onConfirmExecution,
                modifier = Modifier.weight(1f)
            )
            WeavingPrimaryButton(
                text = "返回首页",
                onClick = onGoHome,
                modifier = Modifier.weight(1f)
            )
        }
        WeavingPrimaryButton(
            text = "取消",
            onClick = onCancelExecution,
            modifier = Modifier.fillMaxWidth()
        )
    }
}

@Composable
private fun TimelineActionBar(
    activeMode: String,
    onModeSelected: (String) -> Unit,
    onOpenCalendar: () -> Unit
) {
    Column(
        verticalArrangement = Arrangement.spacedBy(AppSpacing.md)
    ) {
        WeavingGlassCard(
            modifier = Modifier
                .fillMaxWidth()
                .testTag("timeline-calendar-entry"),
            containerColor = AppColors.SurfaceContainerLowest.copy(alpha = 0.92f),
            onClick = onOpenCalendar,
            interactionStyle = WeavingInteractionStyle.TimelineSlide
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Box(
                        modifier = Modifier
                            .size(42.dp)
                            .background(AppColors.MintAccent, CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Rounded.CalendarMonth,
                            contentDescription = null,
                            tint = AppColors.Primary
                        )
                    }
                    Text(
                        text = "日历总览",
                        style = AppTypography.BodyLarge,
                        color = AppColors.Primary,
                        fontWeight = FontWeight.Bold
                    )
                }
                Icon(
                    imageVector = Icons.AutoMirrored.Rounded.ArrowForwardIos,
                    contentDescription = null,
                    tint = AppColors.Primary,
                    modifier = Modifier.size(16.dp)
                )
            }
        }

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .background(AppColors.SurfaceContainerLowest, RoundedCornerShape(AppShapes.Full))
                .padding(3.dp),
            horizontalArrangement = Arrangement.spacedBy(3.dp)
        ) {
            listOf("day" to "本日", "week" to "本周", "month" to "本月").forEach { (key, label) ->
                val interaction = rememberWeavingInteractionSource()
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .weavingPressFeedback(interaction, WeavingInteractionStyle.IconGlow)
                        .background(
                            color = if (activeMode == key) AppColors.Primary else Color.Transparent,
                            shape = RoundedCornerShape(AppShapes.Full)
                        )
                        .weavingClickable(interaction, indication = null) { onModeSelected(key) }
                        .padding(vertical = 10.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = label,
                        style = AppTypography.LabelMedium,
                        color = if (activeMode == key) AppColors.OnPrimary else AppColors.OnSurfaceVariant,
                        fontWeight = FontWeight.Bold
                    )
                }
            }
        }
    }
}

@Composable
private fun TimelineDayGroup(
    bucket: AgendaDayBucket,
    onItemClick: (AgendaCardData) -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(AppSpacing.md)) {
        TimelineDayHeading(bucket.date)
        bucket.items.forEachIndexed { index, item ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(AppSpacing.md)
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text = item.displayTimeLabel(),
                        style = AppTypography.DisplayLarge,
                        color = AppColors.Primary,
                        fontWeight = FontWeight.ExtraBold
                    )
                    Box(
                        modifier = Modifier
                            .width(4.dp)
                            .height(if (index == bucket.items.lastIndex) 28.dp else 92.dp)
                            .background(
                                AppColors.SurfaceContainerHighest,
                                RoundedCornerShape(AppShapes.Full)
                            )
                    )
                }

                WeavingGlassCard(
                    modifier = Modifier
                        .weight(1f)
                        .testTag("timeline-item-${item.id}"),
                    containerColor = when (index % 3) {
                        0 -> AppColors.SurfaceContainer
                        1 -> AppColors.CoralSoft
                        else -> AppColors.GoldSoft
                    },
                    onClick = { onItemClick(item) },
                    interactionStyle = WeavingInteractionStyle.TimelineSlide
                ) {
                    Text(
                        text = item.title,
                        style = AppTypography.BodyLarge,
                        color = AppColors.OnSurface,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = item.location.ifBlank { "地点待补充" },
                        style = AppTypography.LabelSmall,
                        color = AppColors.OnSurfaceVariant
                    )
                }
            }
        }
    }
}

@Composable
private fun TimelineDayHeading(date: LocalDate) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.Bottom
    ) {
        Text(
            text = "${date.dayOfMonth}",
            style = AppTypography.DisplayLarge,
            color = AppColors.Primary,
            fontWeight = FontWeight.ExtraBold
        )
        Text(
            text = date.format(DateTimeFormatter.ofPattern("M月 EEEE", Locale.CHINA)),
            style = AppTypography.BodyLarge,
            color = AppColors.OnSurfaceVariant,
            fontWeight = FontWeight.Bold
        )
    }
}
