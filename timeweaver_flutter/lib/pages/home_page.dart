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

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final primaryPending = controller.pendingNotices.firstOrNull;
    final summary = _buildRecognitionSummary(controller, primaryPending);

    return WeavingBackground(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
        children: [
          _HomeGreeting(controller: controller),
          const SizedBox(height: 16),
          _HomeOverviewCard(controller: controller),
          const SizedBox(height: 16),
          _InputEnergyHubCard(controller: controller),
          const SizedBox(height: 22),
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
  const _HomeGreeting({required this.controller});

  final AppController controller;

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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _HomeAvatar(
              avatarPath: controller.preference.avatarPath.trim(),
              fallbackText: nickname,
              onTap: () => controller.setTab(2),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, $nickname',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: AppColors.muted)),
              ],
            ),
          ],
        ),
        IconButton.filledTonal(
          onPressed: () => controller.setTab(2),
          icon: const Icon(Icons.notifications_active_rounded),
          tooltip: '通知与资料',
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
            color: Colors.white.withValues(alpha: 0.88),
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
      color: const Color(0xFFFFF2B8),
      onTap: () => controller.setTab(1),
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
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.56),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.displayLarge?.copyWith(fontSize: 28),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
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
          color: Colors.white.withValues(alpha: 0.9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '自动识别通知',
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 12),
              _CaptureEntryCard(
                enabled: !controller.isBusy && !isListening,
                onTap: _openLiveCamera,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _textController,
                minLines: 4,
                maxLines: 5,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: '粘贴一段校园通知，我来帮你整理成时间、地点和提醒',
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.72),
                  prefixIcon: IconButton(
                    tooltip: '粘贴通知',
                    onPressed: controller.isBusy ? null : _pasteFromClipboard,
                    icon: const Icon(Icons.content_paste_rounded),
                  ),
                  suffixIcon: hasText
                      ? IconButton(
                          tooltip: '清空输入',
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
                          icon: const Icon(Icons.close_rounded),
                        )
                      : IconButton(
                          tooltip: isListening ? '停止语音' : '开始语音',
                          onPressed: controller.isBusy
                              ? null
                              : isListening
                              ? _stopVoice
                              : _startVoice,
                          icon: Icon(
                            isListening
                                ? Icons.stop_circle_outlined
                                : Icons.mic_rounded,
                          ),
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
                    borderSide: const BorderSide(
                      color: AppColors.primarySoft,
                      width: 1.2,
                    ),
                  ),
                ),
              ),
              if (_imagePath != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.file(
                    File(_imagePath!),
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    InfoChip(
                      label: _sourceLabel(_sourceType),
                      icon: Icons.auto_awesome_rounded,
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.isBusy
                          ? null
                          : () {
                              setState(() {
                                _imagePath = null;
                                if (_sourceType == SourceType.camera ||
                                    _sourceType == SourceType.album ||
                                    _sourceType == SourceType.shareImage) {
                                  _sourceType = SourceType.manualText;
                                }
                              });
                            },
                      icon: const Icon(Icons.image_not_supported_outlined),
                      label: const Text('移除图片'),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: controller.isBusy || isListening || !hasText
                          ? null
                          : _submitTextOnly,
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: Text(
                        controller.isBusy
                            ? '正在解析通知…'
                            : hasText
                            ? '解析这段通知'
                            : '输入通知后解析',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: controller.isBusy ? null : () => _pickAlbum(),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('相册'),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.isBusy ? null : _openLiveCamera,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('拍照'),
                  ),
                  OutlinedButton.icon(
                    onPressed: controller.isBusy
                        ? null
                        : isListening
                        ? _stopVoice
                        : _startVoice,
                    icon: Icon(
                      isListening
                          ? Icons.stop_circle_outlined
                          : Icons.mic_none_rounded,
                    ),
                    label: Text(isListening ? '停止语音' : '语音输入'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _sourceLabel(SourceType type) {
    switch (type) {
      case SourceType.camera:
        return '拍照导入';
      case SourceType.album:
        return '相册导入';
      case SourceType.voice:
        return '语音转写';
      case SourceType.clipboard:
        return '剪贴板导入';
      case SourceType.shareImage:
        return '分享图片';
      case SourceType.shareText:
        return '分享文本';
      case SourceType.manualText:
        return '手动输入';
    }
  }

  Future<void> _pickAlbum() async {
    final picked = await controller.pickImage(SourceType.album);
    if (picked == null) return;
    setState(() {
      _imagePath = picked;
      _sourceType = SourceType.album;
    });
    await _submit();
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
    return Material(
      color: Colors.white.withValues(alpha: 0.52),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: enabled ? onTap : null,
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
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 28,
                    height: 1.15,
                  ),
                ),
              ),
            ],
          ),
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
    final confidence = '${(notice.confidence * 100).round().clamp(0, 100)}%';
    final summary = _buildSummary();

    return WeavingCard(
      color: Colors.white.withValues(alpha: 0.92),
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InfoChip(
            label: sourceLabel,
            icon: Icons.auto_awesome_rounded,
            backgroundColor: AppColors.coral,
          ),
          const SizedBox(height: 12),
          Text('我整理出了这些信息', style: Theme.of(context).textTheme.headlineMedium),
          if (controller.pendingNotices.length > 1) ...[
            const SizedBox(height: 10),
            InfoChip(
              label: '还有 ${controller.pendingNotices.length} 条待确认',
              icon: Icons.notifications_active_rounded,
              backgroundColor: AppColors.gold,
            ),
          ],
          const SizedBox(height: 12),
          _ReviewField(label: '事项', value: notice.title),
          _ReviewField(
            label: '时间',
            value: ZhishiDateUtils.formatDateTime(notice.startTimeIso),
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
            ),
          ],
          const SizedBox(height: 12),
          Text(
            summary,
            style: const TextStyle(color: AppColors.muted, height: 1.45),
          ),
          const SizedBox(height: 12),
          WeavingCard(
            color: AppColors.coral,
            padding: const EdgeInsets.all(14),
            child: const Text(
              '如果还有歧义，可以先进入校验页修改后再加入时间线。',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          WeavingCard(
            color: AppColors.primarySoft,
            onTap: onEdit,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '进入解析校验页',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        '逐项核对标题、时间、地点后再写入',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => controller.confirmNotice(notice),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('确认加入日程'),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 128,
                child: FilledButton(
                  onPressed: () => controller.discardNotice(notice),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                  ),
                  child: const Text('取消'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildSummary() {
    final candidates = <String?>[
      notice.description,
      notice.source.rawText,
      notice.source.ocrText,
    ];
    for (final candidate in candidates) {
      final text = candidate?.trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
    }
    return '如果还有歧义，可以先进入校验页修改后再加入时间线。';
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
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
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
      color: Colors.white.withValues(alpha: 0.9),
      child: Text(
        summary,
        style: const TextStyle(color: AppColors.muted, height: 1.5),
      ),
    );
  }
}
