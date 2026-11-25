package com.phucta.classroom.ui

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.lifecycle.lifecycleScope
import com.phucta.classroom.ClassroomApplication
import com.phucta.classroom.data.model.ClassroomDateUtils
import com.phucta.classroom.ui.screens.MainScreen
import com.phucta.classroom.ui.theme.ClassroomTheme
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {
    private val app: ClassroomApplication by lazy { applicationContext as ClassroomApplication }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        handleOAuthIntent(intent)

        enableEdgeToEdge()

        setContent {
            ClassroomTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.surface
                ) {
                    MainScreen()
                }
            }
        }
    }

    override fun onResume() {
        super.onResume()
        ClassroomDateUtils.ensureDayBoundaries()
        lifecycleScope.launch {
            if (app.oauthManager.isAuthenticated.value) {
                val lastSync = app.preferences.lastSyncTimestampFlow.first()
                val now = System.currentTimeMillis()
                if (lastSync == null || (now - lastSync) > 300_000L) {
                    app.repository.syncAll()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleOAuthIntent(intent)
    }

    private fun handleOAuthIntent(intent: Intent?) {
        val uri: Uri = intent?.data ?: return
        val scheme = uri.scheme ?: return

        if (scheme.contains("googleusercontent") || scheme == "com.phucta.classroom") {
            intent.data = null
            lifecycleScope.launch {
                val success = app.oauthManager.handleRedirectUri(uri)
                if (success) {
                    app.repository.syncAll()
                }
            }
        }
    }
}
