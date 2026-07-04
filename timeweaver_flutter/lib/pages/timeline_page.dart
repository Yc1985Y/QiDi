import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../models/event_item.dart';
import '../models/parsed_notice.dart';
import '../services/timeline_export_service.dart';
import '../utils/date_utils.dart';
import '../widgets/empty_state.dart';
import '../widgets/weaving_widgets.dart';
import 'review_page.dart';
import 'timeline_logic.dart';

class TimelinePage extends StatefulWidget {
  const TimelinePage({super.key, required this.controller});

  final AppController controller;

  @override
  State<TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends State<TimelinePage> {
  TimelineMode _activeMode = TimelineMode.week;
  DateTime? _selectedDateOverride;
  DateTime? _activeMonthOverride;
  bool _showCalendarOverview = false;
  EventItem? _detailEvent;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final groupedItems = groupEventsByDay(
          widget.controller.confirmedEvents,
        );
        final now = DateTime.now();
        final selectedDate =
            _selectedDateOverride ?? groupedItems.firstOrNull?.date ?? now;
        final activeMonth =
            _activeMonthOverride ??
            DateTime(selectedDate.year, selectedDate.month);
        final activeMonthAgendaCount = groupedItems
            .where(
              (bucket) =>
                  bucket.date.year == activeMonth.year &&
                  bucket.date.month == activeMonth.month,
            )
            .fold<int>(0, (sum, bucket) => sum + bucket.items.length);
        final visibleBuckets = buildVisibleBuckets(
          groupedItems: groupedItems,
          activeMode: _activeMode,
          activeDate: selectedDate,
          activeMonth: activeMonth,
        );
        final pendingNotice = widget.controller.pendingNotices.firstOrNull;

        return WeavingBackground(
          child: Stack(
            children: [
              if (_showCalendarOverview)
                _TimelineCalendarOverview(
                  selectedDate: selectedDate,
                  activeMonth: activeMonth,
                  groupedItems: groupedItems,
                  onBack: () => setState(() => _showCalendarOverview = false),
                  onPrevMonth: () => setState(
                    () => _activeMonthOverride = DateTime(
                      activeMonth.year,
                      activeMonth.month - 1,
                    ),
                  ),
                  onNextMonth: () => setState(
                    () => _activeMonthOverride = DateTime(
                      activeMonth.year,
                      activeMonth.month + 1,
                    ),
                  ),
                  onDateSelected: (date) => setState(() {
                    _selectedDateOverride = date;
                    _activeMonthOverride = DateTime(date.year, date.month);
                  }),
                  onItemTap: (event) => setState(() => _detailEvent = event),
                )
              else
                _TimelineMainView(
                  controller: widget.controller,
                  activeMode: _activeMode,
                  activeMonthAgendaCount: activeMonthAgendaCount,
                  visibleBuckets: visibleBuckets,
                  reminderHeadline: _buildReminderHeadline(
                    controller: widget.controller,
                  ),
                  pendingNotice: pendingNotice,
                  onModeSelected: (mode) => setState(() => _activeMode = mode),
                  onOpenCalendar: () =>
                      setState(() => _showCalendarOverview = true),
                  onOpenPendingReview: pendingNotice == null
                      ? null
                      : () => _openReviewPage(context, pendingNotice),
                  onConfirmPending: pendingNotice == null
                      ? null
                      : () => widget.controller.confirmNotice(pendingNotice),
                  onCancelPending: pendingNotice == null
                      ? null
                      : () => widget.controller.discardNotice(pendingNotice),
                  onItemTap: (event) => setState(() => _detailEvent = event),
                ),
              if (_detailEvent != null)
                _TimelineDetailOverlay(
                  item: _detailEvent!,
                  onDismiss: () => setState(() => _detailEvent = null),
                  onUpdate: (event) async {
                    await widget.controller.updateEvent(event);
                    if (!mounted) return;
                    setState(() => _detailEvent = event);
                  },
                  onDelete: (event) async {
                    await widget.controller.deleteEvent(event);
                    if (!mounted) return;
                    setState(() => _detailEvent = null);
                  },
                  onDuplicate: (event) =>
                      widget.controller.duplicateEvent(event),
                  onNavigate: (event) => widget.controller.openMap(event),
                  onShare: (event) => widget.controller.shareEvent(event),
                  onCopy: (event) => widget.controller.copyEvent(event),
                ),
            ],
          ),
        );
      },
    );
  }

  String _buildReminderHeadline({required AppController controller}) {
    final confirmed = controller.confirmedEvents;
    final nextAgenda = confirmed.where((item) {
      final time = timelineScheduleTime(item);
      return time != null && !time.isBefore(DateTime.now());
    }).firstOrNull;
    if (nextAgenda != null) {
      final dateText = timelineScheduleTime(nextAgenda) == null
          ? eventDisplayTimeLabel(nextAgenda)
          : DateFormat(
              'M月d日 HH:mm',
              'zh_CN',
            ).format(timelineScheduleTime(nextAgenda)!);
      return '$dateText · ${nextAgenda.title} · '
          '${(nextAgenda.location ?? '').trim().isEmpty ? '地点待补充' : nextAgenda.location!}';
    }
    if (controller.nextReminderText.trim().isNotEmpty) {
      return controller.nextReminderText;
    }
    if (confirmed.isNotEmpty) {
      return '已沉淀 ${confirmed.length} 条安排，其中 '
          '${widget.controller.scheduledReminderCount} 项仍有后续提醒。';
    }
    return '还没有新的提醒，确认一条校园通知后会在这里出现。';
  }

  Future<void> _openReviewPage(
    BuildContext context,
    ParsedNotice notice,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            ReviewPage(controller: widget.controller, notice: notice),
      ),
    );
  }
}

class _TimelineMainView extends StatelessWidget {
  const _TimelineMainView({
    required this.controller,
    required this.activeMode,
    required this.activeMonthAgendaCount,
    required this.visibleBuckets,
    required this.reminderHeadline,
    required this.pendingNotice,
    required this.onModeSelected,
    required this.onOpenCalendar,
    required this.onOpenPendingReview,
    required this.onConfirmPending,
    required this.onCancelPending,
    required this.onItemTap,
  });

  final AppController controller;
  final TimelineMode activeMode;
  final int activeMonthAgendaCount;
  final List<TimelineDayBucket> visibleBuckets;
  final String reminderHeadline;
  final ParsedNotice? pendingNotice;
  final ValueChanged<TimelineMode> onModeSelected;
  final VoidCallback onOpenCalendar;
  final VoidCallback? onOpenPendingReview;
  final Future<void> Function()? onConfirmPending;
  final Future<void> Function()? onCancelPending;
  final ValueChanged<EventItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                timelineHeaderTitle(),
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            PopupMenuButton<TimelineExportFormat>(
              tooltip: '导出时间线',
              enabled: controller.confirmedEvents.isNotEmpty,
              onSelected: (format) {
                switch (format) {
                  case TimelineExportFormat.pdf:
                    controller.exportTimelinePdf();
                  case TimelineExportFormat.png:
                    controller.exportTimelinePng();
                  case TimelineExportFormat.jpg:
                    controller.exportTimelineJpg();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: TimelineExportFormat.pdf,
                  child: Text('导出 PDF'),
                ),
                PopupMenuItem(
                  value: TimelineExportFormat.png,
                  child: Text('导出 PNG'),
                ),
                PopupMenuItem(
                  value: TimelineExportFormat.jpg,
                  child: Text('导出 JPG'),
                ),
              ],
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  Icons.download_rounded,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              tooltip: '返回首页',
              onPressed: () => controller.setTab(0),
              icon: const Icon(Icons.home_rounded),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StatusStrip(
          message: controller.statusMessage,
          error: controller.errorMessage,
          busy: controller.isBusy,
        ),
        const SizedBox(height: 14),
        WeavingCard(
          color: Colors.white.withValues(alpha: 0.84),
          child: Text(
            reminderHeadline,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(height: 14),
        _TimelineActionBar(
          activeMode: activeMode,
          activeMonthAgendaCount: activeMonthAgendaCount,
          onModeSelected: onModeSelected,
          onOpenCalendar: onOpenCalendar,
        ),
        if (pendingNotice != null) ...[
          const SizedBox(height: 14),
          _PendingTimelineCard(
            notice: pendingNotice!,
            onOpenReview: onOpenPendingReview,
            onConfirm: onConfirmPending,
            onCancel: onCancelPending,
            onGoHome: () => controller.setTab(0),
          ),
        ],
        const SizedBox(height: 14),
        if (visibleBuckets.isEmpty)
          EmptyState(
            title: controller.confirmedEvents.isEmpty
                ? '这一段时间还没有安排'
                : '当前视图暂无安排',
            summary: controller.confirmedEvents.isEmpty
                ? '从首页导入截图、拍照、语音或文本后，确认过的事项会按时间顺序沉淀到这里。'
                : '切换到本日、本周、本月或日历总览后再查看。',
            actionLabel: '去首页',
            onAction: () => controller.setTab(0),
          )
        else
          ...visibleBuckets.map(
            (bucket) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: _TimelineDayGroup(bucket: bucket, onItemTap: onItemTap),
            ),
          ),
      ],
    );
  }
}

class _TimelineActionBar extends StatelessWidget {
  const _TimelineActionBar({
    required this.activeMode,
    required this.activeMonthAgendaCount,
    required this.onModeSelected,
    required this.onOpenCalendar,
  });

  final TimelineMode activeMode;
  final int activeMonthAgendaCount;
  final ValueChanged<TimelineMode> onModeSelected;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        WeavingCard(
          onTap: onOpenCalendar,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '日历总览',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '本月已织入 $activeMonthAgendaCount 条安排',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '当前${activeMode.label}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(99),
          ),
          child: Row(
            children: TimelineMode.values.map((mode) {
              final active = mode == activeMode;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onModeSelected(mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      mode.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: active ? Colors.white : AppColors.muted,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _PendingTimelineCard extends StatelessWidget {
  const _PendingTimelineCard({
    required this.notice,
    required this.onOpenReview,
    required this.onConfirm,
    required this.onCancel,
    required this.onGoHome,
  });

  final ParsedNotice notice;
  final VoidCallback? onOpenReview;
  final Future<void> Function()? onConfirm;
  final Future<void> Function()? onCancel;
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    return WeavingCard(
      onTap: onOpenReview,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '还有一条待确认事项',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            notice.title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            [
              if (notice.startTimeIso != null &&
                  notice.startTimeIso!.trim().isNotEmpty)
                ZhishiDateUtils.formatDateTime(notice.startTimeIso),
              if (notice.location != null && notice.location!.trim().isNotEmpty)
                notice.location!,
            ].join(' · '),
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onConfirm == null ? null : () => onConfirm!.call(),
                  child: const Text('确认写入'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onGoHome,
                  child: const Text('返回首页'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onOpenReview,
                  child: const Text('去校验'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onCancel == null ? null : () => onCancel!.call(),
                  child: const Text('取消'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineDayGroup extends StatelessWidget {
  const _TimelineDayGroup({required this.bucket, required this.onItemTap});

  final TimelineDayBucket bucket;
  final ValueChanged<EventItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${bucket.date.day}',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              DateFormat('M月 EEEE', 'zh_CN').format(bucket.date),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...bucket.items.asMap().entries.map((entry) {
          final index = entry.key;
          final event = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 64,
                  child: Column(
                    children: [
                      Text(
                        eventDisplayTimeLabel(event),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 4,
                        height: index == bucket.items.length - 1 ? 30 : 94,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE4D8CA),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: WeavingCard(
                    onTap: () => onItemTap(event),
                    color: switch (index % 3) {
                      0 => Colors.white.withValues(alpha: 0.86),
                      1 => AppColors.coral,
                      _ => AppColors.gold,
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (event.location ?? '').trim().isEmpty
                              ? '地点待补充'
                              : event.location!,
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _TimelineCalendarOverview extends StatelessWidget {
  const _TimelineCalendarOverview({
    required this.selectedDate,
    required this.activeMonth,
    required this.groupedItems,
    required this.onBack,
    required this.onPrevMonth,
    required this.onNextMonth,
    required this.onDateSelected,
    required this.onItemTap,
  });

  final DateTime selectedDate;
  final DateTime activeMonth;
  final List<TimelineDayBucket> groupedItems;
  final VoidCallback onBack;
  final VoidCallback onPrevMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<EventItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    final selectedBucket = groupedItems.firstWhereOrNull(
      (item) =>
          item.date.year == selectedDate.year &&
          item.date.month == selectedDate.month &&
          item.date.day == selectedDate.day,
    );
    final totalInMonth = groupedItems
        .where(
          (item) =>
              item.date.year == activeMonth.year &&
              item.date.month == activeMonth.month,
        )
        .fold<int>(0, (sum, item) => sum + item.items.length);
    final matrix = timelineMonthMatrix(activeMonth);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: onBack,
              tooltip: '返回',
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '日历总览',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '本月已织入 $totalInMonth 条安排',
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        WeavingCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      timelineMonthTitle(activeMonth),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  _CalendarArrowButton(label: '<', onTap: onPrevMonth),
                  const SizedBox(width: 10),
                  _CalendarArrowButton(label: '>', onTap: onNextMonth),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: const ['日', '一', '二', '三', '四', '五', '六']
                    .map(
                      (label) => Expanded(
                        child: Center(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              ...matrix
                  .map((item) => item)
                  .toList()
                  .slices(7)
                  .map(
                    (row) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: row.map((date) {
                          final selected =
                              date != null &&
                              date.year == selectedDate.year &&
                              date.month == selectedDate.month &&
                              date.day == selectedDate.day;
                          final count = date == null
                              ? 0
                              : groupedItems
                                        .firstWhereOrNull(
                                          (item) =>
                                              item.date.year == date.year &&
                                              item.date.month == date.month &&
                                              item.date.day == date.day,
                                        )
                                        ?.items
                                        .length ??
                                    0;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 2,
                              ),
                              child: GestureDetector(
                                onTap: date == null
                                    ? null
                                    : () => onDateSelected(date),
                                child: Container(
                                  height: 74,
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.primary
                                        : count > 0
                                        ? Colors.white.withValues(alpha: 0.72)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: date == null
                                      ? null
                                      : Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '${date.day}',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w900,
                                                color: selected
                                                    ? Colors.white
                                                    : AppColors.text,
                                              ),
                                            ),
                                            if (count > 0) ...[
                                              const SizedBox(height: 6),
                                              Wrap(
                                                spacing: 2,
                                                children: List.generate(
                                                  count.clamp(0, 4),
                                                  (_) => Container(
                                                    width: 6,
                                                    height: 6,
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Color(
                                                            0xFFF4C84A,
                                                          ),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        WeavingCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timelineDayTitle(selectedDate),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 10),
              if (selectedBucket == null || selectedBucket.items.isEmpty)
                const Text(
                  '这一天暂时没有安排。',
                  style: TextStyle(color: AppColors.muted),
                )
              else
                ...selectedBucket.items.map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => onItemTap(event),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.text,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${eventDisplayTimeLabel(event)} · '
                                    '${(event.location ?? '').trim().isEmpty ? '地点待补充' : event.location!}',
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CalendarArrowButton extends StatelessWidget {
  const _CalendarArrowButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceWarm,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class _TimelineDetailOverlay extends StatefulWidget {
  const _TimelineDetailOverlay({
    required this.item,
    required this.onDismiss,
    required this.onUpdate,
    required this.onDelete,
    required this.onDuplicate,
    required this.onNavigate,
    required this.onShare,
    required this.onCopy,
  });

  final EventItem item;
  final VoidCallback onDismiss;
  final Future<void> Function(EventItem event) onUpdate;
  final Future<void> Function(EventItem event) onDelete;
  final Future<void> Function(EventItem event) onDuplicate;
  final Future<void> Function(EventItem event) onNavigate;
  final Future<void> Function(EventItem event) onShare;
  final Future<void> Function(EventItem event) onCopy;

  @override
  State<_TimelineDetailOverlay> createState() => _TimelineDetailOverlayState();
}

class _TimelineDetailOverlayState extends State<_TimelineDetailOverlay> {
  bool _editing = false;
  late final TextEditingController _titleController;
  late final TextEditingController _timeController;
  late final TextEditingController _locationController;
  late final TextEditingController _summaryController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _timeController = TextEditingController(
      text: widget.item.startTimeIso ?? widget.item.deadlineIso ?? '',
    );
    _locationController = TextEditingController(
      text: widget.item.location ?? '',
    );
    _summaryController = TextEditingController(
      text: widget.item.description ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _TimelineDetailOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id == widget.item.id) return;
    _editing = false;
    _titleController.text = widget.item.title;
    _timeController.text =
        widget.item.startTimeIso ?? widget.item.deadlineIso ?? '';
    _locationController.text = widget.item.location ?? '';
    _summaryController.text = widget.item.description ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _timeController.dispose();
    _locationController.dispose();
    _summaryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.item;
    return Positioned.fill(
      child: Material(
        color: AppColors.background.withValues(alpha: 0.95),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
              child: WeavingCard(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoChip(
                        label: _editing ? '日程详情 · 编辑中' : '日程详情',
                        icon: Icons.timeline_rounded,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _editing ? '校对这条日程' : event.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _editing
                            ? '修改后的内容会直接写回时间线。'
                            : ((event.description ?? '').trim().isEmpty
                                  ? '这条事项已经沉淀到你的专属时间线中。'
                                  : event.description!),
                        style: const TextStyle(
                          color: AppColors.muted,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_editing) ...[
                        _DetailEditField(
                          label: '标题',
                          controller: _titleController,
                        ),
                        _DetailEditField(
                          label: '时间',
                          controller: _timeController,
                        ),
                        _DetailEditField(
                          label: '地点',
                          controller: _locationController,
                        ),
                        _DetailEditField(
                          label: '摘要',
                          controller: _summaryController,
                          maxLines: 3,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: _DetailActionButton(
                                icon: Icons.save_rounded,
                                title: '保存',
                                summary: '写回时间线',
                                color: AppColors.primarySoft,
                                onTap: () {
                                  _saveEditedEvent(event);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _DetailActionButton(
                                icon: Icons.timeline_rounded,
                                title: '取消',
                                summary: '保留原内容',
                                color: Colors.white,
                                onTap: () {
                                  _resetDrafts(event);
                                  setState(() => _editing = false);
                                },
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        _DetailRow(
                          icon: Icons.calendar_month_rounded,
                          label: '时间',
                          value: eventExportTimeLabel(event),
                        ),
                        const SizedBox(height: 10),
                        _DetailRow(
                          icon: Icons.location_on_rounded,
                          label: '地点',
                          value: (event.location ?? '').trim().isEmpty
                              ? '地点待补充'
                              : event.location!,
                        ),
                        const SizedBox(height: 10),
                        _DetailRow(
                          icon: Icons.notifications_active_rounded,
                          label: '提醒',
                          value: eventReminderSummary(event),
                        ),
                        const SizedBox(height: 10),
                        _DetailRow(
                          icon: Icons.file_open_rounded,
                          label: '来源',
                          value: event.source.label.trim().isEmpty
                              ? '校园通知导入'
                              : event.source.label,
                        ),
                        const SizedBox(height: 10),
                        _DetailRow(
                          icon: Icons.query_stats_rounded,
                          label: '状态',
                          value: event.status.trim().isEmpty
                              ? '已沉淀'
                              : event.status,
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _DetailActionButton(
                              icon: Icons.edit_rounded,
                              title: '编辑',
                              summary: '校对字段',
                              color: AppColors.surfaceWarm,
                              onTap: () => setState(() => _editing = true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DetailActionButton(
                              icon: Icons.location_on_rounded,
                              title: '导航',
                              summary: '打开地图',
                              color: AppColors.gold,
                              onTap: () {
                                widget.onNavigate(event);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _DetailActionButton(
                              icon: Icons.content_copy_rounded,
                              title: '复制',
                              summary: '复制摘要',
                              color: Colors.white,
                              onTap: () {
                                widget.onCopy(event);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DetailActionButton(
                              icon: Icons.share_rounded,
                              title: '分享',
                              summary: '发给同学',
                              color: AppColors.coral,
                              onTap: () {
                                widget.onShare(event);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _DetailActionButton(
                              icon: Icons.add_circle_rounded,
                              title: '复制成新事项',
                              summary: '生成副本',
                              color: AppColors.primarySoft,
                              onTap: () {
                                widget.onDuplicate(event);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _DetailActionButton(
                              icon: Icons.delete_rounded,
                              title: '删除',
                              summary: '移出时间线',
                              color: AppColors.coral,
                              onTap: () {
                                widget.onDelete(event);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: widget.onDismiss,
                          child: const Text('关闭详情'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  EventItem _buildEditedEvent(EventItem original) {
    final title = _titleController.text.trim();
    final time = _timeController.text.trim();
    final location = _locationController.text.trim();
    final summary = _summaryController.text.trim();
    return original.copyWith(
      title: title.isEmpty ? original.title : title,
      startTimeIso: time.isEmpty ? null : time,
      location: location.isEmpty ? null : location,
      description: summary.isEmpty ? null : summary,
      source: original.source,
      updatedAtIso: DateTime.now().toIso8601String(),
    );
  }

  Future<void> _saveEditedEvent(EventItem event) async {
    final updated = _buildEditedEvent(event);
    await widget.onUpdate(updated);
    if (!mounted) return;
    setState(() => _editing = false);
  }

  void _resetDrafts(EventItem event) {
    _titleController.text = event.title;
    _timeController.text = event.startTimeIso ?? event.deadlineIso ?? '';
    _locationController.text = event.location ?? '';
    _summaryController.text = event.description ?? '';
  }
}

class _DetailEditField extends StatelessWidget {
  const _DetailEditField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.72),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.border),
          ),
        ),
      ),
    );
  }
}

class _DetailActionButton extends StatelessWidget {
  const _DetailActionButton({
    required this.icon,
    required this.title,
    required this.summary,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String summary;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppColors.gold,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

extension _IterableSearchExtension<E> on Iterable<E> {
  E? firstWhereOrNull(bool Function(E element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

extension _SliceExtension<E> on List<E> {
  Iterable<List<E>> slices(int size) sync* {
    for (var index = 0; index < length; index += size) {
      final end = index + size > length ? length : index + size;
      yield sublist(index, end);
    }
  }
}
