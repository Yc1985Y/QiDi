import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  void Function(String message)? _activeErrorHandler;
  void Function()? _activeDoneHandler;

  Future<bool> initialize() async {
    if (_initialized) return true;
    _initialized = await _speech.initialize(
      onError: (error) => _activeErrorHandler?.call(_errorMessage(error)),
      onStatus: (status) {
        if (status == SpeechToText.doneStatus ||
            status == SpeechToText.notListeningStatus) {
          _activeDoneHandler?.call();
        }
      },
    );
    return _initialized;
  }

  bool get isListening => _speech.isListening;

  Future<void> listen({
    required void Function(String text) onText,
    void Function(String message)? onError,
    void Function()? onDone,
  }) async {
    _activeErrorHandler = onError;
    _activeDoneHandler = onDone;
    final available = await initialize();
    if (!available) {
      onError?.call('系统语音识别不可用');
      return;
    }
    final localeId = await _preferredLocaleId();
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        localeId: localeId,
        partialResults: true,
        listenMode: ListenMode.dictation,
        listenFor: const Duration(seconds: 45),
        pauseFor: const Duration(seconds: 4),
        cancelOnError: true,
      ),
      onResult: (SpeechRecognitionResult result) {
        final words = result.recognizedWords.trim();
        if (words.isNotEmpty) {
          onText(words);
        }
      },
    );
  }

  Future<void> stop() async {
    await _speech.stop();
    _activeDoneHandler?.call();
  }

  Future<String?> _preferredLocaleId() async {
    try {
      final locales = await _speech.locales();
      for (final locale in locales) {
        final normalized = locale.localeId.toLowerCase().replaceAll('-', '_');
        if (normalized == 'zh_cn' ||
            normalized.startsWith('zh_hans') ||
            normalized.startsWith('zh')) {
          return locale.localeId;
        }
      }
      final systemLocale = await _speech.systemLocale();
      final normalizedSystem = systemLocale?.localeId.toLowerCase().replaceAll(
        '-',
        '_',
      );
      if (normalizedSystem?.startsWith('zh') ?? false) {
        return systemLocale?.localeId;
      }
      return 'zh_CN';
    } catch (_) {
      return 'zh_CN';
    }
  }

  String _errorMessage(SpeechRecognitionError error) {
    final message = error.errorMsg.trim();
    if (message.isEmpty) return '系统语音识别未返回结果';
    if (message.contains('permission')) return '麦克风或语音识别权限未授权';
    if (message.contains('network')) return '语音识别需要可用网络或系统语音服务';
    if (message.contains('no_match')) return '没有识别到清晰语音，请靠近麦克风再试';
    return '系统语音识别失败：$message';
  }
}
