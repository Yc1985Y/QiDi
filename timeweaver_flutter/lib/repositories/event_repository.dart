import '../models/achievement_unlock_record.dart';
import '../models/event_item.dart';
import '../models/export_record.dart';
import '../models/inbox_message.dart';
import '../models/parsed_notice.dart';
import '../models/user_preference.dart';
import '../services/storage_service.dart';

class EventRepository {
  EventRepository(this._storageService);

  final StorageService _storageService;

  Future<List<EventItem>> loadEvents() => _storageService.loadEvents();

  Future<List<ParsedNotice>> loadPendingNotices() =>
      _storageService.loadPendingNotices();

  Future<UserPreference> loadPreference() => _storageService.loadPreference();

  Future<List<InboxMessage>> loadInboxMessages() =>
      _storageService.loadInboxMessages();

  Future<List<ExportRecord>> loadExportRecords() =>
      _storageService.loadExportRecords();

  Future<List<AchievementUnlockRecord>> loadAchievementUnlocks() =>
      _storageService.loadAchievementUnlocks();

  Future<void> saveEvents(List<EventItem> events) =>
      _storageService.saveEvents(events);

  Future<void> savePendingNotices(List<ParsedNotice> notices) =>
      _storageService.savePendingNotices(notices);

  Future<void> savePreference(UserPreference preference) =>
      _storageService.savePreference(preference);

  Future<void> saveInboxMessages(List<InboxMessage> messages) =>
      _storageService.saveInboxMessages(messages);

  Future<void> saveExportRecords(List<ExportRecord> records) =>
      _storageService.saveExportRecords(records);

  Future<void> saveAchievementUnlocks(List<AchievementUnlockRecord> records) =>
      _storageService.saveAchievementUnlocks(records);
}
