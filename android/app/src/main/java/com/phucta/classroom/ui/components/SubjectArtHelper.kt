package com.phucta.classroom.ui.components

import androidx.annotation.DrawableRes
import androidx.compose.runtime.Immutable
import androidx.compose.ui.graphics.Color
import com.phucta.classroom.R
import com.phucta.classroom.data.model.normalizeForVietnameseSearch

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

private const val FLAG_MATH = 1L shl 0
private const val FLAG_CS = 1L shl 1
private const val FLAG_BIO = 1L shl 2
private const val FLAG_CHEM = 1L shl 3
private const val FLAG_LIT = 1L shl 4
private const val FLAG_ENG = 1L shl 5
private const val FLAG_PHYSICS = 1L shl 6
private const val FLAG_HISTORY = 1L shl 7
private const val FLAG_DEFENSE = 1L shl 8
private const val FLAG_LOCAL = 1L shl 9
private const val FLAG_EXPERIENTIAL = 1L shl 10

private const val FLAG_LY = 1L shl 11
private const val FLAG_HOA = 1L shl 12
private const val FLAG_SINH = 1L shl 13
private const val FLAG_SU = 1L shl 14
private const val FLAG_VAN = 1L shl 15
private const val FLAG_ANH = 1L shl 16
private const val FLAG_TIN = 1L shl 17
private const val FLAG_TU = 1L shl 18

// Anchor tokens for multi-word phrases to avoid full scans when anchor word is missing
private const val FLAG_W_GIAI = 1L shl 19
private const val FLAG_W_DAI = 1L shl 20
private const val FLAG_W_HINH = 1L shl 21
private const val FLAG_W_XAC = 1L shl 22
private const val FLAG_W_LUONG = 1L shl 23
private const val FLAG_W_DAO = 1L shl 24
private const val FLAG_W_TICH = 1L shl 25
private const val FLAG_W_THONG = 1L shl 26
private const val FLAG_W_VI = 1L shl 27
private const val FLAG_W_MA = 1L shl 28

private const val FLAG_W_VAT = 1L shl 29
private const val FLAG_W_CO = 1L shl 30
private const val FLAG_W_NHIET = 1L shl 31
private const val FLAG_W_QUANG = 1L shl 32
private const val FLAG_W_DIEN = 1L shl 33
private const val FLAG_W_SONG = 1L shl 34

private const val FLAG_W_Y = 1L shl 35
private const val FLAG_W_DI = 1L shl 36
private const val FLAG_W_TE = 1L shl 37
private const val FLAG_W_TIEU = 1L shl 38

private const val FLAG_W_LAP = 1L shl 39
private const val FLAG_W_THUAT = 1L shl 40
private const val FLAG_W_CONG = 1L shl 41
private const val FLAG_W_KHOA = 1L shl 42
private const val FLAG_W_CAU = 1L shl 43
private const val FLAG_W_TRI = 1L shl 44
private const val FLAG_W_MACHINE = 1L shl 45
private const val FLAG_W_HE = 1L shl 46
private const val FLAG_W_KIEN = 1L shl 47

private const val FLAG_W_QUOC = 1L shl 48
private const val FLAG_W_QUAN = 1L shl 49
private const val FLAG_W_GIAO = 1L shl 50
private const val FLAG_W_HOAT = 1L shl 51
private const val FLAG_W_HUONG = 1L shl 52

private val TOKEN_FLAG_MAP: Map<String, Long> = run {
    val map = HashMap<String, Long>(128)
    fun add(words: Array<String>, flag: Long) {
        for (w in words) {
            map[w] = (map[w] ?: 0L) or flag
        }
    }
    fun add(word: String, flag: Long) {
        map[word] = (map[word] ?: 0L) or flag
    }
    add(arrayOf("toan", "math", "maths", "calculus", "algebra", "geometry", "trigonometry", "statistics", "discrete"), FLAG_MATH)
    add("giai", FLAG_W_GIAI)
    add("dai", FLAG_W_DAI)
    add("hinh", FLAG_W_HINH)
    add("xac", FLAG_W_XAC)
    add("luong", FLAG_W_LUONG)
    add("dao", FLAG_W_DAO)
    add("tich", FLAG_W_TICH)
    add("thong", FLAG_W_THONG)
    add("vi", FLAG_W_VI)
    add("ma", FLAG_W_MA)

    add(arrayOf("physics", "mechanics", "thermodynamics", "optics"), FLAG_PHYSICS)
    add(arrayOf("ly", "li"), FLAG_LY)
    add("vat", FLAG_W_VAT)
    add("co", FLAG_W_CO)
    add("nhiet", FLAG_W_NHIET)
    add("quang", FLAG_W_QUANG)
    add("dien", FLAG_W_DIEN)
    add("song", FLAG_W_SONG)

    add(arrayOf("chemistry", "chem", "biochemistry"), FLAG_CHEM)
    add("hoa", FLAG_HOA)

    add(arrayOf("biology", "bio", "genetics", "ecology"), FLAG_BIO)
    add("sinh", FLAG_SINH)
    add("y", FLAG_W_Y)
    add("di", FLAG_W_DI)
    add("te", FLAG_W_TE)
    add("tieu", FLAG_W_TIEU)

    add("history", FLAG_HISTORY)
    add("su", FLAG_SU)

    add(arrayOf("literature", "writing", "essay"), FLAG_LIT)
    add("van", FLAG_VAN)

    add(arrayOf("english", "ielts", "toeic", "toefl"), FLAG_ENG)
    add("anh", FLAG_ANH)

    add("gdqp", FLAG_DEFENSE)
    add("gddp", FLAG_LOCAL)
    add("hdtn", FLAG_EXPERIENTIAL)

    add(arrayOf("android", "ios", "swift", "python", "java", "cntt", "it", "ctdl", "cpp", "kotlin", "javascript", "typescript"), FLAG_CS)
    add("tin", FLAG_TIN)
    add("tu", FLAG_TU)
    add("lap", FLAG_W_LAP)
    add("thuat", FLAG_W_THUAT)
    add("cong", FLAG_W_CONG)
    add("khoa", FLAG_W_KHOA)
    add("cau", FLAG_W_CAU)
    add("tri", FLAG_W_TRI)
    add("machine", FLAG_W_MACHINE)
    add("he", FLAG_W_HE)
    add("kien", FLAG_W_KIEN)

    add("quoc", FLAG_W_QUOC)
    add("quan", FLAG_W_QUAN)
    add("giao", FLAG_W_GIAO)
    add("hoat", FLAG_W_HOAT)
    add("huong", FLAG_W_HUONG)
    map
}

private class TokenTrieNode {
    var flag: Long = 0L
    val children = arrayOfNulls<TokenTrieNode>(26)
}

private val TOKEN_TRIE: TokenTrieNode = run {
    val root = TokenTrieNode()
    fun insert(word: String, flag: Long) {
        var curr = root
        for (i in 0 until word.length) {
            val c = word[i]
            val idx = c - 'a'
            if (idx !in 0..25) continue
            var child = curr.children[idx]
            if (child == null) {
                child = TokenTrieNode()
                curr.children[idx] = child
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

private fun lookupTokenFlag(text: String, start: Int, end: Int): Long {
    var curr = TOKEN_TRIE
    for (i in start until end) {
        val c = text[i]
        val idx = c - 'a'
        if (idx !in 0..25) return 0L
        val next = curr.children[idx] ?: return 0L
        curr = next
    }
    return curr.flag
}

private fun scanTokenFlags(text: String): Long {
    val len = text.length
    if (len == 0) return 0L
    var flags = 0L
    var start = -1
    for (i in 0 until len) {
        val ch = text[i]
        val isWordChar = (ch in 'a'..'z') || (ch in '0'..'9')
        if (isWordChar) {
            if (start == -1) start = i
        } else {
            if (start != -1) {
                val tokenLen = i - start
                if (tokenLen in 1..20) {
                    flags = flags or lookupTokenFlag(text, start, i)
                }
                start = -1
            }
        }
    }
    if (start != -1) {
        val tokenLen = len - start
        if (tokenLen in 1..20) {
            flags = flags or lookupTokenFlag(text, start, len)
        }
    }
    return flags
}

object SubjectArtHelper {
    private const val MAX_CACHE_SIZE = 16384
    private val courseCategoryCache = java.util.concurrent.ConcurrentHashMap<String, SubjectCategory>()
    private val compoundCategoryCache = java.util.concurrent.ConcurrentHashMap<String, SubjectCategory>()
    private val courseBadgeCache = java.util.concurrent.ConcurrentHashMap<String, String>()
    private val themeCache = java.util.concurrent.ConcurrentHashMap<String, SubjectTheme>()

    fun clearCaches() {
        courseCategoryCache.clear()
        compoundCategoryCache.clear()
        courseBadgeCache.clear()
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
        fun match(normText: String, rawText: String, flags: Long): SubjectCategory? {
            // 1. Math
            var hasMath = (flags and FLAG_MATH != 0L)
            if (!hasMath) {
                if ((flags and FLAG_W_GIAI != 0L) && normText.contains("giai tich")) hasMath = true
                else if ((flags and FLAG_W_DAI != 0L) && normText.contains("dai so")) hasMath = true
                else if ((flags and FLAG_W_HINH != 0L) && normText.contains("hinh hoc")) hasMath = true
                else if ((flags and FLAG_W_XAC != 0L) && normText.contains("xac suat")) hasMath = true
                else if ((flags and FLAG_W_LUONG != 0L) && normText.contains("luong giac")) hasMath = true
                else if ((flags and FLAG_W_DAO != 0L) && normText.contains("dao ham")) hasMath = true
                else if ((flags and FLAG_W_TICH != 0L) && normText.contains("tich phan")) hasMath = true
                else if ((flags and FLAG_W_THONG != 0L) && normText.contains("thong ke")) hasMath = true
                else if ((flags and FLAG_W_VI != 0L) && normText.contains("vi phan")) hasMath = true
                else if ((flags and FLAG_W_MA != 0L) && normText.contains("ma tran")) hasMath = true
            } else {
                if (normText.contains("toan cao cap") || normText.contains("toan roi rac")) hasMath = true
            }

            if (hasMath) {
                if (flags and FLAG_MATH != 0L) {
                    if (!normText.contains("dien toan") &&
                        !normText.contains("an toan") &&
                        !normText.contains("thanh toan") &&
                        !normText.contains("hoan toan")) {
                        return SubjectCategory.MATH
                    }
                } else {
                    return SubjectCategory.MATH
                }
            }

            // 2. Physics
            var hasPhysics = (flags and FLAG_PHYSICS != 0L)
            if (!hasPhysics) {
                if (flags and FLAG_W_VAT != 0L) {
                    if (normText.contains("vat ly") || normText.contains("vat li") ||
                        normText.contains("vat ly dai cuong") || normText.contains("vat li dai cuong")) {
                        hasPhysics = true
                    }
                }
                if (!hasPhysics && (flags and FLAG_W_CO != 0L) && normText.contains("co hoc")) hasPhysics = true
                if (!hasPhysics && (flags and FLAG_W_NHIET != 0L) && normText.contains("nhiet hoc")) hasPhysics = true
                if (!hasPhysics && (flags and FLAG_W_QUANG != 0L) && normText.contains("quang hoc")) hasPhysics = true
                if (!hasPhysics && (flags and FLAG_W_DIEN != 0L) && normText.contains("dien tu")) hasPhysics = true
                if (!hasPhysics && (flags and FLAG_W_DAO != 0L) && normText.contains("dao dong")) hasPhysics = true
                if (!hasPhysics && (flags and FLAG_W_SONG != 0L) && normText.contains("song co")) hasPhysics = true
                if (!hasPhysics && (flags and FLAG_LY != 0L)) {
                    if (normText.contains("mon ly") || normText.contains("mon li") ||
                        normText.contains("sbt ly") || normText.contains("sbt li")) {
                        hasPhysics = true
                    } else if (!normText.contains("quan ly") && !normText.contains("quan li") &&
                        !normText.contains("xu ly") && !normText.contains("xu li") &&
                        !normText.contains("tam ly") && !normText.contains("tam li") &&
                        !normText.contains("phap ly") && !normText.contains("phap li") &&
                        !normText.contains("dia ly") && !normText.contains("dia li") &&
                        !normText.contains("triet ly") && !normText.contains("triet li") &&
                        !normText.contains("ly thuyet") && !normText.contains("li thuyet") &&
                        !normText.contains("ly luan") && !normText.contains("li luan") &&
                        !normText.contains("ly do") && !normText.contains("li do") &&
                        !normText.contains("hop ly") && !normText.contains("hop li") &&
                        !normText.contains("dai ly") && !normText.contains("dai li")) {
                        hasPhysics = true
                    }
                }
            }
            if (hasPhysics) return SubjectCategory.PHYSICS

            // 3. Chemistry
            var hasChem = (flags and FLAG_CHEM != 0L)
            if (!hasChem && (flags and FLAG_HOA != 0L)) {
                if (normText.contains("hoa hoc") || normText.contains("mon hoa") ||
                    normText.contains("hoa huu co") || normText.contains("hoa vo co") ||
                    normText.contains("hoa dai cuong") || normText.contains("hoa phan tich")) {
                    hasChem = true
                } else if (!normText.contains("tu dong hoa") &&
                    !normText.contains("tien hoa") &&
                    !normText.contains("tieu hoa") &&
                    !normText.contains("hoa don") &&
                    !normText.contains("van hoa") &&
                    !normText.contains("toi uu hoa") &&
                    !normText.contains("chuan hoa") &&
                    !normText.contains("cong nghiep hoa") &&
                    !normText.contains("hien dai hoa") &&
                    !normText.contains("ao hoa") &&
                    !normText.contains("so hoa") &&
                    !normText.contains("hoa binh") &&
                    !normText.contains("hoa hop") &&
                    !normText.contains("hoa than")) {
                    hasChem = true
                }
            }
            if (hasChem) return SubjectCategory.CHEMISTRY

            // 4. Biology
            var hasBio = (flags and FLAG_BIO != 0L)
            if (!hasBio) {
                if ((flags and FLAG_W_Y != 0L) && normText.contains("y hoc")) hasBio = true
                else if ((flags and FLAG_W_DI != 0L) && normText.contains("di truyen")) hasBio = true
                else if ((flags and FLAG_W_TE != 0L) && normText.contains("te bao")) hasBio = true
                else if ((flags and FLAG_W_VI != 0L) && normText.contains("vi sinh")) hasBio = true
                else if ((flags and FLAG_W_TIEU != 0L) && normText.contains("tieu hoa")) hasBio = true
                else if (flags and FLAG_SINH != 0L) {
                    if (normText.contains("sinh hoc") || normText.contains("mon sinh") || normText.contains("sinh thai")) {
                        hasBio = true
                    } else if (!normText.contains("hoc sinh") &&
                        !normText.contains("sinh vien") &&
                        !normText.contains("sinh hoat")) {
                        hasBio = true
                    }
                }
            }
            if (hasBio) return SubjectCategory.BIOLOGY

            // 5. History
            if (flags and FLAG_HISTORY != 0L) return SubjectCategory.HISTORY
            if (flags and FLAG_SU != 0L) {
                val isLichSuManners = normText.contains("lich su trong") ||
                    normText.contains("giao tiep") ||
                    normText.contains("ung xu") ||
                    rawText.contains("lịch sự")
                if (!isLichSuManners) {
                    if (normText.contains("lich su") || normText.contains("mon su") || !normText.contains("su dung")) {
                        return SubjectCategory.HISTORY
                    }
                }
            }

            // 6. Literature
            if (flags and FLAG_LIT != 0L) return SubjectCategory.LITERATURE
            if (flags and FLAG_VAN != 0L) {
                if (normText.contains("ngu van") || normText.contains("tieng viet") || normText.contains("mon van")) {
                    return SubjectCategory.LITERATURE
                }
                if (!normText.contains("van phong") &&
                    !normText.contains("van hoa") &&
                    !normText.contains("van minh") &&
                    !normText.contains("van ban") &&
                    !normText.contains("luan van")) {
                    return SubjectCategory.LITERATURE
                }
            }

            // 7. English
            if (flags and FLAG_ENG != 0L) return SubjectCategory.ENGLISH
            if (flags and FLAG_ANH != 0L) {
                if (normText.contains("tieng anh") || normText.contains("mon anh")) {
                    return SubjectCategory.ENGLISH
                }
                if (!normText.contains("hinh anh") &&
                    !normText.contains("am thanh") &&
                    !normText.contains("thay") &&
                    !normText.contains("co ") &&
                    !rawText.contains("cô") &&
                    !normText.contains("gv")) {
                    return SubjectCategory.ENGLISH
                }
            }

            // 8. Computer Science
            if (flags and FLAG_CS != 0L) return SubjectCategory.COMPUTER_SCIENCE
            var hasCs = false
            if (flags and FLAG_TIN != 0L) {
                if (normText.contains("tin hoc") || normText.contains("mon tin")) {
                    hasCs = true
                } else if (!normText.contains("thong tin") &&
                    !normText.contains("ban tin") &&
                    !normText.contains("tin tuc") &&
                    !normText.contains("niem tin") &&
                    (flags and FLAG_TU == 0L)) {
                    hasCs = true
                }
            }
            if (!hasCs) {
                if ((flags and FLAG_W_LAP != 0L) && normText.contains("lap trinh")) hasCs = true
                else if ((flags and FLAG_W_DI != 0L) && normText.contains("di dong")) hasCs = true
                else if ((flags and FLAG_W_CONG != 0L) && normText.contains("cong nghe thong tin")) hasCs = true
                else if ((flags and FLAG_W_THUAT != 0L) && normText.contains("thuat toan")) hasCs = true
                else if (((flags and FLAG_W_CO != 0L) && normText.contains("co so du lieu")) ||
                    ((flags and FLAG_W_CAU != 0L) && normText.contains("cau truc du lieu"))) hasCs = true
                else if ((flags and FLAG_W_KHOA != 0L) && normText.contains("khoa hoc may tinh")) hasCs = true
                else if ((flags and FLAG_W_TRI != 0L) && normText.contains("tri tue nhan tao")) hasCs = true
                else if ((flags and FLAG_W_MACHINE != 0L) && normText.contains("machine learning")) hasCs = true
                else if ((flags and FLAG_W_HE != 0L) && normText.contains("he dieu hanh")) hasCs = true
                else if ((flags and FLAG_W_KIEN != 0L) && normText.contains("kien truc may tinh")) hasCs = true
            }
            if (hasCs) return SubjectCategory.COMPUTER_SCIENCE

            // 9. Defense Education
            if (flags and FLAG_DEFENSE != 0L) return SubjectCategory.DEFENSE_EDUCATION
            if ((flags and (FLAG_W_QUOC or FLAG_W_QUAN or FLAG_W_GIAO)) != 0L) {
                if (normText.contains("giao duc quoc phong") ||
                    normText.contains("quoc phong an ninh") ||
                    normText.contains("an ninh quoc phong") ||
                    normText.contains("quan su") ||
                    normText.contains("giao duc qp")) {
                    return SubjectCategory.DEFENSE_EDUCATION
                }
            }

            // 10. Local Education
            if (flags and FLAG_LOCAL != 0L) return SubjectCategory.LOCAL_EDUCATION
            if ((flags and FLAG_W_GIAO != 0L)) {
                if (normText.contains("giao duc dia phuong") || normText.contains("giao duc dp")) {
                    return SubjectCategory.LOCAL_EDUCATION
                }
            }

            // 11. Experiential Activities
            if (flags and FLAG_EXPERIENTIAL != 0L) return SubjectCategory.EXPERIENTIAL_ACTIVITIES
            if ((flags and (FLAG_W_HOAT or FLAG_W_HUONG or FLAG_SINH)) != 0L) {
                if (normText.contains("hoat dong trai nghiem") ||
                    normText.contains("huong nghiep") ||
                    normText.contains("sinh hoat duoi co") ||
                    normText.contains("sinh hoat lop")) {
                    return SubjectCategory.EXPERIENTIAL_ACTIVITIES
                }
            }

            return null
        }

        if (!title.isNullOrBlank()) {
            val titleNorm = title.normalizeForVietnameseSearch()
            val titleFlags = scanTokenFlags(titleNorm)
            val titleCategory = match(titleNorm, title, titleFlags)
            if (titleCategory != null) {
                return titleCategory
            }
            return category(courseName, null)
        }

        val courseNorm = courseName.normalizeForVietnameseSearch()
        val courseFlags = scanTokenFlags(courseNorm)
        return match(courseNorm, courseName, courseFlags) ?: SubjectCategory.OTHER
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
            SubjectCategory.MATH -> "TOÁN"
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
                    val cached = courseBadgeCache[courseName]
                    if (cached != null) return cached
                    val badge = cleaned.take(3).uppercase()
                    if (courseBadgeCache.size >= MAX_CACHE_SIZE) {
                        courseBadgeCache.clear()
                    }
                    courseBadgeCache[courseName] = badge
                    return badge
                }
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

    fun badgeCode(courseName: String, title: String? = null): String {
        val cat = category(courseName, title)
        return badgeCode(cat, courseName, title)
    }
}
