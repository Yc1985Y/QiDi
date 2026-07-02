package com.vsa.visualsemanticagent.ui.home

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.AutoAwesome
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.ContentPaste
import androidx.compose.material.icons.rounded.Mic
import androidx.compose.material.icons.rounded.PhotoCamera
import androidx.compose.material3.Icon
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.vsa.visualsemanticagent.ui.AppColors
import com.vsa.visualsemanticagent.ui.AppShapes
import com.vsa.visualsemanticagent.ui.AppSpacing
import com.vsa.visualsemanticagent.ui.AppTypography
import com.vsa.visualsemanticagent.ui.common.WeavingGlassCard
import com.vsa.visualsemanticagent.ui.common.WeavingInteractionStyle
import com.vsa.visualsemanticagent.ui.common.WeavingPrimaryButton
import com.vsa.visualsemanticagent.ui.common.rememberWeavingInteractionSource
import com.vsa.visualsemanticagent.ui.common.weavingClickable
import com.vsa.visualsemanticagent.ui.common.weavingPressFeedback

@Composable
internal fun InputEnergyHub(
    commandText: String,
    onCommandChanged: (String) -> Unit,
    onSubmitCommandClick: () -> Unit,
    onCaptureClick: () -> Unit,
    onVoiceStartClick: () -> Unit,
    onVoiceStopClick: () -> Unit,
    onPasteTextClick: () -> Unit,
    showLivePreview: Boolean,
    isCameraAvailable: Boolean,
    isLoading: Boolean,
    isVoiceListening: Boolean,
    isVoiceRecordingActive: Boolean,
    voiceRecordingMillis: Long
) {
    val shouldSubmitText = commandText.isNotBlank()

    WeavingGlassCard(
        containerColor = AppColors.SurfaceContainerHigh.copy(alpha = 0.9f)
    ) {
        Text(
            text = "自动识别通知",
            style = AppTypography.HeadlineLargeMobile,
            color = AppColors.OnSurface
        )

        if (showLivePreview) {
            CaptureEntryCard(
                enabled = isCameraAvailable && !isLoading && !isVoiceListening,
                onCaptureClick = onCaptureClick
            )
        }

        OutlinedTextField(
            value = commandText,
            onValueChange = onCommandChanged,
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(AppShapes.Large),
            leadingIcon = {
                val pasteInteractionSource = rememberWeavingInteractionSource()
                Box(
                    modifier = Modifier
                        .size(34.dp)
                        .testTag("home-paste-button")
                        .clip(CircleShape)
                        .background(AppColors.GoldSoft.copy(alpha = 0.72f))
                        .weavingPressFeedback(pasteInteractionSource)
                        .weavingClickable(
                            pasteInteractionSource,
                            indication = null,
                            onClick = onPasteTextClick
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Rounded.ContentPaste,
                        contentDescription = "粘贴通知",
                        tint = AppColors.OnSurface,
                        modifier = Modifier.size(18.dp)
                    )
                }
            },
            trailingIcon = if (commandText.isNotBlank()) {
                {
                    val clearInteractionSource = rememberWeavingInteractionSource()
                    Box(
                        modifier = Modifier
                            .size(34.dp)
                            .testTag("home-clear-command-button")
                            .clip(CircleShape)
                            .background(AppColors.SurfaceContainerLowest.copy(alpha = 0.78f))
                            .weavingPressFeedback(
                                clearInteractionSource,
                                WeavingInteractionStyle.IconGlow
                            )
                            .weavingClickable(clearInteractionSource, indication = null) {
                                onCommandChanged("")
                            },
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Rounded.Close,
                            contentDescription = "清空输入",
                            tint = AppColors.OnSurfaceVariant,
                            modifier = Modifier.size(18.dp)
                        )
                    }
                }
            } else {
                {
                    VoiceToggleButton(
                        isVoiceListening = isVoiceListening,
                        isVoiceRecordingActive = isVoiceRecordingActive,
                        voiceRecordingMillis = voiceRecordingMillis,
                        onClick = {
                            if (isVoiceListening) {
                                onVoiceStopClick()
                            } else {
                                onVoiceStartClick()
                            }
                        }
                    )
                }
            },
            placeholder = {
                Text(
                    text = "粘贴一段校园通知，我来帮你整理成时间、地点和提醒",
                    style = AppTypography.BodyMedium,
                    color = AppColors.OnSurfaceVariant.copy(alpha = 0.5f)
                )
            },
            colors = OutlinedTextFieldDefaults.colors(
                focusedContainerColor = AppColors.SurfaceContainerLowest.copy(alpha = 0.72f),
                unfocusedContainerColor = AppColors.SurfaceContainerLowest.copy(alpha = 0.72f),
                disabledContainerColor = AppColors.SurfaceContainerLowest.copy(alpha = 0.72f),
                focusedBorderColor = AppColors.Primary.copy(alpha = 0.25f),
                unfocusedBorderColor = AppColors.CardBorder,
                focusedTextColor = AppColors.OnSurface,
                unfocusedTextColor = AppColors.OnSurface,
                cursorColor = AppColors.Primary
            ),
            maxLines = 5
        )

        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(AppSpacing.md)
        ) {
            WeavingPrimaryButton(
                text = when {
                    isLoading -> "正在解析通知…"
                    shouldSubmitText -> "解析这段通知"
                    else -> "输入通知后解析"
                },
                onClick = onSubmitCommandClick,
                icon = Icons.Rounded.AutoAwesome,
                enabled = !isLoading && !isVoiceListening && shouldSubmitText,
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@Composable
private fun CaptureEntryCard(
    enabled: Boolean,
    onCaptureClick: () -> Unit
) {
    val interactionSource = rememberWeavingInteractionSource()
    WeavingGlassCard(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = 72.dp)
            .testTag("home-capture-entry")
            .weavingPressFeedback(interactionSource, WeavingInteractionStyle.TimelineSlide)
            .weavingClickable(
                interactionSource,
                enabled = enabled,
                indication = null,
                onClick = onCaptureClick
            ),
        containerColor = Color.White.copy(alpha = 0.52f)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 14.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(68.dp)
                    .clip(CircleShape)
                    .background(AppColors.Primary.copy(alpha = 0.12f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Rounded.PhotoCamera,
                    contentDescription = null,
                    tint = AppColors.Primary,
                    modifier = Modifier.size(38.dp)
                )
            }
            Box(
                modifier = Modifier.weight(1f),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "拍照识别",
                    style = AppTypography.DisplayLarge.copy(
                        fontSize = 28.sp,
                        lineHeight = 32.sp
                    ),
                    color = AppColors.OnSurface,
                    fontWeight = FontWeight.ExtraBold,
                    textAlign = TextAlign.Center,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
    }
}

@Composable
private fun VoiceToggleButton(
    isVoiceListening: Boolean,
    isVoiceRecordingActive: Boolean,
    voiceRecordingMillis: Long,
    onClick: () -> Unit
) {
    val interactionSource = rememberWeavingInteractionSource()
    val elapsedSeconds = (voiceRecordingMillis / 1000L).coerceAtLeast(0L)

    Box(
        modifier = Modifier.testTag("home-voice-toggle-button"),
        contentAlignment = Alignment.Center
    ) {
        Box(
            modifier = Modifier
                .size(36.dp)
                .clip(CircleShape)
                .background(
                    if (isVoiceListening) Color(0xFF76D672) else AppColors.MintAccent.copy(alpha = 0.86f)
                )
                .weavingPressFeedback(interactionSource, WeavingInteractionStyle.IconGlow)
                .weavingClickable(interactionSource, indication = null, onClick = onClick),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Rounded.Mic,
                contentDescription = "语音识别",
                tint = AppColors.Primary,
                modifier = Modifier.size(18.dp)
            )
        }

        if (isVoiceListening || isVoiceRecordingActive) {
            Box(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(start = 18.dp, bottom = 18.dp)
                    .clip(RoundedCornerShape(999.dp))
                    .background(Color.White.copy(alpha = 0.96f))
                    .padding(horizontal = 5.dp, vertical = 2.dp)
            ) {
                Text(
                    text = "${elapsedSeconds}s",
                    style = AppTypography.LabelSmall,
                    color = AppColors.Primary,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}
