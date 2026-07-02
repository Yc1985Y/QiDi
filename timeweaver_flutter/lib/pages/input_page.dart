import 'dart:io';

import 'package:flutter/material.dart';

import '../app.dart';
import '../models/source_info.dart';
import '../widgets/weaving_widgets.dart';

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
    return WeavingCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('信息输入', style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            minLines: 4,
            maxLines: 8,
            decoration: InputDecoration(
              hintText: '粘贴班群通知、教务公告、报名截止信息',
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          if (_imagePath != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                File(_imagePath!),
                height: 140,
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
                onPressed: () => _pick(SourceType.album),
                icon: const Icon(Icons.photo_library_outlined),
                label: const Text('相册'),
              ),
              OutlinedButton.icon(
                onPressed: () => _pick(SourceType.camera),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text('拍照'),
              ),
              OutlinedButton.icon(
                onPressed: widget.controller.isVoiceListening
                    ? _stopVoice
                    : _startVoice,
                icon: Icon(
                  widget.controller.isVoiceListening
                      ? Icons.stop_circle_outlined
                      : Icons.mic_none_rounded,
                ),
                label: Text(widget.controller.isVoiceListening ? '停止' : '语音'),
              ),
              if (_imagePath != null)
                OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _imagePath = null;
                    _sourceType = SourceType.manualText;
                  }),
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
              icon: const Icon(Icons.task_alt_rounded),
              label: const Text('开始解析'),
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

  Future<void> _startVoice() async {
    await widget.controller.startVoiceInput((text) {
      if (!mounted) return;
      setState(() {
        _textController.text = text;
        _textController.selection = TextSelection.collapsed(
          offset: _textController.text.length,
        );
      });
    });
  }

  Future<void> _stopVoice() => widget.controller.stopVoiceInput();
}
