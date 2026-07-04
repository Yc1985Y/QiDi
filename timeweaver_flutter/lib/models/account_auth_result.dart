import 'account_user.dart';

class AccountAuthResult {
  const AccountAuthResult({this.user, required this.message});

  final AccountUser? user;
  final String message;

  bool get success => user != null;
}
