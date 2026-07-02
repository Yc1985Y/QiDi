package com.vsa.visualsemanticagent.ui.review

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.AutoAwesome
import androidx.compose.material.icons.rounded.CalendarMonth
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.ContentPaste
import androidx.compose.material.icons.rounded.LocationOn
import androidx.compose.material.icons.rounded.Schedule
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.vsa.visualsemanticagent.decision.ExecutableIntent
import com.vsa.visualsemanticagent.decision.ExecutionMode
import com.vsa.visualsemanticagent.decision.ExecutionSuggestion
import com.vsa.visualsemanticagent.decision.ScheduleConflict
import com.vsa.visualsemanticagent.model.ModelConstants
import com.vsa.visualsemanticagent.ui.AppColors
import com.vsa.visualsemanticagent.ui.AppShapes
import com.vsa.visualsemanticagent.ui.AppSpacing
import com.vsa.visualsemanticagent.ui.AppTypography
import com.vsa.visualsemanticagent.ui.common.WeavingBackground
import com.vsa.visualsemanticagent.ui.common.WeavingChip
import com.vsa.visualsemanticagent.ui.common.WeavingGlassCard
import com.vsa.visualsemanticagent.ui.common.WeavingIconBubble
import com.vsa.visualsemanticagent.ui.common.WeavingInteractionStyle
import com.vsa.visualsemanticagent.ui.common.WeavingPrimaryButton

@Composable
fun ReviewScreenModule(
    modifier: Modifier = Modifier,
    intent: ExecutableIntent,
    suggestion: ExecutionSuggestion,
    sourceLabel: String,
    sourcePreview: String,
    conflicts: List<ScheduleConflict> = emptyList(),
    performanceLiteMode: Boolean = false,
    onBack: () -> Unit,
    onSaveDraft: (title: String, time: String, location: String, description: String) -> Unit,
    onConfirmDraft: (title: String, time: String, location: String, description: String) -> Unit,
    onCancelExecution: () -> Unit
) {
    val titleState = rememberSaveable(intent.stabilityKey) { mutableStateOf(intent.title.orEmpty()) }
    val timeState = rememberSaveable(intent.stabilityKey) { mutableStateOf(intent.time.orEmpty()) }
    val locationState = rememberSaveable(intent.stabilityKey) { mutableStateOf(intent.location.orEmpty()) }
    val descriptionState = rememberSaveable(intent.stabilityKey) {
        mutableStateOf(intent.description ?: intent.answer ?: "")
    }
    val title = titleState.value
    val time = timeState.value
    val location = locationState.value
    val description = descriptionState.value

    val confidencePercent = (intent.fusedConfidence * 100).toInt().coerceIn(0, 100)
    val needsAttention = confidencePercent < 80 || suggestion.validation.issues.isNotEmpty()
    val canConfirm = when (intent.action) {
        ModelConstants.ACTION_CREATE_EVENT -> title.isNotBlank() && time.isNotBlank()
        ModelConstants.ACTION_NAVIGATE -> location.isNotBlank()
        else -> suggestion.mode != ExecutionMode.BLOCKED
    }

    androidx.compose.foundation.layout.Box(
        modifier = modifier
            .fillMaxSize()
            .background(AppColors.Background)
            .testTag("review-screen")
    ) {
        WeavingBackground(
            interactiveStars = !performanceLiteMode,
            showStarField = !performanceLiteMode
        )
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .testTag("review-main-list")
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
                ReviewTopBar(onBack = onBack)
            }

            item {
                ReviewHeroCard(
                    sourceLabel = sourceLabel,
                    confidencePercent = confidencePercent,
                    needsAttention = needsAttention,
                    prompt = suggestion.prompt
                )
            }

            if (conflicts.isNotEmpty()) {
                item {
                    ConflictWarningCard(conflicts = conflicts)
                }
            }

            item {
                SourcePreviewCard(sourcePreview = sourcePreview)
            }

            item {
                WeavingGlassCard(containerColor = AppColors.SurfaceContainerLowest.copy(alpha = 0.94f)) {
                    Text(
                        text = "结构化校验",
                        style = AppTypography.HeadlineMedium,
                        color = AppColors.Primary,
                        fontWeight = FontWeight.ExtraBold
                    )
                    ReviewEditField(
                        label = "事项",
                        value = title,
                        placeholder = "例如：人工智能前沿讲座",
                        icon = Icons.Rounded.AutoAwesome,
                        highlight = needsAttention && title.isBlank(),
                        testTag = "review-title-field",
                        onValueChange = { titleState.value = it.take(60) }
                    )
                    ReviewEditField(
                        label = "时间",
                        value = time,
                        placeholder = "例如：2026-05-16T19:00:00",
                        icon = Icons.Rounded.CalendarMonth,
                        highlight = needsAttention && time.isBlank(),
                        testTag = "review-time-field",
                        onValueChange = { timeState.value = it.take(60) }
                    )
                    ReviewEditField(
                        label = "地点",
                        value = location,
                        placeholder = "可留空：无地点事项也能保留",
                        icon = Icons.Rounded.LocationOn,
                        highlight = intent.action == ModelConstants.ACTION_NAVIGATE && needsAttention && location.isBlank(),
                        testTag = "review-location-field",
                        onValueChange = { locationState.value = it.take(60) }
                    )
                    ReviewEditField(
                        label = "备注",
                        value = description,
                        placeholder = "可补充签到、会议号、来源说明等",
                        icon = Icons.Rounded.ContentPaste,
                        maxLines = 3,
                        highlight = false,
                        testTag = "review-description-field",
                        onValueChange = { descriptionState.value = it.take(120) }
                    )
                }
            }

            item {
                ReviewIssueCard(suggestion = suggestion, needsAttention = needsAttention)
            }

            item {
                Column(verticalArrangement = Arrangement.spacedBy(AppSpacing.md)) {
                    WeavingPrimaryButton(
                        text = "确认写入时间线",
                        onClick = { onConfirmDraft(title, time, location, description) },
                        enabled = canConfirm,
                        icon = Icons.Rounded.CheckCircle,
                        modifier = Modifier
                            .fillMaxWidth()
                            .testTag("review-confirm")
                    )
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(AppSpacing.md)
                    ) {
                        WeavingGlassCard(
                            modifier = Modifier
                                .weight(1f)
                                .testTag("review-save"),
                            containerColor = AppColors.MintAccent,
                            onClick = {
                                onSaveDraft(title, time, location, description)
                                onBack()
                            },
                            interactionStyle = WeavingInteractionStyle.IconGlow
                        ) {
                            Text(
                                text = "保存校验",
                                style = AppTypography.BodyLarge,
                                color = AppColors.Primary,
                                fontWeight = FontWeight.Bold
                            )
                        }
                        WeavingGlassCard(
                            modifier = Modifier
                                .weight(1f)
                                .testTag("review-cancel"),
                            containerColor = AppColors.CoralSoft,
                            onClick = onCancelExecution,
                            interactionStyle = WeavingInteractionStyle.IconGlow
                        ) {
                            Text(
                                text = "取消本次",
                                style = AppTypography.BodyLarge,
                                color = AppColors.Secondary,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ReviewTopBar(onBack: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        WeavingIconBubble(
            icon = Icons.AutoMirrored.Rounded.ArrowBack,
            background = AppColors.SurfaceContainerLowest.copy(alpha = 0.82f),
            tint = AppColors.Primary,
            onClick = onBack,
            modifier = Modifier.testTag("review-back")
        )
        Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(
                text = "解析校验",
                style = AppTypography.HeadlineLargeMobile,
                color = AppColors.Primary,
                fontWeight = FontWeight.ExtraBold
            )
            Text(
                text = "先核对 AI 抽取结果，再决定是否写入系统",
                style = AppTypography.BodyMedium,
                color = AppColors.OnSurfaceVariant
            )
        }
    }
}

@Composable
private fun ReviewHeroCard(
    sourceLabel: String,
    confidencePercent: Int,
    needsAttention: Boolean,
    prompt: String
) {
    WeavingGlassCard(
        containerColor = if (needsAttention) AppColors.CoralSoft else AppColors.SurfaceContainer
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                WeavingChip(
                    text = sourceLabel.ifBlank { "待校验" },
                    icon = Icons.Rounded.Schedule,
                    background = Color.White.copy(alpha = 0.52f),
                    contentColor = AppColors.Primary
                )
                Text(
                    text = if (needsAttention) "这条结果需要你重点看一眼" else "信息已经整理成可执行草稿",
                    style = AppTypography.HeadlineMedium,
                    color = AppColors.Primary
                )
                Text(
                    text = prompt,
                    style = AppTypography.BodyMedium,
                    color = AppColors.OnSurfaceVariant,
                    maxLines = 3,
                    overflow = TextOverflow.Ellipsis
                )
            }
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Text(
                    text = "$confidencePercent%",
                    style = AppTypography.MonoMetric,
                    color = if (needsAttention) AppColors.Secondary else AppColors.Primary
                )
                Text(
                    text = "信心",
                    style = AppTypography.LabelSmall,
                    color = AppColors.OnSurfaceVariant
                )
            }
        }
    }
}

@Composable
private fun SourcePreviewCard(sourcePreview: String) {
    WeavingGlassCard(containerColor = AppColors.SurfaceContainerLowest.copy(alpha = 0.9f)) {
        Text(
            text = "原始输入回顾",
            style = AppTypography.HeadlineMedium,
            color = AppColors.Primary,
            fontWeight = FontWeight.ExtraBold
        )
        Text(
            text = sourcePreview.ifBlank { "暂无原始文本可回放，当前结果来自相机、相册或系统分享。" },
            style = AppTypography.BodyMedium,
            color = AppColors.OnSurfaceVariant,
            maxLines = 6,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(min = 92.dp)
                .clip(RoundedCornerShape(AppShapes.Large))
                .background(Color.White.copy(alpha = 0.45f))
                .padding(16.dp)
        )
    }
}

@Composable
private fun ReviewEditField(
    label: String,
    value: String,
    placeholder: String,
    icon: ImageVector,
    highlight: Boolean,
    testTag: String,
    maxLines: Int = 1,
    onValueChange: (String) -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(
                color = if (highlight) AppColors.CoralSoft.copy(alpha = 0.72f) else Color.White.copy(alpha = 0.45f),
                shape = RoundedCornerShape(AppShapes.Large)
            )
            .padding(10.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        androidx.compose.foundation.layout.Box(
            modifier = Modifier
                .size(40.dp)
                .clip(CircleShape)
                .background(if (highlight) Color.White.copy(alpha = 0.62f) else AppColors.GoldSoft),
            contentAlignment = Alignment.Center
        ) {
            Icon(imageVector = icon, contentDescription = null, tint = AppColors.Primary)
        }
        OutlinedTextField(
            value = value,
            onValueChange = onValueChange,
            modifier = Modifier
                .weight(1f)
                .testTag(testTag),
            label = { Text(label) },
            placeholder = { Text(placeholder) },
            singleLine = maxLines == 1,
            maxLines = maxLines,
            shape = RoundedCornerShape(AppShapes.Medium),
            textStyle = AppTypography.BodyLarge,
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = if (highlight) AppColors.Secondary else AppColors.Primary,
                unfocusedBorderColor = if (highlight) AppColors.Secondary.copy(alpha = 0.52f) else Color.Transparent,
                focusedContainerColor = Color.White.copy(alpha = 0.5f),
                unfocusedContainerColor = Color.White.copy(alpha = 0.26f),
                cursorColor = AppColors.Primary,
                focusedLabelColor = AppColors.Primary,
                unfocusedLabelColor = AppColors.OnSurfaceVariant
            )
        )
    }
}

@Composable
private fun ReviewIssueCard(
    suggestion: ExecutionSuggestion,
    needsAttention: Boolean
) {
    val issues = suggestion.validation.issues
    WeavingGlassCard(
        containerColor = if (needsAttention) AppColors.GoldSoft else AppColors.MintAccent
    ) {
        Text(
            text = if (issues.isEmpty()) "校验结果" else "需要留意",
            style = AppTypography.HeadlineMedium,
            color = AppColors.Primary,
            fontWeight = FontWeight.ExtraBold
        )
        Text(
            text = if (issues.isEmpty()) {
                "标题、时间、地点等关键字段已经具备，可以确认写入。"
            } else {
                issues.joinToString(separator = " / ")
            },
            style = AppTypography.BodyMedium,
            color = AppColors.OnSurfaceVariant
        )
    }
}

@Composable
private fun ConflictWarningCard(conflicts: List<ScheduleConflict>) {
    WeavingGlassCard(containerColor = AppColors.CoralSoft.copy(alpha = 0.92f)) {
        Text(
            text = "时间冲突提醒",
            style = AppTypography.HeadlineMedium,
            color = AppColors.Primary,
            fontWeight = FontWeight.ExtraBold
        )
        Text(
            text = "这条安排和你时间线里的既有事项靠得很近，建议先核对后再确认。",
            style = AppTypography.BodyMedium,
            color = AppColors.OnSurfaceVariant
        )
        conflicts.take(2).forEach { conflict ->
            WeavingChip(
                text = "${conflict.conflictReason} · ${conflict.conflictWindowLabel}",
                background = Color.White.copy(alpha = 0.52f),
                contentColor = AppColors.Secondary
            )
        }
    }
}
