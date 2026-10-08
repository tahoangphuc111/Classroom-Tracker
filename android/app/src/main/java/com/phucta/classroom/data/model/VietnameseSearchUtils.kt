package com.phucta.classroom.data.model

import java.text.Normalizer
import java.util.Locale
import java.util.regex.Pattern

private val DIACRITICS_PATTERN = Pattern.compile("\\p{InCombiningDiacriticalMarks}+")

fun String.normalizeForVietnameseSearch(): String {
    if (this.isEmpty()) return ""

    // 1. Replace Vietnamese specific 'đ' and 'Đ'
    val replaced = this
        .replace("đ", "d")
        .replace("Đ", "d")

    // 2. Decompose diacritics using NFD and remove combining marks
    val decomposed = Normalizer.normalize(replaced, Normalizer.Form.NFD)
    val stripped = DIACRITICS_PATTERN.matcher(decomposed).replaceAll("")

    // 3. Lowercase with Vietnamese locale
    return stripped.lowercase(Locale("vi", "VN")).trim()
}
