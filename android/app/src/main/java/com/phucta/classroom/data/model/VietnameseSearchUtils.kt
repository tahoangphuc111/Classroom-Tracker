package com.phucta.classroom.data.model

import java.text.Normalizer
import java.util.Locale
import java.util.regex.Pattern

private val DIACRITICS_PATTERN = Pattern.compile("\\p{InCombiningDiacriticalMarks}+")
private val VIETNAMESE_LOCALE = Locale("vi", "VN")

fun String.normalizeForVietnameseSearch(): String {
    if (this.isEmpty()) return ""

    // Lowercase first using Vietnamese locale so both 'đ' and 'Đ' map to 'đ'
    val lower = this.lowercase(VIETNAMESE_LOCALE).replace('đ', 'd')

    val decomposed = Normalizer.normalize(lower, Normalizer.Form.NFD)
    val stripped = DIACRITICS_PATTERN.matcher(decomposed).replaceAll("")

    return stripped.trim()
}
