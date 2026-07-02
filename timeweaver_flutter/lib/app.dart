import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'models/event_item.dart';
import 'models/parsed_notice.dart';
import 'models/source_info.dart';
import 'models/user_preference.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/timeline_page.dart';
import 'repositories/event_repository.dart';
import 'services/parser_service.dart';
import 'services/permission_service.dart';
import 'services/reminder_service.dart';
import 'services/integration_service.dart';
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
        fontFamily: Platform.isIOS ? '.SF Pro Text' : null,
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
          bodyMedium: TextStyle(fontSize: 13, color: AppColors.text),
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
                : IndexedStack(index: controller.currentTab, children: pages),
          ),
          bottomNavigationBar: NavigationBar(
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
      parserService = ParserService(),
      reminderService = ReminderService(),
      permissionService = PermissionService(),
      speechService = SpeechService(),
      ttsService = TtsService(),
      integrationService = IntegrationService(),
      shareReceiveService = ShareReceiveService(),
      timelineExportService = TimelineExportService();

  final EventRepository repository;
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

  List<EventItem> events = [];
  List<ParsedNotice> pendingNotices = [];
  UserPreference preference = const UserPreference();

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

  Future<void> initialize() async {
    initializing = true;
    notifyListeners();
    await reminderService.initialize();
    await ttsService.initialize();
    events = await repository.loadEvents();
    pendingNotices = await repository.loadPendingNotices();
    preference = await repository.loadPreference();
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
        ? await permissionService.requestCamera()
        : await permissionService.requestPhotos();
    if (!granted) {
      errorMessage = type == SourceType.camera ? '相机权限未开启' : '相册权限未开启';
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
      errorMessage = '请先输入通知文字或选择图片';
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
      final notices = await parserService.parseNotice(source: source);
      if (notices.isEmpty) {
        errorMessage = '没有识别到可处理的校园事项';
      } else {
        pendingNotices = [...notices, ...pendingNotices];
        await repository.savePendingNotices(pendingNotices);
        statusMessage = '已生成 ${notices.length} 条待确认事项';
        await ttsService.speak(statusMessage);
      }
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      statusMessage = '解析未完成';
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
      notifyListeners();
      return blocker;
    }

    await reminderService.requestPermissions();
    var event = EventItem.fromParsedNotice(notice, preference);
    final scheduled = await reminderService.scheduleForEvent(event);
    event = event.copyWith(reminders: scheduled);
    pendingNotices = pendingNotices
        .where((item) => item.id != notice.id)
        .toList();
    events = [event, ...events.where((item) => item.id != event.id)];
    await repository.savePendingNotices(pendingNotices);
    await repository.saveEvents(events);
    try {
      await integrationService.addEventToCalendar(event);
      statusMessage = '已加入时间线，并打开系统日历';
      errorMessage = null;
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      statusMessage = '已加入时间线，系统日历未完成';
      errorMessage = message;
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
    await repository.savePendingNotices(pendingNotices);
    statusMessage = '已丢弃待确认事项';
    await ttsService.speak(statusMessage);
    notifyListeners();
  }

  Future<void> updatePendingNotice(ParsedNotice notice) async {
    pendingNotices = pendingNotices
        .map((item) => item.id == notice.id ? notice : item)
        .toList();
    await repository.savePendingNotices(pendingNotices);
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
    await repository.saveEvents(events);
    statusMessage = '时间线事项已更新';
    notifyListeners();
  }

  Future<void> deleteEvent(EventItem event) async {
    await reminderService.cancelForEvent(event);
    events = events.where((item) => item.id != event.id).toList();
    await repository.saveEvents(events);
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
    );
    events = [duplicate, ...events];
    await repository.saveEvents(events);
    statusMessage = '已复制事项';
    notifyListeners();
  }

  Future<void> startVoiceInput(ValueChanged<String> onText) async {
    if (isVoiceListening) return;
    isVoiceListening = true;
    errorMessage = null;
    statusMessage = '正在听写语音';
    notifyListeners();
    await speechService.listen(
      onText: onText,
      onError: (message) {
        errorMessage = message;
        statusMessage = '语音识别未完成';
        isVoiceListening = false;
        notifyListeners();
      },
    );
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

  Future<void> exportTimelinePdf() async {
    isBusy = true;
    errorMessage = null;
    statusMessage = '正在导出时间线 PDF';
    notifyListeners();
    try {
      final result = await timelineExportService.exportPdf(confirmedEvents);
      final opened = await timelineExportService.open(result.path);
      statusMessage = '时间线 PDF 已导出：${result.path}';
      if (!opened) {
        errorMessage = 'PDF 已导出，但系统没有返回打开确认';
      }
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      statusMessage = 'PDF 导出未完成';
    } finally {
      isBusy = false;
      notifyListeners();
    }
  }

  Future<void> savePreference(UserPreference next) async {
    preference = next;
    await repository.savePreference(preference);
    statusMessage = '偏好已保存';
    notifyListeners();
  }

  Future<void> rescheduleReminders() async {
    isBusy = true;
    notifyListeners();
    final updated = <EventItem>[];
    for (final event in events) {
      await reminderService.cancelForEvent(event);
      final scheduled = await reminderService.scheduleForEvent(event);
      updated.add(event.copyWith(reminders: scheduled));
    }
    events = updated;
    await repository.saveEvents(events);
    isBusy = false;
    statusMessage = '本地提醒已重新排程';
    notifyListeners();
  }

  Future<void> clearPending() async {
    pendingNotices = [];
    await repository.savePendingNotices(pendingNotices);
    statusMessage = '待确认列表已清空';
    notifyListeners();
  }

  String _buildInitialStatus() {
    if (pendingNotices.isNotEmpty) return '有 ${pendingNotices.length} 条事项待确认';
    if (todayEvents.isNotEmpty) return '今天有 ${todayEvents.length} 条安排';
    return '等待导入校园通知';
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
    notifyListeners();
  }
}

extension FirstOrNullExtension<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
