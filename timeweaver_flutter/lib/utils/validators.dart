import '../models/parsed_notice.dart';

class Validators {
  static String? confirmBlocker(ParsedNotice notice) {
    if (notice.title.trim().isEmpty) return '请补充标题';
    if (notice.startTimeIso == null || notice.startTimeIso!.trim().isEmpty) {
      return '请补充开始时间';
    }
    if (DateTime.tryParse(notice.startTimeIso!.replaceFirst(' ', 'T')) ==
        null) {
      return '时间格式需要能被识别';
    }
    return null;
  }
}
