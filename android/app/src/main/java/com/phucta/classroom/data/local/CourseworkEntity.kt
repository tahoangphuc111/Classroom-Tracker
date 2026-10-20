package com.phucta.classroom.data.local

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.data.model.SubmissionStatus

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
    val searchIndex: String
) {
    fun toDomain(): Coursework = Coursework(
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
        searchIndex = searchIndex
    )

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
            searchIndex = domain.searchIndex
        )
    }
}
