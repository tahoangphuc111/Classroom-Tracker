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
        assertNotEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Quản lý Dự án Phần mềm"))
        assertNotEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Xử lý Tín hiệu Số"))
        assertNotEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Tâm lý học Đại cương"))
        assertNotEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Pháp lý và Đạo đức"))
    }

    @Test
    fun testNegativeTokenGuards_Chemistry() {
        assertNotEquals(SubjectCategory.CHEMISTRY, SubjectArtHelper.category("Văn hóa Việt Nam"))
        assertNotEquals(SubjectCategory.CHEMISTRY, SubjectArtHelper.category("Hóa đơn và Chứng từ"))
    }

    @Test
    fun testNegativeTokenGuards_Biology() {
        assertNotEquals(SubjectCategory.BIOLOGY, SubjectArtHelper.category("Sinh hoạt Lớp Chủ nhiệm"))
    }

    @Test
    fun testNegativeTokenGuards_History() {
        assertNotEquals(SubjectCategory.HISTORY_OR_GEOGRAPHY, SubjectArtHelper.category("Sử dụng phần mềm văn phòng"))
        assertNotEquals(SubjectCategory.HISTORY_OR_GEOGRAPHY, SubjectArtHelper.category("Lịch sự trong giao tiếp"))

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

    @Test
    fun testSubjectIconCoverage() {
        SubjectCategory.values().forEach { category ->
            val iconRes = SubjectArtHelper.iconForCategory(category)
            org.junit.Assert.assertTrue("Icon res should be non-zero for $category", iconRes != 0)
        }
        val theme = SubjectArtHelper.theme("Toán")
        org.junit.Assert.assertEquals(R.drawable.ic_subject_math, theme.iconRes)
    }

    @Test
    fun testQuanTriMang_ClassifiesAsNetworking_NotEconomics() {
        val category = SubjectArtHelper.category("Quản trị mạng")
        assertEquals(SubjectCategory.NETWORKING, category)
        assertNotEquals(SubjectCategory.ECONOMICS, category)
    }

    @Test
    fun testDienToan_DoesNotClassifyAsMath() {
        assertNotEquals(SubjectCategory.MATH, SubjectArtHelper.category("Điện toán đám mây"))
        assertNotEquals(SubjectCategory.MATH, SubjectArtHelper.category("Khoa học điện toán"))
    }

    @Test
    fun testLyLuan_DoesNotClassifyAsPhysics() {
        assertNotEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Lý luận chính trị"))
        assertNotEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Lí luận văn học"))
    }

    @Test
    fun testAoHoaSoHoa_DoesNotClassifyAsChemistry() {
        assertNotEquals(SubjectCategory.CHEMISTRY, SubjectArtHelper.category("Ảo hóa hệ thống"))
        assertNotEquals(SubjectCategory.CHEMISTRY, SubjectArtHelper.category("Số hóa dữ liệu doanh nghiệp"))
    }

    @Test
    fun testVanBanLuanVan_DoesNotClassifyAsLiterature() {
        assertNotEquals(SubjectCategory.LITERATURE, SubjectArtHelper.category("Soạn thảo văn bản"))
        assertNotEquals(SubjectCategory.LITERATURE, SubjectArtHelper.category("Hướng dẫn viết Luận văn"))
    }

    @Test
    fun testUnaccentedCoreSubjectTokens() {
        assertEquals(SubjectCategory.MATH, SubjectArtHelper.category("Toan 12"))
        assertEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Ly 11"))
        assertEquals(SubjectCategory.CHEMISTRY, SubjectArtHelper.category("Hoa 10"))
        assertEquals(SubjectCategory.LITERATURE, SubjectArtHelper.category("Van 12"))
        assertEquals(SubjectCategory.HISTORY_OR_GEOGRAPHY, SubjectArtHelper.category("Su 11"))
        assertEquals(SubjectCategory.HISTORY_OR_GEOGRAPHY, SubjectArtHelper.category("Dia 10"))

        val diaTheme = SubjectArtHelper.theme("Dia 10")
        assertEquals("ĐỊA", diaTheme.badgeCode)
    }
}
