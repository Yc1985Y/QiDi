import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/achievement_unlock_record.dart';
import '../models/event_item.dart';
import '../models/export_record.dart';
import '../models/inbox_message.dart';
import '../models/parsed_notice.dart';
import '../models/user_preference.dart';

class StorageService {
  static const _eventsKey = 'timeweaver_events_json';
  static const _pendingKey = 'timeweaver_pending_json';
  static const _preferenceKey = 'timeweaver_preference_json';
  static const _inboxKey = 'timeweaver_inbox_json';
  static const _exportsKey = 'timeweaver_exports_json';
  static const _achievementUnlocksKey = 'timeweaver_achievement_unlocks_json';

  Future<List<EventItem>> loadEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_eventsKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => EventItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<ParsedNotice>> loadPendingNotices() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => ParsedNotice.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<UserPreference> loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_preferenceKey);
    if (raw == null || raw.isEmpty) return const UserPreference();
    return UserPreference.fromJson(Map<String, dynamic>.from(jsonDecode(raw)));
  }

  Future<List<InboxMessage>> loadInboxMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_inboxKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => InboxMessage.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<ExportRecord>> loadExportRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_exportsKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => ExportRecord.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<List<AchievementUnlockRecord>> loadAchievementUnlocks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_achievementUnlocksKey);
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map(
          (item) =>
              AchievementUnlockRecord.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.achievementId.isNotEmpty)
        .toList();
  }

  Future<void> saveEvents(List<EventItem> events) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _eventsKey,
      jsonEncode(events.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> savePendingNotices(List<ParsedNotice> notices) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _pendingKey,
      jsonEncode(notices.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> savePreference(UserPreference preference) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_preferenceKey, jsonEncode(preference.toJson()));
  }

  Future<void> saveInboxMessages(List<InboxMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _inboxKey,
      jsonEncode(messages.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> saveExportRecords(List<ExportRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _exportsKey,
      jsonEncode(records.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> saveAchievementUnlocks(
    List<AchievementUnlockRecord> records,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _achievementUnlocksKey,
      jsonEncode(records.map((item) => item.toJson()).toList()),
    );
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_eventsKey);
    await prefs.remove(_pendingKey);
    await prefs.remove(_preferenceKey);
    await prefs.remove(_inboxKey);
    await prefs.remove(_exportsKey);
    await prefs.remove(_achievementUnlocksKey);
  }
}
