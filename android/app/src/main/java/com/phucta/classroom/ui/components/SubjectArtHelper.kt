package com.phucta.classroom.ui.components

import androidx.annotation.DrawableRes
import androidx.compose.runtime.Immutable
import androidx.compose.ui.graphics.Color
import com.phucta.classroom.R

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

@Immutable
data class SubjectTheme(
    val category: SubjectCategory,
    val color: Color,
    val badgeCode: String,
    @DrawableRes val iconRes: Int = SubjectArtHelper.iconForCategory(category)
)

private val MATH_TOKENS = hashSetOf("toan", "math", "maths", "calculus", "algebra", "geometry", "trigonometry", "statistics", "discrete")
private val CS_TOKENS = hashSetOf("android", "ios", "swift", "python", "java", "cntt", "it", "ctdl", "cpp", "kotlin", "javascript", "typescript")
private val NETWORKING_TOKENS = hashSetOf("network", "networking", "tcp", "socket", "cybersecurity")
private val BIO_TOKENS = hashSetOf("biology", "bio", "genetics", "ecology")
private val CHEM_TOKENS = hashSetOf("chemistry", "chem", "biochemistry")
private val LIT_TOKENS = hashSetOf("literature", "writing", "essay")
private val ENG_TOKENS = hashSetOf("english", "ielts", "toeic", "toefl")
private val DESIGN_TOKENS = hashSetOf("design", "ui", "ux", "art")
private val ASSIGNMENT_TOKENS = hashSetOf("lab", "project")

private fun Set<String>.containsAny(targetSet: Set<String>): Boolean {
    if (this.size <= targetSet.size) {
        for (token in this) {
            if (targetSet.contains(token)) return true
        }
    } else {
        for (token in targetSet) {
            if (this.contains(token)) return true
        }
    }
    return false
}

private fun extractTokens(text: String): Set<String> {
    val len = text.length
    if (len == 0) return emptySet()
    val tokens = HashSet<String>()
    var start = -1
    for (i in 0 until len) {
        val ch = text[i]
        if (Character.isLetterOrDigit(ch)) {
            if (start == -1) {
                start = i
            }
        } else {
            if (start != -1) {
                tokens.add(text.substring(start, i))
                start = -1
            }
        }
    }
    if (start != -1) {
        tokens.add(text.substring(start, len))
    }
    return tokens
}

object SubjectArtHelper {
    private val courseCategoryCache = java.util.concurrent.ConcurrentHashMap<String, SubjectCategory>()
    private val compoundCategoryCache = java.util.concurrent.ConcurrentHashMap<String, SubjectCategory>()
    private val themeCache = java.util.concurrent.ConcurrentHashMap<String, SubjectTheme>()

    fun category(courseName: String, title: String? = null): SubjectCategory {
        val courseCat = courseCategoryCache[courseName] ?: run {
            val computed = computeCategory(courseName, null)
            courseCategoryCache[courseName] = computed
            computed
        }
        if (courseCat != SubjectCategory.OTHER || title.isNullOrBlank()) {
            return courseCat
        }
        val key = "$courseName|$title"
        return compoundCategoryCache[key] ?: run {
            val computed = computeCategory(courseName, title)
            compoundCategoryCache[key] = computed
            computed
        }
    }

    fun theme(courseName: String, title: String? = null): SubjectTheme {
        val hasTitle = !title.isNullOrBlank()
        val key = if (hasTitle) "$courseName|$title" else courseName
        val cached = themeCache[key]
        if (cached != null) return cached

        val cat = category(courseName, title)
        val theme = SubjectTheme(
            category = cat,
            color = themeColor(cat),
            badgeCode = badgeCode(cat, courseName, title),
            iconRes = iconForCategory(cat)
        )
        themeCache[key] = theme
        return theme
    }

    private fun computeCategory(courseName: String, title: String? = null): SubjectCategory {
        val courseLower = courseName.lowercase()
        val courseTokens = extractTokens(courseLower)

        fun match(text: String, tokens: Set<String>): SubjectCategory? {
            return when {
                !text.contains("điện toán") && (text.contains("toán") || tokens.containsAny(MATH_TOKENS) ||
                        text.contains("giải tích") || text.contains("đại số") || text.contains("hình học") ||
                        text.contains("xác suất") || text.contains("lượng giác") || text.contains("đạo hàm") ||
                        text.contains("tích phân") || text.contains("toán cao cấp") || text.contains("toán rời rạc") ||
                        text.contains("thống kê") || text.contains("vi phân") || text.contains("ma trận")) -> SubjectCategory.MATH

                text.contains("vật lý") || text.contains("vật lí") || tokens.contains("physics") ||
                        text.contains("môn lý") || text.contains("môn lí") || text.contains("sbt lý") || text.contains("sbt lí") ||
                        text.contains("cơ học") || text.contains("nhiệt học") || text.contains("quang học") ||
                        text.contains("điện từ") || text.contains("vật lý đại cương") || text.contains("vật lí đại cương") ||
                        text.contains("dao động") || text.contains("sóng cơ") ||
                        tokens.contains("mechanics") || tokens.contains("thermodynamics") || tokens.contains("optics") ||
                        ((tokens.contains("lý") || tokens.contains("lí") || tokens.contains("ly")) && !text.contains("quản lý") && !text.contains("quản lí") &&
                                !text.contains("xử lý") && !text.contains("xử lí") &&
                                !text.contains("tâm lý") && !text.contains("tâm lí") &&
                                !text.contains("pháp lý") && !text.contains("pháp lí") &&
                                !text.contains("địa lý") && !text.contains("địa lí") &&
                                !text.contains("triết lý") && !text.contains("triết lí") &&
                                !text.contains("lý thuyết") && !text.contains("lí thuyết") &&
                                !text.contains("lý luận") && !text.contains("lí luận") &&
                                !text.contains("lý do") && !text.contains("lí do")) -> SubjectCategory.PHYSICS

                text.contains("hóa học") || text.contains("hoá học") || text.contains("môn hóa") || text.contains("môn hoá") ||
                        text.contains("hóa hữu cơ") || text.contains("hoá hữu cơ") || text.contains("hóa vô cơ") || text.contains("hoá vô cơ") ||
                        text.contains("hóa đại cương") || text.contains("hoá đại cương") || text.contains("hóa phân tích") || text.contains("hoá phân tích") ||
                        tokens.containsAny(CHEM_TOKENS) ||
                        ((tokens.contains("hóa") || tokens.contains("hoá") || tokens.contains("hoa")) && !text.contains("tự động hóa") && !text.contains("tự động hoá") &&
                                !text.contains("tiến hóa") && !text.contains("tiến hoá") &&
                                !text.contains("hóa đơn") && !text.contains("hoá đơn") &&
                                !text.contains("văn hóa") && !text.contains("văn hoá") &&
                                !text.contains("tối ưu hóa") && !text.contains("tối ưu hoá") &&
                                !text.contains("chuẩn hóa") && !text.contains("chuẩn hoá") &&
                                !text.contains("công nghiệp hóa") && !text.contains("công nghiệp hoá") &&
                                !text.contains("hiện đại hóa") && !text.contains("hiện đại hoá") &&
                                !text.contains("ảo hóa") && !text.contains("ảo hoá") &&
                                !text.contains("số hóa") && !text.contains("số hoá")) -> SubjectCategory.CHEMISTRY

                text.contains("sinh học") || text.contains("môn sinh") || tokens.containsAny(BIO_TOKENS) ||
                        text.contains("y học") || text.contains("di truyền") || text.contains("tế bào") ||
                        text.contains("vi sinh") || text.contains("sinh thái") ||
                        (tokens.contains("sinh") && !text.contains("học sinh") &&
                        !text.contains("sinh viên") && !text.contains("sinh hoạt")) -> SubjectCategory.BIOLOGY

                text.contains("lịch sử") || tokens.contains("history") ||
                        ((tokens.contains("sử") || tokens.contains("su")) && !text.contains("sử dụng") && !text.contains("lịch sự")) ||
                        text.contains("địa lý") || text.contains("địa lí") || tokens.contains("geography") ||
                        ((tokens.contains("địa") || tokens.contains("dia")) && !text.contains("địa chỉ") && !text.contains("địa điểm")) -> SubjectCategory.HISTORY_OR_GEOGRAPHY

                text.contains("ngữ văn") || text.contains("tiếng việt") || tokens.containsAny(LIT_TOKENS) ||
                        ((tokens.contains("văn") || tokens.contains("van")) && !text.contains("văn phòng") && !text.contains("văn hóa") && !text.contains("văn hoá") && !text.contains("văn minh") && !text.contains("văn bản") && !text.contains("luận văn")) -> SubjectCategory.LITERATURE

                text.contains("tiếng anh") || tokens.containsAny(ENG_TOKENS) ||
                        (tokens.contains("anh") && !text.contains("hình ảnh") && !text.contains("âm thanh") && !text.contains("thầy") && !text.contains("cô") && !text.contains("gv")) -> SubjectCategory.ENGLISH

                tokens.contains("gdcd") || text.contains("triết học") || text.contains("chính trị") ||
                        text.contains("pháp luật") || text.contains("kinh tế và pháp luật") || tokens.contains("law") ||
                        text.contains("tư tưởng") || text.contains("mác - lênin") || text.contains("mác lênin") ||
                        text.contains("tư tưởng hồ chí minh") || text.contains("pháp luật đại cương") ||
                        (tokens.contains("triết") && !text.contains("triết lý")) -> SubjectCategory.CIVICS_OR_PHILOSOPHY

                text.contains("an ninh mạng") || text.contains("mạng máy tính") ||
                        text.contains("an toàn thông tin") || text.contains("hệ thống phân tán") || text.contains("quản trị mạng") ||
                        tokens.containsAny(NETWORKING_TOKENS) ||
                        (tokens.contains("mạng") && !text.contains("mạng xã hội")) ||
                        (tokens.contains("cloud") && !tokens.contains("soundcloud")) -> SubjectCategory.NETWORKING

                !text.contains("quản trị mạng") && (text.contains("kinh tế") || text.contains("quản trị") || text.contains("tài chính") ||
                        text.contains("marketing") || text.contains("kế toán") || tokens.contains("business") ||
                        tokens.contains("economics")) -> SubjectCategory.ECONOMICS

                text.contains("đồ họa") || text.contains("thiết kế") || text.contains("mỹ thuật") ||
                        tokens.containsAny(DESIGN_TOKENS) || (tokens.contains("vẽ") && !text.contains("bản vẽ kỹ thuật")) -> SubjectCategory.ART_AND_DESIGN

                text.contains("lập trình") || text.contains("tin học") || text.contains("di động") ||
                        tokens.containsAny(CS_TOKENS) ||
                        text.contains("công nghệ thông tin") || text.contains("thuật toán") ||
                        text.contains("cơ sở dữ liệu") || text.contains("khoa học máy tính") ||
                        text.contains("cấu trúc dữ liệu") ||
                        text.contains("trí tuệ nhân tạo") || text.contains("machine learning") ||
                        text.contains("hệ điều hành") || text.contains("kiến trúc máy tính") ||
                        (tokens.contains("tin") && !text.contains("thông tin") && !text.contains("bản tin") && !text.contains("tin tức") && !text.contains("niềm tin") && !tokens.contains("tự")) -> SubjectCategory.COMPUTER_SCIENCE

                text.contains("nhiệm vụ") || tokens.containsAny(ASSIGNMENT_TOKENS) || text.contains("thực hành") ||
                        text.contains("bài tập") || text.contains("dự án") -> SubjectCategory.GENERAL_ASSIGNMENT

                else -> null
            }
        }

        match(courseLower, courseTokens)?.let { return it }

        if (!title.isNullOrBlank()) {
            val titleLower = title.lowercase()
            val titleTokens = extractTokens(titleLower)
            match(titleLower, titleTokens)?.let { return it }
        }

        return SubjectCategory.OTHER
    }

    fun themeColor(category: SubjectCategory): Color {
        return when (category) {
            SubjectCategory.MATH -> Color(0xFFF2991A)
            SubjectCategory.LITERATURE -> Color(0xFFEB6138)
            SubjectCategory.ENGLISH -> Color(0xFF2694EB)
            SubjectCategory.PHYSICS -> Color(0xFF7361E0)
            SubjectCategory.CHEMISTRY -> Color(0xFFDC47AD)
            SubjectCategory.BIOLOGY -> Color(0xFF33B866)
            SubjectCategory.HISTORY_OR_GEOGRAPHY -> Color(0xFFD98529)
            SubjectCategory.COMPUTER_SCIENCE -> Color(0xFF14AD8A)
            SubjectCategory.NETWORKING -> Color(0xFF8C66EB)
            SubjectCategory.CIVICS_OR_PHILOSOPHY -> Color(0xFFE04752)
            SubjectCategory.ECONOMICS -> Color(0xFFE6A61F)
            SubjectCategory.ART_AND_DESIGN -> Color(0xFFE6408C)
            SubjectCategory.GENERAL_ASSIGNMENT -> Color(0xFF7A6BD6)
            SubjectCategory.OTHER -> Color(0xFF6685A3)
        }
    }

    @DrawableRes
    fun iconForCategory(category: SubjectCategory): Int {
        return when (category) {
            SubjectCategory.MATH -> R.drawable.ic_subject_math
            SubjectCategory.PHYSICS -> R.drawable.ic_subject_physics
            SubjectCategory.CHEMISTRY -> R.drawable.ic_subject_chemistry
            SubjectCategory.BIOLOGY -> R.drawable.ic_subject_biology
            SubjectCategory.HISTORY_OR_GEOGRAPHY -> R.drawable.ic_subject_history
            SubjectCategory.LITERATURE -> R.drawable.ic_subject_literature
            SubjectCategory.ENGLISH -> R.drawable.ic_subject_english
            SubjectCategory.CIVICS_OR_PHILOSOPHY -> R.drawable.ic_subject_civics
            SubjectCategory.ECONOMICS -> R.drawable.ic_subject_economics
            SubjectCategory.ART_AND_DESIGN -> R.drawable.ic_subject_art
            SubjectCategory.COMPUTER_SCIENCE -> R.drawable.ic_subject_cs
            SubjectCategory.NETWORKING -> R.drawable.ic_subject_networking
            SubjectCategory.GENERAL_ASSIGNMENT -> R.drawable.ic_subject_assignment
            SubjectCategory.OTHER -> R.drawable.ic_subject_other
        }
    }

    fun badgeCode(category: SubjectCategory, courseName: String = "", title: String? = null): String {
        return when (category) {
            SubjectCategory.MATH -> "TOÁ"
            SubjectCategory.PHYSICS -> "LÝ"
            SubjectCategory.CHEMISTRY -> "HOÁ"
            SubjectCategory.BIOLOGY -> "SINH"
            SubjectCategory.HISTORY_OR_GEOGRAPHY -> if (courseName.contains("địa", ignoreCase = true) || title?.contains("địa", ignoreCase = true) == true || courseName.contains("dia", ignoreCase = true) || title?.contains("dia", ignoreCase = true) == true) "ĐỊA" else "SỬ"
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
                if (cleaned.length >= 3) {
                    cleaned.take(3).uppercase()
                } else {
                    val titleCleaned = title?.trim().orEmpty()
                    if (titleCleaned.length >= 3) {
                        titleCleaned.take(3).uppercase()
                    } else if (cleaned.isNotEmpty()) {
                        cleaned.uppercase()
                    } else if (titleCleaned.isNotEmpty()) {
                        titleCleaned.uppercase()
                    } else {
                        "MÔN"
                    }
                }
            }
        }
    }
}
