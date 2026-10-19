package com.phucta.classroom

import com.phucta.classroom.data.model.normalizeForVietnameseSearch
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class VietnameseSearchUtilsTest {

    @Test
    fun testDiacriticRemovalAndNormalizing() {
        val input = "Giải tích & Hình học không gian"
        val normalized = input.normalizeForVietnameseSearch()
        assertEquals("giai tich & hinh hoc khong gian", normalized)
    }

    @Test
    fun testLetterDReplacement() {
        val input = "Đại số và Đạo hàm"
        val normalized = input.normalizeForVietnameseSearch()
        assertEquals("dai so va dao ham", normalized)
        assertTrue(normalized.startsWith("d"))
    }

    @Test
    fun testVietnameseToneMarks() {
        val input = "Bài tập thực hành tuần 1"
        val normalized = input.normalizeForVietnameseSearch()
        assertEquals("bai tap thuc hanh tuan 1", normalized)
    }

    @Test
    fun testEmptyAndWhitespace() {
        assertEquals("", "".normalizeForVietnameseSearch())
        assertEquals("toan", "   Toán   ".normalizeForVietnameseSearch())
    }

    @Test
    fun testSearchRelevanceScoring() {
        val tokens = listOf("giai", "tich")
        val rawQuery = "giai tich"

        val exactScore = com.phucta.classroom.data.model.calculateSearchRelevance(
            queryTokens = tokens,
            rawNormalizedQuery = rawQuery,
            title = "Giải tích",
            courseName = "Toán 12",
            content = "Lý thuyết"
        )

        val prefixScore = com.phucta.classroom.data.model.calculateSearchRelevance(
            queryTokens = tokens,
            rawNormalizedQuery = rawQuery,
            title = "Giải tích chương 1",
            courseName = "Toán 12",
            content = "Lý thuyết"
        )

        val contentScore = com.phucta.classroom.data.model.calculateSearchRelevance(
            queryTokens = tokens,
            rawNormalizedQuery = rawQuery,
            title = "Bài tập về nhà",
            courseName = "Toán 12",
            content = "Làm bài tập giải tích SGK trang 45"
        )

        assertTrue("Exact title match must score higher than prefix", exactScore > prefixScore)
        assertTrue("Prefix title match must score higher than content match", prefixScore > contentScore)
    }
}
