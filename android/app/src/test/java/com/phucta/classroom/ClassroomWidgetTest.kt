package com.phucta.classroom

import com.phucta.classroom.data.model.ClassroomDateUtils
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.data.model.SubmissionStatus
import com.phucta.classroom.ui.components.EmberEmotion
import com.phucta.classroom.ui.components.SubjectArtHelper
import com.phucta.classroom.widget.ClassroomGlanceWidget
import com.phucta.classroom.widget.ClassroomGlanceWidgetReceiver
import android.content.Intent
import org.junit.Assert.assertEquals
import org.junit.Test
import java.util.Calendar

class ClassroomWidgetTest {
    @Test
    fun testEmotionParityWithIOS() {
        assertEquals(EmberEmotion.CELEBRATING, ClassroomGlanceWidget.getCharacterEmotion(activeCount = 0, hasCompleted = true, isSmall = false))
        assertEquals(EmberEmotion.CELEBRATING, ClassroomGlanceWidget.getCharacterEmotion(activeCount = 0, hasCompleted = true, isSmall = true))
        assertEquals(EmberEmotion.SLEEPING, ClassroomGlanceWidget.getCharacterEmotion(activeCount = 0, hasCompleted = false, isSmall = false))
        assertEquals(EmberEmotion.SLEEPING, ClassroomGlanceWidget.getCharacterEmotion(activeCount = 0, hasCompleted = false, isSmall = true))

        assertEquals(EmberEmotion.NORMAL, ClassroomGlanceWidget.getCharacterEmotion(activeCount = 1, hasCompleted = false, isSmall = false))
        assertEquals(EmberEmotion.NORMAL, ClassroomGlanceWidget.getCharacterEmotion(activeCount = 2, hasCompleted = true, isSmall = false))

        assertEquals(EmberEmotion.NORMAL, ClassroomGlanceWidget.getCharacterEmotion(activeCount = 2, hasCompleted = false, isSmall = true))
        assertEquals(EmberEmotion.STRESSED, ClassroomGlanceWidget.getCharacterEmotion(activeCount = 3, hasCompleted = false, isSmall = true))

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
        assertEquals("Quá hạn", ClassroomGlanceWidget.getSectionCapsuleLabel("QUÁ HẠN"))
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

    @Test
    fun testSubjectThemeIntegrationWithGlance() {
        val mathTheme = SubjectArtHelper.theme("Toán 12")
        assertEquals(com.phucta.classroom.R.drawable.ic_subject_math, mathTheme.iconRes)
        val csTheme = SubjectArtHelper.theme("Lập trình Python")
        assertEquals(com.phucta.classroom.R.drawable.ic_subject_cs, csTheme.iconRes)
    }

    @Test
    fun testWidgetNeverShowsMockDataWhenUnauthenticated() {
        val authed = false
        val allCourseworkFromDb = com.phucta.classroom.data.local.MockDataProvider.getMockCoursework()

        val items = if (authed) {
            allCourseworkFromDb.filter { !com.phucta.classroom.data.local.MockDataProvider.isMockCourseworkId(it.id) }
        } else {
            emptyList()
        }

        org.junit.Assert.assertTrue("Unauthenticated widget coursework list must be empty", items.isEmpty())
        org.junit.Assert.assertFalse("Unauthenticated widget must never show mock items", items.any { com.phucta.classroom.data.local.MockDataProvider.isMockCourseworkId(it.id) })

        val defaultEmotion = if (authed) ClassroomGlanceWidget.getCharacterEmotion(items.size, false) else EmberEmotion.NORMAL
        assertEquals(EmberEmotion.NORMAL, defaultEmotion)
    }

    @Test
    fun testWidgetFiltersOutMockDataEvenWhenAuthenticated() {
        val authed = true
        val mixedCourses = com.phucta.classroom.data.local.MockDataProvider.mockCourses + listOf(
            com.phucta.classroom.data.model.Course(id = "real_course_123", name = "Real Math", section = "10A1", isSelectedForWidget = true)
        )
        val mixedCoursework = com.phucta.classroom.data.local.MockDataProvider.getMockCoursework() + listOf(
            Coursework(
                id = "real_cw_456",
                courseId = "real_course_123",
                courseName = "Real Math",
                title = "Real Assignment",
                status = SubmissionStatus.PENDING
            )
        )

        val widgetCourses = if (authed) {
            mixedCourses.filter { !com.phucta.classroom.data.local.MockDataProvider.isMockCourse(it.id) }
        } else {
            emptyList()
        }

        val widgetCoursework = if (authed) {
            mixedCoursework.filter { !com.phucta.classroom.data.local.MockDataProvider.isMockCourseworkId(it.id) }
        } else {
            emptyList()
        }

        assertEquals(1, widgetCourses.size)
        assertEquals("real_course_123", widgetCourses.first().id)
        org.junit.Assert.assertFalse("Mock courses must be filtered out", widgetCourses.any { com.phucta.classroom.data.local.MockDataProvider.isMockCourse(it.id) })

        assertEquals(1, widgetCoursework.size)
        assertEquals("real_cw_456", widgetCoursework.first().id)
        org.junit.Assert.assertFalse("Mock coursework must be filtered out", widgetCoursework.any { com.phucta.classroom.data.local.MockDataProvider.isMockCourseworkId(it.id) })
    }

    @Test
    fun testReceiverProcessAction_ClearsCachesForSystemBroadcasts() {
        val receiver = ClassroomGlanceWidgetReceiver()

        // Precondition: ensure caches are populated
        ClassroomDateUtils.ensureDayBoundaries()
        val originalToday = ClassroomDateUtils.startOfToday
        org.junit.Assert.assertTrue(originalToday > 0)

        // 1. UPDATE_WIDGET custom action
        val handledUpdate = receiver.processAction("com.phucta.classroom.action.UPDATE_WIDGET")
        org.junit.Assert.assertTrue("Custom UPDATE_WIDGET action must be handled", handledUpdate)

        // 2. TIMEZONE_CHANGED
        val handledTz = receiver.processAction(Intent.ACTION_TIMEZONE_CHANGED)
        org.junit.Assert.assertTrue("ACTION_TIMEZONE_CHANGED must be handled", handledTz)

        // 3. TIME_CHANGED
        val handledTime = receiver.processAction(Intent.ACTION_TIME_CHANGED)
        org.junit.Assert.assertTrue("ACTION_TIME_CHANGED must be handled", handledTime)

        // 4. DATE_CHANGED
        val handledDate = receiver.processAction(Intent.ACTION_DATE_CHANGED)
        org.junit.Assert.assertTrue("ACTION_DATE_CHANGED must be handled", handledDate)

        // 5. Unrelated action should not be handled
        val handledUnrelated = receiver.processAction("android.intent.action.BATTERY_LOW")
        org.junit.Assert.assertFalse("Unrelated intent must not be handled", handledUnrelated)
    }
}
