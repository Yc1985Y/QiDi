import 'package:flutter/material.dart';

import '../app.dart';
import '../models/parsed_notice.dart';
import '../utils/date_utils.dart';
import 'weaving_widgets.dart';

class ConfirmCard extends StatelessWidget {
  const ConfirmCard({
    super.key,
    required this.notice,
    required this.onConfirm,
    required this.onEdit,
    required this.onDiscard,
  });

  final ParsedNotice notice;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return WeavingCard(
      color: const Color(0xFFFFFFFF),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  notice.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              InfoChip(
                label: '${(notice.confidence * 100).round()}%',
                icon: Icons.verified_outlined,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FieldRow(label: '类型', value: notice.eventType),
          _FieldRow(
            label: '开始',
            value: ZhishiDateUtils.formatDateTime(notice.startTimeIso),
          ),
          _FieldRow(
            label: '截止',
            value: ZhishiDateUtils.formatDateTime(notice.deadlineIso),
          ),
          _FieldRow(label: '地点', value: notice.location ?? '待补充'),
          _FieldRow(label: '来源', value: notice.source.label),
          _FieldRow(label: '提醒', value: notice.reminderSuggestion),
          if (notice.description != null &&
              notice.description!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                notice.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('确认'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: '编辑',
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: '丢弃',
                onPressed: onDiscard,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
