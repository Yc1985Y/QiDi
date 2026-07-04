import '../models/parsed_notice.dart';
import 'date_utils.dart';

class Validators {
  static String? confirmBlocker(ParsedNotice notice) {
    if (notice.title.trim().isEmpty) return '请补充标题';
    if (notice.startTimeIso == null || notice.startTimeIso!.trim().isEmpty) {
      return '请补充开始时间';
    }
    if (ZhishiDateUtils.parse(notice.startTimeIso!) == null) {
      return '时间格式需要能被识别';
    }
    return null;
  }
}
