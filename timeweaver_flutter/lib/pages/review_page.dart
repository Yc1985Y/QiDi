import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../models/parsed_notice.dart';
import '../utils/date_utils.dart';
import '../widgets/weaving_widgets.dart';
import 'review_logic.dart';

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
    for (final controller in [_title, _time, _location, _description]) {
      controller.addListener(_refreshDraft);
    }
  }

  void _refreshDraft() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    for (final controller in [_title, _time, _location, _description]) {
      controller.removeListener(_refreshDraft);
    }
    _title.dispose();
    _time.dispose();
    _location.dispose();
    _description.dispose();
    super.dispose();
  }

  ParsedNotice get _draft {
    final title = _title.text.trim();
    final startTimeIso = _time.text.trim().isEmpty ? null : _time.text.trim();
    final action = reviewedNoticeAction(
      currentAction: widget.notice.action,
      title: title,
      startTimeIso: startTimeIso,
    );
    return ParsedNotice(
      id: widget.notice.id,
      title: title,
      eventType: widget.notice.eventType,
      startTimeIso: startTimeIso,
      deadlineIso: widget.notice.deadlineIso,
      location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      description: _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      source: widget.notice.source,
      confidence: widget.notice.confidence,
      reminderSuggestion: widget.notice.reminderSuggestion,
      rawPayload: widget.notice.rawPayload,
      status: action == NoticeAction.navigate ? '待导航' : '待确认',
      action: action,
      fallbackQuery: widget.notice.fallbackQuery,
      createdAtIso: widget.notice.createdAtIso,
      ownerAccount: widget.notice.ownerAccount,
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
        final issues = buildReviewValidationIssues(draft);
        final confidencePercent = (draft.confidence * 100).toInt().clamp(
          0,
          100,
        );
        final needsAttention = confidencePercent < 80 || issues.isNotEmpty;
        final issueTitle = issues.isEmpty ? '校验结果' : '需要留意';
        final issueSummary = issues.isEmpty
            ? '标题、时间、地点等关键字段已经具备，可以确认写入。'
            : issues.map(reviewIssueLabel).join(' / ');
        final issueCardColor = issues.isEmpty
            ? AppColors.primarySoft
            : AppColors.gold;
        final canConfirm = canConfirmReview(draft);
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: WeavingBackground(
              showStarField: true,
              interactiveStars: true,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                children: [
                  Row(
                    children: [
                      _ReviewIconBubble(onTap: () => Navigator.pop(context)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '解析校验',
                              style: TextStyle(
                                fontFamily: 'PlusJakartaSans',
                                fontSize: 21,
                                height: 27 / 21,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              '先核对 AI 抽取结果，再决定是否写入系统',
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 18 / 12.5,
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
                    color: needsAttention
                        ? AppColors.coral
                        : AppColors.surfaceWarm,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InfoChip(
                                label: draft.source.label.trim().isEmpty
                                    ? '待校验'
                                    : draft.source.label,
                                icon: Icons.schedule,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.52,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                needsAttention
                                    ? '这条结果需要你重点看一眼'
                                    : '信息已经整理成可执行草稿',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(color: AppColors.primary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                buildReviewPrompt(draft, issues),
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.muted),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$confidencePercent%',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 17,
                                height: 21 / 17,
                                fontWeight: FontWeight.w900,
                                color: needsAttention
                                    ? const Color(0xFF9E3F42)
                                    : AppColors.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '信心',
                              style: TextStyle(
                                fontSize: 10.5,
                                height: 13 / 10.5,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (conflicts.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    WeavingCard(
                      color: AppColors.coral.withValues(alpha: 0.92),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '时间冲突提醒',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(color: AppColors.primary),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '这条安排和你时间线里的既有事项靠得很近，建议先核对后再确认。',
                            style: TextStyle(color: AppColors.muted),
                          ),
                          const SizedBox(height: 10),
                          ...conflicts
                              .take(2)
                              .map(
                                (event) => InfoChip(
                                  label: buildReviewConflictLabel(
                                    event,
                                    ZhishiDateUtils.parse(draft.startTimeIso)!,
                                  ),
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.52,
                                  ),
                                  contentColor: const Color(0xFF9E3F42),
                                ),
                              ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  WeavingCard(
                    color: AppColors.surfaceLowest.withValues(alpha: 0.90),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '原始输入回顾',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: AppColors.primary),
                        ),
                        const SizedBox(height: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 92),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _buildSourcePreview(widget.notice),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.muted),
                              maxLines: 6,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  WeavingCard(
                    color: AppColors.surfaceLowest.withValues(alpha: 0.94),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '结构化校验',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: AppColors.primary),
                        ),
                        const SizedBox(height: 10),
                        _EditField(
                          label: '事项',
                          controller: _title,
                          icon: Icons.auto_awesome_rounded,
                          highlight:
                              needsAttention && draft.title.trim().isEmpty,
                          hintText: '例如：人工智能前沿讲座',
                          maxLength: 60,
                        ),
                        _EditField(
                          label: '时间',
                          controller: _time,
                          icon: Icons.calendar_month_rounded,
                          highlight:
                              needsAttention &&
                              (draft.startTimeIso ?? '').trim().isEmpty,
                          hintText: '例如：2026-05-16T19:00:00',
                          maxLength: 60,
                        ),
                        _EditField(
                          label: '地点',
                          controller: _location,
                          icon: Icons.location_on_rounded,
                          highlight:
                              draft.action == NoticeAction.navigate &&
                              needsAttention &&
                              (draft.location ?? '').trim().isEmpty,
                          hintText: '可留空：无地点事项也能保留',
                          maxLength: 60,
                        ),
                        _EditField(
                          label: '备注',
                          controller: _description,
                          icon: Icons.content_paste_rounded,
                          highlight: false,
                          hintText: '可补充签到、会议号、来源说明等',
                          maxLines: 3,
                          maxLength: 120,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  WeavingCard(
                    color: issueCardColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issueTitle,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: AppColors.primary),
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
                  const SizedBox(height: 10),
                  _ReviewPrimaryButton(
                    enabled: canConfirm && !widget.controller.isBusy,
                    onTap: _confirmDraft,
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
                          textColor: const Color(0xFF9E3F42),
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
}

class _EditField extends StatelessWidget {
  const _EditField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.highlight,
    this.maxLines = 1,
    this.hintText,
    this.maxLength,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final bool highlight;
  final int maxLines;
  final String? hintText;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: highlight
              ? AppColors.coral.withValues(alpha: 0.72)
              : Colors.white.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(20),
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
                    ? Colors.white.withValues(alpha: 0.62)
                    : AppColors.gold,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                inputFormatters: maxLength == null
                    ? null
                    : [LengthLimitingTextInputFormatter(maxLength)],
                buildCounter:
                    (
                      _, {
                      required currentLength,
                      required isFocused,
                      maxLength,
                    }) => null,
                style: Theme.of(context).textTheme.bodyLarge,
                minLines: 1,
                maxLines: maxLines,
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hintText,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.26),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: highlight
                          ? const Color(0xFF9E3F42).withValues(alpha: 0.52)
                          : Colors.transparent,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: highlight
                          ? const Color(0xFF9E3F42)
                          : AppColors.primary,
                    ),
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
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReviewIconBubble extends StatelessWidget {
  const _ReviewIconBubble({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.82),
      shape: const CircleBorder(
        side: BorderSide(color: Color(0xA3FFFFFF), width: 0.8),
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

class _ReviewPrimaryButton extends StatelessWidget {
  const _ReviewPrimaryButton({required this.enabled, required this.onTap});

  final bool enabled;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        onPressed: enabled ? () => onTap() : null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: const StadiumBorder(),
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.75),
        ),
        icon: const Icon(Icons.check_circle_rounded, size: 17),
        label: const Text(
          '确认写入时间线',
          style: TextStyle(
            fontSize: 15,
            height: 20 / 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
