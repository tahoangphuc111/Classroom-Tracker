package com.phucta.classroom.worker

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.phucta.classroom.ClassroomApplication

class ClassroomSyncWorker(
    context: Context,
    workerParams: WorkerParameters
) : CoroutineWorker(context, workerParams) {

    override suspend fun doWork(): Result {
        val app = applicationContext as? ClassroomApplication ?: return Result.failure()
        return try {
            if (app.oauthManager.isAuthenticated.value) {
                val syncResult = app.repository.syncAll()
                if (syncResult.isFailure) {
                    return Result.retry()
                }
            }
            Result.success()
        } catch (e: Exception) {
            e.printStackTrace()
            Result.retry()
        }
    }
}
