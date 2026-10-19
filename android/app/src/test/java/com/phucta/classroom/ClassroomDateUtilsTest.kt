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

        val calTodayEndOfDay = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 23)
            set(Calendar.MINUTE, 59)
            set(Calendar.SECOND, 59)
            set(Calendar.MILLISECOND, 999)
        }
        assertEquals("Cuối ngày", ClassroomDateUtils.compactDueString(calTodayEndOfDay.timeInMillis, isCompleted = false))

        val calToday2355 = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 23)
            set(Calendar.MINUTE, 55)
            set(Calendar.SECOND, 0)
        }
        assertEquals("Cuối ngày", ClassroomDateUtils.compactDueString(calToday2355.timeInMillis, isCompleted = false))

        val calTomorrowEndOfDay = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 23)
            set(Calendar.MINUTE, 59)
            set(Calendar.SECOND, 59)
            set(Calendar.MILLISECOND, 999)
        }
        assertEquals("Mai", ClassroomDateUtils.compactDueString(calTomorrowEndOfDay.timeInMillis, isCompleted = false))

        val calTomorrow2355 = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 23)
            set(Calendar.MINUTE, 55)
            set(Calendar.SECOND, 0)
        }
        assertEquals("Mai", ClassroomDateUtils.compactDueString(calTomorrow2355.timeInMillis, isCompleted = false))

        val calToday1430 = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 14)
            set(Calendar.MINUTE, 30)
            set(Calendar.SECOND, 0)
        }
        assertEquals("14:30", ClassroomDateUtils.compactDueString(calToday1430.timeInMillis, isCompleted = false))

        val calTomorrow1430 = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 14)
            set(Calendar.MINUTE, 30)
            set(Calendar.SECOND, 0)
        }
        assertEquals("Mai 14:30", ClassroomDateUtils.compactDueString(calTomorrow1430.timeInMillis, isCompleted = false))
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

    @Test
    fun testLeapYearParsing_Feb29() {
        val epoch = ClassroomDateUtils.parseGoogleDueDateTime(
            year = 2024,
            month = 2,
            day = 29,
            hours = null,
            minutes = null,
            seconds = null
        )
        assertNotNull(epoch)
        val cal = Calendar.getInstance().apply { timeInMillis = epoch!! }
        assertEquals(2024, cal.get(Calendar.YEAR))
        assertEquals(Calendar.FEBRUARY, cal.get(Calendar.MONTH))
        assertEquals(29, cal.get(Calendar.DAY_OF_MONTH))
        assertEquals(23, cal.get(Calendar.HOUR_OF_DAY))
        assertEquals(59, cal.get(Calendar.MINUTE))
        assertEquals(59, cal.get(Calendar.SECOND))
        assertEquals(999, cal.get(Calendar.MILLISECOND))
    }

    @Test
    fun testYearBoundaryParsing_Dec31() {
        val epoch = ClassroomDateUtils.parseGoogleDueDateTime(
            year = 2026,
            month = 12,
            day = 31,
            hours = null,
            minutes = null,
            seconds = null
        )
        assertNotNull(epoch)
        val cal = Calendar.getInstance().apply { timeInMillis = epoch!! }
        assertEquals(2026, cal.get(Calendar.YEAR))
        assertEquals(Calendar.DECEMBER, cal.get(Calendar.MONTH))
        assertEquals(31, cal.get(Calendar.DAY_OF_MONTH))
        assertEquals(23, cal.get(Calendar.HOUR_OF_DAY))
        assertEquals(59, cal.get(Calendar.MINUTE))
        assertEquals(59, cal.get(Calendar.SECOND))
        assertEquals(999, cal.get(Calendar.MILLISECOND))
    }

    @Test
    fun testMidnightBoundaryTransitions() {
        val calTodayEndOfDay = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 23)
            set(Calendar.MINUTE, 59)
            set(Calendar.SECOND, 59)
            set(Calendar.MILLISECOND, 999)
        }
        assertTrue("23:59:59.999 today should be due today", ClassroomDateUtils.isDueToday(calTodayEndOfDay.timeInMillis))
        org.junit.Assert.assertFalse("23:59:59.999 today should not be due tomorrow", ClassroomDateUtils.isDueTomorrow(calTodayEndOfDay.timeInMillis))

        val calTomorrowStartOfDay = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        org.junit.Assert.assertFalse("00:00:00.000 tomorrow should not be due today", ClassroomDateUtils.isDueToday(calTomorrowStartOfDay.timeInMillis))
        assertTrue("00:00:00.000 tomorrow should be due tomorrow", ClassroomDateUtils.isDueTomorrow(calTomorrowStartOfDay.timeInMillis))

        assertEquals("Cuối ngày", ClassroomDateUtils.buildTimeOnlyString(calTodayEndOfDay.timeInMillis))
        assertEquals("00:00", ClassroomDateUtils.buildTimeOnlyString(calTomorrowStartOfDay.timeInMillis))
    }

    @Test
    fun testTimezoneReactivity_FormattersAdoptNewDefaultTimezone() {
        val originalTz = java.util.TimeZone.getDefault()
        try {
            // Fix a specific UTC instant: 1700000000000L = 2023-11-14 22:13:20 UTC
            val epoch = 1700000000000L

            java.util.TimeZone.setDefault(java.util.TimeZone.getTimeZone("UTC"))
            val utcFormatted = ClassroomDateUtils.buildTimeOnlyString(epoch)
            assertEquals("22:13", utcFormatted)

            // Switch to Asia/Bangkok / Vietnam (UTC+7) -> 05:13 next day
            java.util.TimeZone.setDefault(java.util.TimeZone.getTimeZone("Asia/Ho_Chi_Minh"))
            val vnFormatted = ClassroomDateUtils.buildTimeOnlyString(epoch)
            assertEquals("05:13", vnFormatted)

            // Switch to Tokyo (UTC+9) -> 07:13 next day
            java.util.TimeZone.setDefault(java.util.TimeZone.getTimeZone("Asia/Tokyo"))
            val tokyoFormatted = ClassroomDateUtils.buildTimeOnlyString(epoch)
            assertEquals("07:13", tokyoFormatted)
        } finally {
            java.util.TimeZone.setDefault(originalTz)
        }
    }
}
