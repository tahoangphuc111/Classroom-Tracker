package com.phucta.classroom.data.model

import java.text.Normalizer
import java.util.Locale
import java.util.regex.Pattern

private val DIACRITICS_PATTERN = Pattern.compile("\\p{InCombiningDiacriticalMarks}+")
private val VIETNAMESE_LOCALE = Locale("vi", "VN")
private val WHITESPACE_REGEX = Regex("\\s+")
private val NORMALIZE_CACHE = java.util.concurrent.ConcurrentHashMap<String, String>(256)

fun tokenizeSearchQuery(query: String): List<String> {
    val trimmed = query.trim()
    if (trimmed.isEmpty()) return emptyList()
    return trimmed.split(WHITESPACE_REGEX).filter { it.isNotEmpty() }
}

fun String.normalizeForVietnameseSearch(): String {
    if (this.isEmpty()) return ""

    if (this.length <= 128) {
        val cached = NORMALIZE_CACHE[this]
        if (cached != null) return cached
    }

    // Lowercase first using Vietnamese locale so both 'đ' and 'Đ' map to 'đ'
    val lower = this.lowercase(VIETNAMESE_LOCALE).replace('đ', 'd')

    val decomposed = Normalizer.normalize(lower, Normalizer.Form.NFD)
    val stripped = DIACRITICS_PATTERN.matcher(decomposed).replaceAll("").trim()

    if (this.length <= 128 && NORMALIZE_CACHE.size < 1024) {
        NORMALIZE_CACHE[this] = stripped
    }

    return stripped
}

/**
 * Calculates a search relevance score for a given item based on title, course name, and content.
 * Prioritizes exact matches, prefix matches, and title token matches over description mentions.
 */
fun calculateSearchRelevance(
    queryTokens: List<String>,
    rawNormalizedQuery: String,
    title: String,
    courseName: String? = null,
    content: String? = null
): Int {
    if (queryTokens.isEmpty()) return 0

    val normTitle = title.normalizeForVietnameseSearch()
    val normCourse = courseName?.normalizeForVietnameseSearch().orEmpty()
    val normContent = content?.normalizeForVietnameseSearch().orEmpty()

    var score = 0

    // Exact full query match bonuses
    if (normTitle == rawNormalizedQuery) {
        score += 200
    } else if (normTitle.startsWith(rawNormalizedQuery)) {
        score += 120
    } else if (normTitle.contains(rawNormalizedQuery)) {
        score += 80
    }

    if (normCourse == rawNormalizedQuery) {
        score += 100
    } else if (normCourse.startsWith(rawNormalizedQuery)) {
        score += 60
    } else if (normCourse.contains(rawNormalizedQuery)) {
        score += 40
    }

    // Token-level scoring with word boundary recognition
    for (token in queryTokens) {
        if (normTitle.contains(token)) {
            score += 30
            if (normTitle.startsWith(token) || normTitle.contains(" $token")) {
                score += 15
            }
        }
        if (normCourse.contains(token)) {
            score += 15
        }
        if (normContent.contains(token)) {
            score += 5
        }
    }

    return score
}

