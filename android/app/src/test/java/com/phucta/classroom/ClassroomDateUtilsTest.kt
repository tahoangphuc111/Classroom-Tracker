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
        assertEquals(9, cal.get(Calendar.MONTH))
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
        val nowMillis = System.currentTimeMillis()
        if (calToday1430.timeInMillis > nowMillis) {
            assertEquals("14:30", ClassroomDateUtils.compactDueString(calToday1430.timeInMillis, isCompleted = false))
        }

        val calTodayOverdue = Calendar.getInstance().apply { add(Calendar.MINUTE, -15) }
        assertEquals("Quá hạn", ClassroomDateUtils.compactDueString(calTodayOverdue.timeInMillis, isCompleted = false))

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
            val epoch = 1700000000000L

            java.util.TimeZone.setDefault(java.util.TimeZone.getTimeZone("UTC"))
            val utcFormatted = ClassroomDateUtils.buildTimeOnlyString(epoch)
            assertEquals("22:13", utcFormatted)

            java.util.TimeZone.setDefault(java.util.TimeZone.getTimeZone("Asia/Ho_Chi_Minh"))
            val vnFormatted = ClassroomDateUtils.buildTimeOnlyString(epoch)
            assertEquals("05:13", vnFormatted)

            java.util.TimeZone.setDefault(java.util.TimeZone.getTimeZone("Asia/Tokyo"))
            val tokyoFormatted = ClassroomDateUtils.buildTimeOnlyString(epoch)
            assertEquals("07:13", tokyoFormatted)
        } finally {
            java.util.TimeZone.setDefault(originalTz)
        }
    }

    @Test
    fun testParseGoogleDueDateTime_HasDueTimeTrue_NullComponents_DefaultsToMidnightUtc() {
        val epoch = ClassroomDateUtils.parseGoogleDueDateTime(
            year = 2026,
            month = 10,
            day = 15,
            hours = null,
            minutes = null,
            seconds = null,
            hasDueTime = true
        )
        assertNotNull(epoch)

        val calUtc = Calendar.getInstance(java.util.TimeZone.getTimeZone("UTC"), java.util.Locale.US).apply {
            timeInMillis = epoch!!
        }
        assertEquals(2026, calUtc.get(Calendar.YEAR))
        assertEquals(Calendar.OCTOBER, calUtc.get(Calendar.MONTH))
        assertEquals(15, calUtc.get(Calendar.DAY_OF_MONTH))
        assertEquals(0, calUtc.get(Calendar.HOUR_OF_DAY))
        assertEquals(0, calUtc.get(Calendar.MINUTE))
        assertEquals(0, calUtc.get(Calendar.SECOND))
        assertEquals(0, calUtc.get(Calendar.MILLISECOND))
    }

    @Test
    fun testEnsureDayBoundaries_ClockAdjustmentBackward_ResetsBoundaries() {
        try {
            val now = System.currentTimeMillis()
            val futureTime = now + 5 * 86_400_000L

            ClassroomDateUtils.ensureDayBoundaries(futureTime)

            val currentStartOfToday = ClassroomDateUtils.startOfToday

            val cal = Calendar.getInstance(java.util.TimeZone.getDefault(), java.util.Locale.US).apply {
                timeInMillis = now
                set(Calendar.HOUR_OF_DAY, 0)
                set(Calendar.MINUTE, 0)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            assertEquals("startOfToday must reset to current day after clock rollback", cal.timeInMillis, currentStartOfToday)
        } finally {
            ClassroomDateUtils.ensureDayBoundaries(System.currentTimeMillis())
        }
    }

    @Test
    fun testParseGoogleDueDateTime_VietnamTimezone_DueTimeNull_ResolvesTo235959Local() {
        val originalTz = java.util.TimeZone.getDefault()
        try {
            val vietnamTz = java.util.TimeZone.getTimeZone("Asia/Ho_Chi_Minh")
            java.util.TimeZone.setDefault(vietnamTz)

            val epoch = ClassroomDateUtils.parseGoogleDueDateTime(
                year = 2026,
                month = 10,
                day = 25,
                hours = null,
                minutes = null,
                seconds = null,
                hasDueTime = false
            )
            assertNotNull(epoch)

            val calUtc = Calendar.getInstance(java.util.TimeZone.getTimeZone("UTC"), java.util.Locale.US).apply {
                timeInMillis = epoch!!
            }
            assertEquals(16, calUtc.get(Calendar.HOUR_OF_DAY))
            assertEquals(59, calUtc.get(Calendar.MINUTE))
            assertEquals(59, calUtc.get(Calendar.SECOND))

            val calLocal = Calendar.getInstance(vietnamTz, java.util.Locale.US).apply {
                timeInMillis = epoch!!
            }
            assertEquals(2026, calLocal.get(Calendar.YEAR))
            assertEquals(Calendar.OCTOBER, calLocal.get(Calendar.MONTH))
            assertEquals(25, calLocal.get(Calendar.DAY_OF_MONTH))
            assertEquals(23, calLocal.get(Calendar.HOUR_OF_DAY))
            assertEquals(59, calLocal.get(Calendar.MINUTE))
            assertEquals(59, calLocal.get(Calendar.SECOND))
            assertEquals(999, calLocal.get(Calendar.MILLISECOND))

            val label = ClassroomDateUtils.buildTimeOnlyString(epoch)
            assertEquals("Cuối ngày", label)
        } finally {
            java.util.TimeZone.setDefault(originalTz)
        }
    }

    @Test
    fun testEndOfDayBoundary_2355_Threshold() {
        val cal = Calendar.getInstance()

        cal.set(Calendar.HOUR_OF_DAY, 23)
        cal.set(Calendar.MINUTE, 54)
        cal.set(Calendar.SECOND, 59)
        assertEquals("23:54", ClassroomDateUtils.buildTimeOnlyString(cal.timeInMillis))

        cal.set(Calendar.HOUR_OF_DAY, 23)
        cal.set(Calendar.MINUTE, 55)
        cal.set(Calendar.SECOND, 0)
        assertEquals("Cuối ngày", ClassroomDateUtils.buildTimeOnlyString(cal.timeInMillis))

        cal.set(Calendar.HOUR_OF_DAY, 23)
        cal.set(Calendar.MINUTE, 56)
        assertEquals("Cuối ngày", ClassroomDateUtils.buildTimeOnlyString(cal.timeInMillis))

        cal.set(Calendar.HOUR_OF_DAY, 23)
        cal.set(Calendar.MINUTE, 58)
        assertEquals("Cuối ngày", ClassroomDateUtils.buildTimeOnlyString(cal.timeInMillis))

        cal.set(Calendar.HOUR_OF_DAY, 23)
        cal.set(Calendar.MINUTE, 59)
        assertEquals("Cuối ngày", ClassroomDateUtils.buildTimeOnlyString(cal.timeInMillis))
    }

    @Test
    fun testPastDueCoursework_AlwaysTreatedAsCompletedAccordingToAppBusinessRules() {
        val now = System.currentTimeMillis()
        val pastDueTask = com.phucta.classroom.data.model.Coursework(
            id = "cw_past_due_rule",
            courseId = "c1",
            courseName = "Hóa học",
            title = "Bài tập hóa vô cơ",
            dueEpochMillis = now - 60_000L,
            status = com.phucta.classroom.data.model.SubmissionStatus.PENDING,
            isManuallyCompleted = false
        )

        assertTrue("Past due coursework must evaluate isCompleted == true", pastDueTask.isCompleted)
        org.junit.Assert.assertFalse("isOverdue helper property on Coursework model must be false", pastDueTask.isOverdue)

        val tomorrowItems = com.phucta.classroom.domain.BaoBaiBucketingUtils.getTomorrowCoursework(
            items = listOf(pastDueTask),
            includeCompleted = false
        )
        assertTrue("Past due coursework must be excluded from pending tomorrow batch", tomorrowItems.isEmpty())

        val buckets = com.phucta.classroom.domain.BaoBaiBucketingUtils.computeBuckets(listOf(pastDueTask))
        assertEquals("overdue bucket must be empty", 0, buckets.overdue.size)
        assertEquals("completed bucket must contain the expired task", 1, buckets.completed.size)
        assertEquals("cw_past_due_rule", buckets.completed.first().id)
    }

    @Test
    fun testTimezoneChange_InvalidatesDayBoundaries() {
        val originalTz = java.util.TimeZone.getDefault()
        try {
            java.util.TimeZone.setDefault(java.util.TimeZone.getTimeZone("Asia/Ho_Chi_Minh")) // UTC+7
            ClassroomDateUtils.ensureDayBoundaries()
            val startOfTodayVn = ClassroomDateUtils.startOfToday

            java.util.TimeZone.setDefault(java.util.TimeZone.getTimeZone("Asia/Tokyo")) // UTC+9
            ClassroomDateUtils.ensureDayBoundaries()
            val startOfTodayTokyo = ClassroomDateUtils.startOfToday

            // Tokyo is 2 hours ahead of VN, so startOfToday in Tokyo is 2 hours earlier in epoch millis
            assertEquals(2 * 3600 * 1000L, startOfTodayVn - startOfTodayTokyo)
        } finally {
            java.util.TimeZone.setDefault(originalTz)
            ClassroomDateUtils.ensureDayBoundaries()
        }
    }
}
