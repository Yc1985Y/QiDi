import 'dart:io';

import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/event_item.dart';
import '../utils/date_utils.dart';

class TimelineExportResult {
  const TimelineExportResult({required this.path, required this.bytes});

  final String path;
  final int bytes;
}

class TimelineExportService {
  Future<TimelineExportResult> exportPdf(List<EventItem> events) async {
    if (events.isEmpty) {
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

    final ordered = events.toList()
      ..sort((a, b) {
        final left = a.startTime ?? DateTime(9999);
        final right = b.startTime ?? DateTime(9999);
        return left.compareTo(right);
      });

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
              '导出时间：${ZhishiDateUtils.formatDateTime(DateTime.now().toIso8601String())}',
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

    final baseDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory(
      '${baseDir.path}${Platform.pathSeparator}exports',
    );
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(
      '${exportDir.path}${Platform.pathSeparator}timeline-$timestamp.pdf',
    );
    final bytes = await doc.save();
    await file.writeAsBytes(bytes, flush: true);
    return TimelineExportResult(path: file.path, bytes: bytes.length);
  }

  Future<bool> open(String path) async {
    final result = await OpenFilex.open(path);
    return result.type == ResultType.done;
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

class TimelineExportException implements Exception {
  const TimelineExportException(this.message);

  final String message;

  @override
  String toString() => message;
}
