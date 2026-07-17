import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeweaver_flutter/models/achievement_unlock_record.dart';
import 'package:timeweaver_flutter/models/event_item.dart';
import 'package:timeweaver_flutter/models/reminder_item.dart';
import 'package:timeweaver_flutter/models/source_info.dart';
import 'package:timeweaver_flutter/models/user_insight.dart';
import 'package:timeweaver_flutter/models/user_preference.dart';
import 'package:timeweaver_flutter/services/user_insight_service.dart';
import 'package:timeweaver_flutter/services/storage_service.dart';

void main() {
  const service = UserInsightService();

  test(
    'persona waits for enough history and still reports real profile data',
    () {
      final result = service.analyze(
        preference: const UserPreference(school: '织时大学', major: '计算机'),
        confirmedEvents: [_event(id: 'one')],
        pendingCount: 1,
        scheduledReminderCount: 0,
        now: DateTime(2026, 7, 17),
      );

      expect(result.persona.title, '画像生成中');
      expect(result.persona.tags, ['资料不足']);
      expect(result.persona.evidence, contains('当前有 2 条可用记录，至少需要 3 条历史记录'));
      expect(result.persona.evidence, contains('个人资料已完善 2/9 项'));
    },
  );

  test('persona combines profile fields with historical event patterns', () {
    const preference = UserPreference(
      school: '织时大学',
      major: '计算机',
      grade: '大三',
      signature: '保持专注',
      birthday: '2004-01-01',
      hometown: '杭州',
    );
    final events = [
      _event(
        id: 'one',
        type: '讲座',
        sourceType: SourceType.manualText,
        startTime: '2026-07-18T09:00:00',
      ),
      _event(
        id: 'two',
        type: '讲座',
        sourceType: SourceType.shareText,
        startTime: '2026-07-19T10:00:00',
      ),
      _event(
        id: 'three',
        type: '讲座',
        sourceType: SourceType.voice,
        startTime: '2026-07-20T11:00:00',
      ),
    ];

    final persona = service
        .analyze(
          preference: preference,
          confirmedEvents: events,
          pendingCount: 0,
          scheduledReminderCount: 0,
          now: DateTime(2026, 7, 17),
        )
        .persona;

    expect(persona.tags, contains('资料完善度高'));
    expect(persona.tags, contains('校园身份清晰'));
    expect(persona.tags, contains('讲座关注型'));
    expect(persona.tags, contains('上午节奏'));
    expect(persona.evidence, contains('个人资料已完善 6/9 项'));
    expect(persona.description, contains('个人资料'));
  });

  test(
    'achievements use real progress and require successful reminder scheduling',
    () {
      const preference = UserPreference(
        school: '织时大学',
        major: '计算机',
        grade: '大三',
        signature: '保持专注',
        birthday: '2004-01-01',
        hometown: '杭州',
      );
      final events = [
        _event(
          id: 'one',
          type: '讲座',
          sourceType: SourceType.manualText,
          createdAt: '2026-07-01T08:00:00',
          reminders: [_scheduledReminder('one')],
        ),
        _event(
          id: 'two',
          type: '会议',
          sourceType: SourceType.album,
          createdAt: '2026-07-02T08:00:00',
          reminders: [_scheduledReminder('two')],
        ),
        _event(
          id: 'three',
          type: '考试',
          sourceType: SourceType.voice,
          createdAt: '2026-07-03T08:00:00',
          reminders: const [
            ReminderItem(
              id: 'three-reminder',
              eventId: 'three',
              label: '提前1小时',
              minutesBefore: 60,
            ),
          ],
        ),
      ];

      final achievements = service
          .analyze(
            preference: preference,
            confirmedEvents: events,
            pendingCount: 0,
            scheduledReminderCount: 2,
            now: DateTime(2026, 7, 17),
          )
          .achievements;

      UserAchievement achievement(String id) =>
          achievements.singleWhere((item) => item.id == id);

      expect(achievement('first_weave').isUnlocked, isTrue);
      expect(achievement('multi_source').isUnlocked, isTrue);
      expect(achievement('active_days').isUnlocked, isTrue);
      expect(achievement('category_explorer').isUnlocked, isTrue);
      expect(achievement('campus_profile').isUnlocked, isTrue);
      expect(achievement('reminder_guard').isUnlocked, isFalse);
      expect(achievement('reminder_guard').current, 2);
      expect(achievement('location_ready').isUnlocked, isFalse);
      expect(achievement('first_weave').unlockedAt, DateTime(2026, 7, 1, 8));
    },
  );

  test('empty account data never receives a pre-unlocked achievement', () {
    final result = service.analyze(
      preference: const UserPreference(),
      confirmedEvents: const [],
      pendingCount: 0,
      scheduledReminderCount: 0,
      now: DateTime(2026, 7, 17),
    );

    expect(result.unlockedAchievementCount, 0);
    expect(
      result.achievements.where((achievement) => achievement.isUnlocked),
      isEmpty,
    );
  });

  test('persisted achievement remains unlocked after source data changes', () {
    final unlockedAt = DateTime(2026, 7, 16, 9);
    final result = service.analyze(
      preference: const UserPreference(),
      confirmedEvents: const [],
      pendingCount: 0,
      scheduledReminderCount: 0,
      unlockedAtById: {'first_weave': unlockedAt},
      now: DateTime(2026, 7, 17),
    );
    final achievement = result.achievements.singleWhere(
      (item) => item.id == 'first_weave',
    );

    expect(achievement.current, 0);
    expect(achievement.isUnlocked, isTrue);
    expect(achievement.progress, 1);
    expect(achievement.unlockedAt, unlockedAt);
  });

  test('achievement unlock storage preserves account ownership', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    final records = [
      AchievementUnlockRecord(
        achievementId: 'first_weave',
        unlockedAtMillis: DateTime(2026, 7, 16).millisecondsSinceEpoch,
        ownerAccount: 'account-a',
      ),
      AchievementUnlockRecord(
        achievementId: 'campus_profile',
        unlockedAtMillis: DateTime(2026, 7, 17).millisecondsSinceEpoch,
        ownerAccount: 'account-b',
      ),
    ];

    await storage.saveAchievementUnlocks(records);
    final restored = await storage.loadAchievementUnlocks();

    expect(restored, hasLength(2));
    expect(restored.first.ownerAccount, 'account-a');
    expect(restored.last.ownerAccount, 'account-b');
    expect(restored.first.achievementId, 'first_weave');
  });
}

EventItem _event({
  required String id,
  String type = '校园安排',
  SourceType sourceType = SourceType.manualText,
  String createdAt = '2026-07-01T08:00:00',
  String startTime = '2026-07-18T09:00:00',
  List<ReminderItem> reminders = const [],
}) {
  return EventItem(
    id: id,
    title: '$type-$id',
    eventType: type,
    startTimeIso: startTime,
    location: '教学楼 $id',
    source: SourceInfo(type: sourceType),
    reminders: reminders,
    createdAtIso: createdAt,
    updatedAtIso: createdAt,
  );
}

ReminderItem _scheduledReminder(String eventId) {
  return ReminderItem(
    id: '$eventId-reminder',
    eventId: eventId,
    label: '提前1小时',
    minutesBefore: 60,
    scheduledAtIso: '2026-07-18T08:00:00',
    notificationId: eventId.hashCode,
  );
}
