import 'dart:async';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../models/source_info.dart';

typedef SharedImportHandler = Future<void> Function(SharedImport import);
typedef ShareReceiveErrorHandler = void Function(Object error);

class SharedImport {
  const SharedImport({required this.sourceType, this.rawText, this.imagePath});

  final SourceType sourceType;
  final String? rawText;
  final String? imagePath;

  bool get hasContent =>
      (rawText != null && rawText!.trim().isNotEmpty) ||
      (imagePath != null && imagePath!.trim().isNotEmpty);
}

class ShareReceiveService {
  StreamSubscription<List<SharedMediaFile>>? _subscription;

  Future<void> start({
    required SharedImportHandler onImport,
    ShareReceiveErrorHandler? onError,
  }) async {
    await _subscription?.cancel();
    _subscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      (items) => _dispatch(items, onImport),
      onError: onError,
    );

    final initial = await ReceiveSharingIntent.instance.getInitialMedia();
    if (initial.isNotEmpty) {
      await _dispatch(initial, onImport);
      await ReceiveSharingIntent.instance.reset();
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _dispatch(
    List<SharedMediaFile> items,
    SharedImportHandler onImport,
  ) async {
    final sharedText = items
        .map(_textFromItem)
        .whereType<String>()
        .map((text) => text.trim())
        .where((text) => text.isNotEmpty)
        .toSet()
        .join('\n');

    final images = items.where(_isImage).toList();
    if (images.isNotEmpty) {
      for (final image in images) {
        final import = SharedImport(
          sourceType: SourceType.shareImage,
          rawText: sharedText.isEmpty ? null : sharedText,
          imagePath: image.path,
        );
        if (import.hasContent) await onImport(import);
      }
      return;
    }

    if (sharedText.isNotEmpty) {
      await onImport(
        SharedImport(sourceType: SourceType.shareText, rawText: sharedText),
      );
    }
  }

  String? _textFromItem(SharedMediaFile item) {
    final parts = [
      item.message,
      if (item.type == SharedMediaType.text || item.type == SharedMediaType.url)
        item.path,
    ];
    final text = parts
        .whereType<String>()
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .join('\n');
    return text.isEmpty ? null : text;
  }

  bool _isImage(SharedMediaFile item) {
    if (item.type == SharedMediaType.image) return true;
    final mime = item.mimeType?.toLowerCase();
    if (mime != null && mime.startsWith('image/')) return true;
    final path = item.path.toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp') ||
        path.endsWith('.heic') ||
        path.endsWith('.heif');
  }
}
