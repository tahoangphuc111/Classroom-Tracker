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

    fun buildTimeOnlyString(dueEpochMillis: Long?): String {
        if (dueEpochMillis == null) return "--:--"
        val cal = Calendar.getInstance()
        cal.timeInMillis = dueEpochMillis
        val hour = cal.get(Calendar.HOUR_OF_DAY)
        val minute = cal.get(Calendar.MINUTE)
        if (hour == 23 && minute >= 55) {
            return "Cuối ngày"
        }
        return synchronized(timeOnlyFormat) {
            timeOnlyFormat.format(Date(dueEpochMillis))
        }
    }

    fun buildFormattedFullDueDate(dueEpochMillis: Long?): String {
        if (dueEpochMillis == null) return "Không có hạn nộp"
        val formatted = synchronized(fullDueDateFormat) {
            fullDueDateFormat.format(Date(dueEpochMillis))
        }
        return formatted.replaceFirstChar { if (it.isLowerCase()) it.titlecase(VIETNAMESE_LOCALE) else it.toString() }
    }

    fun isDueToday(dueEpochMillis: Long?): Boolean {
        if (dueEpochMillis == null) return false
        val calNow = Calendar.getInstance()
        val calDue = Calendar.getInstance().apply { timeInMillis = dueEpochMillis }
        return calNow.get(Calendar.ERA) == calDue.get(Calendar.ERA) &&
                calNow.get(Calendar.YEAR) == calDue.get(Calendar.YEAR) &&
                calNow.get(Calendar.DAY_OF_YEAR) == calDue.get(Calendar.DAY_OF_YEAR)
    }

    fun isDueTomorrow(dueEpochMillis: Long?): Boolean {
        if (dueEpochMillis == null) return false
        val calTomorrow = Calendar.getInstance().apply { add(Calendar.DAY_OF_YEAR, 1) }
        val calDue = Calendar.getInstance().apply { timeInMillis = dueEpochMillis }
        return calTomorrow.get(Calendar.ERA) == calDue.get(Calendar.ERA) &&
                calTomorrow.get(Calendar.YEAR) == calDue.get(Calendar.YEAR) &&
                calTomorrow.get(Calendar.DAY_OF_YEAR) == calDue.get(Calendar.DAY_OF_YEAR)
    }

    fun isOverdue(dueEpochMillis: Long?, isCompleted: Boolean): Boolean {
        if (dueEpochMillis == null || isCompleted) return false
        return dueEpochMillis < System.currentTimeMillis()
    }

    fun isPast(dueEpochMillis: Long?): Boolean {
        if (dueEpochMillis == null) return false
        val startOfToday = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }.timeInMillis
        return dueEpochMillis < startOfToday
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
                    val dayStr = synchronized(shortDateFormat) { shortDateFormat.format(date) }
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
                val dayStr = synchronized(shortDateFormat) { shortDateFormat.format(date) }
                "Đã qua ($dayStr)"
            }
            else -> {
                val dayStr = synchronized(dayAndDateFormat) { dayAndDateFormat.format(date) }
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

    fun compactDueString(dueEpochMillis: Long?, isCompleted: Boolean): String {
        if (dueEpochMillis == null) return "Không hạn"
        if (isCompleted) return "Đã nộp"
        val time = buildTimeOnlyString(dueEpochMillis)
        val isEndOfDay = (time == "Cuối ngày")
        val overdue = isOverdue(dueEpochMillis, isCompleted)
        val today = isDueToday(dueEpochMillis)
        val tomorrow = isDueTomorrow(dueEpochMillis)
        val past = isPast(dueEpochMillis)

        return when {
            overdue -> {
                if (today) {
                    if (isEndOfDay) "Quá hạn" else "Trễ $time"
                } else {
                    "Quá hạn"
                }
            }
            today -> if (isEndOfDay) "Hết hôm nay" else time
            tomorrow -> if (isEndOfDay) "Hết ngày mai" else "Mai $time"
            past -> "Đã qua"
            else -> {
                val dayStr = synchronized(shortDateFormat) { shortDateFormat.format(Date(dueEpochMillis)) }
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
