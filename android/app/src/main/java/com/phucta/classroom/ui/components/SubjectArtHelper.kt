package com.phucta.classroom.ui.components

import androidx.annotation.DrawableRes
import androidx.compose.runtime.Immutable
import androidx.compose.ui.graphics.Color
import com.phucta.classroom.R

enum class SubjectCategory {
    COMPUTER_SCIENCE,
    MATH,
    ENGLISH,
    LITERATURE,
    PHYSICS,
    CHEMISTRY,
    BIOLOGY,
    HISTORY,
    DEFENSE_EDUCATION,
    LOCAL_EDUCATION,
    EXPERIENTIAL_ACTIVITIES,
    OTHER
}

@Immutable
data class SubjectTheme(
    val category: SubjectCategory,
    val color: Color,
    val badgeCode: String,
    @DrawableRes val iconRes: Int = SubjectArtHelper.iconForCategory(category),
    val textColor: Color = SubjectArtHelper.accessibleTextColor(category),
    val backgroundColor: Color = color.copy(alpha = 0.12f),
    val borderColor: Color = color.copy(alpha = 0.28f)
)

private const val FLAG_MATH = 1 shl 0
private const val FLAG_CS = 1 shl 1
private const val FLAG_BIO = 1 shl 2
private const val FLAG_CHEM = 1 shl 3
private const val FLAG_LIT = 1 shl 4
private const val FLAG_ENG = 1 shl 5
private const val FLAG_PHYSICS = 1 shl 6
private const val FLAG_HISTORY = 1 shl 7
private const val FLAG_DEFENSE = 1 shl 8
private const val FLAG_LOCAL = 1 shl 9
private const val FLAG_EXPERIENTIAL = 1 shl 10

private const val FLAG_LY = 1 shl 11
private const val FLAG_HOA = 1 shl 12
private const val FLAG_SINH = 1 shl 13
private const val FLAG_SU = 1 shl 14
private const val FLAG_VAN = 1 shl 15
private const val FLAG_ANH = 1 shl 16
private const val FLAG_TIN = 1 shl 17
private const val FLAG_TU = 1 shl 18

private val TOKEN_FLAG_MAP: Map<String, Int> = run {
    val map = HashMap<String, Int>(64)
    fun add(words: Array<String>, flag: Int) {
        for (w in words) {
            map[w] = (map[w] ?: 0) or flag
        }
    }
    fun add(word: String, flag: Int) {
        map[word] = (map[word] ?: 0) or flag
    }
    add(arrayOf("toan", "toán", "math", "maths", "calculus", "algebra", "geometry", "trigonometry", "statistics", "discrete"), FLAG_MATH)
    add(arrayOf("android", "ios", "swift", "python", "java", "cntt", "it", "ctdl", "cpp", "kotlin", "javascript", "typescript"), FLAG_CS)
    add(arrayOf("biology", "bio", "genetics", "ecology"), FLAG_BIO)
    add(arrayOf("chemistry", "chem", "biochemistry"), FLAG_CHEM)
    add(arrayOf("literature", "writing", "essay"), FLAG_LIT)
    add(arrayOf("english", "ielts", "toeic", "toefl"), FLAG_ENG)
    add(arrayOf("physics", "mechanics", "thermodynamics", "optics"), FLAG_PHYSICS)
    add("history", FLAG_HISTORY)
    add(arrayOf("ly", "lý", "lí"), FLAG_LY)
    add(arrayOf("hoa", "hóa", "hoá"), FLAG_HOA)
    add("sinh", FLAG_SINH)
    add(arrayOf("su", "sử"), FLAG_SU)
    add(arrayOf("van", "văn"), FLAG_VAN)
    add("anh", FLAG_ANH)
    add("tin", FLAG_TIN)
    add(arrayOf("tự", "tu"), FLAG_TU)
    add("gdqp", FLAG_DEFENSE)
    add(arrayOf("gddp", "gdđp"), FLAG_LOCAL)
    add(arrayOf("hdtn", "hđtn"), FLAG_EXPERIENTIAL)
    map
}

private class TokenTrieNode {
    var flag: Int = 0
    val children = java.util.HashMap<Char, TokenTrieNode>()
}

private val TOKEN_TRIE: TokenTrieNode = run {
    val root = TokenTrieNode()
    fun insert(word: String, flag: Int) {
        val nfc = if (java.text.Normalizer.isNormalized(word, java.text.Normalizer.Form.NFC)) {
            word
        } else {
            java.text.Normalizer.normalize(word, java.text.Normalizer.Form.NFC)
        }
        var curr = root
        for (i in 0 until nfc.length) {
            val c = nfc[i]
            var child = curr.children[c]
            if (child == null) {
                child = TokenTrieNode()
                curr.children[c] = child
            }
            curr = child
        }
        curr.flag = curr.flag or flag
    }
    for ((word, flag) in TOKEN_FLAG_MAP) {
        insert(word, flag)
    }
    root
}

private fun lookupTokenFlag(text: String, start: Int, end: Int): Int {
    var curr = TOKEN_TRIE
    for (i in start until end) {
        val next = curr.children[text[i]] ?: return 0
        curr = next
    }
    return curr.flag
}

private fun scanTokenFlags(text: String): Int {
    val len = text.length
    if (len == 0) return 0
    var flags = 0
    var start = -1
    for (i in 0 until len) {
        val ch = text[i]
        val isWordChar = (ch in 'a'..'z') || (ch in '0'..'9') ||
            (ch > '\u007F' && (Character.isLetterOrDigit(ch) ||
                Character.getType(ch) == Character.NON_SPACING_MARK.toInt() ||
                Character.getType(ch) == Character.COMBINING_SPACING_MARK.toInt()))
        if (isWordChar) {
            if (start == -1) start = i
        } else {
            if (start != -1) {
                val tokenLen = i - start
                if (tokenLen in 2..20) {
                    flags = flags or lookupTokenFlag(text, start, i)
                }
                start = -1
            }
        }
    }
    if (start != -1) {
        val tokenLen = len - start
        if (tokenLen in 2..20) {
            flags = flags or lookupTokenFlag(text, start, len)
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
        if (!title.isNullOrBlank()) {
            val key = "$courseName|$title"
            val cached = compoundCategoryCache[key]
            if (cached != null) return cached
            val computed = computeCategory(courseName, title)
            if (compoundCategoryCache.size >= MAX_CACHE_SIZE) {
                compoundCategoryCache.clear()
            }
            compoundCategoryCache[key] = computed
            return computed
        }

        val cached = courseCategoryCache[courseName]
        if (cached != null) return cached
        val computed = computeCategory(courseName, null)
        if (courseCategoryCache.size >= MAX_CACHE_SIZE) {
            courseCategoryCache.clear()
        }
        courseCategoryCache[courseName] = computed
        return computed
    }

    fun theme(courseName: String, title: String? = null): SubjectTheme {
        val cat = category(courseName, title)
        if (cat != SubjectCategory.OTHER) {
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
        val courseNormalized = if (java.text.Normalizer.isNormalized(courseName, java.text.Normalizer.Form.NFC)) {
            courseName
        } else {
            java.text.Normalizer.normalize(courseName, java.text.Normalizer.Form.NFC)
        }
        val courseLower = courseNormalized.lowercase()
        val courseFlags = scanTokenFlags(courseLower)

        fun match(text: String, flags: Int): SubjectCategory? {
            return when {
                ((flags and FLAG_MATH != 0) || text.contains("toán") ||
                        text.contains("giải tích") || text.contains("giai tich") ||
                        text.contains("đại số") || text.contains("dai so") ||
                        text.contains("hình học") || text.contains("hinh hoc") ||
                        text.contains("xác suất") || text.contains("xac suat") ||
                        text.contains("lượng giác") || text.contains("luong giac") ||
                        text.contains("đạo hàm") || text.contains("dao ham") ||
                        text.contains("tích phân") || text.contains("tich phan") ||
                        text.contains("toán cao cấp") || text.contains("toan cao cap") ||
                        text.contains("toán rời rạc") || text.contains("toan roi rac") ||
                        text.contains("thống kê") || text.contains("thong ke") ||
                        text.contains("vi phân") || text.contains("vi phan") ||
                        text.contains("ma trận") || text.contains("ma tran")) &&
                        !text.contains("điện toán") && !text.contains("dien toan") &&
                        !text.contains("an toàn") && !text.contains("an toan") &&
                        !text.contains("thanh toán") && !text.contains("thanh toan") &&
                        !text.contains("hoàn toàn") && !text.contains("hoan toan") -> SubjectCategory.MATH

                text.contains("vật lý") || text.contains("vật lí") || text.contains("vat ly") || text.contains("vat li") || (flags and FLAG_PHYSICS != 0) ||
                        text.contains("môn lý") || text.contains("môn lí") || text.contains("mon ly") || text.contains("mon li") ||
                        text.contains("sbt lý") || text.contains("sbt lí") || text.contains("sbt ly") || text.contains("sbt li") ||
                        text.contains("cơ học") || text.contains("co hoc") || text.contains("nhiệt học") || text.contains("nhiet hoc") ||
                        text.contains("quang học") || text.contains("quang hoc") ||
                        text.contains("điện từ") || text.contains("dien tu") ||
                        text.contains("vật lý đại cương") || text.contains("vật lí đại cương") || text.contains("vat ly dai cuong") || text.contains("vat li dai cuong") ||
                        text.contains("dao động") || text.contains("dao dong") || text.contains("sóng cơ") || text.contains("song co") ||
                        ((flags and FLAG_LY != 0) &&
                                !text.contains("quản lý") && !text.contains("quản lí") && !text.contains("quan ly") && !text.contains("quan li") &&
                                !text.contains("xử lý") && !text.contains("xử lí") && !text.contains("xu ly") && !text.contains("xu li") &&
                                !text.contains("tâm lý") && !text.contains("tâm lí") && !text.contains("tam ly") && !text.contains("tam li") &&
                                !text.contains("pháp lý") && !text.contains("pháp lí") && !text.contains("phap ly") && !text.contains("phap li") &&
                                !text.contains("địa lý") && !text.contains("địa lí") && !text.contains("dia ly") && !text.contains("dia li") &&
                                !text.contains("triết lý") && !text.contains("triết lí") && !text.contains("triet ly") && !text.contains("triet li") &&
                                !text.contains("lý thuyết") && !text.contains("lí thuyết") && !text.contains("ly thuyet") && !text.contains("li thuyet") &&
                                !text.contains("lý luận") && !text.contains("lí luận") && !text.contains("ly luan") && !text.contains("li luan") &&
                                !text.contains("lý do") && !text.contains("lí do") && !text.contains("ly do") && !text.contains("li do") &&
                                !text.contains("hợp lý") && !text.contains("hợp lí") && !text.contains("hop ly") && !text.contains("hop li") &&
                                !text.contains("đại lý") && !text.contains("đại lí") && !text.contains("dai ly") && !text.contains("dai li")) -> SubjectCategory.PHYSICS

                text.contains("hóa học") || text.contains("hoá học") || text.contains("hoa hoc") ||
                        text.contains("môn hóa") || text.contains("môn hoá") || text.contains("mon hoa") ||
                        text.contains("hóa hữu cơ") || text.contains("hoá hữu cơ") || text.contains("hoa huu co") ||
                        text.contains("hóa vô cơ") || text.contains("hoá vô cơ") || text.contains("hoa vo co") ||
                        text.contains("hóa đại cương") || text.contains("hoá đại cương") || text.contains("hoa dai cuong") ||
                        text.contains("hóa phân tích") || text.contains("hoá phân tích") || text.contains("hoa phan tich") ||
                        (flags and FLAG_CHEM != 0) ||
                        ((flags and FLAG_HOA != 0) &&
                                !text.contains("tự động hóa") && !text.contains("tự động hoá") && !text.contains("tu dong hoa") &&
                                !text.contains("tiến hóa") && !text.contains("tiến hoá") && !text.contains("tien hoa") &&
                                !text.contains("tiêu hóa") && !text.contains("tiêu hoá") && !text.contains("tieu hoa") &&
                                !text.contains("hóa đơn") && !text.contains("hoá đơn") && !text.contains("hoa don") &&
                                !text.contains("văn hóa") && !text.contains("văn hoá") && !text.contains("van hoa") &&
                                !text.contains("tối ưu hóa") && !text.contains("tối ưu hoá") && !text.contains("toi uu hoa") &&
                                !text.contains("chuẩn hóa") && !text.contains("chuẩn hoá") && !text.contains("chuan hoa") &&
                                !text.contains("công nghiệp hóa") && !text.contains("công nghiệp hoá") && !text.contains("cong nghiep hoa") &&
                                !text.contains("hiện đại hóa") && !text.contains("hiện đại hoá") && !text.contains("hien dai hoa") &&
                                !text.contains("ảo hóa") && !text.contains("ảo hoá") && !text.contains("ao hoa") &&
                                !text.contains("số hóa") && !text.contains("số hoá") && !text.contains("so hoa") &&
                                !text.contains("hòa bình") && !text.contains("hoà bình") && !text.contains("hoa binh") &&
                                !text.contains("hòa hợp") && !text.contains("hoà hợp") && !text.contains("hoa hop") &&
                                !text.contains("hóa thân") && !text.contains("hoá thân") && !text.contains("hoa than")) -> SubjectCategory.CHEMISTRY

                text.contains("sinh học") || text.contains("sinh hoc") || text.contains("môn sinh") || text.contains("mon sinh") || (flags and FLAG_BIO != 0) ||
                        text.contains("y học") || text.contains("y hoc") || text.contains("di truyền") || text.contains("di truyen") || text.contains("tế bào") || text.contains("te bao") ||
                        text.contains("vi sinh") || text.contains("sinh thái") || text.contains("sinh thai") || text.contains("tiêu hóa") || text.contains("tiêu hoá") || text.contains("tieu hoa") ||
                        ((flags and FLAG_SINH != 0) &&
                                !text.contains("học sinh") && !text.contains("hoc sinh") &&
                                !text.contains("sinh viên") && !text.contains("sinh vien") &&
                                !text.contains("sinh hoạt") && !text.contains("sinh hoat")) -> SubjectCategory.BIOLOGY

                text.contains("lịch sử") || (text.contains("lich su") && !text.contains("lịch sự") && !text.contains("lich su trong") && !text.contains("giao tiep") && !text.contains("ung xu")) || (flags and FLAG_HISTORY != 0) ||
                        text.contains("môn sử") || text.contains("mon su") ||
                        (((flags and FLAG_SU != 0)) &&
                                !text.contains("sử dụng") && !text.contains("su dung") &&
                                !text.contains("lịch sự") && !text.contains("lich su trong") &&
                                !text.contains("giao tiep") && !text.contains("ung xu")) -> SubjectCategory.HISTORY

                text.contains("ngữ văn") || text.contains("ngu van") || text.contains("tiếng việt") || text.contains("tieng viet") || (flags and FLAG_LIT != 0) ||
                        text.contains("môn văn") || text.contains("mon van") ||
                        (((flags and FLAG_VAN != 0)) &&
                                !text.contains("văn phòng") && !text.contains("van phong") &&
                                !text.contains("văn hóa") && !text.contains("văn hoá") && !text.contains("van hoa") &&
                                !text.contains("văn minh") && !text.contains("van minh") &&
                                !text.contains("văn bản") && !text.contains("van ban") &&
                                !text.contains("luận văn") && !text.contains("luan van")) -> SubjectCategory.LITERATURE

                text.contains("tiếng anh") || text.contains("tieng anh") || (flags and FLAG_ENG != 0) ||
                        text.contains("môn anh") || text.contains("mon anh") ||
                        ((flags and FLAG_ANH != 0) &&
                                !text.contains("hình ảnh") && !text.contains("hinh anh") &&
                                !text.contains("âm thanh") && !text.contains("am thanh") &&
                                !text.contains("thầy") && !text.contains("thay") &&
                                !text.contains("cô") && !text.contains("co ") &&
                                !text.contains("gv")) -> SubjectCategory.ENGLISH

                text.contains("tin học") || text.contains("tin hoc") ||
                        text.contains("môn tin") || text.contains("mon tin") ||
                        text.contains("lập trình") || text.contains("lap trinh") ||
                        text.contains("di động") || text.contains("di dong") ||
                        (flags and FLAG_CS != 0) ||
                        text.contains("công nghệ thông tin") || text.contains("cong nghe thong tin") ||
                        text.contains("thuật toán") || text.contains("thuat toan") ||
                        text.contains("cơ sở dữ liệu") || text.contains("co so du lieu") ||
                        text.contains("khoa học máy tính") || text.contains("khoa hoc may tinh") ||
                        text.contains("cấu trúc dữ liệu") || text.contains("cau truc du lieu") ||
                        text.contains("trí tuệ nhân tạo") || text.contains("tri tue nhan tao") ||
                        text.contains("machine learning") ||
                        text.contains("hệ điều hành") || text.contains("he dieu hanh") ||
                        text.contains("kiến trúc máy tính") || text.contains("kien truc may tinh") ||
                        ((flags and FLAG_TIN != 0) &&
                                !text.contains("thông tin") && !text.contains("thong tin") &&
                                !text.contains("bản tin") && !text.contains("ban tin") &&
                                !text.contains("tin tức") && !text.contains("tin tuc") &&
                                !text.contains("niềm tin") && !text.contains("niem tin") &&
                                (flags and FLAG_TU == 0)) -> SubjectCategory.COMPUTER_SCIENCE

                (flags and FLAG_DEFENSE != 0) ||
                        text.contains("giáo dục quốc phòng") || text.contains("giao duc quoc phong") ||
                        text.contains("quốc phòng an ninh") || text.contains("quoc phong an ninh") ||
                        text.contains("an ninh quốc phòng") || text.contains("an ninh quoc phong") ||
                        text.contains("quân sự") || text.contains("quan su") ||
                        text.contains("giáo dục qp") || text.contains("giao duc qp") -> SubjectCategory.DEFENSE_EDUCATION

                (flags and FLAG_LOCAL != 0) ||
                        text.contains("giáo dục địa phương") || text.contains("giao duc dia phuong") ||
                        text.contains("giáo dục đp") || text.contains("giao duc dp") -> SubjectCategory.LOCAL_EDUCATION

                (flags and FLAG_EXPERIENTIAL != 0) ||
                        text.contains("hoạt động trải nghiệm") || text.contains("hoat dong trai nghiem") ||
                        text.contains("hướng nghiệp") || text.contains("huong nghiep") ||
                        text.contains("sinh hoạt dưới cờ") || text.contains("sinh hoat duoi co") ||
                        text.contains("sinh hoạt lớp") || text.contains("sinh hoat lop") -> SubjectCategory.EXPERIENTIAL_ACTIVITIES

                else -> null
            }
        }

        val titleCategory = if (!title.isNullOrBlank()) {
            val titleNormalized = if (java.text.Normalizer.isNormalized(title, java.text.Normalizer.Form.NFC)) {
                title
            } else {
                java.text.Normalizer.normalize(title, java.text.Normalizer.Form.NFC)
            }
            val titleLower = titleNormalized.lowercase()
            val titleFlags = scanTokenFlags(titleLower)
            match(titleLower, titleFlags)
        } else {
            null
        }

        if (titleCategory != null) {
            return titleCategory
        }

        match(courseLower, courseFlags)?.let { return it }

        return SubjectCategory.OTHER
    }

    fun themeColor(category: SubjectCategory): Color {
        return when (category) {
            SubjectCategory.COMPUTER_SCIENCE -> Color(0xFF14AD8A)
            SubjectCategory.MATH -> Color(0xFFF2991A)
            SubjectCategory.ENGLISH -> Color(0xFF2694EB)
            SubjectCategory.LITERATURE -> Color(0xFFEB6138)
            SubjectCategory.PHYSICS -> Color(0xFF7361E0)
            SubjectCategory.CHEMISTRY -> Color(0xFFDC47AD)
            SubjectCategory.BIOLOGY -> Color(0xFF33B866)
            SubjectCategory.HISTORY -> Color(0xFFD98529)
            SubjectCategory.DEFENSE_EDUCATION -> Color(0xFF299447)
            SubjectCategory.LOCAL_EDUCATION -> Color(0xFF0D9488)
            SubjectCategory.EXPERIENTIAL_ACTIVITIES -> Color(0xFFF26C1F)
            SubjectCategory.OTHER -> Color(0xFF6685A3)
        }
    }

    fun accessibleTextColor(category: SubjectCategory): Color {
        return when (category) {
            SubjectCategory.COMPUTER_SCIENCE -> Color(0xFF0F766E)
            SubjectCategory.MATH -> Color(0xFFB45309)
            SubjectCategory.ENGLISH -> Color(0xFF0369A1)
            SubjectCategory.LITERATURE -> Color(0xFFC2410C)
            SubjectCategory.PHYSICS -> Color(0xFF5B45D6)
            SubjectCategory.CHEMISTRY -> Color(0xFF9D174D)
            SubjectCategory.BIOLOGY -> Color(0xFF15803D)
            SubjectCategory.HISTORY -> Color(0xFF9A3412)
            SubjectCategory.DEFENSE_EDUCATION -> Color(0xFF166534)
            SubjectCategory.LOCAL_EDUCATION -> Color(0xFF115E59)
            SubjectCategory.EXPERIENTIAL_ACTIVITIES -> Color(0xFFC2410C)
            SubjectCategory.OTHER -> Color(0xFF334155)
        }
    }

    @DrawableRes
    fun iconForCategory(category: SubjectCategory): Int {
        return when (category) {
            SubjectCategory.COMPUTER_SCIENCE -> R.drawable.ic_subject_cs
            SubjectCategory.MATH -> R.drawable.ic_subject_math
            SubjectCategory.ENGLISH -> R.drawable.ic_subject_english
            SubjectCategory.LITERATURE -> R.drawable.ic_subject_literature
            SubjectCategory.PHYSICS -> R.drawable.ic_subject_physics
            SubjectCategory.CHEMISTRY -> R.drawable.ic_subject_chemistry
            SubjectCategory.BIOLOGY -> R.drawable.ic_subject_biology
            SubjectCategory.HISTORY -> R.drawable.ic_subject_history
            SubjectCategory.DEFENSE_EDUCATION -> R.drawable.ic_subject_defense
            SubjectCategory.LOCAL_EDUCATION -> R.drawable.ic_subject_local_edu
            SubjectCategory.EXPERIENTIAL_ACTIVITIES -> R.drawable.ic_subject_experiential
            SubjectCategory.OTHER -> R.drawable.ic_subject_other
        }
    }

    fun badgeCode(category: SubjectCategory, courseName: String = "", title: String? = null): String {
        return when (category) {
            SubjectCategory.COMPUTER_SCIENCE -> "TIN"
            SubjectCategory.MATH -> "TOÁ"
            SubjectCategory.ENGLISH -> "ANH"
            SubjectCategory.LITERATURE -> "VĂN"
            SubjectCategory.PHYSICS -> "LÝ"
            SubjectCategory.CHEMISTRY -> "HOÁ"
            SubjectCategory.BIOLOGY -> "SINH"
            SubjectCategory.HISTORY -> "SỬ"
            SubjectCategory.DEFENSE_EDUCATION -> "GDQP"
            SubjectCategory.LOCAL_EDUCATION -> "GDĐP"
            SubjectCategory.EXPERIENTIAL_ACTIVITIES -> "HĐTN"
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
