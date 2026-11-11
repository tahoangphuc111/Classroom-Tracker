package com.phucta.classroom

import com.phucta.classroom.data.model.ClassroomDateUtils
import com.phucta.classroom.data.model.Course
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.data.model.PersonalNote
import com.phucta.classroom.data.model.SubmissionStatus
import com.phucta.classroom.data.repository.ClassroomRepository
import com.phucta.classroom.domain.BaoBaiBucketingUtils
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class LogicRegressionTest {
    private val hiddenCourse = Course(id = "hidden", name = "Toán", isSelectedForWidget = false)
    private val homework = Coursework(id = "task", courseId = "hidden", courseName = "Toán", title = "Đại số")

    @Test
    fun cachedFallbackMustNotAcknowledgeOrOverwriteLocalCompletion() {
        val checked = homework.copy(status = SubmissionStatus.TURNED_IN, isManuallyCompleted = true)
        val preserved = ClassroomRepository.reconcileCoursework(checked, checked, isRemote = false)
        assertTrue(preserved.isManuallyCompleted)
        val uncheckedWhileSyncing = homework.copy(isManuallyCompleted = false)
        assertEquals(uncheckedWhileSyncing, ClassroomRepository.reconcileCoursework(uncheckedWhileSyncing, checked, isRemote = false))
        val synced = ClassroomRepository.reconcileCoursework(preserved, homework)
        assertTrue(synced.isManuallyCompleted)
        assertEquals(SubmissionStatus.TURNED_IN, synced.status)
    }

    @Test
    fun singleItemSearchStillFiltersNonMatchingHomework() {
        assertTrue(BaoBaiBucketingUtils.sortCoursework(listOf(homework), listOf("english"), "english").isEmpty())
        assertEquals(listOf(homework), BaoBaiBucketingUtils.sortCoursework(listOf(homework), listOf("toan"), "toan"))
    }

    @Test
    fun deselectingAllCoursesHidesTasksButKeepsIndependentNotes() {
        val personal = homework.copy(id = "personal", courseId = "personal_note")
        val filtered = BaoBaiBucketingUtils.filterByActiveCourses(listOf(homework, personal), listOf(hiddenCourse))
        assertEquals(listOf(personal), filtered)
        val buckets = BaoBaiBucketingUtils.computeBuckets(listOf(homework, personal), listOf(hiddenCourse))
        assertEquals(listOf(personal), buckets.noDueDate)
        assertEquals(listOf(personal), buckets.widgetItems)
    }

    @Test
    fun deselectingAllCoursesAlsoHidesTheirTomorrowNotes() {
        val hiddenNote = PersonalNote(title = "Ôn tập", courseId = hiddenCourse.id, dueEpochMillis = ClassroomDateUtils.startOfTomorrow + 3600000)
        val independentNote = hiddenNote.copy(id = "independent", courseId = null)
        val result = BaoBaiBucketingUtils.getTomorrowCoursework(
            items = emptyList(), courses = listOf(hiddenCourse), personalNotes = listOf(hiddenNote, independentNote)
        )
        assertEquals(listOf("note_independent"), result.map { it.id })
    }
}
