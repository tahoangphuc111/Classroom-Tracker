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
                val isAuthError = isAuthenticationError(app, error)
                if (isAuthError || runAttemptCount >= 3) {
                    return Result.failure()
                }
                return Result.retry()
            }
            Result.success()
        } catch (e: Exception) {
            e.printStackTrace()
            val isAuthError = isAuthenticationError(app, e)
            if (isAuthError || runAttemptCount >= 3) {
                Result.failure()
            } else {
                Result.retry()
            }
        }
    }

    private fun isAuthenticationError(app: ClassroomApplication, throwable: Throwable?): Boolean {
        if (!app.oauthManager.isAuthenticated.value) return true
        val message = throwable?.message ?: return false
        return message.contains("Phiên đăng nhập", ignoreCase = true) ||
                message.contains("Chưa đăng nhập", ignoreCase = true) ||
                message.contains("Chưa kết nối", ignoreCase = true) ||
                message.contains("401") ||
                message.contains("403") ||
                message.contains("invalid_grant", ignoreCase = true)
    }
}
