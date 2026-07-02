package com.vsa.visualsemanticagent.ui.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.Image
import androidx.activity.compose.BackHandler
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
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
import androidx.compose.material.icons.rounded.ArrowBack
import androidx.compose.material.icons.rounded.AutoGraph
import androidx.compose.material.icons.rounded.Badge
import androidx.compose.material.icons.rounded.CalendarMonth
import androidx.compose.material.icons.rounded.Cake
import androidx.compose.material.icons.rounded.CameraAlt
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.ChevronRight
import androidx.compose.material.icons.rounded.Delete
import androidx.compose.material.icons.rounded.Download
import androidx.compose.material.icons.rounded.DriveFileRenameOutline
import androidx.compose.material.icons.rounded.Edit
import androidx.compose.material.icons.rounded.EmojiEvents
import androidx.compose.material.icons.rounded.History
import androidx.compose.material.icons.rounded.HomeWork
import androidx.compose.material.icons.rounded.LocationOn
import androidx.compose.material.icons.rounded.Logout
import androidx.compose.material.icons.rounded.ManageAccounts
import androidx.compose.material.icons.rounded.Map
import androidx.compose.material.icons.rounded.NotificationsActive
import androidx.compose.material.icons.rounded.Person
import androidx.compose.material.icons.rounded.PhotoLibrary
import androidx.compose.material.icons.rounded.Psychology
import androidx.compose.material.icons.rounded.School
import androidx.compose.material.icons.rounded.QueryStats
import androidx.compose.material.icons.rounded.Replay
import androidx.compose.material.icons.rounded.Search
import androidx.compose.material.icons.rounded.Security
import androidx.compose.material.icons.rounded.Settings
import androidx.compose.material.icons.rounded.Shield
import androidx.compose.material.icons.rounded.Speed
import androidx.compose.material.icons.rounded.Storage
import androidx.compose.material.icons.rounded.Timeline
import androidx.compose.material.icons.rounded.Tune
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.BottomSheetDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.produceState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import android.graphics.BitmapFactory
import java.io.File
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
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
import com.vsa.visualsemanticagent.ui.common.WeavingSectionTitle
import com.vsa.visualsemanticagent.ui.common.rememberWeavingInteractionSource
import com.vsa.visualsemanticagent.ui.common.weavingClickable
import com.vsa.visualsemanticagent.ui.common.weavingPressFeedback
import com.vsa.visualsemanticagent.notification.InboxMessageData
import com.vsa.visualsemanticagent.notification.displayTimeLabel
import com.vsa.visualsemanticagent.plan.AgendaCardData
import com.vsa.visualsemanticagent.plan.displayDateLabel
import com.vsa.visualsemanticagent.plan.displayTimeLabel
import java.time.LocalDate

private val DetailMetricHeight = 112.dp
private val DetailInfoHeight = 104.dp
private val DetailActionHeight = 70.dp
private val DetailTileHeight = 124.dp

@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun ProfileScreenModule(
    modifier: Modifier = Modifier,
    userNickname: String,
    userAccount: String,
    userAvatarUri: String,
    userSignature: String,
    userBirthday: String,
    userSchool: String,
    userAge: String,
    userGender: String,
    userMajor: String,
    userGrade: String,
    userHometown: String,
    scheduledReminderCount: Int,
    confirmedAgendaCount: Int,
    pendingAgendaCount: Int,
    todayAgendaCount: Int,
    agendaItems: List<AgendaCardData> = emptyList(),
    reminderLeadMinutes: Int,
    reminderDayEnabled: Boolean,
    reminderHourEnabled: Boolean,
    blockHighRisk: Boolean,
    muteLowConfidence: Boolean,
    autoMapLink: Boolean,
    performanceLiteMode: Boolean = false,
    runtimeStatus: AgentRuntimeStatusData = AgentRuntimeStatusData(
        modelName = "Volc-DeepSeek-V3.2",
        appIdReady = true,
        apiKeyReady = true,
        chatEndpoint = "v1/chat/completions",
        ocrEndpoint = "ocr/general_recognition",
        dataStoreReady = true,
        accountReady = userAccount.isNotBlank(),
        cameraReady = true,
        voiceReady = true,
        agendaCount = confirmedAgendaCount + pendingAgendaCount,
        inboxCount = 0,
        reminderCount = scheduledReminderCount
    ),
    onReminderLeadMinutesChange: (Int) -> Unit,
    onReminderDayEnabledChange: (Boolean) -> Unit,
    onReminderHourEnabledChange: (Boolean) -> Unit,
    onBlockHighRiskChange: (Boolean) -> Unit,
    onMuteLowConfidenceChange: (Boolean) -> Unit,
    onAutoMapLinkChange: (Boolean) -> Unit,
    onPerformanceLiteModeChange: (Boolean) -> Unit = {},
    onProfileSave: (
        nickname: String,
        avatarUri: String,
        signature: String,
        birthday: String,
        school: String,
        age: String,
        gender: String,
        major: String,
        grade: String,
        hometown: String
    ) -> Unit,
    onPickProfileAvatar: () -> Unit,
    onCaptureProfileAvatar: () -> Unit,
    onOpenPlan: () -> Unit,
    onReparseHistoryItem: (AgendaCardData) -> Unit = {},
    inboxMessages: List<InboxMessageData> = emptyList(),
    onClearInboxMessages: () -> Unit = {},
    onLogout: () -> Unit
) {
    val routeState = rememberSaveable { mutableStateOf(ProfileRoute.Dashboard) }
    val routeStackState = rememberSaveable { mutableStateOf(listOf(ProfileRoute.Dashboard)) }
    val route = routeState.value
    val routeStack = routeStackState.value

    BackHandler(enabled = route != ProfileRoute.Dashboard) {
        val reduced = routeStack.dropLast(1).ifEmpty { listOf(ProfileRoute.Dashboard) }
        routeStackState.value = reduced
        routeState.value = reduced.last()
    }

    fun navigateTo(target: ProfileRoute) {
        if (target == route) return
        routeStackState.value = routeStack + target
        routeState.value = target
    }

    fun popTo(target: ProfileRoute) {
        val lastIndex = routeStack.lastIndexOf(target)
        val nextStack = if (lastIndex >= 0) {
            routeStack.take(lastIndex + 1)
        } else {
            listOf(ProfileRoute.Dashboard)
        }
        routeStackState.value = nextStack
        routeState.value = nextStack.last()
    }

    Box(
        modifier = modifier
            .fillMaxSize()
            .semantics { testTagsAsResourceId = true }
            .testTag("profile-root")
            .background(AppColors.Background)
    ) {
        WeavingBackground()
        when (route) {
            ProfileRoute.Dashboard -> ProfileDashboard(
                userNickname = userNickname,
                userAccount = userAccount,
                userAvatarUri = userAvatarUri,
                userSignature = userSignature,
                userBirthday = userBirthday,
                userSchool = userSchool,
                userAge = userAge,
                userGender = userGender,
                userMajor = userMajor,
                userGrade = userGrade,
                userHometown = userHometown,
                scheduledReminderCount = scheduledReminderCount,
                confirmedAgendaCount = confirmedAgendaCount,
                pendingAgendaCount = pendingAgendaCount,
                todayAgendaCount = todayAgendaCount,
                reminderLeadMinutes = reminderLeadMinutes,
                reminderDayEnabled = reminderDayEnabled,
                reminderHourEnabled = reminderHourEnabled,
                blockHighRisk = blockHighRisk,
                muteLowConfidence = muteLowConfidence,
                autoMapLink = autoMapLink,
                performanceLiteMode = performanceLiteMode,
                onReminderLeadMinutesChange = onReminderLeadMinutesChange,
                onReminderDayEnabledChange = onReminderDayEnabledChange,
                onReminderHourEnabledChange = onReminderHourEnabledChange,
                onBlockHighRiskChange = onBlockHighRiskChange,
                onMuteLowConfidenceChange = onMuteLowConfidenceChange,
                onAutoMapLinkChange = onAutoMapLinkChange,
                onPerformanceLiteModeChange = onPerformanceLiteModeChange,
                onNavigate = ::navigateTo,
                onLogout = onLogout
            )

            ProfileRoute.AgentCenter -> AgentCenterDetailPage(
                confirmedAgendaCount = confirmedAgendaCount,
                pendingAgendaCount = pendingAgendaCount,
                scheduledReminderCount = scheduledReminderCount,
                todayAgendaCount = todayAgendaCount,
                agendaItems = agendaItems,
                inboxMessages = inboxMessages,
                reminderLeadMinutes = reminderLeadMinutes,
                reminderDayEnabled = reminderDayEnabled,
                reminderHourEnabled = reminderHourEnabled,
                blockHighRisk = blockHighRisk,
                muteLowConfidence = muteLowConfidence,
                autoMapLink = autoMapLink,
                performanceLiteMode = performanceLiteMode,
                runtimeStatus = runtimeStatus.copy(
                    agendaCount = agendaItems.size,
                    inboxCount = inboxMessages.size,
                    reminderCount = scheduledReminderCount,
                    accountReady = userAccount.isNotBlank()
                ),
                onReminderLeadMinutesChange = onReminderLeadMinutesChange,
                onReminderDayEnabledChange = onReminderDayEnabledChange,
                onReminderHourEnabledChange = onReminderHourEnabledChange,
                onBlockHighRiskChange = onBlockHighRiskChange,
                onMuteLowConfidenceChange = onMuteLowConfidenceChange,
                onAutoMapLinkChange = onAutoMapLinkChange,
                onPerformanceLiteModeChange = onPerformanceLiteModeChange,
                onNavigate = ::navigateTo,
                onBack = { popTo(ProfileRoute.Dashboard) },
                onLogout = onLogout
            )

            ProfileRoute.AgentCheckup -> AgentCheckupDetailPage(
                confirmedAgendaCount = confirmedAgendaCount,
                pendingAgendaCount = pendingAgendaCount,
                scheduledReminderCount = scheduledReminderCount,
                agendaItems = agendaItems,
                inboxMessages = inboxMessages,
                blockHighRisk = blockHighRisk,
                muteLowConfidence = muteLowConfidence,
                autoMapLink = autoMapLink,
                onNavigate = ::navigateTo,
                onBack = { popTo(ProfileRoute.AgentCenter) }
            )

            ProfileRoute.History -> HistoryDetailPage(
                confirmedAgendaCount = confirmedAgendaCount,
                pendingAgendaCount = pendingAgendaCount,
                agendaItems = agendaItems,
                onBack = { popTo(ProfileRoute.AgentCenter) },
                onOpenPlan = onOpenPlan,
                onReparseHistoryItem = onReparseHistoryItem
            )

            ProfileRoute.Statistics -> StatisticsDetailPage(
                confirmedAgendaCount = confirmedAgendaCount,
                pendingAgendaCount = pendingAgendaCount,
                todayAgendaCount = todayAgendaCount,
                scheduledReminderCount = scheduledReminderCount,
                agendaItems = agendaItems,
                inboxMessages = inboxMessages,
                onBack = { popTo(ProfileRoute.Dashboard) },
                onOpenPlan = onOpenPlan
            )

            ProfileRoute.Account -> AccountDetailPage(
                userNickname = userNickname,
                userAccount = userAccount,
                userAvatarUri = userAvatarUri,
                userSignature = userSignature,
                userSchool = userSchool,
                userMajor = userMajor,
                userGrade = userGrade,
                onBack = { popTo(ProfileRoute.Dashboard) },
                onOpenPersonalInfo = { navigateTo(ProfileRoute.PersonalInfo) },
                onOpenSettings = { navigateTo(ProfileRoute.Settings) },
                onLogout = onLogout
            )

            ProfileRoute.Achievements -> AchievementsDetailPage(
                confirmedAgendaCount = confirmedAgendaCount,
                pendingAgendaCount = pendingAgendaCount,
                scheduledReminderCount = scheduledReminderCount,
                onBack = { popTo(ProfileRoute.AgentCenter) }
            )

            ProfileRoute.Preferences -> PreferencesDetailPage(
                reminderLeadMinutes = reminderLeadMinutes,
                reminderDayEnabled = reminderDayEnabled,
                reminderHourEnabled = reminderHourEnabled,
                blockHighRisk = blockHighRisk,
                muteLowConfidence = muteLowConfidence,
                autoMapLink = autoMapLink,
                performanceLiteMode = performanceLiteMode,
                onReminderLeadMinutesChange = onReminderLeadMinutesChange,
                onReminderDayEnabledChange = onReminderDayEnabledChange,
                onReminderHourEnabledChange = onReminderHourEnabledChange,
                onBlockHighRiskChange = onBlockHighRiskChange,
                onMuteLowConfidenceChange = onMuteLowConfidenceChange,
                onAutoMapLinkChange = onAutoMapLinkChange,
                onPerformanceLiteModeChange = onPerformanceLiteModeChange,
                onBack = { popTo(ProfileRoute.Dashboard) }
            )

            ProfileRoute.Settings -> SettingsDetailPage(
                userAccount = userAccount,
                onBack = { popTo(ProfileRoute.AgentCenter) },
                onLogout = onLogout
            )

            ProfileRoute.PersonalInfo -> PersonalInfoDetailPage(
                userNickname = userNickname,
                userAccount = userAccount,
                userAvatarUri = userAvatarUri,
                userSignature = userSignature,
                userBirthday = userBirthday,
                userSchool = userSchool,
                userAge = userAge,
                userGender = userGender,
                userMajor = userMajor,
                userGrade = userGrade,
                userHometown = userHometown,
                onBack = { popTo(ProfileRoute.Dashboard) },
                onSave = onProfileSave,
                onPickAvatar = onPickProfileAvatar,
                onCaptureAvatar = onCaptureProfileAvatar
            )

            ProfileRoute.Persona -> PersonaDetailPage(
                userNickname = userNickname,
                confirmedAgendaCount = confirmedAgendaCount,
                pendingAgendaCount = pendingAgendaCount,
                todayAgendaCount = todayAgendaCount,
                scheduledReminderCount = scheduledReminderCount,
                onBack = { popTo(ProfileRoute.AgentCenter) }
            )

            ProfileRoute.ReminderCenter -> ReminderCenterDetailPage(
                reminderLeadMinutes = reminderLeadMinutes,
                reminderDayEnabled = reminderDayEnabled,
                reminderHourEnabled = reminderHourEnabled,
                scheduledReminderCount = scheduledReminderCount,
                onReminderLeadMinutesChange = onReminderLeadMinutesChange,
                onReminderDayEnabledChange = onReminderDayEnabledChange,
                onReminderHourEnabledChange = onReminderHourEnabledChange,
                onBack = { popTo(ProfileRoute.Dashboard) }
            )

            ProfileRoute.TimelineAssets -> TimelineAssetsDetailPage(
                confirmedAgendaCount = confirmedAgendaCount,
                pendingAgendaCount = pendingAgendaCount,
                todayAgendaCount = todayAgendaCount,
                scheduledReminderCount = scheduledReminderCount,
                onBack = { popTo(ProfileRoute.AgentCenter) },
                onOpenPlan = onOpenPlan
            )

            ProfileRoute.ExportRecords -> ExportRecordsDetailPage(
                confirmedAgendaCount = confirmedAgendaCount,
                scheduledReminderCount = scheduledReminderCount,
                onBack = { popTo(ProfileRoute.AgentCenter) },
                onOpenPlan = onOpenPlan
            )

            ProfileRoute.RuntimeStatus -> RuntimeStatusDetailPage(
                runtimeStatus = runtimeStatus.copy(
                    agendaCount = agendaItems.size,
                    inboxCount = inboxMessages.size,
                    reminderCount = scheduledReminderCount,
                    accountReady = userAccount.isNotBlank()
                ),
                performanceLiteMode = performanceLiteMode,
                onPerformanceLiteModeChange = onPerformanceLiteModeChange,
                onBack = { popTo(ProfileRoute.AgentCenter) }
            )

            ProfileRoute.NotificationInbox -> NotificationInboxDetailPage(
                pendingAgendaCount = pendingAgendaCount,
                scheduledReminderCount = scheduledReminderCount,
                inboxMessages = inboxMessages,
                onClearInboxMessages = onClearInboxMessages,
                onBack = { popTo(ProfileRoute.AgentCenter) },
                onOpenPreferences = { navigateTo(ProfileRoute.Preferences) }
            )

            ProfileRoute.PrivacySecurity -> PrivacySecurityDetailPage(
                blockHighRisk = blockHighRisk,
                muteLowConfidence = muteLowConfidence,
                onBlockHighRiskChange = onBlockHighRiskChange,
                onMuteLowConfidenceChange = onMuteLowConfidenceChange,
                onBack = { popTo(ProfileRoute.AgentCenter) }
            )

            ProfileRoute.DataSpace -> DataSpaceDetailPage(
                confirmedAgendaCount = confirmedAgendaCount,
                pendingAgendaCount = pendingAgendaCount,
                scheduledReminderCount = scheduledReminderCount,
                onBack = { popTo(ProfileRoute.AgentCenter) },
                onOpenPlan = onOpenPlan
            )
        }
    }
}

@Composable
private fun ProfileDashboard(
    userNickname: String,
    userAccount: String,
    userAvatarUri: String,
    userSignature: String,
    userBirthday: String,
    userSchool: String,
    userAge: String,
    userGender: String,
    userMajor: String,
    userGrade: String,
    userHometown: String,
    scheduledReminderCount: Int,
    confirmedAgendaCount: Int,
    pendingAgendaCount: Int,
    todayAgendaCount: Int,
    reminderLeadMinutes: Int,
    reminderDayEnabled: Boolean,
    reminderHourEnabled: Boolean,
    blockHighRisk: Boolean,
    muteLowConfidence: Boolean,
    autoMapLink: Boolean,
    performanceLiteMode: Boolean,
    onReminderLeadMinutesChange: (Int) -> Unit,
    onReminderDayEnabledChange: (Boolean) -> Unit,
    onReminderHourEnabledChange: (Boolean) -> Unit,
    onBlockHighRiskChange: (Boolean) -> Unit,
    onMuteLowConfidenceChange: (Boolean) -> Unit,
    onAutoMapLinkChange: (Boolean) -> Unit,
    onPerformanceLiteModeChange: (Boolean) -> Unit,
    onNavigate: (ProfileRoute) -> Unit,
    onLogout: () -> Unit
) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .testTag("profile-dashboard-list")
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
            ProfileHeader(
                userNickname = userNickname,
                userAccount = userAccount,
                userAvatarUri = userAvatarUri,
                userSignature = userSignature,
                userBirthday = userBirthday,
                userSchool = userSchool,
                userAge = userAge,
                userGender = userGender,
                userMajor = userMajor,
                userGrade = userGrade,
                userHometown = userHometown,
                onOpenPersonalInfo = { onNavigate(ProfileRoute.PersonalInfo) }
            )
        }

        item {
            ProfileShortcutGrid(
                onOpenSettings = { onNavigate(ProfileRoute.Settings) },
                onOpenHistory = { onNavigate(ProfileRoute.History) },
                onOpenStatistics = { onNavigate(ProfileRoute.Statistics) },
                onOpenAccount = { onNavigate(ProfileRoute.Account) }
            )
        }

        item {
            ScheduleBoardCard(
                todayAgendaCount = todayAgendaCount,
                pendingAgendaCount = pendingAgendaCount,
                scheduledReminderCount = scheduledReminderCount,
                onOpenTimelineAssets = { onNavigate(ProfileRoute.TimelineAssets) },
                onTodayAgendaClick = { onNavigate(ProfileRoute.TimelineAssets) },
                onPendingClick = { onNavigate(ProfileRoute.NotificationInbox) },
                onReminderClick = { onNavigate(ProfileRoute.ReminderCenter) }
            )
        }

        item {
            AgentCenterEntryCard(
                confirmedAgendaCount = confirmedAgendaCount,
                pendingAgendaCount = pendingAgendaCount,
                scheduledReminderCount = scheduledReminderCount,
                blockHighRisk = blockHighRisk,
                muteLowConfidence = muteLowConfidence,
                autoMapLink = autoMapLink,
                onOpenTimelineAssets = { onNavigate(ProfileRoute.TimelineAssets) },
                onOpenAgentCenter = { onNavigate(ProfileRoute.AgentCenter) }
            )
        }
    }
}

@Composable
private fun ProfileHeader(
    userNickname: String,
    userAccount: String,
    userAvatarUri: String,
    userSignature: String,
    userBirthday: String,
    userSchool: String,
    userAge: String,
    userGender: String,
    userMajor: String,
    userGrade: String,
    userHometown: String,
    onOpenPersonalInfo: () -> Unit
) {
    val schoolLine = listOfNotNull(
        userSchool.takeIf { it.isNotBlank() },
        userMajor.takeIf { it.isNotBlank() },
        userGrade.takeIf { it.isNotBlank() }
    ).joinToString(" · ").ifBlank {
        userAccount.ifBlank { "完善学校、专业与年级信息" }
    }
    val signatureLine = userSignature.ifBlank {
        buildProfileBrief(userBirthday, userAge, userGender, userHometown)
    }.ifBlank {
        "添加一句签名，让织时更懂你的校园节奏"
    }

    WeavingGlassCard(
        modifier = Modifier
            .fillMaxWidth()
            .testTag("profile-personal-card"),
        containerColor = AppColors.SurfaceContainerLowest.copy(alpha = 0.92f),
        onClick = onOpenPersonalInfo,
        interactionStyle = WeavingInteractionStyle.TimelineSlide
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(14.dp),
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.weight(1f)
            ) {
                ProfileAvatar(
                    avatarUri = userAvatarUri,
                    fallbackText = userNickname.ifBlank { userAccount.ifBlank { "织" } },
                    size = 58.dp,
                    onClick = onOpenPersonalInfo
                )
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(
                        text = userNickname.ifBlank { "织时用户" },
                        style = AppTypography.HeadlineLargeMobile,
                        color = AppColors.Primary
                    )
                    Text(
                        text = schoolLine,
                        style = AppTypography.BodyMedium,
                        color = AppColors.OnSurfaceVariant,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    Text(
                        text = signatureLine,
                        style = AppTypography.LabelMedium,
                        color = AppColors.OnSurfaceVariant,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }
            WeavingIconBubble(
                icon = Icons.Rounded.ChevronRight,
                background = AppColors.GoldSoft,
                tint = AppColors.Primary,
                onClick = onOpenPersonalInfo
            )
        }
    }
}

@Composable
private fun ProfileInfoChip(text: String) {
    WeavingChip(
        text = text,
        background = Color.White.copy(alpha = 0.5f),
        contentColor = AppColors.Primary,
        modifier = Modifier.height(30.dp)
    )
}

@Composable
private fun ProfileAvatar(
    avatarUri: String,
    fallbackText: String,
    size: androidx.compose.ui.unit.Dp,
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null
) {
    val loadedBitmap = rememberProfileBitmapState(avatarUri).value
    Box(
        modifier = modifier
            .size(size)
            .clip(CircleShape)
            .background(AppColors.CoralSoft, CircleShape)
            .let { base ->
                if (onClick != null) base.clickable { onClick() } else base
            },
        contentAlignment = Alignment.Center
    ) {
        if (loadedBitmap != null) {
            Image(
                bitmap = loadedBitmap.asImageBitmap(),
                contentDescription = null,
                modifier = Modifier
                    .fillMaxSize()
                    .clip(CircleShape)
                    .background(AppColors.CoralSoft, CircleShape)
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
private fun rememberProfileBitmapState(avatarUri: String): androidx.compose.runtime.State<android.graphics.Bitmap?> {
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

@Composable
private fun ProfileShortcutGrid(
    onOpenSettings: () -> Unit,
    onOpenHistory: () -> Unit,
    onOpenStatistics: () -> Unit,
    onOpenAccount: () -> Unit
) {
    WeavingGlassCard(containerColor = AppColors.SurfaceContainerLowest) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(AppSpacing.sm)
        ) {
            ShortcutEntry(
                modifier = Modifier.weight(1f),
                icon = Icons.Rounded.Settings,
                label = "设置",
                background = AppColors.GoldSoft,
                testTag = "profile-shortcut-settings",
                onClick = onOpenSettings
            )
            ShortcutEntry(
                modifier = Modifier.weight(1f),
                icon = Icons.Rounded.History,
                label = "历史",
                background = AppColors.MintAccent,
                testTag = "profile-shortcut-history",
                onClick = onOpenHistory
            )
            ShortcutEntry(
                modifier = Modifier.weight(1f),
                icon = Icons.Rounded.QueryStats,
                label = "统计",
                background = AppColors.CoralSoft,
                testTag = "profile-shortcut-statistics",
                onClick = onOpenStatistics
            )
            ShortcutEntry(
                modifier = Modifier.weight(1f),
                icon = Icons.Rounded.ManageAccounts,
                label = "账户",
                background = AppColors.SurfaceContainer,
                testTag = "profile-shortcut-account",
                onClick = onOpenAccount
            )
        }
    }
}

@Composable
private fun ShortcutEntry(
    modifier: Modifier,
    icon: ImageVector,
    label: String,
    background: Color,
    testTag: String,
    onClick: () -> Unit
) {
    Column(
        modifier = modifier
            .testTag(testTag)
            .background(Color.White.copy(alpha = 0.42f), RoundedCornerShape(AppShapes.Medium))
            .clickable { onClick() }
            .padding(vertical = 10.dp, horizontal = 5.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(5.dp)
    ) {
        WeavingIconBubble(
            icon = icon,
            background = background,
            tint = AppColors.Primary,
            modifier = Modifier.size(36.dp)
        )
        Text(
            text = label,
            style = AppTypography.LabelSmall,
            color = AppColors.OnSurface,
            fontWeight = FontWeight.Bold
        )
    }
}

@Composable
private fun ScheduleBoardCard(
    todayAgendaCount: Int,
    pendingAgendaCount: Int,
    scheduledReminderCount: Int,
    onOpenTimelineAssets: () -> Unit,
    onTodayAgendaClick: () -> Unit,
    onPendingClick: () -> Unit,
    onReminderClick: () -> Unit
) {
    WeavingGlassCard(containerColor = AppColors.CoralSoft.copy(alpha = 0.82f)) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(
                    text = "日程表",
                    style = AppTypography.LabelSmall,
                    color = AppColors.OnSurfaceVariant
                )
                Text(
                    text = "把今天与后续提醒整理在一张看板里",
                    style = AppTypography.BodyLarge,
                    color = AppColors.Primary,
                    fontWeight = FontWeight.Bold
                )
            }
            WeavingIconBubble(
                icon = Icons.Rounded.CalendarMonth,
                background = AppColors.GoldSoft,
                tint = AppColors.Primary,
                onClick = onOpenTimelineAssets
            )
        }
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(AppSpacing.sm)
        ) {
            MetricPill(
                modifier = Modifier.weight(1f),
                title = "今日安排",
                value = todayAgendaCount.toString(),
                icon = Icons.Rounded.CalendarMonth,
                background = AppColors.GoldSoft,
                onClick = onTodayAgendaClick
            )
            MetricPill(
                modifier = Modifier.weight(1f),
                title = "待确认",
                value = pendingAgendaCount.toString(),
                icon = Icons.Rounded.Shield,
                background = AppColors.CoralSoft,
                onClick = onPendingClick
            )
            MetricPill(
                modifier = Modifier.weight(1f),
                title = "待提醒",
                value = scheduledReminderCount.toString(),
                icon = Icons.Rounded.NotificationsActive,
                background = AppColors.MintAccent,
                onClick = onReminderClick
            )
        }
        WeavingPrimaryButton(
            text = "查看完整时间线",
            onClick = onOpenTimelineAssets,
            modifier = Modifier.fillMaxWidth(),
            icon = Icons.Rounded.Timeline
        )
    }
}

@Composable
private fun AgentCenterEntryCard(
    confirmedAgendaCount: Int,
    pendingAgendaCount: Int,
    scheduledReminderCount: Int,
    blockHighRisk: Boolean,
    muteLowConfidence: Boolean,
    autoMapLink: Boolean,
    onOpenTimelineAssets: () -> Unit,
    onOpenAgentCenter: () -> Unit
) {
    val activePolicies = listOf(blockHighRisk, muteLowConfidence, autoMapLink).count { it }
    WeavingGlassCard(
        modifier = Modifier.testTag("profile-agent-center-card"),
        containerColor = AppColors.SurfaceContainerLowest.copy(alpha = 0.92f),
        onClick = onOpenAgentCenter,
        interactionStyle = WeavingInteractionStyle.TimelineSlide
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                WeavingChip(
                    text = "更多功能",
                    icon = Icons.Rounded.Psychology,
                    background = AppColors.MintAccent,
                    contentColor = AppColors.Primary
                )
                Text(
                    text = "把低频功能收进二级空间",
                    style = AppTypography.HeadlineLargeMobile,
                    color = AppColors.Primary
                )
                Text(
                    text = "成就、画像、提醒策略、隐私边界与导出入口都集中在这里，第一屏只保留高频操作。",
                    style = AppTypography.LabelSmall,
                    color = AppColors.OnSurfaceVariant,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
            }
            WeavingIconBubble(
                icon = Icons.Rounded.ChevronRight,
                background = AppColors.GoldSoft,
                tint = AppColors.Primary,
                onClick = onOpenAgentCenter
            )
        }
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(AppSpacing.sm)
        ) {
            CenterStatusPill(
                title = "资产",
                value = confirmedAgendaCount.toString(),
                background = AppColors.MintAccent,
                onClick = onOpenTimelineAssets
            )
            CenterStatusPill(
                title = "待确认",
                value = pendingAgendaCount.toString(),
                background = AppColors.CoralSoft,
                onClick = onOpenAgentCenter
            )
            CenterStatusPill(
                title = "提醒",
                value = scheduledReminderCount.toString(),
                background = AppColors.GoldSoft,
                onClick = onOpenAgentCenter
            )
            CenterStatusPill(
                title = "策略",
                value = "$activePolicies/3",
                background = AppColors.SurfaceContainer,
                onClick = onOpenAgentCenter
            )
        }
    }
}

@Composable
private fun RowScope.CenterStatusPill(
    modifier: Modifier = Modifier,
    title: String,
    value: String,
    background: Color,
    onClick: () -> Unit
) {
    val interactionSource = rememberWeavingInteractionSource()
    Column(
        modifier = modifier
            .weight(1f)
            .height(58.dp)
            .weavingPressFeedback(interactionSource, WeavingInteractionStyle.IconGlow)
            .background(background, RoundedCornerShape(AppShapes.Medium))
            .weavingClickable(interactionSource, indication = null) { onClick() }
            .padding(horizontal = 8.dp, vertical = 7.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(2.dp)
    ) {
        Text(
            text = value,
            style = AppTypography.BodyLarge,
            color = AppColors.OnSurface,
            fontWeight = FontWeight.Bold,
            maxLines = 1
        )
        Text(
            text = title,
            style = AppTypography.LabelSmall,
            color = AppColors.OnSurfaceVariant,
            maxLines = 1
        )
    }
}

@Composable
private fun SuggestionMiniTile(
    modifier: Modifier = Modifier,
    icon: ImageVector,
    title: String,
    summary: String,
    background: Color,
    onClick: () -> Unit
) {
    WeavingGlassCard(
        modifier = modifier.heightIn(min = 120.dp),
        containerColor = background,
        onClick = onClick,
        interactionStyle = WeavingInteractionStyle.IconGlow
    ) {
        WeavingIconBubble(
            icon = icon,
            background = Color.White.copy(alpha = 0.5f),
            tint = AppColors.Primary,
            modifier = Modifier.size(34.dp)
        )
        Text(
            text = title,
            style = AppTypography.LabelSmall,
            color = AppColors.OnSurface,
            fontWeight = FontWeight.Bold,
            maxLines = 1
        )
        Text(
            text = summary,
            style = AppTypography.LabelSmall,
            color = AppColors.OnSurfaceVariant,
            maxLines = 3,
            overflow = TextOverflow.Ellipsis
        )
    }
}

@Composable
private fun MetricPill(
    modifier: Modifier = Modifier,
    title: String,
    value: String,
    icon: ImageVector,
    background: Color,
    testTag: String? = null,
    onClick: (() -> Unit)? = null
) {
    WeavingGlassCard(
        modifier = modifier
            .height(DetailMetricHeight)
            .then(if (testTag != null) Modifier.testTag(testTag) else Modifier),
        containerColor = background,
        onClick = onClick,
        interactionStyle = WeavingInteractionStyle.IconGlow
    ) {
        WeavingIconBubble(
            icon = icon,
            background = Color.White.copy(alpha = 0.45f),
            tint = AppColors.Primary,
            modifier = Modifier.size(36.dp)
        )
        Text(
            text = value,
            style = AppTypography.DisplayLarge.copy(fontSize = AppTypography.HeadlineLarge.fontSize),
            color = AppColors.OnSurface,
            maxLines = 1
        )
        Text(
            text = title,
            style = AppTypography.LabelSmall,
            color = AppColors.OnSurface,
            maxLines = 1
        )
    }
}

@Composable
private fun AchievementRow(
    confirmedAgendaCount: Int,
    pendingAgendaCount: Int,
    scheduledReminderCount: Int,
    onOpenAll: () -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(AppSpacing.md)) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = "成就勋章",
                style = AppTypography.HeadlineMedium,
                color = AppColors.Primary
            )
            Text(
                text = "查看全部",
                style = AppTypography.LabelMedium,
                color = AppColors.Primary,
                modifier = Modifier.clickable { onOpenAll() }
            )
        }
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(AppSpacing.md)
        ) {
            BadgeCard(
                modifier = Modifier.weight(1f),
                title = "海报小能手",
                subtitle = "累计沉淀 $confirmedAgendaCount 条安排",
                background = AppColors.GoldSoft
            )
            BadgeCard(
                modifier = Modifier.weight(1f),
                title = "考试周守护者",
                subtitle = "仍有 $pendingAgendaCount 条待确认",
                background = AppColors.MintAccent
            )
            BadgeCard(
                modifier = Modifier.weight(1f),
                title = "低噪规划师",
                subtitle = "已挂载 $scheduledReminderCount 条提醒",
                background = AppColors.CoralSoft
            )
        }
    }
}

@Composable
private fun BadgeCard(
    modifier: Modifier = Modifier,
    title: String,
    subtitle: String,
    background: Color
) {
    WeavingGlassCard(
        modifier = modifier.height(DetailTileHeight),
        containerColor = background
    ) {
        Box(
            modifier = Modifier
                .size(40.dp)
                .background(Color.White.copy(alpha = 0.45f), CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Rounded.AutoGraph,
                contentDescription = null,
                tint = AppColors.Primary
            )
        }
        Text(
            text = title,
            style = AppTypography.LabelSmall,
            color = AppColors.OnSurface,
            fontWeight = FontWeight.Bold
        )
        Text(
            text = subtitle,
            style = AppTypography.LabelSmall,
            color = AppColors.OnSurfaceVariant
        )
    }
}

@Composable
private fun DetailSectionHeader(
    title: String,
    summary: String? = null
) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(
            text = title,
            style = AppTypography.HeadlineMedium,
            color = AppColors.Primary
        )
        if (!summary.isNullOrBlank()) {
            Text(
                text = summary,
                style = AppTypography.LabelSmall,
                color = AppColors.OnSurfaceVariant
            )
        }
    }
}

@Composable
private fun DetailMetricRow(vararg metrics: @Composable RowScope.() -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(AppSpacing.md)
    ) {
        metrics.forEach { metric ->
            metric()
        }
    }
}

@Composable
private fun DetailTileGrid(
    title: String,
    summary: String? = null,
    tiles: List<DetailTileSpec>
) {
    Column(verticalArrangement = Arrangement.spacedBy(AppSpacing.sm)) {
        DetailSectionHeader(title = title, summary = summary)
        tiles.chunked(2).forEach { rowTiles ->
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(AppSpacing.md)
            ) {
                rowTiles.forEach { tile ->
                    DetailTileCard(
                        modifier = Modifier.weight(1f),
                        spec = tile
                    )
                }
                if (rowTiles.size == 1) {
                    Spacer(modifier = Modifier.weight(1f))
                }
            }
        }
    }
}

@Composable
private fun DetailTileCard(
    modifier: Modifier = Modifier,
    spec: DetailTileSpec
) {
    WeavingGlassCard(
        modifier = modifier
            .height(DetailTileHeight)
            .then(if (spec.testTag != null) Modifier.testTag(spec.testTag) else Modifier),
        containerColor = spec.background,
        onClick = spec.onClick,
        interactionStyle = WeavingInteractionStyle.IconGlow
    ) {
        WeavingIconBubble(
            icon = spec.icon,
            background = Color.White.copy(alpha = 0.48f),
            tint = AppColors.Primary,
            modifier = Modifier.size(36.dp)
        )
        Text(
            text = spec.title,
            style = AppTypography.LabelSmall,
            color = AppColors.OnSurface,
            fontWeight = FontWeight.Bold,
            maxLines = 2
        )
        Text(
            text = spec.summary,
            style = AppTypography.LabelSmall,
            color = AppColors.OnSurfaceVariant,
            maxLines = 3
        )
    }
}

@Composable
private fun DetailRowGroup(
    title: String,
    summary: String? = null,
    rows: List<DetailTileSpec>
) {
    Column(verticalArrangement = Arrangement.spacedBy(AppSpacing.sm)) {
        DetailSectionHeader(title = title, summary = summary)
        WeavingGlassCard(containerColor = AppColors.SurfaceContainerLowest) {
            rows.forEach { row ->
                DetailMiniRow(
                    icon = row.icon,
                    title = row.title,
                    summary = row.summary,
                    onClick = row.onClick
                )
            }
        }
    }
}

@Composable
private fun PreferenceBoard(
    reminderLeadMinutes: Int,
    reminderDayEnabled: Boolean,
    reminderHourEnabled: Boolean,
    blockHighRisk: Boolean,
    muteLowConfidence: Boolean,
    autoMapLink: Boolean,
    performanceLiteMode: Boolean,
    onReminderLeadMinutesChange: (Int) -> Unit,
    onReminderDayEnabledChange: (Boolean) -> Unit,
    onReminderHourEnabledChange: (Boolean) -> Unit,
    onBlockHighRiskChange: (Boolean) -> Unit,
    onMuteLowConfidenceChange: (Boolean) -> Unit,
    onAutoMapLinkChange: (Boolean) -> Unit,
    onPerformanceLiteModeChange: (Boolean) -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(AppSpacing.md)) {
        WeavingGlassCard {
            PreferenceSwitchRow(
                icon = Icons.Rounded.Shield,
                title = "高风险动作拦截",
                summary = "遇到低确定性或越权操作时先停在你这里",
                checked = blockHighRisk,
                onCheckedChange = onBlockHighRiskChange,
                highlight = true
            )
            PreferenceSwitchRow(
                icon = Icons.Rounded.NotificationsActive,
                title = "低置信度静默处理",
                summary = "置信度不够时避免自动推进，等你来确认",
                checked = muteLowConfidence,
                onCheckedChange = onMuteLowConfidenceChange,
                highlight = true
            )
        }

        WeavingGlassCard {
            PreferenceSwitchRow(
                icon = Icons.Rounded.CalendarMonth,
                title = "默认日级提醒",
                summary = "为重要事件提前一天预热",
                checked = reminderDayEnabled,
                onCheckedChange = onReminderDayEnabledChange
            )
            PreferenceSwitchRow(
                icon = Icons.Rounded.NotificationsActive,
                title = "分钟级提醒",
                summary = "当前默认提前 $reminderLeadMinutes 分钟提醒",
                checked = reminderHourEnabled,
                onCheckedChange = onReminderHourEnabledChange
            )
            PreferenceActionRow(
                icon = Icons.Rounded.Settings,
                title = "提醒提前量",
                summary = "点击可切换为 15 / 30 / 60 分钟",
                actionText = "$reminderLeadMinutes 分钟",
                onClick = {
                    val next = when (reminderLeadMinutes) {
                        15 -> 30
                        30 -> 60
                        else -> 15
                    }
                    onReminderLeadMinutesChange(next)
                }
            )
            PreferenceSwitchRow(
                icon = Icons.Rounded.Timeline,
                title = "地点识别联动",
                summary = "识别到地点后自动补足导航兜底能力",
                checked = autoMapLink,
                onCheckedChange = onAutoMapLinkChange
            )
            PreferenceSwitchRow(
                icon = Icons.Rounded.Speed,
                title = "性能轻量模式",
                summary = "降低星群、扫光和旋转动效负担，适合模拟器或低性能设备",
                checked = performanceLiteMode,
                onCheckedChange = onPerformanceLiteModeChange,
                testTag = "profile-performance-lite-switch"
            )
        }
    }
}

@Composable
private fun PreferenceSwitchRow(
    icon: ImageVector,
    title: String,
    summary: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    highlight: Boolean = false,
    testTag: String? = null
) {
    val interactionSource = rememberWeavingInteractionSource()
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .then(if (testTag != null) Modifier.testTag(testTag) else Modifier)
            .weavingPressFeedback(interactionSource, WeavingInteractionStyle.TimelineSlide)
            .background(
                color = if (highlight) AppColors.SurfaceContainer else Color.White.copy(alpha = 0.45f),
                shape = RoundedCornerShape(AppShapes.Medium)
            )
            .weavingClickable(interactionSource, indication = null) { onCheckedChange(!checked) }
            .padding(16.dp),
        horizontalArrangement = Arrangement.spacedBy(14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        WeavingIconBubble(
            icon = icon,
            background = if (highlight) AppColors.CoralSoft else AppColors.GoldSoft,
            tint = AppColors.Primary
        )
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(2.dp)
        ) {
            Text(
                text = title,
                style = AppTypography.BodyLarge,
                color = AppColors.OnSurface,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = summary,
                style = AppTypography.BodyMedium,
                color = AppColors.OnSurfaceVariant
            )
        }
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            colors = SwitchDefaults.colors(
                checkedThumbColor = AppColors.SurfaceContainerLowest,
                checkedTrackColor = AppColors.Primary,
                uncheckedThumbColor = AppColors.SurfaceContainerLowest,
                uncheckedTrackColor = AppColors.OutlineVariant
            )
        )
    }
}

@Composable
private fun PreferenceActionRow(
    icon: ImageVector,
    title: String,
    summary: String,
    actionText: String,
    onClick: () -> Unit
) {
    val interactionSource = rememberWeavingInteractionSource()
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .weavingPressFeedback(interactionSource, WeavingInteractionStyle.TimelineSlide)
            .background(Color.White.copy(alpha = 0.45f), RoundedCornerShape(AppShapes.Medium))
            .weavingClickable(interactionSource, indication = null) { onClick() }
            .padding(16.dp),
        horizontalArrangement = Arrangement.spacedBy(14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        WeavingIconBubble(icon = icon, background = AppColors.MintAccent, tint = AppColors.Primary)
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(2.dp)
        ) {
            Text(
                text = title,
                style = AppTypography.BodyLarge,
                color = AppColors.OnSurface,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = summary,
                style = AppTypography.BodyMedium,
                color = AppColors.OnSurfaceVariant
            )
        }
        Text(
            text = actionText,
            style = AppTypography.LabelMedium,
            color = AppColors.Primary
        )
    }
}

@Composable
private fun Toolboard(
    onOpenTimelineAssets: () -> Unit,
    onOpenReminderSettings: () -> Unit,
    onOpenExportRecords: () -> Unit,
    onOpenNotificationInbox: () -> Unit,
    onOpenPrivacySecurity: () -> Unit,
    onOpenDataSpace: () -> Unit,
    onOpenSettings: () -> Unit,
    onLogout: () -> Unit
) {
    WeavingGlassCard(containerColor = AppColors.SurfaceContainerLowest) {
        ToolRow(Icons.Rounded.Timeline, "时间线中心", "查看最近沉淀的校园安排", "profile-tool-timeline-assets", onOpenTimelineAssets)
        ToolRow(Icons.Rounded.Tune, "提醒与偏好", "微调默认提醒策略和风险边界", "profile-tool-reminder-center", onOpenReminderSettings)
        ToolRow(Icons.Rounded.NotificationsActive, "通知中心", "集中查看待校验、已提醒和低置信度消息", "profile-tool-notification-inbox", onOpenNotificationInbox)
        ToolRow(Icons.Rounded.Security, "隐私与安全", "管理人在回路、风险拦截和低置信度策略", "profile-tool-privacy-security", onOpenPrivacySecurity)
        ToolRow(Icons.Rounded.Storage, "数据空间", "查看本地时间资产、缓存边界和沉淀规模", "profile-tool-data-space", onOpenDataSpace)
        ToolRow(Icons.Rounded.Download, "导出记录", "为答辩或复盘导出你的时间资产", "profile-tool-export-records", onOpenExportRecords)
        ToolRow(Icons.Rounded.ManageAccounts, "账号与设置", "管理本地账号、缓存和应用边界", "profile-tool-settings", onOpenSettings)
        ToolRow(Icons.Rounded.Logout, "退出登录", "返回登录页并保留本地时间线数据", "profile-tool-logout", onLogout)
    }
}

@Composable
private fun ToolRow(
    icon: ImageVector,
    title: String,
    summary: String,
    testTag: String,
    onClick: () -> Unit
) {
    val interactionSource = rememberWeavingInteractionSource()
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .testTag(testTag)
            .weavingPressFeedback(interactionSource, WeavingInteractionStyle.TimelineSlide)
            .weavingClickable(interactionSource, indication = null) { onClick() }
            .padding(vertical = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        WeavingIconBubble(icon = icon, background = AppColors.MintAccent, tint = AppColors.Primary)
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(2.dp)
        ) {
            Text(
                text = title,
                style = AppTypography.BodyLarge,
                color = AppColors.OnSurface,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = summary,
                style = AppTypography.BodyMedium,
                color = AppColors.OnSurfaceVariant
            )
        }
        Icon(
            imageVector = Icons.Rounded.ChevronRight,
            contentDescription = null,
            tint = AppColors.OnSurfaceVariant
        )
    }
}

@Composable
private fun AgentCenterDetailPage(
    confirmedAgendaCount: Int,
    pendingAgendaCount: Int,
    scheduledReminderCount: Int,
    todayAgendaCount: Int,
    agendaItems: List<AgendaCardData>,
    inboxMessages: List<InboxMessageData>,
    reminderLeadMinutes: Int,
    reminderDayEnabled: Boolean,
    reminderHourEnabled: Boolean,
    blockHighRisk: Boolean,
    muteLowConfidence: Boolean,
    autoMapLink: Boolean,
    performanceLiteMode: Boolean,
    runtimeStatus: AgentRuntimeStatusData,
    onReminderLeadMinutesChange: (Int) -> Unit,
    onReminderDayEnabledChange: (Boolean) -> Unit,
    onReminderHourEnabledChange: (Boolean) -> Unit,
    onBlockHighRiskChange: (Boolean) -> Unit,
    onMuteLowConfidenceChange: (Boolean) -> Unit,
    onAutoMapLinkChange: (Boolean) -> Unit,
    onPerformanceLiteModeChange: (Boolean) -> Unit,
    onNavigate: (ProfileRoute) -> Unit,
    onBack: () -> Unit,
    onLogout: () -> Unit
) {
    val checkupItems = remember(
        agendaItems,
        inboxMessages,
        pendingAgendaCount,
        scheduledReminderCount,
        blockHighRisk,
        muteLowConfidence,
        autoMapLink
    ) {
        buildAgentCheckupItems(
            agendaItems = agendaItems,
            inboxMessages = inboxMessages,
            pendingAgendaCount = pendingAgendaCount,
            scheduledReminderCount = scheduledReminderCount,
            blockHighRisk = blockHighRisk,
            muteLowConfidence = muteLowConfidence,
            autoMapLink = autoMapLink
        )
    }
    val checkupScore = remember(checkupItems) { calculateCheckupScore(checkupItems) }

    DetailScaffold(
        title = "更多功能",
        subtitle = "把完整能力沉到二级页，第一屏只保留高频入口",
        icon = Icons.Rounded.Psychology,
        onBack = onBack
    ) {
        DetailMetricRow(
            {
                MetricPill(
                    modifier = Modifier.weight(1f),
                    title = "已沉淀",
                    value = confirmedAgendaCount.toString(),
                    icon = Icons.Rounded.Timeline,
                    background = AppColors.MintAccent
                )
            },
            {
                MetricPill(
                    modifier = Modifier.weight(1f),
                    title = "待确认",
                    value = pendingAgendaCount.toString(),
                    icon = Icons.Rounded.Shield,
                    background = AppColors.CoralSoft
                )
            }
        )
        AgentCenterFlowCard(
            confirmedAgendaCount = confirmedAgendaCount,
            pendingAgendaCount = pendingAgendaCount,
            scheduledReminderCount = scheduledReminderCount,
            todayAgendaCount = todayAgendaCount,
            onOpenTimelineAssets = { onNavigate(ProfileRoute.TimelineAssets) },
            onOpenNotificationInbox = { onNavigate(ProfileRoute.NotificationInbox) },
            onOpenReminderCenter = { onNavigate(ProfileRoute.ReminderCenter) }
        )
        AgentCheckupEntryCard(
            score = checkupScore,
            issueCount = checkupItems.count { it.level != CheckupLevel.Ready },
            onOpenCheckup = { onNavigate(ProfileRoute.AgentCheckup) }
        )
        DetailTileGrid(
            title = "功能地图",
            summary = "二级页统一承接低频能力，避免我的页第一屏继续堆长列表。",
            tiles = profileFeatureMapTiles(onNavigate)
        )
        DetailSectionHeader(
            title = "边界控制",
            summary = "关键开关仍然可在更多功能页直接调整，减少跳转成本。"
        )
        PreferenceBoard(
            reminderLeadMinutes = reminderLeadMinutes,
            reminderDayEnabled = reminderDayEnabled,
            reminderHourEnabled = reminderHourEnabled,
            blockHighRisk = blockHighRisk,
            muteLowConfidence = muteLowConfidence,
            autoMapLink = autoMapLink,
            performanceLiteMode = performanceLiteMode,
            onReminderLeadMinutesChange = onReminderLeadMinutesChange,
            onReminderDayEnabledChange = onReminderDayEnabledChange,
            onReminderHourEnabledChange = onReminderHourEnabledChange,
            onBlockHighRiskChange = onBlockHighRiskChange,
            onMuteLowConfidenceChange = onMuteLowConfidenceChange,
            onAutoMapLinkChange = onAutoMapLinkChange,
            onPerformanceLiteModeChange = onPerformanceLiteModeChange
        )
        AchievementRow(
            confirmedAgendaCount = confirmedAgendaCount,
            pendingAgendaCount = pendingAgendaCount,
            scheduledReminderCount = scheduledReminderCount,
            onOpenAll = { onNavigate(ProfileRoute.Achievements) }
        )
        DetailRowGroup(
            title = "系统入口",
            summary = "完整工具链仍然可达，但不再压在第一界面。",
            rows = profileSystemEntryTiles(
                runtimeModelName = runtimeStatus.modelName,
                performanceLiteMode = performanceLiteMode,
                onNavigate = onNavigate,
                onLogout = onLogout
            )
        )
    }
}

@Composable
private fun AgentCenterFlowCard(
    confirmedAgendaCount: Int,
    pendingAgendaCount: Int,
    scheduledReminderCount: Int,
    todayAgendaCount: Int,
    onOpenTimelineAssets: () -> Unit,
    onOpenNotificationInbox: () -> Unit,
    onOpenReminderCenter: () -> Unit
) {
    WeavingGlassCard(containerColor = AppColors.SurfaceContainerLowest.copy(alpha = 0.94f)) {
        WeavingSectionTitle(
            title = "能力链路",
            subtitle = "导入、校验、提醒与资产回看"
        )
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(AppSpacing.sm)
        ) {
            SuggestionMiniTile(
                modifier = Modifier.weight(1f),
                icon = Icons.Rounded.History,
                title = "回看",
                summary = "${confirmedAgendaCount} 条资产",
                background = AppColors.MintAccent,
                onClick = onOpenTimelineAssets
            )
            SuggestionMiniTile(
                modifier = Modifier.weight(1f),
                icon = Icons.Rounded.Shield,
                title = "校验",
                summary = "${pendingAgendaCount} 条待办",
                background = AppColors.CoralSoft,
                onClick = onOpenNotificationInbox
            )
            SuggestionMiniTile(
                modifier = Modifier.weight(1f),
                icon = Icons.Rounded.NotificationsActive,
                title = "守护",
                summary = "${scheduledReminderCount} 条提醒",
                background = AppColors.GoldSoft,
                onClick = onOpenReminderCenter
            )
        }
        DetailInfoCard(
            title = "今日状态",
            value = if (todayAgendaCount > 0) "今天还有 $todayAgendaCount 项安排" else "今天留白",
            summary = "第一屏只提示关键信息，完整控制链路集中到本页，避免用户在我的页被低频设置淹没。"
        )
    }
}

@Composable
private fun AgentCheckupEntryCard(
    score: Int,
    issueCount: Int,
    onOpenCheckup: () -> Unit
) {
    val statusText = when {
        issueCount == 0 -> "运行清爽"
        issueCount <= 2 -> "建议微调"
        else -> "需要整理"
    }
    WeavingGlassCard(
        containerColor = AppColors.SurfaceContainerLowest.copy(alpha = 0.94f),
        onClick = onOpenCheckup,
        interactionStyle = WeavingInteractionStyle.TimelineSlide
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            WeavingIconBubble(
                icon = Icons.Rounded.CheckCircle,
                background = if (issueCount == 0) AppColors.MintAccent else AppColors.GoldSoft,
                tint = AppColors.Primary
            )
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "智能体一键体检",
                        style = AppTypography.BodyLarge,
                        color = AppColors.OnSurface,
                        fontWeight = FontWeight.Bold
                    )
                    WeavingChip(
                        text = "$score 分",
                        background = if (issueCount == 0) AppColors.MintAccent else AppColors.CoralSoft,
                        contentColor = AppColors.Primary
                    )
                }
                Text(
                    text = if (issueCount == 0) {
                        "时间线、提醒、风险边界与消息收纳状态良好。"
                    } else {
                        "发现 $issueCount 项可优化内容，点击进入逐项处理。"
                    },
                    style = AppTypography.BodyMedium,
                    color = AppColors.OnSurfaceVariant,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = statusText,
                    style = AppTypography.LabelSmall,
                    color = AppColors.Primary,
                    fontWeight = FontWeight.Bold
                )
            }
            Icon(
                imageVector = Icons.Rounded.ChevronRight,
                contentDescription = null,
                tint = AppColors.OnSurfaceVariant
            )
        }
    }
}

@Composable
private fun AgentCheckupDetailPage(
    confirmedAgendaCount: Int,
    pendingAgendaCount: Int,
    scheduledReminderCount: Int,
    agendaItems: List<AgendaCardData>,
    inboxMessages: List<InboxMessageData>,
    blockHighRisk: Boolean,
    muteLowConfidence: Boolean,
    autoMapLink: Boolean,
    onNavigate: (ProfileRoute) -> Unit,
    onBack: () -> Unit
) {
    val checkupItems = remember(
        agendaItems,
        inboxMessages,
        pendingAgendaCount,
        scheduledReminderCount,
        blockHighRisk,
        muteLowConfidence,
        autoMapLink
    ) {
        buildAgentCheckupItems(
            agendaItems = agendaItems,
            inboxMessages = inboxMessages,
            pendingAgendaCount = pendingAgendaCount,
            scheduledReminderCount = scheduledReminderCount,
            blockHighRisk = blockHighRisk,
            muteLowConfidence = muteLowConfidence,
            autoMapLink = autoMapLink
        )
    }
    val actionCount = remember(checkupItems) { checkupItems.count { it.level == CheckupLevel.Action } }
    val watchCount = remember(checkupItems) { checkupItems.count { it.level == CheckupLevel.Watch } }
    val score = remember(checkupItems) { calculateCheckupScore(checkupItems) }

    DetailScaffold(
        title = "智能体体检",
        subtitle = "逐项检查待确认、提醒、冲突、消息与边界策略",
        icon = Icons.Rounded.CheckCircle,
        onBack = onBack
    ) {
        DetailMetricRow(
            {
                MetricPill(
                    modifier = Modifier.weight(1f),
                    title = "健康分",
                    value = score.toString(),
                    icon = Icons.Rounded.QueryStats,
                    background = if (score >= 90) AppColors.MintAccent else AppColors.GoldSoft
                )
            },
            {
                MetricPill(
                    modifier = Modifier.weight(1f),
                    title = "需处理",
                    value = actionCount.toString(),
                    icon = Icons.Rounded.Shield,
                    background = if (actionCount == 0) AppColors.MintAccent else AppColors.CoralSoft
                )
            }
        )
        DetailMetricRow(
            {
                MetricPill(
                    modifier = Modifier.weight(1f),
                    title = "观察项",
                    value = watchCount.toString(),
                    icon = Icons.Rounded.NotificationsActive,
                    background = if (watchCount == 0) AppColors.SurfaceContainer else AppColors.GoldSoft
                )
            },
            {
                MetricPill(
                    modifier = Modifier.weight(1f),
                    title = "已沉淀",
                    value = confirmedAgendaCount.toString(),
                    icon = Icons.Rounded.Timeline,
                    background = AppColors.MintAccent
                )
            }
        )
        DetailInfoCard(
            title = "体检结论",
            value = buildCheckupConclusion(score, actionCount, watchCount),
            summary = "织时会把低频风险集中到体检页，不挤占首页和我的页第一屏；每个体检项都能跳到对应页面继续处理。"
        )
        CheckupItemSection(
            items = checkupItems,
            onNavigate = onNavigate
        )
        DetailTileGrid(
            title = "快速补强",
            summary = "按主流 App 的任务中心思路，把处理入口压缩为三个高频动作。",
            tiles = listOf(
                DetailTileSpec(Icons.Rounded.NotificationsActive, "处理消息", "${inboxMessages.size} 条系统记录", AppColors.CoralSoft) {
                    onNavigate(ProfileRoute.NotificationInbox)
                },
                DetailTileSpec(Icons.Rounded.Tune, "调整偏好", "提醒与安全边界", AppColors.GoldSoft) {
                    onNavigate(ProfileRoute.Preferences)
                },
                DetailTileSpec(Icons.Rounded.Timeline, "回看资产", "$confirmedAgendaCount 条时间线", AppColors.MintAccent) {
                    onNavigate(ProfileRoute.TimelineAssets)
                },
                DetailTileSpec(Icons.Rounded.Security, "安全策略", "人在回路与静默阈值", AppColors.SurfaceContainer) {
                    onNavigate(ProfileRoute.PrivacySecurity)
                }
            )
        )
        WeavingPrimaryButton(
            text = "返回更多功能",
            onClick = onBack,
            modifier = Modifier.fillMaxWidth(),
            icon = Icons.Rounded.Psychology
        )
    }
}

@Composable
private fun CheckupItemSection(
    items: List<AgentCheckupItem>,
    onNavigate: (ProfileRoute) -> Unit
) {
    Column(verticalArrangement = Arrangement.spacedBy(AppSpacing.sm)) {
        DetailSectionHeader(
            title = "体检清单",
            summary = "点击任意条目进入对应二级页面，保持问题发现到处理的完整闭环。"
        )
        WeavingGlassCard(containerColor = AppColors.SurfaceContainerLowest) {
            items.forEach { item ->
                CheckupItemRow(
                    item = item,
                    onClick = { onNavigate(item.route) }
                )
            }
        }
    }
}

@Composable
private fun CheckupItemRow(
    item: AgentCheckupItem,
    onClick: () -> Unit
) {
    val interactionSource = rememberWeavingInteractionSource()
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .testTag("profile-checkup-${item.title}")
            .weavingPressFeedback(interactionSource, WeavingInteractionStyle.TimelineSlide)
            .background(Color.White.copy(alpha = 0.45f), RoundedCornerShape(AppShapes.Medium))
            .weavingClickable(interactionSource, indication = null) { onClick() }
            .padding(14.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        WeavingIconBubble(
            icon = item.icon,
            background = checkupLevelColor(item.level),
            tint = AppColors.Primary,
            modifier = Modifier.size(38.dp)
        )
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(3.dp)
        ) {
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = item.title,
                    style = AppTypography.BodyLarge,
                    color = AppColors.OnSurface,
                    fontWeight = FontWeight.Bold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                WeavingChip(
                    text = checkupLevelLabel(item.level),
                    background = checkupLevelColor(item.level),
                    contentColor = AppColors.Primary
                )
            }
            Text(
                text = item.summary,
                style = AppTypography.BodyMedium,
                color = AppColors.OnSurfaceVariant,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
        }
        Icon(
            imageVector = Icons.Rounded.ChevronRight,
            contentDescription = null,
            tint = AppColors.OnSurfaceVariant
        )
    }
}

@Composable
private fun DetailScaffold(
    title: String,
    subtitle: String,
    icon: ImageVector,
    onBack: () -> Unit,
    content: @Composable ColumnScope.() -> Unit
) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .testTag("profile-detail-list")
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
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(14.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                WeavingIconBubble(
                    icon = Icons.Rounded.ArrowBack,
                    background = AppColors.SurfaceContainerLowest,
                    tint = AppColors.Primary,
                    onClick = onBack,
                    modifier = Modifier.testTag("profile-detail-back")
                )
                WeavingIconBubble(icon = icon, background = AppColors.GoldSoft, tint = AppColors.Primary)
                Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(
                        text = title,
                        style = AppTypography.HeadlineLargeMobile,
                        color = AppColors.Primary
                    )
                    Text(
                        text = subtitle,
                        style = AppTypography.BodyMedium,
                        color = AppColors.OnSurfaceVariant
                    )
                }
            }
        }

        item {
            Column(verticalArrangement = Arrangement.spacedBy(AppSpacing.md)) {
                content()
            }
        }
    }
}

@Composable
private fun HistoryDetailPage(
    confirmedAgendaCount: Int,
    pendingAgendaCount: Int,
    agendaItems: List<AgendaCardData>,
    onBack: () -> Unit,
    onOpenPlan: () -> Unit,
    onReparseHistoryItem: (AgendaCardData) -> Unit
) {
    val queryState = rememberSaveable { mutableStateOf("") }
    val dateFilterState = rememberSaveable { mutableStateOf("全部") }
    val statusFilterState = rememberSaveable { mutableStateOf("全部") }
    val sourceFilterState = rememberSaveable { mutableStateOf("全部") }
    val query = queryState.value
    val dateFilter = dateFilterState.value
    val statusFilter = statusFilterState.value
    val sourceFilter = sourceFilterState.value
    val today = remember { LocalDate.now() }
    val sourceOptions = remember(agendaItems) { historySourceOptions(agendaItems) }
    val filteredItems = remember(agendaItems, query, dateFilter, statusFilter, sourceFilter) {
        filterHistoryItems(
            agendaItems = agendaItems,
            query = query,
            dateFilter = dateFilter,
            statusFilter = statusFilter,
            sourceFilter = sourceFilter,
            today = today
        )
    }

    DetailScaffold(
        title = "历史记录",
        subtitle = "搜索、筛选并重新解析已经织入的校园碎片",
        icon = Icons.Rounded.History,
        onBack = onBack
    ) {
        HistorySearchPanel(
            query = query,
            onQueryChange = { queryState.value = it },
            dateFilter = dateFilter,
            onDateFilterChange = { dateFilterState.value = it },
            statusFilter = statusFilter,
            onStatusFilterChange = { statusFilterState.value = it },
            sourceFilter = sourceFilter,
            onSourceFilterChange = { sourceFilterState.value = it },
            sourceOptions = sourceOptions
        )
        HistoryResultSection(
            items = filteredItems,
            totalCount = agendaItems.size,
            onOpenPlan = onOpenPlan,
            onReparseHistoryItem = onReparseHistoryItem
        )
        WeavingPrimaryButton(
            text = "进入时间线总览",
            onClick = onOpenPlan,
            modifier = Modifier.fillMaxWidth(),
            icon = Icons.Rounded.Timeline
        )
    }
}

@Composable
private fun HistorySearchPanel(
    query: String,
    onQueryChange: (String) -> Unit,
    dateFilter: String,
    onDateFilterChange: (String) -> Unit,
    statusFilter: String,
    onStatusFilterChange: (String) -> Unit,
    sourceFilter: String,
    onSourceFilterChange: (String) -> Unit,
    sourceOptions: List<String>
) {
    WeavingGlassCard(
        containerColor = AppColors.SurfaceContainerLowest,
        modifier = Modifier.testTag("history-search-panel")
    ) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            WeavingIconBubble(
                icon = Icons.Rounded.Search,
                background = AppColors.MintAccent,
                tint = AppColors.Primary
            )
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(
                    text = "历史资产检索",
                    style = AppTypography.BodyLarge,
                    color = AppColors.OnSurface,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "按标题、地点、来源快速定位",
                    style = AppTypography.BodyMedium,
                    color = AppColors.OnSurfaceVariant
                )
            }
        }
        OutlinedTextField(
            value = query,
            onValueChange = onQueryChange,
            modifier = Modifier
                .fillMaxWidth()
                .testTag("history-search-field"),
            placeholder = {
                Text(
                    text = "搜索讲座、教室、截图来源...",
                    style = AppTypography.BodyMedium
                )
            },
            singleLine = true,
            leadingIcon = {
                Icon(
                    imageVector = Icons.Rounded.Search,
                    contentDescription = null,
                    tint = AppColors.Primary
                )
            },
            textStyle = AppTypography.BodyMedium,
            shape = RoundedCornerShape(AppShapes.Large),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = AppColors.Primary.copy(alpha = 0.55f),
                unfocusedBorderColor = AppColors.GlassBorder,
                focusedContainerColor = Color.White.copy(alpha = 0.56f),
                unfocusedContainerColor = Color.White.copy(alpha = 0.42f),
                cursorColor = AppColors.Primary
            )
        )
        HistoryFilterRow(
            options = listOf("全部", "今日", "本周", "待定"),
            selected = dateFilter,
            onSelected = onDateFilterChange,
            testTagPrefix = "history-date-filter"
        )
        HistoryFilterRow(
            options = listOf("全部", "已确认", "待校验"),
            selected = statusFilter,
            onSelected = onStatusFilterChange,
            testTagPrefix = "history-status-filter"
        )
        HistoryFilterRow(
            options = sourceOptions,
            selected = sourceFilter,
            onSelected = onSourceFilterChange,
            testTagPrefix = "history-source-filter"
        )
    }
}

@Composable
private fun HistoryFilterRow(
    options: List<String>,
    selected: String,
    onSelected: (String) -> Unit,
    testTagPrefix: String
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(AppSpacing.sm),
        verticalAlignment = Alignment.CenterVertically
    ) {
        options.take(5).forEach { option ->
            val isSelected = option == selected
            WeavingGlassCard(
                modifier = Modifier
                    .weight(1f)
                    .height(42.dp)
                    .testTag("$testTagPrefix-$option"),
                containerColor = if (isSelected) AppColors.GoldSoft else Color.White.copy(alpha = 0.5f),
                onClick = { onSelected(option) },
                interactionStyle = WeavingInteractionStyle.IconGlow
            ) {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = option,
                        style = AppTypography.LabelSmall,
                        color = if (isSelected) AppColors.Primary else AppColors.OnSurfaceVariant,
                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }
        }
    }
}

@Composable
private fun HistoryResultSection(
    items: List<AgendaCardData>,
    totalCount: Int,
    onOpenPlan: () -> Unit,
    onReparseHistoryItem: (AgendaCardData) -> Unit
) {
    Column(
        modifier = Modifier.testTag("history-result-section"),
        verticalArrangement = Arrangement.spacedBy(AppSpacing.sm)
    ) {
        DetailSectionHeader(
            title = "检索结果",
            summary = "当前命中 ${items.size} / $totalCount 条，可回看或重新解析。"
        )
        if (items.isEmpty()) {
            WeavingGlassCard(
                containerColor = AppColors.SurfaceContainerLowest,
                modifier = Modifier.testTag("history-empty-state")
            ) {
                WeavingIconBubble(
                    icon = Icons.Rounded.QueryStats,
                    background = AppColors.GoldSoft,
                    tint = AppColors.Primary
                )
                Text(
                    text = "暂未找到匹配记录",
                    style = AppTypography.BodyLarge,
                    color = AppColors.OnSurface,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "可以切换日期、状态或来源筛选，也可以回到时间线查看全部沉淀。",
                    style = AppTypography.BodyMedium,
                    color = AppColors.OnSurfaceVariant
                )
                WeavingPrimaryButton(
                    text = "查看全部时间线",
                    onClick = onOpenPlan,
                    modifier = Modifier.fillMaxWidth(),
                    icon = Icons.Rounded.Timeline
                )
            }
        } else {
            items.take(12).forEach { item ->
                HistoryRecordCard(
                    item = item,
                    onOpenPlan = onOpenPlan,
                    onReparse = { onReparseHistoryItem(item) }
                )
            }
        }
    }
}

@Composable
private fun HistoryRecordCard(
    item: AgendaCardData,
    onOpenPlan: () -> Unit,
    onReparse: () -> Unit
) {
    val statusColor = if (item.status.contains("待")) AppColors.CoralSoft else AppColors.MintAccent
    WeavingGlassCard(
        containerColor = AppColors.SurfaceContainerLowest,
        modifier = Modifier
            .fillMaxWidth()
            .testTag("history-record-${item.id}"),
        onClick = onReparse,
        interactionStyle = WeavingInteractionStyle.TimelineSlide
    ) {
        Row(
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.Top
        ) {
            WeavingIconBubble(
                icon = Icons.Rounded.History,
                background = statusColor,
                tint = AppColors.Primary
            )
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Text(
                    text = item.title.ifBlank { "未命名校园事项" },
                    style = AppTypography.BodyLarge,
                    color = AppColors.OnSurface,
                    fontWeight = FontWeight.Bold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = buildHistoryRecordSummary(item),
                    style = AppTypography.BodyMedium,
                    color = AppColors.OnSurfaceVariant,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    WeavingChip(
                        text = item.status.ifBlank { "待校验" },
                        background = statusColor,
                        contentColor = AppColors.Primary
                    )
                    WeavingChip(
                        text = item.sourceLabel.ifBlank { "未知来源" },
                        background = AppColors.GoldSoft,
                        contentColor = AppColors.Primary
                    )
                }
            }
        }
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(AppSpacing.sm)
        ) {
            HistoryMiniAction(
                modifier = Modifier.weight(1f),
                icon = Icons.Rounded.Timeline,
                text = "查看时间线",
                testTag = "history-open-plan-${item.id}",
                onClick = onOpenPlan
            )
            HistoryMiniAction(
                modifier = Modifier.weight(1f),
                icon = Icons.Rounded.Replay,
                text = "重新解析",
                testTag = "history-reparse-${item.id}",
                onClick = onReparse
            )
        }
    }
}

@Composable
private fun HistoryMiniAction(
    modifier: Modifier,
    icon: ImageVector,
    text: String,
    testTag: String,
    onClick: () -> Unit
) {
    val interactionSource = rememberWeavingInteractionSource()
    Row(
        modifier = modifier
            .height(46.dp)
            .testTag(testTag)
            .weavingPressFeedback(interactionSource, WeavingInteractionStyle.PrimaryPress)
            .background(AppColors.SurfaceContainer, RoundedCornerShape(AppShapes.Full))
            .weavingClickable(interactionSource, indication = null) { onClick() }
            .padding(horizontal = 12.dp),
        horizontalArrangement = Arrangement.Center,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = AppColors.Primary,
            modifier = Modifier.size(16.dp)
        )
        Spacer(modifier = Modifier.size(6.dp))
        Text(
            text = text,
            style = AppTypography.LabelSmall,
            color = AppColors.Primary,
            fontWeight = FontWeight.Bold
        )
    }
}

@Composable
private fun AchievementsDetailPage(
    confirmedAgendaCount: Int,
    pendingAgendaCount: Int,
    scheduledReminderCount: Int,
    onBack: () -> Unit
) {
    DetailScaffold(
        title = "我的成就",
        subtitle = "把每一次信息降噪变成可见的成长反馈",
        icon = Icons.Rounded.EmojiEvents,
        onBack = onBack
    ) {
        DetailMetricRow(
            {
            MetricPill(
                modifier = Modifier.weight(1f),
                title = "沉淀",
                value = confirmedAgendaCount.toString(),
                icon = Icons.Rounded.Storage,
                background = AppColors.GoldSoft
            )
            },
            {
            MetricPill(
                modifier = Modifier.weight(1f),
                title = "提醒",
                value = scheduledReminderCount.toString(),
                icon = Icons.Rounded.NotificationsActive,
                background = AppColors.MintAccent
            )
            }
        )
        DetailTileGrid(
            title = "徽章墙",
            summary = "用成就反馈强化长期习惯，保留答辩时的可视化亮点。",
            tiles = listOf(
                DetailTileSpec(Icons.Rounded.AutoGraph, "海报小能手", "已累计沉淀 $confirmedAgendaCount 条安排", AppColors.GoldSoft),
                DetailTileSpec(Icons.Rounded.NotificationsActive, "低噪规划师", "已挂载 $scheduledReminderCount 条提醒", AppColors.MintAccent),
                DetailTileSpec(Icons.Rounded.Shield, "校验守门人", "$pendingAgendaCount 条待确认，保持 HITL", AppColors.CoralSoft),
                DetailTileSpec(Icons.Rounded.Timeline, "时间线织工", "持续把碎片织成秩序", AppColors.SurfaceContainer)
            )
        )
        DetailRowGroup(
            title = "解锁路径",
            rows = listOf(
                DetailTileSpec(Icons.Rounded.History, "连续织入", "连续把讲座、会议和群通知转为时间线，可提升徽章等级。"),
                DetailTileSpec(Icons.Rounded.QueryStats, "低置信度校验", "主动修正时间和地点字段，可强化安全型成就。"),
                DetailTileSpec(Icons.Rounded.Download, "答辩导出", "导出时间线资产后，可补充展示型徽章。")
            )
        )
        DetailInfoCard(
            title = "下一枚徽章",
            value = "连续织入",
            summary = "继续把讲座、会议和群通知转为时间线，可解锁更高等级的低噪规划徽章。"
        )
    }
}

@Composable
private fun PreferencesDetailPage(
    reminderLeadMinutes: Int,
    reminderDayEnabled: Boolean,
    reminderHourEnabled: Boolean,
    blockHighRisk: Boolean,
    muteLowConfidence: Boolean,
    autoMapLink: Boolean,
    performanceLiteMode: Boolean,
    onReminderLeadMinutesChange: (Int) -> Unit,
    onReminderDayEnabledChange: (Boolean) -> Unit,
    onReminderHourEnabledChange: (Boolean) -> Unit,
    onBlockHighRiskChange: (Boolean) -> Unit,
    onMuteLowConfidenceChange: (Boolean) -> Unit,
    onAutoMapLinkChange: (Boolean) -> Unit,
    onPerformanceLiteModeChange: (Boolean) -> Unit,
    onBack: () -> Unit
) {
    DetailScaffold(
        title = "我的偏好",
        subtitle = "集中管理提醒、风控和地点联动策略",
        icon = Icons.Rounded.Tune,
        onBack = onBack
    ) {
        PreferenceBoard(
            reminderLeadMinutes = reminderLeadMinutes,
            reminderDayEnabled = reminderDayEnabled,
            reminderHourEnabled = reminderHourEnabled,
            blockHighRisk = blockHighRisk,
            muteLowConfidence = muteLowConfidence,
            autoMapLink = autoMapLink,
            performanceLiteMode = performanceLiteMode,
            onReminderLeadMinutesChange = onReminderLeadMinutesChange,
            onReminderDayEnabledChange = onReminderDayEnabledChange,
            onReminderHourEnabledChange = onReminderHourEnabledChange,
            onBlockHighRiskChange = onBlockHighRiskChange,
            onMuteLowConfidenceChange = onMuteLowConfidenceChange,
            onAutoMapLinkChange = onAutoMapLinkChange,
            onPerformanceLiteModeChange = onPerformanceLiteModeChange
        )
        DetailTileGrid(
            title = "偏好模板",
            summary = "二级页补充常见效率工具里的快捷策略，便于答辩展示“可配置的智能体边界”。",
            tiles = listOf(
                DetailTileSpec(Icons.Rounded.Shield, "考试周模式", "高风险必确认，提醒提前一天", AppColors.CoralSoft),
                DetailTileSpec(Icons.Rounded.NotificationsActive, "日常轻提醒", "只保留临近提醒，减少打扰", AppColors.GoldSoft),
                DetailTileSpec(Icons.Rounded.Map, "通勤兜底", "地点明确时优先生成导航线索", AppColors.MintAccent),
                DetailTileSpec(Icons.Rounded.Tune, "手动校验优先", "低置信度先停下，不自动写入", AppColors.SurfaceContainer)
            )
        )
    }
}

@Composable
private fun ReminderCenterDetailPage(
    reminderLeadMinutes: Int,
    reminderDayEnabled: Boolean,
    reminderHourEnabled: Boolean,
    scheduledReminderCount: Int,
    onReminderLeadMinutesChange: (Int) -> Unit,
    onReminderDayEnabledChange: (Boolean) -> Unit,
    onReminderHourEnabledChange: (Boolean) -> Unit,
    onBack: () -> Unit
) {
    DetailScaffold(
        title = "提醒中心",
        subtitle = "把每一次关键校园安排提前交给系统守护",
        icon = Icons.Rounded.NotificationsActive,
        onBack = onBack
    ) {
        DetailMetricRow(
            {
            MetricPill(
                modifier = Modifier.weight(1f),
                title = "已挂载",
                value = scheduledReminderCount.toString(),
                icon = Icons.Rounded.NotificationsActive,
                background = AppColors.GoldSoft
            )
            },
            {
            MetricPill(
                modifier = Modifier.weight(1f),
                title = "提前量",
                value = reminderLeadMinutes.toString(),
                icon = Icons.Rounded.Tune,
                background = AppColors.MintAccent
            )
            }
        )
        WeavingGlassCard(containerColor = AppColors.SurfaceContainerLowest) {
            PreferenceSwitchRow(
                icon = Icons.Rounded.CalendarMonth,
                title = "提前一天预热",
                summary = "适合考试、竞赛、答辩等需要提前准备的高价值事项。",
                checked = reminderDayEnabled,
                onCheckedChange = onReminderDayEnabledChange,
                highlight = true
            )
            PreferenceSwitchRow(
                icon = Icons.Rounded.NotificationsActive,
                title = "临近前提醒",
                summary = "当前临近提醒提前 $reminderLeadMinutes 分钟触发。",
                checked = reminderHourEnabled,
                onCheckedChange = onReminderHourEnabledChange,
                highlight = true
            )
            PreferenceActionRow(
                icon = Icons.Rounded.Tune,
                title = "切换提前量",
                summary = "在 15 / 30 / 60 分钟之间循环，适配不同校园距离。",
                actionText = "$reminderLeadMinutes 分钟",
                onClick = {
                    val next = when (reminderLeadMinutes) {
                        15 -> 30
                        30 -> 60
                        else -> 15
                    }
                    onReminderLeadMinutesChange(next)
                }
            )
        }
        DetailTileGrid(
            title = "提醒策略",
            summary = "参考成熟任务应用的多层提醒思路，但只保留校园高频场景。",
            tiles = listOf(
                DetailTileSpec(Icons.Rounded.Shield, "高风险先确认", "考试 / 截止 / 地点不明先停下", AppColors.CoralSoft),
                DetailTileSpec(Icons.Rounded.CalendarMonth, "日级预热", "先给准备窗口，避免临时赶场", AppColors.GoldSoft),
                DetailTileSpec(Icons.Rounded.NotificationsActive, "分钟级提醒", "出门前再次触达", AppColors.MintAccent),
                DetailTileSpec(Icons.Rounded.Map, "地点兜底", "明确地点后可联动导航", AppColors.SurfaceContainer)
            )
        )
        DetailInfoCard(
            title = "策略说明",
            value = "人在回路",
            summary = "织时不会绕过确认卡直接替你建立高风险提醒；字段可信后才进入本地提醒。"
        )
    }
}

@Composable
private fun TimelineAssetsDetailPage(
    confirmedAgendaCount: Int,
    pendingAgendaCount: Int,
    todayAgendaCount: Int,
    scheduledReminderCount: Int,
    onBack: () -> Unit,
    onOpenPlan: () -> Unit
) {
    DetailScaffold(
        title = "时间线资产",
        subtitle = "查看碎片被织入秩序后的沉淀结果",
        icon = Icons.Rounded.Timeline,
        onBack = onBack
    ) {
        DetailMetricRow(
            {
            MetricPill(
                modifier = Modifier.weight(1f),
                title = "已确认",
                value = confirmedAgendaCount.toString(),
                icon = Icons.Rounded.Storage,
                background = AppColors.GoldSoft,
                testTag = "timeline-assets-metric-confirmed",
                onClick = onOpenPlan
            )
            },
            {
            MetricPill(
                modifier = Modifier.weight(1f),
                title = "今日",
                value = todayAgendaCount.toString(),
                icon = Icons.Rounded.QueryStats,
                background = AppColors.MintAccent,
                testTag = "timeline-assets-metric-today",
                onClick = onOpenPlan
            )
            }
        )
        DetailMetricRow(
            {
            MetricPill(
                modifier = Modifier.weight(1f),
                title = "待校验",
                value = pendingAgendaCount.toString(),
                icon = Icons.Rounded.Shield,
                background = AppColors.CoralSoft,
                testTag = "timeline-assets-metric-pending",
                onClick = onOpenPlan
            )
            },
            {
            MetricPill(
                modifier = Modifier.weight(1f),
                title = "待提醒",
                value = scheduledReminderCount.toString(),
                icon = Icons.Rounded.NotificationsActive,
                background = AppColors.SurfaceContainer,
                testTag = "timeline-assets-metric-reminder",
                onClick = onOpenPlan
            )
            }
        )
        DetailInfoCard(
            title = "资产状态",
            value = "持续织入",
            summary = "每一次确认写入都会把零散通知变成可检索、可提醒、可导出的个人时间资产。"
        )
        DetailTileGrid(
            title = "资产能力",
            summary = "把时间线做成可复盘、可检索、可导出的个人校园资产。",
            tiles = listOf(
                DetailTileSpec(Icons.Rounded.History, "来源可追溯", "保留文本 / 截图 / 海报语义", AppColors.GoldSoft),
                DetailTileSpec(Icons.Rounded.QueryStats, "密度可感知", "快速判断本周时间压力", AppColors.MintAccent),
                DetailTileSpec(Icons.Rounded.Download, "成果可导出", "答辩、复盘材料一键整理", AppColors.SurfaceContainer),
                DetailTileSpec(Icons.Rounded.Shield, "风险可回看", "待校验事项不会被埋掉", AppColors.CoralSoft)
            )
        )
        WeavingPrimaryButton(
            text = "打开时间线",
            onClick = onOpenPlan,
            modifier = Modifier.fillMaxWidth(),
            icon = Icons.Rounded.Timeline
        )
    }
}

@Composable
private fun ExportRecordsDetailPage(
    confirmedAgendaCount: Int,
    scheduledReminderCount: Int,
    onBack: () -> Unit,
    onOpenPlan: () -> Unit
) {
    DetailScaffold(
        title = "导出记录",
        subtitle = "为答辩、复盘和学习规划整理时间资产",
        icon = Icons.Rounded.Download,
        onBack = onBack
    ) {
        DetailMetricRow(
            {
            MetricPill(
                modifier = Modifier.weight(1f),
                title = "时间线",
                value = confirmedAgendaCount.toString(),
                icon = Icons.Rounded.Timeline,
                background = AppColors.GoldSoft
            )
            },
            {
            MetricPill(
                modifier = Modifier.weight(1f),
                title = "提醒",
                value = scheduledReminderCount.toString(),
                icon = Icons.Rounded.NotificationsActive,
                background = AppColors.MintAccent
            )
            }
        )
        DetailTileGrid(
            title = "导出类型",
            summary = "让评委看到的不只是 App 页面，也是可交付的时间资产。",
            tiles = listOf(
                DetailTileSpec(Icons.Rounded.Download, "PDF 归档", "答辩材料 / 课程复盘", AppColors.GoldSoft),
                DetailTileSpec(Icons.Rounded.QueryStats, "长图展示", "适合群聊分享和作品页", AppColors.MintAccent),
                DetailTileSpec(Icons.Rounded.Map, "地点上下文", "保留地图导航线索", AppColors.SurfaceContainer),
                DetailTileSpec(Icons.Rounded.Timeline, "周期筛选", "日 / 周 / 月视图后再导出", AppColors.CoralSoft)
            )
        )
        DetailInfoCard(
            title = "导出建议",
            value = "先筛选，再导出",
            summary = "建议在时间线页切换日 / 周 / 月后再导出，答辩展示更清晰。"
        )
        WeavingPrimaryButton(
            text = "前往时间线导出",
            onClick = onOpenPlan,
            modifier = Modifier.fillMaxWidth(),
            icon = Icons.Rounded.Download
        )
    }
}

@Composable
private fun RuntimeStatusDetailPage(
    runtimeStatus: AgentRuntimeStatusData,
    performanceLiteMode: Boolean,
    onPerformanceLiteModeChange: (Boolean) -> Unit,
    onBack: () -> Unit
) {
    val readyCount = remember(runtimeStatus, performanceLiteMode) {
        runtimeReadyCount(runtimeStatus)
    }
    val statusRows = remember(runtimeStatus, performanceLiteMode) {
        runtimeStatusRows(runtimeStatus, performanceLiteMode)
    }

    DetailScaffold(
        title = "运行状态",
        subtitle = "模型、OCR、存储、提醒和性能负载的真实状态面板",
        icon = Icons.Rounded.Speed,
        onBack = onBack
    ) {
        DetailMetricRow(
            {
                MetricPill(
                    modifier = Modifier.weight(1f),
                    title = "就绪模块",
                    value = "$readyCount/6",
                    icon = Icons.Rounded.CheckCircle,
                    background = if (readyCount >= 5) AppColors.MintAccent else AppColors.GoldSoft
                )
            },
            {
                MetricPill(
                    modifier = Modifier.weight(1f),
                    title = "动效模式",
                    value = if (performanceLiteMode) "Lite" else "Full",
                    icon = Icons.Rounded.Speed,
                    background = if (performanceLiteMode) AppColors.GoldSoft else AppColors.MintAccent
                )
            }
        )
        DetailInfoCard(
            title = "接口状态",
            value = if (runtimeStatus.apiKeyReady && runtimeStatus.appIdReady) "真实接入" else "待配置",
            summary = "当前模型链路指向 ${runtimeStatus.modelName}，聊天接口 ${endpointTail(runtimeStatus.chatEndpoint)}，OCR 接口 ${endpointTail(runtimeStatus.ocrEndpoint)}。"
        )
        RuntimeStatusBoard(rows = statusRows)
        WeavingGlassCard(containerColor = AppColors.SurfaceContainerLowest) {
            PreferenceSwitchRow(
                icon = Icons.Rounded.Speed,
                title = "性能轻量模式",
                summary = "开启后会降低解析校验页星群、加载层旋转和扫光动画负担。",
                checked = performanceLiteMode,
                onCheckedChange = onPerformanceLiteModeChange,
                highlight = true,
                testTag = "profile-runtime-lite-switch"
            )
        }
        DetailTileGrid(
            title = "演示建议",
            summary = "答辩现场如果模拟器卡顿，优先打开轻量模式；真机性能充足时可恢复完整动效。",
            tiles = listOf(
                DetailTileSpec(Icons.Rounded.Speed, "低性能设备", "开启轻量模式", AppColors.GoldSoft),
                DetailTileSpec(Icons.Rounded.Psychology, "模型演示", "保留真实 API 链路", AppColors.MintAccent),
                DetailTileSpec(Icons.Rounded.Storage, "数据演示", "先准备 2-3 条时间资产", AppColors.SurfaceContainer),
                DetailTileSpec(Icons.Rounded.NotificationsActive, "提醒演示", "确认提醒数量不为 0", AppColors.CoralSoft)
            )
        )
    }
}

@Composable
private fun RuntimeStatusBoard(rows: List<RuntimeStatusRowSpec>) {
    Column(verticalArrangement = Arrangement.spacedBy(AppSpacing.sm)) {
        DetailSectionHeader(
            title = "模块状态",
            summary = "这里展示的是当前 App 可读到的工程状态，不是静态说明卡。"
        )
        WeavingGlassCard(containerColor = AppColors.SurfaceContainerLowest) {
            rows.forEach { row ->
                RuntimeStatusRow(row)
            }
        }
    }
}

@Composable
private fun RuntimeStatusRow(row: RuntimeStatusRowSpec) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = DetailActionHeight)
            .background(Color.White.copy(alpha = 0.45f), RoundedCornerShape(AppShapes.Medium))
            .padding(14.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        WeavingIconBubble(
            icon = row.icon,
            background = if (row.ready) AppColors.MintAccent else AppColors.CoralSoft,
            tint = AppColors.Primary,
            modifier = Modifier.size(38.dp)
        )
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(3.dp)
        ) {
            Text(
                text = row.title,
                style = AppTypography.BodyLarge,
                color = AppColors.OnSurface,
                fontWeight = FontWeight.Bold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                text = row.summary,
                style = AppTypography.BodyMedium,
                color = AppColors.OnSurfaceVariant,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }
        WeavingChip(
            text = if (row.ready) "正常" else "待处理",
            background = if (row.ready) AppColors.MintAccent else AppColors.CoralSoft,
            contentColor = AppColors.Primary
        )
    }
}

@Composable
private fun NotificationInboxDetailPage(
    pendingAgendaCount: Int,
    scheduledReminderCount: Int,
    inboxMessages: List<InboxMessageData>,
    onClearInboxMessages: () -> Unit,
    onBack: () -> Unit,
    onOpenPreferences: () -> Unit
) {
    val selectedFilterState = rememberSaveable { mutableStateOf(InboxFilter.ALL.name) }
    val selectedMessageIdState = rememberSaveable { mutableStateOf("") }
    val selectedFilter = selectedFilterState.value
    val selectedMessageId = selectedMessageIdState.value
    val unreadCount = remember(inboxMessages) {
        inboxMessages.count { it.status.contains("待") || it.status.contains("未读") }
    }
    val filter = remember(selectedFilter) { InboxFilter.valueOf(selectedFilter) }
    val filteredMessages = remember(inboxMessages, filter) {
        filterInboxMessages(inboxMessages, filter)
    }
    val latestMessages = remember(filteredMessages) { filteredMessages.take(20) }
    val selectedMessage = remember(selectedMessageId, inboxMessages) {
        inboxMessages.firstOrNull { it.id == selectedMessageId }
    }

    DetailScaffold(
        title = "通知中心",
        subtitle = "把待确认、已提醒和低置信度消息集中收纳",
        icon = Icons.Rounded.NotificationsActive,
        onBack = onBack
    ) {
        DetailMetricRow(
            {
                MetricPill(
                    modifier = Modifier.weight(1f),
                    title = "待校验",
                    value = pendingAgendaCount.toString(),
                    icon = Icons.Rounded.Shield,
                    background = AppColors.CoralSoft
                )
            },
            {
                MetricPill(
                    modifier = Modifier.weight(1f),
                    title = "已提醒",
                    value = scheduledReminderCount.toString(),
                    icon = Icons.Rounded.NotificationsActive,
                    background = AppColors.GoldSoft
                )
            }
        )
        DetailTileGrid(
            title = "消息概览",
            summary = "像主流任务 App 的 Inbox 一样，把 AI 解析、风险拦截和时间线操作集中起来。",
            tiles = listOf(
                DetailTileSpec(
                    Icons.Rounded.NotificationsActive,
                    "全部消息",
                    "${inboxMessages.size} 条事件记录",
                    AppColors.GoldSoft,
                    testTag = "profile-inbox-filter-all"
                ) {
                    selectedFilterState.value = InboxFilter.ALL.name
                },
                DetailTileSpec(
                    Icons.Rounded.Shield,
                    "待处理",
                    "$unreadCount 条需要复核",
                    AppColors.CoralSoft,
                    testTag = "profile-inbox-filter-pending"
                ) {
                    selectedFilterState.value = InboxFilter.PENDING.name
                },
                DetailTileSpec(
                    Icons.Rounded.QueryStats,
                    "解析反馈",
                    "低置信度与失败会保留原因",
                    AppColors.MintAccent,
                    testTag = "profile-inbox-filter-feedback"
                ) {
                    selectedFilterState.value = InboxFilter.FEEDBACK.name
                },
                DetailTileSpec(Icons.Rounded.Tune, "通知策略", "调整提醒与静默规则", AppColors.SurfaceContainer, onClick = onOpenPreferences)
            )
        )
        InboxMessageSection(
            messages = latestMessages,
            filter = filter,
            onClearInboxMessages = onClearInboxMessages,
            onOpenMessage = { selectedMessageIdState.value = it.id }
        )
        WeavingPrimaryButton(
            text = "调整通知策略",
            onClick = onOpenPreferences,
            modifier = Modifier.fillMaxWidth(),
            icon = Icons.Rounded.Tune
        )
    }

    selectedMessage?.let { message ->
        AlertDialog(
            onDismissRequest = { selectedMessageIdState.value = "" },
            title = { Text(message.title.ifBlank { "织时消息" }) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("状态：${message.status.ifBlank { "未读" }}")
                    Text("时间：${message.displayTimeLabel()}")
                    Text(message.summary.ifBlank { "暂无摘要" })
                }
            },
            confirmButton = {
                TextButton(onClick = { selectedMessageIdState.value = "" }) {
                    Text("关闭")
                }
            }
        )
    }
}

@Composable
private fun InboxMessageSection(
    messages: List<InboxMessageData>,
    filter: InboxFilter,
    onClearInboxMessages: () -> Unit,
    onOpenMessage: (InboxMessageData) -> Unit
) {
    Column(
        modifier = Modifier.testTag("profile-inbox-section"),
        verticalArrangement = Arrangement.spacedBy(AppSpacing.sm)
    ) {
        DetailSectionHeader(
            title = inboxSectionTitle(filter),
            summary = if (messages.isEmpty()) {
                inboxEmptySummary(filter)
            } else {
                "按时间倒序展示最近 ${messages.size} 条，点击任意消息可查看完整状态。"
            }
        )

        if (messages.isEmpty()) {
            DetailInfoCard(
                title = "收纳箱",
                value = "干净",
                summary = "当你导入图片、确认日程、取消执行或遇到低置信度结果时，这里会保留可回看的系统记录。"
            )
            return@Column
        }

        WeavingGlassCard(containerColor = AppColors.SurfaceContainerLowest) {
            messages.forEach { message ->
                InboxMessageRow(
                    message = message,
                    onClick = { onOpenMessage(message) }
                )
            }
        }
        WeavingPrimaryButton(
            text = "清空通知中心",
            onClick = onClearInboxMessages,
            modifier = Modifier
                .fillMaxWidth()
                .testTag("profile-inbox-clear"),
            icon = Icons.Rounded.Delete
        )
    }
}

@Composable
private fun InboxMessageRow(
    message: InboxMessageData,
    onClick: () -> Unit
) {
    val icon = inboxMessageIcon(message.type, message.status)
    val background = inboxMessageBackground(message.type, message.status)
    val interactionSource = rememberWeavingInteractionSource()
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = DetailActionHeight)
            .background(Color.White.copy(alpha = 0.45f), RoundedCornerShape(AppShapes.Medium))
            .weavingPressFeedback(interactionSource, WeavingInteractionStyle.TimelineSlide)
            .weavingClickable(interactionSource, indication = null) { onClick() }
            .padding(16.dp),
        horizontalArrangement = Arrangement.spacedBy(14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        WeavingIconBubble(icon = icon, background = background, tint = AppColors.Primary)
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(4.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = message.title.ifBlank { "织时消息" },
                    style = AppTypography.BodyLarge,
                    color = AppColors.OnSurface,
                    fontWeight = FontWeight.Bold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                WeavingChip(
                    text = message.status.ifBlank { "未读" },
                    background = background,
                    contentColor = AppColors.Primary
                )
            }
            Text(
                text = message.summary.ifBlank { "暂无摘要" },
                style = AppTypography.BodyMedium,
                color = AppColors.OnSurfaceVariant,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                text = message.displayTimeLabel(),
                style = AppTypography.LabelSmall,
                color = AppColors.OnSurfaceVariant
            )
        }
    }
}

@Composable
private fun PrivacySecurityDetailPage(
    blockHighRisk: Boolean,
    muteLowConfidence: Boolean,
    onBlockHighRiskChange: (Boolean) -> Unit,
    onMuteLowConfidenceChange: (Boolean) -> Unit,
    onBack: () -> Unit
) {
    DetailScaffold(
        title = "隐私与安全",
        subtitle = "明确 AI 能做什么、什么时候必须停下来问你",
        icon = Icons.Rounded.Security,
        onBack = onBack
    ) {
        WeavingGlassCard(containerColor = AppColors.SurfaceContainerLowest) {
            PreferenceSwitchRow(
                icon = Icons.Rounded.Shield,
                title = "高风险动作拦截",
                summary = "考试、截止、地点不明等事项必须先经你确认。",
                checked = blockHighRisk,
                onCheckedChange = onBlockHighRiskChange,
                highlight = true
            )
            PreferenceSwitchRow(
                icon = Icons.Rounded.NotificationsActive,
                title = "低置信度静默处理",
                summary = "置信度不足时不自动推进，减少误写入风险。",
                checked = muteLowConfidence,
                onCheckedChange = onMuteLowConfidenceChange,
                highlight = true
            )
        }
        DetailTileGrid(
            title = "安全边界",
            summary = "让评委能一眼看懂：织时不是黑盒代办，而是可控智能体。",
            tiles = listOf(
                DetailTileSpec(Icons.Rounded.Security, "人在回路", "确认后才写入高风险日程", AppColors.CoralSoft),
                DetailTileSpec(Icons.Rounded.Storage, "本地沉淀", "账号与偏好保存在设备侧", AppColors.GoldSoft),
                DetailTileSpec(Icons.Rounded.Psychology, "模型可解释", "展示信心指数与结构化字段", AppColors.MintAccent),
                DetailTileSpec(Icons.Rounded.Map, "地点兜底", "地点明确才联动导航", AppColors.SurfaceContainer)
            )
        )
        DetailInfoCard(
            title = "隐私说明",
            value = "最小必要",
            summary = "织时只围绕校园通知解析、日程确认、提醒和时间线沉淀组织数据，不把低置信度结果直接越权执行。"
        )
    }
}

@Composable
private fun DataSpaceDetailPage(
    confirmedAgendaCount: Int,
    pendingAgendaCount: Int,
    scheduledReminderCount: Int,
    onBack: () -> Unit,
    onOpenPlan: () -> Unit
) {
    DetailScaffold(
        title = "数据空间",
        subtitle = "查看已经沉淀在本地的时间资产与缓存边界",
        icon = Icons.Rounded.Storage,
        onBack = onBack
    ) {
        DetailMetricRow(
            {
                MetricPill(
                    modifier = Modifier.weight(1f),
                    title = "已确认",
                    value = confirmedAgendaCount.toString(),
                    icon = Icons.Rounded.Timeline,
                    background = AppColors.GoldSoft
                )
            },
            {
                MetricPill(
                    modifier = Modifier.weight(1f),
                    title = "待处理",
                    value = pendingAgendaCount.toString(),
                    icon = Icons.Rounded.Shield,
                    background = AppColors.CoralSoft
                )
            }
        )
        DetailMetricRow(
            {
                MetricPill(
                    modifier = Modifier.weight(1f),
                    title = "提醒",
                    value = scheduledReminderCount.toString(),
                    icon = Icons.Rounded.NotificationsActive,
                    background = AppColors.MintAccent
                )
            },
            {
                MetricPill(
                    modifier = Modifier.weight(1f),
                    title = "本地库",
                    value = "ON",
                    icon = Icons.Rounded.Storage,
                    background = AppColors.SurfaceContainer
                )
            }
        )
        DetailTileGrid(
            title = "数据分层",
            tiles = listOf(
                DetailTileSpec(Icons.Rounded.History, "导入来源", "文本、截图、海报和语音统一建模", AppColors.GoldSoft),
                DetailTileSpec(Icons.Rounded.Psychology, "解析结果", "保留结构化字段和信心指数", AppColors.MintAccent),
                DetailTileSpec(Icons.Rounded.Timeline, "时间资产", "确认后沉淀到专属时间线", AppColors.SurfaceContainer, onClick = onOpenPlan),
                DetailTileSpec(Icons.Rounded.Download, "导出缓存", "用于 PDF / 长图生成", AppColors.CoralSoft)
            )
        )
        WeavingPrimaryButton(
            text = "查看时间线资产",
            onClick = onOpenPlan,
            modifier = Modifier.fillMaxWidth(),
            icon = Icons.Rounded.Timeline
        )
    }
}

@Composable
private fun StatisticsDetailPage(
    confirmedAgendaCount: Int,
    pendingAgendaCount: Int,
    todayAgendaCount: Int,
    scheduledReminderCount: Int,
    agendaItems: List<AgendaCardData>,
    inboxMessages: List<InboxMessageData>,
    onBack: () -> Unit,
    onOpenPlan: () -> Unit
) {
    val sourceCount = agendaItems
        .mapNotNull { it.sourceLabel.takeIf(String::isNotBlank) }
        .distinct()
        .size
    val locationReadyCount = agendaItems.count { it.location.isNotBlank() }
    val recentRecognizedCount = agendaItems.count { it.summary.isNotBlank() || it.time.isNotBlank() }

    DetailScaffold(
        title = "统计",
        subtitle = "从导入、确认到提醒的使用情况总览",
        icon = Icons.Rounded.QueryStats,
        onBack = onBack
    ) {
        DetailMetricRow(
            {
                MetricPill(
                    modifier = Modifier.weight(1f),
                    title = "已沉淀",
                    value = confirmedAgendaCount.toString(),
                    icon = Icons.Rounded.Timeline,
                    background = AppColors.GoldSoft
                )
            },
            {
                MetricPill(
                    modifier = Modifier.weight(1f),
                    title = "待提醒",
                    value = scheduledReminderCount.toString(),
                    icon = Icons.Rounded.NotificationsActive,
                    background = AppColors.MintAccent
                )
            }
        )
        DetailMetricRow(
            {
                MetricPill(
                    modifier = Modifier.weight(1f),
                    title = "今日",
                    value = todayAgendaCount.toString(),
                    icon = Icons.Rounded.CalendarMonth,
                    background = AppColors.SurfaceContainer
                )
            },
            {
                MetricPill(
                    modifier = Modifier.weight(1f),
                    title = "待校验",
                    value = pendingAgendaCount.toString(),
                    icon = Icons.Rounded.Shield,
                    background = AppColors.CoralSoft
                )
            }
        )
        DetailTileGrid(
            title = "数据切面",
            summary = "用更接近主流 App 的统计结构，把资产规模、来源分布和可执行程度展开展示。",
            tiles = listOf(
                DetailTileSpec(Icons.Rounded.History, "来源数", "$sourceCount 个常用来源", AppColors.GoldSoft),
                DetailTileSpec(Icons.Rounded.LocationOn, "地点完整", "$locationReadyCount 条可直接导航", AppColors.MintAccent),
                DetailTileSpec(Icons.Rounded.Psychology, "识别沉淀", "$recentRecognizedCount 条已有解析结果", AppColors.SurfaceContainer),
                DetailTileSpec(Icons.Rounded.NotificationsActive, "消息箱", "${inboxMessages.size} 条消息待回看", AppColors.CoralSoft)
            )
        )
        DetailInfoCard(
            title = "统计解读",
            value = "节奏清晰",
            summary = "这页聚焦展示作品真实沉淀了多少时间资产、多少提醒仍在生效，以及哪些来源最常形成可执行日程。"
        )
        WeavingPrimaryButton(
            text = "查看时间线资产",
            onClick = onOpenPlan,
            modifier = Modifier.fillMaxWidth(),
            icon = Icons.Rounded.Timeline
        )
    }
}

@Composable
private fun AccountDetailPage(
    userNickname: String,
    userAccount: String,
    userAvatarUri: String,
    userSignature: String,
    userSchool: String,
    userMajor: String,
    userGrade: String,
    onBack: () -> Unit,
    onOpenPersonalInfo: () -> Unit,
    onOpenSettings: () -> Unit,
    onLogout: () -> Unit
) {
    DetailScaffold(
        title = "账户",
        subtitle = "查看当前会话、资料入口与账号操作",
        icon = Icons.Rounded.ManageAccounts,
        onBack = onBack
    ) {
        WeavingGlassCard(containerColor = AppColors.SurfaceContainerLowest.copy(alpha = 0.94f)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(14.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                ProfileAvatar(
                    avatarUri = userAvatarUri,
                    fallbackText = userNickname.ifBlank { userAccount.ifBlank { "织" } },
                    size = 62.dp,
                    onClick = onOpenPersonalInfo
                )
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Text(
                        text = userNickname.ifBlank { "织时用户" },
                        style = AppTypography.HeadlineMedium,
                        color = AppColors.Primary
                    )
                    Text(
                        text = buildProfileLine(userAccount, userSchool, userMajor, userGrade),
                        style = AppTypography.BodyMedium,
                        color = AppColors.OnSurfaceVariant,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis
                    )
                    Text(
                        text = userSignature.ifBlank { "点击头像或资料页继续完善你的校园身份信息" },
                        style = AppTypography.LabelMedium,
                        color = AppColors.OnSurfaceVariant,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }
        }
        DetailTileGrid(
            title = "账户操作",
            summary = "把个人资料、系统设置与会话管理拆开，避免所有入口都堆在“我的”第一页。",
            tiles = listOf(
                DetailTileSpec(Icons.Rounded.Person, "个人资料", "头像、签名与校园身份", AppColors.GoldSoft, onClick = onOpenPersonalInfo),
                DetailTileSpec(Icons.Rounded.Settings, "设置", "提醒、风控与系统状态", AppColors.MintAccent, onClick = onOpenSettings),
                DetailTileSpec(Icons.Rounded.ManageAccounts, "当前会话", userAccount.ifBlank { "未登录" }, AppColors.SurfaceContainer),
                DetailTileSpec(Icons.Rounded.Logout, "退出登录", "安全退出当前账号", AppColors.CoralSoft, onClick = onLogout)
            )
        )
        DetailInfoCard(
            title = "测试账号",
            value = "1985",
            summary = "默认验证密码为 12345678，可直接用于功能验收。"
        )
        WeavingPrimaryButton(
            text = "编辑个人资料",
            onClick = onOpenPersonalInfo,
            modifier = Modifier.fillMaxWidth(),
            icon = Icons.Rounded.Edit
        )
    }
}

@Composable
private fun SettingsDetailPage(
    userAccount: String,
    onBack: () -> Unit,
    onLogout: () -> Unit
) {
    DetailScaffold(
        title = "设置",
        subtitle = "账号、安全与应用状态",
        icon = Icons.Rounded.Settings,
        onBack = onBack
    ) {
        DetailInfoCard("当前账号", userAccount.ifBlank { "未登录" }, "本地保存")
        DetailTileGrid(
            title = "账号与会话",
            tiles = listOf(
                DetailTileSpec(Icons.Rounded.ManageAccounts, "账号体系", "登录 / 注册 / 本地会话", AppColors.SurfaceContainer),
                DetailTileSpec(Icons.Rounded.Person, "资料入口", "头像、签名与校园身份", AppColors.GoldSoft),
                DetailTileSpec(Icons.Rounded.Shield, "安全边界", "高风险动作先确认", AppColors.CoralSoft),
                DetailTileSpec(Icons.Rounded.Storage, "本地数据", "SQLite + 偏好存储", AppColors.MintAccent)
            )
        )
        DetailTileGrid(
            title = "运行与策略",
            tiles = listOf(
                DetailTileSpec(Icons.Rounded.Psychology, "大模型", "vivo API 已接入", AppColors.MintAccent),
                DetailTileSpec(Icons.Rounded.NotificationsActive, "提醒策略", "按日级与分钟级双层触发", AppColors.GoldSoft),
                DetailTileSpec(Icons.Rounded.Tune, "低置信度处理", "保留人在回路确认", AppColors.CoralSoft),
                DetailTileSpec(Icons.Rounded.Speed, "性能模式", "保持主界面轻量流畅", AppColors.SurfaceContainer)
            )
        )
        DetailInfoCard("测试账号", "1985", "密码 12345678")
        WeavingPrimaryButton(
            text = "退出登录",
            onClick = onLogout,
            modifier = Modifier
                .fillMaxWidth()
                .testTag("profile-settings-logout"),
            icon = Icons.Rounded.Logout
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun PersonalInfoDetailPage(
    userNickname: String,
    userAccount: String,
    userAvatarUri: String,
    userSignature: String,
    userBirthday: String,
    userSchool: String,
    userAge: String,
    userGender: String,
    userMajor: String,
    userGrade: String,
    userHometown: String,
    onBack: () -> Unit,
    onSave: (
        nickname: String,
        avatarUri: String,
        signature: String,
        birthday: String,
        school: String,
        age: String,
        gender: String,
        major: String,
        grade: String,
        hometown: String
    ) -> Unit,
    onPickAvatar: () -> Unit,
    onCaptureAvatar: () -> Unit
) {
    val nicknameState = rememberSaveable(userNickname, userAccount) { mutableStateOf(userNickname) }
    val signatureState = rememberSaveable(userSignature, userAccount) { mutableStateOf(userSignature) }
    val birthdayState = rememberSaveable(userBirthday, userAccount) { mutableStateOf(userBirthday) }
    val schoolState = rememberSaveable(userSchool, userAccount) { mutableStateOf(userSchool) }
    val ageState = rememberSaveable(userAge, userAccount) { mutableStateOf(userAge) }
    val genderState = rememberSaveable(userGender, userAccount) { mutableStateOf(userGender) }
    val majorState = rememberSaveable(userMajor, userAccount) { mutableStateOf(userMajor) }
    val gradeState = rememberSaveable(userGrade, userAccount) { mutableStateOf(userGrade) }
    val hometownState = rememberSaveable(userHometown, userAccount) { mutableStateOf(userHometown) }
    val showAvatarSheetState = rememberSaveable(userAccount) { mutableStateOf(false) }
    val nickname = nicknameState.value
    val signature = signatureState.value
    val birthday = birthdayState.value
    val school = schoolState.value
    val age = ageState.value
    val gender = genderState.value
    val major = majorState.value
    val grade = gradeState.value
    val hometown = hometownState.value
    val showAvatarSheet = showAvatarSheetState.value

    DetailScaffold(
        title = "个人资料",
        subtitle = "头像、签名和校园身份",
        icon = Icons.Rounded.ManageAccounts,
        onBack = onBack
    ) {
        WeavingGlassCard(containerColor = AppColors.SurfaceContainerLowest.copy(alpha = 0.94f)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                ProfileAvatar(
                    avatarUri = userAvatarUri,
                    fallbackText = nickname.ifBlank { userAccount },
                    size = 82.dp,
                    modifier = Modifier.testTag("profile-avatar-preview"),
                    onClick = { showAvatarSheetState.value = true }
                )
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = nickname.ifBlank { "织时用户" },
                        style = AppTypography.HeadlineMedium,
                        color = AppColors.Primary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis
                    )
                    Text(
                        text = buildProfileLine(userAccount, school, major, grade),
                        style = AppTypography.BodyMedium,
                        color = AppColors.OnSurfaceVariant,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis
                    )
                    Text(
                        text = signature.ifBlank { buildProfileBrief(birthday, age, gender, hometown) },
                        style = AppTypography.LabelMedium,
                        color = AppColors.OnSurfaceVariant,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis
                    )
                }
            }
        }

        ProfileEditGroup(
            title = "公开展示",
            fields = listOf(
                ProfileFieldSpec(
                    icon = Icons.Rounded.Person,
                    label = "昵称",
                    value = nickname,
                    placeholder = "输入你的昵称",
                    onValueChange = { nicknameState.value = it.take(24) }
                ),
                ProfileFieldSpec(
                    icon = Icons.Rounded.DriveFileRenameOutline,
                    label = "个性签名",
                    value = signature,
                    placeholder = "如：把校园碎片织成自己的节奏",
                    singleLine = false,
                    maxLines = 3,
                    onValueChange = { signatureState.value = it.take(80) }
                )
            )
        )

        ProfileEditGroup(
            title = "校园身份",
            fields = listOf(
                ProfileFieldSpec(
                    icon = Icons.Rounded.School,
                    label = "学校",
                    value = school,
                    placeholder = "如：华南理工大学",
                    onValueChange = { schoolState.value = it.take(40) }
                ),
                ProfileFieldSpec(
                    icon = Icons.Rounded.Badge,
                    label = "专业",
                    value = major,
                    placeholder = "如：人工智能",
                    onValueChange = { majorState.value = it.take(40) }
                ),
                ProfileFieldSpec(
                    icon = Icons.Rounded.HomeWork,
                    label = "年级",
                    value = grade,
                    placeholder = "如：大二 / 2024级",
                    onValueChange = { gradeState.value = it.take(24) }
                )
            )
        )

        ProfileEditGroup(
            title = "基础信息",
            fields = listOf(
                ProfileFieldSpec(
                    icon = Icons.Rounded.Cake,
                    label = "生日",
                    value = birthday,
                    placeholder = "如：2005-05-14",
                    onValueChange = { birthdayState.value = it.take(20) }
                ),
                ProfileFieldSpec(
                    icon = Icons.Rounded.Person,
                    label = "年龄",
                    value = age,
                    placeholder = "如：21",
                    onValueChange = { ageState.value = it.filter(Char::isDigit).take(3) }
                ),
                ProfileFieldSpec(
                    icon = Icons.Rounded.ManageAccounts,
                    label = "性别",
                    value = gender,
                    placeholder = "如：男 / 女 / 不展示",
                    onValueChange = { genderState.value = it.take(12) }
                ),
                ProfileFieldSpec(
                    icon = Icons.Rounded.LocationOn,
                    label = "家乡",
                    value = hometown,
                    placeholder = "如：广东广州",
                    onValueChange = { hometownState.value = it.take(40) }
                )
            )
        )

        WeavingPrimaryButton(
            text = "保存个人资料",
            onClick = {
                onSave(nickname, userAvatarUri, signature, birthday, school, age, gender, major, grade, hometown)
                onBack()
            },
            modifier = Modifier
                .fillMaxWidth()
                .testTag("profile-personal-save"),
            icon = Icons.Rounded.ManageAccounts
        )

        if (showAvatarSheet) {
            ModalBottomSheet(
                onDismissRequest = { showAvatarSheetState.value = false },
                containerColor = AppColors.SurfaceBright,
                dragHandle = { BottomSheetDefaults.DragHandle(color = AppColors.GlassBorder) }
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = AppSpacing.lg, vertical = AppSpacing.md),
                    verticalArrangement = Arrangement.spacedBy(AppSpacing.md)
                ) {
                    Text(
                        text = "更换头像",
                        style = AppTypography.HeadlineMedium,
                        color = AppColors.Primary,
                        fontWeight = FontWeight.ExtraBold
                    )
                    AvatarSheetAction(
                        icon = Icons.Rounded.PhotoLibrary,
                        title = "从相册选择",
                        subtitle = "从本机图片中选择一张作为头像",
                        testTag = "profile-avatar-pick",
                        onClick = {
                            showAvatarSheetState.value = false
                            onPickAvatar()
                        }
                    )
                    AvatarSheetAction(
                        icon = Icons.Rounded.CameraAlt,
                        title = "拍照更换",
                        subtitle = "直接拍一张新的照片作为头像",
                        testTag = "profile-avatar-capture",
                        onClick = {
                            showAvatarSheetState.value = false
                            onCaptureAvatar()
                        }
                    )
                    Spacer(modifier = Modifier.height(AppSpacing.md))
                }
            }
        }
    }
}

@Composable
private fun ProfileEditGroup(
    title: String,
    fields: List<ProfileFieldSpec>
) {
    WeavingGlassCard(containerColor = AppColors.SurfaceContainerLowest) {
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(
                text = title,
                style = AppTypography.HeadlineMedium,
                color = AppColors.Primary,
                fontWeight = FontWeight.ExtraBold
            )
        }
        fields.forEach { field ->
            ProfileEditField(
                icon = field.icon,
                label = field.label,
                value = field.value,
                onValueChange = field.onValueChange,
                placeholder = field.placeholder,
                singleLine = field.singleLine,
                maxLines = field.maxLines
            )
        }
    }
}

@Composable
private fun AvatarSheetAction(
    icon: ImageVector,
    title: String,
    subtitle: String,
    testTag: String,
    onClick: () -> Unit
) {
    WeavingGlassCard(
        modifier = Modifier.testTag(testTag),
        containerColor = Color.White.copy(alpha = 0.5f),
        onClick = onClick,
        interactionStyle = WeavingInteractionStyle.IconGlow
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            WeavingIconBubble(
                icon = icon,
                background = AppColors.GoldSoft,
                tint = AppColors.Primary,
                modifier = Modifier.size(40.dp)
            )
            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(
                    text = title,
                    style = AppTypography.BodyLarge,
                    color = AppColors.OnSurface,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = subtitle,
                    style = AppTypography.LabelSmall,
                    color = AppColors.OnSurfaceVariant,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
    }
}

@Composable
private fun ProfileEditField(
    icon: ImageVector,
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
    singleLine: Boolean = true,
    maxLines: Int = 1
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color.White.copy(alpha = 0.38f), RoundedCornerShape(AppShapes.Large))
            .padding(10.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        WeavingIconBubble(
            icon = icon,
            background = AppColors.GoldSoft,
            tint = AppColors.Primary,
            modifier = Modifier.size(40.dp)
        )
        OutlinedTextField(
            value = value,
            onValueChange = onValueChange,
            modifier = Modifier.weight(1f),
            label = { Text(label) },
            placeholder = { Text(placeholder) },
            singleLine = singleLine,
            maxLines = maxLines,
            shape = RoundedCornerShape(AppShapes.Medium),
            textStyle = AppTypography.BodyLarge,
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = AppColors.Primary,
                unfocusedBorderColor = Color.Transparent,
                focusedContainerColor = Color.White.copy(alpha = 0.42f),
                unfocusedContainerColor = Color.White.copy(alpha = 0.2f),
                cursorColor = AppColors.Primary,
                focusedLabelColor = AppColors.Primary,
                unfocusedLabelColor = AppColors.OnSurfaceVariant
            )
        )
    }
}

@Composable
private fun DetailMiniRow(
    icon: ImageVector,
    title: String,
    summary: String,
    onClick: (() -> Unit)? = null
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = DetailActionHeight)
            .background(Color.White.copy(alpha = 0.45f), RoundedCornerShape(AppShapes.Medium))
            .let { base ->
                if (onClick != null) {
                    base.clickable { onClick() }
                } else {
                    base
                }
            }
            .padding(horizontal = 14.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        WeavingIconBubble(
            icon = icon,
            background = AppColors.MintAccent,
            tint = AppColors.Primary,
            modifier = Modifier.size(42.dp)
        )
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(2.dp)
        ) {
            Text(
                text = title,
                style = AppTypography.LabelMedium,
                color = AppColors.OnSurface,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = summary,
                style = AppTypography.LabelSmall,
                color = AppColors.OnSurfaceVariant,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
        }
        if (onClick != null) {
            Icon(
                imageVector = Icons.Rounded.ChevronRight,
                contentDescription = null,
                tint = AppColors.OnSurfaceVariant
            )
        }
    }
}

@Composable
private fun PersonaDetailPage(
    userNickname: String,
    confirmedAgendaCount: Int,
    pendingAgendaCount: Int,
    todayAgendaCount: Int,
    scheduledReminderCount: Int,
    onBack: () -> Unit
) {
    val persona = when {
        confirmedAgendaCount >= 10 && scheduledReminderCount >= 10 -> "高密度规划型"
        pendingAgendaCount > confirmedAgendaCount -> "谨慎校验型"
        todayAgendaCount == 0 -> "低噪留白型"
        else -> "稳态推进型"
    }

    DetailScaffold(
        title = "用户画像",
        subtitle = "$userNickname 的校园时间管理侧写",
        icon = Icons.Rounded.Psychology,
        onBack = onBack
    ) {
        DetailMetricRow(
            {
            MetricPill(
                modifier = Modifier.weight(1f),
                title = "今日",
                value = todayAgendaCount.toString(),
                icon = Icons.Rounded.CalendarMonth,
                background = AppColors.GoldSoft
            )
            },
            {
            MetricPill(
                modifier = Modifier.weight(1f),
                title = "提醒",
                value = scheduledReminderCount.toString(),
                icon = Icons.Rounded.NotificationsActive,
                background = AppColors.MintAccent
            )
            }
        )
        DetailInfoCard("当前画像", persona, "根据确认日程、待确认碎片、今日安排和提醒数量动态估算。")
        DetailTileGrid(
            title = "画像标签",
            summary = "把用户与智能体的关系做成可解释标签，增强二级页展示价值。",
            tiles = listOf(
                DetailTileSpec(Icons.Rounded.Download, "多模态导入型", "适合截图 / 海报 / 群通知", AppColors.GoldSoft),
                DetailTileSpec(Icons.Rounded.Shield, "谨慎授权型", "高风险动作保留确认卡", AppColors.CoralSoft),
                DetailTileSpec(Icons.Rounded.Timeline, "时间线沉淀型", "关注长期秩序资产", AppColors.MintAccent),
                DetailTileSpec(Icons.Rounded.NotificationsActive, "提醒托管型", "关键事项交给系统守护", AppColors.SurfaceContainer)
            )
        )
        DetailRowGroup(
            title = "个性化建议",
            rows = listOf(
                DetailTileSpec(Icons.Rounded.QueryStats, "低置信度先校验", "可让时间线更可信、更适合答辩展示。"),
                DetailTileSpec(Icons.Rounded.Map, "地点字段补齐", "建议遇到会议室、教学楼时尽量保留地点线索。"),
                DetailTileSpec(Icons.Rounded.History, "定期回看历史", "从历史记录中复盘哪些来源最容易产生有效日程。")
            )
        )
    }
}

@Composable
private fun DetailInfoCard(
    title: String,
    value: String,
    summary: String
) {
    WeavingGlassCard(
        modifier = Modifier
            .fillMaxWidth()
            .heightIn(min = DetailInfoHeight),
        containerColor = AppColors.SurfaceContainerLowest
    ) {
        Text(
            text = title,
            style = AppTypography.LabelMedium,
            color = AppColors.OnSurfaceVariant,
            maxLines = 1
        )
        Text(
            text = value,
            style = AppTypography.HeadlineMedium,
            color = AppColors.Primary,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
        Text(
            text = summary,
            style = AppTypography.BodyMedium,
            color = AppColors.OnSurfaceVariant,
            maxLines = 3,
            overflow = TextOverflow.Ellipsis
        )
    }
}
