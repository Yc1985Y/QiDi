import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();

  Future<bool> initialize() {
    return _speech.initialize();
  }

  bool get isListening => _speech.isListening;

  Future<void> listen({
    required void Function(String text) onText,
    void Function(String message)? onError,
  }) async {
    final available = await initialize();
    if (!available) {
      onError?.call('系统语音识别不可用');
      return;
    }
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: 'zh_CN',
        partialResults: true,
        listenMode: ListenMode.dictation,
      ),
      onResult: (SpeechRecognitionResult result) {
        onText(result.recognizedWords);
      },
    );
  }

  Future<void> stop() => _speech.stop();
}
