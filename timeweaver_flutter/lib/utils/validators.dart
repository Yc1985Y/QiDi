import '../models/parsed_notice.dart';
import 'date_utils.dart';

class Validators {
  static String? confirmBlocker(ParsedNotice notice) {
    if (notice.action == NoticeAction.navigate) {
      if (notice.location?.trim().isEmpty ?? true) return '请补充需要导航的地点';
      return null;
    }
    if (notice.title.trim().isEmpty) return '请补充标题';
    if (notice.startTimeIso == null || notice.startTimeIso!.trim().isEmpty) {
      return '请补充开始时间';
    }
    final parsedTime = ZhishiDateUtils.parse(notice.startTimeIso!);
    if (parsedTime == null) {
      return '时间格式需要能被识别';
    }
    if (parsedTime.isBefore(
      DateTime.now().subtract(const Duration(minutes: 30)),
    )) {
      return '事项时间已经过期，请核对后再确认';
    }
    return null;
  }
}
