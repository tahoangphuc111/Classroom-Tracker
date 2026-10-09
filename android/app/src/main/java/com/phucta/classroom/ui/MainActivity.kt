package com.phucta.classroom.ui

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.ui.Modifier
import androidx.lifecycle.lifecycleScope
import com.phucta.classroom.ClassroomApplication
import com.phucta.classroom.ui.screens.MainScreen
import com.phucta.classroom.ui.theme.ChunkyColor
import com.phucta.classroom.ui.theme.ClassroomTypography
import kotlinx.coroutines.launch

class MainActivity : ComponentActivity() {

    private lateinit var app: ClassroomApplication

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        app = applicationContext as ClassroomApplication

        handleOAuthIntent(intent)

        setContent {
            MaterialTheme(
                colorScheme = lightColorScheme(
                    primary = ChunkyColor.SkyBottom,
                    background = ChunkyColor.WindowBackground,
                    surface = ChunkyColor.SurfaceWhite,
                    onPrimary = ChunkyColor.SurfaceWhite,
                    onBackground = ChunkyColor.TextPrimary,
                    onSurface = ChunkyColor.TextPrimary
                ),
                typography = ClassroomTypography
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(ChunkyColor.WindowBackground)
                ) {
                    MainScreen()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleOAuthIntent(intent)
    }

    private fun handleOAuthIntent(intent: Intent?) {
        val uri: Uri = intent?.data ?: return
        val scheme = uri.scheme ?: return

        if (scheme.contains("googleusercontent") || scheme == "com.phucta.classroom") {
            lifecycleScope.launch {
                val success = app.oauthManager.handleRedirectUri(uri)
                if (success) {
                    app.repository.syncAll()
                }
            }
        }
    }
}
