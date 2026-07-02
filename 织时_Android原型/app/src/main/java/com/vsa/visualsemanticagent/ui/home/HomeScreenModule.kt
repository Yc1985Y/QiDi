package com.vsa.visualsemanticagent.ui.home

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.unit.dp
import com.vsa.visualsemanticagent.decision.ExecutableIntent
import com.vsa.visualsemanticagent.decision.ExecutionSuggestion
import com.vsa.visualsemanticagent.plan.AgendaCardData
import com.vsa.visualsemanticagent.ui.AppColors
import com.vsa.visualsemanticagent.ui.AppSpacing
import com.vsa.visualsemanticagent.ui.common.WeavingBackground
import com.vsa.visualsemanticagent.ui.common.WeavingSectionTitle
import com.vsa.visualsemanticagent.utils.PromptPreset

@Suppress("UNUSED_PARAMETER")
@Composable
fun HomeScreenModule(
    modifier: Modifier = Modifier,
    commandText: String,
    onCommandChanged: (String) -> Unit,
    onSubmitCommandClick: () -> Unit,
    onCaptureClick: () -> Unit,
    onVoicePressStart: () -> Unit,
    onVoicePressEnd: () -> Unit,
    onVoicePressCancel: () -> Unit,
    onPasteTextClick: () -> Unit,
    onPresetClick: (PromptPreset) -> Unit,
    onConfirmExecution: () -> Unit,
    onCancelExecution: () -> Unit,
    confirmationIntent: ExecutableIntent?,
    confirmationSuggestion: ExecutionSuggestion?,
    showConfirmationCard: Boolean,
    bindPreview: (androidx.camera.view.PreviewView) -> Unit,
    presets: List<PromptPreset>,
    showLivePreview: Boolean = true,
    isLoading: Boolean = false,
    isVoiceListening: Boolean = false,
    isVoiceRecordingActive: Boolean = false,
    voiceRecordingMillis: Long = 0L,
    isCameraAvailable: Boolean = true,
    statusText: String? = null,
    resultText: String? = null,
    importedSourceLabel: String? = null,
    conflictCount: Int = 0,
    agendaItems: List<AgendaCardData> = emptyList(),
    nextReminderText: String = "",
    todayAgendaCount: Int = 0,
    userNickname: String = "织时用户",
    userAccount: String = "",
    userAvatarUri: String = "",
    scheduledReminderCount: Int = 0,
    onOpenTimeline: (() -> Unit)? = null,
    onOpenProfile: (() -> Unit)? = null,
    onOpenReview: (() -> Unit)? = null,
    onOpenRecentResults: (() -> Unit)? = null
) {
    val pendingCount = remember(agendaItems) {
        agendaItems.count { status ->
            isPendingHomeStatus(status.status)
        }
    }
    val pendingTitle = confirmationIntent?.title ?: "待确认安排"
    val pendingTime = confirmationIntent?.time ?: "请先检查时间"
    val pendingLocation = confirmationIntent?.location ?: "请补充地点"
    val confidence = ((confirmationIntent?.fusedConfidence ?: confirmationSuggestion?.threshold ?: 0.0) * 100)
        .toInt()
        .coerceIn(0, 100)
    val summary = resultText?.takeIf { it.isNotBlank() }
        ?: statusText?.takeIf { it.isNotBlank() }
        ?: "把海报、截图、群通知或一段文字交给织时，我们会先整理，再请你确认。"

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(AppColors.Background)
    ) {
        WeavingBackground()

        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .testTag("home-main-list")
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
                HomeGreeting(
                    userNickname = userNickname,
                    userAccount = userAccount,
                    userAvatarUri = userAvatarUri,
                    todayAgendaCount = todayAgendaCount,
                    onOpenProfile = onOpenProfile,
                    onOpenRecentResults = onOpenRecentResults
                )
            }

            item {
                HomeOverviewCard(
                    todayAgendaCount = todayAgendaCount,
                    scheduledReminderCount = scheduledReminderCount,
                    onClick = onOpenTimeline
                )
            }

            item {
                InputEnergyHub(
                    commandText = commandText,
                    onCommandChanged = onCommandChanged,
                    onSubmitCommandClick = onSubmitCommandClick,
                    onCaptureClick = onCaptureClick,
                    onVoiceStartClick = onVoicePressStart,
                    onVoiceStopClick = onVoicePressEnd,
                    onPasteTextClick = onPasteTextClick,
                    showLivePreview = showLivePreview,
                    isCameraAvailable = isCameraAvailable,
                    isLoading = isLoading,
                    isVoiceListening = isVoiceListening,
                    isVoiceRecordingActive = isVoiceRecordingActive,
                    voiceRecordingMillis = voiceRecordingMillis
                )
            }

            item {
                WeavingSectionTitle(
                    title = "最近识别结果"
                )
            }

            if (showConfirmationCard && confirmationIntent != null && confirmationSuggestion != null) {
                item {
                    PendingReviewCard(
                        title = pendingTitle,
                        time = pendingTime,
                        location = pendingLocation,
                        importedSourceLabel = importedSourceLabel.orEmpty(),
                        confidence = confidence,
                        summary = confirmationSuggestion.prompt,
                        pendingQueueCount = pendingCount,
                        conflictCount = conflictCount,
                        onOpenReview = onOpenReview,
                        onConfirmExecution = onConfirmExecution,
                        onCancelExecution = onCancelExecution
                    )
                }
            } else {
                item {
                    RecentRecognitionCard(summary = summary)
                }
            }
        }
    }
}

private fun isPendingHomeStatus(status: String): Boolean {
    return status.contains("待确认") ||
        status.contains("待补充") ||
        status.contains("待导航") ||
        status.contains("待处理") ||
        status.contains("待校验")
}
