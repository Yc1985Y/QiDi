package com.vsa.visualsemanticagent

import android.content.ClipboardManager
import android.content.Context
import androidx.activity.ComponentActivity
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollToNode
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.test.performTouchInput
import androidx.compose.ui.test.click
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.onAllNodesWithText
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.vsa.visualsemanticagent.account.AccountRepository
import com.vsa.visualsemanticagent.account.AccountSessionStore
import com.vsa.visualsemanticagent.decision.ExecutableIntent
import com.vsa.visualsemanticagent.decision.ExecutablePayload
import com.vsa.visualsemanticagent.decision.ExecutionMode
import com.vsa.visualsemanticagent.decision.ExecutionSuggestion
import com.vsa.visualsemanticagent.decision.IntentRiskLevel
import com.vsa.visualsemanticagent.decision.ValidationResult
import com.vsa.visualsemanticagent.decision.detectScheduleConflicts
import com.vsa.visualsemanticagent.notification.InboxMessageData
import com.vsa.visualsemanticagent.plan.AgendaCardData
import com.vsa.visualsemanticagent.ui.LoginScreen
import com.vsa.visualsemanticagent.ui.home.HomeScreenModule
import com.vsa.visualsemanticagent.ui.profile.AgentRuntimeStatusData
import com.vsa.visualsemanticagent.ui.profile.ProfileScreenModule
import com.vsa.visualsemanticagent.ui.review.ReviewScreenModule
import com.vsa.visualsemanticagent.ui.timeline.TimelineScreenModule
import com.vsa.visualsemanticagent.utils.PromptPreset
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.time.LocalDate
import java.time.YearMonth

@RunWith(AndroidJUnit4::class)
class HomeScreenInteractionTests {

    @get:Rule
    val composeRule = createAndroidComposeRule<ComponentActivity>()

    @Test
    fun greeting_usesCurrentUserInsteadOfPlaceholder() {
        composeRule.setContent {
            HomeScreenModule(
                commandText = "",
                onCommandChanged = {},
                onSubmitCommandClick = {},
                onCaptureClick = {},
                onVoicePressStart = {},
                onVoicePressEnd = {},
                onVoicePressCancel = {},
                onPickImageClick = {},
                onPasteTextClick = {},
                onPresetClick = {},
                onConfirmExecution = {},
                onCancelExecution = {},
                confirmationIntent = null,
                confirmationSuggestion = null,
                showConfirmationCard = false,
                bindPreview = {},
                presets = emptyList(),
                showLivePreview = false,
                isCameraAvailable = false,
                userNickname = "缁囨椂璇勫",
                userAccount = "1985",
                scheduledReminderCount = 2
            )
        }

        composeRule.onNodeWithText("Hi, 缁囨椂璇勫").assertIsDisplayed()
        composeRule.onNodeWithText("宸茶鎻愰啋").assertIsDisplayed()
    }

    @Test
    fun pendingReviewCard_opensReviewCallback() {
        var opened = false
        composeRule.setContent {
            HomeScreenModule(
                commandText = "",
                onCommandChanged = {},
                onSubmitCommandClick = {},
                onCaptureClick = {},
                onVoicePressStart = {},
                onVoicePressEnd = {},
                onVoicePressCancel = {},
                onPickImageClick = {},
                onPasteTextClick = {},
                onPresetClick = {},
                onConfirmExecution = {},
                onCancelExecution = {},
                confirmationIntent = sampleIntent(),
                confirmationSuggestion = sampleSuggestion(),
                showConfirmationCard = true,
                conflictCount = 1,
                bindPreview = {},
                presets = emptyList(),
                showLivePreview = false,
                isCameraAvailable = false,
                onOpenReview = { opened = true }
            )
        }

        composeRule.onNodeWithTag("home-main-list")
            .performScrollToNode(hasTestTag("home-open-review"))
        composeRule.onNodeWithText("鏈?1 鏉＄浉杩戞椂闂村畨鎺?).assertIsDisplayed()
        composeRule.onNodeWithTag("home-open-review").performClick()
        composeRule.runOnIdle {
            assertTrue(opened)
        }
    }

    @Test
    fun scheduleConflictDetector_findsNearbyAgenda() {
        val conflicts = detectScheduleConflicts(
            intent = sampleIntent(),
            agendaItems = sampleAgendaItems()
        )

        assertTrue(conflicts.isNotEmpty())
        assertEquals("浜哄伐鏅鸿兘鍓嶆部璁插骇", conflicts.first().conflictItem.title)
    }

    @Test
    fun voiceToggleButton_showsRecordingStateWhenListening() {
        composeRule.setContent {
            HomeScreenModule(
                commandText = "",
                onCommandChanged = {},
                onSubmitCommandClick = {},
                onCaptureClick = {},
                onVoicePressStart = {},
                onVoicePressEnd = {},
                onVoicePressCancel = {},
                onPickImageClick = {},
                onPasteTextClick = {},
                onPresetClick = {},
                onConfirmExecution = {},
                onCancelExecution = {},
                confirmationIntent = null,
                confirmationSuggestion = null,
                showConfirmationCard = false,
                bindPreview = {},
                presets = emptyList(),
                showLivePreview = false,
                isCameraAvailable = false,
                isVoiceListening = true
            )
        }

        composeRule.onNodeWithTag("home-voice-toggle-button").assertIsDisplayed()
        composeRule.onNodeWithText("0s").assertIsDisplayed()
    }

    @Test
    fun voiceToggleButton_showsElapsedTimeWhileRecording() {
        composeRule.setContent {
            HomeScreenModule(
                commandText = "",
                onCommandChanged = {},
                onSubmitCommandClick = {},
                onCaptureClick = {},
                onVoicePressStart = {},
                onVoicePressEnd = {},
                onVoicePressCancel = {},
                onPickImageClick = {},
                onPasteTextClick = {},
                onPresetClick = {},
                onConfirmExecution = {},
                onCancelExecution = {},
                confirmationIntent = null,
                confirmationSuggestion = null,
                showConfirmationCard = false,
                bindPreview = {},
                presets = emptyList(),
                showLivePreview = false,
                isCameraAvailable = false,
                isVoiceListening = true,
                isVoiceRecordingActive = true,
                voiceRecordingMillis = 2_200L
            )
        }

        composeRule.onNodeWithTag("home-voice-toggle-button").assertIsDisplayed()
        composeRule.onNodeWithText("2s").assertIsDisplayed()
    }
    @Test
    fun homeScreen_hidesScenarioPresetSection() {
        composeRule.setContent {
            HomeScreenModule(
                commandText = "",
                onCommandChanged = {},
                onSubmitCommandClick = {},
                onCaptureClick = {},
                onVoicePressStart = {},
                onVoicePressEnd = {},
                onVoicePressCancel = {},
                onPickImageClick = {},
                onPasteTextClick = {},
                onPresetClick = {},
                onConfirmExecution = {},
                onCancelExecution = {},
                confirmationIntent = null,
                confirmationSuggestion = null,
                showConfirmationCard = false,
                bindPreview = {},
                presets = samplePresets(),
                showLivePreview = false,
                isCameraAvailable = false
            )
        }

        composeRule.waitForIdle()
        assertEquals(
            0,
            composeRule.onAllNodesWithText("甯哥敤鍦烘櫙")
                .fetchSemanticsNodes(atLeastOneRootRequired = false)
                .size
        )
    }
}

@RunWith(AndroidJUnit4::class)
class MainScreenReviewRoutingTests {

    @get:Rule
    val composeRule = createAndroidComposeRule<ComponentActivity>()

    @Test
    fun reviewEntry_usesOuterRouteCallbackInsteadOfRenderingNestedReviewScreen() {
        var openReviewCount = 0

        composeRule.setContent {
            MainScreen(
                currentAccountUser = null,
                commandText = "",
                onCommandChanged = {},
                onSubmitCommand = {},
                onCapture = {},
                onVoicePressStart = {},
                onVoicePressEnd = {},
                onVoicePressCancel = {},
                onPickImage = {},
                onPasteText = {},
                onPreset = {},
                onConfirmExecution = {},
                onCancelExecution = {},
                bindPreview = {},
                presets = emptyList(),
                showLivePreview = false,
                isLoading = false,
                isVoiceListening = false,
                isVoiceRecordingActive = false,
                voiceRecordingMillis = 0L,
                isCameraAvailable = false,
                loadingStage = 0,
                statusText = "",
                resultText = "",
                reviewSourcePreview = "鍘熷閫氱煡",
                importedSourceLabel = "鍒嗕韩鏂囨湰",
                confirmationIntent = sampleIntent(),
                confirmationSuggestion = sampleSuggestion(),
                showConfirmationCard = true,
                agendaItems = sampleAgendaItems(),
                selectedPlanMode = "week",
                selectedPlanDate = LocalDate.of(2026, 5, 16),
                calendarPreviewMonth = YearMonth.of(2026, 5),
                reminderPolicyLabel = "鎻愬墠 15 鍒嗛挓",
                reminderStateText = "鎻愰啋杩愯涓?,
                nextReminderText = "浠婃櫄 19:00 浜哄伐鏅鸿兘鍓嶆部璁插骇",
                reminderLeadMinutes = 15,
                reminderDayEnabled = true,
                reminderHourEnabled = true,
                blockHighRisk = true,
                muteLowConfidence = false,
                autoMapLink = true,
                performanceLiteMode = true,
                runtimeStatus = sampleRuntimeStatus(),
                exportFormats = listOf("PDF", "PNG"),
                showErrorOverlay = false,
                errorText = "",
                showRetry = false,
                retryText = "",
                initialTab = "home",
                tabNavigationNonce = 0,
                onReminderLeadMinutesChange = {},
                onReminderDayEnabledChange = {},
                onReminderHourEnabledChange = {},
                onBlockHighRiskChange = {},
                onMuteLowConfidenceChange = {},
                onAutoMapLinkChange = {},
                onPerformanceLiteModeChange = {},
                onReparseHistoryItem = {},
                onUpdateAgendaItem = {},
                onDeleteAgendaItem = {},
                onDuplicateAgendaItem = {},
                onNavigateAgendaItem = {},
                pendingNavigationAgenda = null,
                onDismissNavigationChoice = {},
                onChooseNavigationProvider = { _, _ -> },
                showVoiceFallbackInput = false,
                voiceFallbackDraft = "",
                onVoiceFallbackDraftChange = {},
                onDismissVoiceFallback = {},
                onConfirmVoiceFallback = {},
                onOpenReview = { openReviewCount += 1 },
                onReviewDraftChanged = { _, _, _, _ -> },
                onProfileSave = { _, _, _, _, _, _, _, _, _, _ -> },
                onPickProfileAvatar = {},
                onCaptureProfileAvatar = {},
                inboxMessages = emptyList(),
                onClearInboxMessages = {},
                onLogout = {},
                onRetry = {},
                onDismissError = {}
            )
        }

        composeRule.onNodeWithTag("home-main-list")
            .performScrollToNode(hasTestTag("home-open-review"))
        composeRule.onNodeWithTag("home-open-review").performClick()
        composeRule.runOnIdle {
            assertEquals(1, openReviewCount)
        }
        assertEquals(
            0,
            composeRule.onAllNodesWithText("瑙ｆ瀽鏍￠獙")
                .fetchSemanticsNodes(atLeastOneRootRequired = false)
                .size
        )
    }
}

@RunWith(AndroidJUnit4::class)
class ReviewScreenInteractionTests {

    @get:Rule
    val composeRule = createAndroidComposeRule<ComponentActivity>()

    @Test
    fun reviewScreen_editsDraftAndConfirms() {
        var savedTitle = ""
        var confirmedTitle = ""

        composeRule.setContent {
            ReviewScreenModule(
                intent = sampleIntent(),
                suggestion = sampleSuggestion(),
                sourceLabel = "鍒嗕韩鏂囨湰",
                sourcePreview = "鏄庡ぉ鏅氫笂涓冪偣鍦ㄥ浘涔﹂鎶ュ憡鍘呬妇琛屼汉宸ユ櫤鑳藉墠娌胯搴с€?,
                conflicts = detectScheduleConflicts(sampleIntent(), sampleAgendaItems()),
                onBack = {},
                onSaveDraft = { title, _, _, _ -> savedTitle = title },
                onConfirmDraft = { title, _, _, _ -> confirmedTitle = title },
                onCancelExecution = {}
            )
        }

        composeRule.onNodeWithText("瑙ｆ瀽鏍￠獙").assertIsDisplayed()
        composeRule.onNodeWithText("鏃堕棿鍐茬獊鎻愰啋").assertIsDisplayed()
        composeRule.onNodeWithText("鍘熷杈撳叆鍥為【").assertIsDisplayed()
        composeRule.onNodeWithTag("review-main-list")
            .performScrollToNode(hasTestTag("review-save"))
        composeRule.onNodeWithTag("review-title-field").performTextInput("Plus")
        composeRule.onNodeWithTag("review-save").performClick()
        composeRule.runOnIdle {
            assertTrue(savedTitle.contains("Plus"))
        }
        composeRule.onNodeWithTag("review-confirm").performClick()
        composeRule.runOnIdle {
            assertTrue(confirmedTitle.contains("Plus"))
        }
    }
}

@RunWith(AndroidJUnit4::class)
class TimelineScreenInteractionTests {

    @get:Rule
    val composeRule = createAndroidComposeRule<ComponentActivity>()

    @Test
    fun calendarEntry_opensCalendarOverviewSecondPage() {
        val sampleDate = LocalDate.of(2026, 5, 14)
        composeRule.setContent {
            TimelineScreenModule(
                confirmationIntent = null,
                confirmationSuggestion = null,
                showConfirmationCard = false,
                agendaItems = listOf(
                    AgendaCardData(
                        id = "agenda-1",
                        title = "浜哄伐鏅鸿兘鍓嶆部璁插骇",
                        summary = "鍥炬枃閫氱煡宸查檷鍣负鏃堕棿绾夸簨浠?,
                        time = "2026-05-14 19:00",
                        location = "鍥句功棣嗘姤鍛婂巺",
                        status = "宸茬‘璁?,
                        isoDateTime = "2026-05-14T19:00:00",
                        sourceLabel = "缇よ亰鎴浘"
                    )
                ),
                selectedPlanMode = "week",
                selectedPlanDate = sampleDate,
                calendarPreviewMonth = YearMonth.of(2026, 5),
                nextReminderText = "浠婃櫄 19:00 浜哄伐鏅鸿兘鍓嶆部璁插骇",
                scheduledReminderCount = 1,
                confirmedAgendaCount = 1,
                onConfirmExecution = {},
                onCancelExecution = {},
                onGoHome = {}
            )
        }

        composeRule.onNodeWithText("缁囩嚎棰勮").assertIsDisplayed()
        composeRule.onNodeWithText("鏃ュ巻鎬昏").assertIsDisplayed()
        composeRule.onNodeWithTag("timeline-calendar-entry").performClick()
        composeRule.onNodeWithText("鏃ュ巻鎬昏").assertIsDisplayed()
        composeRule.onNodeWithText("Day").assertIsDisplayed()
        composeRule.onNodeWithText("Week").assertIsDisplayed()
        composeRule.onNodeWithText("Month").assertIsDisplayed()
        composeRule.onNodeWithTag("timeline-calendar-page")
            .performScrollToNode(hasText("浜哄伐鏅鸿兘鍓嶆部璁插骇"))
        composeRule.onAllNodesWithText("浜哄伐鏅鸿兘鍓嶆部璁插骇")[0].assertIsDisplayed()
        composeRule.onNodeWithText("Month").performClick()
        composeRule.waitForIdle()
        composeRule.onAllNodesWithText("浜哄伐鏅鸿兘鍓嶆部璁插骇")[0].assertIsDisplayed()
        composeRule.onNodeWithTag("timeline-calendar-back").performClick()
        composeRule.waitForIdle()
        composeRule.onNodeWithText("Timeline").assertIsDisplayed()
    }

    @Test
    fun timelineDetail_supportsCopyAction() {
        val sampleDate = LocalDate.of(2026, 5, 16)
        composeRule.setContent {
            TimelineScreenModule(
                confirmationIntent = null,
                confirmationSuggestion = null,
                showConfirmationCard = false,
                agendaItems = sampleAgendaItems(),
                selectedPlanMode = "week",
                selectedPlanDate = sampleDate,
                calendarPreviewMonth = YearMonth.of(2026, 5),
                nextReminderText = "浠婃櫄 19:00 浜哄伐鏅鸿兘鍓嶆部璁插骇",
                scheduledReminderCount = 2,
                confirmedAgendaCount = 2,
                onConfirmExecution = {},
                onCancelExecution = {},
                onGoHome = {}
            )
        }

        composeRule.onNodeWithTag("timeline-main-list")
            .performScrollToNode(hasTestTag("timeline-item-test-lecture"))
        composeRule.onNodeWithTag("timeline-item-test-lecture").performClick()
        composeRule.onNodeWithText("鏃ョ▼鏁呬簨鏉?).assertIsDisplayed()
        composeRule.onNodeWithTag("timeline-detail-scroll")
            .performScrollToNode(hasText("绯荤粺鏃ュ巻鐘舵€?))
        composeRule.onNodeWithText("绯荤粺鏃ュ巻鐘舵€?).assertIsDisplayed()
        composeRule.onNodeWithTag("timeline-detail-scroll")
            .performScrollToNode(hasTestTag("timeline-detail-copy"))
        composeRule.onNodeWithTag("timeline-detail-copy").performClick()

        val clipboard = composeRule.activity.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
        val copied = clipboard.primaryClip?.getItemAt(0)?.coerceToText(composeRule.activity)?.toString().orEmpty()
        assertTrue(copied.contains("浜哄伐鏅鸿兘鍓嶆部璁插骇"))
        assertTrue(copied.contains("鏉ヨ嚜銆婄粐鏃躲€嬬殑鏍″洯鏃ョ▼"))
    }

    @Test
    fun timelineDetail_hidesInternalExplanationPanel() {
        val sampleDate = LocalDate.of(2026, 5, 16)
        composeRule.setContent {
            TimelineScreenModule(
                confirmationIntent = null,
                confirmationSuggestion = null,
                showConfirmationCard = false,
                agendaItems = sampleAgendaItems(),
                selectedPlanMode = "week",
                selectedPlanDate = sampleDate,
                calendarPreviewMonth = YearMonth.of(2026, 5),
                nextReminderText = "浠婃櫄 19:00 浜哄伐鏅鸿兘鍓嶆部璁插骇",
                scheduledReminderCount = 2,
                confirmedAgendaCount = 2,
                onConfirmExecution = {},
                onCancelExecution = {},
                onGoHome = {}
            )
        }

        composeRule.onNodeWithTag("timeline-main-list")
            .performScrollToNode(hasTestTag("timeline-item-test-lecture"))
        composeRule.onNodeWithTag("timeline-item-test-lecture").performClick()
        composeRule.onNodeWithTag("timeline-detail-scroll")
            .performScrollToNode(hasText("绯荤粺鏃ュ巻鐘舵€?))
        composeRule.waitForIdle()
        assertEquals(
            0,
            composeRule.onAllNodesWithText("涓轰粈涔堣繖鏍峰睍绀?)
                .fetchSemanticsNodes(atLeastOneRootRequired = false)
                .size
        )
    }

    @Test
    fun timelineDetail_supportsEditDuplicateDeleteAndNavigateCallbacks() {
        val sampleDate = LocalDate.of(2026, 5, 16)
        var updatedItem: AgendaCardData? = null
        var deletedItem: AgendaCardData? = null
        var duplicatedItem: AgendaCardData? = null
        var navigatedItem: AgendaCardData? = null

        composeRule.setContent {
            TimelineScreenModule(
                confirmationIntent = null,
                confirmationSuggestion = null,
                showConfirmationCard = false,
                agendaItems = sampleAgendaItems(),
                selectedPlanMode = "week",
                selectedPlanDate = sampleDate,
                calendarPreviewMonth = YearMonth.of(2026, 5),
                nextReminderText = "浠婃櫄 19:00 浜哄伐鏅鸿兘鍓嶆部璁插骇",
                scheduledReminderCount = 2,
                confirmedAgendaCount = 2,
                onConfirmExecution = {},
                onCancelExecution = {},
                onGoHome = {},
                onUpdateAgendaItem = { updatedItem = it },
                onDeleteAgendaItem = { deletedItem = it },
                onDuplicateAgendaItem = { duplicatedItem = it },
                onNavigateAgendaItem = { navigatedItem = it }
            )
        }

        composeRule.onNodeWithTag("timeline-main-list")
            .performScrollToNode(hasTestTag("timeline-item-test-lecture"))
        composeRule.onNodeWithTag("timeline-item-test-lecture").performClick()
        composeRule.onNodeWithTag("timeline-detail-scroll")
            .performScrollToNode(hasTestTag("timeline-detail-edit"))
        composeRule.onNodeWithTag("timeline-detail-edit").performClick()
        composeRule.waitForIdle()
        composeRule.onNodeWithTag("timeline-detail-title-field").performTextInput("Plus")
        composeRule.onNodeWithTag("timeline-detail-save").performClick()
        composeRule.runOnIdle {
            assertTrue(updatedItem?.title?.contains("Plus") == true)
        }

        composeRule.onNodeWithTag("timeline-detail-scroll")
            .performScrollToNode(hasTestTag("timeline-detail-duplicate"))
        composeRule.onNodeWithTag("timeline-detail-duplicate").performClick()
        composeRule.onNodeWithTag("timeline-detail-scroll")
            .performScrollToNode(hasTestTag("timeline-detail-navigate"))
        composeRule.onNodeWithTag("timeline-detail-navigate").performClick()
        composeRule.onNodeWithTag("timeline-detail-scroll")
            .performScrollToNode(hasTestTag("timeline-detail-delete"))
        composeRule.onNodeWithTag("timeline-detail-delete").performClick()

        composeRule.runOnIdle {
            assertTrue(duplicatedItem?.title?.contains("浜哄伐鏅鸿兘鍓嶆部璁插骇") == true)
            assertEquals("鍥句功棣嗘姤鍛婂巺", navigatedItem?.location)
            assertTrue(deletedItem?.title?.contains("浜哄伐鏅鸿兘鍓嶆部璁插骇") == true)
        }
    }
}

@RunWith(AndroidJUnit4::class)
class AccountRepositoryIntegrationTests {

    private lateinit var context: Context

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()
        context.deleteDatabase("timeweaver_accounts.db")
        context.getSharedPreferences("timeweaver_account_session", Context.MODE_PRIVATE)
            .edit()
            .clear()
            .commit()
    }

    @After
    fun tearDown() {
        context.deleteDatabase("timeweaver_accounts.db")
    }

    @Test
    fun registerLoginAndSession_arePersistedLocally() {
        val repository = AccountRepository(context)
        val sessionStore = AccountSessionStore(context)

        val testUser = repository.ensureBuiltInTestAccount()
        assertNotNull(testUser)
        val testLoginResult = repository.login(
            AccountRepository.TEST_ACCOUNT,
            AccountRepository.TEST_PASSWORD
        )
        assertTrue(testLoginResult.success)
        assertEquals("1985", testLoginResult.user?.account)

        val registerResult = repository.register(
            accountInput = "student001",
            passwordInput = "Pass123456",
            nicknameInput = "CodexUser"
        )

        assertTrue(registerResult.success)
        assertEquals("CodexUser", registerResult.user?.nickname)
        assertNotNull(repository.findUserById(registerResult.user!!.id))

        sessionStore.saveCurrentUser(registerResult.user!!)
        val loadedSession = sessionStore.loadCurrentUser(repository)
        assertEquals("student001", loadedSession?.account)

        val loginResult = repository.login("student001", "Pass123456")
        assertTrue(loginResult.success)
        assertEquals("CodexUser", loginResult.user?.nickname)
        assertNotEquals(0L, loginResult.user?.lastLoginAt ?: 0L)

        repository.close()
    }

    @Test
    fun register_rejectsWeakCredentials() {
        val repository = AccountRepository(context)

        val shortAccount = repository.register("ab", "Pass123456", "User")
        val shortPassword = repository.register("student002", "123", "User")

        assertTrue(!shortAccount.success)
        assertTrue(shortAccount.message.contains("璐﹀彿"))
        assertTrue(!shortPassword.success)
        assertTrue(shortPassword.message.contains("瀵嗙爜"))

        repository.close()
    }
}

@RunWith(AndroidJUnit4::class)
class LoginScreenInteractionTests {

    @get:Rule
    val composeRule = createAndroidComposeRule<ComponentActivity>()

    @Test
    fun registerMode_submitsNicknameAccountAndPassword() {
        var capturedAccount = ""
        var capturedPassword = ""
        var capturedNickname = ""

        composeRule.setContent {
            LoginScreen(
                isSubmitting = false,
                message = "",
                onLogin = { _, _ -> },
                onRegister = { account, password, nickname ->
                    capturedAccount = account
                    capturedPassword = password
                    capturedNickname = nickname
                }
            )
        }

        composeRule.onNodeWithTag("login-toggle-mode").performClick()
        composeRule.onNodeWithTag("login-nickname").performTextInput("CodexUser")
        composeRule.onNodeWithTag("login-account").performTextInput("student003")
        composeRule.onNodeWithTag("login-password").performTextInput("Pass123456")
        composeRule.onNodeWithTag("login-submit").performClick()

        composeRule.runOnIdle {
            assertEquals("student003", capturedAccount)
            assertEquals("Pass123456", capturedPassword)
            assertEquals("CodexUser", capturedNickname)
        }
    }

    @Test
    fun loginBackgroundDust_acceptsSubtleTapInteraction() {
        composeRule.setContent {
            LoginScreen(
                isSubmitting = false,
                message = "",
                onLogin = { _, _ -> },
                onRegister = { _, _, _ -> }
            )
        }

        composeRule.onNodeWithTag("login-root")
            .performTouchInput { click(Offset(12f, 12f)) }
        composeRule.onNodeWithTag("login-submit").assertIsDisplayed()
    }
}

@RunWith(AndroidJUnit4::class)
class ProfileScreenInteractionTests {

    @get:Rule
    val composeRule = createAndroidComposeRule<ComponentActivity>()

    private var loggedOut = false
    private var reparsedItemTitle = ""
    private var inboxCleared = false
    private var liteModeEnabled = false
    private var planOpenedCount = 0

    @Before
    fun setUp() {
        loggedOut = false
        reparsedItemTitle = ""
        inboxCleared = false
        liteModeEnabled = false
        planOpenedCount = 0
        composeRule.setContent {
            ProfileScreenModule(
                userNickname = "CodexUser",
                userAccount = "student003",
                userAvatarUri = "",
                userSignature = "鎶婃牎鍥鐗囩粐鎴愯嚜宸辩殑鑺傚",
                userBirthday = "2005-05-14",
                userSchool = "缁囨椂澶у",
                userAge = "21",
                userGender = "涓嶅睍绀?,
                userMajor = "浜哄伐鏅鸿兘",
                userGrade = "2024绾?,
                userHometown = "骞夸笢骞垮窞",
                scheduledReminderCount = 2,
                confirmedAgendaCount = 3,
                pendingAgendaCount = 1,
                todayAgendaCount = 1,
                agendaItems = sampleAgendaItems(),
                inboxMessages = sampleInboxMessages(),
                reminderLeadMinutes = 60,
                reminderDayEnabled = true,
                reminderHourEnabled = true,
                blockHighRisk = true,
                muteLowConfidence = false,
                autoMapLink = true,
                performanceLiteMode = liteModeEnabled,
                runtimeStatus = AgentRuntimeStatusData(
                    modelName = "Volc-DeepSeek-V3.2",
                    appIdReady = true,
                    apiKeyReady = true,
                    chatEndpoint = "https://api-ai.vivo.com.cn/v1/chat/completions",
                    ocrEndpoint = "https://api-ai.vivo.com.cn/ocr/general_recognition",
                    dataStoreReady = true,
                    accountReady = true,
                    cameraReady = true,
                    voiceReady = true,
                    agendaCount = sampleAgendaItems().size,
                    inboxCount = sampleInboxMessages().size,
                    reminderCount = 2
                ),
                onReminderLeadMinutesChange = {},
                onReminderDayEnabledChange = {},
                onReminderHourEnabledChange = {},
                onBlockHighRiskChange = {},
                onMuteLowConfidenceChange = {},
                onAutoMapLinkChange = {},
                onPerformanceLiteModeChange = { liteModeEnabled = it },
                onProfileSave = { _, _, _, _, _, _, _, _, _, _ -> },
                onPickProfileAvatar = {},
                onCaptureProfileAvatar = {},
                onOpenPlan = { planOpenedCount += 1 },
                onReparseHistoryItem = { reparsedItemTitle = it.title },
                onClearInboxMessages = { inboxCleared = true },
                onLogout = { loggedOut = true }
            )
        }
    }

    @Test
    fun shortcuts_openAllSecondLevelPages() {
        openShortcutAndReturn("profile-shortcut-agent-center", "鏅鸿兘浣撲腑蹇?)
        openShortcutAndReturn("profile-shortcut-history", "鍘嗗彶璁板綍")
        openShortcutAndReturn("profile-shortcut-preferences", "鎴戠殑鍋忓ソ")
        openShortcutAndReturn("profile-shortcut-notification-inbox", "閫氱煡涓績")
    }

    @Test
    fun agentCenter_openExpandedSecondLevelPages() {
        openAgentCenterTileAndReturn("涓€閿綋妫€", "鏅鸿兘浣撲綋妫€")
        openAgentCenterTileAndReturn("鏃堕棿绾胯祫浜?, "鏃堕棿绾胯祫浜?)
        openAgentCenterTileAndReturn("閫氱煡涓績", "閫氱煡涓績")
        openAgentCenterTileAndReturn("鎴戠殑鎴愬氨", "鎴戠殑鎴愬氨")
        openAgentCenterTileAndReturn("鐢ㄦ埛鐢诲儚", "鐢ㄦ埛鐢诲儚")
        openAgentCenterTileAndReturn("闅愮涓庡畨鍏?, "闅愮涓庡畨鍏?)
        openAgentCenterTileAndReturn("鏁版嵁绌洪棿", "鏁版嵁绌洪棿")
        openAgentCenterTaggedTileAndReturn("profile-agent-runtime-status", "杩愯鐘舵€?)
        openAgentCenterRowAndReturn("瀵煎嚭璁板綍", "瀵煎嚭璁板綍")
        openAgentCenterRowAndReturn("璐﹀彿涓庤缃?, "璁剧疆")
    }

    @Test
    fun runtimeStatus_togglesPerformanceLiteMode() {
        composeRule.onNodeWithTag("profile-shortcut-agent-center").performClick()
        composeRule.onNodeWithText("鏅鸿兘浣撲腑蹇?).assertIsDisplayed()
        composeRule.onNodeWithTag("profile-detail-list")
            .performScrollToNode(hasTestTag("profile-agent-runtime-status"))
        composeRule.onNodeWithTag("profile-agent-runtime-status").performClick()
        composeRule.onNodeWithText("杩愯鐘舵€?).assertIsDisplayed()
        composeRule.onNodeWithText("鐪熷疄鎺ュ叆").assertIsDisplayed()
        composeRule.onNodeWithTag("profile-detail-list")
            .performScrollToNode(hasTestTag("profile-runtime-lite-switch"))
        composeRule.onNodeWithTag("profile-runtime-lite-switch").performClick()

        composeRule.runOnIdle {
            assertTrue(liteModeEnabled)
        }
    }

    @Test
    fun agentCheckup_opensTreatmentPages() {
        composeRule.onNodeWithTag("profile-shortcut-agent-center").performClick()
        composeRule.onNodeWithText("鏅鸿兘浣撲腑蹇?).assertIsDisplayed()
        composeRule.onNodeWithTag("profile-detail-list")
            .performScrollToNode(hasText("鏅鸿兘浣撲竴閿綋妫€"))
        composeRule.onNodeWithText("鏅鸿兘浣撲竴閿綋妫€").performClick()
        composeRule.onNodeWithText("鏅鸿兘浣撲綋妫€").assertIsDisplayed()
        composeRule.onNodeWithText("浣撴娓呭崟").assertIsDisplayed()
        composeRule.onNodeWithTag("profile-detail-list")
            .performScrollToNode(hasText("寰呯‘璁ゆ睜"))
        composeRule.onNodeWithText("寰呯‘璁ゆ睜").performClick()
        composeRule.onNodeWithText("閫氱煡涓績").assertIsDisplayed()
        returnFromAgentCenterChildToDashboard()

        composeRule.onNodeWithTag("profile-shortcut-agent-center").performClick()
        composeRule.onNodeWithText("鏅鸿兘浣撲腑蹇?).assertIsDisplayed()
        composeRule.onNodeWithTag("profile-detail-list")
            .performScrollToNode(hasText("涓€閿綋妫€"))
        composeRule.onNodeWithText("涓€閿綋妫€").performClick()
        composeRule.onNodeWithTag("profile-detail-list")
            .performScrollToNode(hasText("瀹夊叏杈圭晫"))
        composeRule.onNodeWithText("瀹夊叏杈圭晫").performClick()
        composeRule.onNodeWithText("闅愮涓庡畨鍏?).assertIsDisplayed()
    }

    @Test
    fun profileBackgroundDust_acceptsSubtleTapInteraction() {
        composeRule.onNodeWithTag("profile-root")
            .performTouchInput { click(Offset(12f, 12f)) }
        composeRule.onNodeWithText("CodexUser").assertIsDisplayed()
    }

    @Test
    fun settingsLogout_invokesLogoutCallback() {
        composeRule.onNodeWithTag("profile-shortcut-agent-center").performClick()
        composeRule.onNodeWithTag("profile-detail-list")
            .performScrollToNode(hasText("璐﹀彿涓庤缃?))
        composeRule.onNodeWithText("璐﹀彿涓庤缃?).performClick()
        composeRule.onNodeWithText("璁剧疆").assertIsDisplayed()
        composeRule.onNodeWithTag("profile-settings-logout").performClick()

        composeRule.runOnIdle {
            assertTrue(loggedOut)
        }
    }

    @Test
    fun personalInfoCard_opensEditableProfilePage() {
        composeRule.onNodeWithTag("profile-personal-card").performClick()
        composeRule.onNodeWithText("涓汉璧勬枡").assertIsDisplayed()
        composeRule.onNodeWithTag("profile-avatar-preview").performClick()
        composeRule.onNodeWithText("鏇存崲澶村儚").assertIsDisplayed()
        composeRule.onNodeWithText("浠庣浉鍐岄€夋嫨").assertIsDisplayed()
        composeRule.onNodeWithText("鎷嶇収鏇存崲").assertIsDisplayed()
        composeRule.onNodeWithTag("profile-avatar-pick").performClick()
        composeRule.onNodeWithText("涓€х鍚?).assertIsDisplayed()
        composeRule.onNodeWithTag("profile-detail-list")
            .performScrollToNode(hasText("瀛︽牎"))
        composeRule.onNodeWithText("瀛︽牎").assertIsDisplayed()
        composeRule.onNodeWithText("涓撲笟").assertIsDisplayed()
        composeRule.onNodeWithTag("profile-detail-list")
            .performScrollToNode(hasText("鐢熸棩"))
        composeRule.onNodeWithText("鐢熸棩").assertIsDisplayed()
        composeRule.onNodeWithTag("profile-detail-list")
            .performScrollToNode(hasText("瀹朵埂"))
        composeRule.onNodeWithText("骞撮緞").assertIsDisplayed()
        composeRule.onNodeWithText("瀹朵埂").assertIsDisplayed()
        composeRule.onNodeWithTag("profile-detail-list")
            .performScrollToNode(hasTestTag("profile-personal-save"))
        composeRule.onNodeWithTag("profile-personal-save").assertIsDisplayed()
    }

    @Test
    fun historyPage_searchesAndReparsesAgendaItem() {
        composeRule.onNodeWithTag("profile-shortcut-history").performClick()
        composeRule.onNodeWithText("鍘嗗彶璁板綍").assertIsDisplayed()
        composeRule.onNodeWithTag("history-search-field").performTextInput("鍥句功棣?)
        composeRule.onNodeWithTag("history-result-section")
            .assertIsDisplayed()
        composeRule.onNodeWithText("浜哄伐鏅鸿兘鍓嶆部璁插骇").assertIsDisplayed()
        composeRule.onNodeWithTag("history-record-test-lecture").performClick()

        composeRule.runOnIdle {
            assertEquals("浜哄伐鏅鸿兘鍓嶆部璁插骇", reparsedItemTitle)
        }
    }

    @Test
    fun notificationInbox_showsPersistedMessagesAndClears() {
        composeRule.onNodeWithTag("profile-dashboard-list")
            .performScrollToNode(hasTestTag("profile-shortcut-notification-inbox"))
        composeRule.onNodeWithTag("profile-shortcut-notification-inbox").performClick()
        composeRule.onNodeWithText("閫氱煡涓績").assertIsDisplayed()
        composeRule.onNodeWithTag("profile-inbox-section").assertIsDisplayed()
        composeRule.onNodeWithText("浜哄伐鏅鸿兘鍓嶆部璁插骇寰呯‘璁?).assertIsDisplayed()
        composeRule.onNodeWithTag("profile-detail-list")
            .performScrollToNode(hasTestTag("profile-inbox-clear"))
        composeRule.onNodeWithTag("profile-inbox-clear").performClick()

        composeRule.runOnIdle {
            assertTrue(inboxCleared)
        }
    }

    @Test
    fun notificationInbox_filtersPendingMessagesAndOpensMessageDetail() {
        composeRule.onNodeWithTag("profile-dashboard-list")
            .performScrollToNode(hasTestTag("profile-shortcut-notification-inbox"))
        composeRule.onNodeWithTag("profile-shortcut-notification-inbox").performClick()
        composeRule.onNodeWithTag("profile-detail-list")
            .performScrollToNode(hasTestTag("profile-inbox-filter-pending"))
        composeRule.onNodeWithTag("profile-inbox-filter-pending").performClick()
        composeRule.onNodeWithText("寰呭鐞嗘秷鎭?).assertIsDisplayed()
        composeRule.onNodeWithText("浜哄伐鏅鸿兘鍓嶆部璁插骇寰呯‘璁?).performClick()
        composeRule.onAllNodesWithText("妯″瀷宸叉彁鍙栨椂闂淬€佸湴鐐瑰拰鏍囬锛岀瓑寰呯敤鎴风‘璁ゅ啓鍏ャ€?)[0]
            .assertIsDisplayed()
        composeRule.onNodeWithText("鍏抽棴").performClick()
    }

    @Test
    fun timelineAssets_metricsOpenPlanCallback() {
        composeRule.onNodeWithTag("profile-shortcut-agent-center").performClick()
        composeRule.onNodeWithTag("profile-detail-list")
            .performScrollToNode(hasText("鏃堕棿绾胯祫浜?))
        composeRule.onNodeWithText("鏃堕棿绾胯祫浜?).performClick()
        composeRule.onNodeWithTag("timeline-assets-metric-confirmed").performClick()

        composeRule.runOnIdle {
            assertEquals(1, planOpenedCount)
        }
    }

    private fun openShortcutAndReturn(shortcutTag: String, expectedTitle: String) {
        composeRule.onNodeWithTag(shortcutTag).performClick()
        composeRule.onNodeWithText(expectedTitle).assertIsDisplayed()
        returnFromAgentCenterChildToDashboard()
    }

    private fun openToolRowAndReturn(toolTag: String, expectedTitle: String) {
        composeRule.onNodeWithTag("profile-dashboard-list")
            .performScrollToNode(hasTestTag(toolTag))
        composeRule.onNodeWithTag(toolTag).performClick()
        composeRule.onNodeWithText(expectedTitle).assertIsDisplayed()
        returnFromAgentCenterChildToDashboard()
    }

    private fun openAgentCenterTileAndReturn(tileText: String, expectedTitle: String) {
        composeRule.onNodeWithTag("profile-shortcut-agent-center").performClick()
        composeRule.onNodeWithText("鏅鸿兘浣撲腑蹇?).assertIsDisplayed()
        composeRule.onNodeWithTag("profile-detail-list")
            .performScrollToNode(hasText(tileText))
        composeRule.onNodeWithText(tileText).performClick()
        composeRule.onNodeWithText(expectedTitle).assertIsDisplayed()
        returnFromAgentCenterChildToDashboard()
    }

    private fun openAgentCenterTaggedTileAndReturn(tileTag: String, expectedTitle: String) {
        composeRule.onNodeWithTag("profile-shortcut-agent-center").performClick()
        composeRule.onNodeWithText("鏅鸿兘浣撲腑蹇?).assertIsDisplayed()
        composeRule.onNodeWithTag("profile-detail-list")
            .performScrollToNode(hasTestTag(tileTag))
        composeRule.onNodeWithTag(tileTag).performClick()
        composeRule.onNodeWithText(expectedTitle).assertIsDisplayed()
        returnFromAgentCenterChildToDashboard()
    }

    private fun openAgentCenterRowAndReturn(rowText: String, expectedTitle: String) {
        composeRule.onNodeWithTag("profile-shortcut-agent-center").performClick()
        composeRule.onNodeWithText("鏅鸿兘浣撲腑蹇?).assertIsDisplayed()
        composeRule.onNodeWithTag("profile-detail-list")
            .performScrollToNode(hasText(rowText))
        composeRule.onNodeWithText(rowText).performClick()
        composeRule.onNodeWithText(expectedTitle).assertIsDisplayed()
        returnFromAgentCenterChildToDashboard()
    }

    private fun returnFromAgentCenterChildToDashboard() {
        composeRule.onNodeWithTag("profile-detail-back").performClick()
        composeRule.waitForIdle()
        val stillInAgentCenterFlow = composeRule.onAllNodesWithText("鏅鸿兘浣撲腑蹇?)
            .fetchSemanticsNodes(atLeastOneRootRequired = false)
            .isNotEmpty()
        if (stillInAgentCenterFlow) {
            val hasBackButton = composeRule.onAllNodes(hasTestTag("profile-detail-back"))
                .fetchSemanticsNodes(atLeastOneRootRequired = false)
                .isNotEmpty()
            if (hasBackButton) {
                composeRule.onNodeWithTag("profile-detail-back").performClick()
                composeRule.waitForIdle()
            }
        }
        composeRule.onNodeWithText("CodexUser").assertIsDisplayed()
    }
}

@RunWith(AndroidJUnit4::class)
class ProfileScreenEmptyProfileHintTests {

    @get:Rule
    val composeRule = createAndroidComposeRule<ComponentActivity>()

    @Test
    fun personalInfoHint_usesInstructionTextInsteadOfFakeClickHint() {
        composeRule.setContent {
            ProfileScreenModule(
                userNickname = "绌虹櫧鐢ㄦ埛",
                userAccount = "student004",
                userAvatarUri = "",
                userSignature = "",
                userBirthday = "",
                userSchool = "",
                userAge = "",
                userGender = "",
                userMajor = "",
                userGrade = "",
                userHometown = "",
                scheduledReminderCount = 0,
                confirmedAgendaCount = 0,
                pendingAgendaCount = 0,
                todayAgendaCount = 0,
                agendaItems = emptyList(),
                inboxMessages = emptyList(),
                reminderLeadMinutes = 60,
                reminderDayEnabled = true,
                reminderHourEnabled = true,
                blockHighRisk = true,
                muteLowConfidence = false,
                autoMapLink = true,
                performanceLiteMode = false,
                runtimeStatus = AgentRuntimeStatusData(
                    modelName = "Volc-DeepSeek-V3.2",
                    appIdReady = true,
                    apiKeyReady = true,
                    chatEndpoint = "https://api-ai.vivo.com.cn/v1/chat/completions",
                    ocrEndpoint = "https://api-ai.vivo.com.cn/ocr/general_recognition",
                    dataStoreReady = true,
                    accountReady = true,
                    cameraReady = true,
                    voiceReady = true,
                    agendaCount = 0,
                    inboxCount = 0,
                    reminderCount = 0
                ),
                onReminderLeadMinutesChange = {},
                onReminderDayEnabledChange = {},
                onReminderHourEnabledChange = {},
                onBlockHighRiskChange = {},
                onMuteLowConfidenceChange = {},
                onAutoMapLinkChange = {},
                onPerformanceLiteModeChange = {},
                onProfileSave = { _, _, _, _, _, _, _, _, _, _ -> },
                onPickProfileAvatar = {},
                onCaptureProfileAvatar = {},
                onOpenPlan = {},
                onReparseHistoryItem = {},
                onClearInboxMessages = {},
                onLogout = {}
            )
        }

        composeRule.onNodeWithTag("profile-dashboard-list")
            .performScrollToNode(hasText("璇峰畬鍠勭敓鏃ャ€佸勾榫勫拰瀛︽牎璧勬枡"))
        composeRule.onNodeWithText("璇峰畬鍠勭敓鏃ャ€佸勾榫勫拰瀛︽牎璧勬枡").assertIsDisplayed()
    }
}

private fun sampleIntent(): ExecutableIntent {
    return ExecutableIntent(
        scene = "campus_schedule_agent",
        action = "create_event",
        payload = ExecutablePayload(
            title = "浜哄伐鏅鸿兘鍓嶆部璁插骇",
            time = "2026-05-16T19:00:00",
            location = "鍥句功棣嗘姤鍛婂巺",
            description = "娆㈣繋鍚屽浠彁鍓嶅埌鍦?
        ),
        modelConfidence = 0.93,
        fusedConfidence = 0.94,
        fallbackQuery = "璇风‘璁ゆ槸鍚﹂渶瑕佸姞鍏ユ棩绋?,
        requiresConfirmation = true,
        riskLevel = IntentRiskLevel.MEDIUM
    )
}

private fun samplePresets(): List<PromptPreset> {
    return listOf(
        PromptPreset(id = "lecture", label = "璁插骇", prompt = "璇嗗埆璁插骇娴锋姤"),
        PromptPreset(id = "exam", label = "鑰冭瘯", prompt = "璇嗗埆鑰冭瘯閫氱煡")
    )
}

private fun sampleAgendaItems(): List<AgendaCardData> {
    return listOf(
        AgendaCardData(
            id = "test-lecture",
            title = "浜哄伐鏅鸿兘鍓嶆部璁插骇",
            summary = "鐢辩兢鑱婃埅鍥炬暣鐞嗗嚭鐨勮搴ф彁閱?,
            time = "2026-05-16 19:00",
            location = "鍥句功棣嗘姤鍛婂巺",
            status = "宸茬‘璁?,
            isoDateTime = "2026-05-16T19:00:00",
            sourceLabel = "缇よ亰鎴浘"
        ),
        AgendaCardData(
            id = "test-club",
            title = "绀惧洟渚嬩細",
            summary = "绀惧洟閫氱煡娌夋穩",
            time = "2026-05-17 20:00",
            location = "娲诲姩涓績",
            status = "寰呮牎楠?,
            isoDateTime = "2026-05-17T20:00:00",
            sourceLabel = "鏂囨湰瀵煎叆"
        )
    )
}

private fun sampleInboxMessages(): List<InboxMessageData> {
    return listOf(
        InboxMessageData(
            id = "inbox-pending",
            type = "pending",
            title = "浜哄伐鏅鸿兘鍓嶆部璁插骇寰呯‘璁?,
            summary = "妯″瀷宸叉彁鍙栨椂闂淬€佸湴鐐瑰拰鏍囬锛岀瓑寰呯敤鎴风‘璁ゅ啓鍏ャ€?,
            status = "寰呭鐞?,
            createdAtMillis = 1_768_000_000_000
        ),
        InboxMessageData(
            id = "inbox-confirmed",
            type = "confirmed",
            title = "绀惧洟渚嬩細宸插啓鍏?,
            summary = "宸茶繘鍏ユ椂闂寸嚎骞舵寕杞芥湰鍦版彁閱掋€?,
            status = "宸插鐞?,
            createdAtMillis = 1_768_000_060_000
        )
    )
}

private fun sampleRuntimeStatus(): AgentRuntimeStatusData {
    return AgentRuntimeStatusData(
        modelName = "Volc-DeepSeek-V3.2",
        appIdReady = true,
        apiKeyReady = true,
        chatEndpoint = "https://api-ai.vivo.com.cn/v1/chat/completions",
        ocrEndpoint = "https://api-ai.vivo.com.cn/ocr/general_recognition",
        dataStoreReady = true,
        accountReady = true,
        cameraReady = true,
        voiceReady = true,
        agendaCount = 2,
        inboxCount = 0,
        reminderCount = 1
    )
}

private fun sampleSuggestion(): ExecutionSuggestion {
    return ExecutionSuggestion(
        mode = ExecutionMode.REQUIRE_CONFIRMATION,
        summary = "寤鸿娣诲姞鏍″洯鏃ョ▼锛屽彲淇″害 94%",
        prompt = "璇嗗埆鍒版牎鍥棩绋嬶細浜哄伐鏅鸿兘鍓嶆部璁插骇锛屾椂闂?2026-05-16T19:00:00锛屽湴鐐?鍥句功棣嗘姤鍛婂巺銆傛槸鍚︽坊鍔犲埌绯荤粺鏃ュ巻锛?,
        threshold = 0.7,
        validation = ValidationResult(
            isValid = true,
            issues = emptyList()
        )
    )
}
