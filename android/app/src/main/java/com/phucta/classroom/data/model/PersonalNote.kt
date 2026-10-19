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
        get() = ClassroomDateUtils.isDueTomorrow(dueEpochMillis)

    val isDueToday: Boolean
        get() = ClassroomDateUtils.isDueToday(dueEpochMillis)

    companion object {
        fun buildSearchIndex(title: String, content: String, courseName: String?): String {
            val combined = "$title $content ${courseName ?: ""}"
            return combined.normalizeForVietnameseSearch()
        }
    }
}
