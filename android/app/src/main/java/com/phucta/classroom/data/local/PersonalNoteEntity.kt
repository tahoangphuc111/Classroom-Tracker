package com.phucta.classroom.data.local

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.phucta.classroom.data.model.ChecklistItem
import com.phucta.classroom.data.model.PersonalNote
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

@Entity(
    tableName = "personal_notes",
    indices = [
        Index(value = ["coursework_id"], name = "idx_personal_notes_coursework_id"),
        Index(value = ["due_epoch_millis"], name = "idx_personal_notes_due_epoch"),
        Index(value = ["is_completed"], name = "idx_personal_notes_is_completed")
    ]
)
data class PersonalNoteEntity(
    @PrimaryKey
    val id: String,

    @ColumnInfo(name = "coursework_id")
    val courseworkId: String? = null,

    @ColumnInfo(name = "course_id")
    val courseId: String? = null,

    @ColumnInfo(name = "course_name")
    val courseName: String? = null,

    @ColumnInfo(name = "title")
    val title: String,

    @ColumnInfo(name = "content")
    val content: String,

    @ColumnInfo(name = "checklist_json", defaultValue = "[]")
    val checklistJson: String = "[]",

    @ColumnInfo(name = "due_epoch_millis")
    val dueEpochMillis: Long? = null,

    @ColumnInfo(name = "is_completed")
    val isCompleted: Boolean = false,

    @ColumnInfo(name = "created_at")
    val createdAt: Long,

    @ColumnInfo(name = "updated_at")
    val updatedAt: Long,

    @ColumnInfo(name = "search_index")
    val searchIndex: String
) {
    fun toDomain(): PersonalNote {
        val parsedChecklist = try {
            if (checklistJson.isNotBlank() && checklistJson != "[]") {
                jsonHelper.decodeFromString<List<ChecklistItem>>(checklistJson)
            } else {
                emptyList()
            }
        } catch (_: Exception) {
            emptyList()
        }

        return PersonalNote(
            id = id,
            courseworkId = courseworkId,
            courseId = courseId,
            courseName = courseName,
            title = title,
            content = content,
            checklist = parsedChecklist,
            dueEpochMillis = dueEpochMillis,
            isCompleted = isCompleted,
            createdAt = createdAt,
            updatedAt = updatedAt,
            searchIndex = searchIndex
        )
    }

    companion object {
        private val jsonHelper = Json {
            ignoreUnknownKeys = true
            isLenient = true
        }

        fun fromDomain(domain: PersonalNote): PersonalNoteEntity {
            val encodedChecklist = try {
                if (domain.checklist.isNotEmpty()) {
                    jsonHelper.encodeToString(domain.checklist)
                } else {
                    "[]"
                }
            } catch (_: Exception) {
                "[]"
            }

            return PersonalNoteEntity(
                id = domain.id,
                courseworkId = domain.courseworkId,
                courseId = domain.courseId,
                courseName = domain.courseName,
                title = domain.title,
                content = domain.content,
                checklistJson = encodedChecklist,
                dueEpochMillis = domain.dueEpochMillis,
                isCompleted = domain.isCompleted,
                createdAt = domain.createdAt,
                updatedAt = domain.updatedAt,
                searchIndex = PersonalNote.buildSearchIndex(
                    domain.title,
                    domain.content,
                    domain.courseName,
                    domain.checklist
                )
            )
        }
    }
}
