import 'package:flutter/material.dart';

import '../app.dart';
import '../models/parsed_notice.dart';
import '../widgets/confirm_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/event_card.dart';
import '../widgets/weaving_widgets.dart';
import 'input_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return WeavingBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          _Greeting(controller: controller),
          const SizedBox(height: 14),
          StatusStrip(
            message: controller.statusMessage,
            error: controller.errorMessage,
            busy: controller.isBusy,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              MetricTile(
                value: '${controller.todayEvents.length}',
                label: '今日任务',
                color: AppColors.primarySoft,
              ),
              const SizedBox(width: 10),
              MetricTile(
                value: '${controller.pendingNotices.length}',
                label: '待确认',
                color: AppColors.gold,
              ),
              const SizedBox(width: 10),
              MetricTile(
                value: '${controller.scheduledReminderCount}',
                label: '提醒',
                color: AppColors.coral,
              ),
            ],
          ),
          const SizedBox(height: 18),
          InputPage(controller: controller),
          const SizedBox(height: 22),
          SectionHeader(
            title: '待确认',
            trailing: controller.pendingNotices.isEmpty
                ? null
                : TextButton(
                    onPressed: controller.clearPending,
                    child: const Text('清空'),
                  ),
          ),
          const SizedBox(height: 10),
          if (controller.pendingNotices.isEmpty)
            const EmptyState(
              title: '暂无待确认事项',
              summary: '解析出的结构化事项会停在这里，确认后进入时间线。',
            )
          else
            ...controller.pendingNotices.map(
              (notice) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ConfirmCard(
                  notice: notice,
                  onConfirm: () => controller.confirmNotice(notice),
                  onEdit: () => _showNoticeEditor(context, controller, notice),
                  onDiscard: () => controller.discardNotice(notice),
                ),
              ),
            ),
          const SizedBox(height: 12),
          const SectionHeader(title: '最近时间线'),
          const SizedBox(height: 10),
          if (controller.confirmedEvents.isEmpty)
            EmptyState(
              title: '时间线为空',
              summary: '确认后的校园安排会按日期保存。',
              actionLabel: '查看时间线',
              onAction: () => controller.setTab(1),
            )
          else
            ...controller.confirmedEvents
                .take(3)
                .map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: EventCard(event: event),
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _showNoticeEditor(
    BuildContext context,
    AppController controller,
    ParsedNotice notice,
  ) async {
    final title = TextEditingController(text: notice.title);
    final type = TextEditingController(text: notice.eventType);
    final time = TextEditingController(text: notice.startTimeIso ?? '');
    final deadline = TextEditingController(text: notice.deadlineIso ?? '');
    final location = TextEditingController(text: notice.location ?? '');
    final description = TextEditingController(text: notice.description ?? '');
    final result = await showDialog<ParsedNotice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑确认卡片'),
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
                notice.copyWith(
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
                  status: '待确认',
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
    if (result != null) {
      await controller.updatePendingNotice(result);
    }
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: AppColors.coral,
          child: Text(
            controller.preference.nickname.trim().isEmpty
                ? '织'
                : controller.preference.nickname.trim().characters.first,
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('织时', style: Theme.of(context).textTheme.headlineMedium),
              Text(
                controller.nextReminderText,
                style: const TextStyle(color: AppColors.muted),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          onPressed: () => controller.setTab(2),
          icon: const Icon(Icons.tune_rounded),
          tooltip: '设置',
        ),
      ],
    );
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
