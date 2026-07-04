import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app.dart';
import '../models/source_info.dart';
import '../widgets/weaving_widgets.dart';
import 'live_camera_capture_page.dart';

class InputPage extends StatefulWidget {
  const InputPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
  final TextEditingController _textController = TextEditingController();
  String? _imagePath;
  SourceType _sourceType = SourceType.manualText;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _textController.text.trim().isNotEmpty;
    final isListening = widget.controller.isVoiceListening;

    return WeavingCard(
      color: Colors.white.withValues(alpha: 0.92),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('自动识别通知', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 12),
          _CaptureEntryCard(
            enabled: !widget.controller.isBusy && !isListening,
            onTap: _openLiveCamera,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            minLines: 4,
            maxLines: 6,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '粘贴一段校园通知，我来帮你整理成时间、地点和提醒',
              filled: true,
              fillColor: AppColors.background,
              prefixIcon: IconButton(
                tooltip: '读取剪贴板',
                onPressed: widget.controller.isBusy
                    ? null
                    : _pasteFromClipboard,
                icon: const Icon(Icons.content_paste_rounded),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasText)
                    IconButton(
                      tooltip: '清空输入',
                      onPressed: widget.controller.isBusy
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
                    ),
                  IconButton(
                    tooltip: isListening ? '停止语音' : '开始语音',
                    onPressed: widget.controller.isBusy
                        ? null
                        : isListening
                        ? _stopVoice
                        : _startVoice,
                    icon: Icon(
                      isListening
                          ? Icons.stop_circle_outlined
                          : Icons.mic_none_rounded,
                    ),
                  ),
                ],
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
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
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: widget.controller.isBusy
                    ? null
                    : () => _pick(SourceType.album),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('相册'),
              ),
              OutlinedButton.icon(
                onPressed: widget.controller.isBusy ? null : _openLiveCamera,
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('拍照'),
              ),
              OutlinedButton.icon(
                onPressed: widget.controller.isBusy
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
              if (_imagePath != null)
                OutlinedButton.icon(
                  onPressed: widget.controller.isBusy
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.controller.isBusy ? null : _submit,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(
                widget.controller.isBusy
                    ? '正在解析通知'
                    : hasText || _imagePath != null
                    ? '解析这段通知'
                    : '输入通知后再解析',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pick(SourceType type) async {
    final picked = await widget.controller.pickImage(type);
    if (picked == null) return;
    setState(() {
      _imagePath = picked;
      _sourceType = type;
    });
  }

  Future<void> _openLiveCamera() async {
    final granted = await widget.controller.requestCameraAccess();
    if (!granted || !mounted) return;
    final picked = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (context) => const LiveCameraCapturePage()),
    );
    await widget.controller.refreshRuntimeStatus();
    if (picked == null || !mounted) return;
    setState(() {
      _imagePath = picked;
      _sourceType = SourceType.camera;
    });
  }

  Future<void> _submit() async {
    await widget.controller.parseInput(
      rawText: _textController.text,
      imagePath: _imagePath,
      sourceType: _sourceType,
    );
    if (widget.controller.errorMessage == null && mounted) {
      _textController.clear();
      setState(() {
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
    await widget.controller.startVoiceInput((text) {
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

  Future<void> _stopVoice() => widget.controller.stopVoiceInput();
}

class _CaptureEntryCard extends StatelessWidget {
  const _CaptureEntryCard({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.84),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.photo_camera_rounded,
                  size: 30,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  '拍照识别',
                  style: Theme.of(
                    context,
                  ).textTheme.headlineMedium?.copyWith(fontSize: 28),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
