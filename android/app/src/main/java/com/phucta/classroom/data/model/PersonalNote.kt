package com.phucta.classroom.data.model

import java.util.Calendar
import java.util.UUID

data class PersonalNote(
    val id: String = UUID.randomUUID().toString(),
    val courseworkId: String? = null,
    val courseId: String? = null,
    val courseName: String? = null,
    val title: String,
    val content: String = "",
    val dueEpochMillis: Long? = null,
    val isCompleted: Boolean = false,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis(),
    val searchIndex: String = buildSearchIndex(title, content, courseName)
) {
    val isDueTomorrow: Boolean
        get() {
            if (dueEpochMillis == null) return false
            val now = Calendar.getInstance()
            val tomorrowStart = (now.clone() as Calendar).apply {
                add(Calendar.DAY_OF_YEAR, 1)
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            val tomorrowEnd = (now.clone() as Calendar).apply {
                add(Calendar.DAY_OF_YEAR, 1)
                set(Calendar.HOUR_OF_DAY, 23)
                set(Calendar.MINUTE, 59)
                set(Calendar.SECOND, 59)
                set(Calendar.MILLISECOND, 999)
            }
            return dueEpochMillis in tomorrowStart.timeInMillis..tomorrowEnd.timeInMillis
        }

    val isDueToday: Boolean
        get() {
            if (dueEpochMillis == null) return false
            val now = Calendar.getInstance()
            val todayStart = (now.clone() as Calendar).apply {
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            val todayEnd = (now.clone() as Calendar).apply {
                set(Calendar.HOUR_OF_DAY, 23)
                set(Calendar.MINUTE, 59)
                set(Calendar.SECOND, 59)
                set(Calendar.MILLISECOND, 999)
            }
            return dueEpochMillis in todayStart.timeInMillis..todayEnd.timeInMillis
        }

    companion object {
        fun buildSearchIndex(title: String, content: String, courseName: String?): String {
            val combined = "$title $content ${courseName ?: ""}"
            return combined.normalizeForVietnameseSearch()
        }
    }
}
