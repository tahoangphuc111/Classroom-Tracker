package com.phucta.classroom.data.model

import androidx.compose.runtime.Immutable
import kotlinx.serialization.Serializable
import java.util.UUID

@Immutable
@Serializable
data class ChecklistItem(
    val id: String = UUID.randomUUID().toString(),
    val title: String,
    val isCompleted: Boolean = false
)

@Immutable
data class PersonalNote(
    val id: String = UUID.randomUUID().toString(),
    val courseworkId: String? = null,
    val courseId: String? = null,
    val courseName: String? = null,
    val title: String,
    val content: String = "",
    val checklist: List<ChecklistItem> = emptyList(),
    val dueEpochMillis: Long? = null,
    val isCompleted: Boolean = false,
    val createdAt: Long = System.currentTimeMillis(),
    val updatedAt: Long = System.currentTimeMillis(),
    val searchIndex: String = buildSearchIndex(title, content, courseName, checklist)
) {
    val isDueTomorrow: Boolean
        get() = ClassroomDateUtils.isDueTomorrow(dueEpochMillis)

    val isDueToday: Boolean
        get() = ClassroomDateUtils.isDueToday(dueEpochMillis)

    val hasChecklist: Boolean
        get() = checklist.isNotEmpty()

    val totalChecklistCount: Int
        get() = checklist.size

    val completedChecklistCount: Int
        get() = checklist.count { it.isCompleted }

    val checklistProgress: Float
        get() = if (checklist.isEmpty()) 0f else completedChecklistCount.toFloat() / totalChecklistCount.toFloat()

    fun searchRelevanceScore(tokens: List<String>, rawNormalizedQuery: String): Int {
        return calculateSearchRelevance(
            queryTokens = tokens,
            rawNormalizedQuery = rawNormalizedQuery,
            title = title,
            courseName = courseName,
            content = content,
            checklistTitles = checklist.map { it.title }
        )
    }

    companion object {
        fun buildSearchIndex(
            title: String,
            content: String,
            courseName: String?,
            checklist: List<ChecklistItem> = emptyList()
        ): String {
            val checklistText = if (checklist.isEmpty()) "" else checklist.joinToString(" ") { it.title }
            val combined = "$title $content ${courseName ?: ""} $checklistText"
            val base = combined.normalizeForVietnameseSearch()
            val extra = expandVietnameseAcronyms(base)
            return if (extra.isEmpty()) base else "$base $extra"
        }
    }
}
