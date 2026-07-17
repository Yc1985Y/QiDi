class NoticeSegmentExtractor {
  static final RegExp _strongDateMarker = RegExp(
    r'(?:周[一二三四五六日天]|星期[一二三四五六日天]|今天|明天|后天|本周[一二三四五六日天]?|下周[一二三四五六日天]?|\d{1,2}月\d{1,2}日|\d{4}[./-]\d{1,2}[./-]\d{1,2})',
  );
  static final RegExp _timeMarker = RegExp(
    r'(?:\d{1,2}:\d{2}|\d{1,2}点(?:\d{1,2}分?)?|\d{1,2}时(?:\d{1,2}分?)?)',
  );

  static List<String> extractIndependentScheduleSegments(String sourceText) {
    final normalized = sourceText
        .replaceAll('\r\n', '\n')
        .replaceAll('\u3000', ' ')
        .trim();
    if (normalized.isEmpty) return const [];

    final segments = _splitByLines(normalized)
        .expand(_splitByInlineDates)
        .map(_normalizeSegment)
        .where((segment) => segment.isNotEmpty && _containsTimeContext(segment))
        .toSet()
        .toList();
    return segments.length >= 2 ? segments : const [];
  }

  static List<String> _splitByLines(String sourceText) {
    final lines = sourceText
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.length <= 1) return [sourceText];

    final grouped = <String>[];
    final current = StringBuffer();
    for (final line in lines) {
      final currentText = current.toString();
      final startsNewBlock =
          _containsStrongDate(line) &&
          currentText.trim().isNotEmpty &&
          _containsStrongDate(currentText);
      if (startsNewBlock) {
        grouped.add(currentText.trim());
        current.clear();
      }
      if (current.toString().trim().isNotEmpty) current.write('\n');
      current.write(line);
    }
    if (current.toString().trim().isNotEmpty) {
      grouped.add(current.toString().trim());
    }
    return grouped.isEmpty ? [sourceText] : grouped;
  }

  static List<String> _splitByInlineDates(String segment) {
    final matches = _strongDateMarker.allMatches(segment).toList();
    if (matches.length < 2) return [segment];

    final sharedPrefix = segment
        .substring(0, matches.first.start)
        .trim()
        .replaceFirst(RegExp(r'[：:\-\s]+$'), '');
    return List.generate(matches.length, (index) {
      final start = matches[index].start;
      final end = index + 1 < matches.length
          ? matches[index + 1].start
          : segment.length;
      final slice = segment
          .substring(start, end)
          .trim()
          .replaceFirst(RegExp(r'^[，,；;。、]+'), '')
          .replaceFirst(RegExp(r'[，,；;。、]+$'), '');
      return _normalizeSegment(
        sharedPrefix.isEmpty || slice.startsWith(sharedPrefix)
            ? slice
            : '$sharedPrefix $slice',
      );
    });
  }

  static String _normalizeSegment(String segment) {
    return segment.replaceAll('\n', ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool _containsStrongDate(String text) {
    return _strongDateMarker.hasMatch(text);
  }

  static bool _containsTimeContext(String text) {
    return _containsStrongDate(text) || _timeMarker.hasMatch(text);
  }
}
