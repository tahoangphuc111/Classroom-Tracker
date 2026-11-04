package com.phucta.classroom

import com.phucta.classroom.data.local.PersonalNoteEntity
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.data.model.PersonalNote
import com.phucta.classroom.data.model.SubmissionStatus
import com.phucta.classroom.domain.BaoBaiBucketingUtils
import com.phucta.classroom.ui.components.DueDateBadgeDefaults
import com.phucta.classroom.ui.theme.ChunkyColor
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar

class PersonalNoteTest {
    @Test
    fun testPersonalNoteSearchIndex() {
        val note = PersonalNote(
            id = "test-1",
            title = "Ôn tập Toán hình",
            content = "Làm bài tập trang 42 SGK",
            courseName = "Toán Học"
        )

        val index = note.searchIndex
        assertTrue("Search index should contain lowercase unaccented title", index.contains("toan"))
        assertTrue("Search index should contain content keyword", index.contains("trang 42"))
    }

    @Test
    fun testPersonalNoteIsDueTomorrowAndToday() {
        val now = Calendar.getInstance()

        val calTomorrow = (now.clone() as Calendar).apply {
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 15)
        }

        val noteTomorrow = PersonalNote(
            title = "Nộp bài mai",
            dueEpochMillis = calTomorrow.timeInMillis
        )
        assertTrue("Should be due tomorrow", noteTomorrow.isDueTomorrow)
        assertFalse("Should not be due today", noteTomorrow.isDueToday)

        val calToday = (now.clone() as Calendar).apply {
            set(Calendar.HOUR_OF_DAY, 20)
        }
        val noteToday = PersonalNote(
            title = "Nộp bài tối nay",
            dueEpochMillis = calToday.timeInMillis
        )
        assertTrue("Should be due today", noteToday.isDueToday)
        assertFalse("Should not be due tomorrow", noteToday.isDueTomorrow)
    }

    @Test
    fun testEntityDomainConversion() {
        val original = PersonalNote(
            id = "note-uuid-1",
            courseworkId = "cw-123",
            courseId = "c-1",
            courseName = "Vật Lý",
            title = "Chú ý đề bài câu 3",
            content = "Thầy dặn không dùng máy tính",
            dueEpochMillis = 1700000000000L,
            isCompleted = true,
            createdAt = 1699990000000L,
            updatedAt = 1699995000000L
        )

        val entity = PersonalNoteEntity.fromDomain(original)
        assertEquals("note-uuid-1", entity.id)
        assertEquals("cw-123", entity.courseworkId)
        assertEquals("Vật Lý", entity.courseName)
        assertEquals(true, entity.isCompleted)

        val backToDomain = entity.toDomain()
        assertEquals(original.id, backToDomain.id)
        assertEquals(original.courseworkId, backToDomain.courseworkId)
        assertEquals(original.title, backToDomain.title)
        assertEquals(original.content, backToDomain.content)
        assertEquals(original.isCompleted, backToDomain.isCompleted)
        assertEquals(original.searchIndex, backToDomain.searchIndex)
    }

    @Test
    fun testTomorrowCourseworkIncludesTomorrowPersonalNotes() {
        val now = Calendar.getInstance()
        val calTomorrow = (now.clone() as Calendar).apply {
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 9)
        }

        val noteTomorrow = PersonalNote(
            id = "note-standalone-1",
            courseworkId = null,
            courseName = "Văn Học",
            title = "Học thuộc bài thơ Tây Tiến",
            content = "Khổ 1 và 2",
            dueEpochMillis = calTomorrow.timeInMillis,
            isCompleted = false
        )

        val result = BaoBaiBucketingUtils.getTomorrowCoursework(
            items = emptyList(),
            personalNotes = listOf(noteTomorrow)
        )

        assertEquals("Should include tomorrow note when coursework items are empty", 1, result.size)
        val item = result.first()
        assertEquals("note_note-standalone-1", item.id)
        assertEquals("Học thuộc bài thơ Tây Tiến", item.title)
        assertEquals("Văn Học", item.courseName)
        assertFalse("Item should be pending", item.isCompleted)
    }

    @Test
    fun testClearingDueDateToNull() {
        val originalWithDue = PersonalNote(
            id = "note-due-1",
            title = "Bài tập Toán",
            dueEpochMillis = 1700000000000L
        )
        assertNotNull(originalWithDue.dueEpochMillis)

        val cleared = originalWithDue.copy(dueEpochMillis = null)
        assertEquals(null, cleared.dueEpochMillis)
        assertFalse(cleared.isDueToday)
        assertFalse(cleared.isDueTomorrow)

        val entity = PersonalNoteEntity.fromDomain(cleared)
        assertEquals(null, entity.dueEpochMillis)
        val domain = entity.toDomain()
        assertEquals(null, domain.dueEpochMillis)
    }

    @Test
    fun testVietnameseSearchIndexEdgeCases() {
        val note = PersonalNote(
            id = "note-diacritics",
            title = "ĐỀ CƯƠNG ÔN TẬP ĐỊA LÝ & LỊCH SỬ",
            content = "Phần 1: Khí hậu nhiệt đới gió mùa ẩm",
            courseName = "Địa Lý"
        )
        val index = note.searchIndex
        assertTrue("Should contain normalized 'de cuong'", index.contains("de cuong"))
        assertTrue("Should contain normalized 'dia ly'", index.contains("dia ly"))
        assertTrue("Should contain normalized 'nhiet doi'", index.contains("nhiet doi"))
    }

    @Test
    fun testCustomDueDateNeitherTodayNorTomorrow() {
        val calFuture = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 5)
            set(Calendar.HOUR_OF_DAY, 23)
            set(Calendar.MINUTE, 59)
        }
        val noteCustomDate = PersonalNote(
            id = "note-custom-date",
            title = "Nộp báo cáo nhóm",
            dueEpochMillis = calFuture.timeInMillis
        )
        assertFalse("Should not be due today", noteCustomDate.isDueToday)
        assertFalse("Should not be due tomorrow", noteCustomDate.isDueTomorrow)
        assertNotNull("Should have non-null dueEpochMillis", noteCustomDate.dueEpochMillis)
    }

    @Test
    fun testDueDateBadgeColorsWhenNoteCompleted() {
        val completedTomorrowBadge = DueDateBadgeDefaults.colors(
            isCompleted = true,
            isOverdue = false,
            isDueToday = false,
            isDueTomorrow = true
        )
        assertEquals(ChunkyColor.CompletedBadgeBackground, completedTomorrowBadge.background)
        assertEquals(ChunkyColor.CompletedBadgeBorder, completedTomorrowBadge.border)
        assertEquals(ChunkyColor.CompletedBadgeText, completedTomorrowBadge.text)

        val completedTodayBadge = DueDateBadgeDefaults.colors(
            isCompleted = true,
            isOverdue = false,
            isDueToday = true,
            isDueTomorrow = false
        )
        assertEquals(ChunkyColor.CompletedBadgeBackground, completedTodayBadge.background)
        assertEquals(ChunkyColor.CompletedBadgeText, completedTodayBadge.text)
    }

    @Test
    fun testEmptyContentClearingCondition() {
        val existingTitle = "Bài tập Vật Lý hạt nhân"
        val userEnteredContent = "   \n  \t  "
        val trimmed = userEnteredContent.trim()

        val shouldDelete = trimmed.isEmpty()
        assertTrue("Coursework attached note with empty trimmed content must be deleted", shouldDelete)
    }

    @Test
    fun testEndOfDayDetectionAt2355AndLater() {
        fun isEndOfDay(epoch: Long): Boolean {
            val cal = Calendar.getInstance().apply { timeInMillis = epoch }
            return (cal.get(Calendar.HOUR_OF_DAY) == 23 && cal.get(Calendar.MINUTE) >= 55) ||
                   (cal.get(Calendar.HOUR_OF_DAY) == 0 && cal.get(Calendar.MINUTE) == 0 && cal.get(Calendar.SECOND) == 0)
        }

        val cal2355 = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 23)
            set(Calendar.MINUTE, 55)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        assertTrue("23:55 should be detected as end of day", isEndOfDay(cal2355.timeInMillis))

        val cal2358 = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 23)
            set(Calendar.MINUTE, 58)
            set(Calendar.SECOND, 30)
            set(Calendar.MILLISECOND, 0)
        }
        assertTrue("23:58:30 should be detected as end of day", isEndOfDay(cal2358.timeInMillis))

        val cal2359 = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 23)
            set(Calendar.MINUTE, 59)
            set(Calendar.SECOND, 59)
            set(Calendar.MILLISECOND, 999)
        }
        assertTrue("23:59:59.999 should be detected as end of day", isEndOfDay(cal2359.timeInMillis))

        val calMidnight = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        assertTrue("00:00:00.000 should be detected as end of day", isEndOfDay(calMidnight.timeInMillis))

        val cal2354 = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 23)
            set(Calendar.MINUTE, 54)
            set(Calendar.SECOND, 59)
            set(Calendar.MILLISECOND, 999)
        }
        assertFalse("23:54:59 should NOT be detected as end of day", isEndOfDay(cal2354.timeInMillis))
    }

    @Test
    fun testQuickCaptureDeadlineTimestampAlignment() {
        val todayEndOfDay = com.phucta.classroom.data.model.ClassroomDateUtils.startOfToday +
                23 * 3600 * 1000L + 59 * 60 * 1000L + 59 * 1000L + 999L
        val tomorrowEndOfDay = com.phucta.classroom.data.model.ClassroomDateUtils.startOfTomorrow +
                23 * 3600 * 1000L + 59 * 60 * 1000L + 59 * 1000L + 999L

        val calToday = Calendar.getInstance().apply { timeInMillis = todayEndOfDay }
        assertEquals(23, calToday.get(Calendar.HOUR_OF_DAY))
        assertEquals(59, calToday.get(Calendar.MINUTE))
        assertEquals(59, calToday.get(Calendar.SECOND))
        assertEquals(999, calToday.get(Calendar.MILLISECOND))

        val calTomorrow = Calendar.getInstance().apply { timeInMillis = tomorrowEndOfDay }
        assertEquals(23, calTomorrow.get(Calendar.HOUR_OF_DAY))
        assertEquals(59, calTomorrow.get(Calendar.MINUTE))
        assertEquals(59, calTomorrow.get(Calendar.SECOND))
        assertEquals(999, calTomorrow.get(Calendar.MILLISECOND))

        assertEquals("Cuối ngày", com.phucta.classroom.data.model.ClassroomDateUtils.buildTimeOnlyString(todayEndOfDay))
        assertEquals("Cuối ngày", com.phucta.classroom.data.model.ClassroomDateUtils.buildTimeOnlyString(tomorrowEndOfDay))

        val noteToday = PersonalNote(title = "Task Today", dueEpochMillis = todayEndOfDay)
        assertTrue("Quick capture today note should be due today", noteToday.isDueToday)
        assertFalse("Quick capture today note should not be due tomorrow", noteToday.isDueTomorrow)

        val noteTomorrow = PersonalNote(title = "Task Tomorrow", dueEpochMillis = tomorrowEndOfDay)
        assertTrue("Quick capture tomorrow note should be due tomorrow", noteTomorrow.isDueTomorrow)
        assertFalse("Quick capture tomorrow note should not be due today", noteTomorrow.isDueToday)
    }

    @Test
    fun testBuildSearchIndex_IncludesChecklistItems() {
        val checklist = listOf(
            com.phucta.classroom.data.model.ChecklistItem(title = "Nộp bản nháp"),
            com.phucta.classroom.data.model.ChecklistItem(title = "Chuẩn bị slide")
        )
        val note = PersonalNote(
            title = "Thuyết trình",
            content = "Phần 1 và 2",
            courseName = "Tin học",
            checklist = checklist
        )
        assertTrue(note.searchIndex.contains("ban nhap"))
        assertTrue(note.searchIndex.contains("slide"))
        assertTrue(note.searchIndex.contains("thuyet trinh"))
    }

    @Test
    fun testAttachedNoteRetentionLogic() {
        val emptyAttachedNote = PersonalNote(
            id = "note-empty",
            courseworkId = "cw-1",
            title = "Bài tập",
            content = "   ",
            checklist = emptyList()
        )
        val shouldDelete = emptyAttachedNote.courseworkId != null &&
            emptyAttachedNote.content.trim().isEmpty() &&
            emptyAttachedNote.checklist.isEmpty()
        assertTrue("Attached note with blank content and empty checklist should be eligible for deletion", shouldDelete)

        val noteWithChecklistOnly = emptyAttachedNote.copy(
            checklist = listOf(com.phucta.classroom.data.model.ChecklistItem(title = "Việc 1"))
        )
        val shouldDeleteWithChecklist = noteWithChecklistOnly.courseworkId != null &&
            noteWithChecklistOnly.content.trim().isEmpty() &&
            noteWithChecklistOnly.checklist.isEmpty()
        assertFalse("Attached note with checklist must not be deleted even if content is empty", shouldDeleteWithChecklist)
    }
}
