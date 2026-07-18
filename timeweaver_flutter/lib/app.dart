import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'models/account_user.dart';
import 'models/achievement_unlock_record.dart';
import 'models/event_item.dart';
import 'models/export_record.dart';
import 'models/inbox_message.dart';
import 'models/parsed_notice.dart';
import 'models/source_info.dart';
import 'models/user_insight.dart';
import 'models/user_preference.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/profile_page.dart';
import 'pages/timeline_page.dart';
import 'repositories/account_repository.dart';
import 'repositories/event_repository.dart';
import 'services/account_session_service.dart';
import 'services/api_config.dart';
import 'services/integration_service.dart';
import 'services/parser_service.dart';
import 'services/permission_service.dart';
import 'services/reminder_service.dart';
import 'services/schedule_intelligence_service.dart';
import 'services/share_receive_service.dart';
import 'services/speech_service.dart';
import 'services/storage_service.dart';
import 'services/timeline_export_service.dart';
import 'services/tts_service.dart';
import 'services/user_insight_service.dart';
import 'utils/date_utils.dart';
import 'utils/validators.dart';
import 'widgets/app_overlays.dart';

class AppColors {
  static const primary = Color(0xFF003528);
  static const onPrimary = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF0B4D3D);
  static const secondary = Color(0xFF9E3F42);
  static const primarySoft = Color(0xFFB2EFD9);
  static const mint = Color(0xFFCCF2E6);
  static const coral = Color(0xFFFFE0DC);
  static const gold = Color(0xFFFFEDC0);
  static const background = Color(0xFFFFF8F2);
  static const surface = Color(0xFFFFFCF8);
  static const surfaceLowest = Color(0xFFFFFFFF);
  static const surfaceLow = Color(0xFFFFF2DF);
  static const surfaceWarm = Color(0xFFFFEBCB);
  static const surfaceHigh = Color(0xFFFFE5B6);
  static const surfaceHighest = Color(0xFFFFDEA1);
  static const text = Color(0xFF261900);
  static const muted = Color(0xFF404945);
  static const border = Color(0xFFF0E4D6);
  static const glass = Color(0xCCFFFCF8);
}

class TimeWeaverApp extends StatefulWidget {
  const TimeWeaverApp({super.key});

  @override
  State<TimeWeaverApp> createState() => _TimeWeaverAppState();
}

class _TimeWeaverAppState extends State<TimeWeaverApp> {
  late final AppController controller;

  @override
  void initState() {
    super.initState();
    controller = AppController()..initialize();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '织时',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          primaryContainer: AppColors.primaryContainer,
          secondary: Color(0xFF9E3F42),
          secondaryContainer: Color(0xFFFE8989),
          tertiary: Color(0xFF8A6500),
          tertiaryContainer: Color(0xFFB67A00),
          error: Color(0xFFBA1A1A),
          surface: AppColors.surface,
          onSurface: AppColors.text,
          onSurfaceVariant: AppColors.muted,
          outline: Color(0xFF707975),
          outlineVariant: Color(0xFFBFC9C3),
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Manrope',
        navigationBarTheme: NavigationBarThemeData(
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
            return IconThemeData(
              color: states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.muted,
            );
          }),
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
            return TextStyle(
              color: states.contains(WidgetState.selected)
                  ? AppColors.primary
                  : AppColors.muted,
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w500,
            );
          }),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontFamilyFallback: ['NotoSansSC'],
            fontSize: 32,
            height: 38 / 32,
            letterSpacing: -0.576,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
          headlineLarge: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontFamilyFallback: ['NotoSansSC'],
            fontSize: 25,
            height: 31 / 25,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontFamilyFallback: ['NotoSansSC'],
            fontSize: 18,
            height: 24 / 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
          headlineSmall: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontFamilyFallback: ['NotoSansSC'],
            fontSize: 21,
            height: 27 / 21,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
          titleMedium: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontFamilyFallback: ['NotoSansSC'],
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
          bodyLarge: TextStyle(
            fontFamily: 'Manrope',
            fontFamilyFallback: ['NotoSansSC'],
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w500,
            color: AppColors.text,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Manrope',
            fontFamilyFallback: ['NotoSansSC'],
            fontSize: 12.5,
            height: 18 / 12.5,
            color: AppColors.text,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Manrope',
            fontFamilyFallback: ['NotoSansSC'],
            fontSize: 11.5,
            height: 16 / 11.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.08,
            color: AppColors.text,
          ),
          labelMedium: TextStyle(
            fontFamily: 'Manrope',
            fontFamilyFallback: ['NotoSansSC'],
            fontSize: 11.5,
            height: 16 / 11.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.08,
            color: AppColors.text,
          ),
          labelSmall: TextStyle(
            fontFamily: 'Manrope',
            fontFamilyFallback: ['NotoSansSC'],
            fontSize: 10.5,
            height: 13 / 10.5,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.32,
            color: AppColors.text,
          ),
        ),
      ),
      home: TimeWeaverShell(controller: controller),
    );
  }
}

class TimeWeaverShell extends StatelessWidget {
  const TimeWeaverShell({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final pages = [
          HomePage(controller: controller),
          TimelinePage(controller: controller),
          ProfilePage(controller: controller),
        ];

        return Stack(
          children: [
            Scaffold(
              body: SafeArea(
                bottom: false,
                child: controller.initializing
                    ? const Center(child: CircularProgressIndicator())
                    : controller.currentUser == null
                    ? LoginPage(
                        isSubmitting: controller.loginSubmitting,
                        message: controller.loginMessage,
                        onLogin: controller.loginAccount,
                        onRegister: controller.registerAccount,
                      )
                    : IndexedStack(
                        index: controller.currentTab,
                        children: pages,
                      ),
              ),
              bottomNavigationBar: controller.currentUser == null
                  ? null
                  : NavigationBar(
                      selectedIndex: controller.currentTab,
                      backgroundColor: Colors.white,
                      indicatorColor: AppColors.primarySoft.withValues(
                        alpha: 0.60,
                      ),
                      onDestinationSelected: controller.setTab,
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.home_rounded),
                          label: '首页',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.schedule_rounded),
                          label: '时间线',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.person_rounded),
                          label: '我的',
                        ),
                      ],
                    ),
            ),
            if (controller.currentUser != null) ...[
              AppLoadingOverlay(
                isVisible: controller.isBusy,
                currentStage: controller.loadingStage,
                onCancel: controller.cancelParsing,
              ),
              AppErrorOverlay(
                errorMessage: controller.errorMessage,
                showRetry: controller.canRetryLastAction,
                onRetry: controller.retryLastAction,
                onDismiss: controller.dismissError,
              ),
              TimelineTransferOverlay(
                isVisible: controller.showTimelineTransfer,
              ),
            ],
          ],
        );
      },
    );
  }
}

class AppController extends ChangeNotifier {
  AppController()
    : repository = EventRepository(StorageService()),
      accountRepository = AccountRepository(),
      accountSessionService = AccountSessionService(),
      parserService = ParserService(),
      reminderService = ReminderService(),
      scheduleIntelligenceService = const ScheduleIntelligenceService(),
      permissionService = PermissionService(),
      speechService = SpeechService(),
      ttsService = TtsService(),
      integrationService = IntegrationService(),
      shareReceiveService = ShareReceiveService(),
      timelineExportService = TimelineExportService(),
      userInsightService = const UserInsightService();

  final EventRepository repository;
  final AccountRepository accountRepository;
  final AccountSessionService accountSessionService;
  final ParserService parserService;
  final ReminderService reminderService;
  final ScheduleIntelligenceService scheduleIntelligenceService;
  final PermissionService permissionService;
  final SpeechService speechService;
  final TtsService ttsService;
  final IntegrationService integrationService;
  final ShareReceiveService shareReceiveService;
  final TimelineExportService timelineExportService;
  final UserInsightService userInsightService;
  final ImagePicker _imagePicker = ImagePicker();
  Timer? _voiceElapsedTimer;
  DateTime? _voiceStartedAt;
  int _parseOperationId = 0;
  final Set<String> _confirmingNoticeIds = <String>{};
  String? _lastParseRawText;
  String? _lastParseImagePath;
  SourceType? _lastParseSourceType;
  bool _errorCanRetry = false;

  bool initializing = true;
  bool isBusy = false;
  int loadingStage = 0;
  bool showTimelineTransfer = false;
  bool isVoiceListening = false;
  int currentTab = 0;
  String statusMessage = '';
  String? errorMessage;
  AccountUser? currentUser;
  String loginMessage = '';
  bool loginSubmitting = false;

  List<EventItem> allEvents = [];
  List<ParsedNotice> allPendingNotices = [];
  List<InboxMessage> allInboxMessages = [];
  List<ExportRecord> allExportRecords = [];
  List<AchievementUnlockRecord> allAchievementUnlocks = [];
  List<EventItem> events = [];
  List<ParsedNotice> pendingNotices = [];
  List<InboxMessage> inboxMessages = [];
  List<ExportRecord> exportRecords = [];
  List<AchievementUnlockRecord> achievementUnlocks = [];
  UserPreference preference = const UserPreference();
  bool dataStoreReady = false;
  bool cameraPermissionReady = false;
  bool photosPermissionReady = false;
  bool notificationPermissionReady = false;
  bool microphonePermissionReady = false;

  List<EventItem> get confirmedEvents =>
      events.where((item) => item.isConfirmed).toList()..sort((a, b) {
        final left = a.startTime ?? DateTime(9999);
        final right = b.startTime ?? DateTime(9999);
        return left.compareTo(right);
      });

  List<EventItem> get todayEvents => confirmedEvents
      .where((item) => ZhishiDateUtils.isToday(item.startTimeIso))
      .toList();

  String get nextReminderText =>
      reminderService.nextReminderSummary(confirmedEvents);

  int get scheduledReminderCount =>
      reminderService.upcomingReminderCount(confirmedEvents);

  UserInsightResult get userInsights => userInsightService.analyze(
    preference: preference,
    confirmedEvents: confirmedEvents,
    pendingCount: pendingNotices.length,
    scheduledReminderCount: scheduledReminderCount,
    unlockedAtById: {
      for (final record in achievementUnlocks)
        record.achievementId: record.unlockedAt,
    },
  );

  Duration get voiceRecordingDuration => _voiceStartedAt == null
      ? Duration.zero
      : DateTime.now().difference(_voiceStartedAt!);

  String get currentAccountLabel => currentUser?.account ?? '';

  bool get canRetryLastAction =>
      _errorCanRetry && _lastParseSourceType != null && !isBusy;

  Future<void> initialize() async {
    initializing = true;
    notifyListeners();
    await accountRepository.initialize();
    await reminderService.initialize();
    await ttsService.initialize();
    currentUser = await accountSessionService.loadCurrentUser(
      accountRepository,
    );
    allEvents = await repository.loadEvents();
    allPendingNotices = await repository.loadPendingNotices();
    final legacyPreference = await repository.loadPreference();
    allInboxMessages = await repository.loadInboxMessages();
    allExportRecords = await repository.loadExportRecords();
    allAchievementUnlocks = await repository.loadAchievementUnlocks();
    if (currentUser != null) {
      await _claimUnownedDataForAccount(currentUser!.account);
      final scopedPreference = await repository.loadPreferenceForAccount(
        currentUser!.account,
      );
      preference = _applyCurrentUserToPreference(
        scopedPreference ?? legacyPreference,
        currentUser,
      );
      if (scopedPreference == null) await _saveCurrentPreference();
    } else {
      preference = legacyPreference;
    }
    _loadVisibleDataForCurrentAccount();
    await _syncAchievementUnlocks(notifyInbox: false);
    dataStoreReady = true;
    await _refreshRuntimeStatus(notify: false);
    initializing = false;
    statusMessage = _buildInitialStatus();
    notifyListeners();
    await shareReceiveService.start(
      onImport: _handleSharedImport,
      onError: _handleShareReceiveError,
    );
  }

  @override
  void dispose() {
    _voiceElapsedTimer?.cancel();
    unawaited(shareReceiveService.dispose());
    unawaited(speechService.dispose());
    unawaited(ttsService.stop());
    super.dispose();
  }

  void setTab(int index) {
    currentTab = index;
    notifyListeners();
  }

  Future<String?> pickImage(SourceType type) async {
    final granted = type == SourceType.camera
        ? await requestCameraAccess(notify: false)
        : await permissionService.requestPhotos();
    await _refreshRuntimeStatus(notify: false);
    if (!granted) {
      errorMessage = type == SourceType.camera
          ? '需要相机权限才能拍照识别，请先授权。'
          : '需要图片读取权限才能导入相册或分享图片，请先授权。';
      notifyListeners();
      return null;
    }
    final picked = await _imagePicker.pickImage(
      source: type == SourceType.camera
          ? ImageSource.camera
          : ImageSource.gallery,
      imageQuality: 88,
      maxWidth: 1800,
    );
    return picked?.path;
  }

  Future<void> parseInput({
    required String rawText,
    String? imagePath,
    required SourceType sourceType,
  }) async {
    final hasText = rawText.trim().isNotEmpty;
    final hasImage = imagePath != null && imagePath.trim().isNotEmpty;
    if (!hasText && !hasImage) {
      errorMessage = '先输入一段校园通知文本，再点击发送解析。';
      _errorCanRetry = false;
      notifyListeners();
      return;
    }

    final operationId = ++_parseOperationId;
    _lastParseRawText = rawText;
    _lastParseImagePath = imagePath;
    _lastParseSourceType = sourceType;
    _errorCanRetry = false;
    isBusy = true;
    loadingStage = 0;
    errorMessage = null;
    statusMessage = '正在整理通知';
    notifyListeners();
    try {
      final source = SourceInfo(
        type: sourceType,
        rawText: hasText ? rawText.trim() : null,
        imagePath: imagePath,
        importedAtIso: DateTime.now().toIso8601String(),
      );
      if (operationId != _parseOperationId) return;
      loadingStage = 1;
      notifyListeners();
      final outcome = await parserService.parseNotice(source: source);
      if (operationId != _parseOperationId) return;
      loadingStage = 2;
      notifyListeners();
      final parsedNotices = outcome.notices
          .map((item) => item.copyWith(ownerAccount: currentAccountLabel))
          .toList();
      final notices = <ParsedNotice>[];
      var duplicateCount = 0;
      for (final candidate in parsedNotices) {
        final pendingDuplicate = scheduleIntelligenceService
            .findPendingDuplicate(candidate, [...pendingNotices, ...notices]);
        final confirmedDuplicate = scheduleIntelligenceService
            .findConfirmedDuplicate(candidate, confirmedEvents);
        if (pendingDuplicate != null || confirmedDuplicate != null) {
          duplicateCount++;
          continue;
        }
        notices.add(candidate);
      }
      if (outcome.action == NoticeAction.ttsFeedback) {
        final speechText = outcome.speechText?.trim();
        if (speechText == null || speechText.isEmpty) {
          errorMessage = outcome.feedback ?? '接口没有返回可播报内容';
          statusMessage = '语音反馈未生成';
        } else {
          statusMessage = speechText;
          await _pushInboxMessage(
            type: 'tts_feedback',
            title: '语音反馈已生成',
            summary: speechText,
            status: '已处理',
          );
          await ttsService.speak(speechText);
        }
      } else if (duplicateCount > 0 && notices.isEmpty) {
        errorMessage = null;
        statusMessage = duplicateCount == 1
            ? '这条事项已在待确认列表或时间线中，无需重复添加'
            : '识别出的 $duplicateCount 条事项均已存在，无需重复添加';
        await _pushInboxMessage(
          type: 'duplicate_skipped',
          title: '已避免重复添加',
          summary: '来源：${source.label}。$statusMessage',
          status: '已处理',
        );
        await ttsService.speak(statusMessage);
      } else if (outcome.action == NoticeAction.unknown || notices.isEmpty) {
        errorMessage = outcome.feedback ?? '没有识别到可处理的校园事项';
        _errorCanRetry = true;
        statusMessage = '未生成待确认事项';
        await _pushInboxMessage(
          type: 'parse_feedback',
          title: '解析结果为空',
          summary: '来源：${source.label}。${errorMessage!}',
          status: '反馈',
        );
      } else {
        pendingNotices = [...notices, ...pendingNotices];
        await _saveScopedPendingNotices();
        final clarificationCount = notices
            .where((notice) => notice.action == NoticeAction.clarification)
            .length;
        final navigationCount = notices
            .where((notice) => notice.action == NoticeAction.navigate)
            .length;
        statusMessage = clarificationCount > 0
            ? preference.muteLowConfidence
                  ? '低置信度结果已保留，请补充信息后再确认'
                  : '已生成 ${notices.length} 条结果，其中 $clarificationCount 条需要补充信息'
            : navigationCount > 0
            ? '已识别校园地点，请确认后打开地图'
            : '已生成 ${notices.length} 条待确认事项';
        if (duplicateCount > 0) {
          statusMessage = '$statusMessage，另有 $duplicateCount 条重复事项未再次添加';
        }
        await _pushInboxMessage(
          type: clarificationCount > 0 ? 'clarification' : 'parse_result',
          title: clarificationCount > 0 ? '解析结果需要补充' : '已生成待确认事项',
          summary: '来源：${source.label}。$statusMessage',
          status: clarificationCount > 0 ? '待补充' : '待处理',
        );
        await ttsService.speak(statusMessage);
      }
    } catch (error) {
      if (operationId != _parseOperationId) return;
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      _errorCanRetry = true;
      statusMessage = '解析未完成';
      await _pushInboxMessage(
        type: 'parse_feedback',
        title: '解析失败',
        summary: errorMessage!,
        status: '反馈',
      );
      await ttsService.speak(errorMessage!);
    } finally {
      if (operationId == _parseOperationId) {
        isBusy = false;
        loadingStage = 0;
        notifyListeners();
      }
    }
  }

  void cancelParsing() {
    if (!isBusy) return;
    _parseOperationId++;
    isBusy = false;
    loadingStage = 0;
    statusMessage = '识别已取消';
    notifyListeners();
  }

  Future<void> retryLastAction() async {
    final sourceType = _lastParseSourceType;
    if (sourceType == null || isBusy) return;
    final rawText = _lastParseRawText ?? '';
    final imagePath = _lastParseImagePath;
    dismissError(notify: false);
    await parseInput(
      rawText: rawText,
      imagePath: imagePath,
      sourceType: sourceType,
    );
  }

  void dismissError({bool notify = true}) {
    errorMessage = null;
    _errorCanRetry = false;
    if (notify) notifyListeners();
  }

  Future<String?> confirmNotice(
    ParsedNotice notice, {
    bool navigateToTimeline = true,
  }) async {
    if (!_confirmingNoticeIds.add(notice.id)) {
      return '这条事项正在处理中，请稍候';
    }
    try {
      return await _confirmNotice(
        notice,
        navigateToTimeline: navigateToTimeline,
      );
    } finally {
      _confirmingNoticeIds.remove(notice.id);
    }
  }

  Future<String?> _confirmNotice(
    ParsedNotice notice, {
    required bool navigateToTimeline,
  }) async {
    final blocker = Validators.confirmBlocker(notice);
    if (blocker != null) {
      errorMessage = blocker;
      await _pushInboxMessage(
        type: 'confirm_feedback',
        title: '事项未能写入时间线',
        summary: blocker,
        status: '待处理',
      );
      notifyListeners();
      return blocker;
    }

    if (notice.action == NoticeAction.navigate) {
      if (!preference.autoMapLink) {
        const message = '地点解析与地图联动已关闭，请先在偏好设置中开启';
        errorMessage = message;
        statusMessage = '地图导航未执行';
        await _pushInboxMessage(
          type: 'navigate_blocked',
          title: '地图联动已关闭',
          summary: notice.location ?? message,
          status: '已拦截',
        );
        notifyListeners();
        return message;
      }
      final opened = await integrationService.openLocation(notice.location!);
      if (!opened) {
        const message = '系统没有可用的地图应用';
        errorMessage = message;
        statusMessage = '地图导航未完成';
        await _pushInboxMessage(
          type: 'navigate_failed',
          title: '导航失败',
          summary: notice.location!,
          status: '待处理',
        );
        notifyListeners();
        return message;
      }
      pendingNotices = pendingNotices
          .where((item) => item.id != notice.id)
          .toList();
      await _saveScopedPendingNotices();
      errorMessage = null;
      statusMessage = '已打开地点导航';
      await _pushInboxMessage(
        type: 'navigate',
        title: '已打开地点导航',
        summary: notice.location!,
        status: '已处理',
      );
      notifyListeners();
      return null;
    }

    final replacingEvent = events
        .where((item) => item.id == notice.id)
        .firstOrNull;
    final duplicate = scheduleIntelligenceService.findConfirmedDuplicate(
      notice,
      confirmedEvents,
      excludingEventId: replacingEvent?.id,
    );
    if (duplicate != null) {
      pendingNotices = pendingNotices
          .where((item) => item.id != notice.id)
          .toList();
      await _saveScopedPendingNotices();
      errorMessage = null;
      statusMessage = '时间线中已有《${duplicate.title}》，未重复写入';
      await _pushInboxMessage(
        type: 'duplicate_skipped',
        title: '已避免重复写入时间线',
        summary: statusMessage,
        status: '已处理',
      );
      if (navigateToTimeline) currentTab = 1;
      await ttsService.speak(statusMessage);
      notifyListeners();
      return null;
    }

    await reminderService.requestPermissions();
    await _refreshRuntimeStatus(notify: false);
    if (replacingEvent != null) {
      await reminderService.cancelForEvent(replacingEvent);
    }
    var event = EventItem.fromParsedNotice(
      notice,
      preference,
      currentAccountLabel,
    );
    final scheduled = await reminderService.scheduleForEvent(event);
    event = event.copyWith(reminders: scheduled);
    pendingNotices = pendingNotices
        .where((item) => item.id != notice.id)
        .toList();
    events = [event, ...events.where((item) => item.id != event.id)];
    await _saveScopedPendingNotices();
    await _saveScopedEvents();
    await _syncAchievementUnlocks();
    try {
      if (replacingEvent == null) {
        await integrationService.addEventToCalendar(event);
      }
      statusMessage = replacingEvent == null
          ? '已加入时间线，并打开系统日历'
          : '已更新时间线事项与本地提醒';
      errorMessage = null;
      await _pushInboxMessage(
        type: 'timeline_confirm',
        title: replacingEvent == null ? '事项已写入时间线' : '时间线事项已更新',
        summary: replacingEvent == null
            ? '《${event.title}》已写入时间线，并已尝试打开系统日历。'
            : '《${event.title}》已更新，旧提醒已取消并按当前偏好重新排程。',
        status: '已处理',
      );
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      statusMessage = replacingEvent == null
          ? '已加入时间线，系统日历未完成'
          : '已更新时间线，本地提醒未完成';
      errorMessage = message;
      await _pushInboxMessage(
        type: 'timeline_confirm',
        title: replacingEvent == null ? '事项已写入时间线' : '时间线事项已更新',
        summary: replacingEvent == null
            ? '《${event.title}》已写入时间线，但系统日历未完成：$message'
            : '《${event.title}》已更新时间线，但本地提醒未完成：$message',
        status: '反馈',
      );
    }
    if (navigateToTimeline) currentTab = 1;
    await ttsService.speak(errorMessage ?? '已加入时间线，并按你的提醒偏好排程');
    notifyListeners();
    return null;
  }

  Future<String?> confirmNoticeWithTransfer(ParsedNotice notice) async {
    showTimelineTransfer = true;
    notifyListeners();

    final blocker = await confirmNotice(notice, navigateToTimeline: false);
    if (blocker != null) {
      showTimelineTransfer = false;
      notifyListeners();
      return blocker;
    }

    await Future<void>.delayed(const Duration(milliseconds: 420));
    currentTab = 1;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 360));
    showTimelineTransfer = false;
    notifyListeners();
    return null;
  }

  Future<void> discardNotice(ParsedNotice notice) async {
    pendingNotices = pendingNotices
        .where((item) => item.id != notice.id)
        .toList();
    await _saveScopedPendingNotices();
    statusMessage = '已丢弃待确认事项';
    await _pushInboxMessage(
      type: 'timeline_discard',
      title: '已丢弃待确认事项',
      summary: '《${notice.title}》已从待确认列表移除。',
      status: '已处理',
    );
    await ttsService.speak(statusMessage);
    notifyListeners();
  }

  Future<void> updatePendingNotice(ParsedNotice notice) async {
    pendingNotices = pendingNotices
        .map((item) => item.id == notice.id ? notice : item)
        .toList();
    await _saveScopedPendingNotices();
    statusMessage = '待确认事项已更新';
    notifyListeners();
  }

  Future<void> updateEvent(EventItem event) async {
    final old = events.where((item) => item.id == event.id).firstOrNull;
    if (old != null) await reminderService.cancelForEvent(old);
    final scheduled = await reminderService.scheduleForEvent(event);
    final updated = event.copyWith(
      reminders: scheduled,
      updatedAtIso: DateTime.now().toIso8601String(),
    );
    events = events
        .map((item) => item.id == updated.id ? updated : item)
        .toList();
    await _saveScopedEvents();
    await _syncAchievementUnlocks();
    statusMessage = '时间线事项已更新';
    await _pushInboxMessage(
      type: 'edited',
      title: '日程已更新',
      summary: '${updated.title} · ${updated.startTimeIso ?? '时间待补充'}',
      status: '已处理',
    );
    notifyListeners();
  }

  Future<void> deleteEvent(EventItem event) async {
    await reminderService.cancelForEvent(event);
    events = events.where((item) => item.id != event.id).toList();
    await _saveScopedEvents();
    statusMessage = '已从时间线删除';
    await _pushInboxMessage(
      type: 'deleted',
      title: '日程已删除',
      summary: event.title,
      status: '已处理',
    );
    notifyListeners();
  }

  Future<void> duplicateEvent(EventItem event) async {
    final nowIso = DateTime.now().toIso8601String();
    final duplicate = ParsedNotice(
      id: '${event.id}-copy-${DateTime.now().millisecondsSinceEpoch}',
      title: '${event.title} 副本',
      eventType: event.eventType,
      startTimeIso: event.startTimeIso,
      deadlineIso: event.deadlineIso,
      location: event.location,
      description: event.description,
      source: event.source,
      confidence: event.confidence,
      createdAtIso: nowIso,
      reminderSuggestion: event.reminders.isEmpty
          ? '提前${preference.reminderLeadDays}天 / 提前${preference.reminderLeadMinutes}分钟'
          : event.reminders.map((reminder) => reminder.label).join(' / '),
      status: '待确认',
      ownerAccount: currentAccountLabel,
    );
    pendingNotices = [duplicate, ...pendingNotices];
    await _saveScopedPendingNotices();
    currentTab = 0;
    statusMessage = '已复制成待校验事项';
    await _pushInboxMessage(
      type: 'duplicated',
      title: '已复制成新事项',
      summary: duplicate.title,
      status: '待校验',
    );
    notifyListeners();
  }

  Future<void> startVoiceInput(ValueChanged<String> onText) async {
    if (isVoiceListening) return;
    final microphoneGranted = await permissionService.requestMicrophone();
    microphonePermissionReady = microphoneGranted;
    if (!microphoneGranted) {
      errorMessage = '麦克风权限未授权，无法进行真实语音识别';
      statusMessage = '语音识别未启动';
      notifyListeners();
      return;
    }
    isVoiceListening = true;
    _voiceStartedAt = DateTime.now();
    _voiceElapsedTimer?.cancel();
    _voiceElapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (isVoiceListening) notifyListeners();
    });
    errorMessage = null;
    statusMessage = '已开始语音识别，再次点击可结束';
    var recognizedAnyText = false;
    notifyListeners();
    await speechService.listen(
      onText: (text) {
        recognizedAnyText = text.trim().isNotEmpty;
        onText(text);
        statusMessage = '语音正在转写';
        notifyListeners();
      },
      onError: (message) {
        errorMessage = message;
        statusMessage = '语音识别未完成';
        isVoiceListening = false;
        _stopVoiceElapsedTimer();
        unawaited(
          _pushInboxMessage(
            type: 'voice_feedback',
            title: '语音识别未完成',
            summary: message,
            status: '反馈',
          ),
        );
        notifyListeners();
      },
      onDone: () {
        if (!isVoiceListening) return;
        isVoiceListening = false;
        _stopVoiceElapsedTimer();
        statusMessage = recognizedAnyText ? '语音已转写，可继续解析' : '语音识别未返回文本';
        notifyListeners();
      },
    );
    await _refreshRuntimeStatus(notify: false);
  }

  Future<void> stopVoiceInput() async {
    if (!isVoiceListening) return;
    final elapsed = voiceRecordingDuration;
    if (elapsed < const Duration(milliseconds: 450)) {
      await speechService.cancel();
      isVoiceListening = false;
      _stopVoiceElapsedTimer();
      statusMessage = '语音时长太短，请点击语音按钮后再说话';
      notifyListeners();
      return;
    }
    statusMessage = '正在识别 ${elapsed.inSeconds} 秒的语音…';
    notifyListeners();
    await speechService.stop();
  }

  void _stopVoiceElapsedTimer() {
    _voiceElapsedTimer?.cancel();
    _voiceElapsedTimer = null;
    _voiceStartedAt = null;
  }

  Future<void> openMap(EventItem event) async {
    if (!preference.autoMapLink) {
      errorMessage = '地点解析与地图联动已关闭，请先在偏好设置中开启';
      statusMessage = '地图导航未执行';
      await _pushInboxMessage(
        type: 'navigate_blocked',
        title: '地图联动已关闭',
        summary: event.location ?? event.title,
        status: '已拦截',
      );
      notifyListeners();
      return;
    }
    final opened = await integrationService.openMap(event);
    if (!opened) {
      errorMessage = '事项没有地点，或系统没有可用的地图应用';
      statusMessage = '地图导航未完成';
    } else {
      errorMessage = null;
      statusMessage = '已打开地图导航';
    }
    await _pushInboxMessage(
      type: opened ? 'navigate' : 'navigate_failed',
      title: opened ? '已打开地点导航' : '导航失败',
      summary: event.location ?? event.title,
      status: opened ? '已处理' : '待补充',
    );
    notifyListeners();
  }

  Future<void> shareEvent(EventItem event) async {
    await integrationService.shareEvent(event);
    statusMessage = '已调用系统分享';
    notifyListeners();
  }

  Future<void> copyEvent(EventItem event) async {
    await integrationService.copyEvent(event);
    statusMessage = '已复制日程摘要';
    notifyListeners();
  }

  Future<void> exportTimelinePdf() => exportTimeline(TimelineExportFormat.pdf);

  Future<void> exportTimelinePng() => exportTimeline(TimelineExportFormat.png);

  Future<void> exportTimelineJpg() => exportTimeline(TimelineExportFormat.jpg);

  Future<void> exportTimeline(TimelineExportFormat format) async {
    isBusy = true;
    errorMessage = null;
    statusMessage = '正在导出时间线 ${format.label}';
    notifyListeners();
    try {
      final now = DateTime.now();
      final exportEvents = confirmedEvents.where((event) {
        final start = event.startTime;
        return start != null &&
            start.year == now.year &&
            start.month == now.month;
      }).toList();
      final result = await timelineExportService.export(exportEvents, format);
      final opened = await timelineExportService.open(result.path);
      final record = ExportRecord(
        id: 'export-${DateTime.now().millisecondsSinceEpoch}',
        format: result.format.label,
        path: result.path,
        bytes: result.bytes,
        eventCount: exportEvents.length,
        createdAtMillis: DateTime.now().millisecondsSinceEpoch,
        ownerAccount: currentAccountLabel,
      );
      exportRecords = [record, ...exportRecords];
      await _saveScopedExportRecords();
      statusMessage = '时间线 ${result.format.label} 已导出：${result.path}';
      await _pushInboxMessage(
        type: 'export_record',
        title: '时间线已导出',
        summary:
            '已导出本月 ${exportEvents.length} 条事项，格式：${result.format.label}，文件路径：${result.path}',
        status: '已处理',
      );
      if (!opened) {
        errorMessage = '${result.format.label} 已导出，但系统没有返回打开确认';
      }
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      statusMessage = '${format.label} 导出未完成';
      await _pushInboxMessage(
        type: 'export_record',
        title: '导出失败',
        summary: errorMessage!,
        status: '反馈',
      );
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> savePreference(UserPreference next) async {
    final reminderPolicyChanged =
        preference.reminderLeadMinutes != next.reminderLeadMinutes ||
        preference.reminderLeadDays != next.reminderLeadDays;
    preference = next;
    await _saveCurrentPreference();
    if (reminderPolicyChanged) {
      await _rebuildAgendaReminderPolicies();
    }
    statusMessage = '偏好已保存';
    notifyListeners();
  }

  Future<void> loginAccount(String account, String password) async {
    if (loginSubmitting) return;
    loginSubmitting = true;
    loginMessage = '';
    notifyListeners();
    final result = await accountRepository.login(account, password);
    loginSubmitting = false;
    loginMessage = result.message;
    notifyListeners();
    final user = result.user;
    if (user == null) return;
    await _enterAppWithUser(user);
  }

  Future<void> registerAccount(
    String account,
    String password,
    String nickname,
  ) async {
    if (loginSubmitting) return;
    loginSubmitting = true;
    loginMessage = '';
    notifyListeners();
    final result = await accountRepository.register(
      account,
      password,
      nickname,
    );
    loginSubmitting = false;
    loginMessage = result.message;
    notifyListeners();
    final user = result.user;
    if (user == null) return;
    await _enterAppWithUser(user);
  }

  Future<void> logoutAccount() async {
    await accountSessionService.clear();
    currentUser = null;
    preference = const UserPreference();
    currentTab = 0;
    _loadVisibleDataForCurrentAccount();
    loginMessage = '已退出登录';
    statusMessage = '';
    notifyListeners();
  }

  Future<void> saveAccountProfile({
    required String nickname,
    required String avatarPath,
    required String signature,
    required String birthday,
    required String school,
    required String age,
    required String gender,
    required String major,
    required String grade,
    required String hometown,
  }) async {
    final user = currentUser;
    if (user == null) return;
    final persistedAvatarPath = await _persistProfileAvatarIfNeeded(
      avatarPath: avatarPath,
      userId: user.id,
    );
    final updated = await accountRepository.updateProfile(
      userId: user.id,
      nicknameInput: nickname,
      avatarUriInput: persistedAvatarPath,
      signatureInput: signature,
      birthdayInput: birthday,
      schoolInput: school,
      ageInput: age,
      genderInput: gender,
      majorInput: major,
      gradeInput: grade,
      hometownInput: hometown,
    );
    if (updated == null) {
      errorMessage = '个人资料保存失败，请稍后重试';
      notifyListeners();
      return;
    }
    currentUser = updated;
    await accountSessionService.saveCurrentUser(updated);
    preference = _applyCurrentUserToPreference(preference, updated);
    await _saveCurrentPreference();
    await _syncAchievementUnlocks();
    errorMessage = null;
    statusMessage = '个人资料已更新';
    notifyListeners();
  }

  Future<void> rescheduleReminders() async {
    isBusy = true;
    notifyListeners();
    await _rebuildAgendaReminderPolicies();
    isBusy = false;
    statusMessage = '本地提醒已重新排程';
    notifyListeners();
  }

  Future<void> _rebuildAgendaReminderPolicies() async {
    final updated = <EventItem>[];
    for (final event in events) {
      await reminderService.cancelForEvent(event);
      final withPolicy = event.withReminderPolicy(preference);
      final scheduled = await reminderService.scheduleForEvent(withPolicy);
      updated.add(withPolicy.copyWith(reminders: scheduled));
    }
    events = updated;
    await _saveScopedEvents();
    await _syncAchievementUnlocks();
  }

  Future<void> clearPending() async {
    pendingNotices = [];
    await _saveScopedPendingNotices();
    statusMessage = '待确认列表已清空';
    notifyListeners();
  }

  Future<void> clearInboxMessages() async {
    inboxMessages = [];
    await _saveScopedInboxMessages();
    statusMessage = '通知中心已清空';
    notifyListeners();
  }

  Future<void> openExportRecord(ExportRecord record) async {
    final opened = await timelineExportService.open(record.path);
    if (opened) {
      errorMessage = null;
      statusMessage = '已打开导出文件';
    } else {
      errorMessage = '导出文件存在，但系统没有返回打开确认';
      statusMessage = '导出文件打开未完成';
    }
    notifyListeners();
  }

  Future<void> reparseEvent(EventItem event) async {
    final nowIso = DateTime.now().toIso8601String();
    final notice = ParsedNotice(
      id: event.id,
      title: event.title,
      eventType: event.eventType,
      startTimeIso: event.startTimeIso,
      deadlineIso: event.deadlineIso,
      location: event.location,
      description: event.description,
      source: event.source,
      confidence: event.confidence,
      reminderSuggestion: event.reminders.isEmpty
          ? '提前1天 / 提前1小时'
          : event.reminders.map((item) => item.label).join(' / '),
      status: '待确认',
      createdAtIso: nowIso,
      ownerAccount: currentAccountLabel,
    );
    pendingNotices = [
      notice,
      ...pendingNotices.where((item) => item.id != event.id),
    ];
    await _saveScopedPendingNotices();
    currentTab = 0;
    statusMessage = '已将事项送回待确认列表';
    await _pushInboxMessage(
      type: 'history_reparse',
      title: '已重新送回待确认',
      summary: '《${event.title}》已回到待确认列表，可再次校验。',
      status: '待处理',
    );
    notifyListeners();
  }

  List<EventItem> detectConflictsForNotice(ParsedNotice notice) {
    if (notice.action != NoticeAction.createEvent) return const [];
    final referenceTime = _referenceTimeForNotice(notice);
    if (referenceTime == null) return const [];
    final conflicts = <EventItem>[];
    for (final event in confirmedEvents) {
      if (event.id == notice.id) continue;
      final eventTime = event.startTime ?? event.deadline;
      if (eventTime == null) continue;
      final distance = eventTime.difference(referenceTime).inMinutes.abs();
      if (distance <= 60) {
        conflicts.add(event);
      }
    }
    conflicts.sort((left, right) {
      final leftTime = left.startTime ?? left.deadline ?? DateTime(9999);
      final rightTime = right.startTime ?? right.deadline ?? DateTime(9999);
      return leftTime.compareTo(rightTime);
    });
    return conflicts;
  }

  Future<bool> requestCameraAccess({bool notify = true}) async {
    final granted = await permissionService.requestCamera();
    await _refreshRuntimeStatus(notify: false);
    if (!granted) {
      errorMessage = '需要相机权限才能拍照识别，请先授权。';
    } else if (errorMessage == '需要相机权限才能拍照识别，请先授权。') {
      errorMessage = null;
    }
    if (notify) notifyListeners();
    return granted;
  }

  Future<void> refreshRuntimeStatus() async {
    await _refreshRuntimeStatus(notify: true);
  }

  String _buildInitialStatus() {
    if (pendingNotices.isNotEmpty) return '有 ${pendingNotices.length} 条事项待确认';
    if (todayEvents.isNotEmpty) return '今天有 ${todayEvents.length} 条安排';
    return '';
  }

  DateTime? _referenceTimeForNotice(ParsedNotice notice) {
    final start = ZhishiDateUtils.parse(notice.startTimeIso);
    if (start != null) return start;
    final deadline = ZhishiDateUtils.parse(notice.deadlineIso);
    return deadline;
  }

  Future<void> _refreshRuntimeStatus({required bool notify}) async {
    cameraPermissionReady = await permissionService.isCameraGranted();
    photosPermissionReady = await permissionService.isPhotosGranted();
    notificationPermissionReady = await permissionService
        .isNotificationGranted();
    microphonePermissionReady = await permissionService.isMicrophoneGranted();
    if (notify) notifyListeners();
  }

  Future<void> _pushInboxMessage({
    required String type,
    required String title,
    required String summary,
    required String status,
  }) async {
    final next = InboxMessage(
      id: '$type-${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      title: title,
      summary: summary,
      status: status,
      createdAtMillis: DateTime.now().millisecondsSinceEpoch,
      ownerAccount: currentAccountLabel,
    );
    inboxMessages = [next, ...inboxMessages].take(80).toList();
    await _saveScopedInboxMessages();
  }

  Future<void> _handleSharedImport(SharedImport import) async {
    if (!import.hasContent) return;
    currentTab = 0;
    statusMessage = import.sourceType == SourceType.shareImage
        ? '收到系统分享图片，正在识别'
        : '收到系统分享文本，正在解析';
    errorMessage = null;
    notifyListeners();
    await parseInput(
      rawText: import.rawText ?? '',
      imagePath: import.imagePath,
      sourceType: import.sourceType,
    );
  }

  void _handleShareReceiveError(Object error) {
    errorMessage = '系统分享接收失败：$error';
    statusMessage = '分享导入未完成';
    unawaited(
      _pushInboxMessage(
        type: 'share_feedback',
        title: '系统分享接收失败',
        summary: '$error',
        status: '反馈',
      ),
    );
    notifyListeners();
  }

  String get runtimeModelName => ApiConfig.modelName;

  bool get chatConfigReady => ApiConfig.hasChatConfig;

  bool get ocrConfigReady => ApiConfig.hasOcrConfig;

  String get chatEndpoint => ApiConfig.apiEndpoint;

  String get ocrEndpoint => ApiConfig.ocrEndpoint;

  void _loadVisibleDataForCurrentAccount() {
    final account = currentAccountLabel;
    events = allEvents
        .where((item) => _matchesAccount(item.ownerAccount, account))
        .toList();
    pendingNotices = allPendingNotices
        .where((item) => _matchesAccount(item.ownerAccount, account))
        .toList();
    inboxMessages = allInboxMessages
        .where((item) => _matchesAccount(item.ownerAccount, account))
        .toList();
    exportRecords = allExportRecords
        .where((item) => _matchesAccount(item.ownerAccount, account))
        .toList();
    achievementUnlocks = allAchievementUnlocks
        .where((item) => _matchesAccount(item.ownerAccount, account))
        .toList();
  }

  bool _matchesAccount(String ownerAccount, String account) {
    return ownerAccount == account || (ownerAccount.isEmpty && account.isEmpty);
  }

  Future<void> _saveScopedEvents() async {
    final account = currentAccountLabel;
    final scopedEvents = events
        .map((item) => item.copyWith(ownerAccount: account))
        .toList();
    allEvents =
        allEvents
            .where((item) => !_matchesAccount(item.ownerAccount, account))
            .toList()
          ..addAll(scopedEvents);
    await repository.saveEvents(allEvents);
  }

  Future<void> _saveScopedPendingNotices() async {
    final account = currentAccountLabel;
    final scopedNotices = pendingNotices
        .map((item) => item.copyWith(ownerAccount: account))
        .toList();
    allPendingNotices =
        allPendingNotices
            .where((item) => !_matchesAccount(item.ownerAccount, account))
            .toList()
          ..addAll(scopedNotices);
    await repository.savePendingNotices(allPendingNotices);
  }

  Future<void> _saveScopedInboxMessages() async {
    final account = currentAccountLabel;
    final scopedMessages = inboxMessages
        .map((item) => item.copyWith(ownerAccount: account))
        .toList();
    allInboxMessages =
        allInboxMessages
            .where((item) => !_matchesAccount(item.ownerAccount, account))
            .toList()
          ..addAll(scopedMessages);
    await repository.saveInboxMessages(allInboxMessages);
  }

  Future<void> _saveScopedExportRecords() async {
    final account = currentAccountLabel;
    final scopedRecords = exportRecords
        .map((item) => item.copyWith(ownerAccount: account))
        .toList();
    allExportRecords =
        allExportRecords
            .where((item) => !_matchesAccount(item.ownerAccount, account))
            .toList()
          ..addAll(scopedRecords);
    await repository.saveExportRecords(allExportRecords);
  }

  Future<void> _saveScopedAchievementUnlocks() async {
    final account = currentAccountLabel;
    final scopedRecords = achievementUnlocks
        .map((item) => item.copyWith(ownerAccount: account))
        .toList();
    allAchievementUnlocks =
        allAchievementUnlocks
            .where((item) => !_matchesAccount(item.ownerAccount, account))
            .toList()
          ..addAll(scopedRecords);
    await repository.saveAchievementUnlocks(allAchievementUnlocks);
  }

  Future<void> _saveCurrentPreference() async {
    await repository.savePreference(preference);
    final account = currentAccountLabel;
    if (account.isNotEmpty) {
      await repository.savePreferenceForAccount(account, preference);
    }
  }

  Future<void> _syncAchievementUnlocks({bool notifyInbox = true}) async {
    final account = currentAccountLabel;
    if (account.isEmpty) return;
    final existingIds = achievementUnlocks
        .map((record) => record.achievementId)
        .toSet();
    final newlyUnlocked = userInsights.achievements
        .where(
          (achievement) =>
              achievement.isUnlocked && !existingIds.contains(achievement.id),
        )
        .toList();
    if (newlyUnlocked.isEmpty) return;

    final now = DateTime.now();
    achievementUnlocks = [
      ...achievementUnlocks,
      for (final achievement in newlyUnlocked)
        AchievementUnlockRecord(
          achievementId: achievement.id,
          unlockedAtMillis:
              (achievement.unlockedAt ?? now).millisecondsSinceEpoch,
          ownerAccount: account,
        ),
    ];
    await _saveScopedAchievementUnlocks();
    if (!notifyInbox) return;

    final titles = newlyUnlocked
        .map((achievement) => achievement.title)
        .join('、');
    await _pushInboxMessage(
      type: 'achievement_unlocked',
      title: newlyUnlocked.length == 1 ? '解锁新成就' : '解锁多项成就',
      summary: '已解锁：$titles。成就状态已保存到当前账号。',
      status: '新解锁',
    );
  }

  Future<void> _enterAppWithUser(AccountUser user) async {
    currentUser = user;
    await accountSessionService.saveCurrentUser(user);
    await _claimUnownedDataForAccount(user.account);
    final scopedPreference = await repository.loadPreferenceForAccount(
      user.account,
    );
    preference = _applyCurrentUserToPreference(
      scopedPreference ?? const UserPreference(),
      user,
    );
    await _saveCurrentPreference();
    _loadVisibleDataForCurrentAccount();
    await _syncAchievementUnlocks(notifyInbox: false);
    statusMessage = _buildInitialStatus();
    notifyListeners();
  }

  Future<void> _claimUnownedDataForAccount(String account) async {
    if (account.isEmpty) return;
    var changed = false;
    allEvents = allEvents.map((item) {
      if (item.ownerAccount.isNotEmpty) return item;
      changed = true;
      return item.copyWith(ownerAccount: account);
    }).toList();
    allPendingNotices = allPendingNotices.map((item) {
      if (item.ownerAccount.isNotEmpty) return item;
      changed = true;
      return item.copyWith(ownerAccount: account);
    }).toList();
    allInboxMessages = allInboxMessages.map((item) {
      if (item.ownerAccount.isNotEmpty) return item;
      changed = true;
      return item.copyWith(ownerAccount: account);
    }).toList();
    allExportRecords = allExportRecords.map((item) {
      if (item.ownerAccount.isNotEmpty) return item;
      changed = true;
      return item.copyWith(ownerAccount: account);
    }).toList();
    if (!changed) return;
    await repository.saveEvents(allEvents);
    await repository.savePendingNotices(allPendingNotices);
    await repository.saveInboxMessages(allInboxMessages);
    await repository.saveExportRecords(allExportRecords);
  }

  UserPreference _applyCurrentUserToPreference(
    UserPreference base,
    AccountUser? user,
  ) {
    if (user == null) return base;
    return base.copyWith(
      nickname: user.nickname,
      avatarPath: user.avatarUri,
      signature: user.signature,
      birthday: user.birthday,
      school: user.school,
      age: user.age,
      gender: user.gender,
      major: user.major,
      grade: user.grade,
      hometown: user.hometown,
    );
  }

  Future<String> _persistProfileAvatarIfNeeded({
    required String avatarPath,
    required int userId,
  }) async {
    final trimmedPath = avatarPath.trim();
    if (trimmedPath.isEmpty) return '';
    final file = File(trimmedPath);
    if (!await file.exists()) return trimmedPath;
    final documents = await getApplicationDocumentsDirectory();
    final profileDir = Directory(p.join(documents.path, 'profile'));
    if (!await profileDir.exists()) {
      await profileDir.create(recursive: true);
    }
    if (p.equals(p.dirname(trimmedPath), profileDir.path)) {
      return trimmedPath;
    }
    final extension = p.extension(trimmedPath).trim().isEmpty
        ? '.jpg'
        : p.extension(trimmedPath);
    final target = File(
      p.join(
        profileDir.path,
        'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}$extension',
      ),
    );
    await file.copy(target.path);
    return target.path;
  }
}

extension FirstOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
