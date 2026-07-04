import 'package:shared_preferences/shared_preferences.dart';

import '../models/account_user.dart';
import '../repositories/account_repository.dart';

class AccountSessionService {
  static const _prefsName = 'timeweaver_account_session';
  static const _currentUserIdKey = 'current_user_id';
  static const _noUser = -1;

  Future<void> saveCurrentUser(AccountUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefsName:$_currentUserIdKey', user.id);
  }

  Future<AccountUser?> loadCurrentUser(AccountRepository repository) async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt('$_prefsName:$_currentUserIdKey') ?? _noUser;
    if (id == _noUser) return null;
    return repository.findUserById(id);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefsName:$_currentUserIdKey');
  }
}
