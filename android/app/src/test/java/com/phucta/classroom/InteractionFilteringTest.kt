package com.phucta.classroom

import com.phucta.classroom.data.model.ClassroomDateUtils
import com.phucta.classroom.data.model.Course
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.data.model.SubmissionStatus
import com.phucta.classroom.data.model.cleanTelexKeystrokes
import com.phucta.classroom.data.model.normalizeForVietnameseSearch
import com.phucta.classroom.data.model.tokenizeSearchQuery
import com.phucta.classroom.domain.BaoBaiBucketingUtils
import org.junit.Assert.assertEquals
import org.junit.Test

class InteractionFilteringTest {
    @Test
    fun fusedFilteringPreservesSectionsRankingAndCounts() {
        val now = System.currentTimeMillis()
        val items = (0 until 60).map { i ->
            Coursework(
                id = "item-$i",
                courseId = listOf("math", "physics", "unknown")[i % 3],
                courseName = if (i % 2 == 0) "Toán" else "Vật lý",
                title = listOf("Bài tập về nhà giải tích", "Kiểm tra 15 phút", "Đọc SGK")[i % 3],
                description = "Ôn tập chương 2",
                dueEpochMillis = when (i % 5) {
                    0 -> now - 3_600_000L
                    1 -> ClassroomDateUtils.startOfTomorrow + 3_600_000L
                    2 -> ClassroomDateUtils.startOfDayAfter + 3_600_000L
                    3 -> null
                    else -> now + 3_600_000L
                },
                status = if (i % 4 == 0) SubmissionStatus.TURNED_IN else SubmissionStatus.PENDING
            )
        }
        val selections = listOf(
            emptyList(),
            listOf(Course("math", "Toán", isSelectedForWidget = true), Course("physics", "Lý", isSelectedForWidget = false)),
            listOf(Course("math", "Toán", isSelectedForWidget = false), Course("physics", "Lý", isSelectedForWidget = false)),
            listOf(Course("unloaded", "Khác", isSelectedForWidget = false))
        )
        for (courses in selections) {
            for (raw in listOf("", "toans", "btvn", "15p", "sgk", "chuong 2", "khong co")) {
                val normalized = raw.normalizeForVietnameseSearch()
                val tokens = tokenizeSearchQuery(normalized)
                val active = BaoBaiBucketingUtils.filterByActiveCourses(items, courses)
                // The previous screen filtered first, then computeBuckets filtered again.
                val filtered = active.filter { item ->
                    tokens.all { token ->
                        item.searchIndex.contains(token) || cleanTelexKeystrokes(token).let { alternative ->
                            alternative != token && item.searchIndex.contains(alternative)
                        }
                    }
                }
                val previous = BaoBaiBucketingUtils.computeBuckets(filtered, searchTokens = tokens, rawNormalizedQuery = normalized)
                val fused = BaoBaiBucketingUtils.computeBuckets(items, courses, tokens, normalized)
                assertEquals("Selection/query parity: $courses / $raw", previous, fused)
                val count = fused.overdue.size + fused.today.size + fused.tomorrow.size +
                    fused.laterUpcoming.size + fused.noDueDate.size + fused.completed.size
                assertEquals("Search count must include each matched item once", filtered.size, count)
            }
        }
    }
}
