package com.phucta.classroom

import android.app.Application
import androidx.work.Constraints
import androidx.work.ExistingPeriodicWorkPolicy
import androidx.work.NetworkType
import androidx.work.PeriodicWorkRequestBuilder
import androidx.work.WorkManager
import com.phucta.classroom.data.local.ClassroomDatabase
import com.phucta.classroom.data.local.ClassroomPreferences
import com.phucta.classroom.data.local.TokenStorage
import com.phucta.classroom.data.remote.GoogleOAuthManager
import com.phucta.classroom.data.repository.ClassroomRepository
import com.phucta.classroom.worker.ClassroomSyncWorker
import com.phucta.classroom.data.model.ClassroomDateUtils
import com.phucta.classroom.data.model.clearVietnameseSearchCache
import com.phucta.classroom.data.remote.ClassroomApiService
import com.phucta.classroom.ui.components.SubjectArtHelper
import com.phucta.classroom.widget.EmberWidgetBitmapHelper
import kotlinx.coroutines.CoroutineExceptionHandler
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import okhttp3.OkHttpClient
import java.util.concurrent.TimeUnit

class ClassroomApplication : Application() {
    lateinit var database: ClassroomDatabase
        private set
    lateinit var preferences: ClassroomPreferences
        private set
    lateinit var tokenStorage: TokenStorage
        private set
    lateinit var oauthManager: GoogleOAuthManager
        private set
    lateinit var repository: ClassroomRepository
        private set

    val okHttpClient: OkHttpClient by lazy {
        OkHttpClient.Builder()
            .connectTimeout(20, TimeUnit.SECONDS)
            .readTimeout(20, TimeUnit.SECONDS)
            .writeTimeout(20, TimeUnit.SECONDS)
            .build()
    }

    private val applicationScope = CoroutineScope(
        SupervisorJob() + Dispatchers.IO + CoroutineExceptionHandler { _, throwable ->
            android.util.Log.e("ClassroomApplication", "Unhandled application coroutine exception", throwable)
        }
    )

    override fun onCreate() {
        super.onCreate()

        database = ClassroomDatabase.getInstance(this)
        preferences = ClassroomPreferences(this)
        tokenStorage = TokenStorage(this)
        oauthManager = GoogleOAuthManager(this, preferences, tokenStorage, okHttpClient)
        val apiService = ClassroomApiService(okHttpClient)
        repository = ClassroomRepository(this, database, preferences, oauthManager, apiService)

        applicationScope.launch {
            repository.ensureInitialData()
        }

        setupPeriodicBackgroundSync()
    }

    private fun setupPeriodicBackgroundSync() {
        try {
            val constraints = Constraints.Builder()
                .setRequiredNetworkType(NetworkType.CONNECTED)
                .build()

            val syncRequest = PeriodicWorkRequestBuilder<ClassroomSyncWorker>(15, TimeUnit.MINUTES)
                .setConstraints(constraints)
                .build()

            WorkManager.getInstance(this).enqueueUniquePeriodicWork(
                "classroom_periodic_sync",
                ExistingPeriodicWorkPolicy.KEEP,
                syncRequest
            )
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)
        if (level >= TRIM_MEMORY_BACKGROUND) {
            SubjectArtHelper.clearCaches()
            ClassroomDateUtils.clearCaches()
            EmberWidgetBitmapHelper.clearCache()
            clearVietnameseSearchCache()
        }
    }

    override fun onLowMemory() {
        super.onLowMemory()
        SubjectArtHelper.clearCaches()
        ClassroomDateUtils.clearCaches()
        EmberWidgetBitmapHelper.clearCache()
        clearVietnameseSearchCache()
    }
}
