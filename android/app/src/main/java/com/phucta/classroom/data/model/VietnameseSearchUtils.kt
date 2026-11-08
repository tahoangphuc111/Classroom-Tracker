package com.phucta.classroom.data.model

private val SKIP_COMBINING_MARK = '\uFFFF'

private class CacheEntry(val key: String, val value: String)

private class FastStringCache(private val capacity: Int = 16384) {
    private val mask = capacity - 1
    private val entries = java.util.concurrent.atomic.AtomicReferenceArray<CacheEntry?>(capacity)

    operator fun get(key: String): String? {
        val idx = key.hashCode() and mask
        val entry = entries.get(idx)
        return if (entry != null && entry.key == key) entry.value else null
    }

    operator fun set(key: String, value: String) {
        val idx = key.hashCode() and mask
        entries.set(idx, CacheEntry(key, value))
    }

    fun clear() {
        for (i in 0 until capacity) {
            entries.set(i, null)
        }
    }
}

private val NORMALIZE_CACHE = FastStringCache(capacity = 16384)

fun clearVietnameseSearchCache() {
    NORMALIZE_CACHE.clear()
}

private val VIETNAMESE_CHAR_MAP: CharArray = run {
    val map = CharArray(0x1F00)

    for (c in 0 until 0x1F00) {
        map[c] = c.toChar().lowercaseChar()
    }

    fun mapChars(targets: String, replacement: Char) {
        for (ch in targets) {
            map[ch.code] = replacement
        }
    }

    mapChars("àáảãạâầấẩẫậăằắẳẵặÀÁẢÃẠÂẦẤẨẪẬĂẰẮẲẴẶ", 'a')

    mapChars("đĐ", 'd')

    mapChars("èéẻẽẹêềếểễệÈÉẺẼẸÊỀẾỂỄỆ", 'e')

    mapChars("ìíỉĩịÌÍỈĨỊ", 'i')

    mapChars("òóỏõọôồốổỗộơờớởỡợÒÓỎÕỌÔỒỐỔỖỘƠỜỚỞỠỢ", 'o')

    mapChars("ùúủũụưừứửữựÙÚỦŨỤƯỪỨỬỮỰ", 'u')

    mapChars("ỳýỷỹỵỲÝỶỸỴ", 'y')

    for (code in 0x0300..0x036F) {
        map[code] = SKIP_COMBINING_MARK
    }

    map[0x00A0] = ' '

    map
}

private val COMMON_SYLLABLES: Map<String, String> = run {
    val pairs = listOf(
        "toán" to "toan", "toan" to "toan", "Toán" to "toan", "TOÁN" to "toan",
        "học" to "hoc", "hoc" to "hoc", "Học" to "hoc", "HỌC" to "hoc",
        "vật" to "vat", "vat" to "vat", "Vật" to "vat", "VẬT" to "vat",
        "lý" to "ly", "ly" to "ly", "Lý" to "ly", "LÝ" to "ly",
        "lí" to "li", "li" to "li", "Lí" to "li", "LÍ" to "li",
        "hóa" to "hoa", "hoa" to "hoa", "Hóa" to "hoa", "HÓA" to "hoa",
        "hoá" to "hoa", "Hoá" to "hoa", "HOÁ" to "hoa",
        "sinh" to "sinh", "Sinh" to "sinh", "SINH" to "sinh",
        "sử" to "su", "su" to "su", "Sử" to "su", "SỬ" to "su",
        "địa" to "dia", "dia" to "dia", "Địa" to "dia", "ĐỊA" to "dia",
        "văn" to "van", "van" to "van", "Văn" to "van", "VĂN" to "van",
        "anh" to "anh", "Anh" to "anh", "ANH" to "anh",
        "tin" to "tin", "Tin" to "tin", "TIN" to "tin",
        "đại" to "dai", "dai" to "dai", "Đại" to "dai", "ĐẠI" to "dai",
        "số" to "so", "so" to "so", "Số" to "so", "SỐ" to "so",
        "giải" to "giai", "giai" to "giai", "Giải" to "giai", "GIẢI" to "giai",
        "tích" to "tich", "tich" to "tich", "Tích" to "tich", "TÍCH" to "tich",
        "hình" to "hinh", "hinh" to "hinh", "Hình" to "hinh", "HÌNH" to "hinh",
        "bài" to "bai", "bai" to "bai", "Bài" to "bai", "BÀI" to "bai",
        "tập" to "tap", "tap" to "tap", "Tập" to "tap", "TẬP" to "tap",
        "về" to "ve", "ve" to "ve", "Về" to "ve", "VỀ" to "ve",
        "nhà" to "nha", "nha" to "nha", "Nhà" to "nha", "NHÀ" to "nha",
        "đề" to "de", "de" to "de", "Đề" to "de", "ĐỀ" to "de",
        "thi" to "thi", "Thi" to "thi", "THI" to "thi",
        "thử" to "thu", "thu" to "thu", "Thử" to "thu", "THỬ" to "thu",
        "kiểm" to "kiem", "kiem" to "kiem", "Kiểm" to "kiem", "KIỂM" to "kiem",
        "tra" to "tra", "Tra" to "tra", "TRA" to "tra",
        "toán học" to "toan hoc", "Toán Học" to "toan hoc", "TOÁN HỌC" to "toan hoc",
        "vật lý" to "vat ly", "Vật Lý" to "vat ly", "VẬT LÝ" to "vat ly",
        "vật lí" to "vat li", "Vật Lí" to "vat li", "VẬT LÍ" to "vat li",
        "hóa học" to "hoa hoc", "Hóa Học" to "hoa hoc", "HÓA HỌC" to "hoa hoc",
        "hoá học" to "hoa hoc", "Hoá Học" to "hoa hoc", "HOÁ HỌC" to "hoa hoc",
        "sinh học" to "sinh hoc", "Sinh Học" to "sinh hoc", "SINH HỌC" to "sinh hoc",
        "ngữ văn" to "ngu van", "Ngữ Văn" to "ngu van", "NGỮ VĂN" to "ngu van",
        "tiếng anh" to "tieng anh", "Tiếng Anh" to "tieng anh", "TIẾNG ANH" to "tieng anh",
        "lịch sử" to "lich su", "Lịch Sử" to "lich su", "LỊCH SỬ" to "lich su",
        "địa lý" to "dia ly", "Địa Lý" to "dia ly", "ĐỊA LÝ" to "dia ly",
        "địa lí" to "dia li", "Địa Lí" to "dia li", "ĐỊA LÍ" to "dia li",
        "tin học" to "tin hoc", "Tin Học" to "tin hoc", "TIN HỌC" to "tin hoc",
        "đại số" to "dai so", "Đại Số" to "dai so", "Đại số" to "dai so",
        "giải tích" to "giai tich", "Giải Tích" to "giai tich", "Giải tích" to "giai tich",
        "hình học" to "hinh hoc", "Hình Học" to "hinh hoc", "Hình học" to "hinh hoc",
        "đạo hàm" to "dao ham", "Đạo Hàm" to "dao ham", "Đạo hàm" to "dao ham",
        "tích phân" to "tich phan", "Tích Phân" to "tich phan", "Tích phân" to "tich phan",
        "nguyên hàm" to "nguyen ham", "Nguyên Hàm" to "nguyen ham",
        "quang học" to "quang hoc", "Quang Học" to "quang hoc",
        "cơ học" to "co hoc", "Cơ Học" to "co hoc",
        "nhiệt học" to "nhiet hoc", "Nhiệt Học" to "nhiet hoc",
        "điện từ" to "dien tu", "Điện Từ" to "dien tu",
        "bài tập" to "bai tap", "Bài Tập" to "bai tap", "Bài tập" to "bai tap",
        "kiểm tra" to "kiem tra", "Kiểm Tra" to "kiem tra", "Kiểm tra" to "kiem tra",
        "thực hành" to "thuc hanh", "Thực Hành" to "thuc hanh", "Thực hành" to "thuc hanh",
        "hướng dẫn" to "huong dan", "Hướng Dẫn" to "huong dan", "Hướng dẫn" to "huong dan",
        "lớp 12" to "lop 12", "Lớp 12" to "lop 12",
        "lớp 11" to "lop 11", "Lớp 11" to "lop 11",
        "lớp 10" to "lop 10", "Lớp 10" to "lop 10"
    )
    val map = java.util.HashMap<String, String>(pairs.size * 2)
    for ((k, v) in pairs) {
        map[k] = v
    }
    map
}

private fun isSearchDelimiterChar(ch: Char): Boolean {
    return ch <= ' ' || ch == '\u00A0' || ch == '\u202F' || ch == ',' || ch == ';' || ch == ':' ||
            ch == '-' || ch == '/' || ch == '(' || ch == ')' || ch == '[' || ch == ']' ||
            ch == '{' || ch == '}' || ch == '|' || ch == '"' || ch == '\'' || ch == '?' || ch == '!' || ch == '_'
}

fun tokenizeSearchQuery(query: String): List<String> {
    val len = query.length
    if (len == 0) return emptyList()

    var start = -1
    var tokens: ArrayList<String>? = null

    for (i in 0 until len) {
        val ch = query[i]
        val isDelimiter = isSearchDelimiterChar(ch)
        if (!isDelimiter) {
            if (start == -1) {
                start = i
            }
        } else {
            if (start != -1) {
                if (tokens == null) {
                    tokens = ArrayList(8)
                }
                tokens.add(query.substring(start, i))
                start = -1
            }
        }
    }
    if (start != -1) {
        if (tokens == null) {
            return listOf(query.substring(start, len))
        }
        tokens.add(query.substring(start, len))
    }
    return tokens ?: emptyList()
}

fun String.normalizeForVietnameseSearch(): String {
    val len = this.length
    if (len == 0) return ""

    var start = 0
    while (start < len && (this[start] <= ' ' || this[start] == '\u00A0' || this[start] == '\u202F')) start++
    if (start == len) return ""

    var end = len - 1
    while (end > start && (this[end] <= ' ' || this[end] == '\u00A0' || this[end] == '\u202F')) end--

    var needsNormalization = false
    for (i in start..end) {
        val c = this[i]
        if (c in 'A'..'Z' || c.code >= 0x80) {
            needsNormalization = true
            break
        }
    }
    if (!needsNormalization) {
        if (start == 0 && end == len - 1) return this
        return this.substring(start, end + 1)
    }

    val trimmedLen = end - start + 1
    if (len <= 128) {
        val cached = NORMALIZE_CACHE[this]
        if (cached != null) return cached
    }

    if (trimmedLen <= 25) {
        val lookupKey = if (start == 0 && end == len - 1) this else this.substring(start, end + 1)
        val common = COMMON_SYLLABLES[lookupKey]
        if (common != null) return common
    }

    val buffer = if (trimmedLen <= 512) threadLocalBuffer.get() ?: CharArray(512) else CharArray(trimmedLen)
    var outPos = 0
    for (i in start..end) {
        val ch = this[i]
        val code = ch.code
        if (code < 0x1F00) {
            val mapped = VIETNAMESE_CHAR_MAP[code]
            if (mapped != SKIP_COMBINING_MARK) {
                buffer[outPos++] = mapped
            }
        } else {
            buffer[outPos++] = ch.lowercaseChar()
        }
    }

    val stripped = String(buffer, 0, outPos)
    if (len <= 128) {
        NORMALIZE_CACHE[this] = stripped
    }

    return stripped
}

private val threadLocalBuffer = object : ThreadLocal<CharArray>() {
    override fun initialValue(): CharArray = CharArray(512)
}

fun cleanTelexKeystrokes(s: String): String {
    val len = s.length
    if (len < 3) return s

    val last = s[len - 1]
    val hasTrailingTone = last == 's' || last == 'f' || last == 'r' || last == 'x' || last == 'j'
    val effectiveLen = if (hasTrailingTone) len - 1 else len
    if (effectiveLen < 2) return s

    var hasPair = false
    for (i in 0 until effectiveLen - 1) {
        val c1 = s[i]
        val c2 = s[i + 1]
        if ((c1 == 'd' && c2 == 'd') ||
            (c1 == 'a' && c2 == 'a') ||
            (c1 == 'e' && c2 == 'e') ||
            (c1 == 'o' && c2 == 'o') ||
            (c1 == 'u' && c2 == 'w') ||
            (c1 == 'o' && c2 == 'w') ||
            (c1 == 'a' && c2 == 'w')) {
            hasPair = true
            break
        }
    }

    if (!hasTrailingTone && !hasPair) {
        return s
    }

    val sb = java.lang.StringBuilder(effectiveLen)
    var i = 0
    while (i < effectiveLen) {
        val c = s[i]
        if (i + 1 < effectiveLen) {
            val next = s[i + 1]
            if ((c == 'd' && next == 'd') ||
                (c == 'a' && next == 'a') ||
                (c == 'e' && next == 'e') ||
                (c == 'o' && next == 'o')) {
                sb.append(c)
                i += 2
                continue
            } else if (c == 'u' && next == 'w') {
                sb.append('u')
                i += 2
                continue
            } else if (c == 'o' && next == 'w') {
                sb.append('o')
                i += 2
                continue
            } else if (c == 'a' && next == 'w') {
                sb.append('a')
                i += 2
                continue
            }
        }
        sb.append(c)
        i++
    }
    return sb.toString()
}

fun expandVietnameseAcronyms(normalizedText: String): String {
    if (normalizedText.isEmpty()) return ""
    val expansions = ArrayList<String>(4)

    if (normalizedText.contains("bai tap ve nha")) expansions.add("btvn")
    if (normalizedText.contains("kiem tra")) expansions.add("kt")
    if (normalizedText.contains("15 phut")) expansions.add("15p")
    if (normalizedText.contains("45 phut")) expansions.add("45p")
    if (normalizedText.contains("giua ki") || normalizedText.contains("giua ky")) expansions.add("gk")
    if (normalizedText.contains("cuoi ki") || normalizedText.contains("cuoi ky")) expansions.add("ck")
    if (normalizedText.contains("thuc hanh")) expansions.add("th")
    if (normalizedText.contains("chuyen de")) expansions.add("cd")
    if (normalizedText.contains("sach giao khoa")) expansions.add("sgk")
    if (normalizedText.contains("sach bai tap")) expansions.add("sbt")

    val tokens = tokenizeSearchQuery(normalizedText)
    for (tok in tokens) {
        when (tok) {
            "btvn" -> expansions.add("bai tap ve nha")
            "kt" -> expansions.add("kiem tra")
            "15p" -> expansions.add("15 phut")
            "45p" -> expansions.add("45 phut")
            "gk" -> {
                expansions.add("giua ki")
                expansions.add("giua ky")
            }
            "ck" -> {
                expansions.add("cuoi ki")
                expansions.add("cuoi ky")
            }
            "th" -> expansions.add("thuc hanh")
            "cd" -> expansions.add("chuyen de")
            "sgk" -> expansions.add("sach giao khoa")
            "sbt" -> expansions.add("sach bai tap")
        }
    }

    if (expansions.isEmpty()) return ""
    return expansions.joinToString(" ")
}

private fun isWordBoundaryChar(ch: Char): Boolean {
    return !(ch in 'a'..'z' || ch in '0'..'9')
}

private fun isWordAt(text: String, offset: Int, length: Int): Boolean {
    if (offset < 0 || offset + length > text.length) return false
    val leftOk = (offset == 0 || isWordBoundaryChar(text[offset - 1]))
    val rightOk = (offset + length == text.length || isWordBoundaryChar(text[offset + length]))
    return leftOk && rightOk
}

private fun hasWordBoundaryMatch(text: String, token: String, firstMatchOffset: Int): Boolean {
    val tokenLen = token.length
    if (isWordAt(text, firstMatchOffset, tokenLen)) return true
    var index = text.indexOf(token, firstMatchOffset + 1)
    while (index >= 0) {
        if (isWordAt(text, index, tokenLen)) {
            return true
        }
        index = text.indexOf(token, index + 1)
    }
    return false
}

fun isSchoolAcronymMatch(queryOrToken: String, normalizedTitle: String): Boolean {
    if (queryOrToken.isEmpty() || normalizedTitle.isEmpty()) return false
    return when (queryOrToken) {
        "btvn" -> normalizedTitle.contains("bai tap ve nha")
        "kt" -> normalizedTitle.contains("kiem tra")
        "15p" -> normalizedTitle.contains("15 phut")
        "45p" -> normalizedTitle.contains("45 phut")
        "gk" -> normalizedTitle.contains("giua ki") || normalizedTitle.contains("giua ky")
        "ck" -> normalizedTitle.contains("cuoi ki") || normalizedTitle.contains("cuoi ky")
        "th" -> normalizedTitle.contains("thuc hanh")
        "cd" -> normalizedTitle.contains("chuyen de")
        "sgk" -> normalizedTitle.contains("sach giao khoa")
        "sbt" -> normalizedTitle.contains("sach bai tap")
        "bai tap ve nha" -> {
            val idx = normalizedTitle.indexOf("btvn")
            idx >= 0 && isWordAt(normalizedTitle, idx, 4)
        }
        "kiem tra" -> {
            val idx = normalizedTitle.indexOf("kt")
            idx >= 0 && isWordAt(normalizedTitle, idx, 2)
        }
        "15 phut" -> {
            val idx = normalizedTitle.indexOf("15p")
            idx >= 0 && isWordAt(normalizedTitle, idx, 3)
        }
        "45 phut" -> {
            val idx = normalizedTitle.indexOf("45p")
            idx >= 0 && isWordAt(normalizedTitle, idx, 3)
        }
        else -> false
    }
}

fun calculateSearchRelevance(
    queryTokens: List<String>,
    rawNormalizedQuery: String,
    title: String,
    courseName: String? = null,
    content: String? = null,
    normalizedTitle: String? = null,
    normalizedCourseName: String? = null,
    normalizedContent: String? = null,
    checklistTitles: List<String> = emptyList()
): Int {
    val tokenCount = queryTokens.size
    if (tokenCount == 0) return 0
    val normTitle = normalizedTitle ?: title.normalizeForVietnameseSearch()
    val normCourse = normalizedCourseName ?: (if (courseName.isNullOrEmpty()) "" else courseName.normalizeForVietnameseSearch())
    val normContent = normalizedContent ?: (if (content.isNullOrEmpty()) "" else content.normalizeForVietnameseSearch())

    val titleLen = normTitle.length
    val courseLen = normCourse.length
    val contentLen = normContent.length

    if (titleLen == 0 && courseLen == 0 && contentLen == 0 && checklistTitles.isEmpty()) return 0
    var score = 0

    val rawQueryLen = rawNormalizedQuery.length
    var titleIdx = -1
    var courseIdx = -1
    if (rawQueryLen > 0) {
        if (titleLen >= rawQueryLen) {
            titleIdx = normTitle.indexOf(rawNormalizedQuery)
            if (titleIdx == 0) {
                score += if (titleLen == rawQueryLen) 200 else 120
            } else if (titleIdx > 0) {
                score += 80
            }
        }
        if (courseLen >= rawQueryLen) {
            courseIdx = normCourse.indexOf(rawNormalizedQuery)
            if (courseIdx == 0) {
                score += if (courseLen == rawQueryLen) 100 else 60
            } else if (courseIdx > 0) {
                score += 40
            }
        }
        if (isSchoolAcronymMatch(rawNormalizedQuery, normTitle)) {
            score += 70
        }
    }
    if (tokenCount == 1 && rawQueryLen > 0 && queryTokens[0] == rawNormalizedQuery) {
        val token = rawNormalizedQuery
        if (titleLen >= rawQueryLen && titleIdx >= 0) {
            score += 30
            if (hasWordBoundaryMatch(normTitle, token, titleIdx)) {
                score += 15
            }
        }
        if (courseLen >= rawQueryLen && courseIdx >= 0) {
            score += 15
        }
        if (contentLen >= rawQueryLen && normContent.indexOf(token) >= 0) {
            score += 5
        }
        if (titleIdx < 0 && courseIdx < 0) {
            val altTok = cleanTelexKeystrokes(token)
            if (altTok != token) {
                val altLen = altTok.length
                if (titleLen >= altLen) {
                    val altIdx = normTitle.indexOf(altTok)
                    if (altIdx >= 0) {
                        score += 20
                        if (hasWordBoundaryMatch(normTitle, altTok, altIdx)) {
                            score += 10
                        }
                    }
                }
                if (courseLen >= altLen && normCourse.indexOf(altTok) >= 0) {
                    score += 10
                }
                if (contentLen >= altLen && normContent.indexOf(altTok) >= 0) {
                    score += 4
                }
            }
        }
        if (checklistTitles.isNotEmpty()) {
            for (rawChecklistTitle in checklistTitles) {
                val normItem = rawChecklistTitle.normalizeForVietnameseSearch()
                if (normItem.contains(rawNormalizedQuery)) {
                    score += 5
                }
            }
        }
        return score
    }

    var allMatchedTitle = true
    var allMatchedEither = true

    for (i in 0 until tokenCount) {
        val token = queryTokens[i]
        val tokenLen = token.length
        if (tokenLen == 0) continue
        var matchedTitle = false
        var matchedCourse = false

        if (titleLen >= tokenLen) {
            val matchIdx = normTitle.indexOf(token)
            if (matchIdx >= 0) {
                score += 30
                matchedTitle = true
                if (hasWordBoundaryMatch(normTitle, token, matchIdx)) {
                    score += 15
                }
            }
        }
        if (courseLen >= tokenLen && normCourse.indexOf(token) >= 0) {
            score += 15
            matchedCourse = true
        }
        if (contentLen >= tokenLen && normContent.indexOf(token) >= 0) {
            score += 5
        }

        if (!matchedTitle && !matchedCourse) {
            val altTok = cleanTelexKeystrokes(token)
            if (altTok != token) {
                val altLen = altTok.length
                if (titleLen >= altLen) {
                    val altIdx = normTitle.indexOf(altTok)
                    if (altIdx >= 0) {
                        score += 20
                        matchedTitle = true
                        if (hasWordBoundaryMatch(normTitle, altTok, altIdx)) {
                            score += 10
                        }
                    }
                }
                if (courseLen >= altLen && normCourse.indexOf(altTok) >= 0) {
                    score += 10
                    matchedCourse = true
                }
            }
        }

        if (isSchoolAcronymMatch(token, normTitle)) {
            score += 35
            matchedTitle = true
        }

        if (!matchedTitle) allMatchedTitle = false
        if (!matchedTitle && !matchedCourse) allMatchedEither = false
    }

    if (tokenCount > 1) {
        if (allMatchedTitle) {
            score += 50
        } else if (allMatchedEither) {
            score += 25
        }
    }

    if (checklistTitles.isNotEmpty()) {
        for (rawChecklistTitle in checklistTitles) {
            val normItem = rawChecklistTitle.normalizeForVietnameseSearch()
            val normItemLen = normItem.length
            if (rawQueryLen > 0 && normItemLen >= rawQueryLen) {
                if (normItem == rawNormalizedQuery) {
                    score += 60
                } else if (normItem.contains(rawNormalizedQuery)) {
                    score += 30
                }
            }
            for (i in 0 until tokenCount) {
                val token = queryTokens[i]
                if (token.isNotEmpty() && normItem.contains(token)) {
                    score += 8
                }
            }
        }
    }
    return score
}
