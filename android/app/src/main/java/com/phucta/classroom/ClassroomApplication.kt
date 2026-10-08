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
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
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

    override fun onCreate() {
        super.onCreate()

        database = ClassroomDatabase.getInstance(this)
        preferences = ClassroomPreferences(this)
        tokenStorage = TokenStorage(this)
        oauthManager = GoogleOAuthManager(this, preferences, tokenStorage)
        repository = ClassroomRepository(this, database, preferences, oauthManager)

        CoroutineScope(Dispatchers.IO).launch {
            repository.ensureInitialData()
        }

        setupPeriodicBackgroundSync()
    }

    private fun setupPeriodicBackgroundSync() {
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
    }
}
