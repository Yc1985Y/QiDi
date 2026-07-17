import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:package_info_plus/package_info_plus.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as web_socket_status;

import 'api_config.dart';
import 'vivo_asr_protocol.dart';

class SpeechService {
  static const _maximumRecordingDuration = Duration(seconds: 15);
  static const _resultIdleTimeout = Duration(milliseconds: 1500);
  static const _pcmFrameBytes = 1280;

  final AudioRecorder _recorder = AudioRecorder();
  Completer<void>? _stopSignal;
  Completer<void>? _sessionFinished;
  bool _cancelRequested = false;
  bool _isListening = false;

  bool get isListening => _isListening;

  Future<void> listen({
    required void Function(String text) onText,
    void Function(String message)? onError,
    void Function()? onDone,
  }) async {
    if (_isListening) return;
    if (!ApiConfig.hasVivoAsrConfig) {
      onError?.call('语音识别需要配置真实 VLM_API_KEY');
      return;
    }

    _isListening = true;
    _cancelRequested = false;
    _stopSignal = Completer<void>();
    _sessionFinished = Completer<void>();

    IOWebSocketChannel? channel;
    StreamSubscription<dynamic>? socketSubscription;
    StreamSubscription<Uint8List>? audioSubscription;
    final socketFinished = Completer<void>();
    final segments = <int, String>{};
    var finalText = '';
    var pendingAudio = BytesBuilder(copy: false);

    try {
      if (!await _recorder.hasPermission()) {
        throw const SpeechServiceException('麦克风权限未授权');
      }

      final requestId = const Uuid().v4().replaceAll('-', '');
      final packageInfo = await PackageInfo.fromPlatform();
      final systemVersion = Platform.operatingSystemVersion;
      final uri = buildVivoAsrUri(
        endpoint: ApiConfig.vivoAsrEndpoint,
        engineId: ApiConfig.vivoAsrEngineId,
        requestId: requestId,
        packageName: packageInfo.packageName,
        model: Platform.localHostname,
        systemVersion: systemVersion,
        systemTimeMillis: DateTime.now().millisecondsSinceEpoch,
      );

      channel = IOWebSocketChannel.connect(
        uri,
        headers: {'Authorization': 'Bearer ${ApiConfig.apiKey}'},
        connectTimeout: const Duration(seconds: 8),
      );
      socketSubscription = channel.stream.listen(
        (message) {
          if (message is! String) return;
          final event = parseVivoAsrMessage(message);
          if (event.isError) {
            if (!socketFinished.isCompleted) {
              socketFinished.completeError(
                SpeechServiceException(event.error!),
              );
            }
            return;
          }
          final text = event.text.trim();
          if (text.isNotEmpty) {
            if (event.resultId != null) {
              segments[event.resultId!] = text;
            } else {
              finalText = text;
            }
          }
          if (event.isFinish && !socketFinished.isCompleted) {
            socketFinished.complete();
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (!socketFinished.isCompleted) {
            socketFinished.completeError(error, stackTrace);
          }
        },
        onDone: () {
          if (!socketFinished.isCompleted) socketFinished.complete();
        },
      );
      await channel.ready.timeout(const Duration(seconds: 8));
      channel.sink.add(buildVivoAsrStartFrame(requestId: requestId));

      final audioStream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
          streamBufferSize: _pcmFrameBytes,
        ),
      );
      audioSubscription = audioStream.listen((chunk) {
        pendingAudio.add(chunk);
        final bytes = pendingAudio.takeBytes();
        var offset = 0;
        while (bytes.length - offset >= _pcmFrameBytes) {
          channel?.sink.add(
            Uint8List.sublistView(bytes, offset, offset + _pcmFrameBytes),
          );
          offset += _pcmFrameBytes;
        }
        if (offset < bytes.length) {
          pendingAudio.add(Uint8List.sublistView(bytes, offset));
        }
      });

      await Future.any([
        _stopSignal!.future,
        Future<void>.delayed(_maximumRecordingDuration),
        socketFinished.future,
      ]);
      await _recorder.stop();
      await audioSubscription.cancel();
      audioSubscription = null;

      if (!_cancelRequested) {
        final remaining = pendingAudio.takeBytes();
        if (remaining.isNotEmpty) channel.sink.add(remaining);
        channel.sink.add(Uint8List.fromList('--end--'.codeUnits));
        await Future.any([
          socketFinished.future,
          Future<void>.delayed(_resultIdleTimeout),
        ]);
      }

      if (_cancelRequested) return;
      final text = segments.isNotEmpty
          ? mergeVivoAsrSegments(
              (segments.entries.toList()
                    ..sort((a, b) => a.key.compareTo(b.key)))
                  .map((entry) => entry.value),
            ).trim()
          : finalText.trim();
      if (text.isEmpty) {
        throw const SpeechServiceException('vivo 语音识别未返回文本');
      }
      onText(text);
      onDone?.call();
    } catch (error) {
      if (!_cancelRequested) onError?.call(_errorMessage(error));
    } finally {
      if (await _recorder.isRecording()) await _recorder.cancel();
      await audioSubscription?.cancel();
      await socketSubscription?.cancel();
      if (channel != null) {
        channel.sink.add(Uint8List.fromList('--close--'.codeUnits));
        await channel.sink.close(web_socket_status.normalClosure, 'done');
      }
      _isListening = false;
      _stopSignal = null;
      if (!(_sessionFinished?.isCompleted ?? true)) {
        _sessionFinished!.complete();
      }
    }
  }

  Future<void> stop() async {
    if (!_isListening) return;
    if (!(_stopSignal?.isCompleted ?? true)) _stopSignal!.complete();
    await _sessionFinished?.future;
  }

  Future<void> cancel() async {
    if (!_isListening) return;
    _cancelRequested = true;
    if (!(_stopSignal?.isCompleted ?? true)) _stopSignal!.complete();
    await _sessionFinished?.future;
  }

  Future<void> dispose() async {
    await cancel();
    await _recorder.dispose();
  }

  String _errorMessage(Object error) {
    final message = error.toString();
    if (message.contains('VLM_API_KEY')) {
      return '语音识别需要配置真实 VLM_API_KEY';
    }
    if (message.toLowerCase().contains('permission')) {
      return '麦克风权限未授权';
    }
    if (message.contains('未返回文本')) {
      return '没有识别到清晰语音，请靠近麦克风再试';
    }
    if (error is TimeoutException ||
        message.contains('Socket') ||
        message.contains('WebSocket') ||
        message.contains('Connection')) {
      return 'vivo 语音识别服务连接失败，请检查网络后重试';
    }
    return 'vivo 语音识别失败：${message.replaceFirst('SpeechServiceException: ', '')}';
  }
}

class SpeechServiceException implements Exception {
  const SpeechServiceException(this.message);

  final String message;

  @override
  String toString() => 'SpeechServiceException: $message';
}
