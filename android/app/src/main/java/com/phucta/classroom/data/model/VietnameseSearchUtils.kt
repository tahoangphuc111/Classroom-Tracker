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

fun tokenizeSearchQuery(query: String): List<String> {
    val len = query.length
    if (len == 0) return emptyList()

    var start = -1
    var tokens: ArrayList<String>? = null

    for (i in 0 until len) {
        val ch = query[i]
        val isWs = ch <= ' ' || ch == '\u00A0'
        if (!isWs) {
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
    while (start < len && this[start] <= ' ') start++
    if (start == len) return ""

    var end = len - 1
    while (end > start && this[end] <= ' ') end--

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

    val outChars = CharArray(trimmedLen)
    var outPos = 0
    for (i in start..end) {
        val ch = this[i]
        val code = ch.code
        if (code < 0x1F00) {
            val mapped = VIETNAMESE_CHAR_MAP[code]
            if (mapped != SKIP_COMBINING_MARK) {
                outChars[outPos++] = mapped
            }
        } else {
            outChars[outPos++] = ch.lowercaseChar()
        }
    }

    val stripped = if (outPos == trimmedLen) String(outChars) else String(outChars, 0, outPos)
    if (len <= 128) {
        NORMALIZE_CACHE[this] = stripped
    }

    return stripped
}

private fun hasSubsequentWordBoundary(text: String, token: String, fromIndex: Int): Boolean {
    var index = text.indexOf(token, fromIndex + 1)
    while (index > 0) {
        if (text[index - 1] == ' ') {
            return true
        }
        index = text.indexOf(token, index + 1)
    }
    return false
}

fun calculateSearchRelevance(
    queryTokens: List<String>,
    rawNormalizedQuery: String,
    title: String,
    courseName: String? = null,
    content: String? = null,
    normalizedTitle: String? = null,
    normalizedCourseName: String? = null,
    normalizedContent: String? = null
): Int {
    val tokenCount = queryTokens.size
    if (tokenCount == 0) return 0
    val normTitle = normalizedTitle ?: title.normalizeForVietnameseSearch()
    val normCourse = normalizedCourseName ?: (if (courseName.isNullOrEmpty()) "" else courseName.normalizeForVietnameseSearch())
    val normContent = normalizedContent ?: (if (content.isNullOrEmpty()) "" else content.normalizeForVietnameseSearch())

    val titleLen = normTitle.length
    val courseLen = normCourse.length
    val contentLen = normContent.length

    if (titleLen == 0 && courseLen == 0 && contentLen == 0) return 0
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
    }
    if (tokenCount == 1 && rawQueryLen > 0 && queryTokens[0] == rawNormalizedQuery) {
        val token = rawNormalizedQuery
        if (titleLen >= rawQueryLen && titleIdx >= 0) {
            score += 30
            if (titleIdx == 0 || normTitle[titleIdx - 1] == ' ' || hasSubsequentWordBoundary(normTitle, token, titleIdx)) {
                score += 15
            }
        }
        if (courseLen >= rawQueryLen && courseIdx >= 0) {
            score += 15
        }
        if (contentLen >= rawQueryLen && normContent.indexOf(token) >= 0) {
            score += 5
        }
        return score
    }
    for (i in 0 until tokenCount) {
        val token = queryTokens[i]
        val tokenLen = token.length
        if (tokenLen == 0) continue
        if (titleLen >= tokenLen) {
            val matchIdx = normTitle.indexOf(token)
            if (matchIdx >= 0) {
                score += 30
                if (matchIdx == 0 || normTitle[matchIdx - 1] == ' ' || hasSubsequentWordBoundary(normTitle, token, matchIdx)) {
                    score += 15
                }
            }
        }
        if (courseLen >= tokenLen && normCourse.indexOf(token) >= 0) {
            score += 15
        }
        if (contentLen >= tokenLen && normContent.indexOf(token) >= 0) {
            score += 5
        }
    }
    return score
}
