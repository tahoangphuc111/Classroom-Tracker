package com.phucta.classroom.data.local

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import androidx.datastore.preferences.core.emptyPreferences
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import java.io.IOException

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "classroom_settings")

class ClassroomPreferences(context: Context) {
    private val appContext = context.applicationContext
    private val tokenStorage: TokenStorage by lazy { TokenStorage(appContext) }

    companion object {
        val KEY_USER_EMAIL = stringPreferencesKey("cached_user_email")
        val KEY_USER_NAME = stringPreferencesKey("cached_user_name")
        val KEY_USER_AVATAR = stringPreferencesKey("cached_user_avatar")
        val KEY_LAST_SYNC_TIMESTAMP = longPreferencesKey("cached_last_sync_timestamp")
        val KEY_HAS_USER_LOGGED_IN = booleanPreferencesKey("cached_has_user_logged_in")
        val KEY_CUSTOM_CLIENT_ID = stringPreferencesKey("custom_client_id")
        val KEY_CUSTOM_CLIENT_SECRET = stringPreferencesKey("custom_client_secret")

        const val BUNDLED_CLIENT_ID = "1024991814751-qs4rkg9pa09r092lp083l3e9gk6e3mru.apps.googleusercontent.com"
        const val BUNDLED_CLIENT_SECRET = ""
    }

    private val safePreferencesFlow: Flow<Preferences> = appContext.dataStore.data
        .catch { exception ->
            if (exception is IOException) {
                emit(emptyPreferences())
            } else {
                throw exception
            }
        }

    private val _customClientSecretFlow = kotlinx.coroutines.flow.MutableStateFlow<String?>(tokenStorage.loadCustomClientSecret())

    val userEmailFlow: Flow<String?> = safePreferencesFlow.map { it[KEY_USER_EMAIL] }
    val userNameFlow: Flow<String?> = safePreferencesFlow.map { it[KEY_USER_NAME] }
    val userAvatarFlow: Flow<String?> = safePreferencesFlow.map { it[KEY_USER_AVATAR] }
    val lastSyncTimestampFlow: Flow<Long?> = safePreferencesFlow.map { it[KEY_LAST_SYNC_TIMESTAMP] }
    val hasUserLoggedInFlow: Flow<Boolean> = safePreferencesFlow.map { it[KEY_HAS_USER_LOGGED_IN] ?: false }

    val clientIdFlow: Flow<String> = safePreferencesFlow.map {
        val custom = it[KEY_CUSTOM_CLIENT_ID]
        if (!custom.isNullOrBlank()) custom else BUNDLED_CLIENT_ID
    }

    val clientSecretFlow: Flow<String> = _customClientSecretFlow.map {
        if (!it.isNullOrBlank()) it else BUNDLED_CLIENT_SECRET
    }

    val customClientIdFlow: Flow<String?> = safePreferencesFlow.map { it[KEY_CUSTOM_CLIENT_ID] }
    val customClientSecretFlow: Flow<String?> = _customClientSecretFlow

    suspend fun saveUserProfile(email: String?, name: String?, avatar: String?) {
        appContext.dataStore.edit { prefs ->
            if (email != null) prefs[KEY_USER_EMAIL] = email else prefs.remove(KEY_USER_EMAIL)
            if (name != null) prefs[KEY_USER_NAME] = name else prefs.remove(KEY_USER_NAME)
            if (avatar != null) prefs[KEY_USER_AVATAR] = avatar else prefs.remove(KEY_USER_AVATAR)
            prefs[KEY_HAS_USER_LOGGED_IN] = !email.isNullOrBlank()
        }
    }

    suspend fun saveLastSyncTime(timestamp: Long) {
        appContext.dataStore.edit { it[KEY_LAST_SYNC_TIMESTAMP] = timestamp }
    }

    suspend fun saveCustomCredentials(clientId: String?, clientSecret: String?) {
        val trimmedSecret = clientSecret?.trim()
        val effectiveSecret = if (!trimmedSecret.isNullOrBlank() && trimmedSecret != BUNDLED_CLIENT_SECRET) trimmedSecret else null
        tokenStorage.saveCustomClientSecret(effectiveSecret)
        _customClientSecretFlow.value = effectiveSecret

        appContext.dataStore.edit { prefs ->
            val trimmedId = clientId?.trim()
            if (!trimmedId.isNullOrBlank() && trimmedId != BUNDLED_CLIENT_ID) {
                prefs[KEY_CUSTOM_CLIENT_ID] = trimmedId
            } else {
                prefs.remove(KEY_CUSTOM_CLIENT_ID)
            }
            prefs.remove(KEY_CUSTOM_CLIENT_SECRET)
        }
    }

    suspend fun getEffectiveClientId(): String {
        val stored = safePreferencesFlow.first()[KEY_CUSTOM_CLIENT_ID]
        return if (!stored.isNullOrBlank()) stored else BUNDLED_CLIENT_ID
    }

    suspend fun getEffectiveClientSecret(): String {
        val encryptedSecret = tokenStorage.loadCustomClientSecret()
        if (!encryptedSecret.isNullOrBlank()) {
            return encryptedSecret
        }
        val stored = safePreferencesFlow.first()[KEY_CUSTOM_CLIENT_SECRET]
        if (!stored.isNullOrBlank() && stored != BUNDLED_CLIENT_SECRET) {
            tokenStorage.saveCustomClientSecret(stored)
            _customClientSecretFlow.value = stored
            appContext.dataStore.edit { it.remove(KEY_CUSTOM_CLIENT_SECRET) }
            return stored
        }
        return ""
    }

    suspend fun clear() {
        tokenStorage.saveCustomClientSecret(null)
        _customClientSecretFlow.value = null
        appContext.dataStore.edit { prefs ->
            prefs.remove(KEY_USER_EMAIL)
            prefs.remove(KEY_USER_NAME)
            prefs.remove(KEY_USER_AVATAR)
            prefs.remove(KEY_LAST_SYNC_TIMESTAMP)
            prefs.remove(KEY_CUSTOM_CLIENT_SECRET)
            prefs[KEY_HAS_USER_LOGGED_IN] = false
        }
    }
}
