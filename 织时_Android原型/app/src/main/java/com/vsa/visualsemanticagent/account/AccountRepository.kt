package com.vsa.visualsemanticagent.account

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import java.security.MessageDigest
import java.security.SecureRandom

class AccountRepository(context: Context) :
    SQLiteOpenHelper(context.applicationContext, DATABASE_NAME, null, DATABASE_VERSION) {

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            """
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
            """.trimIndent()
        )
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        if (oldVersion < 1) {
            onCreate(db)
            return
        }
        if (oldVersion < 2) {
            addColumnIfMissing(db, "users", "birthday", "TEXT NOT NULL DEFAULT ''")
            addColumnIfMissing(db, "users", "school", "TEXT NOT NULL DEFAULT ''")
            addColumnIfMissing(db, "users", "age", "TEXT NOT NULL DEFAULT ''")
        }
        if (oldVersion < 3) {
            addColumnIfMissing(db, "users", "avatar_uri", "TEXT NOT NULL DEFAULT ''")
            addColumnIfMissing(db, "users", "signature", "TEXT NOT NULL DEFAULT ''")
            addColumnIfMissing(db, "users", "birthday", "TEXT NOT NULL DEFAULT ''")
            addColumnIfMissing(db, "users", "school", "TEXT NOT NULL DEFAULT ''")
            addColumnIfMissing(db, "users", "age", "TEXT NOT NULL DEFAULT ''")
            addColumnIfMissing(db, "users", "gender", "TEXT NOT NULL DEFAULT ''")
            addColumnIfMissing(db, "users", "major", "TEXT NOT NULL DEFAULT ''")
            addColumnIfMissing(db, "users", "grade", "TEXT NOT NULL DEFAULT ''")
            addColumnIfMissing(db, "users", "hometown", "TEXT NOT NULL DEFAULT ''")
        }
    }

    fun ensureBuiltInTestAccount(): AccountUser? {
        val account = TEST_ACCOUNT
        val password = TEST_PASSWORD
        val nickname = TEST_NICKNAME
        val existing = findStoredUserByAccount(account)
        val now = System.currentTimeMillis()
        val salt = generateSalt()
        if (existing == null) {
            val values = ContentValues().apply {
                put("account", account)
                put("nickname", nickname)
                put("avatar_uri", "")
                put("signature", "把校园碎片织成自己的节奏")
                put("birthday", "2005-01-01")
                put("school", "未填写学校")
                put("age", "21")
                put("gender", "未填写")
                put("major", "未填写专业")
                put("grade", "未填写年级")
                put("hometown", "未填写")
                put("password_hash", hashPassword(password, salt))
                put("salt", salt)
                put("created_at", now)
                put("last_login_at", now)
            }
            writableDatabase.insert("users", null, values)
        } else {
            val values = ContentValues().apply {
                put("password_hash", hashPassword(password, salt))
                put("salt", salt)
            }
            writableDatabase.update("users", values, "account = ?", arrayOf(account))
        }

        return findUserByAccount(account)
    }

    fun register(accountInput: String, passwordInput: String, nicknameInput: String): AccountAuthResult {
        val account = accountInput.trim()
        val password = passwordInput.trim()
        val nickname = nicknameInput.trim().ifBlank { account.take(12) }

        validateCredential(account, password)?.let { return AccountAuthResult(message = it) }
        if (findUserByAccount(account) != null) {
            return AccountAuthResult(message = "该账号已注册，请直接登录")
        }

        val now = System.currentTimeMillis()
        val salt = generateSalt()
        val values = ContentValues().apply {
            put("account", account)
            put("nickname", nickname)
            put("avatar_uri", "")
            put("signature", "")
            put("birthday", "")
            put("school", "")
            put("age", "")
            put("gender", "")
            put("major", "")
            put("grade", "")
            put("hometown", "")
            put("password_hash", hashPassword(password, salt))
            put("salt", salt)
            put("created_at", now)
            put("last_login_at", now)
        }
        val id = writableDatabase.insert("users", null, values)
        if (id <= 0L) {
            return AccountAuthResult(message = "注册失败，请稍后重试")
        }
        return AccountAuthResult(
            user = AccountUser(
                id = id,
                account = account,
                nickname = nickname,
                avatarUri = "",
                signature = "",
                birthday = "",
                school = "",
                age = "",
                gender = "",
                major = "",
                grade = "",
                hometown = "",
                createdAt = now,
                lastLoginAt = now
            ),
            message = "注册成功，已进入织时"
        )
    }

    fun login(accountInput: String, passwordInput: String): AccountAuthResult {
        val account = accountInput.trim()
        val password = passwordInput.trim()

        validateCredential(account, password)?.let { return AccountAuthResult(message = it) }
        val stored = findStoredUserByAccount(account)
            ?: return AccountAuthResult(message = "账号不存在，请先注册")

        val hashed = hashPassword(password, stored.salt)
        if (hashed != stored.passwordHash) {
            return AccountAuthResult(message = "密码不正确，请重新输入")
        }

        val now = System.currentTimeMillis()
        val values = ContentValues().apply { put("last_login_at", now) }
        writableDatabase.update("users", values, "id = ?", arrayOf(stored.user.id.toString()))

        return AccountAuthResult(
            user = stored.user.copy(lastLoginAt = now),
            message = "欢迎回来，${stored.user.nickname}"
        )
    }

    fun findUserById(id: Long): AccountUser? {
        readableDatabase.query(
            "users",
            USER_COLUMNS,
            "id = ?",
            arrayOf(id.toString()),
            null,
            null,
            null,
            "1"
        ).use { cursor ->
            if (!cursor.moveToFirst()) return null
            return cursor.toAccountUser()
        }
    }

    fun updateProfile(
        userId: Long,
        nicknameInput: String,
        avatarUriInput: String,
        signatureInput: String,
        birthdayInput: String,
        schoolInput: String,
        ageInput: String,
        genderInput: String,
        majorInput: String,
        gradeInput: String,
        hometownInput: String
    ): AccountUser? {
        val nickname = nicknameInput.trim().ifBlank { "织时用户" }.take(24)
        val avatarUri = avatarUriInput.trim()
        val signature = signatureInput.trim().take(80)
        val birthday = birthdayInput.trim().take(20)
        val school = schoolInput.trim().take(40)
        val age = ageInput.trim().filter { it.isDigit() }.take(3)
        val gender = genderInput.trim().take(12)
        val major = majorInput.trim().take(40)
        val grade = gradeInput.trim().take(24)
        val hometown = hometownInput.trim().take(40)
        val values = ContentValues().apply {
            put("nickname", nickname)
            put("avatar_uri", avatarUri)
            put("signature", signature)
            put("birthday", birthday)
            put("school", school)
            put("age", age)
            put("gender", gender)
            put("major", major)
            put("grade", grade)
            put("hometown", hometown)
        }
        writableDatabase.update("users", values, "id = ?", arrayOf(userId.toString()))
        return findUserById(userId)
    }

    private fun findUserByAccount(account: String): AccountUser? {
        return findStoredUserByAccount(account)?.user
    }

    private fun findStoredUserByAccount(account: String): StoredUser? {
        readableDatabase.query(
            "users",
            USER_COLUMNS,
            "account = ?",
            arrayOf(account),
            null,
            null,
            null,
            "1"
        ).use { cursor ->
            if (!cursor.moveToFirst()) return null
            return StoredUser(
                user = cursor.toAccountUser(),
                passwordHash = cursor.getString(cursor.getColumnIndexOrThrow("password_hash")),
                salt = cursor.getString(cursor.getColumnIndexOrThrow("salt"))
            )
        }
    }

    private fun android.database.Cursor.toAccountUser(): AccountUser {
        return AccountUser(
            id = getLong(getColumnIndexOrThrow("id")),
            account = getString(getColumnIndexOrThrow("account")),
            nickname = getString(getColumnIndexOrThrow("nickname")),
            avatarUri = getString(getColumnIndexOrThrow("avatar_uri")),
            signature = getString(getColumnIndexOrThrow("signature")),
            birthday = getString(getColumnIndexOrThrow("birthday")),
            school = getString(getColumnIndexOrThrow("school")),
            age = getString(getColumnIndexOrThrow("age")),
            gender = getString(getColumnIndexOrThrow("gender")),
            major = getString(getColumnIndexOrThrow("major")),
            grade = getString(getColumnIndexOrThrow("grade")),
            hometown = getString(getColumnIndexOrThrow("hometown")),
            createdAt = getLong(getColumnIndexOrThrow("created_at")),
            lastLoginAt = getLong(getColumnIndexOrThrow("last_login_at"))
        )
    }

    private fun addColumnIfMissing(
        db: SQLiteDatabase,
        table: String,
        column: String,
        definition: String
    ) {
        db.rawQuery("PRAGMA table_info($table)", null).use { cursor ->
            val nameIndex = cursor.getColumnIndex("name")
            while (cursor.moveToNext()) {
                if (cursor.getString(nameIndex) == column) return
            }
        }
        db.execSQL("ALTER TABLE $table ADD COLUMN $column $definition")
    }

    private fun validateCredential(account: String, password: String): String? {
        return when {
            account.length < 3 -> "账号至少需要 3 个字符"
            password.length < 6 -> "密码至少需要 6 个字符"
            else -> null
        }
    }

    private fun generateSalt(): String {
        val bytes = ByteArray(16)
        secureRandom.nextBytes(bytes)
        return bytes.toHex()
    }

    private fun hashPassword(password: String, salt: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val bytes = digest.digest("$salt:$password".toByteArray(Charsets.UTF_8))
        return bytes.toHex()
    }

    private fun ByteArray.toHex(): String = joinToString(separator = "") { byte ->
        "%02x".format(byte)
    }

    private data class StoredUser(
        val user: AccountUser,
        val passwordHash: String,
        val salt: String
    )

    companion object {
        private const val DATABASE_NAME = "timeweaver_accounts.db"
        private const val DATABASE_VERSION = 3
        const val TEST_ACCOUNT = "1985"
        const val TEST_PASSWORD = "12345678"
        private const val TEST_NICKNAME = "织时测试账号"
        private val secureRandom = SecureRandom()
        private val USER_COLUMNS = arrayOf(
            "id",
            "account",
            "nickname",
            "avatar_uri",
            "signature",
            "birthday",
            "school",
            "age",
            "gender",
            "major",
            "grade",
            "hometown",
            "password_hash",
            "salt",
            "created_at",
            "last_login_at"
        )
    }
}
