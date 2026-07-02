import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/event_item.dart';
import '../models/parsed_notice.dart';
import '../models/user_preference.dart';

class StorageService {
  static const _eventsKey = 'timeweaver_events_json';
  static const _pendingKey = 'timeweaver_pending_json';
  static const _preferenceKey = 'timeweaver_preference_json';

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

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_eventsKey);
    await prefs.remove(_pendingKey);
    await prefs.remove(_preferenceKey);
  }
}
