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

    private val timeOnlyFormat = SimpleDateFormat("HH:mm", Locale.US)
    private val shortDateFormat = SimpleDateFormat("d/M", VIETNAMESE_LOCALE)
    private val dayAndDateFormat = SimpleDateFormat("E, d/M", VIETNAMESE_LOCALE)
    private val fullDueDateFormat = SimpleDateFormat("EEEE, 'ngày' d 'tháng' M, yyyy 'lúc' HH:mm", VIETNAMESE_LOCALE)

    @Volatile
    private var cachedStartOfToday: Long = 0L
    @Volatile
    private var cachedStartOfTomorrow: Long = 0L
    @Volatile
    private var cachedStartOfDayAfter: Long = 0L
    @Volatile
    private var cacheExpirationTime: Long = 0L
    @Volatile
    private var cachedTimeZoneId: String = ""

    private val timeOnlyCache = java.util.concurrent.ConcurrentHashMap<Long, String>()
    private val fullDueDateCache = java.util.concurrent.ConcurrentHashMap<Long, String>()

    private fun checkTimeZone() {
        val currentTzId = TimeZone.getDefault().id
        if (currentTzId != cachedTimeZoneId) {
            synchronized(this) {
                if (currentTzId != cachedTimeZoneId) {
                    cachedTimeZoneId = currentTzId
                    timeOnlyCache.clear()
                    fullDueDateCache.clear()
                    cachedStartOfToday = 0L
                    cacheExpirationTime = 0L
                }
            }
        }
    }

    fun ensureDayBoundaries(now: Long = System.currentTimeMillis()) {
        checkTimeZone()
        if (now >= cacheExpirationTime || cachedStartOfToday == 0L) {
            synchronized(this) {
                if (now >= cacheExpirationTime || cachedStartOfToday == 0L) {
                    val cal = Calendar.getInstance().apply {
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
        return synchronized(shortDateFormat) {
            shortDateFormat.timeZone = TimeZone.getDefault()
            shortDateFormat.format(Date(dueEpochMillis))
        }
    }

    fun buildTimeOnlyString(dueEpochMillis: Long?): String {
        if (dueEpochMillis == null) return "--:--"
        checkTimeZone()
        val cached = timeOnlyCache[dueEpochMillis]
        if (cached != null) return cached

        val cal = Calendar.getInstance()
        cal.timeInMillis = dueEpochMillis
        val hour = cal.get(Calendar.HOUR_OF_DAY)
        val minute = cal.get(Calendar.MINUTE)
        val result = if (hour == 23 && minute >= 55) {
            "Cuối ngày"
        } else {
            synchronized(timeOnlyFormat) {
                timeOnlyFormat.timeZone = TimeZone.getDefault()
                timeOnlyFormat.format(Date(dueEpochMillis))
            }
        }
        if (timeOnlyCache.size < 1000) {
            timeOnlyCache[dueEpochMillis] = result
        }
        return result
    }

    fun buildFormattedFullDueDate(dueEpochMillis: Long?): String {
        if (dueEpochMillis == null) return "Không có hạn nộp"
        checkTimeZone()
        val cached = fullDueDateCache[dueEpochMillis]
        if (cached != null) return cached

        val formatted = synchronized(fullDueDateFormat) {
            fullDueDateFormat.timeZone = TimeZone.getDefault()
            fullDueDateFormat.format(Date(dueEpochMillis))
        }
        val result = formatted.replaceFirstChar { if (it.isLowerCase()) it.titlecase(VIETNAMESE_LOCALE) else it.toString() }
        if (fullDueDateCache.size < 1000) {
            fullDueDateCache[dueEpochMillis] = result
        }
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
        val time = buildTimeOnlyString(dueEpochMillis)
        val isEndOfDay = (time == "Cuối ngày")
        val overdue = isOverdue(dueEpochMillis, isCompleted)
        val today = isDueToday(dueEpochMillis)
        val tomorrow = isDueTomorrow(dueEpochMillis)
        val past = isPast(dueEpochMillis)
        val date = Date(dueEpochMillis)

        return when {
            overdue -> {
                if (today) {
                    if (isEndOfDay) "Quá hạn (hôm nay)" else "Quá hạn ($time)"
                } else {
                    val dayStr = synchronized(shortDateFormat) {
                        shortDateFormat.timeZone = TimeZone.getDefault()
                        shortDateFormat.format(date)
                    }
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
                val dayStr = synchronized(shortDateFormat) {
                    shortDateFormat.timeZone = TimeZone.getDefault()
                    shortDateFormat.format(date)
                }
                "Đã qua ($dayStr)"
            }
            else -> {
                val dayStr = synchronized(dayAndDateFormat) {
                    dayAndDateFormat.timeZone = TimeZone.getDefault()
                    dayAndDateFormat.format(date)
                }
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
        val time = precomputedTimeOnly ?: buildTimeOnlyString(dueEpochMillis)
        val isEndOfDay = (time == "Cuối ngày")
        val overdue = isOverdue(dueEpochMillis, isCompleted)
        val today = isDueToday(dueEpochMillis)
        val tomorrow = isDueTomorrow(dueEpochMillis)
        val past = isPast(dueEpochMillis)

        return when {
            today -> if (isEndOfDay) "Cuối ngày" else time
            tomorrow -> if (isEndOfDay) "Mai" else "Mai $time"
            overdue -> "Quá hạn"
            past -> "Đã qua"
            else -> {
                val dayStr = synchronized(shortDateFormat) {
                    shortDateFormat.timeZone = TimeZone.getDefault()
                    shortDateFormat.format(Date(dueEpochMillis))
                }
                if (isEndOfDay) dayStr else "$dayStr $time"
            }
        }
    }

    /**
     * Parses Google Classroom API Date and Time objects.
     * Google returns `date` and `time` in UTC.
     * In proto3 JSON, 0-value fields (like hours = 0) are omitted.
     * If `hasDueTime` is false (or time is null), it represents end of day in the user's LOCAL timezone (23:59:59).
     */
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
            // Google Classroom API TimeOfDay is in UTC; proto3 omits 0 fields
            val utcCal = Calendar.getInstance(TimeZone.getTimeZone("UTC")).apply {
                clear() // Prevent day-of-month overflow from current date
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
            // End of day in user's local timezone
            val localCal = Calendar.getInstance().apply {
                clear() // Prevent day-of-month overflow from current date
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
