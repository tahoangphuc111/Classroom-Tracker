package com.phucta.classroom.ui.components

import androidx.compose.ui.graphics.Color

enum class SubjectCategory {
    MATH,
    PHYSICS,
    CHEMISTRY,
    BIOLOGY,
    HISTORY_OR_GEOGRAPHY,
    LITERATURE,
    ENGLISH,
    CIVICS_OR_PHILOSOPHY,
    ECONOMICS,
    ART_AND_DESIGN,
    COMPUTER_SCIENCE,
    NETWORKING,
    GENERAL_ASSIGNMENT,
    OTHER
}

data class SubjectTheme(
    val category: SubjectCategory,
    val color: Color,
    val badgeCode: String
)

object SubjectArtHelper {

    private val categoryCache = mutableMapOf<String, SubjectCategory>()

    fun category(courseName: String, title: String? = null): SubjectCategory {
        val key = "$courseName|${title ?: ""}"
        synchronized(categoryCache) {
            categoryCache[key]?.let { return it }
        }

        val computed = computeCategory(courseName, title)
        synchronized(categoryCache) {
            categoryCache[key] = computed
        }
        return computed
    }

    fun theme(courseName: String, title: String? = null): SubjectTheme {
        val cat = category(courseName, title)
        return SubjectTheme(
            category = cat,
            color = themeColor(cat),
            badgeCode = badgeCode(cat, courseName)
        )
    }

    private fun computeCategory(courseName: String, title: String? = null): SubjectCategory {
        val titleLower = (title ?: "").lowercase()
        val titleTokens = titleLower.split(Regex("[^\\p{L}\\p{Nd}]+")).filter { it.isNotEmpty() }.toSet()

        val courseLower = courseName.lowercase()
        val courseTokens = courseLower.split(Regex("[^\\p{L}\\p{Nd}]+")).filter { it.isNotEmpty() }.toSet()

        fun match(text: String, tokens: Set<String>): SubjectCategory? {
            return when {
                text.contains("toán") || tokens.contains("math") || tokens.contains("maths") ||
                        text.contains("giải tích") || text.contains("đại số") || text.contains("hình học") ||
                        text.contains("xác suất") || tokens.contains("calculus") || tokens.contains("algebra") ||
                        tokens.contains("geometry") -> SubjectCategory.MATH

                text.contains("vật lý") || text.contains("vật lí") || tokens.contains("physics") ||
                        text.contains("môn lý") || text.contains("môn lí") || text.contains("sbt lý") || text.contains("sbt lí") ||
                        ((tokens.contains("lý") || tokens.contains("lí")) && !text.contains("quản lý") && !text.contains("quản lí") &&
                                !text.contains("xử lý") && !text.contains("xử lí") &&
                                !text.contains("tâm lý") && !text.contains("tâm lí") &&
                                !text.contains("pháp lý") && !text.contains("pháp lí") &&
                                !text.contains("địa lý") && !text.contains("địa lí") &&
                                !text.contains("triết lý") && !text.contains("triết lí") &&
                                !text.contains("lý thuyết") && !text.contains("lí thuyết") &&
                                !text.contains("lý do") && !text.contains("lí do")) -> SubjectCategory.PHYSICS

                text.contains("hóa học") || text.contains("hoá học") || text.contains("môn hóa") || text.contains("môn hoá") ||
                        tokens.contains("chemistry") || tokens.contains("chem") ||
                        ((tokens.contains("hóa") || tokens.contains("hoá")) && !text.contains("tự động hóa") && !text.contains("tự động hoá") &&
                                !text.contains("tiến hóa") && !text.contains("tiến hoá") &&
                                !text.contains("hóa đơn") && !text.contains("hoá đơn") &&
                                !text.contains("văn hóa") && !text.contains("văn hoá") &&
                                !text.contains("tối ưu hóa") && !text.contains("tối ưu hoá") &&
                                !text.contains("chuẩn hóa") && !text.contains("chuẩn hoá") &&
                                !text.contains("công nghiệp hóa") && !text.contains("công nghiệp hoá") &&
                                !text.contains("hiện đại hóa") && !text.contains("hiện đại hoá")) -> SubjectCategory.CHEMISTRY

                text.contains("sinh học") || text.contains("môn sinh") || tokens.contains("biology") || tokens.contains("bio") ||
                        text.contains("y học") || (tokens.contains("sinh") && !text.contains("học sinh") &&
                        !text.contains("sinh viên") && !text.contains("sinh hoạt")) -> SubjectCategory.BIOLOGY

                text.contains("lịch sử") || tokens.contains("history") ||
                        (tokens.contains("sử") && !text.contains("sử dụng") && !text.contains("lịch sự")) ||
                        text.contains("địa lý") || text.contains("địa lí") || tokens.contains("geography") ||
                        (tokens.contains("địa") && !text.contains("địa chỉ") && !text.contains("địa điểm")) -> SubjectCategory.HISTORY_OR_GEOGRAPHY

                text.contains("ngữ văn") || text.contains("tiếng việt") || tokens.contains("literature") ||
                        tokens.contains("writing") || tokens.contains("essay") ||
                        (tokens.contains("văn") && !text.contains("văn phòng") && !text.contains("văn hóa") && !text.contains("văn minh")) -> SubjectCategory.LITERATURE

                text.contains("tiếng anh") || tokens.contains("english") || tokens.contains("ielts") ||
                        tokens.contains("toeic") || tokens.contains("toefl") ||
                        (tokens.contains("anh") && !text.contains("hình ảnh") && !text.contains("âm thanh")) -> SubjectCategory.ENGLISH

                tokens.contains("gdcd") || text.contains("triết học") || text.contains("chính trị") ||
                        text.contains("pháp luật") || text.contains("kinh tế và pháp luật") || tokens.contains("law") ||
                        text.contains("tư tưởng") || (tokens.contains("triết") && !text.contains("triết lý")) -> SubjectCategory.CIVICS_OR_PHILOSOPHY

                text.contains("kinh tế") || text.contains("quản trị") || text.contains("tài chính") ||
                        text.contains("marketing") || text.contains("kế toán") || tokens.contains("business") ||
                        tokens.contains("economics") -> SubjectCategory.ECONOMICS

                text.contains("đồ họa") || text.contains("thiết kế") || text.contains("mỹ thuật") ||
                        tokens.contains("design") || tokens.contains("ui") || tokens.contains("ux") ||
                        tokens.contains("art") || (tokens.contains("vẽ") && !text.contains("bản vẽ kỹ thuật")) -> SubjectCategory.ART_AND_DESIGN

                text.contains("lập trình") || text.contains("tin học") || text.contains("di động") ||
                        tokens.contains("android") || tokens.contains("ios") || tokens.contains("swift") ||
                        tokens.contains("python") || tokens.contains("java") || tokens.contains("cntt") ||
                        text.contains("công nghệ thông tin") || tokens.contains("it") || text.contains("thuật toán") ||
                        text.contains("cơ sở dữ liệu") || text.contains("khoa học máy tính") ||
                        (tokens.contains("tin") && !text.contains("thông tin liên lạc") && !tokens.contains("tự")) -> SubjectCategory.COMPUTER_SCIENCE

                text.contains("an ninh mạng") || text.contains("mạng máy tính") ||
                        tokens.contains("network") || tokens.contains("networking") ||
                        tokens.contains("tcp") || tokens.contains("socket") ||
                        (tokens.contains("mạng") && !text.contains("mạng xã hội")) -> SubjectCategory.NETWORKING

                text.contains("nhiệm vụ") || tokens.contains("lab") || text.contains("thực hành") ||
                        text.contains("bài tập") || tokens.contains("project") || text.contains("dự án") -> SubjectCategory.GENERAL_ASSIGNMENT

                else -> null
            }
        }

        match(courseLower, courseTokens)?.let { return it }
        if (titleLower.isNotEmpty()) {
            match(titleLower, titleTokens)?.let { return it }
        }
        return SubjectCategory.OTHER
    }

    fun themeColor(category: SubjectCategory): Color {
        return when (category) {
            SubjectCategory.MATH -> Color(0xFFF2991A)
            SubjectCategory.PHYSICS -> Color(0xFF7361E0)
            SubjectCategory.CHEMISTRY -> Color(0xFFDC47AD)
            SubjectCategory.BIOLOGY -> Color(0xFF33B866)
            SubjectCategory.HISTORY_OR_GEOGRAPHY -> Color(0xFFD98529)
            SubjectCategory.LITERATURE -> Color(0xFFEB6138)
            SubjectCategory.ENGLISH -> Color(0xFF2694EB)
            SubjectCategory.CIVICS_OR_PHILOSOPHY -> Color(0xFFE04752)
            SubjectCategory.ECONOMICS -> Color(0xFFE6A61F)
            SubjectCategory.ART_AND_DESIGN -> Color(0xFFE6408C)
            SubjectCategory.COMPUTER_SCIENCE -> Color(0xFF14AD8A)
            SubjectCategory.NETWORKING -> Color(0xFF8C66EB)
            SubjectCategory.GENERAL_ASSIGNMENT -> Color(0xFF7A6BD6)
            SubjectCategory.OTHER -> Color(0xFF6685A3)
        }
    }

    private fun badgeCode(category: SubjectCategory, courseName: String): String {
        return when (category) {
            SubjectCategory.MATH -> "TOÁ"
            SubjectCategory.PHYSICS -> "LÝ"
            SubjectCategory.CHEMISTRY -> "HOÁ"
            SubjectCategory.BIOLOGY -> "SINH"
            SubjectCategory.HISTORY_OR_GEOGRAPHY -> if (courseName.contains("địa", ignoreCase = true)) "ĐỊA" else "SỬ"
            SubjectCategory.LITERATURE -> "VĂN"
            SubjectCategory.ENGLISH -> "ANH"
            SubjectCategory.CIVICS_OR_PHILOSOPHY -> "GDCD"
            SubjectCategory.ECONOMICS -> "KTẾ"
            SubjectCategory.ART_AND_DESIGN -> "TKẾ"
            SubjectCategory.COMPUTER_SCIENCE -> "TIN"
            SubjectCategory.NETWORKING -> "MẠNG"
            SubjectCategory.GENERAL_ASSIGNMENT -> "BTH"
            SubjectCategory.OTHER -> {
                val cleaned = courseName.trim()
                if (cleaned.length >= 3) cleaned.take(3).uppercase() else "MÔN"
            }
        }
    }
}
