enum SourceType {
  manualText('manual_text', '手动输入文本'),
  album('album', '相册图片'),
  camera('camera', '拍摄图片'),
  shareText('share_text', '分享文本'),
  shareImage('share_image', '分享图片'),
  clipboard('clipboard', '剪贴板文本'),
  voice('voice', '语音文本');

  const SourceType(this.value, this.label);

  final String value;
  final String label;

  static SourceType fromValue(String? value) {
    return SourceType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => SourceType.manualText,
    );
  }
}

class SourceInfo {
  const SourceInfo({
    required this.type,
    this.rawText,
    this.imagePath,
    this.ocrText,
    this.importedAtIso,
  });

  final SourceType type;
  final String? rawText;
  final String? imagePath;
  final String? ocrText;
  final String? importedAtIso;

  String get label => type.label;

  SourceInfo copyWith({
    SourceType? type,
    String? rawText,
    String? imagePath,
    String? ocrText,
    String? importedAtIso,
  }) {
    return SourceInfo(
      type: type ?? this.type,
      rawText: rawText ?? this.rawText,
      imagePath: imagePath ?? this.imagePath,
      ocrText: ocrText ?? this.ocrText,
      importedAtIso: importedAtIso ?? this.importedAtIso,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'rawText': rawText,
      'imagePath': imagePath,
      'ocrText': ocrText,
      'importedAtIso': importedAtIso,
    };
  }

  factory SourceInfo.fromJson(Map<String, dynamic> json) {
    return SourceInfo(
      type: SourceType.fromValue(json['type'] as String?),
      rawText: json['rawText'] as String?,
      imagePath: json['imagePath'] as String?,
      ocrText: json['ocrText'] as String?,
      importedAtIso: json['importedAtIso'] as String?,
    );
  }
}
