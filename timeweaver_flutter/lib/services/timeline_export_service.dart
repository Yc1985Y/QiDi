import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/event_item.dart';
import '../utils/date_utils.dart';

enum TimelineExportFormat {
  pdf('PDF', 'pdf'),
  png('PNG', 'png'),
  jpg('JPG', 'jpg');

  const TimelineExportFormat(this.label, this.extension);

  final String label;
  final String extension;
}

class TimelineExportResult {
  const TimelineExportResult({
    required this.path,
    required this.bytes,
    required this.format,
  });

  final String path;
  final int bytes;
  final TimelineExportFormat format;
}

class TimelineExportService {
  Future<TimelineExportResult> export(
    List<EventItem> events,
    TimelineExportFormat format,
  ) {
    switch (format) {
      case TimelineExportFormat.pdf:
        return exportPdf(events);
      case TimelineExportFormat.png:
        return exportImage(events, TimelineExportFormat.png);
      case TimelineExportFormat.jpg:
        return exportImage(events, TimelineExportFormat.jpg);
    }
  }

  Future<TimelineExportResult> exportPdf(List<EventItem> events) async {
    final ordered = _orderedEvents(events);
    if (ordered.isEmpty) {
      throw const TimelineExportException('时间线为空，无法导出 PDF');
    }

    final fontData = await rootBundle.load(
      'assets/fonts/NotoSansSC-Regular.otf',
    );
    final baseFont = pw.Font.ttf(fontData);
    final doc = pw.Document(
      title: '织时时间线',
      author: '织时',
      creator: '织时 Flutter',
    );

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 34),
          theme: pw.ThemeData.withFont(base: baseFont, bold: baseFont),
        ),
        header: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '织时时间线',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#003528'),
              ),
            ),
            pw.Text(
              '导出时间：${ZhishiDateUtils.formatExport(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ],
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            '${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 16),
          pw.Text(
            '共 ${ordered.length} 条已确认校园事项',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 14),
          ...ordered.map(_eventBlock),
        ],
      ),
    );

    final bytes = await doc.save();
    return _writeExportBytes(bytes, TimelineExportFormat.pdf);
  }

  Future<TimelineExportResult> exportImage(
    List<EventItem> events,
    TimelineExportFormat format,
  ) async {
    final ordered = _orderedEvents(events);
    if (ordered.isEmpty) {
      throw TimelineExportException('时间线为空，无法导出 ${format.label}');
    }

    final pngBytes = await _renderSnapshotPng(ordered);
    final bytes = switch (format) {
      TimelineExportFormat.png => pngBytes,
      TimelineExportFormat.jpg => _encodeJpgFromPng(pngBytes),
      TimelineExportFormat.pdf => throw const TimelineExportException(
        '图片导出不支持 PDF 格式',
      ),
    };
    return _writeExportBytes(bytes, format);
  }

  Future<bool> open(String path) async {
    final result = await OpenFilex.open(path);
    return result.type == ResultType.done;
  }

  Future<TimelineExportResult> _writeExportBytes(
    Uint8List bytes,
    TimelineExportFormat format,
  ) async {
    final exportDir = await _ensureExportDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(
      '${exportDir.path}${Platform.pathSeparator}timeline-$timestamp.${format.extension}',
    );
    await file.writeAsBytes(bytes, flush: true);
    return TimelineExportResult(
      path: file.path,
      bytes: bytes.length,
      format: format,
    );
  }

  Future<Directory> _ensureExportDirectory() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(
      '${baseDir.path}${Platform.pathSeparator}exports',
    );
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  List<EventItem> _orderedEvents(List<EventItem> events) {
    return events.toList()..sort((a, b) {
      final left = a.startTime ?? DateTime(9999);
      final right = b.startTime ?? DateTime(9999);
      return left.compareTo(right);
    });
  }

  Future<Uint8List> _renderSnapshotPng(List<EventItem> events) async {
    final lineItems = _buildSnapshotLines(events);
    const width = 1400.0;
    final height =
        (lineItems.fold<double>(
                  260,
                  (value, item) => value + item.estimatedHeight,
                ) +
                100)
            .clamp(960, 5400)
            .toDouble();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final background = Paint()..color = const Color(0xFFFFF8F2);
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), background);

    final accentPaint = Paint()..color = const Color(0xFFEAF7F0);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(56, 56, width - 112, 168),
        const Radius.circular(28),
      ),
      accentPaint,
    );

    var cursorY = 92.0;
    _paintText(
      canvas,
      '织时时间线',
      const Offset(88, 92),
      const TextStyle(
        color: Color(0xFF003528),
        fontSize: 42,
        fontWeight: FontWeight.w800,
      ),
      maxWidth: width - 176,
    );
    cursorY += 62;
    _paintText(
      canvas,
      '导出时间：${ZhishiDateUtils.formatExport(DateTime.now())}  ·  共 ${events.length} 条已确认事项',
      Offset(88, cursorY),
      const TextStyle(
        color: Color(0xFF5B6762),
        fontSize: 22,
        fontWeight: FontWeight.w500,
      ),
      maxWidth: width - 176,
    );

    var top = 266.0;
    for (final item in lineItems) {
      final blockHeight = item.estimatedHeight - 14;
      final cardRect = Rect.fromLTWH(56, top, width - 112, blockHeight);
      canvas.drawRRect(
        RRect.fromRectAndRadius(cardRect, const Radius.circular(24)),
        Paint()..color = Colors.white.withValues(alpha: 0.96),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(cardRect, const Radius.circular(24)),
        Paint()
          ..color = const Color(0xFFF0E4D6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(78, top + 22, 10, blockHeight - 44),
          const Radius.circular(999),
        ),
        Paint()..color = const Color(0xFFB2EFD9),
      );

      var lineY = top + 24;
      for (final textLine in item.lines) {
        _paintText(
          canvas,
          textLine.text,
          Offset(textLine.indent == 0 ? 116 : 132, lineY),
          textLine.style,
          maxWidth: width - 220,
        );
        lineY += textLine.height;
      }
      top += item.estimatedHeight;
    }

    final image = await recorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    if (data == null) {
      throw const TimelineExportException('图片导出失败，未生成位图数据');
    }
    return data.buffer.asUint8List();
  }

  Uint8List _encodeJpgFromPng(Uint8List pngBytes) {
    final decoded = img.decodePng(pngBytes);
    if (decoded == null) {
      throw const TimelineExportException('JPG 导出失败，无法解析 PNG 中间结果');
    }
    return Uint8List.fromList(img.encodeJpg(decoded, quality: 94));
  }

  List<_SnapshotBlock> _buildSnapshotLines(List<EventItem> events) {
    final blocks = <_SnapshotBlock>[];
    for (var i = 0; i < events.length; i++) {
      final event = events[i];
      final lines = <_SnapshotLine>[
        _SnapshotLine(
          text: '${i + 1}. ${event.title}',
          style: const TextStyle(
            color: Color(0xFF261900),
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.32,
          ),
          height: 50,
        ),
        _SnapshotLine(
          text:
              '${event.eventType} · ${ZhishiDateUtils.formatDateTime(event.startTimeIso)}',
          style: const TextStyle(
            color: Color(0xFF003528),
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
          height: 38,
        ),
      ];

      if (event.deadlineIso != null && event.deadlineIso!.trim().isNotEmpty) {
        lines.add(
          _SnapshotLine(
            text: '截止：${ZhishiDateUtils.formatDateTime(event.deadlineIso)}',
            style: _snapshotBodyStyle,
            height: 32,
            indent: 1,
          ),
        );
      }
      if (event.location != null && event.location!.trim().isNotEmpty) {
        lines.add(
          _SnapshotLine(
            text: '地点：${event.location!}',
            style: _snapshotBodyStyle,
            height: 32,
            indent: 1,
          ),
        );
      }
      if (event.description != null && event.description!.trim().isNotEmpty) {
        lines.add(
          _SnapshotLine(
            text: '说明：${event.description!}',
            style: _snapshotBodyStyle,
            height: 40,
            indent: 1,
          ),
        );
      }
      lines.add(
        _SnapshotLine(
          text: '来源：${event.source.label}',
          style: _snapshotBodyStyle,
          height: 32,
          indent: 1,
        ),
      );
      if (event.reminders.isNotEmpty) {
        lines.add(
          _SnapshotLine(
            text: '提醒：${event.reminders.map((item) => item.label).join(' / ')}',
            style: _snapshotBodyStyle,
            height: 32,
            indent: 1,
          ),
        );
      }

      final estimatedHeight =
          lines.fold<double>(58, (value, line) => value + line.height) + 18;
      blocks.add(
        _SnapshotBlock(lines: lines, estimatedHeight: estimatedHeight),
      );
    }
    return blocks;
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset,
    TextStyle style, {
    required double maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 20,
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  pw.Widget _eventBlock(EventItem event) {
    final accent = PdfColor.fromHex('#B2EFD9');
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromHex('#E6DED3')),
        borderRadius: pw.BorderRadius.circular(8),
        color: PdfColor.fromHex('#FFFCF8'),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 5,
                height: 44,
                decoration: pw.BoxDecoration(
                  color: accent,
                  borderRadius: pw.BorderRadius.circular(4),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      event.title,
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#261900'),
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      '${event.eventType} · ${ZhishiDateUtils.formatDateTime(event.startTimeIso)}',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (event.deadlineIso != null && event.deadlineIso!.trim().isNotEmpty)
            _line('截止', ZhishiDateUtils.formatDateTime(event.deadlineIso)),
          if (event.location != null && event.location!.trim().isNotEmpty)
            _line('地点', event.location!),
          if (event.description != null && event.description!.trim().isNotEmpty)
            _line('说明', event.description!),
          _line('来源', event.source.label),
          if (event.reminders.isNotEmpty)
            _line('提醒', event.reminders.map((item) => item.label).join(' / ')),
        ],
      ),
    );
  }

  pw.Widget _line(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 6),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label：',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#003528'),
              ),
            ),
            pw.TextSpan(text: value),
          ],
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey900),
        ),
      ),
    );
  }
}

const _snapshotBodyStyle = TextStyle(
  color: Color(0xFF5B6762),
  fontSize: 22,
  fontWeight: FontWeight.w500,
  height: 1.42,
);

class _SnapshotBlock {
  const _SnapshotBlock({required this.lines, required this.estimatedHeight});

  final List<_SnapshotLine> lines;
  final double estimatedHeight;
}

class _SnapshotLine {
  const _SnapshotLine({
    required this.text,
    required this.style,
    required this.height,
    this.indent = 0,
  });

  final String text;
  final TextStyle style;
  final double height;
  final int indent;
}

class TimelineExportException implements Exception {
  const TimelineExportException(this.message);

  final String message;

  @override
  String toString() => message;
}
