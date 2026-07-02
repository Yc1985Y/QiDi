package com.vsa.visualsemanticagent.storage

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.PreferenceDataStoreFactory
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStoreFile
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.vsa.visualsemanticagent.notification.InboxMessageData
import com.vsa.visualsemanticagent.plan.AgendaCardData
import com.vsa.visualsemanticagent.plan.AgendaReminderData
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

class AppPreferencesStore(context: Context) {
    private val appContext = context.applicationContext
    private val dataStore = getDataStore(appContext)
    private val gson = Gson()

    val stateFlow: Flow<AppStoredState> = dataStore.data.map { preferences ->
        AppStoredState(
            agendaItems = decodeAgendas(preferences[KEY_AGENDAS_JSON]),
            inboxMessages = decodeInboxMessages(preferences[KEY_INBOX_MESSAGES_JSON]),
            reminderLeadMinutes = preferences[KEY_REMINDER_LEAD_MINUTES] ?: DEFAULT_REMINDER_LEAD_MINUTES,
            reminderDayEnabled = preferences[KEY_REMINDER_DAY_ENABLED] ?: true,
            reminderHourEnabled = preferences[KEY_REMINDER_HOUR_ENABLED] ?: true,
            blockHighRisk = preferences[KEY_BLOCK_HIGH_RISK] ?: true,
            muteLowConfidence = preferences[KEY_MUTE_LOW_CONFIDENCE] ?: false,
            autoMapLink = preferences[KEY_AUTO_MAP_LINK] ?: true,
            performanceLiteMode = preferences[KEY_PERFORMANCE_LITE_MODE] ?: false
        )
    }

    suspend fun saveAgendaItems(items: List<AgendaCardData>) {
        dataStore.edit { preferences ->
            preferences[KEY_AGENDAS_JSON] = gson.toJson(items)
        }
    }

    suspend fun saveInboxMessages(messages: List<InboxMessageData>) {
        dataStore.edit { preferences ->
            preferences[KEY_INBOX_MESSAGES_JSON] = gson.toJson(messages.take(MAX_INBOX_MESSAGES))
        }
    }

    suspend fun savePreferences(
        reminderLeadMinutes: Int,
        reminderDayEnabled: Boolean,
        reminderHourEnabled: Boolean,
        blockHighRisk: Boolean,
        muteLowConfidence: Boolean,
        autoMapLink: Boolean,
        performanceLiteMode: Boolean
    ) {
        dataStore.edit { preferences ->
            preferences[KEY_REMINDER_LEAD_MINUTES] = reminderLeadMinutes
            preferences[KEY_REMINDER_DAY_ENABLED] = reminderDayEnabled
            preferences[KEY_REMINDER_HOUR_ENABLED] = reminderHourEnabled
            preferences[KEY_BLOCK_HIGH_RISK] = blockHighRisk
            preferences[KEY_MUTE_LOW_CONFIDENCE] = muteLowConfidence
            preferences[KEY_AUTO_MAP_LINK] = autoMapLink
            preferences[KEY_PERFORMANCE_LITE_MODE] = performanceLiteMode
        }
    }

    private fun decodeAgendas(raw: String?): List<AgendaCardData> {
        if (raw.isNullOrBlank()) return emptyList()
        return runCatching {
            val type = object : TypeToken<List<AgendaCardDataRaw>>() {}.type
            val parsed: List<AgendaCardDataRaw> = gson.fromJson(raw, type)
            parsed.map { it.toAgendaCardData() }
        }.getOrDefault(emptyList())
    }

    private fun decodeInboxMessages(raw: String?): List<InboxMessageData> {
        if (raw.isNullOrBlank()) return emptyList()
        return runCatching {
            val type = object : TypeToken<List<InboxMessageDataRaw>>() {}.type
            val parsed: List<InboxMessageDataRaw> = gson.fromJson(raw, type)
            parsed.map { it.toInboxMessageData() }
        }.getOrDefault(emptyList())
    }

    companion object {
        private const val DATASTORE_NAME = "timeweaver_prefs"
        private const val MAX_INBOX_MESSAGES = 60
        @Volatile
        private var dataStoreInstance: DataStore<Preferences>? = null

        private fun getDataStore(context: Context): DataStore<Preferences> {
            return dataStoreInstance ?: synchronized(this) {
                dataStoreInstance ?: PreferenceDataStoreFactory.create(
                    produceFile = { context.applicationContext.preferencesDataStoreFile(DATASTORE_NAME) }
                ).also { created ->
                    dataStoreInstance = created
                }
            }
        }

        private val KEY_AGENDAS_JSON = stringPreferencesKey("agendas_json")
        private val KEY_INBOX_MESSAGES_JSON = stringPreferencesKey("inbox_messages_json")
        private val KEY_REMINDER_LEAD_MINUTES = intPreferencesKey("reminder_lead_minutes")
        private val KEY_REMINDER_DAY_ENABLED = booleanPreferencesKey("reminder_day_enabled")
        private val KEY_REMINDER_HOUR_ENABLED = booleanPreferencesKey("reminder_hour_enabled")
        private val KEY_BLOCK_HIGH_RISK = booleanPreferencesKey("block_high_risk")
        private val KEY_MUTE_LOW_CONFIDENCE = booleanPreferencesKey("mute_low_confidence")
        private val KEY_AUTO_MAP_LINK = booleanPreferencesKey("auto_map_link")
        private val KEY_PERFORMANCE_LITE_MODE = booleanPreferencesKey("performance_lite_mode")
        const val DEFAULT_REMINDER_LEAD_MINUTES = 60
    }
}

data class AppStoredState(
    val agendaItems: List<AgendaCardData> = emptyList(),
    val inboxMessages: List<InboxMessageData> = emptyList(),
    val reminderLeadMinutes: Int = AppPreferencesStore.DEFAULT_REMINDER_LEAD_MINUTES,
    val reminderDayEnabled: Boolean = true,
    val reminderHourEnabled: Boolean = true,
    val blockHighRisk: Boolean = true,
    val muteLowConfidence: Boolean = false,
    val autoMapLink: Boolean = true,
    val performanceLiteMode: Boolean = false
)

    private data class AgendaCardDataRaw(
    val id: String,
    val title: String,
    val summary: String,
    val time: String,
    val location: String,
    val status: String,
    val isoDateTime: String? = null,
    val sourceLabel: String = "",
    val action: String = "create_event",
    val reminders: List<AgendaReminderDataRaw> = emptyList(),
    val ownerAccount: String = ""
) {
    fun toAgendaCardData(): AgendaCardData {
        return AgendaCardData(
            id = id,
            title = title,
            summary = summary,
            time = time,
            location = location,
            status = status,
            isoDateTime = isoDateTime,
            sourceLabel = sourceLabel,
            action = action,
            reminders = reminders.map { AgendaReminderData(label = it.label, minutesBefore = it.minutesBefore) },
            ownerAccount = ownerAccount
        )
    }
}

private data class AgendaReminderDataRaw(
    val label: String,
    val minutesBefore: Int
)

private data class InboxMessageDataRaw(
    val id: String,
    val type: String,
    val title: String,
    val summary: String,
    val status: String = "未读",
    val createdAtMillis: Long = System.currentTimeMillis(),
    val ownerAccount: String = ""
) {
    fun toInboxMessageData(): InboxMessageData {
        return InboxMessageData(
            id = id,
            type = type,
            title = title,
            summary = summary,
            status = status,
            createdAtMillis = createdAtMillis,
            ownerAccount = ownerAccount
        )
    }
}
