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

private const val FLAG_MATH = 1 shl 0
private const val FLAG_CS = 1 shl 1
private const val FLAG_NETWORKING = 1 shl 2
private const val FLAG_BIO = 1 shl 3
private const val FLAG_CHEM = 1 shl 4
private const val FLAG_LIT = 1 shl 5
private const val FLAG_ENG = 1 shl 6
private const val FLAG_DESIGN = 1 shl 7
private const val FLAG_ASSIGNMENT = 1 shl 8
private const val FLAG_PHYSICS = 1 shl 9
private const val FLAG_LY = 1 shl 10
private const val FLAG_HOA = 1 shl 11
private const val FLAG_SINH = 1 shl 12
private const val FLAG_SU = 1 shl 13
private const val FLAG_DIA = 1 shl 14
private const val FLAG_VAN = 1 shl 15
private const val FLAG_ANH = 1 shl 16
private const val FLAG_GDCD = 1 shl 17
private const val FLAG_LAW = 1 shl 18
private const val FLAG_TRIET = 1 shl 19
private const val FLAG_MANG = 1 shl 20
private const val FLAG_CLOUD = 1 shl 21
private const val FLAG_SOUNDCLOUD = 1 shl 22
private const val FLAG_ECON = 1 shl 23
private const val FLAG_VE = 1 shl 24
private const val FLAG_TIN = 1 shl 25
private const val FLAG_TU = 1 shl 26
private const val FLAG_HISTORY = 1 shl 27
private const val FLAG_GEOGRAPHY = 1 shl 28

private val TOKEN_FLAG_MAP: Map<String, Int> = run {
    val map = HashMap<String, Int>(128)
    fun add(words: Array<String>, flag: Int) {
        for (w in words) {
            map[w] = (map[w] ?: 0) or flag
        }
    }
    fun add(word: String, flag: Int) {
        map[word] = (map[word] ?: 0) or flag
    }
    add(arrayOf("toan", "math", "maths", "calculus", "algebra", "geometry", "trigonometry", "statistics", "discrete"), FLAG_MATH)
    add(arrayOf("android", "ios", "swift", "python", "java", "cntt", "it", "ctdl", "cpp", "kotlin", "javascript", "typescript"), FLAG_CS)
    add(arrayOf("network", "networking", "tcp", "socket", "cybersecurity"), FLAG_NETWORKING)
    add(arrayOf("biology", "bio", "genetics", "ecology"), FLAG_BIO)
    add(arrayOf("chemistry", "chem", "biochemistry"), FLAG_CHEM)
    add(arrayOf("literature", "writing", "essay"), FLAG_LIT)
    add(arrayOf("english", "ielts", "toeic", "toefl"), FLAG_ENG)
    add(arrayOf("design", "ui", "ux", "art"), FLAG_DESIGN)
    add(arrayOf("lab", "project"), FLAG_ASSIGNMENT)
    add(arrayOf("physics", "mechanics", "thermodynamics", "optics"), FLAG_PHYSICS)
    add("history", FLAG_HISTORY)
    add("geography", FLAG_GEOGRAPHY)
    add("gdcd", FLAG_GDCD)
    add("law", FLAG_LAW)
    add(arrayOf("business", "economics"), FLAG_ECON)
    add(arrayOf("ly", "lý", "lí"), FLAG_LY)
    add(arrayOf("hoa", "hóa", "hoá"), FLAG_HOA)
    add("sinh", FLAG_SINH)
    add(arrayOf("su", "sử"), FLAG_SU)
    add(arrayOf("dia", "địa"), FLAG_DIA)
    add(arrayOf("van", "văn"), FLAG_VAN)
    add("anh", FLAG_ANH)
    add("triết", FLAG_TRIET)
    add(arrayOf("mạng", "mang"), FLAG_MANG)
    add("cloud", FLAG_CLOUD)
    add("soundcloud", FLAG_SOUNDCLOUD)
    add("tin", FLAG_TIN)
    add("tự", FLAG_TU)
    add("vẽ", FLAG_VE)
    map
}

private fun scanTokenFlags(text: String): Int {
    val len = text.length
    if (len == 0) return 0
    var flags = 0
    var start = -1
    for (i in 0 until len) {
        val ch = text[i]
        val isWordChar = (ch in 'a'..'z') || (ch in '0'..'9') || (ch > '\u007F' && Character.isLetterOrDigit(ch))
        if (isWordChar) {
            if (start == -1) start = i
        } else {
            if (start != -1) {
                val tokenLen = i - start
                if (tokenLen <= 14) {
                    val token = text.substring(start, i)
                    val f = TOKEN_FLAG_MAP[token]
                    if (f != null) flags = flags or f
                }
                start = -1
            }
        }
    }
    if (start != -1) {
        val tokenLen = len - start
        if (tokenLen <= 14) {
            val token = text.substring(start, len)
            val f = TOKEN_FLAG_MAP[token]
            if (f != null) flags = flags or f
        }
    }
    return flags
}

object SubjectArtHelper {
    private const val MAX_CACHE_SIZE = 16384
    private val courseCategoryCache = java.util.concurrent.ConcurrentHashMap<String, SubjectCategory>()
    private val compoundCategoryCache = java.util.concurrent.ConcurrentHashMap<String, SubjectCategory>()
    private val themeCache = java.util.concurrent.ConcurrentHashMap<String, SubjectTheme>()

    fun clearCaches() {
        courseCategoryCache.clear()
        compoundCategoryCache.clear()
        themeCache.clear()
    }

    private val STANDARD_THEMES: Array<SubjectTheme> = Array(SubjectCategory.values().size) { idx ->
        val cat = SubjectCategory.values()[idx]
        SubjectTheme(
            category = cat,
            color = themeColor(cat),
            badgeCode = badgeCode(cat, "", null),
            iconRes = iconForCategory(cat)
        )
    }

    fun category(courseName: String, title: String? = null): SubjectCategory {
        val courseCat = courseCategoryCache[courseName]
        if (courseCat != null) {
            if (title == null || courseCat != SubjectCategory.OTHER || title.isBlank()) {
                return courseCat
            }
            val key = "$courseName|$title"
            return compoundCategoryCache[key] ?: run {
                val computed = computeCategory(courseName, title)
                if (compoundCategoryCache.size >= MAX_CACHE_SIZE) {
                    compoundCategoryCache.clear()
                }
                compoundCategoryCache[key] = computed
                computed
            }
        }
        val computed = computeCategory(courseName, null)
        if (courseCategoryCache.size >= MAX_CACHE_SIZE) {
            courseCategoryCache.clear()
        }
        courseCategoryCache[courseName] = computed
        if (title == null || computed != SubjectCategory.OTHER || title.isBlank()) {
            return computed
        }
        val key = "$courseName|$title"
        return compoundCategoryCache[key] ?: run {
            val compoundComputed = computeCategory(courseName, title)
            if (compoundCategoryCache.size >= MAX_CACHE_SIZE) {
                compoundCategoryCache.clear()
            }
            compoundCategoryCache[key] = compoundComputed
            compoundComputed
        }
    }

    fun theme(courseName: String, title: String? = null): SubjectTheme {
        val cat = category(courseName, title)
        if (cat != SubjectCategory.HISTORY_OR_GEOGRAPHY && cat != SubjectCategory.OTHER) {
            return STANDARD_THEMES[cat.ordinal]
        }
        val hasTitle = !title.isNullOrBlank()
        val key = if (hasTitle) "$courseName|$title" else courseName
        val cached = themeCache[key]
        if (cached != null) return cached

        val theme = SubjectTheme(
            category = cat,
            color = themeColor(cat),
            badgeCode = badgeCode(cat, courseName, title),
            iconRes = iconForCategory(cat)
        )
        if (themeCache.size >= MAX_CACHE_SIZE) {
            themeCache.clear()
        }
        themeCache[key] = theme
        return theme
    }

    private fun computeCategory(courseName: String, title: String? = null): SubjectCategory {
        val courseLower = courseName.lowercase()
        val courseFlags = scanTokenFlags(courseLower)

        fun match(text: String, flags: Int): SubjectCategory? {
            return when {
                !text.contains("điện toán") && (text.contains("toán") || (flags and FLAG_MATH != 0) ||
                        text.contains("giải tích") || text.contains("đại số") || text.contains("hình học") ||
                        text.contains("xác suất") || text.contains("lượng giác") || text.contains("đạo hàm") ||
                        text.contains("tích phân") || text.contains("toán cao cấp") || text.contains("toán rời rạc") ||
                        text.contains("thống kê") || text.contains("vi phân") || text.contains("ma trận")) -> SubjectCategory.MATH

                text.contains("vật lý") || text.contains("vật lí") || (flags and FLAG_PHYSICS != 0) ||
                        text.contains("môn lý") || text.contains("môn lí") || text.contains("sbt lý") || text.contains("sbt lí") ||
                        text.contains("cơ học") || text.contains("nhiệt học") || text.contains("quang học") ||
                        text.contains("điện từ") || text.contains("vật lý đại cương") || text.contains("vật lí đại cương") ||
                        text.contains("dao động") || text.contains("sóng cơ") ||
                        ((flags and FLAG_LY != 0) && !text.contains("quản lý") && !text.contains("quản lí") &&
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
                        (flags and FLAG_CHEM != 0) ||
                        ((flags and FLAG_HOA != 0) && !text.contains("tự động hóa") && !text.contains("tự động hoá") &&
                                !text.contains("tiến hóa") && !text.contains("tiến hoá") &&
                                !text.contains("tiêu hóa") && !text.contains("tiêu hoá") &&
                                !text.contains("hóa đơn") && !text.contains("hoá đơn") &&
                                !text.contains("văn hóa") && !text.contains("văn hoá") &&
                                !text.contains("tối ưu hóa") && !text.contains("tối ưu hoá") &&
                                !text.contains("chuẩn hóa") && !text.contains("chuẩn hoá") &&
                                !text.contains("công nghiệp hóa") && !text.contains("công nghiệp hoá") &&
                                !text.contains("hiện đại hóa") && !text.contains("hiện đại hoá") &&
                                !text.contains("ảo hóa") && !text.contains("ảo hoá") &&
                                !text.contains("số hóa") && !text.contains("số hoá")) -> SubjectCategory.CHEMISTRY

                text.contains("sinh học") || text.contains("môn sinh") || (flags and FLAG_BIO != 0) ||
                        text.contains("y học") || text.contains("di truyền") || text.contains("tế bào") ||
                        text.contains("vi sinh") || text.contains("sinh thái") || text.contains("tiêu hóa") || text.contains("tiêu hoá") ||
                        ((flags and FLAG_SINH != 0) && !text.contains("học sinh") &&
                                !text.contains("sinh viên") && !text.contains("sinh hoạt")) -> SubjectCategory.BIOLOGY

                text.contains("lịch sử") || (flags and FLAG_HISTORY != 0) ||
                        (((flags and FLAG_SU != 0)) && !text.contains("sử dụng") && !text.contains("lịch sự")) ||
                        text.contains("địa lý") || text.contains("địa lí") || (flags and FLAG_GEOGRAPHY != 0) ||
                        (((flags and FLAG_DIA != 0)) && !text.contains("địa chỉ") && !text.contains("địa điểm")) -> SubjectCategory.HISTORY_OR_GEOGRAPHY

                text.contains("ngữ văn") || text.contains("tiếng việt") || (flags and FLAG_LIT != 0) ||
                        (((flags and FLAG_VAN != 0)) && !text.contains("văn phòng") && !text.contains("văn hóa") && !text.contains("văn hoá") && !text.contains("văn minh") && !text.contains("văn bản") && !text.contains("luận văn")) -> SubjectCategory.LITERATURE

                text.contains("tiếng anh") || (flags and FLAG_ENG != 0) ||
                        ((flags and FLAG_ANH != 0) && !text.contains("hình ảnh") && !text.contains("âm thanh") && !text.contains("thầy") && !text.contains("cô") && !text.contains("gv")) -> SubjectCategory.ENGLISH

                (flags and FLAG_GDCD != 0) || text.contains("triết học") || text.contains("chính trị") ||
                        text.contains("pháp luật") || text.contains("kinh tế và pháp luật") || (flags and FLAG_LAW != 0) ||
                        text.contains("tư tưởng") || text.contains("mác - lênin") || text.contains("mác lênin") ||
                        text.contains("tư tưởng hồ chí minh") || text.contains("pháp luật đại cương") ||
                        ((flags and FLAG_TRIET != 0) && !text.contains("triết lý")) -> SubjectCategory.CIVICS_OR_PHILOSOPHY

                text.contains("an ninh mạng") || text.contains("mạng máy tính") ||
                        text.contains("an toàn thông tin") || text.contains("hệ thống phân tán") || text.contains("quản trị mạng") ||
                        (flags and FLAG_NETWORKING != 0) ||
                        ((flags and FLAG_MANG != 0) && !text.contains("mạng xã hội")) ||
                        ((flags and FLAG_CLOUD != 0) && (flags and FLAG_SOUNDCLOUD == 0)) -> SubjectCategory.NETWORKING

                !text.contains("quản trị mạng") && (text.contains("kinh tế") || text.contains("quản trị") || text.contains("tài chính") ||
                        text.contains("marketing") || text.contains("kế toán") || (flags and FLAG_ECON != 0)) -> SubjectCategory.ECONOMICS

                text.contains("đồ họa") || text.contains("thiết kế") || text.contains("mỹ thuật") ||
                        (flags and FLAG_DESIGN != 0) || ((flags and FLAG_VE != 0) && !text.contains("bản vẽ kỹ thuật")) -> SubjectCategory.ART_AND_DESIGN

                text.contains("lập trình") || text.contains("tin học") || text.contains("di động") ||
                        (flags and FLAG_CS != 0) ||
                        text.contains("công nghệ thông tin") || text.contains("thuật toán") ||
                        text.contains("cơ sở dữ liệu") || text.contains("khoa học máy tính") ||
                        text.contains("cấu trúc dữ liệu") ||
                        text.contains("trí tuệ nhân tạo") || text.contains("machine learning") ||
                        text.contains("hệ điều hành") || text.contains("kiến trúc máy tính") ||
                        ((flags and FLAG_TIN != 0) && !text.contains("thông tin") && !text.contains("bản tin") && !text.contains("tin tức") && !text.contains("niềm tin") && (flags and FLAG_TU == 0)) -> SubjectCategory.COMPUTER_SCIENCE

                text.contains("nhiệm vụ") || (flags and FLAG_ASSIGNMENT != 0) || text.contains("thực hành") ||
                        text.contains("bài tập") || text.contains("dự án") -> SubjectCategory.GENERAL_ASSIGNMENT

                else -> null
            }
        }

        match(courseLower, courseFlags)?.let { return it }

        if (!title.isNullOrBlank()) {
            val titleLower = title.lowercase()
            val titleFlags = scanTokenFlags(titleLower)
            match(titleLower, titleFlags)?.let { return it }
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

    fun badgeCode(courseName: String, title: String? = null): String {
        val cat = category(courseName, title)
        return badgeCode(cat, courseName, title)
    }
}
