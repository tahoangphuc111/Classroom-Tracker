package com.phucta.classroom.benchmark

import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.data.model.SubmissionStatus
import com.phucta.classroom.data.model.calculateSearchRelevance
import com.phucta.classroom.data.model.normalizeForVietnameseSearch
import com.phucta.classroom.data.model.tokenizeSearchQuery
import org.junit.Assert.assertTrue
import org.junit.Test

class VietnameseSearchBenchmark {
    @Test
    fun benchmarkDiacriticsNormalization() {
        val sampleTemplates = listOf(
            "Đề kiểm tra 15 phút Đại số và Giải tích lớp 12: Đạo hàm cấp 2 và vi phân",
            "Bài tập Hóa học hữu cơ: Dẫn xuất Halogen, Ancol và Phenol (tiết 4)",
            "Vật lý 11: Hiện tượng cảm ứng điện từ, suất điện động cảm ứng và tự cảm trong cuộn dây",
            "Ngữ văn 10: Phân tích tâm trạng người lính Tây Tiến trong bài thơ của Quang Dũng",
            "Tiếng Anh Unit 5: Inventions and Technological Advances in Modern Life - Reading Comprehension",
            "Lịch sử Việt Nam: Phong trào Cần Vương và các cuộc khởi nghĩa vũ trang cuối thế kỷ XIX",
            "Địa lý 12: Vấn đề khai thác thế mạnh ở vùng Duyên hải Nam Trung Bộ và Tây Nguyên",
            "Giáo dục công dân: Công dân với các quyền tự do cơ bản và nghĩa vụ với nhà nước",
            "Tin học: Cấu trúc dữ liệu danh sách liên kết kép và cây nhị phân tìm kiếm",
            "Sinh học: Cơ chế điều hòa hoạt động của gen - Cụm gen Operon Lac ở vi khuẩn E.coli",
            "To\u0301an ho\u0323c va\u0300 Đa\u0323i sô\u0301 (NFD Decomposed Unicode Characters)",
            "THI THỬ TỐT NGHIỆP TRUNG HỌC PHỔ THÔNG QUỐC GIA NĂM HỌC 2026 - MÔN TIẾNG ANH",
            "Công nghệ thông tin: Lập trình hướng đối tượng với Java và Kotlin coroutines",
            "Triết học Mác - Lênin: Mối quan hệ biện chứng giữa vật chất và ý thức",
            "Kinh tế chính trị: Quy luật giá trị và vai trò của nó trong nền kinh tế thị trường"
        )

        val datasetSize = 10_000
        val testStrings = ArrayList<String>(datasetSize)
        var totalBytes = 0L
        for (i in 0 until datasetSize) {
            val template = sampleTemplates[i % sampleTemplates.size]
            val str = "$template (Mã bài tập #$i - Thầy Phúc hướng dẫn)"
            testStrings.add(str)
            totalBytes += str.toByteArray(Charsets.UTF_8).size
        }

        val stats = BenchmarkHarness.run(
            name = "Vietnamese Diacritics Normalization (10,000 strings)",
            warmupCycles = 4,
            timedCycles = 8,
            opsPerCycle = datasetSize.toLong(),
            totalBytesProcessed = totalBytes
        ) {
            var totalLength = 0
            for (str in testStrings) {
                val normalized = str.normalizeForVietnameseSearch()
                totalLength += normalized.length
            }
            totalLength
        }

        assertTrue("Diacritics normalization throughput should exceed 50,000 ops/sec", stats.opsPerSec > 50_000)
        assertTrue("Mean latency per 10k batch should be under 200 ms", stats.meanMillis < 200.0)
    }

    @Test
    fun benchmarkSearchTokenization() {
        val rawQueries = listOf(
            "   toan    hinh    hoc   khong gian  ",
            "đại số giải tích 12",
            "hoa hoc huu co",
            "bai tap ve nha ly 11",
            "kiem tra 1 tiet anh van",
            "lich su viet nam chong phap",
            "  tin   hoc   ",
            "sinh hoc di truyen quan the",
            "gdcd phap luat doi song",
            "   \t\n   ",
            "de thi thu thpt quoc gia 2026 mon toan",
            "chuyen de dao ham tich phan",
            "lap trinh di dong android compose",
            "ngu van tay tien quang dung",
            "bai_tap_1"
        )

        val datasetSize = 10_000
        val queries = ArrayList<String>(datasetSize)
        for (i in 0 until datasetSize) {
            queries.add(rawQueries[i % rawQueries.size])
        }

        val stats = BenchmarkHarness.run(
            name = "Search Query Tokenization (10,000 queries)",
            warmupCycles = 4,
            timedCycles = 8,
            opsPerCycle = datasetSize.toLong()
        ) {
            var tokenCount = 0
            for (query in queries) {
                val tokens = tokenizeSearchQuery(query)
                tokenCount += tokens.size
            }
            tokenCount
        }

        assertTrue("Query tokenization throughput should exceed 200,000 ops/sec", stats.opsPerSec > 200_000)
        assertTrue("Mean latency per 10k queries should be under 50 ms", stats.meanMillis < 50.0)
    }

    @Test
    fun benchmarkSearchRelevanceScoring() {
        fun generateCourseworkPool(size: Int): List<Coursework> {
            val subjects = listOf("Toán Học", "Vật Lý", "Hóa Học", "Sinh Học", "Ngữ Văn", "Tiếng Anh", "Tin Học")
            val titles = listOf(
                "Giải tích chương 1: Đạo hàm và khảo sát hàm số",
                "Bài tập về nhà Giải tích ứng dụng",
                "Lý thuyết nguyên hàm và tích phân",
                "Kiểm tra 15 phút Giải tích",
                "Bài tập Hóa học đại cương",
                "Thí nghiệm Vật lý quang học",
                "Ôn tập thi học kỳ môn Toán",
                "Thực hành lập trình Kotlin Android",
                "Soạn văn bài thơ Tây Tiến",
                "Tiếng Anh luyện đề thi thử đại học"
            )

            val items = ArrayList<Coursework>(size)
            for (i in 0 until size) {
                val subject = subjects[i % subjects.size]
                val title = "${titles[i % titles.size]} - Bài $i"
                val desc = "Hướng dẫn chi tiết làm bài giải tích và toán học cho học sinh lớp 12"
                items.add(
                    Coursework(
                        id = "cw-$i",
                        courseId = "c-${i % 10}",
                        courseName = subject,
                        title = title,
                        description = desc,
                        dueEpochMillis = System.currentTimeMillis() + (i * 3600_000L),
                        status = SubmissionStatus.PENDING
                    )
                )
            }
            return items
        }

        val queryTokens = listOf("giai", "tich")
        val rawNormalizedQuery = "giai tich"

        val pool1000 = generateCourseworkPool(1_000)
        val stats1000 = BenchmarkHarness.run(
            name = "Search Relevance Scoring (1,000 Coursework Items)",
            warmupCycles = 4,
            timedCycles = 10,
            opsPerCycle = 1_000L
        ) {
            val scores = IntArray(pool1000.size) { index ->
                val item = pool1000[index]
                calculateSearchRelevance(
                    queryTokens = queryTokens,
                    rawNormalizedQuery = rawNormalizedQuery,
                    title = item.title,
                    courseName = item.courseName,
                    content = item.description
                )
            }
            val indices = Array(pool1000.size) { it }
            indices.sortWith { a, b -> scores[b].compareTo(scores[a]) }
            indices[0]
        }

        val pool10000 = generateCourseworkPool(10_000)
        val stats10000 = BenchmarkHarness.run(
            name = "Search Relevance Scoring (10,000 Coursework Items)",
            warmupCycles = 4,
            timedCycles = 10,
            opsPerCycle = 10_000L
        ) {
            val scores = IntArray(pool10000.size) { index ->
                val item = pool10000[index]
                calculateSearchRelevance(
                    queryTokens = queryTokens,
                    rawNormalizedQuery = rawNormalizedQuery,
                    title = item.title,
                    courseName = item.courseName,
                    content = item.description
                )
            }
            val indices = Array(pool10000.size) { it }
            indices.sortWith { a, b -> scores[b].compareTo(scores[a]) }
            indices[0]
        }

        assertTrue("Scoring 1,000 items should complete in < 25 ms", stats1000.meanMillis < 25.0)
        assertTrue("Scoring 10,000 items should complete in < 150 ms", stats10000.meanMillis < 150.0)
    }
}
