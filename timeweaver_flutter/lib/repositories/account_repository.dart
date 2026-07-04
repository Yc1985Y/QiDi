import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/account_auth_result.dart';
import '../models/account_user.dart';

class AccountRepository {
  static const testAccount = '1985';
  static const testPassword = '12345678';
  static const _testNickname = '织时测试账号';

  Database? _database;

  Future<void> initialize() async {
    await _db;
  }

  Future<AccountUser?> ensureBuiltInTestAccount() async {
    final existing = await _findStoredUserByAccount(testAccount);
    final now = DateTime.now().millisecondsSinceEpoch;
    final salt = _generateSalt();
    final db = await _db;
    if (existing == null) {
      await db.insert('users', {
        'account': testAccount,
        'nickname': _testNickname,
        'avatar_uri': '',
        'signature': '把校园碎片织成自己的节奏',
        'birthday': '2005-01-01',
        'school': '未填写学校',
        'age': '21',
        'gender': '未填写',
        'major': '未填写专业',
        'grade': '未填写年级',
        'hometown': '未填写',
        'password_hash': _hashPassword(testPassword, salt),
        'salt': salt,
        'created_at': now,
        'last_login_at': now,
      });
    } else {
      await db.update(
        'users',
        {
          'password_hash': _hashPassword(testPassword, salt),
          'salt': salt,
        },
        where: 'account = ?',
        whereArgs: [testAccount],
      );
    }
    return findUserByAccount(testAccount);
  }

  Future<AccountAuthResult> register(
    String accountInput,
    String passwordInput,
    String nicknameInput,
  ) async {
    final account = accountInput.trim();
    final password = passwordInput.trim();
    final nickname = nicknameInput.trim().isEmpty
        ? _takeAtMost(account, 12)
        : nicknameInput.trim();
    final blocker = _validateCredential(account, password);
    if (blocker != null) {
      return AccountAuthResult(message: blocker);
    }
    if (await findUserByAccount(account) != null) {
      return const AccountAuthResult(message: '该账号已注册，请直接登录');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final salt = _generateSalt();
    final db = await _db;
    final id = await db.insert('users', {
      'account': account,
      'nickname': nickname,
      'avatar_uri': '',
      'signature': '',
      'birthday': '',
      'school': '',
      'age': '',
      'gender': '',
      'major': '',
      'grade': '',
      'hometown': '',
      'password_hash': _hashPassword(password, salt),
      'salt': salt,
      'created_at': now,
      'last_login_at': now,
    });
    if (id <= 0) {
      return const AccountAuthResult(message: '注册失败，请稍后重试');
    }
    return AccountAuthResult(
      user: AccountUser(
        id: id,
        account: account,
        nickname: nickname,
        createdAt: now,
        lastLoginAt: now,
      ),
      message: '注册成功，已进入织时',
    );
  }

  Future<AccountAuthResult> login(
    String accountInput,
    String passwordInput,
  ) async {
    final account = accountInput.trim();
    final password = passwordInput.trim();
    final blocker = _validateCredential(account, password);
    if (blocker != null) {
      return AccountAuthResult(message: blocker);
    }
    final stored = await _findStoredUserByAccount(account);
    if (stored == null) {
      return const AccountAuthResult(message: '账号不存在，请先注册');
    }
    final hashed = _hashPassword(password, stored.salt);
    if (hashed != stored.passwordHash) {
      return const AccountAuthResult(message: '密码不正确，请重新输入');
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final db = await _db;
    await db.update(
      'users',
      {'last_login_at': now},
      where: 'id = ?',
      whereArgs: [stored.user.id],
    );
    final user = stored.user.copyWith(lastLoginAt: now);
    return AccountAuthResult(user: user, message: '欢迎回来，${user.nickname}');
  }

  Future<AccountUser?> findUserById(int id) async {
    final db = await _db;
    final rows = await db.query(
      'users',
      columns: _userColumns,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return _toAccountUser(rows.first);
  }

  Future<AccountUser?> findUserByAccount(String account) async {
    return (await _findStoredUserByAccount(account))?.user;
  }

  Future<AccountUser?> updateProfile({
    required int userId,
    required String nicknameInput,
    required String avatarUriInput,
    required String signatureInput,
    required String birthdayInput,
    required String schoolInput,
    required String ageInput,
    required String genderInput,
    required String majorInput,
    required String gradeInput,
    required String hometownInput,
  }) async {
    final db = await _db;
    await db.update(
      'users',
      {
        'nickname': _takeAtMost(
          nicknameInput.trim().isEmpty ? '织时用户' : nicknameInput.trim(),
          24,
        ),
        'avatar_uri': avatarUriInput.trim(),
        'signature': _takeAtMost(signatureInput.trim(), 80),
        'birthday': _takeAtMost(birthdayInput.trim(), 20),
        'school': _takeAtMost(schoolInput.trim(), 40),
        'age': _takeAtMost(
          ageInput.trim().replaceAll(RegExp(r'[^0-9]'), ''),
          3,
        ),
        'gender': _takeAtMost(genderInput.trim(), 12),
        'major': _takeAtMost(majorInput.trim(), 40),
        'grade': _takeAtMost(gradeInput.trim(), 24),
        'hometown': _takeAtMost(hometownInput.trim(), 40),
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
    return findUserById(userId);
  }

  Future<Database> get _db async {
    final existing = _database;
    if (existing != null) return existing;
    final path = p.join(await getDatabasesPath(), 'timeweaver_accounts.db');
    _database = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            account TEXT NOT NULL UNIQUE,
            nickname TEXT NOT NULL,
            avatar_uri TEXT NOT NULL DEFAULT '',
            signature TEXT NOT NULL DEFAULT '',
            birthday TEXT NOT NULL DEFAULT '',
            school TEXT NOT NULL DEFAULT '',
            age TEXT NOT NULL DEFAULT '',
            gender TEXT NOT NULL DEFAULT '',
            major TEXT NOT NULL DEFAULT '',
            grade TEXT NOT NULL DEFAULT '',
            hometown TEXT NOT NULL DEFAULT '',
            password_hash TEXT NOT NULL,
            salt TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            last_login_at INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _addColumnIfMissing(
            db,
            table: 'users',
            column: 'birthday',
            definition: "TEXT NOT NULL DEFAULT ''",
          );
          await _addColumnIfMissing(
            db,
            table: 'users',
            column: 'school',
            definition: "TEXT NOT NULL DEFAULT ''",
          );
          await _addColumnIfMissing(
            db,
            table: 'users',
            column: 'age',
            definition: "TEXT NOT NULL DEFAULT ''",
          );
        }
        if (oldVersion < 3) {
          for (final column in const {
            'avatar_uri': "TEXT NOT NULL DEFAULT ''",
            'signature': "TEXT NOT NULL DEFAULT ''",
            'birthday': "TEXT NOT NULL DEFAULT ''",
            'school': "TEXT NOT NULL DEFAULT ''",
            'age': "TEXT NOT NULL DEFAULT ''",
            'gender': "TEXT NOT NULL DEFAULT ''",
            'major': "TEXT NOT NULL DEFAULT ''",
            'grade': "TEXT NOT NULL DEFAULT ''",
            'hometown': "TEXT NOT NULL DEFAULT ''",
          }.entries) {
            await _addColumnIfMissing(
              db,
              table: 'users',
              column: column.key,
              definition: column.value,
            );
          }
        }
      },
    );
    return _database!;
  }

  Future<StoredUser?> _findStoredUserByAccount(String account) async {
    final db = await _db;
    final rows = await db.query(
      'users',
      columns: _userColumns,
      where: 'account = ?',
      whereArgs: [account],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return StoredUser(
      user: _toAccountUser(row),
      passwordHash: row['password_hash'] as String? ?? '',
      salt: row['salt'] as String? ?? '',
    );
  }

  AccountUser _toAccountUser(Map<String, Object?> row) {
    return AccountUser(
      id: (row['id'] as num).toInt(),
      account: row['account'] as String? ?? '',
      nickname: row['nickname'] as String? ?? '',
      avatarUri: row['avatar_uri'] as String? ?? '',
      signature: row['signature'] as String? ?? '',
      birthday: row['birthday'] as String? ?? '',
      school: row['school'] as String? ?? '',
      age: row['age'] as String? ?? '',
      gender: row['gender'] as String? ?? '',
      major: row['major'] as String? ?? '',
      grade: row['grade'] as String? ?? '',
      hometown: row['hometown'] as String? ?? '',
      createdAt: (row['created_at'] as num?)?.toInt() ?? 0,
      lastLoginAt: (row['last_login_at'] as num?)?.toInt() ?? 0,
    );
  }

  Future<void> _addColumnIfMissing(
    Database db, {
    required String table,
    required String column,
    required String definition,
  }) async {
    final columns = await db.rawQuery('PRAGMA table_info($table)');
    final exists = columns.any((item) => item['name'] == column);
    if (exists) return;
    await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
  }

  String? _validateCredential(String account, String password) {
    if (account.length < 3) return '账号至少需要 3 个字符';
    if (password.length < 6) return '密码至少需要 6 个字符';
    return null;
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((item) => item.toRadixString(16).padLeft(2, '0')).join();
  }

  String _hashPassword(String password, String salt) {
    return sha256.convert(utf8.encode('$salt:$password')).toString();
  }

  String _takeAtMost(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return value.substring(0, maxLength);
  }
}

class StoredUser {
  const StoredUser({
    required this.user,
    required this.passwordHash,
    required this.salt,
  });

  final AccountUser user;
  final String passwordHash;
  final String salt;
}

const List<String> _userColumns = [
  'id',
  'account',
  'nickname',
  'avatar_uri',
  'signature',
  'birthday',
  'school',
  'age',
  'gender',
  'major',
  'grade',
  'hometown',
  'password_hash',
  'salt',
  'created_at',
  'last_login_at',
];
