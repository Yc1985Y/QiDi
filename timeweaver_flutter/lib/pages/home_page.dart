import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../models/parsed_notice.dart';
import '../models/source_info.dart';
import '../utils/date_utils.dart';
import '../widgets/weaving_widgets.dart';
import 'live_camera_capture_page.dart';
import 'review_page.dart';
import 'review_logic.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final primaryPending = controller.pendingNotices.firstOrNull;
    final summary = _buildRecognitionSummary(controller, primaryPending);

    return WeavingBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          _HomeGreeting(
            controller: controller,
            onNotificationTap: primaryPending == null
                ? () => controller.setTab(2)
                : () => _openReviewPage(context, controller, primaryPending),
          ),
          const SizedBox(height: 10),
          _HomeOverviewCard(controller: controller),
          const SizedBox(height: 10),
          _InputEnergyHubCard(controller: controller),
          const SizedBox(height: 10),
          const SectionHeader(title: '最近识别结果'),
          const SizedBox(height: 10),
          if (primaryPending != null)
            _PendingReviewCard(
              controller: controller,
              notice: primaryPending,
              onEdit: () =>
                  _openReviewPage(context, controller, primaryPending),
            )
          else
            _RecentRecognitionCard(summary: summary),
        ],
      ),
    );
  }

  Future<void> _openReviewPage(
    BuildContext context,
    AppController controller,
    ParsedNotice notice,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            ReviewPage(controller: controller, notice: notice),
      ),
    );
  }

  String _buildRecognitionSummary(
    AppController controller,
    ParsedNotice? primaryPending,
  ) {
    if (primaryPending != null) {
      final source = primaryPending.source.label.trim().isEmpty
          ? '待确认'
          : primaryPending.source.label;
      final time = ZhishiDateUtils.formatDateTime(primaryPending.startTimeIso);
      final location = primaryPending.location?.trim().isNotEmpty == true
          ? primaryPending.location!
          : '请补充地点';
      return '来源：$source\n时间：$time\n地点：$location';
    }
    final recentEvent = controller.confirmedEvents.isEmpty
        ? null
        : controller.confirmedEvents.last;
    if (recentEvent != null) {
      return [
        '最近已确认：${recentEvent.title}',
        '时间：${ZhishiDateUtils.formatDateTime(recentEvent.startTimeIso)}',
        if (recentEvent.location?.trim().isNotEmpty == true)
          '地点：${recentEvent.location!}',
      ].join('\n');
    }
    if (controller.statusMessage.trim().isNotEmpty) {
      return controller.statusMessage;
    }
    return '把海报、截图、群通知或一段文字交给织时，我们会先整理，再请你确认。';
  }
}

class _HomeGreeting extends StatelessWidget {
  const _HomeGreeting({
    required this.controller,
    required this.onNotificationTap,
  });

  final AppController controller;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final nickname = controller.preference.nickname.trim().isEmpty
        ? '织时用户'
        : controller.preference.nickname.trim();
    final subtitle = controller.todayEvents.isNotEmpty
        ? '今天有 ${controller.todayEvents.length} 项安排待处理'
        : controller.currentAccountLabel.isNotEmpty
        ? '${controller.currentAccountLabel} · 今天想把哪条校园通知整理进时间线？'
        : '今天想把哪条校园通知整理进时间线？';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Row(
            children: [
              _HomeAvatar(
                avatarPath: controller.preference.avatarPath.trim(),
                fallbackText: nickname,
                onTap: () => controller.setTab(2),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hi, $nickname',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: AppColors.surfaceWarm,
          shape: const CircleBorder(
            side: BorderSide(color: Colors.white, width: 0.8),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onNotificationTap,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.notifications_active_rounded,
                size: 20,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeAvatar extends StatelessWidget {
  const _HomeAvatar({
    required this.avatarPath,
    required this.fallbackText,
    required this.onTap,
  });

  final String avatarPath;
  final String fallbackText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasAvatar = avatarPath.isNotEmpty && File(avatarPath).existsSync();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.surfaceWarm,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.64),
              width: 0.8,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: hasAvatar
              ? Image.file(File(avatarPath), fit: BoxFit.cover)
              : Center(
                  child: Text(
                    fallbackText.characters.first,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _HomeOverviewCard extends StatelessWidget {
  const _HomeOverviewCard({required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return WeavingCard(
      color: const Color(0xFFFFF9C7),
      onTap: () => controller.setTab(1),
      interactionStyle: WeavingInteractionStyle.timelineSlide,
      child: Row(
        children: [
          Expanded(
            child: _OverviewMetric(
              icon: Icons.calendar_month_rounded,
              value: '${controller.todayEvents.length}',
              label: '今日安排',
            ),
          ),
          Container(
            width: 1,
            height: 72,
            color: Colors.white.withValues(alpha: 0.55),
          ),
          Expanded(
            child: _OverviewMetric(
              icon: Icons.schedule_rounded,
              value: '${controller.scheduledReminderCount}',
              label: '待提醒项',
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.56),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, size: 24, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          Text(value, style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputEnergyHubCard extends StatefulWidget {
  const _InputEnergyHubCard({required this.controller});

  final AppController controller;

  @override
  State<_InputEnergyHubCard> createState() => _InputEnergyHubCardState();
}

class _InputEnergyHubCardState extends State<_InputEnergyHubCard> {
  final TextEditingController _textController = TextEditingController();
  String? _imagePath;
  SourceType _sourceType = SourceType.manualText;

  AppController get controller => widget.controller;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _textController.text.trim().isNotEmpty;
    final isListening = controller.isVoiceListening;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return WeavingCard(
          color: AppColors.surfaceHigh.withValues(alpha: 0.9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '自动识别通知',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 21,
                  height: 27 / 21,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 8),
              _CaptureEntryCard(
                enabled: !controller.isBusy && !isListening,
                onTap: _openLiveCamera,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _textController,
                minLines: 1,
                maxLines: 5,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '粘贴一段校园通知，我来帮你整理成时间、地点和提醒',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted.withValues(alpha: 0.5),
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.72),
                  prefixIcon: _RoundInputIcon(
                    icon: Icons.content_paste_rounded,
                    background: AppColors.gold.withValues(alpha: 0.72),
                    onPressed: controller.isBusy ? null : _pasteFromClipboard,
                  ),
                  suffixIcon: hasText
                      ? _RoundInputIcon(
                          icon: Icons.close_rounded,
                          background: Colors.white.withValues(alpha: 0.78),
                          onPressed: controller.isBusy
                              ? null
                              : () {
                                  setState(() {
                                    _textController.clear();
                                    if (_imagePath == null) {
                                      _sourceType = SourceType.manualText;
                                    }
                                  });
                                },
                        )
                      : _VoiceInputButton(
                          isListening: isListening,
                          elapsed: controller.voiceRecordingDuration,
                          onPressed: controller.isBusy
                              ? null
                              : isListening
                              ? _stopVoice
                              : _startVoice,
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _HomePrimaryButton(
                      label: controller.isBusy
                          ? '正在解析通知…'
                          : hasText
                          ? '解析这段通知'
                          : '输入通知后解析',
                      icon: Icons.auto_awesome_rounded,
                      onPressed: controller.isBusy || isListening || !hasText
                          ? null
                          : _submitTextOnly,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openLiveCamera() async {
    final granted = await controller.requestCameraAccess();
    if (!granted || !mounted) return;
    final picked = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const LiveCameraCapturePage()),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _imagePath = picked;
      _sourceType = SourceType.camera;
    });
    await _submit();
  }

  Future<void> _submitTextOnly() async {
    await _submit();
  }

  Future<void> _submit() async {
    await controller.parseInput(
      rawText: _textController.text,
      imagePath: _imagePath,
      sourceType: _sourceType,
    );
    if (!mounted) return;
    if (controller.errorMessage == null) {
      setState(() {
        _textController.clear();
        _imagePath = null;
        _sourceType = SourceType.manualText;
      });
    }
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('剪贴板里没有可导入的文本')));
      return;
    }
    setState(() {
      _textController.text = text;
      _textController.selection = TextSelection.collapsed(offset: text.length);
      _sourceType = SourceType.clipboard;
    });
  }

  Future<void> _startVoice() async {
    await controller.startVoiceInput((text) {
      if (!mounted) return;
      setState(() {
        _textController.text = text;
        _textController.selection = TextSelection.collapsed(
          offset: _textController.text.length,
        );
        _sourceType = SourceType.voice;
      });
    });
  }

  Future<void> _stopVoice() => controller.stopVoiceInput();
}

class _CaptureEntryCard extends StatelessWidget {
  const _CaptureEntryCard({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WeavingCard(
      color: Colors.white.withValues(alpha: 0.52),
      onTap: enabled ? onTap : null,
      interactionStyle: WeavingInteractionStyle.timelineSlide,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Icon(
                Icons.photo_camera_rounded,
                size: 38,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '拍照识别',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.displayLarge?.copyWith(fontSize: 28, height: 1.15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoundInputIcon extends StatelessWidget {
  const _RoundInputIcon({
    required this.icon,
    required this.background,
    required this.onPressed,
  });

  final IconData icon;
  final Color background;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: Material(
          color: background,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: 34,
              height: 34,
              child: Icon(icon, size: 18, color: AppColors.text),
            ),
          ),
        ),
      ),
    );
  }
}

class _VoiceInputButton extends StatelessWidget {
  const _VoiceInputButton({
    required this.isListening,
    required this.elapsed,
    required this.onPressed,
  });

  final bool isListening;
  final Duration elapsed;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isListening ? '结束语音识别' : '语音识别',
      child: SizedBox(
        width: 48,
        height: 48,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            _RoundInputIcon(
              icon: Icons.mic_rounded,
              background: isListening
                  ? const Color(0xFF76D672)
                  : AppColors.mint.withValues(alpha: 0.86),
              onPressed: onPressed,
            ),
            if (isListening)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${elapsed.inSeconds}s',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
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

class _PendingReviewCard extends StatelessWidget {
  const _PendingReviewCard({
    required this.controller,
    required this.notice,
    required this.onEdit,
  });

  final AppController controller;
  final ParsedNotice notice;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final conflictCount = controller.detectConflictsForNotice(notice).length;
    final sourceLabel = notice.source.label.trim().isEmpty
        ? '待确认'
        : notice.source.label;
    final confidence = '${(notice.confidence * 100).toInt().clamp(0, 100)}%';
    final summary = buildReviewPrompt(
      notice,
      buildReviewValidationIssues(notice),
    );

    return WeavingCard(
      color: AppColors.surfaceWarm,
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoChip(
            label: sourceLabel,
            icon: Icons.auto_awesome_rounded,
            backgroundColor: AppColors.coral,
            contentColor: const Color(0xFF9E3F42),
          ),
          const SizedBox(height: 8),
          Text(
            '我整理出了这些信息',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              fontSize: 21,
              height: 27 / 21,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
            ),
          ),
          if (controller.pendingNotices.length > 1) ...[
            const SizedBox(height: 8),
            InfoChip(
              label: '还有 ${controller.pendingNotices.length} 条待确认',
              icon: Icons.notifications_active_rounded,
              backgroundColor: AppColors.gold,
              contentColor: const Color(0xFF9E3F42),
            ),
          ],
          const SizedBox(height: 8),
          _ReviewField(
            label: '事项',
            value: notice.title.trim().isEmpty ? '待确认安排' : notice.title,
          ),
          _ReviewField(
            label: '时间',
            value: (notice.startTimeIso ?? '').trim().isEmpty
                ? '请先检查时间'
                : notice.startTimeIso!.trim(),
          ),
          _ReviewField(
            label: '地点',
            value: notice.location?.trim().isNotEmpty == true
                ? notice.location!
                : '请补充地点',
          ),
          _ReviewField(label: '信心指数', value: confidence),
          if (conflictCount > 0) ...[
            const SizedBox(height: 2),
            InfoChip(
              label: '有 $conflictCount 条相近时间安排',
              icon: Icons.notifications_active_rounded,
              backgroundColor: AppColors.gold,
              contentColor: const Color(0xFF9E3F42),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            summary,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          WeavingCard(
            color: AppColors.coral,
            child: Text(
              '如果还有歧义，可以先进入校验页修改后再加入时间线。',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: const Color(0xFF9E3F42)),
            ),
          ),
          const SizedBox(height: 8),
          WeavingCard(
            color: AppColors.primarySoft,
            onTap: onEdit,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '进入解析校验页',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '逐项核对标题、时间、地点后再写入',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _HomePrimaryButton(
                  label: '确认加入日程',
                  icon: Icons.check_circle_rounded,
                  onPressed: () => controller.confirmNoticeWithTransfer(notice),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 128,
                child: _HomePrimaryButton(
                  label: '取消',
                  onPressed: () => controller.discardNotice(notice),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewField extends StatelessWidget {
  const _ReviewField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}

class _RecentRecognitionCard extends StatelessWidget {
  const _RecentRecognitionCard({required this.summary});

  final String summary;

  @override
  Widget build(BuildContext context) {
    return WeavingCard(
      child: Text(
        summary,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(color: AppColors.muted),
      ),
    );
  }
}

class _HomePrimaryButton extends StatelessWidget {
  const _HomePrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(50),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shape: const StadiumBorder(),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.45),
      disabledForegroundColor: Colors.white.withValues(alpha: 0.75),
      textStyle: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 15,
        height: 20 / 15,
        fontWeight: FontWeight.w700,
      ),
    );
    if (icon == null) {
      return FilledButton(
        onPressed: onPressed,
        style: style,
        child: Text(label),
      );
    }
    return FilledButton.icon(
      onPressed: onPressed,
      style: style,
      icon: Icon(icon, size: 17),
      label: Text(label),
    );
  }
}
