package com.vsa.visualsemanticagent.ui.home

import android.graphics.BitmapFactory
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.CalendarMonth
import androidx.compose.material.icons.rounded.NotificationsActive
import androidx.compose.material.icons.rounded.Schedule
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.State
import androidx.compose.runtime.produceState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.vsa.visualsemanticagent.ui.AppColors
import com.vsa.visualsemanticagent.ui.AppSpacing
import com.vsa.visualsemanticagent.ui.AppTypography
import com.vsa.visualsemanticagent.ui.common.WeavingGlassCard
import com.vsa.visualsemanticagent.ui.common.WeavingIconBubble
import com.vsa.visualsemanticagent.ui.common.WeavingInteractionStyle
import com.vsa.visualsemanticagent.ui.common.rememberWeavingInteractionSource
import com.vsa.visualsemanticagent.ui.common.weavingClickable
import com.vsa.visualsemanticagent.ui.common.weavingPressFeedback
import java.io.File
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

@Composable
internal fun HomeGreeting(
    userNickname: String,
    userAccount: String,
    userAvatarUri: String,
    todayAgendaCount: Int,
    onOpenProfile: (() -> Unit)? = null,
    onOpenRecentResults: (() -> Unit)? = null
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            HomeAvatar(
                avatarUri = userAvatarUri,
                fallbackText = userNickname.ifBlank { userAccount.ifBlank { "织" } },
                onClick = onOpenProfile
            )
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(
                    text = "Hi, ${userNickname.ifBlank { "织时用户" }}",
                    style = AppTypography.HeadlineMedium,
                    color = AppColors.Primary
                )
                Text(
                    text = if (todayAgendaCount > 0) {
                        "今天有 $todayAgendaCount 项安排待处理"
                    } else if (userAccount.isNotBlank()) {
                        "$userAccount · 今天想把哪条校园通知整理进时间线？"
                    } else {
                        "今天想把哪条校园通知整理进时间线？"
                    },
                    style = AppTypography.BodyMedium,
                    color = AppColors.OnSurfaceVariant
                )
            }
        }
        WeavingIconBubble(
            icon = Icons.Rounded.NotificationsActive,
            background = AppColors.SurfaceContainer,
            tint = AppColors.Primary,
            onClick = onOpenRecentResults ?: onOpenProfile
        )
    }
}

@Composable
internal fun HomeOverviewCard(
    todayAgendaCount: Int,
    scheduledReminderCount: Int,
    onClick: (() -> Unit)? = null
) {
    val overviewColor = Color.hsv(54f, 0.22f, 1f)
    WeavingGlassCard(
        modifier = Modifier.fillMaxWidth(),
        containerColor = overviewColor,
        onClick = onClick,
        interactionStyle = WeavingInteractionStyle.TimelineSlide
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(AppSpacing.md),
            verticalAlignment = Alignment.CenterVertically
        ) {
            OverviewMetric(
                modifier = Modifier.weight(1f),
                icon = Icons.Rounded.CalendarMonth,
                value = todayAgendaCount.toString(),
                label = "今日安排"
            )
            Box(
                modifier = Modifier
                    .size(width = 1.dp, height = 72.dp)
                    .background(Color.White.copy(alpha = 0.55f))
            )
            OverviewMetric(
                modifier = Modifier.weight(1f),
                icon = Icons.Rounded.Schedule,
                value = scheduledReminderCount.toString(),
                label = "待提醒项"
            )
        }
    }
}

@Composable
private fun OverviewMetric(
    modifier: Modifier = Modifier,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    value: String,
    label: String
) {
    Column(
        modifier = modifier.padding(vertical = 4.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        Box(
            modifier = Modifier
                .size(52.dp)
                .clip(CircleShape)
                .background(Color.White.copy(alpha = 0.56f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = AppColors.Primary,
                modifier = Modifier.size(24.dp)
            )
        }
        Text(
            text = value,
            style = AppTypography.DisplayLarge,
            color = AppColors.OnSurface
        )
        Text(
            text = label,
            style = AppTypography.BodyLarge,
            color = AppColors.OnSurface,
            fontWeight = FontWeight.Bold
        )
    }
}

@Composable
private fun HomeAvatar(
    avatarUri: String,
    fallbackText: String,
    onClick: (() -> Unit)? = null
) {
    val bitmap = rememberHomeAvatarBitmapState(avatarUri).value
    val interactionSource = rememberWeavingInteractionSource()
    Box(
        modifier = Modifier
            .size(48.dp)
            .clip(CircleShape)
            .background(AppColors.SurfaceContainer)
            .border(0.8.dp, Color.White.copy(alpha = 0.64f), CircleShape)
            .let { base ->
                if (onClick != null) {
                    base
                        .weavingPressFeedback(interactionSource, WeavingInteractionStyle.IconGlow)
                        .weavingClickable(interactionSource) { onClick() }
                } else {
                    base
                }
            },
        contentAlignment = Alignment.Center
    ) {
        if (bitmap != null) {
            Image(
                bitmap = bitmap.asImageBitmap(),
                contentDescription = null,
                modifier = Modifier
                    .fillMaxSize()
                    .clip(CircleShape)
            )
        } else {
            Text(
                text = fallbackText.trim().take(1).ifBlank { "织" },
                style = AppTypography.HeadlineMedium,
                color = AppColors.Primary,
                fontWeight = FontWeight.ExtraBold
            )
        }
    }
}

@Composable
private fun rememberHomeAvatarBitmapState(avatarUri: String): State<android.graphics.Bitmap?> {
    return produceState<android.graphics.Bitmap?>(initialValue = null, avatarUri) {
        value = if (avatarUri.isBlank()) {
            null
        } else {
            withContext(Dispatchers.IO) {
                runCatching {
                    val file = File(avatarUri)
                    if (file.exists()) BitmapFactory.decodeFile(file.absolutePath) else null
                }.getOrNull()
            }
        }
    }
}
