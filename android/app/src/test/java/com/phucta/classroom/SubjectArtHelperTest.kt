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
        assertEquals(SubjectCategory.OTHER, SubjectArtHelper.category("Triết học Mác - Lênin"))
        assertEquals(SubjectCategory.OTHER, SubjectArtHelper.category("Tư tưởng Hồ Chí Minh"))
        assertEquals(SubjectCategory.COMPUTER_SCIENCE, SubjectArtHelper.category("Cấu trúc dữ liệu và giải thuật"))
        assertEquals(SubjectCategory.COMPUTER_SCIENCE, SubjectArtHelper.category("Trí tuệ nhân tạo"))
        assertEquals(SubjectCategory.OTHER, SubjectArtHelper.category("An toàn thông tin mạng"))

        // 11 Core High School Curriculum Subjects
        assertEquals(SubjectCategory.DEFENSE_EDUCATION, SubjectArtHelper.category("Giáo dục Quốc phòng và An ninh 12"))
        assertEquals(SubjectCategory.DEFENSE_EDUCATION, SubjectArtHelper.category("GDQP 10"))
        assertEquals(SubjectCategory.LOCAL_EDUCATION, SubjectArtHelper.category("Giáo dục địa phương 11"))
        assertEquals(SubjectCategory.LOCAL_EDUCATION, SubjectArtHelper.category("GDDP 11"))
        assertEquals(SubjectCategory.EXPERIENTIAL_ACTIVITIES, SubjectArtHelper.category("Hoạt động trải nghiệm, hướng nghiệp 12"))
        assertEquals(SubjectCategory.EXPERIENTIAL_ACTIVITIES, SubjectArtHelper.category("HDTN 10"))
    }

    @Test
    fun testNegativeTokenGuards_Physics() {
        assertNotEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Quản lý Dự án Phần mềm"))
        assertNotEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Xử lý Tín hiệu Số"))
        assertNotEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Tâm lý học Đại cương"))
        assertNotEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Pháp lý và Đạo đức"))
        assertNotEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Địa lý tự nhiên"))
        assertNotEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Triết lý kinh doanh"))

        // Unaccented guards
        assertNotEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Quan ly Du an Phan mem"))
        assertNotEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Xu ly Tin hieu So"))
        assertNotEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Tam ly hoc Dai cuong"))
        assertNotEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Phap ly va Dao duc"))
        assertNotEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Dia ly tu nhien"))
        assertNotEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Triet ly kinh doanh"))
    }

    @Test
    fun testNegativeTokenGuards_Chemistry() {
        assertNotEquals(SubjectCategory.CHEMISTRY, SubjectArtHelper.category("Văn hóa Việt Nam"))
        assertNotEquals(SubjectCategory.CHEMISTRY, SubjectArtHelper.category("Hóa đơn và Chứng từ"))
        assertNotEquals(SubjectCategory.CHEMISTRY, SubjectArtHelper.category("Tự động hóa quá trình sản xuất"))
        assertNotEquals(SubjectCategory.CHEMISTRY, SubjectArtHelper.category("Chuẩn hóa cơ sở dữ liệu"))

        // Unaccented guards
        assertNotEquals(SubjectCategory.CHEMISTRY, SubjectArtHelper.category("Van hoa Viet Nam"))
        assertNotEquals(SubjectCategory.CHEMISTRY, SubjectArtHelper.category("Hoa don va Chung tu"))
        assertNotEquals(SubjectCategory.CHEMISTRY, SubjectArtHelper.category("Tu dong hoa qua trinh san xuat"))
        assertNotEquals(SubjectCategory.CHEMISTRY, SubjectArtHelper.category("Chuan hoa co so du lieu"))
    }

    @Test
    fun testNegativeTokenGuards_Biology() {
        assertNotEquals(SubjectCategory.BIOLOGY, SubjectArtHelper.category("Sinh hoạt Lớp Chủ nhiệm"))
        assertNotEquals(SubjectCategory.BIOLOGY, SubjectArtHelper.category("Sinh hoat Lop Chu nhiem"))
    }

    @Test
    fun testNegativeTokenGuards_History() {
        assertNotEquals(SubjectCategory.HISTORY, SubjectArtHelper.category("Sử dụng phần mềm văn phòng"))
        assertNotEquals(SubjectCategory.HISTORY, SubjectArtHelper.category("Lịch sự trong giao tiếp"))

        // Unaccented guards
        assertNotEquals(SubjectCategory.HISTORY, SubjectArtHelper.category("Su dung phan mem van phong"))
        assertNotEquals(SubjectCategory.HISTORY, SubjectArtHelper.category("Lich su trong giao tiep"))

        assertEquals(SubjectCategory.HISTORY, SubjectArtHelper.category("Lịch sử Việt Nam"))
        assertEquals(SubjectCategory.HISTORY, SubjectArtHelper.category("Sử 12"))
        assertEquals(SubjectCategory.HISTORY, SubjectArtHelper.category("Lich su Viet Nam"))
        assertEquals(SubjectCategory.HISTORY, SubjectArtHelper.category("Su 12"))
    }

    @Test
    fun testUnicodeNfdAndUnaccentedMatching() {
        // NFD decomposed forms:
        // "Lý 10" with decomposed acute accent
        val nfdLy = java.text.Normalizer.normalize("Lý 10", java.text.Normalizer.Form.NFD)
        assertEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category(nfdLy))

        // "Hóa 11" with decomposed acute accent
        val nfdHoa = java.text.Normalizer.normalize("Hóa 11", java.text.Normalizer.Form.NFD)
        assertEquals(SubjectCategory.CHEMISTRY, SubjectArtHelper.category(nfdHoa))

        // "Sử 12" with decomposed horn and hook
        val nfdSu = java.text.Normalizer.normalize("Sử 12", java.text.Normalizer.Form.NFD)
        assertEquals(SubjectCategory.HISTORY, SubjectArtHelper.category(nfdSu))

        // "Quản lý" decomposed must not match PHYSICS
        val nfdQuanLy = java.text.Normalizer.normalize("Quản lý Dự án", java.text.Normalizer.Form.NFD)
        assertNotEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category(nfdQuanLy))

        // "Văn hóa" decomposed must not match CHEMISTRY
        val nfdVanHoa = java.text.Normalizer.normalize("Văn hóa Doanh nghiệp", java.text.Normalizer.Form.NFD)
        assertNotEquals(SubjectCategory.CHEMISTRY, SubjectArtHelper.category(nfdVanHoa))

        // Unaccented positive matching
        assertEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Vat ly Dai cuong"))
        assertEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("Mon ly 12"))
        assertEquals(SubjectCategory.CHEMISTRY, SubjectArtHelper.category("Hoa hoc Huu co"))
        assertEquals(SubjectCategory.CHEMISTRY, SubjectArtHelper.category("Mon hoa 11"))
        assertEquals(SubjectCategory.MATH, SubjectArtHelper.category("Toan Giai tich 12"))
        assertEquals(SubjectCategory.LITERATURE, SubjectArtHelper.category("Ngu van 11"))
        assertEquals(SubjectCategory.ENGLISH, SubjectArtHelper.category("Tieng Anh 12"))
        assertEquals(SubjectCategory.COMPUTER_SCIENCE, SubjectArtHelper.category("Tin hoc 12"))
    }

    @Test
    fun testBadgeCodeFallback_OtherCategory() {
        val theme1 = SubjectArtHelper.theme("Kỹ năng mềm")
        assertEquals("KỸ ", theme1.badgeCode)

        val theme1Trimmed = SubjectArtHelper.theme("  Kỹ năng mềm  ")
        assertEquals("KỸ ", theme1Trimmed.badgeCode)

        val theme2 = SubjectArtHelper.theme("", "Khảo sát đầu năm")
        assertEquals("KHẢ", theme2.badgeCode)

        val theme3 = SubjectArtHelper.theme("", "")
        assertEquals("MÔN", theme3.badgeCode)

        val theme3Whitespace = SubjectArtHelper.theme("   ", "   ")
        assertEquals("MÔN", theme3Whitespace.badgeCode)

        val theme4 = SubjectArtHelper.theme("AI", "")
        assertEquals("AI", theme4.badgeCode)

        val theme4Padded = SubjectArtHelper.theme("  AI  ", "")
        assertEquals("AI", theme4Padded.badgeCode)

        // Course < 3 chars fallback to title >= 3 chars
        val themeCourseShortTitleLong = SubjectArtHelper.badgeCode(SubjectCategory.OTHER, "A", "Khảo sát đầu năm")
        assertEquals("KHẢ", themeCourseShortTitleLong)

        // Course < 3 chars and title < 3 chars uses course
        val themeBothShort = SubjectArtHelper.badgeCode(SubjectCategory.OTHER, "A", "B")
        assertEquals("A", themeBothShort)

        // Empty course and title < 3 chars uses title
        val themeTitleShort = SubjectArtHelper.badgeCode(SubjectCategory.OTHER, "", "ML")
        assertEquals("ML", themeTitleShort)

        // Convenience overload matches Swift parity
        assertEquals("TOÁN", SubjectArtHelper.badgeCode("Toán 12"))
        assertEquals("LÝ", SubjectArtHelper.badgeCode("Vật lý 10"))
        assertEquals("KỸ ", SubjectArtHelper.badgeCode("Kỹ năng mềm"))
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
    fun testCloudToken_FallbackToOther() {
        assertEquals(SubjectCategory.OTHER, SubjectArtHelper.category("Hạ tầng Cloud"))
    }

    @Test
    fun testThemeColorUniqueness() {
        val categories = SubjectCategory.values()
        val colors = categories.map { SubjectArtHelper.themeColor(it) }

        assertNotEquals(SubjectArtHelper.themeColor(SubjectCategory.MATH), SubjectArtHelper.themeColor(SubjectCategory.LITERATURE))
        assertNotEquals(SubjectArtHelper.themeColor(SubjectCategory.MATH), SubjectArtHelper.themeColor(SubjectCategory.HISTORY))
        assertNotEquals(SubjectArtHelper.themeColor(SubjectCategory.MATH), SubjectArtHelper.themeColor(SubjectCategory.DEFENSE_EDUCATION))
        assertNotEquals(SubjectArtHelper.themeColor(SubjectCategory.LITERATURE), SubjectArtHelper.themeColor(SubjectCategory.LOCAL_EDUCATION))
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
    fun testNonCurriculumSubjects_ClassifyAsOther() {
        val category = SubjectArtHelper.category("Quản trị mạng")
        assertEquals(SubjectCategory.OTHER, category)

        val econCategory = SubjectArtHelper.category("Kinh tế học đại cương")
        assertEquals(SubjectCategory.OTHER, econCategory)

        val artCategory = SubjectArtHelper.category("Mỹ thuật và Thiết kế")
        assertEquals(SubjectCategory.OTHER, artCategory)
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
        assertEquals(SubjectCategory.HISTORY, SubjectArtHelper.category("Su 11"))
        assertEquals(SubjectCategory.OTHER, SubjectArtHelper.category("Dia 10"))

        val diaTheme = SubjectArtHelper.theme("Dia 10")
        assertEquals("DIA", diaTheme.badgeCode)
    }

    @Test
    fun testHistoryBadgeAndGeographyFallback() {
        // Course has "Lịch sử" but also "Địa điểm" - badge must be "SỬ"
        val courseWithLocation = "Lịch sử 12 - Địa điểm P.301"
        assertEquals(SubjectCategory.HISTORY, SubjectArtHelper.category(courseWithLocation))
        assertEquals("SỬ", SubjectArtHelper.badgeCode(courseWithLocation))

        // Course with "Địa chỉ" in history
        val courseWithAddress = "Lịch sử 10 - Địa chỉ lớp học"
        assertEquals(SubjectCategory.HISTORY, SubjectArtHelper.category(courseWithAddress))
        assertEquals("SỬ", SubjectArtHelper.badgeCode(courseWithAddress))

        // Non-curriculum Geography courses fall into OTHER with clean prefix badge
        assertEquals("ĐỊA", SubjectArtHelper.badgeCode("Địa lý 12"))
        assertEquals("ĐỊA", SubjectArtHelper.badgeCode("Địa lí 11"))
        assertEquals("MÔN", SubjectArtHelper.badgeCode("Môn Địa 10 - Địa điểm phòng 101"))
        assertEquals("DIA", SubjectArtHelper.badgeCode("Dia ly 12"))
    }

    @Test
    fun testHomeroomClassWithSpecificAssignmentTitle() {
        // High school homeroom class "11 Tin" should not force Physics/Math/Local assignments into Computer Science
        assertEquals(SubjectCategory.PHYSICS, SubjectArtHelper.category("11 Tin", "Lý (tuần 10)"))
        assertEquals("LÝ", SubjectArtHelper.badgeCode(SubjectCategory.PHYSICS, "11 Tin", "Lý (tuần 10)"))

        assertEquals(SubjectCategory.MATH, SubjectArtHelper.category("11 Tin", "Toán (tuần 7)"))
        assertEquals("TOÁN", SubjectArtHelper.badgeCode(SubjectCategory.MATH, "11 Tin", "Toán (tuần 7)"))

        assertEquals(SubjectCategory.LOCAL_EDUCATION, SubjectArtHelper.category("11 Tin", "GDDP (tuần 8)"))
        assertEquals("GDĐP", SubjectArtHelper.badgeCode(SubjectCategory.LOCAL_EDUCATION, "11 Tin", "GDDP (tuần 8)"))

        assertEquals(SubjectCategory.DEFENSE_EDUCATION, SubjectArtHelper.category("11 Tin", "GDQP (tuần 9)"))
        assertEquals("GDQP", SubjectArtHelper.badgeCode(SubjectCategory.DEFENSE_EDUCATION, "11 Tin", "GDQP (tuần 9)"))

        assertEquals(SubjectCategory.EXPERIENTIAL_ACTIVITIES, SubjectArtHelper.category("11 Tin", "HDTN (tuần 10)"))
        assertEquals("HĐTN", SubjectArtHelper.badgeCode(SubjectCategory.EXPERIENTIAL_ACTIVITIES, "11 Tin", "HDTN (tuần 10)"))
    }
}
