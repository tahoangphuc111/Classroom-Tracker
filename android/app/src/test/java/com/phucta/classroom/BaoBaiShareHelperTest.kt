package com.phucta.classroom

import android.content.Intent
import com.phucta.classroom.data.model.ClassroomDateUtils
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.data.model.SubmissionStatus
import com.phucta.classroom.domain.BaoBaiShareHelper
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class BaoBaiShareHelperTest {
    @Test
    fun testFormatEmptyList() {
        val text = BaoBaiShareHelper.formatBaoBaiText(
            items = emptyList(),
            dateEpochMillis = 1770000000000L,
            targetDayLabel = "NGÀY MAI"
        )
        assertTrue(text.contains("🎉 BÁO BÀI NGÀY MAI"))
        assertTrue(text.contains("không có bài tập nào cần làm"))
        assertTrue(text.contains("⚡ Classroom Tracker"))
    }

    @Test
    fun testFormatNonEmptyListWithProgress() {
        val startOfTomorrow = ClassroomDateUtils.startOfTomorrow
        val items = listOf(
            Coursework(
                id = "1",
                courseId = "c1",
                courseName = "Toán 12",
                title = "Bài tập Đại số chương 3",
                dueEpochMillis = startOfTomorrow + 23 * 3600 * 1000L,
                status = SubmissionStatus.PENDING
            ),
            Coursework(
                id = "2",
                courseId = "c2",
                courseName = "Ngữ văn",
                title = "Soạn bài Đất Nước",
                dueEpochMillis = startOfTomorrow + 12 * 3600 * 1000L,
                status = SubmissionStatus.TURNED_IN,
                isManuallyCompleted = true
            ),
            Coursework(
                id = "3",
                courseId = "c3",
                courseName = "Tiếng Anh",
                title = "Review Unit 5",
                dueEpochMillis = null,
                status = SubmissionStatus.PENDING
            )
        )

        val text = BaoBaiShareHelper.formatBaoBaiText(
            items = items,
            dateEpochMillis = startOfTomorrow,
            targetDayLabel = "NGÀY MAI"
        )

        assertTrue(text.contains("📋 BÁO BÀI NGÀY MAI"))
        assertTrue(text.contains("1. [Toán 12] Bài tập Đại số chương 3"))
        assertTrue(text.contains("2. [Ngữ văn] Soạn bài Đất Nước"))
        assertTrue(text.contains("(Đã xong ✓)"))
        assertTrue(text.contains("3. [Tiếng Anh] Review Unit 5 — Không có hạn nộp"))
        assertTrue(text.contains("🔥 Tiến độ: 1/3 bài hoàn thành"))
        assertTrue(text.contains("⚡ Classroom Tracker"))
    }

    @Test
    fun testFormatHeaderDate() {
        val formatted = BaoBaiShareHelper.formatHeaderDate(1770000000000L)
        assertNotNull(formatted)
        assertTrue(formatted.isNotBlank())
        assertTrue(formatted[0].isUpperCase())
    }
}
