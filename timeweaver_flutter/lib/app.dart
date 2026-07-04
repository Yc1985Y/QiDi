import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'models/account_user.dart';
import 'models/event_item.dart';
import 'models/export_record.dart';
import 'models/inbox_message.dart';
import 'models/parsed_notice.dart';
import 'models/source_info.dart';
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
import 'services/share_receive_service.dart';
import 'services/speech_service.dart';
import 'services/storage_service.dart';
import 'services/timeline_export_service.dart';
import 'services/tts_service.dart';
import 'utils/date_utils.dart';
import 'utils/validators.dart';

class AppColors {
  static const primary = Color(0xFF003528);
  static const primarySoft = Color(0xFFB2EFD9);
  static const coral = Color(0xFFFFE0DC);
  static const gold = Color(0xFFFFEDC0);
  static const background = Color(0xFFFFF8F2);
  static const surface = Color(0xFFFFFCF8);
  static const surfaceWarm = Color(0xFFFFEBCB);
  static const text = Color(0xFF261900);
  static const muted = Color(0xFF5B6762);
  static const border = Color(0xFFF0E4D6);
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
          surface: AppColors.surface,
        ),
        scaffoldBackgroundColor: AppColors.background,
        fontFamily: 'Manrope',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontFamilyFallback: ['NotoSansSC'],
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
          headlineMedium: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontFamilyFallback: ['NotoSansSC'],
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
          titleMedium: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontFamilyFallback: ['NotoSansSC'],
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Manrope',
            fontFamilyFallback: ['NotoSansSC'],
            fontSize: 13,
            color: AppColors.text,
          ),
          labelLarge: TextStyle(
            fontFamily: 'Manrope',
            fontFamilyFallback: ['NotoSansSC'],
            fontSize: 13,
            fontWeight: FontWeight.w600,
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

        return Scaffold(
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
                : IndexedStack(index: controller.currentTab, children: pages),
          ),
          bottomNavigationBar: controller.currentUser == null
              ? null
              : NavigationBar(
                  selectedIndex: controller.currentTab,
                  backgroundColor: Colors.white,
                  indicatorColor: AppColors.primarySoft,
                  onDestinationSelected: controller.setTab,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: '首页',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.timeline_outlined),
                      selectedIcon: Icon(Icons.timeline_rounded),
                      label: '时间线',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline_rounded),
                      selectedIcon: Icon(Icons.person_rounded),
                      label: '我的',
                    ),
                  ],
                ),
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
      permissionService = PermissionService(),
      speechService = SpeechService(),
      ttsService = TtsService(),
      integrationService = IntegrationService(),
      shareReceiveService = ShareReceiveService(),
      timelineExportService = TimelineExportService();

  final EventRepository repository;
  final AccountRepository accountRepository;
  final AccountSessionService accountSessionService;
  final ParserService parserService;
  final ReminderService reminderService;
  final PermissionService permissionService;
  final SpeechService speechService;
  final TtsService ttsService;
  final IntegrationService integrationService;
  final ShareReceiveService shareReceiveService;
  final TimelineExportService timelineExportService;
  final ImagePicker _imagePicker = ImagePicker();

  bool initializing = true;
  bool isBusy = false;
  bool isVoiceListening = false;
  int currentTab = 0;
  String statusMessage = '等待导入校园通知';
  String? errorMessage;
  AccountUser? currentUser;
  String loginMessage = '';
  bool loginSubmitting = false;

  List<EventItem> allEvents = [];
  List<ParsedNotice> allPendingNotices = [];
  List<InboxMessage> allInboxMessages = [];
  List<ExportRecord> allExportRecords = [];
  List<EventItem> events = [];
  List<ParsedNotice> pendingNotices = [];
  List<InboxMessage> inboxMessages = [];
  List<ExportRecord> exportRecords = [];
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

  String get currentAccountLabel => currentUser?.account ?? '';

  Future<void> initialize() async {
    initializing = true;
    notifyListeners();
    await accountRepository.initialize();
    await accountRepository.ensureBuiltInTestAccount();
    await reminderService.initialize();
    await ttsService.initialize();
    currentUser = await accountSessionService.loadCurrentUser(
      accountRepository,
    );
    allEvents = await repository.loadEvents();
    allPendingNotices = await repository.loadPendingNotices();
    preference = await repository.loadPreference();
    allInboxMessages = await repository.loadInboxMessages();
    allExportRecords = await repository.loadExportRecords();
    if (currentUser != null) {
      await _claimUnownedDataForAccount(currentUser!.account);
      preference = _applyCurrentUserToPreference(preference, currentUser);
    }
    _loadVisibleDataForCurrentAccount();
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
    unawaited(shareReceiveService.dispose());
    unawaited(speechService.stop());
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
      notifyListeners();
      return;
    }

    isBusy = true;
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
      final notices = (await parserService.parseNotice(source: source))
          .map((item) => item.copyWith(ownerAccount: currentAccountLabel))
          .toList();
      if (notices.isEmpty) {
        errorMessage = '没有识别到可处理的校园事项';
        await _pushInboxMessage(
          type: 'parse_feedback',
          title: '解析结果为空',
          summary: '来源：${source.label}。没有识别到可处理的校园事项。',
          status: '反馈',
        );
      } else {
        pendingNotices = [...notices, ...pendingNotices];
        await _saveScopedPendingNotices();
        statusMessage = '已生成 ${notices.length} 条待确认事项';
        await _pushInboxMessage(
          type: 'parse_result',
          title: '已生成待确认事项',
          summary: '来源：${source.label}，共生成 ${notices.length} 条待确认事项。',
          status: '待处理',
        );
        await ttsService.speak(statusMessage);
      }
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      statusMessage = '解析未完成';
      await _pushInboxMessage(
        type: 'parse_feedback',
        title: '解析失败',
        summary: errorMessage!,
        status: '反馈',
      );
      await ttsService.speak(errorMessage!);
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<String?> confirmNotice(ParsedNotice notice) async {
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

    await reminderService.requestPermissions();
    await _refreshRuntimeStatus(notify: false);
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
    try {
      await integrationService.addEventToCalendar(event);
      statusMessage = '已加入时间线，并打开系统日历';
      errorMessage = null;
      await _pushInboxMessage(
        type: 'timeline_confirm',
        title: '事项已写入时间线',
        summary: '《${event.title}》已写入时间线，并已尝试打开系统日历。',
        status: '已处理',
      );
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      statusMessage = '已加入时间线，系统日历未完成';
      errorMessage = message;
      await _pushInboxMessage(
        type: 'timeline_confirm',
        title: '事项已写入时间线',
        summary: '《${event.title}》已写入时间线，但系统日历未完成：$message',
        status: '反馈',
      );
    }
    currentTab = 1;
    await ttsService.speak(errorMessage ?? '已加入时间线，并按你的提醒偏好排程');
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
    statusMessage = '时间线事项已更新';
    notifyListeners();
  }

  Future<void> deleteEvent(EventItem event) async {
    await reminderService.cancelForEvent(event);
    events = events.where((item) => item.id != event.id).toList();
    await _saveScopedEvents();
    statusMessage = '已从时间线删除';
    notifyListeners();
  }

  Future<void> duplicateEvent(EventItem event) async {
    final nowIso = DateTime.now().toIso8601String();
    final duplicateId =
        '${event.id}-copy-${DateTime.now().millisecondsSinceEpoch}';
    final duplicate = event.copyWith(
      id: duplicateId,
      title: '${event.title} 副本',
      createdAtIso: nowIso,
      updatedAtIso: nowIso,
      reminders: event.reminders
          .map(
            (reminder) => reminder.copyWith(
              id: '${reminder.id}-copy',
              eventId: duplicateId,
              scheduledAtIso: null,
              notificationId: null,
            ),
          )
          .toList(),
      ownerAccount: currentAccountLabel,
    );
    events = [duplicate, ...events];
    await _saveScopedEvents();
    statusMessage = '已复制事项';
    notifyListeners();
  }

  Future<void> startVoiceInput(ValueChanged<String> onText) async {
    if (isVoiceListening) return;
    isVoiceListening = true;
    errorMessage = null;
    statusMessage = '正在听写语音';
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
        statusMessage = recognizedAnyText ? '语音已转写，可继续解析' : '语音识别未返回文本';
        notifyListeners();
      },
    );
    await _refreshRuntimeStatus(notify: false);
  }

  Future<void> stopVoiceInput() async {
    if (!isVoiceListening) return;
    await speechService.stop();
    isVoiceListening = false;
    statusMessage = '语音已转写，可继续解析';
    notifyListeners();
  }

  Future<void> openMap(EventItem event) async {
    final opened = await integrationService.openMap(event);
    if (!opened) {
      errorMessage = '没有可打开的地点';
    } else {
      errorMessage = null;
      statusMessage = '已打开地图';
    }
    notifyListeners();
  }

  Future<void> shareEvent(EventItem event) async {
    await integrationService.shareEvent(event);
    statusMessage = '已调用系统分享';
    notifyListeners();
  }

  Future<void> copyEvent(EventItem event) async {
    await integrationService.copyEvent(event);
    statusMessage = '事项已复制到剪贴板';
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
      final result = await timelineExportService.export(
        confirmedEvents,
        format,
      );
      final opened = await timelineExportService.open(result.path);
      final record = ExportRecord(
        id: 'export-${DateTime.now().millisecondsSinceEpoch}',
        format: result.format.label,
        path: result.path,
        bytes: result.bytes,
        eventCount: confirmedEvents.length,
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
            '已导出 ${confirmedEvents.length} 条事项，格式：${result.format.label}，文件路径：${result.path}',
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
    await repository.savePreference(preference);
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
    currentTab = 0;
    _loadVisibleDataForCurrentAccount();
    loginMessage = '已退出登录';
    statusMessage = '等待导入校园通知';
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
    await repository.savePreference(preference);
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
      id: 'reparse-${event.id}-${DateTime.now().millisecondsSinceEpoch}',
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
    pendingNotices = [notice, ...pendingNotices];
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
    final referenceTime = _referenceTimeForNotice(notice);
    if (referenceTime == null) return const [];
    final conflicts = <EventItem>[];
    for (final event in confirmedEvents) {
      final eventTime = event.startTime ?? event.deadline;
      if (eventTime == null) continue;
      if (eventTime.year != referenceTime.year ||
          eventTime.month != referenceTime.month ||
          eventTime.day != referenceTime.day) {
        continue;
      }
      final distance = eventTime.difference(referenceTime).inMinutes.abs();
      if (distance <= 120) {
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
    return '等待导入校园通知';
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

  Future<void> _enterAppWithUser(AccountUser user) async {
    currentUser = user;
    await accountSessionService.saveCurrentUser(user);
    await _claimUnownedDataForAccount(user.account);
    preference = _applyCurrentUserToPreference(preference, user);
    _loadVisibleDataForCurrentAccount();
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
