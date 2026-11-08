package com.phucta.classroom.data.local

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

data class OAuthTokens(
    val accessToken: String,
    val refreshToken: String?,
    val expiresIn: Int,
    val expiresAt: Long
) {
    val isExpired: Boolean
        get() = (System.currentTimeMillis() + 60_000) >= expiresAt
}

class TokenStorage(context: Context) {
    private val appContext = context.applicationContext

    init {
        try {
            appContext.deleteSharedPreferences("secure_oauth_tokens_fallback")
        } catch (_: Exception) {}
    }

    private fun createEncryptedPrefs(): SharedPreferences {
        val masterKey = MasterKey.Builder(appContext)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()

        return EncryptedSharedPreferences.create(
            appContext,
            "secure_oauth_tokens",
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
    }

    private val prefs: SharedPreferences by lazy {
        try {
            createEncryptedPrefs()
        } catch (firstAttemptError: Throwable) {
            android.util.Log.w("TokenStorage", "Android KeyStore / EncryptedSharedPreferences corrupted, attempting recovery...", firstAttemptError)
            try {
                appContext.deleteSharedPreferences("secure_oauth_tokens")
                try {
                    val keyStore = java.security.KeyStore.getInstance("AndroidKeyStore").apply { load(null) }
                    keyStore.deleteEntry(MasterKey.DEFAULT_MASTER_KEY_ALIAS)
                } catch (ksError: Throwable) {
                    android.util.Log.w("TokenStorage", "Could not delete MasterKey alias from AndroidKeyStore", ksError)
                }
                createEncryptedPrefs()
            } catch (recoveryError: Throwable) {
                android.util.Log.e("TokenStorage", "EncryptedSharedPreferences recovery failed, falling back to private preferences to prevent crash bootloop", recoveryError)
                appContext.getSharedPreferences("secure_oauth_tokens_fallback_safe", Context.MODE_PRIVATE)
            }
        }
    }

    companion object {
        private const val KEY_ACCESS_TOKEN = "access_token"
        private const val KEY_REFRESH_TOKEN = "refresh_token"
        private const val KEY_EXPIRES_IN = "expires_in"
        private const val KEY_EXPIRES_AT = "expires_at"
        private const val KEY_AUTH_VERIFIER = "auth_verifier"
        private const val KEY_AUTH_REDIRECT_URI = "auth_redirect_uri"
        private const val KEY_AUTH_STATE = "auth_state"
        private const val KEY_CUSTOM_CLIENT_SECRET = "custom_client_secret"
    }

    fun saveAuthFlowState(verifier: String, redirectUri: String, state: String? = null) {
        try {
            val editor = prefs.edit()
                .putString(KEY_AUTH_VERIFIER, verifier)
                .putString(KEY_AUTH_REDIRECT_URI, redirectUri)
            if (state != null) {
                editor.putString(KEY_AUTH_STATE, state)
            } else {
                editor.remove(KEY_AUTH_STATE)
            }
            editor.commit()
        } catch (e: Exception) {
            android.util.Log.e("TokenStorage", "saveAuthFlowState error", e)
            e.printStackTrace()
        }
    }

    fun loadAuthFlowVerifier(): String? = try {
        prefs.getString(KEY_AUTH_VERIFIER, null)
    } catch (e: Exception) {
        android.util.Log.e("TokenStorage", "loadAuthFlowVerifier error", e)
        null
    }

    fun loadAuthFlowRedirectUri(): String? = try {
        prefs.getString(KEY_AUTH_REDIRECT_URI, null)
    } catch (e: Exception) {
        android.util.Log.e("TokenStorage", "loadAuthFlowRedirectUri error", e)
        null
    }

    fun loadAuthFlowState(): String? = try {
        prefs.getString(KEY_AUTH_STATE, null)
    } catch (e: Exception) {
        android.util.Log.e("TokenStorage", "loadAuthFlowState error", e)
        null
    }

    fun clearAuthFlowState() {
        try {
            prefs.edit()
                .remove(KEY_AUTH_VERIFIER)
                .remove(KEY_AUTH_REDIRECT_URI)
                .remove(KEY_AUTH_STATE)
                .commit()
        } catch (e: Exception) {
            android.util.Log.e("TokenStorage", "clearAuthFlowState error", e)
            e.printStackTrace()
        }
    }

    fun saveTokens(tokens: OAuthTokens) {
        try {
            prefs.edit()
                .putString(KEY_ACCESS_TOKEN, tokens.accessToken)
                .putString(KEY_REFRESH_TOKEN, tokens.refreshToken)
                .putInt(KEY_EXPIRES_IN, tokens.expiresIn)
                .putLong(KEY_EXPIRES_AT, tokens.expiresAt)
                .commit()
        } catch (e: Exception) {
            android.util.Log.e("TokenStorage", "saveTokens error", e)
            e.printStackTrace()
        }
    }

    fun loadTokens(): OAuthTokens? {
        return try {
            val accessToken = prefs.getString(KEY_ACCESS_TOKEN, null) ?: return null
            val refreshToken = prefs.getString(KEY_REFRESH_TOKEN, null)
            val expiresIn = prefs.getInt(KEY_EXPIRES_IN, 3600)
            val expiresAt = prefs.getLong(KEY_EXPIRES_AT, 0L)
            OAuthTokens(
                accessToken = accessToken,
                refreshToken = refreshToken,
                expiresIn = expiresIn,
                expiresAt = expiresAt
            )
        } catch (e: Exception) {
            null
        }
    }

    fun clearTokens() {
        try {
            prefs.edit().clear().apply()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun hasValidTokens(): Boolean {
        val tokens = loadTokens() ?: return false
        if (tokens.accessToken.isBlank()) return false
        if (tokens.isExpired) {
            return !tokens.refreshToken.isNullOrBlank()
        }
        return true
    }

    fun saveCustomClientSecret(secret: String?) {
        try {
            val editor = prefs.edit()
            if (!secret.isNullOrBlank()) {
                editor.putString(KEY_CUSTOM_CLIENT_SECRET, secret.trim())
            } else {
                editor.remove(KEY_CUSTOM_CLIENT_SECRET)
            }
            editor.commit()
        } catch (e: Exception) {
            android.util.Log.e("TokenStorage", "saveCustomClientSecret error", e)
        }
    }

    fun loadCustomClientSecret(): String? {
        return try {
            prefs.getString(KEY_CUSTOM_CLIENT_SECRET, null)?.takeIf { it.isNotBlank() }
        } catch (e: Exception) {
            null
        }
    }
}
