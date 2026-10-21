package com.phucta.classroom.data.model

import androidx.compose.runtime.Immutable
import kotlinx.serialization.Serializable

@Immutable
@Serializable
data class Coursework(
    val id: String,
    val courseId: String,
    val courseName: String,
    val title: String,
    val description: String? = null,
    val alternateLink: String? = null,
    val dueEpochMillis: Long? = null,
    val status: SubmissionStatus = SubmissionStatus.PENDING,
    val maxPoints: Double? = null,
    val isManuallyCompleted: Boolean = false,
    val normalizedTitle: String = title.normalizeForVietnameseSearch(),
    val normalizedCourseName: String = courseName.normalizeForVietnameseSearch(),
    val searchIndex: String = buildNormalizedSearchIndex(normalizedTitle, normalizedCourseName, description)
) {
    val timeOnlyString: String
        get() = ClassroomDateUtils.buildTimeOnlyString(dueEpochMillis)
    val formattedFullDueDate: String
        get() = ClassroomDateUtils.buildFormattedFullDueDate(dueEpochMillis)

    val isCompleted: Boolean
        get() = status == SubmissionStatus.TURNED_IN ||
                status == SubmissionStatus.RETURNED ||
                isManuallyCompleted ||
                (dueEpochMillis != null && dueEpochMillis < System.currentTimeMillis())
    val destinationURL: String
        get() = alternateLink ?: "https://classroom.google.com"

    val isUrgent: Boolean
        get() {
            if (dueEpochMillis == null || isCompleted) return false
            val interval = dueEpochMillis - System.currentTimeMillis()
            return interval in 1..(12 * 3600 * 1000)
        }
    val isOverdue: Boolean
        get() = false

    val isPast: Boolean
        get() = ClassroomDateUtils.isPast(dueEpochMillis)

    val isDueToday: Boolean
        get() = ClassroomDateUtils.isDueToday(dueEpochMillis)

    val isDueTomorrow: Boolean
        get() = ClassroomDateUtils.isDueTomorrow(dueEpochMillis)

    val hasNoDueDate: Boolean
        get() = dueEpochMillis == null

    val isDueTodayOrTomorrow: Boolean
        get() = isDueToday || isDueTomorrow

    val isUpcomingTodayOrTomorrow: Boolean
        get() = isDueTodayOrTomorrow && !isCompleted

    val friendlyDueString: String
        get() = ClassroomDateUtils.friendlyDueString(dueEpochMillis, isCompleted)

    val countdownBadgeString: String
        get() = ClassroomDateUtils.countdownBadgeString(dueEpochMillis, isCompleted)

    val compactDueString: String
        get() = ClassroomDateUtils.compactDueString(dueEpochMillis, isCompleted, timeOnlyString)

    val isDueLater: Boolean
        get() = dueEpochMillis != null && dueEpochMillis >= ClassroomDateUtils.startOfDayAfter

    val statusTitle: String
        get() = when (status) {
            SubmissionStatus.TURNED_IN -> "Đã nộp"
            SubmissionStatus.RETURNED -> "Đã chấm điểm"
            SubmissionStatus.LATE -> "Đã hoàn thành"
            SubmissionStatus.PENDING -> if (isCompleted) "Đã hoàn thành" else "Chưa nộp"
        }
    companion object {
        fun buildSearchIndex(title: String, courseName: String, description: String?): String {
            val normTitle = title.normalizeForVietnameseSearch()
            val normCourse = courseName.normalizeForVietnameseSearch()
            return buildNormalizedSearchIndex(normTitle, normCourse, description)
        }
        fun buildNormalizedSearchIndex(normTitle: String, normCourse: String, description: String?): String {
            return if (description.isNullOrBlank()) {
                "$normTitle $normCourse"
            } else {
                "$normTitle $normCourse ${description.normalizeForVietnameseSearch()}"
            }
        }
    }
}
