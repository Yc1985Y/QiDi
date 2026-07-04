import 'package:flutter/material.dart';

import '../app.dart';
import '../models/parsed_notice.dart';
import '../utils/date_utils.dart';
import '../widgets/weaving_widgets.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({super.key, required this.controller, required this.notice});

  final AppController controller;
  final ParsedNotice notice;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  late final TextEditingController _title;
  late final TextEditingController _time;
  late final TextEditingController _location;
  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.notice.title);
    _time = TextEditingController(text: widget.notice.startTimeIso ?? '');
    _location = TextEditingController(text: widget.notice.location ?? '');
    _description = TextEditingController(text: widget.notice.description ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _time.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  ParsedNotice get _draft {
    return widget.notice.copyWith(
      title: _title.text.trim().isEmpty ? '新的校园事项' : _title.text.trim(),
      eventType: widget.notice.eventType,
      startTimeIso: _time.text.trim().isEmpty ? null : _time.text.trim(),
      deadlineIso: widget.notice.deadlineIso,
      location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      status: '待确认',
    );
  }

  Future<void> _saveDraft() async {
    await widget.controller.updatePendingNotice(_draft);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _confirmDraft() async {
    final blocker = await widget.controller.confirmNotice(_draft);
    if (blocker == null && mounted) Navigator.pop(context);
  }

  Future<void> _discardDraft() async {
    await widget.controller.discardNotice(_draft);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final draft = _draft;
        final conflicts = widget.controller.detectConflictsForNotice(draft);
        final issues = _buildValidationIssues(draft, conflicts);
        final confidencePercent = (draft.confidence * 100).round().clamp(
          0,
          100,
        );
        final needsAttention = confidencePercent < 80 || issues.isNotEmpty;
        final issueTitle = issues.isEmpty ? '校验结果' : '需要留意';
        final issueSummary = issues.isEmpty
            ? '标题、时间、地点等关键字段已经具备，可以确认写入。'
            : issues.join(' / ');
        final issueCardColor = issues.isEmpty
            ? AppColors.primarySoft
            : AppColors.gold;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: WeavingBackground(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                        tooltip: '返回',
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              '解析校验',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              '先核对 AI 抽取结果，再决定是否写入系统',
                              style: TextStyle(color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  WeavingCard(
                    color: needsAttention
                        ? AppColors.coral
                        : AppColors.surfaceWarm,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            InfoChip(
                              label: draft.source.label.trim().isEmpty
                                  ? '待校验'
                                  : draft.source.label,
                              icon: Icons.schedule,
                            ),
                            const Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '$confidencePercent%',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const Text(
                                  '信心',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          needsAttention ? '这条结果需要你重点看一眼' : '信息已经整理成可执行草稿',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _buildHeroPrompt(draft),
                          style: const TextStyle(color: AppColors.muted),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  StatusStrip(
                    message: widget.controller.statusMessage,
                    error: widget.controller.errorMessage,
                    busy: widget.controller.isBusy,
                  ),
                  if (conflicts.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    WeavingCard(
                      color: const Color(0xFFFFE0DC),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '时间冲突提醒',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '这条安排与现有时间线中的事项时间靠得很近，建议确认后再写入。',
                            style: TextStyle(color: AppColors.muted),
                          ),
                          const SizedBox(height: 10),
                          ...conflicts
                              .take(3)
                              .map(
                                (event) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.75,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          event.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          [
                                            ZhishiDateUtils.formatDateTime(
                                              event.startTimeIso,
                                            ),
                                            if (event.location != null &&
                                                event.location!
                                                    .trim()
                                                    .isNotEmpty)
                                              event.location!,
                                          ].join(' · '),
                                          style: const TextStyle(
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  WeavingCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '原始输入回顾',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            _buildSourcePreview(widget.notice),
                            style: const TextStyle(
                              color: AppColors.text,
                              height: 1.45,
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
                          '结构化校验',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        _EditField(
                          label: '事项',
                          controller: _title,
                          icon: Icons.auto_awesome_rounded,
                          highlight: draft.title.trim().isEmpty,
                          hintText: '例如：人工智能前沿讲座',
                        ),
                        _EditField(
                          label: '时间',
                          controller: _time,
                          icon: Icons.calendar_month_rounded,
                          highlight: (draft.startTimeIso ?? '').trim().isEmpty,
                          helper: '支持 ISO 时间或原始时间文本',
                          hintText: '例如：2026-05-16T19:00:00',
                        ),
                        _EditField(
                          label: '地点',
                          controller: _location,
                          icon: Icons.location_on_rounded,
                          highlight: false,
                          hintText: '可留空：无地点事项也能保留',
                        ),
                        _EditField(
                          label: '备注',
                          controller: _description,
                          icon: Icons.content_paste_rounded,
                          highlight: false,
                          hintText: '可补充签到、会议号、来源说明等',
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  WeavingCard(
                    color: issueCardColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issueTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          issueSummary,
                          style: const TextStyle(
                            color: AppColors.muted,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: widget.controller.isBusy
                          ? null
                          : _confirmDraft,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('确认写入时间线'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _ReviewSecondaryAction(
                          label: '保存校验',
                          onTap: _saveDraft,
                          color: AppColors.primarySoft,
                          enabled: !widget.controller.isBusy,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ReviewSecondaryAction(
                          label: '取消本次',
                          onTap: _discardDraft,
                          color: AppColors.coral,
                          enabled: !widget.controller.isBusy,
                          textColor: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _buildSourcePreview(ParsedNotice notice) {
    final parts = <String>[
      '来源：${notice.source.label}',
      if (notice.source.rawText != null &&
          notice.source.rawText!.trim().isNotEmpty)
        '原文：\n${notice.source.rawText!.trim()}',
      if (notice.source.ocrText != null &&
          notice.source.ocrText!.trim().isNotEmpty)
        'OCR：\n${notice.source.ocrText!.trim()}',
      if (notice.source.imagePath != null &&
          notice.source.imagePath!.trim().isNotEmpty)
        '图片：${notice.source.imagePath}',
      if (notice.rawPayload != null && notice.rawPayload!.trim().isNotEmpty)
        '模型原始结构：\n${notice.rawPayload!.trim()}',
    ];
    return parts.join('\n\n');
  }

  String _buildHeroPrompt(ParsedNotice notice) {
    if (notice.description?.trim().isNotEmpty == true) {
      return notice.description!;
    }
    if (notice.title.trim().isNotEmpty) {
      return '已抽取到事项《${notice.title}》，请核对时间、地点和备注后再写入。';
    }
    return '请检查标题、时间、地点后再确认写入。';
  }

  List<String> _buildValidationIssues(
    ParsedNotice notice,
    List<dynamic> conflicts,
  ) {
    final issues = <String>[];
    if (notice.title.trim().isEmpty) {
      issues.add('事项标题为空，建议先补齐。');
    }
    if ((notice.startTimeIso ?? '').trim().isEmpty) {
      issues.add('时间字段为空，确认写入前建议补齐。');
    }
    if (conflicts.isNotEmpty) {
      issues.add('当前与已有时间线事项存在近时段冲突，建议先复核。');
    }
    if ((notice.location ?? '').trim().isEmpty) {
      issues.add('地点为空时仍可保存，但地图与到场提醒会受影响。');
    }
    return issues;
  }
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.highlight,
    this.maxLines = 1,
    this.helper,
    this.hintText,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool highlight;
  final int maxLines;
  final String? helper;
  final String? hintText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.coral.withValues(alpha: 0.72)
              : Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: maxLines == 1
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: highlight
                    ? Colors.white.withValues(alpha: 0.66)
                    : AppColors.gold,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                maxLines: maxLines,
                decoration: InputDecoration(
                  labelText: label,
                  helperText: helper,
                  hintText: hintText,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.36),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: highlight
                          ? AppColors.primary.withValues(alpha: 0.48)
                          : AppColors.border,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewSecondaryAction extends StatelessWidget {
  const _ReviewSecondaryAction({
    required this.label,
    required this.onTap,
    required this.color,
    required this.enabled,
    this.textColor = AppColors.primary,
  });

  final String label;
  final Future<void> Function() onTap;
  final Color color;
  final bool enabled;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.58,
      child: IgnorePointer(
        ignoring: !enabled,
        child: WeavingCard(
          color: color,
          onTap: () {
            onTap();
          },
          child: Center(
            child: Text(
              label,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
    );
  }
}
