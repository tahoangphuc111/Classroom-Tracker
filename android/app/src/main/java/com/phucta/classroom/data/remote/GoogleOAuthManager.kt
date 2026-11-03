package com.phucta.classroom.data.remote

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Base64
import androidx.browser.customtabs.CustomTabsIntent
import com.phucta.classroom.data.local.ClassroomPreferences
import com.phucta.classroom.data.local.OAuthTokens
import com.phucta.classroom.data.local.TokenStorage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import okhttp3.FormBody
import okhttp3.OkHttpClient
import okhttp3.Request
import java.security.MessageDigest
import java.security.SecureRandom

@Serializable
data class GoogleUserInfo(
    val email: String? = null,
    val name: String? = null,
    val picture: String? = null
)

@Serializable
private data class TokenResponse(
    @SerialName("access_token") val accessToken: String,
    @SerialName("refresh_token") val refreshToken: String? = null,
    @SerialName("expires_in") val expiresIn: Int = 3600
)

class GoogleOAuthManager(
    context: Context,
    private val preferences: ClassroomPreferences,
    private val tokenStorage: TokenStorage,
    private val httpClient: OkHttpClient = OkHttpClient()
) {
    private val json = Json { ignoreUnknownKeys = true }
    private val refreshMutex = Mutex()

    private val _isAuthenticated = MutableStateFlow(tokenStorage.hasValidTokens())
    val isAuthenticated: StateFlow<Boolean> = _isAuthenticated.asStateFlow()

    private val _authErrorMessage = MutableStateFlow<String?>(null)
    val authErrorMessage: StateFlow<String?> = _authErrorMessage.asStateFlow()

    private var activeCodeVerifier: String? = null
    private var activeRedirectUri: String? = null
    private var activeAuthState: String? = null

    companion object {
        val SCOPES = listOf(
            "https://www.googleapis.com/auth/classroom.courses.readonly",
            "https://www.googleapis.com/auth/classroom.coursework.me.readonly",
            "https://www.googleapis.com/auth/classroom.student-submissions.me.readonly",
            "email",
            "profile"
        )
    }

    private fun generateCodeVerifier(): String {
        val bytes = ByteArray(64)
        SecureRandom().nextBytes(bytes)
        return Base64.encodeToString(bytes, Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING)
    }

    private fun generateCodeChallenge(verifier: String): String {
        val bytes = verifier.toByteArray(Charsets.US_ASCII)
        val digest = MessageDigest.getInstance("SHA-256").digest(bytes)
        return Base64.encodeToString(digest, Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING)
    }

    private fun generateState(): String {
        val bytes = ByteArray(16)
        SecureRandom().nextBytes(bytes)
        return Base64.encodeToString(bytes, Base64.URL_SAFE or Base64.NO_WRAP or Base64.NO_PADDING)
    }

    suspend fun startSignIn(context: Context) {
        _authErrorMessage.value = null
        val clientId = preferences.getEffectiveClientId()
        val verifier = generateCodeVerifier()
        activeCodeVerifier = verifier

        val state = generateState()
        activeAuthState = state

        val redirectUri = if (clientId == ClassroomPreferences.BUNDLED_CLIENT_ID) {
            val reversedClientId = clientId.split(".").reversed().joinToString(".")
            "$reversedClientId:/oauth2redirect/google"
        } else {
            "com.phucta.classroom://oauth2redirect"
        }
        activeRedirectUri = redirectUri
        tokenStorage.saveAuthFlowState(verifier, redirectUri, state)

        val challenge = generateCodeChallenge(verifier)

        val authUri = Uri.parse("https://accounts.google.com/o/oauth2/v2/auth").buildUpon()
            .appendQueryParameter("client_id", clientId)
            .appendQueryParameter("redirect_uri", redirectUri)
            .appendQueryParameter("response_type", "code")
            .appendQueryParameter("scope", SCOPES.joinToString(" "))
            .appendQueryParameter("code_challenge", challenge)
            .appendQueryParameter("code_challenge_method", "S256")
            .appendQueryParameter("state", state)
            .appendQueryParameter("access_type", "offline")
            .appendQueryParameter("prompt", "select_account consent")
            .build()

        try {
            val customTabsIntent = CustomTabsIntent.Builder().setShowTitle(true).build()
            customTabsIntent.intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            customTabsIntent.launchUrl(context, authUri)
        } catch (e: Exception) {
            try {
                val browserIntent = Intent(Intent.ACTION_VIEW, authUri).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(browserIntent)
            } catch (ex: Exception) {
                _authErrorMessage.value = "Không thể mở trình duyệt đăng nhập: ${ex.localizedMessage ?: "Lỗi không xác định"}"
            }
        }
    }

    suspend fun handleRedirectUri(uri: Uri): Boolean = withContext(Dispatchers.IO) {
        val error = uri.getQueryParameter("error")
        if (error != null) {
            _authErrorMessage.value = "Đăng nhập Google thất bại: $error"
            return@withContext false
        }

        try {
            val returnedState = uri.getQueryParameter("state")
            val expectedState = activeAuthState ?: tokenStorage.loadAuthFlowState()
            if (returnedState.isNullOrBlank() || expectedState.isNullOrBlank() || returnedState != expectedState) {
                _authErrorMessage.value = "Xác thực không hợp lệ: Lỗi CSRF state mismatch"
                return@withContext false
            }

            val code = uri.getQueryParameter("code") ?: return@withContext false
            val verifier = activeCodeVerifier ?: tokenStorage.loadAuthFlowVerifier() ?: return@withContext false
            val redirectUri = activeRedirectUri ?: tokenStorage.loadAuthFlowRedirectUri() ?: run {
                val scheme = uri.scheme ?: ""
                if (scheme.startsWith("com.googleusercontent.apps.")) {
                    "$scheme:/oauth2redirect/google"
                } else {
                    "com.phucta.classroom://oauth2redirect"
                }
            }
            val clientId = preferences.getEffectiveClientId()
            val clientSecret = preferences.getEffectiveClientSecret()

            val formBuilder = FormBody.Builder()
                .add("client_id", clientId)
                .add("code", code)
                .add("code_verifier", verifier)
                .add("grant_type", "authorization_code")
                .add("redirect_uri", redirectUri)

            if (clientSecret.isNotBlank()) {
                formBuilder.add("client_secret", clientSecret)
            }

            val request = Request.Builder()
                .url("https://oauth2.googleapis.com/token")
                .post(formBuilder.build())
                .build()

            val (isSuccess, responseBody) = httpClient.newCall(request).execute().use { response ->
                Pair(response.isSuccessful, response.body?.string() ?: "")
            }

            if (!isSuccess) {
                _authErrorMessage.value = "Lỗi đổi token: $responseBody"
                return@withContext false
            }

            val tokenResponse = json.decodeFromString<TokenResponse>(responseBody)
            val existingRefreshToken = tokenStorage.loadTokens()?.refreshToken
            val tokens = OAuthTokens(
                accessToken = tokenResponse.accessToken,
                refreshToken = tokenResponse.refreshToken ?: existingRefreshToken,
                expiresIn = tokenResponse.expiresIn,
                expiresAt = System.currentTimeMillis() + (tokenResponse.expiresIn * 1000L)
            )

            tokenStorage.saveTokens(tokens)
            _isAuthenticated.value = true
            fetchAndSaveUserInfo(tokens.accessToken)
            return@withContext true
        } catch (e: Exception) {
            _authErrorMessage.value = "Lỗi xác thực: ${e.localizedMessage}"
            return@withContext false
        } finally {
            activeCodeVerifier = null
            activeRedirectUri = null
            activeAuthState = null
            tokenStorage.clearAuthFlowState()
        }
    }

    suspend fun getValidAccessToken(): String = withContext(Dispatchers.IO) {
        val currentTokens = tokenStorage.loadTokens()
            ?: throw IllegalStateException("Chưa đăng nhập Google.")

        if (!currentTokens.isExpired) {
            return@withContext currentTokens.accessToken
        }

        refreshMutex.withLock {
            val freshTokens = tokenStorage.loadTokens()
            if (freshTokens != null && !freshTokens.isExpired) {
                return@withLock freshTokens.accessToken
            }

            val refreshToken = currentTokens.refreshToken?.takeIf { it.isNotBlank() }
            if (refreshToken == null) {
                signOut()
                _authErrorMessage.value = "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại."
                throw IllegalStateException("Phiên đăng nhập đã bị thu hồi.")
            }

            val clientId = preferences.getEffectiveClientId()
            val clientSecret = preferences.getEffectiveClientSecret()

            val formBuilder = FormBody.Builder()
                .add("client_id", clientId)
                .add("refresh_token", refreshToken)
                .add("grant_type", "refresh_token")

            if (clientSecret.isNotBlank()) {
                formBuilder.add("client_secret", clientSecret)
            }

            val request = Request.Builder()
                .url("https://oauth2.googleapis.com/token")
                .post(formBuilder.build())
                .build()

            val (isSuccessful, statusCode, responseBody) = httpClient.newCall(request).execute().use { response ->
                Triple(response.isSuccessful, response.code, response.body?.string() ?: "")
            }

            if (statusCode == 400 || statusCode == 401) {
                signOut()
                _authErrorMessage.value = "Phiên đăng nhập đã bị thu hồi. Vui lòng đăng nhập lại."
                throw IllegalStateException("Phiên đăng nhập đã bị thu hồi.")
            }

            if (!isSuccessful) {
                throw IllegalStateException("Lỗi làm mới token: $responseBody")
            }

            val tokenResponse = json.decodeFromString<TokenResponse>(responseBody)
            val newTokens = OAuthTokens(
                accessToken = tokenResponse.accessToken,
                refreshToken = tokenResponse.refreshToken ?: refreshToken,
                expiresIn = tokenResponse.expiresIn,
                expiresAt = System.currentTimeMillis() + (tokenResponse.expiresIn * 1000L)
            )

            tokenStorage.saveTokens(newTokens)
            return@withLock newTokens.accessToken
        }
    }

    private suspend fun fetchAndSaveUserInfo(accessToken: String) {
        try {
            val request = Request.Builder()
                .url("https://www.googleapis.com/oauth2/v2/userinfo")
                .addHeader("Authorization", "Bearer $accessToken")
                .build()

            httpClient.newCall(request).execute().use { response ->
                if (response.isSuccessful) {
                    val body = response.body?.string() ?: return
                    val userInfo = json.decodeFromString<GoogleUserInfo>(body)
                    preferences.saveUserProfile(userInfo.email, userInfo.name, userInfo.picture)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    suspend fun signOut() {
        tokenStorage.clearTokens()
        preferences.clear()
        _isAuthenticated.value = false
    }
}
