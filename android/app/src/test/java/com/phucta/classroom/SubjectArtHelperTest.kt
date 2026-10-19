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
    fun testAdvancedAcademicCurriculumMatching() {
        assertEquals(SubjectCategory.MATH, SubjectArtHelper.category("Chuyên đề Lượng giác 11"))
        assertEquals(SubjectCategory.MATH, SubjectArtHelper.category("Đạo hàm và Tích phân"))
        assertEquals(SubjectCategory.MATH, SubjectArtHelper.category("Toán rời rạc"))
        assertEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Cơ học lượng tử"))
        assertEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Thí nghiệm Quang học"))
        assertEquals(SubjectCategory.CHEMISTRY, SubjectArtHelper.category("Hóa phân tích thực nghiệm"))
        assertEquals(SubjectCategory.BIOLOGY, SubjectArtHelper.category("Di truyền học quần thể"))
        assertEquals(SubjectCategory.CIVICS_OR_PHILOSOPHY, SubjectArtHelper.category("Triết học Mác - Lênin"))
        assertEquals(SubjectCategory.CIVICS_OR_PHILOSOPHY, SubjectArtHelper.category("Tư tưởng Hồ Chí Minh"))
        assertEquals(SubjectCategory.COMPUTER_SCIENCE, SubjectArtHelper.category("Cấu trúc dữ liệu và giải thuật"))
        assertEquals(SubjectCategory.COMPUTER_SCIENCE, SubjectArtHelper.category("Trí tuệ nhân tạo"))
        assertEquals(SubjectCategory.NETWORKING, SubjectArtHelper.category("An toàn thông tin mạng"))
    }

    @Test
    fun testNegativeTokenGuards_Physics() {
        // "Quản lý", "Xử lý", and "Tâm lý" must not be categorized as physics.
        assertNotEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Quản lý Dự án Phần mềm"))
        assertNotEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Xử lý Tín hiệu Số"))
        assertNotEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Tâm lý học Đại cương"))
        assertNotEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Pháp lý và Đạo đức"))
    }

    @Test
    fun testNegativeTokenGuards_Chemistry() {
        // "Văn hóa" and "Hóa đơn" must not be categorized as chemistry.
        assertNotEquals(SubjectCategory.CHEMISTRY, SubjectArtHelper.category("Văn hóa Việt Nam"))
        assertNotEquals(SubjectCategory.CHEMISTRY, SubjectArtHelper.category("Hóa đơn và Chứng từ"))
    }

    @Test
    fun testNegativeTokenGuards_Biology() {
        // "Học sinh", "Sinh viên", and "Sinh hoạt" must not be categorized as biology.
        assertNotEquals(SubjectCategory.BIOLOGY, SubjectArtHelper.category("Sinh hoạt Lớp Chủ nhiệm"))
    }

    @Test
    fun testNegativeTokenGuards_History() {
        // "Sử dụng" and "Lịch sự" must not be categorized as history.
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

        val theme4 = SubjectArtHelper.theme("AI", "")
        assertEquals("AI", theme4.badgeCode)
    }

    @Test
    fun testTeacherNameExclusion_EnglishCategory() {
        assertNotEquals(SubjectCategory.ENGLISH, SubjectArtHelper.category("Lớp Cô Mai Anh"))
        assertNotEquals(SubjectCategory.ENGLISH, SubjectArtHelper.category("Chủ nhiệm Thầy Tuấn Anh"))
        assertNotEquals(SubjectCategory.ENGLISH, SubjectArtHelper.category("GV Lê Anh"))
    }

    @Test
    fun testVietnameseAccentVariation_LiteratureCategory() {
        assertNotEquals(SubjectCategory.LITERATURE, SubjectArtHelper.category("Cơ sở Văn hoá"))
    }

    @Test
    fun testCloudToken_NetworkingCategory() {
        assertEquals(SubjectCategory.NETWORKING, SubjectArtHelper.category("Hạ tầng Cloud"))
    }

    @Test
    fun testThemeColorUniqueness() {
        val categories = SubjectCategory.values()
        val colors = categories.map { SubjectArtHelper.themeColor(it) }
        
        // Ensure no adjacent categories share duplicate colors (e.g. Math, Lit, Civics, History, Economics are separated)
        assertNotEquals(SubjectArtHelper.themeColor(SubjectCategory.MATH), SubjectArtHelper.themeColor(SubjectCategory.LITERATURE))
        assertNotEquals(SubjectArtHelper.themeColor(SubjectCategory.MATH), SubjectArtHelper.themeColor(SubjectCategory.HISTORY_OR_GEOGRAPHY))
        assertNotEquals(SubjectArtHelper.themeColor(SubjectCategory.MATH), SubjectArtHelper.themeColor(SubjectCategory.ECONOMICS))
        assertNotEquals(SubjectArtHelper.themeColor(SubjectCategory.LITERATURE), SubjectArtHelper.themeColor(SubjectCategory.CIVICS_OR_PHILOSOPHY))
    }

    @Test
    fun testDueDateBadgeDefaults() {
        val overdueColors = com.phucta.classroom.ui.components.DueDateBadgeDefaults.colors(
            isCompleted = false,
            isOverdue = true,
            isDueToday = false,
            isDueTomorrow = false
        )
        assertEquals(com.phucta.classroom.ui.theme.ChunkyColor.OverdueText, overdueColors.text)
        assertEquals(com.phucta.classroom.ui.theme.ChunkyColor.OverdueBackground, overdueColors.background)

        val todayColors = com.phucta.classroom.ui.components.DueDateBadgeDefaults.colors(
            isCompleted = false,
            isOverdue = false,
            isDueToday = true,
            isDueTomorrow = false
        )
        assertEquals(com.phucta.classroom.ui.theme.ChunkyColor.TodayText, todayColors.text)

        val tomorrowColors = com.phucta.classroom.ui.components.DueDateBadgeDefaults.colors(
            isCompleted = false,
            isOverdue = false,
            isDueToday = false,
            isDueTomorrow = true
        )
        assertEquals(com.phucta.classroom.ui.theme.ChunkyColor.TomorrowText, tomorrowColors.text)

        val completedColors = com.phucta.classroom.ui.components.DueDateBadgeDefaults.colors(
            isCompleted = true,
            isOverdue = false,
            isDueToday = false,
            isDueTomorrow = false
        )
        assertEquals(com.phucta.classroom.ui.theme.ChunkyColor.CompletedBadgeText, completedColors.text)
    }
}
