package com.vsa.visualsemanticagent.ui.timeline

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.widget.Toast
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.AddCircle
import androidx.compose.material.icons.rounded.CalendarMonth
import androidx.compose.material.icons.rounded.ContentCopy
import androidx.compose.material.icons.rounded.Delete
import androidx.compose.material.icons.rounded.Edit
import androidx.compose.material.icons.rounded.LocationOn
import androidx.compose.material.icons.rounded.NotificationsActive
import androidx.compose.material.icons.rounded.QueryStats
import androidx.compose.material.icons.rounded.Save
import androidx.compose.material.icons.rounded.Share
import androidx.compose.material.icons.rounded.Timeline
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.vsa.visualsemanticagent.plan.AgendaCardData
import com.vsa.visualsemanticagent.plan.exportTimeLabel
import com.vsa.visualsemanticagent.plan.reminderSummary
import com.vsa.visualsemanticagent.ui.AppColors
import com.vsa.visualsemanticagent.ui.AppShapes
import com.vsa.visualsemanticagent.ui.AppSpacing
import com.vsa.visualsemanticagent.ui.AppTypography
import com.vsa.visualsemanticagent.ui.common.WeavingChip
import com.vsa.visualsemanticagent.ui.common.WeavingGlassCard
import com.vsa.visualsemanticagent.ui.common.WeavingInteractionStyle
import com.vsa.visualsemanticagent.ui.common.WeavingPrimaryButton
import com.vsa.visualsemanticagent.ui.common.rememberWeavingInteractionSource
import com.vsa.visualsemanticagent.ui.common.weavingClickable
import com.vsa.visualsemanticagent.ui.common.weavingPressFeedback

@Composable
internal fun TimelineDetailCard(
    item: AgendaCardData,
    onDismiss: () -> Unit,
    onUpdateAgendaItem: (AgendaCardData) -> Unit,
    onDeleteAgendaItem: (AgendaCardData) -> Unit,
    onDuplicateAgendaItem: (AgendaCardData) -> Unit,
    onNavigateAgendaItem: (AgendaCardData) -> Unit
) {
    val context = LocalContext.current
    val isEditingState = remember(item.id) { mutableStateOf(false) }
    val titleDraftState = remember(item.id, item.title) { mutableStateOf(item.title) }
    val timeDraftState = remember(item.id, item.time, item.isoDateTime) {
        mutableStateOf(item.isoDateTime ?: item.time)
    }
    val locationDraftState = remember(item.id, item.location) { mutableStateOf(item.location) }
    val summaryDraftState = remember(item.id, item.summary) { mutableStateOf(item.summary) }
    val scrollState = rememberScrollState()
    val isEditing = isEditingState.value
    val titleDraft = titleDraftState.value
    val timeDraft = timeDraftState.value
    val locationDraft = locationDraftState.value
    val summaryDraft = summaryDraftState.value

    LaunchedEffect(isEditing, item.id) {
        if (isEditing) {
            scrollState.scrollTo(0)
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(AppColors.Background.copy(alpha = 0.96f))
            .padding(AppSpacing.lg),
        contentAlignment = Alignment.Center
    ) {
        WeavingGlassCard(
            modifier = Modifier
                .fillMaxWidth()
                .heightIn(max = 720.dp),
            containerColor = AppColors.SurfaceContainerHigh.copy(alpha = 0.96f)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(scrollState),
                verticalArrangement = Arrangement.spacedBy(AppSpacing.md)
            ) {
                WeavingChip(
                    text = if (isEditing) "日程详情 · 编辑中" else "日程详情",
                    icon = Icons.Rounded.Timeline,
                    background = AppColors.MintAccent,
                    contentColor = AppColors.Primary
                )

                Text(
                    text = if (isEditing) "校对这条日程" else item.title,
                    style = AppTypography.DisplayLarge,
                    color = AppColors.Primary
                )

                Text(
                    text = if (isEditing) {
                        "修改后的内容会直接写回时间线。"
                    } else {
                        item.summary.ifBlank { "这条事项已经沉淀到你的专属时间线中。" }
                    },
                    style = AppTypography.BodyLarge,
                    color = AppColors.OnSurfaceVariant
                )

                if (isEditing) {
                    DetailEditField("标题", titleDraft, { titleDraftState.value = it }, modifier = Modifier.testTag("timeline-detail-title-field"))
                    DetailEditField("时间", timeDraft, { timeDraftState.value = it }, modifier = Modifier.testTag("timeline-detail-time-field"))
                    DetailEditField("地点", locationDraft, { locationDraftState.value = it }, modifier = Modifier.testTag("timeline-detail-location-field"))
                    DetailEditField(
                        label = "摘要",
                        value = summaryDraft,
                        onValueChange = { summaryDraftState.value = it },
                        singleLine = false,
                        maxLines = 3,
                        modifier = Modifier.testTag("timeline-detail-summary-field")
                    )
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(AppSpacing.md)
                    ) {
                        DetailActionButton(
                            modifier = Modifier
                                .weight(1f)
                                .testTag("timeline-detail-save"),
                            icon = Icons.Rounded.Save,
                            title = "保存",
                            summary = "写回时间线",
                            background = AppColors.MintAccent,
                            onClick = {
                                isEditingState.value = false
                                onUpdateAgendaItem(
                                    buildEditedAgendaItem(
                                        original = item,
                                        title = titleDraft,
                                        time = timeDraft,
                                        location = locationDraft,
                                        summary = summaryDraft
                                    )
                                )
                            }
                        )
                        DetailActionButton(
                            modifier = Modifier
                                .weight(1f)
                                .testTag("timeline-detail-cancel-edit"),
                            icon = Icons.Rounded.Timeline,
                            title = "取消",
                            summary = "保留原内容",
                            background = AppColors.SurfaceContainerLowest,
                            onClick = {
                                titleDraftState.value = item.title
                                timeDraftState.value = item.isoDateTime ?: item.time
                                locationDraftState.value = item.location
                                summaryDraftState.value = item.summary
                                isEditingState.value = false
                            }
                        )
                    }
                } else {
                    DetailRow("时间", item.exportTimeLabel(), Icons.Rounded.CalendarMonth)
                    DetailRow("地点", item.location.ifBlank { "地点待补充" }, Icons.Rounded.LocationOn)
                    DetailRow("提醒", item.reminderSummary(), Icons.Rounded.NotificationsActive)
                    DetailRow("来源", item.sourceLabel.ifBlank { "校园通知导入" }, Icons.Rounded.Timeline)
                    DetailRow("状态", item.status.ifBlank { "已沉淀" }, Icons.Rounded.QueryStats)
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(AppSpacing.md)
                ) {
                    DetailActionButton(
                        modifier = Modifier
                            .weight(1f)
                            .testTag("timeline-detail-edit"),
                        icon = Icons.Rounded.Edit,
                        title = "编辑",
                        summary = "校对字段",
                        background = AppColors.SurfaceContainerLowest,
                        onClick = { isEditingState.value = true }
                    )
                    DetailActionButton(
                        modifier = Modifier
                            .weight(1f)
                            .testTag("timeline-detail-navigate"),
                        icon = Icons.Rounded.LocationOn,
                        title = "导航",
                        summary = "打开地图",
                        background = AppColors.GoldSoft,
                        onClick = { onNavigateAgendaItem(item) }
                    )
                }
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(AppSpacing.md)
                ) {
                    DetailActionButton(
                        modifier = Modifier
                            .weight(1f)
                            .testTag("timeline-detail-copy"),
                        icon = Icons.Rounded.ContentCopy,
                        title = "复制",
                        summary = "复制摘要",
                        background = AppColors.SurfaceContainerLowest,
                        onClick = { copyAgendaToClipboard(context, item) }
                    )
                    DetailActionButton(
                        modifier = Modifier
                            .weight(1f)
                            .testTag("timeline-detail-share"),
                        icon = Icons.Rounded.Share,
                        title = "分享",
                        summary = "发给同学",
                        background = AppColors.CoralSoft,
                        onClick = { shareAgenda(context, item) }
                    )
                }
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(AppSpacing.md)
                ) {
                    DetailActionButton(
                        modifier = Modifier
                            .weight(1f)
                            .testTag("timeline-detail-duplicate"),
                        icon = Icons.Rounded.AddCircle,
                        title = "复制成新事项",
                        summary = "生成副本",
                        background = AppColors.MintAccent,
                        onClick = { onDuplicateAgendaItem(item) }
                    )
                    DetailActionButton(
                        modifier = Modifier
                            .weight(1f)
                            .testTag("timeline-detail-delete"),
                        icon = Icons.Rounded.Delete,
                        title = "删除",
                        summary = "移出时间线",
                        background = AppColors.CoralSoft,
                        onClick = { onDeleteAgendaItem(item) }
                    )
                }

                WeavingPrimaryButton(
                    text = "关闭详情",
                    onClick = onDismiss,
                    modifier = Modifier.fillMaxWidth()
                )
            }
        }
    }
}

@Composable
private fun DetailEditField(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    singleLine: Boolean = true,
    maxLines: Int = 1
) {
    OutlinedTextField(
        value = value,
        onValueChange = onValueChange,
        modifier = modifier.fillMaxWidth(),
        label = { Text(label) },
        singleLine = singleLine,
        maxLines = maxLines,
        shape = RoundedCornerShape(AppShapes.Medium),
        textStyle = AppTypography.BodyLarge,
        colors = OutlinedTextFieldDefaults.colors(
            focusedBorderColor = AppColors.Primary.copy(alpha = 0.6f),
            unfocusedBorderColor = Color.White.copy(alpha = 0.4f),
            focusedContainerColor = Color.White.copy(alpha = 0.46f),
            unfocusedContainerColor = Color.White.copy(alpha = 0.28f),
            cursorColor = AppColors.Primary,
            focusedLabelColor = AppColors.Primary,
            unfocusedLabelColor = AppColors.OnSurfaceVariant
        )
    )
}

private fun buildEditedAgendaItem(
    original: AgendaCardData,
    title: String,
    time: String,
    location: String,
    summary: String
): AgendaCardData {
    val cleanTitle = title.trim().ifBlank { original.title }
    val cleanTime = time.trim().ifBlank { original.time }
    val cleanLocation = location.trim().ifBlank { original.location }
    val cleanSummary = summary.trim().ifBlank { original.summary }
    val timeChanged = cleanTime != original.time && cleanTime != original.isoDateTime
    return original.copy(
        title = cleanTitle,
        time = cleanTime,
        location = cleanLocation,
        summary = cleanSummary,
        isoDateTime = if (timeChanged) null else original.isoDateTime,
        status = if (original.status.contains("已")) original.status else "待校验"
    )
}

@Composable
private fun DetailActionButton(
    modifier: Modifier = Modifier,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    title: String,
    summary: String,
    background: Color,
    onClick: () -> Unit
) {
    val interaction = rememberWeavingInteractionSource()
    Row(
        modifier = modifier
            .weavingPressFeedback(interaction, WeavingInteractionStyle.IconGlow)
            .background(background, RoundedCornerShape(AppShapes.Large))
            .weavingClickable(interaction, indication = null, onClick = onClick)
            .padding(14.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(38.dp)
                .background(Color.White.copy(alpha = 0.52f), CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = AppColors.Primary,
                modifier = Modifier.size(19.dp)
            )
        }
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(2.dp)
        ) {
            Text(
                text = title,
                style = AppTypography.LabelMedium,
                color = AppColors.Primary,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = summary,
                style = AppTypography.LabelSmall,
                color = AppColors.OnSurfaceVariant,
                maxLines = 1
            )
        }
    }
}

@Composable
private fun DetailRow(
    label: String,
    value: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color.White.copy(alpha = 0.5f), RoundedCornerShape(AppShapes.Medium))
            .padding(16.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(42.dp)
                .background(AppColors.GoldSoft, CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Icon(imageVector = icon, contentDescription = null, tint = AppColors.Primary)
        }
        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
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
}

private fun copyAgendaToClipboard(
    context: Context,
    item: AgendaCardData
) {
    val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
    clipboard.setPrimaryClip(
        ClipData.newPlainText("织时时间线", buildAgendaShareText(item))
    )
    Toast.makeText(context, "已复制日程摘要", Toast.LENGTH_SHORT).show()
}

private fun shareAgenda(
    context: Context,
    item: AgendaCardData
) {
    val shareIntent = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(Intent.EXTRA_TEXT, buildAgendaShareText(item))
    }
    runCatching {
        context.startActivity(Intent.createChooser(shareIntent, "分享织时时间线"))
    }.onFailure {
        Toast.makeText(context, "暂时无法打开分享面板", Toast.LENGTH_SHORT).show()
    }
}

private fun buildAgendaShareText(item: AgendaCardData): String {
    return buildString {
        appendLine("来自《织时》的校园日程")
        appendLine("事项：${item.title.ifBlank { "未命名事项" }}")
        appendLine("时间：${item.exportTimeLabel()}")
        appendLine("地点：${item.location.ifBlank { "地点待补充" }}")
        appendLine("提醒：${item.reminderSummary().ifBlank { "未设置" }}")
        if (item.summary.isNotBlank()) appendLine("摘要：${item.summary}")
    }.trim()
}
