import '../models/event_item.dart';
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

  Future<void> saveEvents(List<EventItem> events) =>
      _storageService.saveEvents(events);

  Future<void> savePendingNotices(List<ParsedNotice> notices) =>
      _storageService.savePendingNotices(notices);

  Future<void> savePreference(UserPreference preference) =>
      _storageService.savePreference(preference);
}
