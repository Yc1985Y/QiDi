package com.vsa.visualsemanticagent.ui.home

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.AutoAwesome
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.NotificationsActive
import androidx.compose.material.icons.rounded.Timeline
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.vsa.visualsemanticagent.plan.AgendaCardData
import com.vsa.visualsemanticagent.plan.displayTimeLabel
import com.vsa.visualsemanticagent.ui.AppColors
import com.vsa.visualsemanticagent.ui.AppShapes
import com.vsa.visualsemanticagent.ui.AppSpacing
import com.vsa.visualsemanticagent.ui.AppTypography
import com.vsa.visualsemanticagent.ui.common.EmptyStateCard
import com.vsa.visualsemanticagent.ui.common.WeavingChip
import com.vsa.visualsemanticagent.ui.common.WeavingGlassCard
import com.vsa.visualsemanticagent.ui.common.WeavingPrimaryButton
import com.vsa.visualsemanticagent.ui.common.WeavingSectionTitle

@Composable
internal fun PendingReviewCard(
    title: String,
    time: String,
    location: String,
    importedSourceLabel: String,
    confidence: Int,
    summary: String,
    pendingQueueCount: Int,
    conflictCount: Int,
    onOpenReview: (() -> Unit)?,
    onConfirmExecution: () -> Unit,
    onCancelExecution: () -> Unit
) {
    WeavingGlassCard(
        modifier = Modifier.testTag("home-pending-review-card"),
        onClick = onOpenReview,
        containerColor = AppColors.SurfaceContainer
    ) {
        WeavingChip(
            text = if (importedSourceLabel.isBlank()) "待确认" else importedSourceLabel,
            icon = Icons.Rounded.AutoAwesome,
            background = AppColors.CoralSoft,
            contentColor = AppColors.Secondary
        )
        Text(
            text = "我整理出了这些信息",
            style = AppTypography.HeadlineLargeMobile,
            color = AppColors.Primary
        )
        if (pendingQueueCount > 1) {
            WeavingChip(
                text = "还有 $pendingQueueCount 条待确认",
                icon = Icons.Rounded.NotificationsActive,
                background = AppColors.GoldSoft,
                contentColor = AppColors.Secondary
            )
        }
        ReviewField("事项", title)
        ReviewField("时间", time)
        ReviewField("地点", location)
        ReviewField("信心指数", "$confidence%")
        if (conflictCount > 0) {
            WeavingChip(
                text = "有 $conflictCount 条相近时间安排",
                icon = Icons.Rounded.NotificationsActive,
                background = AppColors.GoldSoft,
                contentColor = AppColors.Secondary
            )
        }
        Text(
            text = summary,
            style = AppTypography.BodyMedium,
            color = AppColors.OnSurfaceVariant
        )
        WeavingGlassCard(
            modifier = Modifier.fillMaxWidth(),
            containerColor = AppColors.CoralSoft
        ) {
            Text(
                text = "如果还有歧义，可以先进入校验页修改后再加入时间线。",
                style = AppTypography.LabelMedium,
                color = AppColors.Secondary
            )
        }
        if (onOpenReview != null) {
            WeavingGlassCard(
                modifier = Modifier
                    .fillMaxWidth()
                    .testTag("home-open-review"),
                containerColor = AppColors.MintAccent,
                onClick = onOpenReview
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
                        Text(
                            text = "进入解析校验页",
                            style = AppTypography.BodyLarge,
                            color = AppColors.Primary,
                            fontWeight = FontWeight.Bold
                        )
                        Text(
                            text = "逐项核对标题、时间、地点后再写入",
                            style = AppTypography.LabelSmall,
                            color = AppColors.OnSurfaceVariant
                        )
                    }
                    Icon(
                        imageVector = Icons.Rounded.CheckCircle,
                        contentDescription = null,
                        tint = AppColors.Primary
                    )
                }
            }
        }
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(AppSpacing.md)
        ) {
            WeavingPrimaryButton(
                text = "确认加入日程",
                onClick = onConfirmExecution,
                icon = Icons.Rounded.CheckCircle,
                modifier = Modifier.weight(1f)
            )
            WeavingPrimaryButton(
                text = "取消",
                onClick = onCancelExecution,
                modifier = Modifier.width(128.dp)
            )
        }
    }
}

@Composable
private fun ReviewField(label: String, value: String) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color.White.copy(alpha = 0.5f), RoundedCornerShape(AppShapes.Medium))
            .padding(13.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        Text(
            text = label,
            style = AppTypography.LabelMedium,
            color = AppColors.OnSurfaceVariant
        )
        Text(
            text = value,
            style = AppTypography.BodyLarge,
            color = AppColors.OnSurface
        )
    }
}

@Composable
internal fun RecentRecognitionCard(summary: String) {
    WeavingGlassCard {
        Text(
            text = summary,
            style = AppTypography.BodyLarge,
            color = AppColors.OnSurfaceVariant
        )
    }
}

@Composable
internal fun TodayAgendaCard(todayItems: List<AgendaCardData>) {
    if (todayItems.isEmpty()) {
        EmptyStateCard(
            title = "今天暂时没有安排",
            summary = "所有确认后的校园事项都会在这里沉淀成清晰的今日时间线。"
        )
        return
    }

    WeavingGlassCard {
        WeavingSectionTitle(
            title = "今日安排",
            subtitle = "Today-First：先看离你最近的一件事"
        )
        todayItems.take(3).forEach { item ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(Color.White.copy(alpha = 0.5f), RoundedCornerShape(AppShapes.Large))
                    .padding(13.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .size(44.dp)
                        .background(AppColors.GoldSoft, CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Rounded.Timeline,
                        contentDescription = null,
                        tint = AppColors.Primary
                    )
                }
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(2.dp)
                ) {
                    Text(
                        text = item.title,
                        style = AppTypography.BodyLarge,
                        color = AppColors.OnSurface,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = "${item.displayTimeLabel()} · ${item.location}",
                        style = AppTypography.LabelSmall,
                        color = AppColors.OnSurfaceVariant
                    )
                }
            }
        }
    }
}
