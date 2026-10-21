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
        if (!app.oauthManager.isAuthenticated.value) {
            return Result.success()
        }

        return try {
            val syncResult = app.repository.syncAll()
            if (syncResult.isFailure) {
                val error = syncResult.exceptionOrNull()
                val isAuthError = !app.oauthManager.isAuthenticated.value ||
                        (error is IllegalStateException && error.message?.contains("Phiên đăng nhập") == true)
                if (isAuthError || runAttemptCount >= 3) {
                    return Result.failure()
                }
                return Result.retry()
            }
            Result.success()
        } catch (e: Exception) {
            e.printStackTrace()
            if (!app.oauthManager.isAuthenticated.value || runAttemptCount >= 3) {
                Result.failure()
            } else {
                Result.retry()
            }
        }
    }
}
