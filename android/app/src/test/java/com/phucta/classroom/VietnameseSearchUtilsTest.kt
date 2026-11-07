package com.phucta.classroom

import com.phucta.classroom.data.model.normalizeForVietnameseSearch
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class VietnameseSearchUtilsTest {
    @Test
    fun testDiacriticRemovalAndNormalizing() {
        val input = "Giải tích & Hình học không gian"
        val normalized = input.normalizeForVietnameseSearch()
        assertEquals("giai tich & hinh hoc khong gian", normalized)
    }

    @Test
    fun testLetterDReplacement() {
        val input = "Đại số và Đạo hàm"
        val normalized = input.normalizeForVietnameseSearch()
        assertEquals("dai so va dao ham", normalized)
        assertTrue(normalized.startsWith("d"))
    }

    @Test
    fun testVietnameseToneMarks() {
        val input = "Bài tập thực hành tuần 1"
        val normalized = input.normalizeForVietnameseSearch()
        assertEquals("bai tap thuc hanh tuan 1", normalized)
    }

    @Test
    fun testEmptyAndWhitespace() {
        assertEquals("", "".normalizeForVietnameseSearch())
        assertEquals("toan", "   Toán   ".normalizeForVietnameseSearch())
    }

    @Test
    fun testAllVowelsAndAccents() {
        val accentedA = "aàáảãạăằắẳẵặâầấẩẫậ"
        assertEquals("aaaaaaaaaaaaaaaaaa", accentedA.normalizeForVietnameseSearch())

        val accentedE = "eèéẻẽẹêềếểễệ"
        assertEquals("eeeeeeeeeeee", accentedE.normalizeForVietnameseSearch())

        val accentedI = "iìíỉĩị"
        assertEquals("iiiiii", accentedI.normalizeForVietnameseSearch())

        val accentedO = "oòóỏõọôồốổỗộơờớởỡợ"
        assertEquals("oooooooooooooooooo", accentedO.normalizeForVietnameseSearch())

        val accentedU = "uùúủũụưừứửữự"
        assertEquals("uuuuuuuuuuuu", accentedU.normalizeForVietnameseSearch())

        val accentedY = "yỳýỷỹỵ"
        assertEquals("yyyyyy", accentedY.normalizeForVietnameseSearch())

        val dChar = "dđ"
        assertEquals("dd", dChar.normalizeForVietnameseSearch())
    }

    @Test
    fun testUppercaseVowelsAndAccents() {
        val uppercaseInput = "TOÁN HỌC VÀ ĐỊA LÝ LỚP 12"
        assertEquals("toan hoc va dia ly lop 12", uppercaseInput.normalizeForVietnameseSearch())
    }

    @Test
    fun testCombiningDiacriticsRemoval() {
        val nfdString = "To\u0301an"
        assertEquals("toan", nfdString.normalizeForVietnameseSearch())
    }

    @Test
    fun testSearchRelevanceScoring() {
        val tokens = listOf("giai", "tich")
        val rawQuery = "giai tich"

        val exactScore = com.phucta.classroom.data.model.calculateSearchRelevance(
            queryTokens = tokens,
            rawNormalizedQuery = rawQuery,
            title = "Giải tích",
            courseName = "Toán 12",
            content = "Lý thuyết"
        )

        val prefixScore = com.phucta.classroom.data.model.calculateSearchRelevance(
            queryTokens = tokens,
            rawNormalizedQuery = rawQuery,
            title = "Giải tích chương 1",
            courseName = "Toán 12",
            content = "Lý thuyết"
        )

        val contentScore = com.phucta.classroom.data.model.calculateSearchRelevance(
            queryTokens = tokens,
            rawNormalizedQuery = rawQuery,
            title = "Bài tập về nhà",
            courseName = "Toán 12",
            content = "Làm bài tập giải tích SGK trang 45"
        )

        assertTrue("Exact title match must score higher than prefix", exactScore > prefixScore)
        assertTrue("Prefix title match must score higher than content match", prefixScore > contentScore)
    }

    @Test
    fun testTokenizeSearchQuery_CharLoopFastSlicing() {
        assertEquals(emptyList<String>(), com.phucta.classroom.data.model.tokenizeSearchQuery(""))
        assertEquals(emptyList<String>(), com.phucta.classroom.data.model.tokenizeSearchQuery("   "))
        assertEquals(listOf("toan"), com.phucta.classroom.data.model.tokenizeSearchQuery("toan"))
        assertEquals(listOf("toan"), com.phucta.classroom.data.model.tokenizeSearchQuery("  toan  "))
        assertEquals(
            listOf("giai", "tich", "12"),
            com.phucta.classroom.data.model.tokenizeSearchQuery("  giai   tich \t 12 \n ")
        )
    }

    @Test
    fun testNormalizeFastPath_PureAscii() {
        val pureAscii = "toan hoc 12"
        val result = pureAscii.normalizeForVietnameseSearch()
        org.junit.Assert.assertSame(pureAscii, result)

        val singleWord = "algebra"
        org.junit.Assert.assertSame(singleWord, singleWord.normalizeForVietnameseSearch())
    }

    @Test
    fun testCalculateSearchRelevance_PreNormalizedFields() {
        val tokens = listOf("giai", "tich")
        val rawQuery = "giai tich"
        val title = "Giải tích"
        val normTitle = title.normalizeForVietnameseSearch()
        val courseName = "Toán 12"
        val normCourse = courseName.normalizeForVietnameseSearch()

        val scoreWithoutPreNormalized = com.phucta.classroom.data.model.calculateSearchRelevance(
            queryTokens = tokens,
            rawNormalizedQuery = rawQuery,
            title = title,
            courseName = courseName
        )

        val scoreWithPreNormalized = com.phucta.classroom.data.model.calculateSearchRelevance(
            queryTokens = tokens,
            rawNormalizedQuery = rawQuery,
            title = title,
            courseName = courseName,
            normalizedTitle = normTitle,
            normalizedCourseName = normCourse
        )

        assertEquals("Scores must match identically when using pre-normalized fields", scoreWithoutPreNormalized, scoreWithPreNormalized)
    }

    @Test
    fun testCoursework_PreNormalizedFieldsStored() {
        val item = com.phucta.classroom.data.model.Coursework(
            id = "cw1",
            courseId = "c1",
            courseName = "Toán Cao Cấp",
            title = "Đại số tuyến tính"
        )
        assertEquals("dai so tuyen tinh", item.normalizedTitle)
        assertEquals("toan cao cap", item.normalizedCourseName)
    }

    @Test
    fun testTokenizeSearchQuery_WithPunctuation() {
        val tokensWithComma = com.phucta.classroom.data.model.tokenizeSearchQuery("Toán, Lý".normalizeForVietnameseSearch())
        assertEquals(listOf("toan", "ly"), tokensWithComma)

        val tokensWithDashAndBrackets = com.phucta.classroom.data.model.tokenizeSearchQuery("Toán - Đại số (chương 1)".normalizeForVietnameseSearch())
        assertEquals(listOf("toan", "dai", "so", "chuong", "1"), tokensWithDashAndBrackets)
    }

    @Test
    fun testCalculateSearchRelevance_ChecklistTitles() {
        val note = com.phucta.classroom.data.model.PersonalNote(
            id = "note_test",
            title = "Chuẩn bị bài tập",
            content = "Xem lại sách giáo khoa",
            checklist = listOf(
                com.phucta.classroom.data.model.ChecklistItem(id = "item1", title = "Làm đề thi thử"),
                com.phucta.classroom.data.model.ChecklistItem(id = "item2", title = "Mang máy tính Casio")
            )
        )

        val tokensExact = com.phucta.classroom.data.model.tokenizeSearchQuery("Làm đề thi thử")
        val scoreExactChecklist = note.searchRelevanceScore(tokensExact, "lam de thi thu")
        assertTrue("Checklist exact match must produce high score", scoreExactChecklist >= 60)

        val tokensCasio = com.phucta.classroom.data.model.tokenizeSearchQuery("Casio")
        val scoreCasio = note.searchRelevanceScore(tokensCasio, "casio")
        assertTrue("Checklist token match must produce positive score", scoreCasio > 0)
    }
}
