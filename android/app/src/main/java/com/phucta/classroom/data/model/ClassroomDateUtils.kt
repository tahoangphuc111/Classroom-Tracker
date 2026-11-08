package com.phucta.classroom.data.model

import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.TimeZone
import kotlin.math.abs
import kotlin.math.max

object ClassroomDateUtils {
    val VIETNAMESE_LOCALE = Locale("vi", "VN")

    private val dayAndDateFormatPool = object : ThreadLocal<SimpleDateFormat>() {
        override fun initialValue(): SimpleDateFormat {
            return SimpleDateFormat("E, d/M", VIETNAMESE_LOCALE).apply {
                timeZone = TimeZone.getDefault()
            }
        }
    }
    private val fullDueDateFormatPool = object : ThreadLocal<SimpleDateFormat>() {
        override fun initialValue(): SimpleDateFormat {
            return SimpleDateFormat("EEEE, 'ngày' d 'tháng' M, yyyy 'lúc' HH:mm", VIETNAMESE_LOCALE).apply {
                timeZone = TimeZone.getDefault()
            }
        }
    }

    @Volatile
    private var cachedStartOfToday: Long = 0L
    @Volatile
    private var cachedStartOfTomorrow: Long = 0L
    @Volatile
    private var cachedStartOfDayAfter: Long = 0L
    @Volatile
    private var cacheExpirationTime: Long = 0L
    @Volatile
    private var cachedTimeZone: TimeZone? = null
    @Volatile
    private var cachedTimeZoneId: String = ""

    private class FastLongStringCache(capacity: Int = 2048) {
        private val mask = capacity - 1
        private val keys = LongArray(capacity) { Long.MIN_VALUE }
        private val values = arrayOfNulls<String>(capacity)

        @Synchronized
        operator fun get(key: Long): String? {
            val idx = (key xor (key ushr 32)).toInt() and mask
            return if (keys[idx] == key) values[idx] else null
        }

        @Synchronized
        operator fun set(key: Long, value: String) {
            val idx = (key xor (key ushr 32)).toInt() and mask
            keys[idx] = key
            values[idx] = value
        }

        @Synchronized
        fun clear() {
            keys.fill(Long.MIN_VALUE)
            values.fill(null)
        }
    }

    private val timeOnlyCache = FastLongStringCache(capacity = 2048)
    private val fullDueDateCache = FastLongStringCache(capacity = 1024)
    private val conciseDueDateCache = FastLongStringCache(capacity = 1024)
    private val shortDateCache = FastLongStringCache(capacity = 2048)
    private val dayAndDateCache = FastLongStringCache(capacity = 2048)

    private val calendarPool = object : ThreadLocal<Calendar>() {
        override fun initialValue(): Calendar {
            return Calendar.getInstance(TimeZone.getDefault(), Locale.US)
        }
    }

    fun createLocalCalendar(timeInMillis: Long? = null): Calendar {
        val cal = Calendar.getInstance(TimeZone.getDefault(), Locale.US)
        if (timeInMillis != null) {
            cal.timeInMillis = timeInMillis
        }
        return cal
    }

    private val utcCalendarPool = object : ThreadLocal<Calendar>() {
        override fun initialValue(): Calendar {
            return Calendar.getInstance(TimeZone.getTimeZone("UTC"), Locale.US)
        }
    }

    private fun checkTimeZone() {
        val currentTz = TimeZone.getDefault()
        if (currentTz !== cachedTimeZone) {
            val currentTzId = currentTz.id
            if (currentTzId != cachedTimeZoneId) {
                synchronized(this) {
                    if (currentTzId != cachedTimeZoneId) {
                        cachedTimeZone = currentTz
                        cachedTimeZoneId = currentTzId
                        timeOnlyCache.clear()
                        fullDueDateCache.clear()
                        conciseDueDateCache.clear()
                        shortDateCache.clear()
                        dayAndDateCache.clear()
                        cachedStartOfToday = 0L
                        cachedStartOfTomorrow = 0L
                        cachedStartOfDayAfter = 0L
                        cacheExpirationTime = 0L
                    }
                }
            } else {
                cachedTimeZone = currentTz
            }
        }
    }

    fun clearCaches() {
        synchronized(this) {
            timeOnlyCache.clear()
            fullDueDateCache.clear()
            conciseDueDateCache.clear()
            shortDateCache.clear()
            dayAndDateCache.clear()
            cachedStartOfToday = 0L
            cachedStartOfTomorrow = 0L
            cachedStartOfDayAfter = 0L
            cacheExpirationTime = 0L
            cachedTimeZone = null
            cachedTimeZoneId = ""
        }
    }

    fun ensureDayBoundaries(now: Long = System.currentTimeMillis()) {
        checkTimeZone()
        if (now < cachedStartOfToday || now >= cacheExpirationTime || cachedStartOfToday == 0L) {
            synchronized(this) {
                if (now < cachedStartOfToday || now >= cacheExpirationTime || cachedStartOfToday == 0L) {
                    val cal = (calendarPool.get() ?: Calendar.getInstance(TimeZone.getDefault(), Locale.US)).apply {
                        timeZone = TimeZone.getDefault()
                        timeInMillis = now
                        set(Calendar.HOUR_OF_DAY, 0)
                        set(Calendar.MINUTE, 0)
                        set(Calendar.SECOND, 0)
                        set(Calendar.MILLISECOND, 0)
                    }
                    val today = cal.timeInMillis
                    cal.add(Calendar.DAY_OF_YEAR, 1)
                    val tomorrow = cal.timeInMillis
                    cal.add(Calendar.DAY_OF_YEAR, 1)
                    val dayAfter = cal.timeInMillis

                    cachedStartOfToday = today
                    cachedStartOfTomorrow = tomorrow
                    cachedStartOfDayAfter = dayAfter
                    cacheExpirationTime = minOf(tomorrow, now + 60_000L)
                }
            }
        }
    }

    val startOfToday: Long
        get() {
            ensureDayBoundaries()
            return cachedStartOfToday
        }

    val startOfTomorrow: Long
        get() {
            ensureDayBoundaries()
            return cachedStartOfTomorrow
        }

    val startOfDayAfter: Long
        get() {
            ensureDayBoundaries()
            return cachedStartOfDayAfter
        }

    fun formatShortDate(dueEpochMillis: Long?): String {
        if (dueEpochMillis == null) return "--/--"
        checkTimeZone()
        val cached = shortDateCache[dueEpochMillis]
        if (cached != null) return cached

        val cal = (calendarPool.get() ?: Calendar.getInstance(TimeZone.getDefault(), Locale.US)).apply {
            timeZone = TimeZone.getDefault()
            timeInMillis = dueEpochMillis
        }
        val day = cal.get(Calendar.DAY_OF_MONTH)
        val month = cal.get(Calendar.MONTH) + 1
        val formatted = "$day/$month"
        shortDateCache[dueEpochMillis] = formatted
        return formatted
    }

    fun formatDayAndDate(dueEpochMillis: Long): String {
        checkTimeZone()
        val cached = dayAndDateCache[dueEpochMillis]
        if (cached != null) return cached

        val format = dayAndDateFormatPool.get() ?: SimpleDateFormat("E, d/M", VIETNAMESE_LOCALE)
        format.timeZone = TimeZone.getDefault()
        val formatted = format.format(Date(dueEpochMillis))
        dayAndDateCache[dueEpochMillis] = formatted
        return formatted
    }

    fun buildTimeOnlyString(dueEpochMillis: Long?): String {
        if (dueEpochMillis == null) return "--:--"
        checkTimeZone()
        val cached = timeOnlyCache[dueEpochMillis]
        if (cached != null) return cached

        val cal = (calendarPool.get() ?: Calendar.getInstance(TimeZone.getDefault(), Locale.US)).apply {
            timeZone = TimeZone.getDefault()
            timeInMillis = dueEpochMillis
        }
        val hour = cal.get(Calendar.HOUR_OF_DAY)
        val minute = cal.get(Calendar.MINUTE)
        val result = if (hour == 23 && minute >= 55) {
            "Cuối ngày"
        } else {
            val h1 = ((hour / 10) + 48).toChar()
            val h2 = ((hour % 10) + 48).toChar()
            val m1 = ((minute / 10) + 48).toChar()
            val m2 = ((minute % 10) + 48).toChar()
            String(charArrayOf(h1, h2, ':', m1, m2))
        }
        timeOnlyCache[dueEpochMillis] = result
        return result
    }

    fun buildFormattedFullDueDate(dueEpochMillis: Long?): String {
        if (dueEpochMillis == null) return "Không có hạn nộp"
        checkTimeZone()
        val cached = fullDueDateCache[dueEpochMillis]
        if (cached != null) return cached

        val format = fullDueDateFormatPool.get() ?: SimpleDateFormat("EEEE, 'ngày' d 'tháng' M, yyyy 'lúc' HH:mm", VIETNAMESE_LOCALE)
        format.timeZone = TimeZone.getDefault()
        val formatted = format.format(Date(dueEpochMillis))
        val result = formatted.replaceFirstChar { if (it.isLowerCase()) it.titlecase(VIETNAMESE_LOCALE) else it.toString() }
        fullDueDateCache[dueEpochMillis] = result
        return result
    }

    fun buildConciseDueString(dueEpochMillis: Long?): String {
        if (dueEpochMillis == null) return "Không có hạn"
        checkTimeZone()
        val cached = conciseDueDateCache[dueEpochMillis]
        if (cached != null) return cached

        val cal = (calendarPool.get() ?: Calendar.getInstance(TimeZone.getDefault(), Locale.US)).apply {
            timeInMillis = dueEpochMillis
        }
        val hour = cal.get(Calendar.HOUR_OF_DAY)
        val minute = cal.get(Calendar.MINUTE)
        val timeStr = String.format(Locale.US, "%02d:%02d", hour, minute)
        val dayOfWeekStr = when (cal.get(Calendar.DAY_OF_WEEK)) {
            Calendar.MONDAY -> "T2"
            Calendar.TUESDAY -> "T3"
            Calendar.WEDNESDAY -> "T4"
            Calendar.THURSDAY -> "T5"
            Calendar.FRIDAY -> "T6"
            Calendar.SATURDAY -> "T7"
            Calendar.SUNDAY -> "CN"
            else -> ""
        }
        val day = cal.get(Calendar.DAY_OF_MONTH)
        val month = cal.get(Calendar.MONTH) + 1
        val year = cal.get(Calendar.YEAR)

        val nowCal = (calendarPool.get() ?: Calendar.getInstance(TimeZone.getDefault(), Locale.US)).apply {
            timeInMillis = System.currentTimeMillis()
        }
        val currentYear = nowCal.get(Calendar.YEAR)

        val result = if (year != currentYear) {
            "$timeStr • $dayOfWeekStr, $day/$month/$year"
        } else {
            "$timeStr • $dayOfWeekStr, $day/$month"
        }
        conciseDueDateCache[dueEpochMillis] = result
        return result
    }

    fun isDueToday(dueEpochMillis: Long?): Boolean {
        if (dueEpochMillis == null) return false
        ensureDayBoundaries()
        return dueEpochMillis in cachedStartOfToday until cachedStartOfTomorrow
    }

    fun isDueTomorrow(dueEpochMillis: Long?): Boolean {
        if (dueEpochMillis == null) return false
        ensureDayBoundaries()
        return dueEpochMillis in cachedStartOfTomorrow until cachedStartOfDayAfter
    }

    fun isOverdue(dueEpochMillis: Long?, isCompleted: Boolean): Boolean {
        if (dueEpochMillis == null || isCompleted) return false
        return dueEpochMillis < System.currentTimeMillis()
    }

    fun isPast(dueEpochMillis: Long?): Boolean {
        if (dueEpochMillis == null) return false
        ensureDayBoundaries()
        return dueEpochMillis < cachedStartOfToday
    }

    fun friendlyDueString(dueEpochMillis: Long?, isCompleted: Boolean): String {
        if (dueEpochMillis == null) return "Không có hạn"
        ensureDayBoundaries()
        val startToday = cachedStartOfToday
        val startTomorrow = cachedStartOfTomorrow
        val startDayAfter = cachedStartOfDayAfter

        val time = buildTimeOnlyString(dueEpochMillis)
        val isEndOfDay = (time == "Cuối ngày")
        val now = System.currentTimeMillis()
        val overdue = !isCompleted && dueEpochMillis < now
        val today = dueEpochMillis in startToday until startTomorrow
        val tomorrow = dueEpochMillis in startTomorrow until startDayAfter
        val past = dueEpochMillis < startToday

        return when {
            overdue -> {
                if (today) {
                    if (isEndOfDay) "Quá hạn (hôm nay)" else "Quá hạn ($time)"
                } else {
                    val dayStr = formatShortDate(dueEpochMillis)
                    "Quá hạn ($dayStr)"
                }
            }
            today -> {
                if (isEndOfDay) "Hết hôm nay" else "Hôm nay, $time"
            }
            tomorrow -> {
                if (isEndOfDay) "Hết ngày mai" else "Ngày mai, $time"
            }
            past -> {
                val dayStr = formatShortDate(dueEpochMillis)
                "Đã qua ($dayStr)"
            }
            else -> {
                val dayStr = formatDayAndDate(dueEpochMillis)
                if (isEndOfDay) "$dayStr (hết ngày)" else "$dayStr, $time"
            }
        }
    }

    fun countdownBadgeString(dueEpochMillis: Long?, isCompleted: Boolean): String {
        if (dueEpochMillis == null) return "Không có hạn"
        if (isCompleted) return "Đã hoàn thành"

        val now = System.currentTimeMillis()
        val interval = dueEpochMillis - now

        return if (interval < 0) {
            val absSecs = abs(interval) / 1000
            when {
                absSecs < 3600 -> {
                    val mins = max(1, (absSecs / 60).toInt())
                    "Quá hạn $mins phút"
                }
                absSecs < 86400 -> {
                    val hours = (absSecs / 3600).toInt()
                    "Quá hạn $hours giờ"
                }
                else -> {
                    val days = max(1, (absSecs / 86400).toInt())
                    "Quá hạn $days ngày"
                }
            }
        } else {
            val secs = interval / 1000
            when {
                secs < 3600 -> {
                    val mins = max(1, (secs / 60).toInt())
                    "Còn $mins phút"
                }
                secs < 86400 -> {
                    val hours = (secs / 3600).toInt()
                    val mins = ((secs % 3600) / 60).toInt()
                    if (mins > 0) "Còn ${hours}g ${mins}p" else "Còn $hours giờ"
                }
                isDueToday(dueEpochMillis) || isDueTomorrow(dueEpochMillis) -> {
                    friendlyDueString(dueEpochMillis, isCompleted)
                }
                else -> {
                    friendlyDueString(dueEpochMillis, isCompleted)
                }
            }
        }
    }

    fun compactDueString(
        dueEpochMillis: Long?,
        isCompleted: Boolean,
        precomputedTimeOnly: String? = null
    ): String {
        if (dueEpochMillis == null) return "Không hạn"
        if (isCompleted) return "Đã nộp"
        ensureDayBoundaries()
        val startToday = cachedStartOfToday
        val startTomorrow = cachedStartOfTomorrow
        val startDayAfter = cachedStartOfDayAfter

        val time = precomputedTimeOnly ?: buildTimeOnlyString(dueEpochMillis)
        val isEndOfDay = (time == "Cuối ngày")
        val now = System.currentTimeMillis()
        val today = dueEpochMillis in startToday until startTomorrow
        val tomorrow = dueEpochMillis in startTomorrow until startDayAfter
        val overdue = dueEpochMillis < now
        val past = dueEpochMillis < startToday

        return when {
            overdue -> "Quá hạn"
            today -> if (isEndOfDay) "Cuối ngày" else time
            tomorrow -> if (isEndOfDay) "Mai" else "Mai $time"
            past -> "Đã qua"
            else -> {
                val dayStr = formatShortDate(dueEpochMillis)
                if (isEndOfDay) dayStr else "$dayStr $time"
            }
        }
    }

    fun parseGoogleDueDateTime(
        year: Int?,
        month: Int?,
        day: Int?,
        hours: Int?,
        minutes: Int?,
        seconds: Int?,
        hasDueTime: Boolean = (hours != null || minutes != null || seconds != null)
    ): Long? {
        if (year == null || month == null || day == null) return null
        return if (hasDueTime) {
            val utcCal = (utcCalendarPool.get() ?: Calendar.getInstance(TimeZone.getTimeZone("UTC"), Locale.US)).apply {
                clear()
                set(Calendar.YEAR, year)
                set(Calendar.MONTH, month - 1)
                set(Calendar.DAY_OF_MONTH, day)
                set(Calendar.HOUR_OF_DAY, hours ?: 0)
                set(Calendar.MINUTE, minutes ?: 0)
                set(Calendar.SECOND, seconds ?: 0)
                set(Calendar.MILLISECOND, 0)
            }
            utcCal.timeInMillis
        } else {
            val localCal = (calendarPool.get() ?: Calendar.getInstance(TimeZone.getDefault(), Locale.US)).apply {
                timeZone = TimeZone.getDefault()
                clear()
                set(Calendar.YEAR, year)
                set(Calendar.MONTH, month - 1)
                set(Calendar.DAY_OF_MONTH, day)
                set(Calendar.HOUR_OF_DAY, 23)
                set(Calendar.MINUTE, 59)
                set(Calendar.SECOND, 59)
                set(Calendar.MILLISECOND, 999)
            }
            localCal.timeInMillis
        }
    }
}
