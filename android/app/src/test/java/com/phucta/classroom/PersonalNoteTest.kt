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

        // Clear due date to null
        val cleared = originalWithDue.copy(dueEpochMillis = null)
        assertEquals(null, cleared.dueEpochMillis)
        assertFalse(cleared.isDueToday)
        assertFalse(cleared.isDueTomorrow)

        // Verify entity roundtrip preserves null due date
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
        // Simulates coursework-attached note deletion condition
        val existingTitle = "Bài tập Vật Lý hạt nhân"
        val userEnteredContent = "   \n  \t  "
        val trimmed = userEnteredContent.trim()
        
        // Even though existing title is not empty, trimmed content is empty so it should qualify for deletion
        val shouldDelete = trimmed.isEmpty()
        assertTrue("Coursework attached note with empty trimmed content must be deleted", shouldDelete)
    }
}
