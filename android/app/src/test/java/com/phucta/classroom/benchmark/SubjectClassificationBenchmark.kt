package com.phucta.classroom.benchmark

import com.phucta.classroom.ui.components.SubjectArtHelper
import com.phucta.classroom.ui.components.SubjectCategory
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.concurrent.Callable
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.Future

class SubjectClassificationBenchmark {
    companion object {
        fun clearSubjectCaches() {
            try {
                val helperClass = SubjectArtHelper::class.java
                val courseCacheField = helperClass.getDeclaredField("courseCategoryCache").apply { isAccessible = true }
                val compoundCacheField = helperClass.getDeclaredField("compoundCategoryCache").apply { isAccessible = true }
                val themeCacheField = helperClass.getDeclaredField("themeCache").apply { isAccessible = true }

                (courseCacheField.get(null) as? ConcurrentHashMap<*, *>)?.clear()
                (compoundCacheField.get(null) as? ConcurrentHashMap<*, *>)?.clear()
                (themeCacheField.get(null) as? ConcurrentHashMap<*, *>)?.clear()
            } catch (ignored: Exception) {}
        }
    }

    private val baseCourseTemplates = listOf(
        "Giải tích 12 nâng cao",
        "Đại số tuyến tính và hình học giải tích",
        "Calculus and Discrete Mathematics",
        "Toan roi rac va ly thuyet do thi",
        "Xác suất thống kê trong kinh tế",
        "Vật lý đại cương 1: Cơ học và Nhiệt học",
        "Quang học và Vật lý sóng",
        "Quản lý dự án CNTT",
        "Xử lý tín hiệu số",
        "Tâm lý học đại cương",
        "Pháp lý trong kinh doanh thương mại",
        "Lý luận chính trị",
        "Lý do chọn đề tài nghiên cứu",
        "Hóa học vô cơ và Hóa hữu cơ",
        "Biochemistry and Molecular Biology",
        "Tự động hóa quá trình sản xuất",
        "Hóa đơn chứng từ kế toán",
        "Văn hóa các dân tộc Việt Nam",
        "Tối ưu hóa thuật toán",
        "Số hóa tài liệu lưu trữ",
        "Sinh học tế bào và di truyền học",
        "Ecology and Environmental Biology",
        "Học sinh giỏi cấp quốc gia môn Văn",
        "Sinh viên nghiên cứu khoa học",
        "Sinh hoạt chủ nhiệm đầu tuần",
        "Lịch sử Việt Nam cận hiện đại",
        "World History and International Relations",
        "Sử dụng phần mềm mô phỏng",
        "Địa lý kinh tế xã hội Việt Nam",
        "Địa điểm và thời gian khảo sát thực tế",
        "Địa chỉ các cơ quan hành chính",
        "Ngữ văn 12: Đọc hiểu văn bản văn học",
        "Vietnamese Literature and Essay Writing",
        "Văn phòng phẩm và trang thiết bị",
        "Văn hóa học đường",
        "Luận văn tốt nghiệp thạc sĩ",
        "Tiếng Anh 12: IELTS Academic Skills",
        "English for Computer Science",
        "Hình ảnh minh họa bài giảng",
        "Âm thanh kỹ thuật số",
        "Thầy Tuấn chủ nhiệm lớp 12A1",
        "Giáo dục công dân 12: Kinh tế và pháp luật",
        "Triết học Mác - Lênin và Tư tưởng Hồ Chí Minh",
        "Pháp luật đại cương",
        "Mạng máy tính và truyền thông dữ liệu",
        "An ninh mạng và an toàn thông tin",
        "Cloud Computing Architecture",
        "Mạng xã hội và truyền thông đa phương tiện",
        "Kinh tế học vi mô và vĩ mô",
        "Quản trị kinh doanh quốc tế",
        "Tài chính doanh nghiệp và thị trường chứng khoán",
        "Thiết kế đồ họa và mỹ thuật ứng dụng",
        "UI UX Design with Figma",
        "Lập trình ứng dụng Android với Kotlin",
        "Cấu trúc dữ liệu và giải thuật nâng cao",
        "Khoa học máy tính và Trí tuệ nhân tạo",
        "Bản tin thời sự công nghệ",
        "Tin tức sự kiện tuần",
        "Niềm tin khách hàng",
        "Nhiệm vụ đồ án môn học học kỳ 1",
        "Bài tập thực hành Lab số 4",
        "Project Capstone tốt nghiệp",
        "Kỹ năng mềm và làm việc nhóm",
        "Hoạt động ngoại khóa dã ngoại"
    )

    private fun generateCourseTitles(size: Int): List<String> {
        val titles = ArrayList<String>(size)
        for (i in 0 until size) {
            val base = baseCourseTemplates[i % baseCourseTemplates.size]
            titles.add("$base (Lớp K${(i % 15) + 20}-NH$i)")
        }
        return titles
    }

    @Test
    fun benchmarkCategoryClassification() {
        val datasetSize = 5_000
        val titles = generateCourseTitles(datasetSize)

        clearSubjectCaches()

        val stats = BenchmarkHarness.run(
            name = "Subject Category Classification (5,000 Diverse Course Titles with Guards)",
            warmupCycles = 4,
            timedCycles = 8,
            opsPerCycle = datasetSize.toLong()
        ) {
            var mathCount = 0
            var physicsCount = 0
            var csCount = 0
            for (title in titles) {
                when (SubjectArtHelper.category(courseName = title)) {
                    SubjectCategory.MATH -> mathCount++
                    SubjectCategory.PHYSICS -> physicsCount++
                    SubjectCategory.COMPUTER_SCIENCE -> csCount++
                    else -> {}
                }
            }
            mathCount + physicsCount + csCount
        }

        assertTrue("Classification throughput should exceed 20,000 ops/sec", stats.opsPerSec > 20_000)
        assertTrue("Classifying 5,000 titles should complete in < 250 ms", stats.meanMillis < 250.0)
    }

    @Test
    fun benchmarkConcurrentCategoryLookup() {
        val datasetSize = 10_000
        val titles = generateCourseTitles(datasetSize)

        for (title in titles) {
            SubjectArtHelper.category(courseName = title)
        }

        val threadCount = Runtime.getRuntime().availableProcessors().coerceIn(4, 16)
        val executor = Executors.newFixedThreadPool(threadCount)
        val itemsPerThread = datasetSize / threadCount

        try {
            val stats = BenchmarkHarness.run(
                name = "Concurrent Category Lookup ($datasetSize lookups across $threadCount threads)",
                warmupCycles = 4,
                timedCycles = 8,
                opsPerCycle = datasetSize.toLong()
            ) {
                val tasks = ArrayList<Callable<Int>>(threadCount)
                for (t in 0 until threadCount) {
                    val startIdx = t * itemsPerThread
                    val endIdx = if (t == threadCount - 1) datasetSize else startIdx + itemsPerThread
                    tasks.add(Callable {
                        var sumCategories = 0
                        for (i in startIdx until endIdx) {
                            sumCategories += SubjectArtHelper.category(courseName = titles[i]).ordinal
                        }
                        sumCategories
                    })
                }

                val futures: List<Future<Int>> = executor.invokeAll(tasks)
                var total = 0
                for (f in futures) {
                    total += f.get()
                }
                total
            }

            assertTrue("Concurrent lookup throughput should exceed 2,000,000 ops/sec", stats.opsPerSec > 2_000_000)
            assertTrue("Mean concurrent latency for 10k lookups should be < 15 ms", stats.meanMillis < 15.0)
        } finally {
            executor.shutdown()
        }
    }
}
