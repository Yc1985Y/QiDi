package com.vsa.visualsemanticagent.ui.timeline

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.automirrored.rounded.ArrowForwardIos
import androidx.compose.material.icons.rounded.CalendarMonth
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.vsa.visualsemanticagent.plan.AgendaCardData
import com.vsa.visualsemanticagent.plan.AgendaDayBucket
import com.vsa.visualsemanticagent.plan.agendaDayTitle
import com.vsa.visualsemanticagent.plan.agendaMonthMatrix
import com.vsa.visualsemanticagent.plan.agendaMonthTitle
import com.vsa.visualsemanticagent.plan.displayTimeLabel
import com.vsa.visualsemanticagent.ui.AppColors
import com.vsa.visualsemanticagent.ui.AppShapes
import com.vsa.visualsemanticagent.ui.AppSpacing
import com.vsa.visualsemanticagent.ui.AppTypography
import com.vsa.visualsemanticagent.ui.common.WeavingBackground
import com.vsa.visualsemanticagent.ui.common.WeavingGlassCard
import com.vsa.visualsemanticagent.ui.common.WeavingIconBubble
import com.vsa.visualsemanticagent.ui.common.WeavingInteractionStyle
import com.vsa.visualsemanticagent.ui.common.rememberWeavingInteractionSource
import com.vsa.visualsemanticagent.ui.common.weavingClickable
import com.vsa.visualsemanticagent.ui.common.weavingPressFeedback
import java.time.LocalDate
import java.time.YearMonth

@Composable
internal fun CalendarOverviewPage(
    month: YearMonth,
    selectedDate: LocalDate,
    buckets: List<AgendaDayBucket>,
    onPrev: () -> Unit,
    onNext: () -> Unit,
    onDateSelected: (LocalDate) -> Unit,
    onBack: () -> Unit,
    onItemClick: (AgendaCardData) -> Unit
) {
    val selectedBucket = buckets.firstOrNull { it.date == selectedDate }
    val totalInMonth = buckets
        .filter { it.date.year == month.year && it.date.month == month.month }
        .sumOf { it.items.size }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(AppColors.Background)
            .testTag("timeline-calendar-root")
    ) {
        WeavingBackground()
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .testTag("timeline-calendar-page")
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
                CalendarOverviewHeader(
                    totalInMonth = totalInMonth,
                    onBack = onBack
                )
            }

            item {
                MonthCard(
                    month = month,
                    selectedDate = selectedDate,
                    buckets = buckets,
                    onPrev = onPrev,
                    onNext = onNext,
                    onDateSelected = onDateSelected
                )
            }

            item {
                SelectedDateAgendaCard(
                    selectedDate = selectedDate,
                    items = selectedBucket?.items.orEmpty(),
                    onItemClick = onItemClick
                )
            }
        }
    }
}

@Composable
private fun CalendarOverviewHeader(
    totalInMonth: Int,
    onBack: () -> Unit
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(AppSpacing.md),
        verticalAlignment = Alignment.CenterVertically
    ) {
        WeavingIconBubble(
            icon = Icons.AutoMirrored.Rounded.ArrowBack,
            background = AppColors.SurfaceContainerLowest,
            tint = AppColors.Primary,
            modifier = Modifier.testTag("timeline-calendar-back"),
            onClick = onBack
        )
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Text(
                text = "日历总览",
                style = AppTypography.HeadlineLargeMobile,
                color = AppColors.Primary
            )
            Text(
                text = "本月已织入 $totalInMonth 条安排",
                style = AppTypography.LabelSmall,
                color = AppColors.OnSurfaceVariant
            )
        }
    }
}

@Composable
private fun MonthCard(
    month: YearMonth,
    selectedDate: LocalDate,
    buckets: List<AgendaDayBucket>,
    onPrev: () -> Unit,
    onNext: () -> Unit,
    onDateSelected: (LocalDate) -> Unit
) {
    val matrix = agendaMonthMatrix(month)

    WeavingGlassCard(containerColor = AppColors.SurfaceContainerLowest) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = agendaMonthTitle(month),
                style = AppTypography.HeadlineLargeMobile,
                color = AppColors.Primary
            )
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                CalendarArrowButton(label = "‹", onClick = onPrev)
                CalendarArrowButton(label = "›", onClick = onNext)
            }
        }

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            listOf("日", "一", "二", "三", "四", "五", "六").forEach { day ->
                Text(
                    text = day,
                    style = AppTypography.BodyMedium,
                    color = AppColors.OnSurfaceVariant,
                    modifier = Modifier.width(44.dp),
                    fontWeight = FontWeight.Bold
                )
            }
        }

        matrix.chunked(7).forEach { row ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                row.forEach { date ->
                    val eventCount = if (date == null) 0 else buckets.firstOrNull { it.date == date }?.items?.size ?: 0
                    val isSelected = date == selectedDate
                    val interaction = rememberWeavingInteractionSource()
                    Box(
                        modifier = Modifier
                            .size(width = 44.dp, height = 76.dp)
                            .background(
                                color = when {
                                    isSelected -> AppColors.Primary
                                    eventCount > 0 -> AppColors.SurfaceContainer.copy(alpha = 0.74f)
                                    else -> Color.Transparent
                                },
                                shape = RoundedCornerShape(AppShapes.Medium)
                            )
                            .weavingPressFeedback(interaction, WeavingInteractionStyle.IconGlow)
                            .weavingClickable(interaction, enabled = date != null, indication = null) {
                                date?.let(onDateSelected)
                            },
                        contentAlignment = Alignment.Center
                    ) {
                        Column(
                            horizontalAlignment = Alignment.CenterHorizontally,
                            verticalArrangement = Arrangement.spacedBy(5.dp)
                        ) {
                            Text(
                                text = date?.dayOfMonth?.toString().orEmpty(),
                                style = AppTypography.HeadlineMedium,
                                color = if (isSelected) AppColors.OnPrimary else AppColors.OnSurface,
                                fontWeight = FontWeight.ExtraBold
                            )
                            if (eventCount > 0 && date != null) {
                                Row(horizontalArrangement = Arrangement.spacedBy(2.dp)) {
                                    repeat(eventCount.coerceAtMost(4)) {
                                        Box(
                                            modifier = Modifier
                                                .size(6.dp)
                                                .background(Color(0xFFF4C84A), CircleShape)
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun CalendarArrowButton(
    label: String,
    onClick: () -> Unit
) {
    val interaction = rememberWeavingInteractionSource()
    Box(
        modifier = Modifier
            .weavingPressFeedback(interaction, WeavingInteractionStyle.IconGlow)
            .background(AppColors.SurfaceContainer, RoundedCornerShape(AppShapes.Full))
            .weavingClickable(interaction, indication = null, onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 10.dp)
    ) {
        Text(
            text = label,
            style = AppTypography.BodyLarge,
            color = AppColors.Primary
        )
    }
}

@Composable
private fun SelectedDateAgendaCard(
    selectedDate: LocalDate,
    items: List<AgendaCardData>,
    onItemClick: (AgendaCardData) -> Unit
) {
    WeavingGlassCard(
        containerColor = AppColors.SurfaceContainerLowest.copy(alpha = 0.9f)
    ) {
        Text(
            text = agendaDayTitle(selectedDate),
            style = AppTypography.HeadlineLargeMobile,
            color = AppColors.Primary
        )
        if (items.isEmpty()) {
            Text(
                text = "这一天暂时没有安排。",
                style = AppTypography.LabelSmall,
                color = AppColors.OnSurfaceVariant
            )
        } else {
            items.forEach { item ->
                CalendarAgendaRow(
                    item = item,
                    onClick = { onItemClick(item) }
                )
            }
        }
    }
}

@Composable
private fun CalendarAgendaRow(
    item: AgendaCardData,
    onClick: () -> Unit
) {
    val interaction = rememberWeavingInteractionSource()
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color.White.copy(alpha = 0.52f), RoundedCornerShape(AppShapes.Medium))
            .weavingPressFeedback(interaction, WeavingInteractionStyle.TimelineSlide)
            .weavingClickable(interaction, indication = null, onClick = onClick)
            .padding(12.dp),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(2.dp)
        ) {
            Text(
                text = item.title,
                style = AppTypography.BodyLarge,
                color = AppColors.OnSurface,
                fontWeight = FontWeight.Bold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                text = "${item.displayTimeLabel()} · ${item.location.ifBlank { "地点待补充" }}",
                style = AppTypography.LabelSmall,
                color = AppColors.OnSurfaceVariant,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
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
