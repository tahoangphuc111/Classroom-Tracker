package com.phucta.classroom

import com.phucta.classroom.ui.components.SubjectArtHelper
import com.phucta.classroom.ui.components.SubjectCategory
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Test

class SubjectArtHelperTest {

    @Test
    fun testStandardSubjectMatching() {
        assertEquals(SubjectCategory.MATH, SubjectArtHelper.category("Toán Giải tích 12"))
        assertEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Vật lý Đại cương"))
        assertEquals(SubjectCategory.CHEMISTRY, SubjectArtHelper.category("Hóa học Hữu cơ"))
        assertEquals(SubjectCategory.BIOLOGY, SubjectArtHelper.category("Sinh học Tế bào"))
        assertEquals(SubjectCategory.LITERATURE, SubjectArtHelper.category("Ngữ văn 11"))
        assertEquals(SubjectCategory.ENGLISH, SubjectArtHelper.category("Tiếng Anh Chuyên ngành"))
        assertEquals(SubjectCategory.COMPUTER_SCIENCE, SubjectArtHelper.category("Lập trình Android"))
    }

    @Test
    fun testNegativeTokenGuards_Physics() {
        // "Quản lý", "Xử lý", "Tâm lý" must NOT be categorized as Physics!
        assertNotEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Quản lý Dự án Phần mềm"))
        assertNotEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Xử lý Tín hiệu Số"))
        assertNotEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Tâm lý học Đại cương"))
        assertNotEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Pháp lý và Đạo đức"))
    }

    @Test
    fun testNegativeTokenGuards_Chemistry() {
        // "Văn hóa", "Hóa đơn" must NOT be categorized as Chemistry!
        assertNotEquals(SubjectCategory.CHEMISTRY, SubjectArtHelper.category("Văn hóa Việt Nam"))
        assertNotEquals(SubjectCategory.CHEMISTRY, SubjectArtHelper.category("Hóa đơn và Chứng từ"))
    }

    @Test
    fun testNegativeTokenGuards_Biology() {
        // "Học sinh", "Sinh viên", "Sinh hoạt" must NOT be categorized as Biology!
        assertNotEquals(SubjectCategory.BIOLOGY, SubjectArtHelper.category("Sinh hoạt Lớp Chủ nhiệm"))
    }

    @Test
    fun testNegativeTokenGuards_History() {
        // "Sử dụng", "Lịch sự" must NOT be categorized as History!
        assertNotEquals(SubjectCategory.HISTORY_OR_GEOGRAPHY, SubjectArtHelper.category("Sử dụng phần mềm văn phòng"))
        assertNotEquals(SubjectCategory.HISTORY_OR_GEOGRAPHY, SubjectArtHelper.category("Lịch sự trong giao tiếp"))

        // Legitimate history courses should match
        assertEquals(SubjectCategory.HISTORY_OR_GEOGRAPHY, SubjectArtHelper.category("Lịch sử Việt Nam"))
        assertEquals(SubjectCategory.HISTORY_OR_GEOGRAPHY, SubjectArtHelper.category("Sử 12"))
    }

    @Test
    fun testBadgeCodeFallback_OtherCategory() {
        val theme1 = SubjectArtHelper.theme("Kỹ năng mềm")
        assertEquals("KỸ ", theme1.badgeCode)

        val theme2 = SubjectArtHelper.theme("", "Khảo sát đầu năm")
        assertEquals("KHẢ", theme2.badgeCode)

        val theme3 = SubjectArtHelper.theme("", "")
        assertEquals("MÔN", theme3.badgeCode)
    }
}
