import '../models/event_item.dart';
import '../models/source_info.dart';
import '../models/user_insight.dart';
import '../models/user_preference.dart';

class UserInsightService {
  const UserInsightService();

  static const int totalProfileFields = 9;

  UserInsightResult analyze({
    required UserPreference preference,
    required List<EventItem> confirmedEvents,
    required int pendingCount,
    required int scheduledReminderCount,
    Map<String, DateTime> unlockedAtById = const {},
    DateTime? now,
  }) {
    final analysisTime = now ?? DateTime.now();
    return UserInsightResult(
      persona: _buildPersona(
        preference: preference,
        confirmedEvents: confirmedEvents,
        pendingCount: pendingCount,
        scheduledReminderCount: scheduledReminderCount,
        now: analysisTime,
      ),
      achievements: _buildAchievements(
        preference: preference,
        confirmedEvents: confirmedEvents,
        unlockedAtById: unlockedAtById,
      ),
    );
  }

  int completedProfileFieldCount(UserPreference preference) {
    final values = [
      preference.avatarPath,
      preference.signature,
      preference.birthday,
      preference.school,
      preference.age,
      preference.gender,
      preference.major,
      preference.grade,
      preference.hometown,
    ];
    return values.where((value) => value.trim().isNotEmpty).length;
  }

  UserPersonaSummary _buildPersona({
    required UserPreference preference,
    required List<EventItem> confirmedEvents,
    required int pendingCount,
    required int scheduledReminderCount,
    required DateTime now,
  }) {
    final confirmedCount = confirmedEvents.length;
    final totalRecordCount = confirmedCount + pendingCount;
    final completedProfileFields = completedProfileFieldCount(preference);
    if (totalRecordCount < 3) {
      return UserPersonaSummary(
        title: '画像生成中',
        description: '继续确认时间线记录后，系统会结合个人资料生成更准确的使用偏好参考。',
        tags: const ['资料不足'],
        evidence: [
          '当前有 $totalRecordCount 条可用记录，至少需要 3 条历史记录',
          '个人资料已完善 $completedProfileFields/$totalProfileFields 项',
        ],
        completedProfileFields: completedProfileFields,
        totalProfileFields: totalProfileFields,
      );
    }

    final tags = <String>[];
    final evidence = <String>[];
    final expiredItemCount = confirmedEvents
        .where((event) => event.startTime?.isBefore(now) ?? false)
        .length;
    final locationReadyCount = confirmedEvents.where(_hasUsableLocation).length;
    final locationCompleteRate = confirmedEvents.isEmpty
        ? 0.0
        : locationReadyCount / confirmedEvents.length;
    final imageSourceCount = confirmedEvents
        .where((event) => _isImageSource(event.source.type))
        .length;
    final textSourceCount = confirmedEvents
        .where((event) => _isTextSource(event.source.type))
        .length;

    if (scheduledReminderCount >= 3 ||
        (confirmedCount > 0 && scheduledReminderCount * 2 >= confirmedCount)) {
      tags.add('提醒依赖型');
      evidence.add('当前有 $scheduledReminderCount 项真实本地提醒等待触发');
    }
    if (confirmedCount >= 5) {
      tags.add('时间线沉淀型');
      evidence.add('已确认 $confirmedCount 条时间线记录');
    }
    if (expiredItemCount > 0) {
      tags.add('过期事项沉淀');
      evidence.add('时间线中有 $expiredItemCount 条历史事项，可用于回看时间管理节奏');
    }
    if (pendingCount >= 3 || pendingCount > confirmedCount) {
      tags.add('待确认偏多');
      evidence.add('仍有 $pendingCount 条事项等待确认或补充');
    }
    if (completedProfileFields >= 6) {
      tags.add('资料完善度高');
      evidence.add('个人资料已完善 $completedProfileFields/$totalProfileFields 项');
    } else {
      evidence.add('个人资料已完善 $completedProfileFields/$totalProfileFields 项');
    }
    final hasSchool = preference.school.trim().isNotEmpty;
    final hasCampusStage =
        preference.major.trim().isNotEmpty ||
        preference.grade.trim().isNotEmpty;
    if (hasSchool && hasCampusStage) {
      tags.add('校园身份清晰');
      evidence.add('已填写学校及专业或年级信息');
    }
    if (locationCompleteRate >= 0.7 && confirmedEvents.isNotEmpty) {
      tags.add('地点信息完整');
      evidence.add('多数已确认记录包含地点信息');
    }
    if (imageSourceCount > textSourceCount && imageSourceCount > 0) {
      tags.add('图片导入常用');
      evidence.add('常通过图片入口导入校园通知');
    } else if (textSourceCount > 0) {
      tags.add('文本整理常用');
      evidence.add('常通过文本、语音、剪贴板或系统分享导入通知');
    }

    final dominantType = _dominantEventType(confirmedEvents);
    if (dominantType != null) {
      tags.add('$dominantType关注型');
      evidence.add('历史记录中“$dominantType”类型占比最高');
    }
    final dominantPeriod = _dominantSchedulePeriod(confirmedEvents);
    if (dominantPeriod != null) {
      tags.add('${dominantPeriod.label}节奏');
      evidence.add('有明确时间的事项多数安排在${dominantPeriod.label}');
    }

    if (tags.isEmpty) {
      tags.add('稳态整理');
      evidence.add('当前记录、提醒与确认状态较均衡');
    }

    final distinctTags = tags.toSet().take(6).toList();
    final title = distinctTags.contains('过期事项沉淀')
        ? '提醒节奏需要回看'
        : distinctTags.contains('待确认偏多')
        ? '待确认事项需要回看'
        : distinctTags.contains('提醒依赖型')
        ? '提醒辅助型'
        : distinctTags.contains('时间线沉淀型')
        ? '时间线整理型'
        : '稳态整理型';

    return UserPersonaSummary(
      title: title,
      description: '根据当前账号的个人资料、历史事项、提醒设置、导入来源与时间分布实时生成。',
      tags: distinctTags,
      evidence: evidence.toSet().take(8).toList(),
      completedProfileFields: completedProfileFields,
      totalProfileFields: totalProfileFields,
    );
  }

  List<UserAchievement> _buildAchievements({
    required UserPreference preference,
    required List<EventItem> confirmedEvents,
    required Map<String, DateTime> unlockedAtById,
  }) {
    final chronologicalEvents = [...confirmedEvents]
      ..sort(
        (left, right) =>
            _eventTimestamp(left).compareTo(_eventTimestamp(right)),
      );
    final completedProfileFields = completedProfileFieldCount(preference);
    final scheduledEvents = chronologicalEvents
        .where(_hasActuallyScheduledReminder)
        .toList();
    final locationEvents = chronologicalEvents
        .where(_hasUsableLocation)
        .toList();
    final sourceTypes = confirmedEvents
        .map((event) => event.source.type)
        .toSet();
    final eventTypes = confirmedEvents
        .map((event) => event.eventType.trim())
        .where((type) => type.isNotEmpty)
        .toSet();
    final activeDays = chronologicalEvents
        .map(_eventTimestampOrNull)
        .whereType<DateTime>()
        .map((date) => '${date.year}-${date.month}-${date.day}')
        .toSet();

    return [
      UserAchievement(
        id: 'first_weave',
        title: '初次织入',
        description: '确认首条事项并写入时间线',
        current: confirmedEvents.length,
        target: 1,
        progressLabel: '已确认 ${confirmedEvents.length}/1 条',
        unlockedAt: _resolveUnlockDate(
          unlockedAtById,
          'first_weave',
          _thresholdDate(chronologicalEvents, 1),
        ),
      ),
      UserAchievement(
        id: 'timeline_keeper',
        title: '持续沉淀',
        description: '累计确认 10 条真实时间线记录',
        current: confirmedEvents.length,
        target: 10,
        progressLabel: '已确认 ${confirmedEvents.length}/10 条',
        unlockedAt: _resolveUnlockDate(
          unlockedAtById,
          'timeline_keeper',
          _thresholdDate(chronologicalEvents, 10),
        ),
      ),
      UserAchievement(
        id: 'reminder_guard',
        title: '提醒守护',
        description: '为 3 条事项成功安排本地提醒',
        current: scheduledEvents.length,
        target: 3,
        progressLabel: '已排程 ${scheduledEvents.length}/3 条事项',
        unlockedAt: _resolveUnlockDate(
          unlockedAtById,
          'reminder_guard',
          _thresholdDate(scheduledEvents, 3),
        ),
      ),
      UserAchievement(
        id: 'multi_source',
        title: '多源采集',
        description: '使用 3 种不同入口织入事项',
        current: sourceTypes.length,
        target: 3,
        progressLabel: '已使用 ${sourceTypes.length}/3 种来源',
        unlockedAt: _resolveUnlockDate(
          unlockedAtById,
          'multi_source',
          _distinctThresholdDate<SourceType>(
            chronologicalEvents,
            (event) => event.source.type,
            3,
          ),
        ),
      ),
      UserAchievement(
        id: 'location_ready',
        title: '地点有序',
        description: '为 5 条事项保留有效地点',
        current: locationEvents.length,
        target: 5,
        progressLabel: '地点完整 ${locationEvents.length}/5 条',
        unlockedAt: _resolveUnlockDate(
          unlockedAtById,
          'location_ready',
          _thresholdDate(locationEvents, 5),
        ),
      ),
      UserAchievement(
        id: 'campus_profile',
        title: '校园名片',
        description: '完善 6 项真实个人资料',
        current: completedProfileFields,
        target: 6,
        progressLabel: '已完善 $completedProfileFields/6 项',
        unlockedAt: unlockedAtById['campus_profile'],
      ),
      UserAchievement(
        id: 'active_days',
        title: '多日沉淀',
        description: '在 3 个不同日期留下时间线记录',
        current: activeDays.length,
        target: 3,
        progressLabel: '已覆盖 ${activeDays.length}/3 个日期',
        unlockedAt: _resolveUnlockDate(
          unlockedAtById,
          'active_days',
          _distinctThresholdDate<String>(chronologicalEvents, (event) {
            final date = _eventTimestampOrNull(event);
            return date == null
                ? null
                : '${date.year}-${date.month}-${date.day}';
          }, 3),
        ),
      ),
      UserAchievement(
        id: 'category_explorer',
        title: '事项多面手',
        description: '沉淀 3 种不同类型的校园事项',
        current: eventTypes.length,
        target: 3,
        progressLabel: '已覆盖 ${eventTypes.length}/3 种类型',
        unlockedAt: _resolveUnlockDate(
          unlockedAtById,
          'category_explorer',
          _distinctThresholdDate<String>(chronologicalEvents, (event) {
            final type = event.eventType.trim();
            return type.isEmpty ? null : type;
          }, 3),
        ),
      ),
    ];
  }

  bool _hasActuallyScheduledReminder(EventItem event) {
    return event.reminders.any(
      (reminder) =>
          reminder.notificationId != null &&
          (reminder.scheduledAtIso?.trim().isNotEmpty ?? false),
    );
  }

  bool _hasUsableLocation(EventItem event) {
    final location = event.location?.trim() ?? '';
    return location.isNotEmpty && location != '无地点';
  }

  bool _isImageSource(SourceType type) {
    return type == SourceType.album ||
        type == SourceType.camera ||
        type == SourceType.shareImage;
  }

  bool _isTextSource(SourceType type) {
    return type == SourceType.manualText ||
        type == SourceType.shareText ||
        type == SourceType.clipboard ||
        type == SourceType.voice;
  }

  String? _dominantEventType(List<EventItem> events) {
    final counts = <String, int>{};
    for (final event in events) {
      final type = event.eventType.trim();
      if (type.isEmpty) continue;
      counts[type] = (counts[type] ?? 0) + 1;
    }
    if (counts.isEmpty) return null;
    final dominant = counts.entries.reduce(
      (left, right) => left.value >= right.value ? left : right,
    );
    if (dominant.value < 2 || dominant.value * 2 < events.length) return null;
    return dominant.key;
  }

  _SchedulePeriod? _dominantSchedulePeriod(List<EventItem> events) {
    final counts = <_SchedulePeriod, int>{};
    var timedCount = 0;
    for (final event in events) {
      final time = event.startTime;
      if (time == null) continue;
      timedCount++;
      final period = switch (time.hour) {
        >= 5 && < 12 => _SchedulePeriod.morning,
        >= 12 && < 18 => _SchedulePeriod.afternoon,
        _ => _SchedulePeriod.evening,
      };
      counts[period] = (counts[period] ?? 0) + 1;
    }
    if (timedCount < 3 || counts.isEmpty) return null;
    final dominant = counts.entries.reduce(
      (left, right) => left.value >= right.value ? left : right,
    );
    return dominant.value * 2 >= timedCount ? dominant.key : null;
  }

  DateTime _eventTimestamp(EventItem event) {
    return _eventTimestampOrNull(event) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  DateTime? _eventTimestampOrNull(EventItem event) {
    return DateTime.tryParse(event.createdAtIso) ?? event.startTime;
  }

  DateTime? _thresholdDate(List<EventItem> events, int target) {
    if (events.length < target) return null;
    return _eventTimestampOrNull(events[target - 1]);
  }

  DateTime? _resolveUnlockDate(
    Map<String, DateTime> unlockedAtById,
    String achievementId,
    DateTime? derivedDate,
  ) {
    return unlockedAtById[achievementId] ?? derivedDate;
  }

  DateTime? _distinctThresholdDate<T>(
    List<EventItem> events,
    T? Function(EventItem event) selector,
    int target,
  ) {
    final values = <T>{};
    for (final event in events) {
      final value = selector(event);
      if (value == null) continue;
      values.add(value);
      if (values.length >= target) return _eventTimestampOrNull(event);
    }
    return null;
  }
}

enum _SchedulePeriod {
  morning('上午'),
  afternoon('下午'),
  evening('晚间');

  const _SchedulePeriod(this.label);

  final String label;
}
