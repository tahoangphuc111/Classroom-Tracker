package com.phucta.classroom

import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.data.model.SubmissionStatus
import com.phucta.classroom.ui.components.EmberEmotion
import com.phucta.classroom.widget.ClassroomGlanceWidget
import org.junit.Assert.assertEquals
import org.junit.Test
import java.util.Calendar

class ClassroomWidgetTest {

    @Test
    fun testEmotionParityWithIOS() {
        // Zero active items: celebrating if any completed, sleeping if none
        assertEquals(EmberEmotion.CELEBRATING, ClassroomGlanceWidget.getCharacterEmotion(activeCount = 0, hasCompleted = true, isSmall = false))
        assertEquals(EmberEmotion.CELEBRATING, ClassroomGlanceWidget.getCharacterEmotion(activeCount = 0, hasCompleted = true, isSmall = true))
        assertEquals(EmberEmotion.SLEEPING, ClassroomGlanceWidget.getCharacterEmotion(activeCount = 0, hasCompleted = false, isSmall = false))
        assertEquals(EmberEmotion.SLEEPING, ClassroomGlanceWidget.getCharacterEmotion(activeCount = 0, hasCompleted = false, isSmall = true))

        // Normal threshold
        assertEquals(EmberEmotion.NORMAL, ClassroomGlanceWidget.getCharacterEmotion(activeCount = 1, hasCompleted = false, isSmall = false))
        assertEquals(EmberEmotion.NORMAL, ClassroomGlanceWidget.getCharacterEmotion(activeCount = 2, hasCompleted = true, isSmall = false))

        // Small widget stressed threshold is >= 3
        assertEquals(EmberEmotion.NORMAL, ClassroomGlanceWidget.getCharacterEmotion(activeCount = 2, hasCompleted = false, isSmall = true))
        assertEquals(EmberEmotion.STRESSED, ClassroomGlanceWidget.getCharacterEmotion(activeCount = 3, hasCompleted = false, isSmall = true))

        // Medium & Large widget stressed threshold is >= 4
        assertEquals(EmberEmotion.NORMAL, ClassroomGlanceWidget.getCharacterEmotion(activeCount = 3, hasCompleted = false, isSmall = false))
        assertEquals(EmberEmotion.STRESSED, ClassroomGlanceWidget.getCharacterEmotion(activeCount = 4, hasCompleted = false, isSmall = false))
        assertEquals(EmberEmotion.STRESSED, ClassroomGlanceWidget.getCharacterEmotion(activeCount = 5, hasCompleted = true, isSmall = false))
    }

    @Test
    fun testSectionHeaderParityWithIOS() {
        val calToday = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 23)
            set(Calendar.MINUTE, 59)
            set(Calendar.SECOND, 59)
            set(Calendar.MILLISECOND, 999)
        }
        val todayMillis = calToday.timeInMillis

        val calTomorrow = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 23)
            set(Calendar.MINUTE, 59)
            set(Calendar.SECOND, 59)
            set(Calendar.MILLISECOND, 999)
        }
        val tomorrowMillis = calTomorrow.timeInMillis

        val itemToday = Coursework(
            id = "1", courseId = "c1", courseName = "Toán", title = "Bài 1",
            dueEpochMillis = todayMillis, status = SubmissionStatus.PENDING
        )
        val itemTomorrow = Coursework(
            id = "2", courseId = "c2", courseName = "Văn", title = "Bài 2",
            dueEpochMillis = tomorrowMillis, status = SubmissionStatus.PENDING
        )

        assertEquals("HÔM NAY", ClassroomGlanceWidget.getSectionHeaderTitle(listOf(itemToday)))
        assertEquals("NGÀY MAI", ClassroomGlanceWidget.getSectionHeaderTitle(listOf(itemTomorrow)))
        assertEquals("HÔM NAY & MAI", ClassroomGlanceWidget.getSectionHeaderTitle(listOf(itemToday, itemTomorrow)))
    }

    @Test
    fun testSectionCapsuleLabels() {
        assertEquals("Hôm nay & mai", ClassroomGlanceWidget.getSectionCapsuleLabel("HÔM NAY & MAI"))
        assertEquals("Hôm nay", ClassroomGlanceWidget.getSectionCapsuleLabel("HÔM NAY"))
        assertEquals("Sắp tới", ClassroomGlanceWidget.getSectionCapsuleLabel("SẮP TỚI"))
        assertEquals("Ngày mai", ClassroomGlanceWidget.getSectionCapsuleLabel("NGÀY MAI"))
        assertEquals("Ngày mai", ClassroomGlanceWidget.getSectionCapsuleLabel("UNKNOWN"))
    }

    @Test
    fun testDueLabelFormatting() {
        val completedItem = Coursework(
            id = "1", courseId = "c1", courseName = "Toán", title = "Bài 1",
            status = SubmissionStatus.TURNED_IN
        )
        assertEquals("Đã nộp", ClassroomGlanceWidget.dueLabel(completedItem))

        val undatedItem = Coursework(
            id = "2", courseId = "c2", courseName = "Sử", title = "Bài 2",
            dueEpochMillis = null, status = SubmissionStatus.PENDING
        )
        assertEquals("Không hạn", ClassroomGlanceWidget.dueLabel(undatedItem))

        val calTodayEndOfDay = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 23)
            set(Calendar.MINUTE, 59)
            set(Calendar.SECOND, 59)
            set(Calendar.MILLISECOND, 999)
        }
        val itemTodayEndOfDay = Coursework(
            id = "3", courseId = "c1", courseName = "Toán", title = "Bài 3",
            dueEpochMillis = calTodayEndOfDay.timeInMillis, status = SubmissionStatus.PENDING
        )
        assertEquals("Cuối ngày", ClassroomGlanceWidget.dueLabel(itemTodayEndOfDay))

        val calTomorrowEndOfDay = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 23)
            set(Calendar.MINUTE, 59)
            set(Calendar.SECOND, 59)
            set(Calendar.MILLISECOND, 999)
        }
        val itemTomorrowEndOfDay = Coursework(
            id = "4", courseId = "c1", courseName = "Toán", title = "Bài 4",
            dueEpochMillis = calTomorrowEndOfDay.timeInMillis, status = SubmissionStatus.PENDING
        )
        assertEquals("Mai", ClassroomGlanceWidget.dueLabel(itemTomorrowEndOfDay))
    }

    @Test
    fun testFormatDeadlinePill() {
        val calTodayEndOfDay = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 23)
            set(Calendar.MINUTE, 59)
            set(Calendar.SECOND, 59)
            set(Calendar.MILLISECOND, 999)
        }
        val itemTodayEndOfDay = Coursework(
            id = "1", courseId = "c1", courseName = "Toán", title = "Bài 1",
            dueEpochMillis = calTodayEndOfDay.timeInMillis, status = SubmissionStatus.PENDING
        )
        assertEquals("Cuối ngày", ClassroomGlanceWidget.formatDeadlinePill(itemTodayEndOfDay))

        val calTomorrowEndOfDay = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 23)
            set(Calendar.MINUTE, 59)
            set(Calendar.SECOND, 59)
            set(Calendar.MILLISECOND, 999)
        }
        val itemTomorrowEndOfDay = Coursework(
            id = "2", courseId = "c1", courseName = "Toán", title = "Bài 2",
            dueEpochMillis = calTomorrowEndOfDay.timeInMillis, status = SubmissionStatus.PENDING
        )
        assertEquals("Mai", ClassroomGlanceWidget.formatDeadlinePill(itemTomorrowEndOfDay))

        val calToday1430 = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 14)
            set(Calendar.MINUTE, 30)
            set(Calendar.SECOND, 0)
        }
        val itemToday1430 = Coursework(
            id = "3", courseId = "c1", courseName = "Toán", title = "Bài 3",
            dueEpochMillis = calToday1430.timeInMillis, status = SubmissionStatus.PENDING
        )
        assertEquals("14:30", ClassroomGlanceWidget.formatDeadlinePill(itemToday1430))

        val calTomorrow1430 = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 14)
            set(Calendar.MINUTE, 30)
            set(Calendar.SECOND, 0)
        }
        val itemTomorrow1430 = Coursework(
            id = "4", courseId = "c1", courseName = "Toán", title = "Bài 4",
            dueEpochMillis = calTomorrow1430.timeInMillis, status = SubmissionStatus.PENDING
        )
        assertEquals("14:30", ClassroomGlanceWidget.formatDeadlinePill(itemTomorrow1430))
    }
}
