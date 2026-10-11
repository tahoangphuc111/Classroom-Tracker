package com.phucta.classroom

import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.data.model.SubmissionStatus
import com.phucta.classroom.ui.components.EmberEmotion
import org.junit.Assert.assertEquals
import org.junit.Test
import java.util.Calendar

class ClassroomWidgetTest {

    private fun getSectionHeaderTitle(items: List<Coursework>): String {
        val pending = items.filter { !it.isCompleted }
        val hasToday = pending.any { it.isDueToday }
        val hasTomorrow = pending.any { it.isDueTomorrow }

        return when {
            hasToday && hasTomorrow -> "HÔM NAY & MAI"
            hasToday -> "HÔM NAY"
            hasTomorrow -> "NGÀY MAI"
            pending.isNotEmpty() -> "SẮP TỚI"
            items.any { it.isDueToday } -> "HÔM NAY"
            else -> "NGÀY MAI"
        }
    }

    private fun getCharacterEmotion(activeCount: Int, hasCompleted: Boolean): EmberEmotion {
        return when {
            activeCount == 0 -> if (hasCompleted) EmberEmotion.CELEBRATING else EmberEmotion.SLEEPING
            activeCount >= 3 -> EmberEmotion.STRESSED
            else -> EmberEmotion.NORMAL
        }
    }

    private fun dueLabel(item: Coursework): String {
        return when {
            item.isCompleted -> "Đã nộp"
            item.isDueToday -> item.timeOnlyString
            item.isDueTomorrow -> if (item.timeOnlyString == "Cuối ngày") "Mai" else "Mai ${item.timeOnlyString}"
            item.dueEpochMillis == null -> "Không hạn"
            else -> item.compactDueString
        }
    }

    @Test
    fun testEmotionParityWithIOS() {
        assertEquals(EmberEmotion.CELEBRATING, getCharacterEmotion(activeCount = 0, hasCompleted = true))

        assertEquals(EmberEmotion.SLEEPING, getCharacterEmotion(activeCount = 0, hasCompleted = false))

        assertEquals(EmberEmotion.NORMAL, getCharacterEmotion(activeCount = 1, hasCompleted = false))
        assertEquals(EmberEmotion.NORMAL, getCharacterEmotion(activeCount = 2, hasCompleted = true))

        assertEquals(EmberEmotion.STRESSED, getCharacterEmotion(activeCount = 3, hasCompleted = false))
        assertEquals(EmberEmotion.STRESSED, getCharacterEmotion(activeCount = 5, hasCompleted = true))
    }

    @Test
    fun testSectionHeaderParityWithIOS() {
        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 14)
            set(Calendar.MINUTE, 0)
        }
        val todayMillis = cal.timeInMillis

        cal.add(Calendar.DAY_OF_YEAR, 1)
        val tomorrowMillis = cal.timeInMillis

        val itemToday = Coursework(
            id = "1", courseId = "c1", courseName = "Toán", title = "Bài 1",
            dueEpochMillis = todayMillis, status = SubmissionStatus.PENDING
        )
        val itemTomorrow = Coursework(
            id = "2", courseId = "c2", courseName = "Văn", title = "Bài 2",
            dueEpochMillis = tomorrowMillis, status = SubmissionStatus.PENDING
        )

        assertEquals("HÔM NAY", getSectionHeaderTitle(listOf(itemToday)))
        assertEquals("NGÀY MAI", getSectionHeaderTitle(listOf(itemTomorrow)))
        assertEquals("HÔM NAY & MAI", getSectionHeaderTitle(listOf(itemToday, itemTomorrow)))
    }

    @Test
    fun testDueLabelFormatting() {
        val completedItem = Coursework(
            id = "1", courseId = "c1", courseName = "Toán", title = "Bài 1",
            status = SubmissionStatus.TURNED_IN
        )
        assertEquals("Đã nộp", dueLabel(completedItem))

        val undatedItem = Coursework(
            id = "2", courseId = "c2", courseName = "Sử", title = "Bài 2",
            dueEpochMillis = null, status = SubmissionStatus.PENDING
        )
        assertEquals("Không hạn", dueLabel(undatedItem))
    }
}
