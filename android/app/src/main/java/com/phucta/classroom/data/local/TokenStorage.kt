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

    private val prefs: SharedPreferences by lazy {
        try {
            val masterKey = MasterKey.Builder(context)
                .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
                .build()

            EncryptedSharedPreferences.create(
                context,
                "secure_oauth_tokens",
                masterKey,
                EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
            )
        } catch (e: Exception) {
            // Fallback for devices with KeyStore migration issues
            context.getSharedPreferences("secure_oauth_tokens_fallback", Context.MODE_PRIVATE)
        }
    }

    companion object {
        private const val KEY_ACCESS_TOKEN = "access_token"
        private const val KEY_REFRESH_TOKEN = "refresh_token"
        private const val KEY_EXPIRES_IN = "expires_in"
        private const val KEY_EXPIRES_AT = "expires_at"
        private const val KEY_AUTH_VERIFIER = "auth_verifier"
        private const val KEY_AUTH_REDIRECT_URI = "auth_redirect_uri"
    }

    fun saveAuthFlowState(verifier: String, redirectUri: String) {
        try {
            prefs.edit()
                .putString(KEY_AUTH_VERIFIER, verifier)
                .putString(KEY_AUTH_REDIRECT_URI, redirectUri)
                .apply()
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun loadAuthFlowVerifier(): String? = try {
        prefs.getString(KEY_AUTH_VERIFIER, null)
    } catch (e: Exception) {
        null
    }

    fun loadAuthFlowRedirectUri(): String? = try {
        prefs.getString(KEY_AUTH_REDIRECT_URI, null)
    } catch (e: Exception) {
        null
    }

    fun clearAuthFlowState() {
        try {
            prefs.edit()
                .remove(KEY_AUTH_VERIFIER)
                .remove(KEY_AUTH_REDIRECT_URI)
                .apply()
        } catch (e: Exception) {
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
                .apply()
        } catch (e: Exception) {
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
        return tokens.accessToken.isNotBlank()
    }
}
