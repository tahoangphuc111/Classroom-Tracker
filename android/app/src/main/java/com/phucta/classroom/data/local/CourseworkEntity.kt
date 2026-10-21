package com.phucta.classroom.data.local

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.data.model.SubmissionStatus
import com.phucta.classroom.data.model.normalizeForVietnameseSearch

@Entity(
    tableName = "courseworks",
    indices = [
        Index(value = ["course_id"], name = "idx_courseworks_course_id"),
        Index(value = ["due_epoch_millis"], name = "idx_courseworks_due_epoch"),
        Index(value = ["status"], name = "idx_courseworks_status")
    ]
)
data class CourseworkEntity(
    @PrimaryKey
    val id: String,

    @ColumnInfo(name = "course_id")
    val courseId: String,

    @ColumnInfo(name = "course_name")
    val courseName: String,

    @ColumnInfo(name = "title")
    val title: String,

    @ColumnInfo(name = "description")
    val description: String? = null,

    @ColumnInfo(name = "alternate_link")
    val alternateLink: String? = null,

    @ColumnInfo(name = "due_epoch_millis")
    val dueEpochMillis: Long? = null,

    @ColumnInfo(name = "status")
    val status: String,

    @ColumnInfo(name = "max_points")
    val maxPoints: Double? = null,

    @ColumnInfo(name = "is_manually_completed")
    val isManuallyCompleted: Boolean = false,

    @ColumnInfo(name = "search_index")
    val searchIndex: String,

    @ColumnInfo(name = "normalized_title", defaultValue = "")
    val normalizedTitle: String = "",

    @ColumnInfo(name = "normalized_course_name", defaultValue = "")
    val normalizedCourseName: String = ""
) {
    fun toCoursework(): Coursework {
        val normTitle = if (normalizedTitle.isNotEmpty()) normalizedTitle else title.normalizeForVietnameseSearch()
        val normCourse = if (normalizedCourseName.isNotEmpty()) normalizedCourseName else courseName.normalizeForVietnameseSearch()
        return Coursework(
            id = id,
            courseId = courseId,
            courseName = courseName,
            title = title,
            description = description,
            alternateLink = alternateLink,
            dueEpochMillis = dueEpochMillis,
            status = SubmissionStatus.fromRaw(status),
            maxPoints = maxPoints,
            isManuallyCompleted = isManuallyCompleted,
            normalizedTitle = normTitle,
            normalizedCourseName = normCourse,
            searchIndex = searchIndex
        )
    }

    fun toDomain(): Coursework = toCoursework()

    companion object {
        fun fromDomain(domain: Coursework): CourseworkEntity = CourseworkEntity(
            id = domain.id,
            courseId = domain.courseId,
            courseName = domain.courseName,
            title = domain.title,
            description = domain.description,
            alternateLink = domain.alternateLink,
            dueEpochMillis = domain.dueEpochMillis,
            status = domain.status.rawValue,
            maxPoints = domain.maxPoints,
            isManuallyCompleted = domain.isManuallyCompleted,
            searchIndex = domain.searchIndex,
            normalizedTitle = domain.normalizedTitle,
            normalizedCourseName = domain.normalizedCourseName
        )
    }
}

fun List<CourseworkEntity>.toCoursework(): List<Coursework> {
    val count = this.size
    if (count == 0) return emptyList()
    val result = ArrayList<Coursework>(count)

    var lastRawCourseName: String? = null
    var lastNormCourseName: String? = null

    for (i in 0 until count) {
        val entity = this[i]
        val normTitle = if (entity.normalizedTitle.isNotEmpty()) {
            entity.normalizedTitle
        } else {
            entity.title.normalizeForVietnameseSearch()
        }

        val normCourse = if (entity.normalizedCourseName.isNotEmpty()) {
            entity.normalizedCourseName
        } else {
            val raw = entity.courseName
            if (raw == lastRawCourseName && lastNormCourseName != null) {
                lastNormCourseName
            } else {
                val computed = raw.normalizeForVietnameseSearch()
                lastRawCourseName = raw
                lastNormCourseName = computed
                computed
            }
        }

        result.add(
            Coursework(
                id = entity.id,
                courseId = entity.courseId,
                courseName = entity.courseName,
                title = entity.title,
                description = entity.description,
                alternateLink = entity.alternateLink,
                dueEpochMillis = entity.dueEpochMillis,
                status = SubmissionStatus.fromRaw(entity.status),
                maxPoints = entity.maxPoints,
                isManuallyCompleted = entity.isManuallyCompleted,
                normalizedTitle = normTitle,
                normalizedCourseName = normCourse,
                searchIndex = entity.searchIndex
            )
        )
    }
    return result
}
