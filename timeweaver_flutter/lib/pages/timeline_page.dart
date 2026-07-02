import 'package:flutter/material.dart';

import '../app.dart';
import '../models/event_item.dart';
import '../models/source_info.dart';
import '../utils/date_utils.dart';
import '../widgets/empty_state.dart';
import '../widgets/timeline_item.dart';
import '../widgets/weaving_widgets.dart';

class TimelinePage extends StatelessWidget {
  const TimelinePage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final buckets = _groupByDay(controller.confirmedEvents);
    return WeavingBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '时间线',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              IconButton.filledTonal(
                tooltip: '导出 PDF',
                onPressed: controller.confirmedEvents.isEmpty
                    ? null
                    : controller.exportTimelinePdf,
                icon: const Icon(Icons.picture_as_pdf_rounded),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: '回到首页',
                onPressed: () => controller.setTab(0),
                icon: const Icon(Icons.add_task_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StatusStrip(
            message: controller.nextReminderText,
            error: controller.errorMessage,
            busy: controller.isBusy,
          ),
          const SizedBox(height: 14),
          if (controller.pendingNotices.isNotEmpty)
            WeavingCard(
              color: AppColors.gold,
              onTap: () => controller.setTab(0),
              child: Row(
                children: [
                  const Icon(
                    Icons.pending_actions_rounded,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${controller.pendingNotices.length} 条事项待确认',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          if (controller.pendingNotices.isNotEmpty) const SizedBox(height: 14),
          if (buckets.isEmpty)
            EmptyState(
              title: '暂无时间线事项',
              summary: '确认后的校园事项会按日期自动归档。',
              actionLabel: '去首页',
              onAction: () => controller.setTab(0),
            )
          else
            ...buckets.entries.map(
              (entry) => _DaySection(
                date: entry.key,
                events: entry.value,
                controller: controller,
              ),
            ),
        ],
      ),
    );
  }

  Map<DateTime, List<EventItem>> _groupByDay(List<EventItem> events) {
    final map = <DateTime, List<EventItem>>{};
    for (final event in events) {
      final date = event.startTime;
      final key = date == null
          ? DateTime(9999)
          : DateTime(date.year, date.month, date.day);
      map.putIfAbsent(key, () => []).add(event);
    }
    final entries = map.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return {for (final entry in entries) entry.key: entry.value};
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.date,
    required this.events,
    required this.controller,
  });

  final DateTime date;
  final List<EventItem> events;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final title = date.year == 9999 ? '待补时间' : ZhishiDateUtils.formatDay(date);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 10),
          ...events.map(
            (event) => TimelineItem(
              event: event,
              onEdit: () => _showEventEditor(context, controller, event),
              onDelete: () => controller.deleteEvent(event),
              onDuplicate: () => controller.duplicateEvent(event),
              onNavigate: () => controller.openMap(event),
              onShare: () => controller.shareEvent(event),
              onCopy: () => controller.copyEvent(event),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEventEditor(
    BuildContext context,
    AppController controller,
    EventItem event,
  ) async {
    final title = TextEditingController(text: event.title);
    final type = TextEditingController(text: event.eventType);
    final time = TextEditingController(text: event.startTimeIso ?? '');
    final deadline = TextEditingController(text: event.deadlineIso ?? '');
    final location = TextEditingController(text: event.location ?? '');
    final description = TextEditingController(text: event.description ?? '');
    final result = await showDialog<EventItem>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑时间线事项'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _EditField(label: '标题', controller: title),
              _EditField(label: '类型', controller: type),
              _EditField(label: '开始时间 ISO', controller: time),
              _EditField(label: '截止时间 ISO', controller: deadline),
              _EditField(label: '地点', controller: location),
              _EditField(label: '描述', controller: description, maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                context,
                event.copyWith(
                  title: title.text.trim(),
                  eventType: type.text.trim().isEmpty
                      ? '校园安排'
                      : type.text.trim(),
                  startTimeIso: time.text.trim().isEmpty
                      ? null
                      : time.text.trim(),
                  deadlineIso: deadline.text.trim().isEmpty
                      ? null
                      : deadline.text.trim(),
                  location: location.text.trim().isEmpty
                      ? null
                      : location.text.trim(),
                  description: description.text.trim().isEmpty
                      ? null
                      : description.text.trim(),
                  source: event.source.copyWith(type: SourceType.manualText),
                ),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
    title.dispose();
    type.dispose();
    time.dispose();
    deadline.dispose();
    location.dispose();
    description.dispose();
    if (result != null) await controller.updateEvent(result);
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
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
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
