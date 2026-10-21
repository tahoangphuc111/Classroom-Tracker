package com.phucta.classroom.domain

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import com.phucta.classroom.data.model.ClassroomDateUtils
import com.phucta.classroom.data.model.Coursework
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

object BaoBaiShareHelper {
    private val headerDateFormat = SimpleDateFormat("EEEE, d/M", ClassroomDateUtils.VIETNAMESE_LOCALE)
    fun formatHeaderDate(dateEpochMillis: Long): String {
        val raw = synchronized(headerDateFormat) {
            headerDateFormat.timeZone = TimeZone.getDefault()
            headerDateFormat.format(Date(dateEpochMillis))
        }
        return raw.replaceFirstChar { if (it.isLowerCase()) it.titlecase(Locale.getDefault()) else it.toString() }
    }
    fun formatBaoBaiText(
        items: List<Coursework>,
        dateEpochMillis: Long = ClassroomDateUtils.startOfTomorrow,
        targetDayLabel: String = "NGÀY MAI"
    ): String {
        val dateString = formatHeaderDate(dateEpochMillis)
        if (items.isEmpty()) {
            return buildString {
                append("🎉 BÁO BÀI $targetDayLabel ($dateString)\n\n")
                append("Tuyệt vời! Ngày mai bạn không có bài tập nào cần làm.\n")
                append("Nghỉ ngơi thật tốt nhé! 🚀\n\n")
                append("---\n")
                append("⚡ Classroom Tracker")
            }
        }
        val totalCount = items.size
        var completedCount = 0
        return buildString {
            append("📋 BÁO BÀI $targetDayLabel ($dateString)\n\n")
            for (i in 0 until totalCount) {
                val item = items[i]
                if (item.isCompleted) {
                    completedCount++
                }
                val courseTag = if (item.courseName.isNotBlank()) "[${item.courseName}]" else "[Chung]"
                val dueString = if (item.dueEpochMillis != null) {
                    val timeOnly = item.timeOnlyString
                    if (ClassroomDateUtils.isDueTomorrow(item.dueEpochMillis)) {
                        "Hạn: $timeOnly"
                    } else {
                        "Hạn: $timeOnly (${ClassroomDateUtils.formatShortDate(item.dueEpochMillis)})"
                    }
                } else {
                    "Không có hạn nộp"
                }
                val statusSuffix = if (item.isCompleted) " (Đã xong ✓)" else ""
                append("${i + 1}. $courseTag ${item.title} — $dueString$statusSuffix\n")
            }
            append("\n---\n")
            append("🔥 Tiến độ: $completedCount/$totalCount bài hoàn thành\n")
            append("⚡ Classroom Tracker")
        }
    }
    fun copyToClipboard(context: Context, text: String, label: String = "Báo bài"): Boolean {
        return try {
            val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager ?: return false
            val clip = ClipData.newPlainText(label, text)
            clipboard.setPrimaryClip(clip)
            true
        } catch (_: Exception) {
            false
        }
    }
    fun createShareIntent(text: String, title: String = "Chia sẻ Báo bài"): Intent {
        return Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            putExtra(Intent.EXTRA_SUBJECT, title)
            putExtra(Intent.EXTRA_TEXT, text)
        }
    }
}
