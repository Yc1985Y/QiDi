import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    await _tts.setLanguage('zh-CN');
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  Future<void> speak(String text) async {
    final normalized = text
        .split(RegExp(r'[\n。]'))
        .where((line) => line.trim().isNotEmpty)
        .take(2)
        .join('。')
        .trim();
    if (normalized.isEmpty) return;
    await initialize();
    await _tts.speak(
      normalized.length > 90 ? normalized.substring(0, 90) : normalized,
    );
  }

  Future<void> stop() => _tts.stop();
}
