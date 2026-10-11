package com.phucta.classroom

import com.phucta.classroom.data.local.PersonalNoteEntity
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.data.model.PersonalNote
import com.phucta.classroom.data.model.SubmissionStatus
import com.phucta.classroom.domain.BaoBaiBucketingUtils
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
}
