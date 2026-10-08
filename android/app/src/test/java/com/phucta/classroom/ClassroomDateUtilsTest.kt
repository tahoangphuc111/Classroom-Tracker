package com.phucta.classroom

import com.phucta.classroom.data.model.ClassroomDateUtils
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar

class ClassroomDateUtilsTest {

    @Test
    fun testEndOfDayFormatting() {
        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 23)
            set(Calendar.MINUTE, 57)
        }
        val label = ClassroomDateUtils.buildTimeOnlyString(cal.timeInMillis)
        assertEquals("Cuối ngày", label)

        cal.set(Calendar.HOUR_OF_DAY, 23)
        cal.set(Calendar.MINUTE, 55)
        assertEquals("Cuối ngày", ClassroomDateUtils.buildTimeOnlyString(cal.timeInMillis))

        cal.set(Calendar.HOUR_OF_DAY, 14)
        cal.set(Calendar.MINUTE, 30)
        assertEquals("14:30", ClassroomDateUtils.buildTimeOnlyString(cal.timeInMillis))
    }

    @Test
    fun testParseGoogleDueDateTime_NullTime_DefaultsToLocalEndOfDay() {
        val epoch = ClassroomDateUtils.parseGoogleDueDateTime(
            year = 2026,
            month = 10,
            day = 15,
            hours = null,
            minutes = null,
            seconds = null
        )
        assertNotNull(epoch)

        val cal = Calendar.getInstance().apply { timeInMillis = epoch!! }
        assertEquals(2026, cal.get(Calendar.YEAR))
        assertEquals(9, cal.get(Calendar.MONTH)) // 0-indexed in Calendar
        assertEquals(15, cal.get(Calendar.DAY_OF_MONTH))
        assertEquals(23, cal.get(Calendar.HOUR_OF_DAY))
        assertEquals(59, cal.get(Calendar.MINUTE))
        assertEquals(59, cal.get(Calendar.SECOND))
    }

    @Test
    fun testParseGoogleDueDateTime_ZeroHourUTC_DoesNotDefaultToEndOfDay() {
        val epoch = ClassroomDateUtils.parseGoogleDueDateTime(
            year = 2026,
            month = 10,
            day = 15,
            hours = null,
            minutes = 30,
            seconds = 0,
            hasDueTime = true
        )
        assertNotNull(epoch)

        val calUtc = Calendar.getInstance(java.util.TimeZone.getTimeZone("UTC")).apply { timeInMillis = epoch!! }
        assertEquals(2026, calUtc.get(Calendar.YEAR))
        assertEquals(9, calUtc.get(Calendar.MONTH))
        assertEquals(15, calUtc.get(Calendar.DAY_OF_MONTH))
        assertEquals(0, calUtc.get(Calendar.HOUR_OF_DAY))
        assertEquals(30, calUtc.get(Calendar.MINUTE))
    }

    @Test
    fun testCompactDueString() {
        assertEquals("Không hạn", ClassroomDateUtils.compactDueString(null, isCompleted = false))
        assertEquals("Đã nộp", ClassroomDateUtils.compactDueString(System.currentTimeMillis(), isCompleted = true))

        val calOverdue = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, -2) }
        assertEquals("Quá hạn", ClassroomDateUtils.compactDueString(calOverdue.timeInMillis, isCompleted = false))
    }

    @Test
    fun testCountdownBadge_Completed() {
        val cal = Calendar.getInstance().apply { add(Calendar.HOUR_OF_DAY, 2) }
        val badge = ClassroomDateUtils.countdownBadgeString(cal.timeInMillis, isCompleted = true)
        assertEquals("Đã hoàn thành", badge)
    }

    @Test
    fun testCountdownBadge_Overdue() {
        val cal = Calendar.getInstance().apply { add(Calendar.HOUR_OF_DAY, -2) }
        val badge = ClassroomDateUtils.countdownBadgeString(cal.timeInMillis, isCompleted = false)
        assertTrue(badge.startsWith("Quá hạn"))
    }
}
