import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../models/event_item.dart';
import '../models/parsed_notice.dart';
import '../widgets/weaving_widgets.dart';
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
                  visibleBuckets: visibleBuckets,
                  reminderHeadline: _buildReminderHeadline(
                    controller: widget.controller,
                  ),
                  pendingNotice: pendingNotice,
                  onModeSelected: (mode) => setState(() => _activeMode = mode),
                  onOpenCalendar: () =>
                      setState(() => _showCalendarOverview = true),
                  onConfirmPending: pendingNotice == null
                      ? null
                      : () => widget.controller.confirmNoticeWithTransfer(
                          pendingNotice,
                        ),
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
    final nextAgenda = findNextTimelineEvent(confirmed);
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
      return '已经整理 ${confirmed.length} 条安排，已设置 '
          '${widget.controller.scheduledReminderCount} 项提醒';
    }
    return '还没有生成安排，可以从首页导入通知开始整理';
  }
}

class _TimelineMainView extends StatelessWidget {
  const _TimelineMainView({
    required this.controller,
    required this.activeMode,
    required this.visibleBuckets,
    required this.reminderHeadline,
    required this.pendingNotice,
    required this.onModeSelected,
    required this.onOpenCalendar,
    required this.onConfirmPending,
    required this.onCancelPending,
    required this.onItemTap,
  });

  final AppController controller;
  final TimelineMode activeMode;
  final List<TimelineDayBucket> visibleBuckets;
  final String reminderHeadline;
  final ParsedNotice? pendingNotice;
  final ValueChanged<TimelineMode> onModeSelected;
  final VoidCallback onOpenCalendar;
  final Future<void> Function()? onConfirmPending;
  final Future<void> Function()? onCancelPending;
  final ValueChanged<EventItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        Text(
          timelineHeaderTitle(),
          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
            fontSize: 21,
            height: 27 / 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: WeavingCard(
            color: AppColors.surfaceHigh.withValues(alpha: 0.92),
            child: Text(
              reminderHeadline,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(color: AppColors.primary),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _TimelineActionBar(
          activeMode: activeMode,
          onModeSelected: onModeSelected,
          onOpenCalendar: onOpenCalendar,
        ),
        if (pendingNotice != null) ...[
          const SizedBox(height: 10),
          _PendingTimelineCard(
            notice: pendingNotice!,
            onConfirm: onConfirmPending,
            onCancel: onCancelPending,
            onGoHome: () => controller.setTab(0),
          ),
        ],
        const SizedBox(height: 10),
        if (visibleBuckets.isEmpty)
          WeavingCard(
            color: AppColors.surfaceWarm,
            child: Column(
              children: [
                Text(
                  '暂无时间线安排',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '还没有确认的校园通知进入时间线，你可以先从首页导入通知，识别后再进行确认。',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
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
    required this.onModeSelected,
    required this.onOpenCalendar,
  });

  final TimelineMode activeMode;
  final ValueChanged<TimelineMode> onModeSelected;
  final VoidCallback onOpenCalendar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        WeavingCard(
          onTap: onOpenCalendar,
          interactionStyle: WeavingInteractionStyle.timelineSlide,
          color: AppColors.surfaceLowest.withValues(alpha: 0.92),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.mint,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '日历总览',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
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
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.surfaceLowest,
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
    required this.onConfirm,
    required this.onCancel,
    required this.onGoHome,
  });

  final ParsedNotice notice;
  final Future<void> Function()? onConfirm;
  final Future<void> Function()? onCancel;
  final VoidCallback onGoHome;

  @override
  Widget build(BuildContext context) {
    return WeavingCard(
      color: AppColors.surfaceWarm,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '最近提醒已备好，是否写入时间线？',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            buildTimelinePendingPrompt(notice),
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
                child: FilledButton(
                  onPressed: onGoHome,
                  child: const Text('回到首页'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onCancel == null ? null : () => onCancel!.call(),
              child: const Text('取消'),
            ),
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
              DateFormat('M月d日', 'zh_CN').format(bucket.date),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              DateFormat('EEEE', 'zh_CN').format(bucket.date),
              style: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
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
          final expired = _isExpired(event);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Text(
                      eventDisplayTimeLabel(event),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 32,
                        height: 38 / 32,
                        fontWeight: FontWeight.w900,
                        color: expired
                            ? AppColors.secondary
                            : AppColors.primary,
                      ),
                    ),
                    if (expired)
                      const Text(
                        '已过期',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 10.5,
                          height: 13 / 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    Container(
                      width: 4,
                      height: index == bucket.items.length - 1 ? 28 : 92,
                      decoration: BoxDecoration(
                        color: expired
                            ? AppColors.secondary.withValues(alpha: 0.35)
                            : AppColors.surfaceHighest,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: WeavingCard(
                    onTap: () => onItemTap(event),
                    interactionStyle: WeavingInteractionStyle.timelineSlide,
                    color: expired
                        ? AppColors.coral.withValues(alpha: 0.88)
                        : switch (index % 3) {
                            0 => AppColors.surfaceWarm,
                            1 => AppColors.coral,
                            _ => AppColors.gold,
                          },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (expired) ...[
                          const Text(
                            '日期已过',
                            style: TextStyle(
                              color: AppColors.secondary,
                              fontSize: 10.5,
                              height: 13 / 10.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          event.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          (event.location ?? '').trim().isEmpty
                              ? '地点待补全'
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

  bool _isExpired(EventItem event) {
    final schedule = timelineScheduleTime(event);
    return schedule != null && schedule.isBefore(DateTime.now());
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        Row(
          children: [
            _TimelineIconBubble(onTap: onBack),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '日历总览',
                    style: TextStyle(
                      fontFamily: 'PlusJakartaSans',
                      fontSize: 21,
                      height: 27 / 21,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '本月已织入 $totalInMonth 条安排',
                    style: const TextStyle(
                      fontSize: 10.5,
                      height: 13 / 10.5,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        WeavingCard(
          color: AppColors.surfaceLowest,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      timelineMonthTitle(activeMonth),
                      style: const TextStyle(
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 21,
                        height: 27 / 21,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  _CalendarArrowButton(label: '‹', onTap: onPrevMonth),
                  const SizedBox(width: 12),
                  _CalendarArrowButton(label: '›', onTap: onNextMonth),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const ['日', '一', '二', '三', '四', '五', '六']
                    .map(
                      (label) => SizedBox(
                        width: 44,
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
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          return _TimelinePressSurface(
                            onTap: date == null
                                ? null
                                : () => onDateSelected(date),
                            interactionStyle: WeavingInteractionStyle.iconGlow,
                            borderRadius: 12,
                            child: Container(
                              width: 44,
                              height: 76,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary
                                    : count > 0
                                    ? AppColors.surfaceWarm.withValues(
                                        alpha: 0.74,
                                      )
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
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
                                            fontFamily: 'PlusJakartaSans',
                                            fontSize: 18,
                                            height: 24 / 18,
                                            fontWeight: FontWeight.w800,
                                            color: selected
                                                ? Colors.white
                                                : AppColors.text,
                                          ),
                                        ),
                                        if (count > 0) ...[
                                          const SizedBox(height: 5),
                                          Wrap(
                                            spacing: 2,
                                            children: List.generate(
                                              count.clamp(0, 4),
                                              (_) => Container(
                                                width: 6,
                                                height: 6,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFF4C84A),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
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
        const SizedBox(height: 10),
        WeavingCard(
          color: AppColors.surfaceLowest.withValues(alpha: 0.9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                timelineDayTitle(selectedDate),
                style: const TextStyle(
                  fontFamily: 'PlusJakartaSans',
                  fontSize: 21,
                  height: 27 / 21,
                  fontWeight: FontWeight.w800,
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
                    child: _TimelinePressSurface(
                      borderRadius: 12,
                      interactionStyle: WeavingInteractionStyle.timelineSlide,
                      onTap: () => onItemTap(event),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.52),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.title,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.text,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${eventDisplayTimeLabel(event)} · '
                                    '${(event.location ?? '').trim().isEmpty ? '地点待补充' : event.location!}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(color: AppColors.muted),
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
    return _TimelinePressSurface(
      onTap: onTap,
      borderRadius: 99,
      interactionStyle: WeavingInteractionStyle.iconGlow,
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

class _TimelineIconBubble extends StatelessWidget {
  const _TimelineIconBubble({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceLowest,
      shape: CircleBorder(
        side: BorderSide(
          color: Colors.white.withValues(alpha: 0.64),
          width: 0.8,
        ),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const SizedBox.square(
          dimension: 44,
          child: Icon(
            Icons.arrow_back_rounded,
            size: 20,
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
  final ScrollController _scrollController = ScrollController();
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
    _scrollController.dispose();
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
        color: AppColors.background.withValues(alpha: 0.96),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 720),
              child: WeavingCard(
                color: AppColors.surfaceHigh.withValues(alpha: 0.96),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InfoChip(
                        label: _editing ? '日程详情 · 编辑中' : '日程详情',
                        icon: Icons.timeline_rounded,
                        backgroundColor: AppColors.mint,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _editing ? '校对这条日程' : event.title,
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 32,
                          height: 38 / 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _editing
                            ? '修改后的内容会直接写回时间线。'
                            : ((event.description ?? '').trim().isEmpty
                                  ? '这条事项已经沉淀到你的专属时间线中。'
                                  : event.description!),
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
                      ),
                      const SizedBox(height: 10),
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
                          icon: Icons.timeline_rounded,
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
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _DetailActionButton(
                              icon: Icons.edit_rounded,
                              title: '编辑',
                              summary: '校对字段',
                              color: AppColors.surfaceLowest,
                              onTap: () {
                                setState(() => _editing = true);
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (_scrollController.hasClients) {
                                    _scrollController.jumpTo(0);
                                  }
                                });
                              },
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
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: widget.onDismiss,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            shape: const StadiumBorder(),
                          ),
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
    return buildEditedTimelineEvent(
      original: original,
      title: _titleController.text,
      time: _timeController.text,
      location: _locationController.text,
      summary: _summaryController.text,
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

class _DetailEditField extends StatefulWidget {
  const _DetailEditField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;

  @override
  State<_DetailEditField> createState() => _DetailEditFieldState();
}

class _DetailEditFieldState extends State<_DetailEditField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChanged);
  }

  void _handleFocusChanged() => setState(() {});

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        cursorColor: AppColors.primary,
        style: Theme.of(context).textTheme.bodyLarge,
        maxLines: widget.maxLines,
        decoration: InputDecoration(
          labelText: widget.label,
          labelStyle: TextStyle(
            color: _focusNode.hasFocus ? AppColors.primary : AppColors.muted,
          ),
          filled: true,
          fillColor: Colors.white.withValues(
            alpha: _focusNode.hasFocus ? 0.46 : 0.28,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
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
    return _TimelinePressSurface(
      onTap: onTap,
      borderRadius: 20,
      interactionStyle: WeavingInteractionStyle.iconGlow,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.52),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    summary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppColors.muted),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
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
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.muted),
                ),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelinePressSurface extends StatefulWidget {
  const _TimelinePressSurface({
    required this.child,
    required this.onTap,
    required this.interactionStyle,
    required this.borderRadius,
  });

  final Widget child;
  final VoidCallback? onTap;
  final WeavingInteractionStyle interactionStyle;
  final double borderRadius;

  @override
  State<_TimelinePressSurface> createState() => _TimelinePressSurfaceState();
}

class _TimelinePressSurfaceState extends State<_TimelinePressSurface> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final pressedScale = switch (widget.interactionStyle) {
      WeavingInteractionStyle.primaryPress => 0.965,
      WeavingInteractionStyle.iconGlow => 0.92,
      _ => 0.985,
    };
    final pressedOffsetY = switch (widget.interactionStyle) {
      WeavingInteractionStyle.timelineSlide => 6.0,
      WeavingInteractionStyle.cardLift => 2.0,
      _ => 0.0,
    };
    final pressedOpacity =
        widget.interactionStyle == WeavingInteractionStyle.iconGlow
        ? 0.88
        : 1.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(end: widget.onTap != null && _pressed ? 1 : 0),
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      builder: (context, progress, child) => Transform.translate(
        offset: Offset(0, pressedOffsetY * progress),
        child: Transform.scale(
          scale: 1 - ((1 - pressedScale) * progress),
          child: Opacity(
            opacity: 1 - ((1 - pressedOpacity) * progress),
            child: child,
          ),
        ),
      ),
      child: Semantics(
        button: widget.onTap != null,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: widget.onTap == null
                ? null
                : (pressed) => setState(() => _pressed = pressed),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            child: widget.child,
          ),
        ),
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
