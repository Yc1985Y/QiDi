package com.vsa.visualsemanticagent

import android.Manifest
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.widget.Toast
import androidx.activity.compose.BackHandler
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.ImageCaptureException
import androidx.camera.view.PreviewView
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Home
import androidx.compose.material.icons.rounded.Person
import androidx.compose.material.icons.rounded.Schedule
import androidx.compose.material3.Icon
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.TextButton
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.ui.ExperimentalComposeUiApi
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.testTagsAsResourceId
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import androidx.lifecycle.lifecycleScope
import com.vsa.visualsemanticagent.account.AccountRepository
import com.vsa.visualsemanticagent.account.AccountSessionStore
import com.vsa.visualsemanticagent.account.AccountUser
import com.vsa.visualsemanticagent.camera.CameraManager
import com.vsa.visualsemanticagent.decision.ExecutableIntent
import com.vsa.visualsemanticagent.decision.ExecutablePayload
import com.vsa.visualsemanticagent.decision.ExecutionMode
import com.vsa.visualsemanticagent.decision.PendingExecutionEntry
import com.vsa.visualsemanticagent.decision.PendingExecutionRegistry
import com.vsa.visualsemanticagent.decision.PendingExecutionSnapshot
import com.vsa.visualsemanticagent.decision.ExecutionSuggestion
import com.vsa.visualsemanticagent.decision.IntentRiskLevel
import com.vsa.visualsemanticagent.decision.RiskPolicyEngine
import com.vsa.visualsemanticagent.decision.VisualActionIntentSchema
import com.vsa.visualsemanticagent.decision.detectScheduleConflicts
import com.vsa.visualsemanticagent.input.CampusNoticeInput
import com.vsa.visualsemanticagent.input.NoticeSourceType
import com.vsa.visualsemanticagent.input.TextInputClearPolicy
import com.vsa.visualsemanticagent.intent.ActivityNotFoundException
import com.vsa.visualsemanticagent.intent.IntentDispatcher
import com.vsa.visualsemanticagent.model.ModelConstants
import com.vsa.visualsemanticagent.model.VLMResponse
import com.vsa.visualsemanticagent.network.CampusNoticeAnalysis
import com.vsa.visualsemanticagent.network.VLMApiException
import com.vsa.visualsemanticagent.network.VLMNetworkClient
import com.vsa.visualsemanticagent.network.VLMNetworkException
import com.vsa.visualsemanticagent.network.VLMResponseParseException
import com.vsa.visualsemanticagent.notification.InboxMessageData
import com.vsa.visualsemanticagent.storage.AppPreferencesStore
import com.vsa.visualsemanticagent.reminder.ReminderScheduler
import com.vsa.visualsemanticagent.tts.TextToSpeechManager
import com.vsa.visualsemanticagent.plan.AgendaCardData
import com.vsa.visualsemanticagent.plan.countAgendasWithUpcomingReminders
import com.vsa.visualsemanticagent.plan.defaultAgendaReminders
import com.vsa.visualsemanticagent.plan.isConfirmedStatus
import com.vsa.visualsemanticagent.plan.isPendingStatus
import com.vsa.visualsemanticagent.plan.scheduleDate
import com.vsa.visualsemanticagent.plan.scheduleDateTime
import com.vsa.visualsemanticagent.ui.ErrorOverlay
import com.vsa.visualsemanticagent.ui.LoadingOverlay
import com.vsa.visualsemanticagent.ui.StartupIntroScreen
import com.vsa.visualsemanticagent.ui.TimelineTransferOverlay
import com.vsa.visualsemanticagent.ui.camera.LiveCameraCaptureScreen
import com.vsa.visualsemanticagent.ui.home.HomeScreenModule
import com.vsa.visualsemanticagent.ui.profile.AgentRuntimeStatusData
import com.vsa.visualsemanticagent.ui.profile.ProfileScreenModule
import com.vsa.visualsemanticagent.ui.review.ReviewScreenModule
import com.vsa.visualsemanticagent.ui.timeline.TimelineScreenModule
import com.vsa.visualsemanticagent.utils.NoticeSegmentExtractor
import com.vsa.visualsemanticagent.utils.PromptPreset
import com.vsa.visualsemanticagent.utils.PromptPresets
import com.vsa.visualsemanticagent.utils.ResponseInterpreter
import com.vsa.visualsemanticagent.utils.UriImageUtils
import com.vsa.visualsemanticagent.voice.VivoAsrException
import com.vsa.visualsemanticagent.voice.VivoRealtimeAsrClient
import com.vsa.visualsemanticagent.voice.VoiceRecognitionException
import com.vsa.visualsemanticagent.voice.VoiceRecognitionManager
import java.io.File
import java.io.FileNotFoundException
import java.io.FileOutputStream
import java.time.LocalDate
import java.time.YearMonth
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import timber.log.Timber

class MainActivity : ComponentActivity() {

    companion object {
        private const val RUNTIME_PREFS = "timeweaver_runtime"
        private const val KEY_HAS_ENTERED_APP = "has_entered_app"
        private const val INBOX_PERSIST_DEBOUNCE_MILLIS = 650L
        private const val TTS_DEBOUNCE_MILLIS = 2800L
        private const val MAX_TTS_TEXT_LENGTH = 90
        private const val MIN_VOICE_RECORD_MILLIS = 450L
        private const val MAX_VOICE_RECORD_MILLIS = 15_000L
    }

    private enum class RecoveryAction {
        NONE,
        REQUEST_PERMISSIONS,
        RETRY_CAPTURE,
        RETRY_VOICE,
        RETRY_IMPORT
    }

    private val isLoadingState = mutableStateOf(false)
    private var isLoading: Boolean
        get() = isLoadingState.value
        set(value) { isLoadingState.value = value }
    private val isVoiceListeningState = mutableStateOf(false)
    private var isVoiceListening: Boolean
        get() = isVoiceListeningState.value
        set(value) { isVoiceListeningState.value = value }
    private val isVoiceRecordingActiveState = mutableStateOf(false)
    private var isVoiceRecordingActive: Boolean
        get() = isVoiceRecordingActiveState.value
        set(value) { isVoiceRecordingActiveState.value = value }
    private val voiceRecordingMillisState = mutableStateOf(0L)
    private var voiceRecordingMillis: Long
        get() = voiceRecordingMillisState.value
        set(value) { voiceRecordingMillisState.value = value }
    private val loadingStageState = mutableStateOf(0)
    private var loadingStage: Int
        get() = loadingStageState.value
        set(value) { loadingStageState.value = value }
    private val commandTextState = mutableStateOf("")
    private var commandText: String
        get() = commandTextState.value
        set(value) { commandTextState.value = value }
    private val statusTextState = mutableStateOf("")
    private var statusText: String
        get() = statusTextState.value
        set(value) { statusTextState.value = value }
    private val resultTextState = mutableStateOf("")
    private var resultText: String
        get() = resultTextState.value
        set(value) { resultTextState.value = value }
    private val cameraPermissionGrantedState = mutableStateOf(false)
    private var cameraPermissionGranted: Boolean
        get() = cameraPermissionGrantedState.value
        set(value) { cameraPermissionGrantedState.value = value }
    private val showLiveCameraScreenState = mutableStateOf(false)
    private var showLiveCameraScreen: Boolean
        get() = showLiveCameraScreenState.value
        set(value) { showLiveCameraScreenState.value = value }
    private val isCameraCapturingState = mutableStateOf(false)
    private var isCameraCapturing: Boolean
        get() = isCameraCapturingState.value
        set(value) { isCameraCapturingState.value = value }
    private val audioPermissionGrantedState = mutableStateOf(false)
    private var audioPermissionGranted: Boolean
        get() = audioPermissionGrantedState.value
        set(value) { audioPermissionGrantedState.value = value }
    private val cameraAvailableState = mutableStateOf(true)
    private var cameraAvailable: Boolean
        get() = cameraAvailableState.value
        set(value) { cameraAvailableState.value = value }
    private val notificationPermissionGrantedState = mutableStateOf(false)
    private var notificationPermissionGranted: Boolean
        get() = notificationPermissionGrantedState.value
        set(value) { notificationPermissionGrantedState.value = value }
    private val lastErrorState = mutableStateOf("")
    private var lastError: String
        get() = lastErrorState.value
        set(value) { lastErrorState.value = value }
    private val showErrorOverlayState = mutableStateOf(false)
    private var showErrorOverlay: Boolean
        get() = showErrorOverlayState.value
        set(value) { showErrorOverlayState.value = value }
    private val currentRecoveryActionState = mutableStateOf(RecoveryAction.NONE)
    private var currentRecoveryAction: RecoveryAction
        get() = currentRecoveryActionState.value
        set(value) { currentRecoveryActionState.value = value }
    private val pendingExecutableIntentState = mutableStateOf<ExecutableIntent?>(null)
    private var pendingExecutableIntent: ExecutableIntent?
        get() = pendingExecutableIntentState.value
        set(value) { pendingExecutableIntentState.value = value }
    private val pendingExecutionSuggestionState = mutableStateOf<ExecutionSuggestion?>(null)
    private var pendingExecutionSuggestion: ExecutionSuggestion?
        get() = pendingExecutionSuggestionState.value
        set(value) { pendingExecutionSuggestionState.value = value }
    private val pendingExecutionSnapshotState = mutableStateOf(PendingExecutionSnapshot())
    private var pendingExecutionSnapshot: PendingExecutionSnapshot
        get() = pendingExecutionSnapshotState.value
        set(value) { pendingExecutionSnapshotState.value = value }
    private val pendingSourceLabelState = mutableStateOf("")
    private var pendingSourceLabel: String
        get() = pendingSourceLabelState.value
        set(value) { pendingSourceLabelState.value = value }
    private val pendingSourcePreviewState = mutableStateOf("")
    private var pendingSourcePreview: String
        get() = pendingSourcePreviewState.value
        set(value) { pendingSourcePreviewState.value = value }
    private val showConfirmationCardState = mutableStateOf(false)
    private var showConfirmationCard: Boolean
        get() = showConfirmationCardState.value
        set(value) { showConfirmationCardState.value = value }
    private val agendaItemsState = mutableStateOf<List<AgendaCardData>>(emptyList())
    private var agendaItems: List<AgendaCardData>
        get() = agendaItemsState.value
        set(value) { agendaItemsState.value = value }
    private val showStartupIntroState = mutableStateOf(true)
    private var showStartupIntro: Boolean
        get() = showStartupIntroState.value
        set(value) { showStartupIntroState.value = value }
    private val launchTabState = mutableStateOf("home")
    private var launchTab: String
        get() = launchTabState.value
        set(value) { launchTabState.value = value }
    private val reminderPolicyLabelState = mutableStateOf("榛樿鎻愬墠涓€澶╁拰鎻愬墠涓€灏忔椂")
    private var reminderPolicyLabel: String
        get() = reminderPolicyLabelState.value
        set(value) { reminderPolicyLabelState.value = value }
    private val reminderStateTextState = mutableStateOf("本地提醒尚未初始化")
    private var reminderStateText: String
        get() = reminderStateTextState.value
        set(value) { reminderStateTextState.value = value }
    private val nextReminderTextState = mutableStateOf("暂无即将触发的提醒")
    private var nextReminderText: String
        get() = nextReminderTextState.value
        set(value) { nextReminderTextState.value = value }
    private val scheduledReminderCountState = mutableIntStateOf(0)
    private var scheduledReminderCount: Int
        get() = scheduledReminderCountState.intValue
        set(value) { scheduledReminderCountState.intValue = value }
    private val confirmedAgendaCountState = mutableIntStateOf(0)
    private var confirmedAgendaCount: Int
        get() = confirmedAgendaCountState.intValue
        set(value) { confirmedAgendaCountState.intValue = value }
    private val pendingAgendaCountState = mutableIntStateOf(0)
    private var pendingAgendaCount: Int
        get() = pendingAgendaCountState.intValue
        set(value) { pendingAgendaCountState.intValue = value }
    private val todayAgendaCountState = mutableIntStateOf(0)
    private var todayAgendaCount: Int
        get() = todayAgendaCountState.intValue
        set(value) { todayAgendaCountState.intValue = value }
    private val exportFormatsState = mutableStateOf(listOf("PDF", "JPG", "PNG"))
    private var exportFormats: List<String>
        get() = exportFormatsState.value
        set(value) { exportFormatsState.value = value }
    private val reminderLeadMinutesState = mutableIntStateOf(60)
    private var reminderLeadMinutes: Int
        get() = reminderLeadMinutesState.intValue
        set(value) { reminderLeadMinutesState.intValue = value }
    private val reminderDayEnabledState = mutableStateOf(true)
    private var reminderDayEnabled: Boolean
        get() = reminderDayEnabledState.value
        set(value) { reminderDayEnabledState.value = value }
    private val reminderHourEnabledState = mutableStateOf(true)
    private var reminderHourEnabled: Boolean
        get() = reminderHourEnabledState.value
        set(value) { reminderHourEnabledState.value = value }
    private val blockHighRiskState = mutableStateOf(true)
    private var blockHighRisk: Boolean
        get() = blockHighRiskState.value
        set(value) { blockHighRiskState.value = value }
    private val muteLowConfidenceState = mutableStateOf(false)
    private var muteLowConfidence: Boolean
        get() = muteLowConfidenceState.value
        set(value) { muteLowConfidenceState.value = value }
    private val autoMapLinkState = mutableStateOf(true)
    private var autoMapLink: Boolean
        get() = autoMapLinkState.value
        set(value) { autoMapLinkState.value = value }
    private val performanceLiteModeState = mutableStateOf(false)
    private var performanceLiteMode: Boolean
        get() = performanceLiteModeState.value
        set(value) { performanceLiteModeState.value = value }
    private val selectedPlanModeState = mutableStateOf("month")
    private var selectedPlanMode: String
        get() = selectedPlanModeState.value
        set(value) { selectedPlanModeState.value = value }
    private val selectedPlanDateState = mutableStateOf<LocalDate?>(null)
    private var selectedPlanDate: LocalDate?
        get() = selectedPlanDateState.value
        set(value) { selectedPlanDateState.value = value }
    private val calendarPreviewMonthState = mutableStateOf(YearMonth.now())
    private var calendarPreviewMonth: YearMonth
        get() = calendarPreviewMonthState.value
        set(value) { calendarPreviewMonthState.value = value }
    private val pendingNavigationAgendaState = mutableStateOf<AgendaCardData?>(null)
    private var pendingNavigationAgenda: AgendaCardData?
        get() = pendingNavigationAgendaState.value
        set(value) { pendingNavigationAgendaState.value = value }
    private val showVoiceFallbackInputState = mutableStateOf(false)
    private var showVoiceFallbackInput: Boolean
        get() = showVoiceFallbackInputState.value
        set(value) { showVoiceFallbackInputState.value = value }
    private val voiceFallbackDraftState = mutableStateOf("")
    private var voiceFallbackDraft: String
        get() = voiceFallbackDraftState.value
        set(value) { voiceFallbackDraftState.value = value }
    private val showReviewScreenState = mutableStateOf(false)
    private var showReviewScreen: Boolean
        get() = showReviewScreenState.value
        set(value) { showReviewScreenState.value = value }
    private val importedTextState = mutableStateOf("")
    private var importedText: String
        get() = importedTextState.value
        set(value) { importedTextState.value = value }
    private val importedSourceLabelState = mutableStateOf("")
    private var importedSourceLabel: String
        get() = importedSourceLabelState.value
        set(value) { importedSourceLabelState.value = value }
    private val importedImageUriTextState = mutableStateOf("")
    private var importedImageUriText: String
        get() = importedImageUriTextState.value
        set(value) { importedImageUriTextState.value = value }
    private val tabNavigationNonceState = mutableIntStateOf(0)
    private var tabNavigationNonce: Int
        get() = tabNavigationNonceState.intValue
        set(value) { tabNavigationNonceState.intValue = value }
    private val planExportStatusState = mutableStateOf("绛夊緟瀵煎嚭")
    private var planExportStatus: String
        get() = planExportStatusState.value
        set(value) { planExportStatusState.value = value }
    private val inboxMessagesState = mutableStateOf<List<InboxMessageData>>(emptyList())
    private var inboxMessages: List<InboxMessageData>
        get() = inboxMessagesState.value
        set(value) { inboxMessagesState.value = value }
    private val currentAccountUserState = mutableStateOf<AccountUser?>(null)
    private var currentAccountUser: AccountUser?
        get() = currentAccountUserState.value
        set(value) { currentAccountUserState.value = value }
    private val loginMessageState = mutableStateOf("")
    private var loginMessage: String
        get() = loginMessageState.value
        set(value) { loginMessageState.value = value }
    private val loginSubmittingState = mutableStateOf(false)
    private var loginSubmitting: Boolean
        get() = loginSubmittingState.value
        set(value) { loginSubmittingState.value = value }
    private var pendingProfileCameraUri: Uri? = null
    private var appInitialized = false
    private var preferencesSeeded = false
    private var allStoredAgendaItems: List<AgendaCardData> = emptyList()
    private var allStoredInboxMessages: List<InboxMessageData> = emptyList()
    private var pendingInboxPersistJob: Job? = null
    private var voiceCaptureJob: Job? = null
    private var voiceTimerJob: Job? = null
    private var voiceStopSignal: CompletableDeferred<Unit>? = null
    private var voiceRecordStartedAtMillis = 0L
    private var lastSpokenText = ""
    private var lastSpokenAtMillis = 0L

    private lateinit var accountRepository: AccountRepository
    private lateinit var accountSessionStore: AccountSessionStore
    private lateinit var intentDispatcher: IntentDispatcher
    private lateinit var textToSpeechManager: TextToSpeechManager
    private lateinit var vlmNetworkClient: VLMNetworkClient
    private lateinit var reminderScheduler: ReminderScheduler
    private lateinit var appPreferencesStore: AppPreferencesStore
    private lateinit var vivoRealtimeAsrClient: VivoRealtimeAsrClient

    private val riskPolicyEngine = RiskPolicyEngine()
    private val presets = PromptPresets.defaults
    private val runtimePrefs by lazy { getSharedPreferences(RUNTIME_PREFS, MODE_PRIVATE) }

    private var lastNoticeInput: CampusNoticeInput? = null

    private val permissionLauncher = registerForActivityResult(
        ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        cameraPermissionGranted = permissions[Manifest.permission.CAMERA] == true || hasPermission(Manifest.permission.CAMERA)
        audioPermissionGranted = permissions[Manifest.permission.RECORD_AUDIO] == true || hasPermission(Manifest.permission.RECORD_AUDIO)
        notificationPermissionGranted = hasNotificationPermission()

        if (hasCaptureAccess()) {
            initializeAppIfNeeded()
            if (!audioPermissionGranted) {
                statusText = getString(R.string.voice_permission_tip)
            } else if (statusText == getString(R.string.permissions_missing)) {
                statusText = ""
            }
            clearErrorState()
        } else {
            showError(
                message = getString(R.string.camera_permission_missing),
                recoveryAction = RecoveryAction.REQUEST_PERMISSIONS
            )
        }
    }

    private val pickImageLauncher = registerForActivityResult(
        ActivityResultContracts.GetContent()
    ) { uri ->
        if (uri != null) {
            onImageUriImported(uri, NoticeSourceType.ALBUM)
        }
    }

    private val pickAvatarLauncher = registerForActivityResult(
        ActivityResultContracts.GetContent()
    ) { uri ->
        if (uri != null) {
            saveProfileAvatarFromUri(uri)
        }
    }

    private val takeAvatarLauncher = registerForActivityResult(
        ActivityResultContracts.TakePicture()
    ) { success ->
        val uri = pendingProfileCameraUri
        pendingProfileCameraUri = null
        if (success && uri != null) {
            saveProfileAvatarFromUri(uri)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (BuildConfig.DEBUG && Timber.forest().isEmpty()) {
            Timber.plant(Timber.DebugTree())
        }

        accountRepository = AccountRepository(this)
        accountRepository.ensureBuiltInTestAccount()
        accountSessionStore = AccountSessionStore(this)
        currentAccountUser = accountSessionStore.loadCurrentUser(accountRepository)
        appPreferencesStore = AppPreferencesStore(this)
        lifecycleScope.launch {
            appPreferencesStore.stateFlow.collect { stored ->
                if (!preferencesSeeded) {
                    allStoredAgendaItems = stored.agendaItems
                    allStoredInboxMessages = stored.inboxMessages
                    loadVisibleDataForCurrentAccount()
                    reminderLeadMinutes = stored.reminderLeadMinutes
                    reminderDayEnabled = stored.reminderDayEnabled
                    reminderHourEnabled = stored.reminderHourEnabled
                    blockHighRisk = stored.blockHighRisk
                    muteLowConfidence = stored.muteLowConfidence
                    autoMapLink = stored.autoMapLink
                    performanceLiteMode = stored.performanceLiteMode
                    preferencesSeeded = true
                    persistAppPreferences()
                    refreshReminderState()
                }
            }
        }

        refreshPermissionState()
        launchTab = resolveLaunchTab(intent)
        showStartupIntro = shouldShowStartupIntro(intent)
        refreshReminderState()

        setContent {
            BackHandler(enabled = showLiveCameraScreen) {
                CameraManager.unbindPreview()
                showLiveCameraScreen = false
                isCameraCapturing = false
            }
            BackHandler(enabled = showReviewScreen) {
                showReviewScreen = false
            }
            if (showStartupIntro) {
                com.vsa.visualsemanticagent.ui.LoginScreen(
                    isSubmitting = loginSubmitting,
                    message = loginMessage,
                    onLogin = { account, password -> loginAccount(account, password) },
                    onRegister = { account, password, nickname -> registerAccount(account, password, nickname) }
                )
            } else if (showLiveCameraScreen) {
                LiveCameraCaptureScreen(
                    modifier = Modifier.fillMaxSize(),
                    isCapturing = isCameraCapturing,
                    statusText = statusText,
                    onBack = {
                        CameraManager.unbindPreview()
                        showLiveCameraScreen = false
                        isCameraCapturing = false
                    },
                    onCapture = { onLiveCameraShutterClicked() },
                    onPickImage = {
                        CameraManager.unbindPreview()
                        showLiveCameraScreen = false
                        isCameraCapturing = false
                        onPickImageClicked()
                    }
                )
            } else if (showReviewScreen && pendingExecutableIntent != null && pendingExecutionSuggestion != null) {
                ReviewScreenModule(
                    modifier = Modifier.fillMaxSize(),
                    intent = pendingExecutableIntent!!,
                    suggestion = pendingExecutionSuggestion!!,
                    sourceLabel = activeSourceLabel(),
                    sourcePreview = activeSourcePreview(),
                    conflicts = detectScheduleConflicts(pendingExecutableIntent!!, agendaItems),
                    performanceLiteMode = performanceLiteMode,
                    onBack = { showReviewScreen = false },
                    onSaveDraft = { title, time, location, description ->
                        updatePendingReviewDraft(title, time, location, description)
                        showReviewScreen = false
                    },
                    onConfirmDraft = { title, time, location, description ->
                        updatePendingReviewDraft(title, time, location, description)
                        showReviewScreen = false
                        onConfirmExecutionClicked()
                    },
                    onCancelExecution = {
                        showReviewScreen = false
                        onCancelExecutionClicked()
                    }
                )
            } else {
                val runtimeStatus = AgentRuntimeStatusData(
                    modelName = BuildConfig.VLM_MODEL_NAME,
                    appIdReady = BuildConfig.VLM_APP_ID.isNotBlank(),
                    apiKeyReady = BuildConfig.VLM_API_KEY.isNotBlank(),
                    chatEndpoint = BuildConfig.VLM_API_ENDPOINT,
                    ocrEndpoint = BuildConfig.VLM_OCR_ENDPOINT,
                    dataStoreReady = ::appPreferencesStore.isInitialized && preferencesSeeded,
                    accountReady = currentAccountUser != null,
                    cameraReady = cameraPermissionGranted || cameraAvailable,
                    voiceReady = audioPermissionGranted,
                    agendaCount = agendaItems.size,
                    inboxCount = inboxMessages.size,
                    reminderCount = scheduledReminderCount
                )
                MainScreen(
                    currentAccountUser = currentAccountUser,
                    commandText = commandText,
                    onCommandChanged = { commandText = it },
                    onSubmitCommand = { onSubmitCommandClicked() },
                    onCapture = { onCaptureButtonClicked() },
                    onVoicePressStart = { startVoiceCapture() },
                    onVoicePressEnd = { finishVoiceRecording() },
                    onVoicePressCancel = { cancelVoiceCapture() },
                    onPasteText = { onPasteTextClicked() },
                    onPreset = { onPresetSelected(it) },
                    onConfirmExecution = { onConfirmExecutionClicked() },
                    onCancelExecution = { onCancelExecutionClicked() },
                    bindPreview = { bindPreview(it) },
                    presets = presets,
                    showLivePreview = true,
                    isLoading = isLoading,
                    isVoiceListening = isVoiceListening,
                    isVoiceRecordingActive = isVoiceRecordingActive,
                    voiceRecordingMillis = voiceRecordingMillis,
                    isCameraAvailable = cameraAvailable,
                    loadingStage = loadingStage,
                    statusText = statusText,
                    resultText = resultText,
                    reviewSourcePreview = activeSourcePreview(),
                    importedSourceLabel = activeSourceLabel(),
                    confirmationIntent = pendingExecutableIntent,
                    confirmationSuggestion = pendingExecutionSuggestion,
                    showConfirmationCard = showConfirmationCard,
                    agendaItems = agendaItems,
                    selectedPlanMode = selectedPlanMode,
                    selectedPlanDate = selectedPlanDate,
                    calendarPreviewMonth = calendarPreviewMonth,
                    reminderPolicyLabel = reminderPolicyLabel,
                    reminderStateText = reminderStateText,
                    nextReminderText = nextReminderText,
                    reminderLeadMinutes = reminderLeadMinutes,
                    reminderDayEnabled = reminderDayEnabled,
                    reminderHourEnabled = reminderHourEnabled,
                    blockHighRisk = blockHighRisk,
                    muteLowConfidence = muteLowConfidence,
                    autoMapLink = autoMapLink,
                    performanceLiteMode = performanceLiteMode,
                    runtimeStatus = runtimeStatus,
                    exportFormats = exportFormats,
                    showErrorOverlay = showErrorOverlay,
                    errorText = lastError,
                    showRetry = currentRecoveryAction != RecoveryAction.NONE,
                    retryText = getRetryButtonText(),
                    initialTab = launchTab,
                    tabNavigationNonce = tabNavigationNonce,
                    onReminderLeadMinutesChange = { updateReminderLeadMinutes(it) },
                    onReminderDayEnabledChange = { updateReminderDayEnabled(it) },
                    onReminderHourEnabledChange = { updateReminderHourEnabled(it) },
                    onBlockHighRiskChange = { updateBlockHighRisk(it) },
                    onMuteLowConfidenceChange = { updateMuteLowConfidence(it) },
                    onAutoMapLinkChange = { updateAutoMapLink(it) },
                    onPerformanceLiteModeChange = { updatePerformanceLiteMode(it) },
                    onReparseHistoryItem = { reparseHistoryItem(it) },
                    onUpdateAgendaItem = { updateAgendaItem(it) },
                    onDeleteAgendaItem = { deleteAgendaItem(it) },
                    onDuplicateAgendaItem = { duplicateAgendaItem(it) },
                    onNavigateAgendaItem = { navigateAgendaItem(it) },
                    pendingNavigationAgenda = pendingNavigationAgenda,
                    onDismissNavigationChoice = { pendingNavigationAgenda = null },
                    onChooseNavigationProvider = { item, provider ->
                        pendingNavigationAgenda = null
                        executeAgendaNavigation(item, provider)
                    },
                    showVoiceFallbackInput = showVoiceFallbackInput,
                    voiceFallbackDraft = voiceFallbackDraft,
                    onVoiceFallbackDraftChange = { voiceFallbackDraft = it },
                    onDismissVoiceFallback = {
                        showVoiceFallbackInput = false
                        isVoiceListening = false
                    },
                    onConfirmVoiceFallback = { submitVoiceFallbackText() },
                    onOpenReview = { showReviewScreen = true },
                    onReviewDraftChanged = { title, time, location, description ->
                        updatePendingReviewDraft(title, time, location, description)
                    },
                    onProfileSave = { nickname, avatarUri, signature, birthday, school, age, gender, major, grade, hometown ->
                        updateAccountProfile(nickname, avatarUri, signature, birthday, school, age, gender, major, grade, hometown)
                    },
                    onPickProfileAvatar = { onPickProfileAvatar() },
                    onCaptureProfileAvatar = { onCaptureProfileAvatar() },
                    inboxMessages = inboxMessages,
                    onClearInboxMessages = { clearInboxMessages() },
                    onLogout = { logoutAccount() },
                    onRetry = { onRetryRequested() },
                    onDismissError = { clearErrorState() },
                    onCancelLoading = {
                        isLoading = false
                        loadingStage = 0
                        statusText = "识别已取消"
                    }
                )
            }
        }

        handleIncomingShareIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        launchTab = resolveLaunchTab(intent)
        if (isShareIntent(intent)) {
            markAppEntered()
            showStartupIntro = false
        }
        handleIncomingShareIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        refreshPermissionState()
        refreshReminderState()
    }

    override fun onPause() {
        super.onPause()
        cancelVoiceCapture()
        if (::textToSpeechManager.isInitialized) {
            textToSpeechManager.stop()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        pendingInboxPersistJob?.cancel()
        CameraManager.shutdown()
        if (::textToSpeechManager.isInitialized) {
            textToSpeechManager.release()
        }
    }

    private fun requestPermissions(
        requestCamera: Boolean = true,
        requestAudio: Boolean = true,
        requestImages: Boolean = false
    ) {
        refreshPermissionState()

        val permissions = buildList {
            if (requestCamera && !cameraPermissionGranted) {
                add(Manifest.permission.CAMERA)
            }
            if (requestImages) {
                when {
                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
                        !hasPermission(Manifest.permission.READ_MEDIA_IMAGES) -> {
                        add(Manifest.permission.READ_MEDIA_IMAGES)
                    }

                    Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU &&
                        !hasPermission(Manifest.permission.READ_EXTERNAL_STORAGE) -> {
                        add(Manifest.permission.READ_EXTERNAL_STORAGE)
                    }
                }
            }
            if (requestAudio && !audioPermissionGranted) {
                add(Manifest.permission.RECORD_AUDIO)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !hasNotificationPermission()) {
                add(Manifest.permission.POST_NOTIFICATIONS)
            }
        }

        if (permissions.isEmpty()) {
            initializeAppIfNeeded()
            return
        }

        permissionLauncher.launch(permissions.toTypedArray())
    }

    private fun initializeAppIfNeeded() {
        if (appInitialized) {
            return
        }

        intentDispatcher = IntentDispatcher(this)
        reminderScheduler = ReminderScheduler(this)
        vlmNetworkClient = VLMNetworkClient(
            appId = BuildConfig.VLM_APP_ID,
            apiKey = BuildConfig.VLM_API_KEY,
            modelName = BuildConfig.VLM_MODEL_NAME,
            apiEndpoint = BuildConfig.VLM_API_ENDPOINT,
            ocrEndpoint = BuildConfig.VLM_OCR_ENDPOINT,
            useMockMode = false
        )
        vivoRealtimeAsrClient = VivoRealtimeAsrClient(
            context = this,
            apiKey = BuildConfig.VLM_API_KEY,
            endpoint = BuildConfig.VIVO_ASR_ENDPOINT,
            engineId = BuildConfig.VIVO_ASR_ENGINE_ID
        )
        reminderScheduler.ensureNotificationChannel()
        notificationPermissionGranted = reminderScheduler.notificationsGranted()
        refreshReminderState()
        statusText = ""
        resultText = ""
        appInitialized = true
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && !notificationPermissionGranted) {
            requestPermissions(requestCamera = false, requestAudio = false)
        }
    }

    private fun bindPreview(previewView: PreviewView) {
        if (!cameraPermissionGranted) return
        CameraManager.bindCamera(this, this, previewView) { available ->
            cameraAvailable = available
            if (!available) {
                statusText = getString(R.string.camera_preview_unavailable_mock_hint)
            }
        }
    }

    private fun onPresetSelected(preset: PromptPreset) {
        commandText = preset.prompt
        statusText = "已选择通知类型：${preset.label}"
    }

    private fun startVoiceCapture(autoStopMillis: Long? = null) {
        if (isLoading || isVoiceListening) return
        initializeAppIfNeeded()
        clearErrorState()

        if (!audioPermissionGranted) {
            openVoiceFallbackInput("麦克风尚未授权。你可以先输入语音转写内容继续解析，授权后再使用实时语音。")
            statusText = "麦克风未授权，可先使用语音兜底输入"
            requestPermissions(requestCamera = false, requestAudio = true)
            return
        }

        val stopSignal = CompletableDeferred<Unit>()
        voiceStopSignal = stopSignal
        isVoiceListening = true
        isVoiceRecordingActive = true
        voiceRecordingMillis = 0L
        voiceRecordStartedAtMillis = System.currentTimeMillis()
        statusText = "已开始语音识别，再次点击可结束"

        voiceTimerJob?.cancel()
        voiceTimerJob = lifecycleScope.launch {
            while (isVoiceRecordingActive) {
                voiceRecordingMillis = System.currentTimeMillis() - voiceRecordStartedAtMillis
                delay(180L)
            }
        }

        voiceCaptureJob?.cancel()
        voiceCaptureJob = lifecycleScope.launch {
            try {
                clearErrorState()
                val vivoText = vivoRealtimeAsrClient.listenOnce(
                    maxRecordMillis = MAX_VOICE_RECORD_MILLIS,
                    stopSignal = stopSignal
                )
                if (!vivoText.isNullOrBlank()) {
                    onVoiceTextRecognized(vivoText.trim())
                    return@launch
                }

                openVoiceFallbackInput("这次没有稳定识别出语音文本。你可以把转写内容补在这里，织时会继续发送给大模型解析。")
                statusText = "语音识别未返回有效文本，可手动补充"
            } catch (e: VivoAsrException) {
                Timber.e(e, "Vivo voice capture failed")
                openVoiceFallbackInput("语音识别暂时没有稳定返回。你可以先把转写内容补在这里，织时会继续发送给大模型解析。")
                statusText = mapVivoAsrMessage(e)
                clearErrorState()
            } catch (e: Exception) {
                if (e is CancellationException) throw e
                Timber.e(e, "Voice capture failed")
                openVoiceFallbackInput("语音入口暂时不可用，请把语音转写内容填在这里继续解析。")
                statusText = resolveErrorMessage(e)
                clearErrorState()
            } finally {
                stopVoiceTimer()
                isVoiceListening = false
                isVoiceRecordingActive = false
                voiceStopSignal = null
                voiceCaptureJob = null
            }
        }

        if (autoStopMillis != null) {
            lifecycleScope.launch {
                delay(autoStopMillis)
                finishVoiceRecording()
            }
        }
    }

    private fun finishVoiceRecording() {
        if (!isVoiceRecordingActive) return
        val elapsed = System.currentTimeMillis() - voiceRecordStartedAtMillis
        voiceRecordingMillis = elapsed
        isVoiceRecordingActive = false
        stopVoiceTimer()

        if (elapsed < MIN_VOICE_RECORD_MILLIS) {
            cancelVoiceCapture(showHint = true)
            return
        }

        statusText = "正在识别 ${formatVoiceDuration(elapsed)} 的语音…"
        voiceStopSignal?.complete(Unit)
    }

    private fun cancelVoiceCapture(showHint: Boolean = false) {
        voiceStopSignal?.complete(Unit)
        voiceCaptureJob?.cancel()
        stopVoiceTimer()
        isVoiceListening = false
        isVoiceRecordingActive = false
        voiceStopSignal = null
        voiceCaptureJob = null
        if (showHint) {
            statusText = "语音时长太短，请按住语音按钮后再说话"
        }
    }

    private fun stopVoiceTimer() {
        voiceTimerJob?.cancel()
        voiceTimerJob = null
    }

    private fun onVoiceTextRecognized(text: String) {
        commandText = text
        importedText = text
        importedImageUriText = ""
        importedSourceLabel = NoticeSourceType.VOICE.label
        statusText = "已识别语音内容，正在同步交给大模型解析"
        isVoiceListening = false
        isVoiceRecordingActive = false
        stopVoiceTimer()
        onTextImported(
            text = text,
            sourceType = NoticeSourceType.VOICE,
            userInstruction = text
        )
    }

    private fun formatVoiceDuration(millis: Long): String {
        val seconds = (millis / 1000L).coerceAtLeast(1L)
        return "${seconds}秒"
    }
    private fun openVoiceFallbackInput(message: String) {
        voiceFallbackDraft = commandText.takeIf { it != getString(R.string.default_command) }.orEmpty()
        showVoiceFallbackInput = true
        lastError = ""
        currentRecoveryAction = RecoveryAction.NONE
        showErrorOverlay = false
        if (message.isNotBlank()) {
            statusText = message
        }
    }

    private fun submitVoiceFallbackText() {
        val text = voiceFallbackDraft.trim()
        if (text.isBlank()) {
            statusText = "请先输入语音转写内容，再交给织时解析"
            return
        }
        showVoiceFallbackInput = false
        isVoiceListening = false
        commandText = text
        onTextImported(text, NoticeSourceType.VOICE)
    }

    private fun onCaptureButtonClicked() {
        if (isLoading || isVoiceListening) return
        if (!hasCaptureAccess()) {
            showError(
                message = getString(R.string.camera_permission_missing),
                recoveryAction = RecoveryAction.REQUEST_PERMISSIONS
            )
            requestPermissions(requestCamera = true, requestAudio = false)
            return
        }
        initializeAppIfNeeded()
        clearErrorState()
        statusText = "实时取景已打开，请对准通知后按下快门"
        showLiveCameraScreen = true
    }

    private fun onLiveCameraShutterClicked() {
        if (isLoading || isVoiceListening || isCameraCapturing) return
        if (!hasCaptureAccess()) {
            showLiveCameraScreen = false
            requestPermissions(requestCamera = true, requestAudio = false)
            return
        }
        initializeAppIfNeeded()
        lifecycleScope.launch {
            try {
                isCameraCapturing = true
                if (!CameraManager.isCaptureReady()) {
                    throw IllegalStateException("No available camera can be found")
                }
                val base64Image = CameraManager.captureBase64Image()

                val noticeInput = CampusNoticeInput(
                    sourceType = NoticeSourceType.CAMERA,
                    base64Image = base64Image,
                    userInstruction = commandText.ifBlank { getString(R.string.default_command) }
                )
                CameraManager.unbindPreview()
                showLiveCameraScreen = false
                processNoticeInput(noticeInput)
            } catch (e: Exception) {
                if (e is CancellationException) throw e
                Timber.e(e, "Camera capture flow failed")
                CameraManager.unbindPreview()
                showLiveCameraScreen = false
                handleError(e, RecoveryAction.RETRY_CAPTURE)
            } finally {
                isCameraCapturing = false
            }
        }
    }

    private fun onPickImageClicked() {
        if (isLoading || isVoiceListening) return
        pickImageLauncher.launch("image/*")
    }

    private fun onPasteTextClicked() {
        if (isLoading || isVoiceListening) return
        val clipboard = getSystemService(CLIPBOARD_SERVICE) as ClipboardManager
        val clip = clipboard.primaryClip
        val text = clip
            ?.takeIf {
                it.description.hasMimeType(ClipDescription.MIMETYPE_TEXT_PLAIN) ||
                    it.description.hasMimeType(ClipDescription.MIMETYPE_TEXT_HTML)
            }
            ?.getItemAt(0)
            ?.coerceToText(this)
            ?.toString()
            ?.trim()
            .orEmpty()

        if (text.isBlank()) {
            statusText = getString(R.string.clipboard_empty)
            return
        }

        commandText = text
        importedText = text
        importedImageUriText = ""
        importedSourceLabel = NoticeSourceType.CLIPBOARD.label
        statusText = "已粘贴到输入框，确认无误后点击解析"
    }

    private fun onSubmitCommandClicked() {
        if (isLoading || isVoiceListening) return
        val text = commandText.trim()
        if (text.isBlank() || text == getString(R.string.default_command)) {
            statusText = getString(R.string.manual_text_empty)
            return
        }
        val activeIntent = pendingExecutableIntent
        val activeSuggestion = pendingExecutionSuggestion
        if (
            showConfirmationCard &&
            activeIntent != null &&
            activeSuggestion != null &&
            activeSuggestion.mode == ExecutionMode.REQUIRE_CLARIFICATION
        ) {
            submitClarificationFollowUp(text, activeIntent)
            return
        }
        onTextImported(text, NoticeSourceType.MANUAL_TEXT)
    }

    private fun onImageUriImported(
        uri: Uri,
        sourceType: NoticeSourceType
    ) {
        initializeAppIfNeeded()
        requestTabNavigation("home")
        Timber.d("Image imported: sourceType=%s uri=%s", sourceType.value, uri)
        importedText = ""
        importedImageUriText = uri.toString()
        importedSourceLabel = sourceType.label
        val noticeInput = CampusNoticeInput(
            sourceType = sourceType,
            imageUri = uri,
            userInstruction = currentInstructionOrDefault()
        )
        processNoticeInput(noticeInput)
    }

    private fun onTextImported(
        text: String,
        sourceType: NoticeSourceType
    ) {
        onTextImported(
            text = text,
            sourceType = sourceType,
            userInstruction = currentInstructionOrDefault()
        )
    }

    private fun onTextImported(
        text: String,
        sourceType: NoticeSourceType,
        userInstruction: String
    ) {
        initializeAppIfNeeded()
        requestTabNavigation("home")
        Timber.d(
            "Text imported: sourceType=%s textLength=%s preview=%s",
            sourceType.value,
            text.length,
            text.take(120)
        )
        importedText = text
        importedImageUriText = ""
        importedSourceLabel = sourceType.label
        val noticeInput = CampusNoticeInput(
            sourceType = sourceType,
            rawText = text,
            userInstruction = userInstruction
        )
        processNoticeInput(noticeInput)
    }

    private fun submitClarificationFollowUp(
        text: String,
        activeIntent: ExecutableIntent
    ) {
        val originalSummary = buildReviewSourcePreview().ifBlank {
            activeIntent.buildConfirmationPrompt()
        }
        val followUpText = buildString {
            appendLine("你正在继续补全同一条校园事项，请结合已有草稿和新增补充，输出同一条事项的更新结果。")
            appendLine("不要创建新的独立事件；如果仍然无法确定，请继续返回 clarification。")
            appendLine("当前草稿标题：${activeIntent.title.orEmpty().ifBlank { "待补充" }}")
            appendLine("当前草稿时间：${activeIntent.time.orEmpty().ifBlank { "待补充" }}")
            appendLine("当前草稿地点：${activeIntent.location.orEmpty().ifBlank { "待补充" }}")
            appendLine("原始通知内容：")
            appendLine(originalSummary)
            appendLine("用户新增补充：")
            appendLine(text)
        }
        statusText = "已收到补充说明，正在继续完善当前待确认事项"
        removePendingAgendaItemById(activeIntent.stabilityKey)
        onTextImported(
            text = followUpText,
            sourceType = NoticeSourceType.MANUAL_TEXT,
            userInstruction = "请只更新当前这条待确认校园事项，不要额外创建新的事项。"
        )
    }

    private fun currentInstructionOrDefault(): String {
        return commandText.trim().takeIf { it.isNotBlank() && it != getString(R.string.default_command) }
            ?: getString(R.string.default_command)
    }

    private fun reparseHistoryItem(item: AgendaCardData) {
        val text = buildString {
            appendLine("请重新解析这条已经沉淀的校园时间碎片，并输出可执行的日程建议。")
            appendLine("标题：${item.title.ifBlank { "未命名事项" }}")
            appendLine("时间：${item.time.ifBlank { item.isoDateTime.orEmpty() }.ifBlank { "待识别" }}")
            appendLine("地点：${item.location.ifBlank { "待识别" }}")
            appendLine("来源：${item.sourceLabel.ifBlank { "历史记录" }}")
            appendLine("状态：${item.status.ifBlank { "待校验" }}")
            appendLine("摘要：${item.summary.ifBlank { "无" }}")
        }
        statusText = "正在重新解析历史记录：${item.title.ifBlank { "校园事项" }}"
        onTextImported(text, NoticeSourceType.MANUAL_TEXT)
    }

    private fun handleIncomingShareIntent(intent: Intent?) {
        if (intent?.action != Intent.ACTION_SEND) return

        Timber.d("Handle share intent: type=%s extras=%s", intent.type, intent.extras?.keySet()?.joinToString())
        val type = intent.type.orEmpty()
        when {
            type.startsWith("image/") -> {
                val uri = extractSharedImageUri(intent)
                if (uri != null) {
                    showStartupIntro = false
                    onImageUriImported(uri, NoticeSourceType.SHARE_IMAGE)
                }
            }

            type == "text/plain" || type.startsWith("text/") -> {
                val text = intent.getStringExtra(Intent.EXTRA_TEXT).orEmpty().trim()
                if (text.isNotBlank()) {
                    showStartupIntro = false
                    onTextImported(text, NoticeSourceType.SHARE_TEXT)
                }
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun extractSharedImageUri(intent: Intent): Uri? {
        return if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }
    }

    private fun processNoticeInput(noticeInput: CampusNoticeInput) {
        if (isLoading || isVoiceListening) return
        initializeAppIfNeeded()
        Timber.d(
            "Process notice input: sourceType=%s hasImage=%s hasText=%s instruction=%s",
            noticeInput.sourceType.value,
            noticeInput.hasImage,
            noticeInput.hasText,
            noticeInput.userInstruction.take(120)
        )

        if (BuildConfig.VLM_API_KEY.isBlank()) {
            showError(
                message = getString(R.string.api_key_missing),
                recoveryAction = RecoveryAction.NONE
            )
            playTextToSpeech(statusText)
            return
        }

        if (noticeInput.hasImage && BuildConfig.VLM_APP_ID.isBlank()) {
            showError(
                message = getString(R.string.app_id_missing),
                recoveryAction = RecoveryAction.NONE
            )
            playTextToSpeech(statusText)
            return
        }

        lastNoticeInput = noticeInput
        isLoading = true
        loadingStage = 0
        resultText = ""
        clearErrorState()

        lifecycleScope.launch {
            try {
                val finalCommand = commandText.ifBlank { noticeInput.userInstruction }
                loadingStage = 1
                Timber.d("Notice processing stage=prepare command=%s", finalCommand.take(120))

                val base64Image = when {
                    !noticeInput.base64Image.isNullOrBlank() -> noticeInput.base64Image
                    noticeInput.imageUri != null -> {
                        withContext(Dispatchers.IO) {
                            UriImageUtils.uriToBase64Jpeg(this@MainActivity, noticeInput.imageUri)
                        }
                    }

                    else -> null
                }
                Timber.d(
                    "Notice processing stage=prepared sourceType=%s imageBase64Length=%s rawTextLength=%s",
                    noticeInput.sourceType.value,
                    base64Image?.length ?: 0,
                    noticeInput.rawText?.length ?: 0
                )

                val analysis = analyzeCampusNotice(
                    noticeInput = noticeInput,
                    base64Image = base64Image,
                    userText = finalCommand
                )
                handleVlmResponse(
                    analysis = analysis,
                    noticeInput = noticeInput,
                    userText = finalCommand
                )
            } catch (e: Exception) {
                if (e is CancellationException) throw e
                Timber.e(e, "Campus notice flow failed")
                handleError(
                    throwable = e,
                    recoveryAction = if (noticeInput.sourceType == NoticeSourceType.CAMERA) {
                        RecoveryAction.RETRY_CAPTURE
                    } else {
                        RecoveryAction.RETRY_IMPORT
                    }
                )
                if (lastError.isNotBlank()) {
                    playTextToSpeech(lastError)
                }
            } finally {
                isLoading = false
                loadingStage = 0
            }
        }
    }

    private suspend fun analyzeCampusNotice(
        noticeInput: CampusNoticeInput,
        base64Image: String?,
        userText: String
    ): CampusNoticeAnalysis {
        return vlmNetworkClient.analyzeCampusNotice(
            base64Image = base64Image,
            userText = userText,
            rawText = noticeInput.rawText,
            sourceType = noticeInput.sourceType.label
        )
    }

    private suspend fun handleVlmResponse(
        analysis: CampusNoticeAnalysis,
        noticeInput: CampusNoticeInput,
        userText: String
    ) {
        val executableIntents = resolveExecutableIntents(
            analysis = analysis,
            noticeInput = noticeInput,
            userText = userText
        )
        Timber.d(
            "VLM parsed batch: count=%s actions=%s",
            executableIntents.size,
            executableIntents.joinToString(separator = ",") { it.action }
        )
        loadingStage = 2
        handleExecutionSuggestions(executableIntents)
        clearTextInputAfterSuccessfulParse()
    }

    private suspend fun resolveExecutableIntents(
        analysis: CampusNoticeAnalysis,
        noticeInput: CampusNoticeInput,
        userText: String
    ): List<ExecutableIntent> {
        val initialIntents = ResponseInterpreter.expand(analysis.response)
            .map(VisualActionIntentSchema::fromResponse)
            .distinctBy { it.stabilityKey }
        if (initialIntents.size > 1) {
            return initialIntents
        }

        val candidateSegments = NoticeSegmentExtractor.extractIndependentScheduleSegments(
            analysis.sourceTextForSegmentation
        )
        if (candidateSegments.size < 2) {
            return initialIntents
        }

        Timber.d(
            "Detected %s candidate notice segments for multi-event fallback: %s",
            candidateSegments.size,
            candidateSegments.joinToString(" || ")
        )

        val fallbackIntents = candidateSegments.mapNotNull { segment ->
            runCatching {
                vlmNetworkClient.sendCampusNoticeRequest(
                    base64Image = null,
                    userText = userText,
                    rawText = segment,
                    sourceType = "${noticeInput.sourceType.label}-segment"
                )
            }.onFailure { throwable ->
                Timber.w(throwable, "Fallback segment parse failed: %s", segment)
            }.getOrNull()
        }
            .flatMap { ResponseInterpreter.expand(it) }
            .map(VisualActionIntentSchema::fromResponse)
            .distinctBy { it.stabilityKey }

        return if (fallbackIntents.size > initialIntents.size) {
            Timber.d(
                "Multi-event fallback promoted result set from %s to %s items",
                initialIntents.size,
                fallbackIntents.size
            )
            fallbackIntents
        } else {
            initialIntents
        }
    }

    private fun clearTextInputAfterSuccessfulParse() {
        val sourceType = lastNoticeInput?.sourceType
        if (TextInputClearPolicy.shouldClearAfterSuccessfulParse(sourceType)) {
            commandText = ""
        }
    }

    private fun handleExecutionSuggestions(executableIntents: List<ExecutableIntent>) {
        if (executableIntents.isEmpty()) return
        if (executableIntents.size == 1) {
            handleExecutionSuggestion(executableIntents.first())
            return
        }
        handleBatchExecutionSuggestions(executableIntents)
    }

    private fun evaluateExecutionSuggestion(executableIntent: ExecutableIntent): ExecutionSuggestion {
        return evaluateExecutionSuggestionSafe(executableIntent)
        /*
        var suggestion = riskPolicyEngine.evaluate(executableIntent)
        if (blockHighRisk && executableIntent.riskLevel == com.vsa.visualsemanticagent.decision.IntentRiskLevel.HIGH) {
            suggestion = suggestion.copy(
                mode = ExecutionMode.BLOCKED,
                summary = "妤傛﹢顥撻梽鈺佸З娴ｆ粌鍑＄悮顐ょ矏閺冩儼鍤滈崝銊﹀閹?,
                prompt = "瑜版挸澧犻崑蹇撱偨瀹告彃绱戦崥顖炵彯妞嬪酣娅撻幐鍥︽姢閼奉亜濮╅幏锔藉焻閵嗗倷璐熸穱婵婄槈鐎瑰鍙忛敍宀冪箹缁濮╂担婊€绗夋导姘辨埛缂侇厽澧界悰灞烩偓?
            )
        } else if (!blockHighRisk && executableIntent.riskLevel == com.vsa.visualsemanticagent.decision.IntentRiskLevel.HIGH) {
            suggestion = suggestion.copy(
                summary = "${suggestion.summary}閿涘牆缍嬮崜宥呭嚒閸忔娊妫存姗€顥撻梽鈺佸З娴ｆ粓顤傛径鏍ㄥ閹搭亷绱?,
                prompt = "娴ｇ姴鍑￠崗鎶芥４妤傛﹢顥撻梽鈺佸З娴ｆ粓顤傛径鏍ㄥ閹搭亷绱濇担鍡欑矏閺冩湹绮涘楦款唴鐠嬨劍鍘х涵顔款吇閵?
            )
        }
        if (!autoMapLink && executableIntent.action == "navigate") {
            suggestion = suggestion.copy(
                mode = ExecutionMode.BLOCKED,
                summary = "瀹歌尪鐦戦崚顐㈠毉閸︽壆鍋ｉ敍灞肩稻閸︽澘娴橀懕鏂垮З瑜版挸澧犲鎻掑彠闂?,
                prompt = "娴ｇ姴褰叉禒銉ユ躬閳ユ粍鍨滈惃鍕ㄢ偓婵嬨€夐柌宥嗘煀瀵偓閸氼垰婀撮悙纭呅掗弸鎰瑢閸︽澘娴橀懕鏂垮З閿涘本鍨ㄩ崗鍫濈殺閸︽壆鍋ｆ担婊€璐熼弲顕€鈧矮淇婇幁顖欑箽閻ｆ瑣鈧?
            )
        }
        if (muteLowConfidence && suggestion.mode == ExecutionMode.REQUIRE_CLARIFICATION) {
            suggestion = suggestion.copy(
                summary = "娴ｅ海鐤嗘穱鈥冲缂佹挻鐏夊鑼额潶闂堟瑩绮梽宥囬獓閿涘苯缂撶拋顔荤稑鐞涖儱鍘栨穱鈩冧紖閸氬骸鍟€鐠囨洏鈧?,
                prompt = "瑜版挸澧犵紒鎾寸亯娑撳秴顧勭粙鍐茬暰閿涘苯缂撶拋顔克夐崗鍛闂傛番鈧礁婀撮悙瑙勫灗闁插秵鏌婄€电厧鍙嗛妴?
            )
        }
        return suggestion
        */
    }

    private fun evaluateExecutionSuggestionSafe(executableIntent: ExecutableIntent): ExecutionSuggestion {
        var suggestion = riskPolicyEngine.evaluate(executableIntent)
        if (blockHighRisk && executableIntent.riskLevel == com.vsa.visualsemanticagent.decision.IntentRiskLevel.HIGH) {
            suggestion = suggestion.copy(
                mode = ExecutionMode.BLOCKED,
                summary = "高风险动作已被织时自动拦截",
                prompt = "当前偏好已开启高风险指令自动拦截。为保证安全，这类动作不会继续执行。"
            )
        } else if (!blockHighRisk && executableIntent.riskLevel == com.vsa.visualsemanticagent.decision.IntentRiskLevel.HIGH) {
            suggestion = suggestion.copy(
                summary = "${suggestion.summary}（当前已关闭高风险动作额外拦截）",
                prompt = "你已关闭高风险动作额外拦截，但织时仍建议谨慎确认。"
            )
        }
        if (!autoMapLink && executableIntent.action == "navigate") {
            suggestion = suggestion.copy(
                mode = ExecutionMode.BLOCKED,
                summary = "已识别出地点，但地图联动当前已关闭",
                prompt = "你可以在“我的”页重新开启地点解析与地图联动，或先将地点作为普通信息保留下来。"
            )
        }
        if (muteLowConfidence && suggestion.mode == ExecutionMode.REQUIRE_CLARIFICATION) {
            suggestion = suggestion.copy(
                summary = "低置信度结果已被静默降级，建议你补充信息后再试。",
                prompt = "当前结果不够稳定，建议补充时间、地点或重新导入。"
            )
        }
        return suggestion
    }

    private fun handleBatchExecutionSuggestions(executableIntents: List<ExecutableIntent>) {
        val actionableIntents = executableIntents.filterNot { it.action == ModelConstants.ACTION_UNKNOWN }
            .ifEmpty { executableIntents.take(1) }
        var confirmationCount = 0
        var clarificationCount = 0
        var blockedCount = 0
        var ttsCount = 0

        actionableIntents.asReversed().forEach { executableIntent ->
            val suggestion = evaluateExecutionSuggestion(executableIntent)
            when (suggestion.mode) {
                ExecutionMode.DIRECT_TTS -> {
                    ttsCount += 1
                    appendInboxMessage(
                        type = "tts",
                        title = "语音反馈已生成",
                        summary = suggestion.summary,
                        status = "已处理"
                    )
                }

                ExecutionMode.REQUIRE_CONFIRMATION -> {
                    confirmationCount += 1
                    enqueuePendingExecution(executableIntent, suggestion, activate = true)
                    upsertPendingAgendaItem(
                        executableIntent = executableIntent,
                        summary = suggestion.summary,
                        status = when (executableIntent.action) {
                            "create_event" -> "待确认"
                            "navigate" -> "待导航"
                            else -> "待处理"
                        }
                    )
                    appendInboxMessage(
                        type = "pending",
                        title = executableIntent.title ?: "有一条待确认校园事项",
                        summary = suggestion.summary,
                        status = "待确认"
                    )
                }

                ExecutionMode.REQUIRE_CLARIFICATION -> {
                    clarificationCount += 1
                    enqueuePendingExecution(executableIntent, suggestion, activate = true)
                    upsertPendingAgendaItem(
                        executableIntent = executableIntent,
                        summary = suggestion.summary,
                        status = "待补充"
                    )
                    appendInboxMessage(
                        type = "clarification",
                        title = executableIntent.title ?: "低置信度结果需要补充",
                        summary = suggestion.summary,
                        status = "待补充"
                    )
                }

                ExecutionMode.BLOCKED -> {
                    blockedCount += 1
                    appendInboxMessage(
                        type = "blocked",
                        title = "高风险动作已拦截",
                        summary = suggestion.summary,
                        status = "已拦截"
                    )
                }
            }
        }

        statusText = when {
            clarificationCount > 0 -> "本次共识别 ${actionableIntents.size} 条事项，其中 $clarificationCount 条还需补充信息"
            confirmationCount > 0 -> "本次共识别 ${actionableIntents.size} 条事项，已有待确认结果可继续处理"
            blockedCount > 0 -> "本次识别中有 ${actionableIntents.size} 条事项，部分结果因风险过高已被拦截"
            ttsCount > 0 -> "本次识别已生成语音反馈"
            else -> "本次校园碎片已完成初步整理"
        }
        resultText = buildBatchResultCardText(
            executableIntents = actionableIntents,
            confirmationCount = confirmationCount,
            clarificationCount = clarificationCount,
            blockedCount = blockedCount
        )
        showReviewScreen = pendingExecutionSuggestion?.mode == ExecutionMode.REQUIRE_CLARIFICATION

        when {
            clarificationCount > 0 && !muteLowConfidence -> {
                playTextToSpeech("这批通知里还有信息不够完整的结果，建议你补充标题、时间或地点后再确认。")
            }

            confirmationCount > 0 -> {
                playTextToSpeech("这批通知里已经生成待确认事项，你可以继续检查后再执行。")
            }

            blockedCount > 0 && !muteLowConfidence -> {
                playTextToSpeech("部分结果因风险较高已被拦截。若确认需要执行，请先调整风险偏好或补充信息。")
            }
        }
    }

    private fun handleExecutionSuggestion(executableIntent: ExecutableIntent) {
        var suggestion = riskPolicyEngine.evaluate(executableIntent)
        if (blockHighRisk && executableIntent.riskLevel == com.vsa.visualsemanticagent.decision.IntentRiskLevel.HIGH) {
            suggestion = suggestion.copy(
                mode = ExecutionMode.BLOCKED,
                summary = "高风险动作已被织时自动拦截",
                prompt = "当前偏好已开启高风险指令自动拦截。为保证安全，这类动作不会继续执行。"
            )
        } else if (!blockHighRisk && executableIntent.riskLevel == com.vsa.visualsemanticagent.decision.IntentRiskLevel.HIGH) {
            suggestion = suggestion.copy(
                summary = "${suggestion.summary}（当前已关闭高风险动作额外拦截）",
                prompt = "你已关闭高风险动作额外拦截，但织时仍建议谨慎确认。"
            )
        }
        if (!autoMapLink && executableIntent.action == "navigate") {
            suggestion = suggestion.copy(
                mode = ExecutionMode.BLOCKED,
                summary = "已识别出地点，但地图联动当前已关闭",
                prompt = "你可以在“我的”页重新开启地点解析与地图联动，或先将地点作为普通信息保留。"
            )
        }
        if (muteLowConfidence && suggestion.mode == ExecutionMode.REQUIRE_CLARIFICATION) {
            suggestion = suggestion.copy(
                summary = "低置信度结果已被静默降级，建议你补充信息后再试。",
                prompt = "当前结果不够稳定，建议补充时间、地点或重新导入。"
            )
        }
        Timber.d(
            "Execution suggestion: action=%s mode=%s threshold=%.2f summary=%s",
            executableIntent.action,
            suggestion.mode,
            suggestion.threshold,
            suggestion.summary
        )

        when (suggestion.mode) {
            ExecutionMode.DIRECT_TTS -> {
                statusText = suggestion.summary
                resultText = buildResultCardText(executableIntent, suggestion.summary, suggestion)
                syncPendingExecutionUi()
                appendInboxMessage(
                    type = "tts",
                    title = "语音反馈已生成",
                    summary = suggestion.summary,
                    status = "已处理"
                )
                playTextToSpeech(suggestion.prompt)
            }

            ExecutionMode.REQUIRE_CONFIRMATION -> {
                enqueuePendingExecution(executableIntent, suggestion)
                statusText = suggestion.summary
                resultText = buildResultCardText(executableIntent, suggestion.summary, suggestion)
                upsertPendingAgendaItem(
                    executableIntent = executableIntent,
                    summary = suggestion.summary,
                    status = when (executableIntent.action) {
                        "create_event" -> "待确认"
                        "navigate" -> "待导航"
                        else -> "待处理"
                    }
                )
                appendInboxMessage(
                    type = "pending",
                    title = executableIntent.title ?: "有一条待确认校园事项",
                    summary = suggestion.summary,
                    status = "待处理"
                )
                playTextToSpeech(suggestion.prompt)
            }

            ExecutionMode.REQUIRE_CLARIFICATION -> {
                enqueuePendingExecution(executableIntent, suggestion)
                statusText = suggestion.summary
                resultText = buildResultCardText(executableIntent, suggestion.summary, suggestion)
                showReviewScreen = true
                upsertPendingAgendaItem(
                    executableIntent = executableIntent,
                    summary = suggestion.summary,
                    status = "待补充"
                )
                appendInboxMessage(
                    type = "clarification",
                    title = executableIntent.title ?: "低置信度结果需要补充",
                    summary = suggestion.summary,
                    status = "待补充"
                )
                if (!muteLowConfidence) {
                    playTextToSpeech(suggestion.prompt)
                }
            }

            ExecutionMode.BLOCKED -> {
                statusText = suggestion.summary
                resultText = buildResultCardText(executableIntent, suggestion.summary, suggestion)
                syncPendingExecutionUi()
                appendInboxMessage(
                    type = "blocked",
                    title = "高风险动作已拦截",
                    summary = suggestion.summary,
                    status = "已拦截"
                )
                if (!muteLowConfidence) {
                    playTextToSpeech(suggestion.prompt)
                }
            }
        }
    }

    private fun onConfirmExecutionClicked() {
        val executableIntent = pendingExecutableIntent
        val suggestion = pendingExecutionSuggestion
        if (!showConfirmationCard || executableIntent == null || suggestion == null) {
            statusText = "褰撳墠娌℃湁鍙‘璁ょ殑浜嬮」锛岃鍏堝鍏ヤ竴鏉℃柊鐨勬牎鍥€氱煡"
            return
        }
        if (suggestion.mode == ExecutionMode.REQUIRE_CLARIFICATION) {
            showReviewScreen = true
            statusText = "这条通知还需要补充确认，请先在解析校验页修改标题、时间或地点"
            return
        }

        try {
            val summary = if (executableIntent.action == "create_event") {
                "已确认事项，已织入你的专属时间线"
            } else {
                intentDispatcher.dispatchIntent(executableIntent).summary
            }
            statusText = summary
            resultText = buildResultCardText(executableIntent, summary, suggestion)
            showConfirmationCard = false
            removePendingExecution(executableIntent.stabilityKey)
            if (executableIntent.action == "create_event") {
                movePendingAgendaToAdded(
                    executableIntent = executableIntent,
                    summary = summary
                )
            } else {
                removePendingAgendaItem(executableIntent)
            }
            appendInboxMessage(
                type = "confirmed",
                title = executableIntent.title ?: "已确认一条校园事项",
                summary = summary,
                status = "已处理"
            )
            refreshReminderState()
            playTextToSpeech(summary)
        } catch (e: Exception) {
            Timber.e(e, "Execution failed after confirmation")
            handleError(e, RecoveryAction.RETRY_IMPORT)
        }
    }

    private fun onCancelExecutionClicked() {
        val executableIntent = pendingExecutableIntent
        val suggestion = pendingExecutionSuggestion
        statusText = "已取消执行"
        if (executableIntent == null) {
            syncPendingExecutionUi(showCard = false)
        }
        if (executableIntent != null) {
            agendaItems = agendaItems.map { item ->
                if (item.id == executableIntent.stabilityKey) {
                    item.copy(status = "已取消", reminders = currentReminderSet())
                } else {
                    item
                }
            }
            removePendingAgendaItem(executableIntent)
            removePendingExecution(executableIntent.stabilityKey)
            appendInboxMessage(
                type = "cancelled",
                title = executableIntent.title ?: "已取消一条待执行事项",
                summary = suggestion?.summary ?: "用户取消了本次执行",
                status = "已取消"
            )
        }
        resultText = buildString {
            append("已取消执行")
            if (suggestion != null) {
                append("\n")
                append(suggestion.prompt)
            }
        }
        refreshReminderState()
    }

    private fun updatePendingReviewDraft(
        title: String,
        time: String,
        location: String,
        description: String
    ) {
        val currentIntent = pendingExecutableIntent ?: return
        val currentSuggestion = pendingExecutionSuggestion ?: return
        val originalKey = currentIntent.stabilityKey
        val updatedPayload = currentIntent.payload.copy(
            title = title.trim().ifBlank { null },
            time = time.trim().ifBlank { null },
            location = location.trim().ifBlank { null },
            description = description.trim().ifBlank { null }
        )
        val updatedIntent = currentIntent.withReviewedSchedulePayload(updatedPayload)
        val shouldPromoteClarificationToEvent = currentIntent.action == ModelConstants.ACTION_CLARIFICATION &&
            updatedIntent.action == ModelConstants.ACTION_CREATE_EVENT
        val reevaluatedSuggestion = riskPolicyEngine.evaluate(updatedIntent)
        val updatedSuggestion = reevaluatedSuggestion.copy(
            mode = when {
                shouldPromoteClarificationToEvent -> ExecutionMode.REQUIRE_CONFIRMATION
                currentSuggestion.mode == ExecutionMode.REQUIRE_CLARIFICATION && reevaluatedSuggestion.mode == ExecutionMode.BLOCKED ->
                    ExecutionMode.REQUIRE_CLARIFICATION
                else -> reevaluatedSuggestion.mode
            },
            summary = updatedIntent.buildSummary(),
            prompt = updatedIntent.buildConfirmationPrompt()
        )
        replacePendingExecution(originalKey, updatedIntent, updatedSuggestion)
        if (originalKey != updatedIntent.stabilityKey) {
            removePendingAgendaItemById(originalKey)
        }
        upsertPendingAgendaItem(
            executableIntent = updatedIntent,
            summary = updatedSuggestion.summary,
            status = pendingAgendaStatusFor(updatedIntent, updatedSuggestion)
        )
        statusText = updatedSuggestion.summary
        resultText = buildResultCardText(updatedIntent, updatedSuggestion.summary, updatedSuggestion)
    }

    private fun buildReviewSourcePreview(): String {
        return when {
            importedText.isNotBlank() -> importedText
            commandText.isNotBlank() && commandText != getString(R.string.default_command) -> commandText
            importedImageUriText.isNotBlank() -> "图片来源：$importedImageUriText"
            lastNoticeInput?.rawText?.isNotBlank() == true -> lastNoticeInput?.rawText.orEmpty()
            resultText.isNotBlank() -> resultText
            statusText.isNotBlank() -> statusText
            else -> ""
        }
    }

    private fun activeSourceLabel(): String {
        return pendingSourceLabel.ifBlank { importedSourceLabel }
    }

    private fun activeSourcePreview(): String {
        return pendingSourcePreview.ifBlank { buildReviewSourcePreview() }
    }

    private fun buildPendingExecutionEntry(
        executableIntent: ExecutableIntent,
        suggestion: ExecutionSuggestion
    ): PendingExecutionEntry {
        return PendingExecutionEntry(
            intent = executableIntent,
            suggestion = suggestion,
            sourceLabel = importedSourceLabel,
            sourcePreview = buildReviewSourcePreview()
        )
    }

    private fun syncPendingExecutionUi(showCard: Boolean = pendingExecutionSnapshot.activeEntry != null) {
        val active = pendingExecutionSnapshot.activeEntry
        pendingExecutableIntent = active?.intent
        pendingExecutionSuggestion = active?.suggestion
        pendingSourceLabel = active?.sourceLabel.orEmpty()
        pendingSourcePreview = active?.sourcePreview.orEmpty()
        showConfirmationCard = showCard && active != null
    }

    private fun enqueuePendingExecution(
        executableIntent: ExecutableIntent,
        suggestion: ExecutionSuggestion,
        activate: Boolean = true
    ) {
        pendingExecutionSnapshot = PendingExecutionRegistry.upsert(
            snapshot = pendingExecutionSnapshot,
            entry = buildPendingExecutionEntry(executableIntent, suggestion),
            activate = activate
        )
        syncPendingExecutionUi(showCard = true)
    }

    private fun removePendingExecution(stabilityKey: String) {
        pendingExecutionSnapshot = PendingExecutionRegistry.remove(
            snapshot = pendingExecutionSnapshot,
            stabilityKey = stabilityKey
        )
        syncPendingExecutionUi()
    }

    private fun replacePendingExecution(
        originalKey: String,
        updatedIntent: ExecutableIntent,
        updatedSuggestion: ExecutionSuggestion
    ) {
        val active = pendingExecutionSnapshot.activeEntry
        val updatedEntry = PendingExecutionEntry(
            intent = updatedIntent,
            suggestion = updatedSuggestion,
            sourceLabel = active?.sourceLabel.orEmpty(),
            sourcePreview = active?.sourcePreview.orEmpty()
        )
        pendingExecutionSnapshot = PendingExecutionRegistry.replace(
            snapshot = pendingExecutionSnapshot,
            originalKey = originalKey,
            updatedEntry = updatedEntry,
            activate = true
        )
        syncPendingExecutionUi(showCard = true)
    }

    private fun buildResultCardText(
        intent: ExecutableIntent,
        summary: String,
        suggestion: ExecutionSuggestion
    ): String {
        val parts = linkedSetOf<String>()
        if (importedSourceLabel.isNotBlank()) {
            parts.add("来源：$importedSourceLabel")
        }
        parts.add(summary)
        parts.add("建议动作：${intent.action}")
        parts.add("识别可信度：${"%.2f".format(intent.fusedConfidence)}")
        parts.add("执行模式：${suggestion.mode}")
        intent.title?.let { parts.add("标题：$it") }
        intent.time?.let { parts.add("时间：$it") }
        intent.location?.let { parts.add("地点：$it") }
        intent.description?.let { parts.add("备注：$it") }
        intent.answer?.let { parts.add("播报：$it") }
        if (suggestion.validation.issues.isNotEmpty()) {
            parts.add("校验问题：${suggestion.validation.issues.joinToString()}")
        }
        parts.add("建议话术：${suggestion.prompt}")
        return parts.joinToString(separator = "\n")
    }

    private fun buildBatchResultCardText(
        executableIntents: List<ExecutableIntent>,
        confirmationCount: Int,
        clarificationCount: Int,
        blockedCount: Int
    ): String {
        val parts = mutableListOf<String>()
        if (importedSourceLabel.isNotBlank()) {
            parts += "来源：$importedSourceLabel"
        }
        parts += "本次共识别 ${executableIntents.size} 条校园事项"
        if (confirmationCount > 0) {
            parts += "待确认：$confirmationCount 条"
        }
        if (clarificationCount > 0) {
            parts += "待补充：$clarificationCount 条"
        }
        if (blockedCount > 0) {
            parts += "已拦截：$blockedCount 条"
        }
        executableIntents.forEachIndexed { index, intent ->
            parts += "${index + 1}. ${intent.title ?: "未命名事项"} · ${intent.time ?: "时间待补充"} · ${intent.location ?: "地点待补充"}"
        }
        pendingExecutableIntent?.let { activeIntent ->
            parts += "当前卡片：${activeIntent.title ?: "未命名事项"}"
        }
        return parts.joinToString(separator = "\n")
    }

    private fun upsertPendingAgendaItem(
        executableIntent: ExecutableIntent,
        summary: String,
        status: String
    ) {
        val item = buildAgendaCardData(
            executableIntent = executableIntent,
            summary = summary,
            status = status
        )
        agendaItems = listOf(item) + agendaItems.filterNot { it.id == item.id }
        persistAgendaItems()
    }

    private fun pendingAgendaStatusFor(
        executableIntent: ExecutableIntent,
        suggestion: ExecutionSuggestion
    ): String {
        return when (suggestion.mode) {
            ExecutionMode.REQUIRE_CONFIRMATION -> when (executableIntent.action) {
                "navigate" -> "待导航"
                else -> "待确认"
            }

            ExecutionMode.REQUIRE_CLARIFICATION -> "待补充"
            ExecutionMode.BLOCKED -> "待校验"
            else -> "待处理"
        }
    }

    private fun movePendingAgendaToAdded(
        executableIntent: ExecutableIntent,
        summary: String
    ) {
        val item = buildAgendaCardData(
            executableIntent = executableIntent,
            summary = summary,
            status = "已加入日历"
        )
        agendaItems = listOf(item) + agendaItems.filterNot { it.id == item.id }
        reminderScheduler.scheduleAgendaReminders(item)
        persistAgendaItems()
        refreshReminderState()
    }

    private fun removePendingAgendaItem(executableIntent: ExecutableIntent) {
        removePendingAgendaItemById(executableIntent.stabilityKey)
    }

    private fun removePendingAgendaItemById(stabilityKey: String) {
        val currentItem = agendaItems.firstOrNull { it.id == stabilityKey }
        reminderScheduler.cancelAgendaReminders(
            agendaId = stabilityKey,
            reminders = currentItem?.reminders ?: defaultAgendaReminders()
        )
        agendaItems = agendaItems.filterNot { it.id == stabilityKey }
        persistAgendaItems()
        refreshReminderState()
    }

    private fun updateAgendaItem(updatedItem: AgendaCardData) {
        val previousItem = agendaItems.firstOrNull { it.id == updatedItem.id }
        if (previousItem == null) {
            agendaItems = listOf(updatedItem) + agendaItems
        } else {
            if (::reminderScheduler.isInitialized && previousItem.isConfirmedStatus()) {
                reminderScheduler.cancelAgendaReminders(previousItem.id, previousItem.reminders)
            }
            agendaItems = agendaItems.map { item ->
                if (item.id == updatedItem.id) updatedItem else item
            }
        }
        if (::reminderScheduler.isInitialized && updatedItem.isConfirmedStatus()) {
            reminderScheduler.scheduleAgendaReminders(updatedItem)
        }
        statusText = "已更新日程：${updatedItem.title}"
        resultText = buildAgendaOperationText("日程已保存", updatedItem)
        persistAgendaItems()
        refreshReminderState()
        appendInboxMessage(
            type = "edited",
            title = "日程已更新",
            summary = "${updatedItem.title.ifBlank { "未命名事项" }} · ${updatedItem.time.ifBlank { "时间待补充" }}",
            status = "已处理"
        )
    }

    private fun deleteAgendaItem(item: AgendaCardData) {
        if (::reminderScheduler.isInitialized) {
            reminderScheduler.cancelAgendaReminders(item.id, item.reminders)
        }
        agendaItems = agendaItems.filterNot { it.id == item.id }
        statusText = "已删除日程：${item.title}"
        resultText = buildAgendaOperationText("日程已从时间线移除", item)
        persistAgendaItems()
        refreshReminderState()
        appendInboxMessage(
            type = "deleted",
            title = "日程已删除",
            summary = item.title.ifBlank { "未命名事项" },
            status = "已处理"
        )
    }

    private fun duplicateAgendaItem(item: AgendaCardData) {
        val duplicate = item.copy(
            id = "${item.id}-copy-${System.currentTimeMillis()}",
            title = "${item.title.ifBlank { "未命名事项" }} 副本",
            status = "待校验",
            sourceLabel = item.sourceLabel.ifBlank { "时间线复制" },
            reminders = currentReminderSet()
        )
        agendaItems = listOf(duplicate) + agendaItems
        statusText = "已复制成待校验事项"
        resultText = buildAgendaOperationText("已生成待校验副本", duplicate)
        persistAgendaItems()
        refreshReminderState()
        appendInboxMessage(
            type = "duplicated",
            title = "已复制成新事项",
            summary = duplicate.title,
            status = "待校验"
        )
    }

    private fun navigateAgendaItem(item: AgendaCardData) {
        val location = item.location.trim()
        if (location.isBlank()) {
            Toast.makeText(this, "这条日程还没有地点，暂时不能导航", Toast.LENGTH_SHORT).show()
            appendInboxMessage(
                type = "navigate_failed",
                title = "导航失败",
                summary = "${item.title.ifBlank { "未命名事项" }} 缺少地点字段",
                status = "待补充"
            )
            return
        }
        pendingNavigationAgenda = item
    }

    private fun executeAgendaNavigation(item: AgendaCardData, provider: String?) {
        val location = item.location.trim()
        if (location.isBlank()) return
        val navigateIntent = ExecutableIntent(
            scene = VisualActionIntentSchema.SCENE_CAMPUS_SCHEDULE_AGENT,
            action = ModelConstants.ACTION_NAVIGATE,
            payload = ExecutablePayload(
                title = item.title,
                location = location,
                description = item.summary
            ),
            modelConfidence = 1.0,
            fusedConfidence = 1.0,
            fallbackQuery = null,
            requiresConfirmation = false,
            riskLevel = IntentRiskLevel.MEDIUM
        )
        runCatching {
            val result = intentDispatcher.dispatchIntent(navigateIntent, preferredMapProvider = provider)
            statusText = result.summary
            resultText = buildAgendaOperationText(result.summary, item)
            appendInboxMessage(
                type = "navigate",
                title = "已打开地点导航",
                summary = location,
                status = "已处理"
            )
        }.onFailure { error ->
            Timber.e(error, "Failed to navigate from agenda detail")
            val message = resolveErrorMessage(error)
            Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
            appendInboxMessage(
                type = "error",
                title = "导航失败",
                summary = message,
                status = "待处理"
            )
        }
    }

    private fun buildAgendaOperationText(action: String, item: AgendaCardData): String {
        return buildString {
            appendLine(action)
            appendLine("标题：${item.title.ifBlank { "未命名事项" }}")
            appendLine("时间：${item.time.ifBlank { item.isoDateTime.orEmpty() }.ifBlank { "待补充" }}")
            appendLine("地点：${item.location.ifBlank { "待补充" }}")
            appendLine("状态：${item.status.ifBlank { "待校验" }}")
        }.trim()
    }

    private fun AgendaCardData.isConfirmedAgenda(): Boolean {
        return status.contains("已加入") || status.contains("已确认")
    }

    private fun AgendaCardData.isPendingAgenda(): Boolean {
        return status.contains("待确认") ||
            status.contains("待补充") ||
            status.contains("待导航") ||
            status.contains("待处理") ||
            status.contains("待校验")
    }

    private fun buildAgendaCardData(
        executableIntent: ExecutableIntent,
        summary: String,
        status: String
    ): AgendaCardData {
        return AgendaCardData(
            id = executableIntent.stabilityKey,
            title = executableIntent.title
                ?: commandText.takeIf { it.isNotBlank() }?.take(18)
                ?: "新的校园通知待整理",
            summary = summary,
            time = executableIntent.time ?: "等待提取时间字段",
            location = executableIntent.location?.takeIf { it.isNotBlank() } ?: "无地点",
            status = status,
            isoDateTime = executableIntent.time,
            sourceLabel = activeSourceLabel(),
            action = executableIntent.action,
            reminders = currentReminderSet(),
            ownerAccount = currentAccountUser?.account.orEmpty()
        )
    }

    private fun playTextToSpeech(text: String) {
        val normalized = text
            .lineSequence()
            .map { it.trim() }
            .filter { it.isNotBlank() }
            .take(2)
            .joinToString("。")
            .take(MAX_TTS_TEXT_LENGTH)
            .trim()
        if (normalized.isBlank()) return

        val now = System.currentTimeMillis()
        if (normalized == lastSpokenText && now - lastSpokenAtMillis < TTS_DEBOUNCE_MILLIS) {
            return
        }
        lastSpokenText = normalized
        lastSpokenAtMillis = now
        ensureTextToSpeechManager().speak(normalized)
    }

    private fun ensureTextToSpeechManager(): TextToSpeechManager {
        if (!::textToSpeechManager.isInitialized) {
            textToSpeechManager = TextToSpeechManager(this)
        }
        return textToSpeechManager
    }

    private fun refreshReminderState() {
        val confirmedItems = agendaItems.filter {
            it.isConfirmedStatus()
        }
        confirmedAgendaCount = confirmedItems.size
        pendingAgendaCount = agendaItems.count { it.isPendingStatus() }
        todayAgendaCount = confirmedItems.count { it.scheduleDate() == LocalDate.now() }
        scheduledReminderCount = countAgendasWithUpcomingReminders(confirmedItems)
        reminderStateText = if (::reminderScheduler.isInitialized && reminderScheduler.notificationsGranted()) {
            "本地通知已启用，正在保护 ${confirmedItems.size} 条已确认日程"
        } else if (::reminderScheduler.isInitialized) {
            "通知权限未开启，本地提醒暂不可见"
        } else if (confirmedItems.isEmpty()) {
            "提醒引擎待激活"
        } else {
            "提醒引擎待激活，已确认日程将在初始化后挂载提醒"
        }
        nextReminderText = if (::reminderScheduler.isInitialized) {
            reminderScheduler.nextReminderSummary(confirmedItems)
        } else if (confirmedItems.isEmpty()) {
            "暂无即将触发的提醒"
        } else {
            "初始化后将生成本地提醒"
        }
        val labels = buildList {
            if (reminderDayEnabled) add("1天")
            if (reminderHourEnabled) add("${reminderLeadMinutes}分钟")
        }
        reminderPolicyLabel = "默认提前 ${labels.joinToString(" / ").ifBlank { "关闭" }}"
    }

    private fun currentReminderSet(): List<com.vsa.visualsemanticagent.plan.AgendaReminderData> {
        return buildList {
            if (reminderDayEnabled) {
                add(com.vsa.visualsemanticagent.plan.AgendaReminderData(label = "提前1天", minutesBefore = 24 * 60))
            }
            if (reminderHourEnabled) {
                val label = when (reminderLeadMinutes) {
                    15 -> "提前15分钟"
                    30 -> "提前30分钟"
                    60 -> "提前1小时"
                    else -> "提前${reminderLeadMinutes}分钟"
                }
                add(com.vsa.visualsemanticagent.plan.AgendaReminderData(label = label, minutesBefore = reminderLeadMinutes))
            }
        }
    }

    private fun persistAgendaItems() {
        if (!::appPreferencesStore.isInitialized || !preferencesSeeded) return
        lifecycleScope.launch {
            val account = currentAccountUser?.account.orEmpty()
            val scopedItems = agendaItems.map { it.copy(ownerAccount = account) }
            allStoredAgendaItems = allStoredAgendaItems
                .filterNot { it.ownerAccount == account || (it.ownerAccount.isBlank() && account.isBlank()) } + scopedItems
            appPreferencesStore.saveAgendaItems(allStoredAgendaItems)
        }
    }

    private fun appendInboxMessage(
        type: String,
        title: String,
        summary: String,
        status: String = "未读"
    ) {
        val message = InboxMessageData(
            id = "${type}-${System.currentTimeMillis()}",
            type = type,
            title = title,
            summary = summary,
            status = status,
            ownerAccount = currentAccountUser?.account.orEmpty()
        )
        inboxMessages = (listOf(message) + inboxMessages).take(60)
        persistInboxMessages()
    }

    private fun persistInboxMessages(immediate: Boolean = false) {
        if (!::appPreferencesStore.isInitialized || !preferencesSeeded) return
        pendingInboxPersistJob?.cancel()
        pendingInboxPersistJob = lifecycleScope.launch {
            if (!immediate) {
                delay(INBOX_PERSIST_DEBOUNCE_MILLIS)
            }
            val account = currentAccountUser?.account.orEmpty()
            val scopedMessages = inboxMessages.map { it.copy(ownerAccount = account) }
            allStoredInboxMessages = allStoredInboxMessages
                .filterNot { it.ownerAccount == account || (it.ownerAccount.isBlank() && account.isBlank()) } + scopedMessages
            appPreferencesStore.saveInboxMessages(allStoredInboxMessages)
        }
    }

    private fun clearInboxMessages() {
        inboxMessages = emptyList()
        persistInboxMessages(immediate = true)
        Toast.makeText(this, "通知中心已清空", Toast.LENGTH_SHORT).show()
    }

    private fun persistAppPreferences() {
        if (!::appPreferencesStore.isInitialized || !preferencesSeeded) return
        lifecycleScope.launch {
            appPreferencesStore.savePreferences(
                reminderLeadMinutes = reminderLeadMinutes,
                reminderDayEnabled = reminderDayEnabled,
                reminderHourEnabled = reminderHourEnabled,
                blockHighRisk = blockHighRisk,
                muteLowConfidence = muteLowConfidence,
                autoMapLink = autoMapLink,
                performanceLiteMode = performanceLiteMode
            )
        }
    }

    private fun updateReminderLeadMinutes(minutes: Int) {
        reminderLeadMinutes = minutes
        rebuildAgendaReminderPolicies()
    }

    private fun updateReminderDayEnabled(enabled: Boolean) {
        reminderDayEnabled = enabled
        rebuildAgendaReminderPolicies()
    }

    private fun updateReminderHourEnabled(enabled: Boolean) {
        reminderHourEnabled = enabled
        rebuildAgendaReminderPolicies()
    }

    private fun updateBlockHighRisk(enabled: Boolean) {
        blockHighRisk = enabled
        persistAppPreferences()
    }

    private fun updateMuteLowConfidence(enabled: Boolean) {
        muteLowConfidence = enabled
        persistAppPreferences()
    }

    private fun updateAutoMapLink(enabled: Boolean) {
        autoMapLink = enabled
        persistAppPreferences()
    }

    private fun updatePerformanceLiteMode(enabled: Boolean) {
        performanceLiteMode = enabled
        persistAppPreferences()
        Toast.makeText(
            this,
            if (enabled) "已开启轻量模式，降低动效负担" else "已恢复完整动效",
            Toast.LENGTH_SHORT
        ).show()
    }

    private fun loadVisibleDataForCurrentAccount() {
        val account = currentAccountUser?.account.orEmpty()
        agendaItems = allStoredAgendaItems
            .filter { it.ownerAccount == account || (it.ownerAccount.isBlank() && account.isBlank()) }
        inboxMessages = allStoredInboxMessages
            .filter { it.ownerAccount == account || (it.ownerAccount.isBlank() && account.isBlank()) }
        pendingExecutionSnapshot = PendingExecutionSnapshot()
        syncPendingExecutionUi(showCard = false)
        showReviewScreen = false
        showVoiceFallbackInput = false
        showLiveCameraScreen = false
        showErrorOverlay = false
        pendingNavigationAgenda = null
        importedText = ""
        importedSourceLabel = ""
        importedImageUriText = ""
        voiceFallbackDraft = ""
        commandText = ""
        statusText = ""
        resultText = ""
        refreshReminderState()
    }

    private fun rebuildAgendaReminderPolicies() {
        val previousItems = agendaItems
        val reminders = currentReminderSet()
        agendaItems = agendaItems.map { item ->
            item.copy(reminders = reminders)
        }
        if (::reminderScheduler.isInitialized) {
            previousItems.forEach { item ->
                if (item.isConfirmedStatus()) {
                    reminderScheduler.cancelAgendaReminders(item.id, item.reminders)
                }
            }
            agendaItems.forEach { item ->
                if (item.isConfirmedStatus()) {
                    reminderScheduler.scheduleAgendaReminders(item)
                }
            }
        }
        persistAgendaItems()
        persistAppPreferences()
        refreshReminderState()
    }

    private fun onRetryRequested() {
        val recoveryAction = currentRecoveryAction
        clearErrorState()
        when (recoveryAction) {
            RecoveryAction.REQUEST_PERMISSIONS -> requestPermissions(
                requestCamera = !cameraPermissionGranted,
                requestAudio = !audioPermissionGranted,
                requestImages = !hasImageAccessPermission()
            )

            RecoveryAction.RETRY_CAPTURE -> onCaptureButtonClicked()
            RecoveryAction.RETRY_VOICE -> startVoiceCapture()
            RecoveryAction.RETRY_IMPORT -> lastNoticeInput?.let(::processNoticeInput)
            RecoveryAction.NONE -> Unit
        }
    }

    private fun handleError(
        throwable: Throwable,
        recoveryAction: RecoveryAction
    ) {
        showError(
            message = resolveErrorMessage(throwable),
            recoveryAction = recoveryAction
        )
    }

    private fun showError(
        message: String,
        recoveryAction: RecoveryAction
    ) {
        statusText = message
        lastError = message
        currentRecoveryAction = recoveryAction
        showErrorOverlay = true
        appendInboxMessage(
            type = "error",
            title = "处理失败",
            summary = message,
            status = "待处理"
        )
    }

    private fun clearErrorState() {
        lastError = ""
        currentRecoveryAction = RecoveryAction.NONE
        showErrorOverlay = false
    }

    private fun resolveErrorMessage(throwable: Throwable): String {
        return when (throwable) {
            is VLMNetworkException -> getString(R.string.network_error)
            is VLMApiException -> mapApiErrorMessage(throwable)
            is VLMResponseParseException -> getString(R.string.parse_error)
            is FileNotFoundException -> getString(R.string.image_import_failed)
            is ActivityNotFoundException -> mapActivityNotFoundMessage(throwable)
            is ImageCaptureException -> getString(R.string.camera_capture_failed)
            is VivoAsrException -> mapVivoAsrMessage(throwable)
            is VoiceRecognitionException -> mapVoiceRecognitionMessage(throwable)
            is IllegalStateException -> mapIllegalStateMessage(throwable)
            is IllegalArgumentException -> mapIllegalArgumentMessage(throwable)
            else -> throwable.message ?: getString(R.string.error_occurred)
        }
    }

    private fun mapApiErrorMessage(throwable: VLMApiException): String {
        val responseBody = throwable.responseBody.lowercase()
        return when {
            throwable.code == 429 || responseBody.contains("rate limit") || responseBody.contains("429") -> {
                getString(R.string.model_rate_limited)
            }

            responseBody.contains("no model access permission") || responseBody.contains("permission expires") -> {
                getString(R.string.model_permission_denied)
            }

            responseBody.contains("today usage limit") -> {
                getString(R.string.model_daily_quota_exceeded)
            }

            else -> getString(R.string.model_error)
        }
    }

    private fun mapIllegalArgumentMessage(throwable: IllegalArgumentException): String {
        val message = throwable.message.orEmpty()
        return when {
            message.contains("Missing location", ignoreCase = true) -> getString(R.string.location_missing)
            else -> message.ifBlank { getString(R.string.error_occurred) }
        }
    }

    private fun mapVoiceRecognitionMessage(throwable: VoiceRecognitionException): String {
        val message = throwable.message.orEmpty()
        val errorCode = throwable.errorCode ?: message.substringAfterLast(": ", "").toIntOrNull()
        return when {
            message.contains("unavailable", ignoreCase = true) -> getString(R.string.voice_not_supported)
            message.contains("no speech recognized", ignoreCase = true) -> getString(R.string.voice_capture_failed)
            errorCode == VoiceRecognitionManager.ERROR_RECOGNIZER_BUSY -> getString(R.string.voice_busy)
            errorCode == VoiceRecognitionManager.ERROR_AUDIO ||
                errorCode == VoiceRecognitionManager.ERROR_SERVER ||
                errorCode == VoiceRecognitionManager.ERROR_NETWORK ||
                errorCode == VoiceRecognitionManager.ERROR_NETWORK_TIMEOUT -> getString(R.string.voice_service_error)

            errorCode == VoiceRecognitionManager.ERROR_NO_MATCH ||
                errorCode == VoiceRecognitionManager.ERROR_SPEECH_TIMEOUT -> getString(R.string.voice_capture_failed)

            else -> getString(R.string.voice_capture_failed)
        }
    }

    private fun mapVivoAsrMessage(throwable: VivoAsrException): String {
        val message = throwable.message.orEmpty()
        return when {
            message.contains("Microphone permission is missing", ignoreCase = true) ->
                getString(R.string.microphone_permission_missing)

            message.contains("No speech text returned", ignoreCase = true) ||
                message.contains("no speech", ignoreCase = true) ->
                getString(R.string.voice_capture_failed)

            message.contains("AudioRecord initialization failed", ignoreCase = true) ||
                message.contains("min buffer size is invalid", ignoreCase = true) ->
                getString(R.string.voice_not_supported)

            message.contains("timeout", ignoreCase = true) ||
                message.contains("failed", ignoreCase = true) ||
                message.contains("error", ignoreCase = true) ->
                getString(R.string.voice_service_error)

            else -> getString(R.string.voice_service_error)
        }
    }

    private fun mapIllegalStateMessage(throwable: IllegalStateException): String {
        val message = throwable.message.orEmpty()
        return when {
            message.contains("Camera is not ready", ignoreCase = true) -> getString(R.string.camera_not_ready)
            message.contains("No available camera can be found", ignoreCase = true) ->
                getString(R.string.camera_preview_unavailable_mock_hint)

            message.contains("Voice recognition unavailable", ignoreCase = true) -> getString(R.string.voice_not_supported)
            message.contains("No speech recognized", ignoreCase = true) -> getString(R.string.voice_capture_failed)
            message.contains("Missing location", ignoreCase = true) -> getString(R.string.location_missing)
            else -> message.ifBlank { getString(R.string.error_occurred) }
        }
    }

    private fun mapActivityNotFoundMessage(throwable: ActivityNotFoundException): String {
        val message = throwable.message.orEmpty()
        return when {
            message.contains("Calendar", ignoreCase = true) -> getString(R.string.calendar_app_missing)
            message.contains("Map", ignoreCase = true) -> getString(R.string.map_app_missing)
            else -> getString(R.string.error_occurred)
        }
    }

    private fun getRetryButtonText(): String {
        return when (currentRecoveryAction) {
            RecoveryAction.REQUEST_PERMISSIONS -> getString(R.string.retry_permission)
            RecoveryAction.RETRY_CAPTURE,
            RecoveryAction.RETRY_VOICE,
            RecoveryAction.RETRY_IMPORT -> getString(R.string.retry)

            RecoveryAction.NONE -> getString(R.string.retry)
        }
    }

    private fun refreshPermissionState() {
        cameraPermissionGranted = hasPermission(Manifest.permission.CAMERA)
        audioPermissionGranted = hasPermission(Manifest.permission.RECORD_AUDIO)
        notificationPermissionGranted = hasNotificationPermission()
    }

    private fun markAppEntered() {
        runtimePrefs.edit().putBoolean(KEY_HAS_ENTERED_APP, true).apply()
    }

    private fun shouldShowStartupIntro(intent: Intent?): Boolean {
        return currentAccountUser == null && !isShareIntent(intent)
    }

    private fun loginAccount(account: String, password: String) {
        if (loginSubmitting) return
        loginSubmitting = true
        loginMessage = ""
        lifecycleScope.launch {
            val result = withContext(Dispatchers.IO) {
                accountRepository.login(account, password)
            }
            loginSubmitting = false
            loginMessage = result.message
            result.user?.let { user -> enterAppWithUser(user) }
        }
    }

    private fun registerAccount(account: String, password: String, nickname: String) {
        if (loginSubmitting) return
        loginSubmitting = true
        loginMessage = ""
        lifecycleScope.launch {
            val result = withContext(Dispatchers.IO) {
                accountRepository.register(account, password, nickname)
            }
            loginSubmitting = false
            loginMessage = result.message
            result.user?.let { user -> enterAppWithUser(user) }
        }
    }

    private fun enterAppWithUser(user: AccountUser) {
        currentAccountUser = user
        accountSessionStore.saveCurrentUser(user)
        markAppEntered()
        loadVisibleDataForCurrentAccount()
        refreshReminderState()
        initializeAppIfNeeded()
        showStartupIntro = false
    }

    private fun logoutAccount() {
        accountSessionStore.clear()
        currentAccountUser = null
        loadVisibleDataForCurrentAccount()
        loginMessage = "已退出登录"
        showStartupIntro = true
        appInitialized = false
        CameraManager.unbindPreview()
    }

    private fun updateAccountProfile(
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
    ) {
        val userId = currentAccountUser?.id ?: return
        lifecycleScope.launch {
            val updatedUser = withContext(Dispatchers.IO) {
                accountRepository.updateProfile(
                    userId = userId,
                    nicknameInput = nickname,
                    avatarUriInput = avatarUri,
                    signatureInput = signature,
                    birthdayInput = birthday,
                    schoolInput = school,
                    ageInput = age,
                    genderInput = gender,
                    majorInput = major,
                    gradeInput = grade,
                    hometownInput = hometown
                )
            }
            updatedUser?.let {
                currentAccountUser = it
                accountSessionStore.saveCurrentUser(it)
                Toast.makeText(this@MainActivity, "个人资料已更新", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun onPickProfileAvatar() {
        pickAvatarLauncher.launch("image/*")
    }

    private fun onCaptureProfileAvatar() {
        if (!cameraPermissionGranted) {
            requestPermissions(requestCamera = true, requestAudio = false, requestImages = false)
            Toast.makeText(this, "请授权相机后再次点击拍照更换头像", Toast.LENGTH_SHORT).show()
            return
        }
        val output = createProfileCameraFile()
        val uri = FileProvider.getUriForFile(
            this,
            "${BuildConfig.APPLICATION_ID}.fileprovider",
            output
        )
        pendingProfileCameraUri = uri
        takeAvatarLauncher.launch(uri)
    }

    private fun saveProfileAvatarFromUri(uri: Uri) {
        val user = currentAccountUser ?: return
        lifecycleScope.launch {
            val savedPath = withContext(Dispatchers.IO) {
                copyProfileAvatar(uri, user.id)
            }
            if (savedPath.isBlank()) {
                Toast.makeText(this@MainActivity, "头像保存失败，请换一张图片重试", Toast.LENGTH_SHORT).show()
                return@launch
            }
            updateAccountProfile(
                nickname = user.nickname,
                avatarUri = savedPath,
                signature = user.signature,
                birthday = user.birthday,
                school = user.school,
                age = user.age,
                gender = user.gender,
                major = user.major,
                grade = user.grade,
                hometown = user.hometown
            )
        }
    }

    private fun copyProfileAvatar(sourceUri: Uri, userId: Long): String {
        return runCatching {
            val targetDir = File(filesDir, "profile").apply { mkdirs() }
            val target = File(targetDir, "avatar_${userId}_${System.currentTimeMillis()}.jpg")
            contentResolver.openInputStream(sourceUri)?.use { input ->
                FileOutputStream(target).use { output ->
                    input.copyTo(output)
                }
            } ?: return ""
            target.absolutePath
        }.getOrElse {
            Timber.e(it, "Failed to copy profile avatar")
            ""
        }
    }


    private fun createProfileCameraFile(): File {
        val targetDir = File(cacheDir, "profile_camera").apply { mkdirs() }
        return File(targetDir, "avatar_capture_${System.currentTimeMillis()}.jpg")
    }

    private fun hasCaptureAccess(): Boolean {
        return cameraPermissionGranted
    }

    private fun hasPermission(permission: String): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            permission
        ) == android.content.pm.PackageManager.PERMISSION_GRANTED
    }

    private fun hasNotificationPermission(): Boolean {
        return Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU ||
            hasPermission(Manifest.permission.POST_NOTIFICATIONS)
    }

    private fun hasImageAccessPermission(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            hasPermission(Manifest.permission.READ_MEDIA_IMAGES)
        } else {
            hasPermission(Manifest.permission.READ_EXTERNAL_STORAGE)
        }
    }

    private fun resolveLaunchTab(intent: Intent?): String {
        return when (intent?.getStringExtra("open_tab")) {
            "plan", "profile", "home" -> intent.getStringExtra("open_tab").orEmpty()
            else -> "home"
        }.ifBlank { "home" }
    }

    private fun requestTabNavigation(tabId: String) {
        launchTab = tabId
        tabNavigationNonce++
    }

    private fun isShareIntent(intent: Intent?): Boolean {
        return intent?.action == Intent.ACTION_SEND
    }
}

@OptIn(ExperimentalComposeUiApi::class)
@Composable
fun MainScreen(
    currentAccountUser: AccountUser?,
    commandText: String,
    onCommandChanged: (String) -> Unit,
    onSubmitCommand: () -> Unit,
    onCapture: () -> Unit,
    onVoicePressStart: () -> Unit,
    onVoicePressEnd: () -> Unit,
    onVoicePressCancel: () -> Unit,
    onPasteText: () -> Unit,
    onPreset: (PromptPreset) -> Unit,
    onConfirmExecution: () -> Unit,
    onCancelExecution: () -> Unit,
    bindPreview: (PreviewView) -> Unit,
    presets: List<PromptPreset>,
    showLivePreview: Boolean,
    isLoading: Boolean,
    isVoiceListening: Boolean,
    isVoiceRecordingActive: Boolean,
    voiceRecordingMillis: Long,
    isCameraAvailable: Boolean,
    loadingStage: Int,
    statusText: String,
    resultText: String,
    reviewSourcePreview: String,
    importedSourceLabel: String,
    confirmationIntent: ExecutableIntent?,
    confirmationSuggestion: ExecutionSuggestion?,
    showConfirmationCard: Boolean,
    agendaItems: List<AgendaCardData>,
    selectedPlanMode: String,
    selectedPlanDate: LocalDate?,
    calendarPreviewMonth: YearMonth,
    reminderPolicyLabel: String,
    reminderStateText: String,
    nextReminderText: String,
    reminderLeadMinutes: Int,
    reminderDayEnabled: Boolean,
    reminderHourEnabled: Boolean,
    blockHighRisk: Boolean,
    muteLowConfidence: Boolean,
    autoMapLink: Boolean,
    performanceLiteMode: Boolean,
    runtimeStatus: AgentRuntimeStatusData,
    exportFormats: List<String>,
    showErrorOverlay: Boolean,
    errorText: String,
    showRetry: Boolean,
    retryText: String,
    initialTab: String,
    tabNavigationNonce: Int,
    onReminderLeadMinutesChange: (Int) -> Unit,
    onReminderDayEnabledChange: (Boolean) -> Unit,
    onReminderHourEnabledChange: (Boolean) -> Unit,
    onBlockHighRiskChange: (Boolean) -> Unit,
    onMuteLowConfidenceChange: (Boolean) -> Unit,
    onAutoMapLinkChange: (Boolean) -> Unit,
    onPerformanceLiteModeChange: (Boolean) -> Unit,
    onReparseHistoryItem: (AgendaCardData) -> Unit,
    onUpdateAgendaItem: (AgendaCardData) -> Unit,
    onDeleteAgendaItem: (AgendaCardData) -> Unit,
    onDuplicateAgendaItem: (AgendaCardData) -> Unit,
    onNavigateAgendaItem: (AgendaCardData) -> Unit,
    pendingNavigationAgenda: AgendaCardData?,
    onDismissNavigationChoice: () -> Unit,
    onChooseNavigationProvider: (AgendaCardData, String) -> Unit,
    showVoiceFallbackInput: Boolean,
    voiceFallbackDraft: String,
    onVoiceFallbackDraftChange: (String) -> Unit,
    onDismissVoiceFallback: () -> Unit,
    onConfirmVoiceFallback: () -> Unit,
    onOpenReview: () -> Unit,
    onReviewDraftChanged: (title: String, time: String, location: String, description: String) -> Unit,
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
    inboxMessages: List<InboxMessageData>,
    onClearInboxMessages: () -> Unit,
    onLogout: () -> Unit,
    onRetry: () -> Unit,
    onDismissError: () -> Unit,
    onCancelLoading: (() -> Unit)? = null
) {
    val surfaceColor = if (showLivePreview) {
        com.vsa.visualsemanticagent.ui.AppColors.Background
    } else {
        Color(0xFFEEF4FF)
    }
    val tabs = androidx.compose.runtime.remember {
        listOf(
            MainTabItem("home",    "首页",   Icons.Rounded.Home),
            MainTabItem("plan",    "时间线", Icons.Rounded.Schedule),
            MainTabItem("profile", "我的",   Icons.Rounded.Person)
        )
    }
    val selectedTabState = rememberSaveable(initialTab, tabNavigationNonce) {
        mutableStateOf(initialTab)
    }
    val showTimelineTransferState = rememberSaveable { mutableStateOf(false) }
    val selectedTab = selectedTabState.value
    val showTimelineTransfer = showTimelineTransferState.value
    val scope = rememberCoroutineScope()
    val confirmedAgendaItems = androidx.compose.runtime.remember(agendaItems) {
        agendaItems.filter { it.isConfirmedStatus() }
    }
    val resolvedConfirmedAgendaCount = confirmedAgendaItems.size
    val resolvedPendingAgendaCount = androidx.compose.runtime.remember(agendaItems) {
        agendaItems.count { it.isPendingStatus() }
    }
    val resolvedTodayAgendaCount = androidx.compose.runtime.remember(confirmedAgendaItems) {
        confirmedAgendaItems.count { it.scheduleDate() == LocalDate.now() }
    }
    val resolvedScheduledReminderCount = androidx.compose.runtime.remember(confirmedAgendaItems) {
        countAgendasWithUpcomingReminders(confirmedAgendaItems)
    }
    val activeConflicts = androidx.compose.runtime.remember(confirmationIntent, agendaItems) {
        confirmationIntent?.let { detectScheduleConflicts(it, agendaItems) }.orEmpty()
    }

    LaunchedEffect(initialTab, tabNavigationNonce) {
        selectedTabState.value = initialTab
    }

    LaunchedEffect(selectedTab, showLivePreview, isCameraAvailable) {
        if (selectedTab != "home" || !isCameraAvailable) {
            CameraManager.unbindPreview()
        }
    }

    BackHandler(enabled = selectedTab != "home") {
        selectedTabState.value = "home"
    }

    val confirmWithTimelineTransfer: () -> Unit = {
        scope.launch {
            showTimelineTransferState.value = true
            onConfirmExecution()
            delay(420)
            selectedTabState.value = "plan"
            delay(360)
            showTimelineTransferState.value = false
        }
    }

    Surface(
        modifier = Modifier.fillMaxSize(),
        color = surfaceColor
    ) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .semantics { testTagsAsResourceId = true }
                .testTag("main-root")
        ) {
            Scaffold(
                modifier = Modifier.fillMaxSize(),
                containerColor = surfaceColor,
                bottomBar = {
                    NavigationBar(
                        containerColor = com.vsa.visualsemanticagent.ui.AppColors.SurfaceContainerLowest,
                        contentColor   = com.vsa.visualsemanticagent.ui.AppColors.Primary
                    ) {
                        tabs.forEach { tab ->
                        NavigationBarItem(
                            selected = selectedTab == tab.id,
                            onClick = { selectedTabState.value = tab.id },
                            modifier = Modifier.testTag("tab-${tab.id}"),
                            colors = NavigationBarItemDefaults.colors(
                                selectedIconColor   = com.vsa.visualsemanticagent.ui.AppColors.Primary,
                                selectedTextColor   = com.vsa.visualsemanticagent.ui.AppColors.Primary,
                                indicatorColor      = com.vsa.visualsemanticagent.ui.AppColors.PrimaryFixed.copy(alpha = 0.60f),
                                unselectedIconColor = com.vsa.visualsemanticagent.ui.AppColors.OnSurfaceVariant,
                                unselectedTextColor = com.vsa.visualsemanticagent.ui.AppColors.OnSurfaceVariant
                            ),
                            icon = {
                                Icon(
                                    imageVector = tab.icon,
                                        contentDescription = tab.label
                                    )
                                },
                                label = { Text(tab.label) }
                            )
                        }
                    }
                }
            ) { innerPadding ->
                val pageModifier = Modifier
                    .fillMaxSize()
                    .padding(bottom = innerPadding.calculateBottomPadding())

                Box(modifier = pageModifier) {
                    when (selectedTab) {
                        "home" -> HomeScreenModule(
                            modifier = Modifier.fillMaxSize(),
                            commandText = commandText,
                            onCommandChanged = onCommandChanged,
                            onSubmitCommandClick = onSubmitCommand,
                            onCaptureClick = onCapture,
                            onVoicePressStart = onVoicePressStart,
                            onVoicePressEnd = onVoicePressEnd,
                            onVoicePressCancel = onVoicePressCancel,
                            onPasteTextClick = onPasteText,
                            onPresetClick = onPreset,
                            onConfirmExecution = confirmWithTimelineTransfer,
                            onCancelExecution = onCancelExecution,
                            confirmationIntent = confirmationIntent,
                            confirmationSuggestion = confirmationSuggestion,
                            showConfirmationCard = showConfirmationCard,
                            bindPreview = bindPreview,
                            presets = presets,
                            showLivePreview = showLivePreview,
                            isLoading = isLoading,
                            isVoiceListening = isVoiceListening,
                            isVoiceRecordingActive = isVoiceRecordingActive,
                            voiceRecordingMillis = voiceRecordingMillis,
                            isCameraAvailable = isCameraAvailable,
                            statusText = statusText,
                            resultText = resultText,
                            importedSourceLabel = importedSourceLabel,
                            conflictCount = activeConflicts.size,
                            agendaItems = agendaItems,
                            nextReminderText = nextReminderText,
                            todayAgendaCount = resolvedTodayAgendaCount,
                            userNickname = currentAccountUser?.nickname ?: "织时用户",
                            userAccount = currentAccountUser?.account ?: "",
                            userAvatarUri = currentAccountUser?.avatarUri.orEmpty(),
                            scheduledReminderCount = resolvedScheduledReminderCount,
                            onOpenTimeline = { selectedTabState.value = "plan" },
                            onOpenProfile = { selectedTabState.value = "profile" },
                            onOpenReview = onOpenReview,
                            onOpenRecentResults = {
                                if (showConfirmationCard) {
                                    onOpenReview()
                                } else {
                                    selectedTabState.value = "profile"
                                }
                            }
                        )

                        "plan" -> TimelineScreenModule(
                            modifier = Modifier.fillMaxSize(),
                            confirmationIntent = confirmationIntent,
                            confirmationSuggestion = confirmationSuggestion,
                            showConfirmationCard = showConfirmationCard,
                            agendaItems = agendaItems,
                            selectedPlanMode = selectedPlanMode,
                            selectedPlanDate = selectedPlanDate,
                            calendarPreviewMonth = calendarPreviewMonth,
                            nextReminderText = nextReminderText,
                            scheduledReminderCount = resolvedScheduledReminderCount,
                            confirmedAgendaCount = resolvedConfirmedAgendaCount,
                            onConfirmExecution = confirmWithTimelineTransfer,
                            onCancelExecution = onCancelExecution,
                            onGoHome = { selectedTabState.value = "home" },
                            onUpdateAgendaItem = onUpdateAgendaItem,
                            onDeleteAgendaItem = onDeleteAgendaItem,
                            onDuplicateAgendaItem = onDuplicateAgendaItem,
                            onNavigateAgendaItem = onNavigateAgendaItem
                        )

                        else -> ProfileScreenModule(
                            modifier = Modifier.fillMaxSize(),
                            userNickname = currentAccountUser?.nickname ?: "织时用户",
                            userAccount = currentAccountUser?.account ?: "未登录",
                            userAvatarUri = currentAccountUser?.avatarUri.orEmpty(),
                            userSignature = currentAccountUser?.signature.orEmpty(),
                            userBirthday = currentAccountUser?.birthday.orEmpty(),
                            userSchool = currentAccountUser?.school.orEmpty(),
                            userAge = currentAccountUser?.age.orEmpty(),
                            userGender = currentAccountUser?.gender.orEmpty(),
                            userMajor = currentAccountUser?.major.orEmpty(),
                            userGrade = currentAccountUser?.grade.orEmpty(),
                            userHometown = currentAccountUser?.hometown.orEmpty(),
                            scheduledReminderCount = resolvedScheduledReminderCount,
                            confirmedAgendaCount = resolvedConfirmedAgendaCount,
                            pendingAgendaCount = resolvedPendingAgendaCount,
                            todayAgendaCount = resolvedTodayAgendaCount,
                            agendaItems = agendaItems,
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
                                reminderCount = resolvedScheduledReminderCount
                            ),
                            onReminderLeadMinutesChange = onReminderLeadMinutesChange,
                            onReminderDayEnabledChange = onReminderDayEnabledChange,
                            onReminderHourEnabledChange = onReminderHourEnabledChange,
                            onBlockHighRiskChange = onBlockHighRiskChange,
                            onMuteLowConfidenceChange = onMuteLowConfidenceChange,
                            onAutoMapLinkChange = onAutoMapLinkChange,
                            onPerformanceLiteModeChange = onPerformanceLiteModeChange,
                            onProfileSave = onProfileSave,
                            onPickProfileAvatar = onPickProfileAvatar,
                            onCaptureProfileAvatar = onCaptureProfileAvatar,
                            inboxMessages = inboxMessages,
                            onClearInboxMessages = onClearInboxMessages,
                            onOpenPlan = { selectedTabState.value = "plan" },
                            onReparseHistoryItem = onReparseHistoryItem,
                            onLogout = onLogout
                        )
                    }
                }
            }

            LoadingOverlay(
                isVisible    = isLoading,
                currentStage = loadingStage,
                performanceLiteMode = performanceLiteMode,
                onCancel     = onCancelLoading
            )

            ErrorOverlay(
                isVisible = showErrorOverlay,
                errorMessage = errorText,
                showRetry = showRetry,
                retryText = retryText,
                onRetry = onRetry,
                onDismiss = onDismissError
            )

            TimelineTransferOverlay(
                isVisible = showTimelineTransfer
            )

            pendingNavigationAgenda?.let { item ->
                AlertDialog(
                    onDismissRequest = onDismissNavigationChoice,
                    title = { Text("选择导航软件") },
                    text = { Text("将打开地图前往：${item.location}") },
                    confirmButton = {
                        TextButton(onClick = {
                            onChooseNavigationProvider(item, "amap")
                        }) { Text("高德地图") }
                    },
                    dismissButton = {
                        Row {
                            TextButton(onClick = {
                                onChooseNavigationProvider(item, "baidu")
                            }) { Text("百度地图") }
                            TextButton(onClick = {
                                onChooseNavigationProvider(item, "tencent")
                            }) { Text("腾讯地图") }
                        }
                    }
                )
            }

            if (showVoiceFallbackInput) {
                AlertDialog(
                    onDismissRequest = onDismissVoiceFallback,
                    title = { Text("语音转文字") },
                    text = {
                        OutlinedTextField(
                            value = voiceFallbackDraft,
                            onValueChange = onVoiceFallbackDraftChange,
                            placeholder = { Text("如果系统没有直接识别成功，请把语音内容转写到这里。点击开始解析后会继续发送给大模型。") },
                            minLines = 3,
                            colors = OutlinedTextFieldDefaults.colors(),
                            modifier = Modifier.testTag("voice-fallback-field")
                        )
                    },
                    confirmButton = {
                        TextButton(
                            onClick = onConfirmVoiceFallback,
                            modifier = Modifier.testTag("voice-fallback-confirm")
                        ) { Text("开始解析") }
                    },
                    dismissButton = {
                        TextButton(
                            onClick = onDismissVoiceFallback,
                            modifier = Modifier.testTag("voice-fallback-cancel")
                        ) { Text("鍙栨秷") }
                    }
                )
            }
        }
    }
}

private data class MainTabItem(
    val id: String,
    val label: String,
    val icon: androidx.compose.ui.graphics.vector.ImageVector
)

