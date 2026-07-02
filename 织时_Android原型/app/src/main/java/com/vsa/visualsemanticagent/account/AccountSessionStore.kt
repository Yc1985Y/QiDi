package com.vsa.visualsemanticagent.account

import android.content.Context

class AccountSessionStore(context: Context) {
    private val prefs = context.applicationContext.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun saveCurrentUser(user: AccountUser) {
        prefs.edit().putLong(KEY_CURRENT_USER_ID, user.id).apply()
    }

    fun loadCurrentUser(repository: AccountRepository): AccountUser? {
        val id = prefs.getLong(KEY_CURRENT_USER_ID, NO_USER)
        if (id == NO_USER) return null
        return repository.findUserById(id)
    }

    fun clear() {
        prefs.edit().remove(KEY_CURRENT_USER_ID).apply()
    }

    companion object {
        private const val PREFS_NAME = "timeweaver_account_session"
        private const val KEY_CURRENT_USER_ID = "current_user_id"
        private const val NO_USER = -1L
    }
}

