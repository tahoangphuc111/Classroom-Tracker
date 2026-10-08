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
}
