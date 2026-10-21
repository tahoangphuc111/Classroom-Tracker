package com.phucta.classroom.benchmark

import com.phucta.classroom.data.model.ClassroomDateUtils
import com.phucta.classroom.data.model.Course
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.data.model.SubmissionStatus
import com.phucta.classroom.domain.BaoBaiBucketingUtils
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test

class BaoBaiBucketingBenchmark {
    private fun createCourseList(): List<Course> {
        return listOf(
            Course(id = "c-1", name = "Toán Học 12", isSelectedForWidget = true),
            Course(id = "c-2", name = "Vật Lý 12", isSelectedForWidget = true),
            Course(id = "c-3", name = "Hóa Học 12", isSelectedForWidget = true),
            Course(id = "c-4", name = "Sinh Học 12", isSelectedForWidget = false),
            Course(id = "c-5", name = "Ngữ Văn 12", isSelectedForWidget = true),
            Course(id = "c-6", name = "Tiếng Anh 12", isSelectedForWidget = true),
            Course(id = "c-7", name = "Lịch Sử 12", isSelectedForWidget = false),
            Course(id = "c-8", name = "Địa Lý 12", isSelectedForWidget = true),
            Course(id = "c-9", name = "GDCD 12", isSelectedForWidget = true),
            Course(id = "c-10", name = "Tin Học 12", isSelectedForWidget = true)
        )
    }

    private fun generateCourseworkItems(count: Int, courses: List<Course>): List<Coursework> {
        ClassroomDateUtils.ensureDayBoundaries()
        val now = System.currentTimeMillis()
        val startOfToday = ClassroomDateUtils.startOfToday
        val startOfTomorrow = ClassroomDateUtils.startOfTomorrow
        val startOfDayAfter = ClassroomDateUtils.startOfDayAfter

        val items = ArrayList<Coursework>(count)
        val statuses = listOf(SubmissionStatus.PENDING, SubmissionStatus.TURNED_IN, SubmissionStatus.RETURNED)

        for (i in 0 until count) {
            val course = courses[i % courses.size]
            val status = statuses[i % statuses.size]

            val dueMillis: Long? = when (i % 6) {
                0 -> startOfToday - 3600_000L * (1 + (i % 48))
                1 -> startOfToday + 3600_000L * 10
                2 -> startOfTomorrow + 3600_000L * 8
                3 -> startOfTomorrow + 3600_000L * 20
                4 -> startOfDayAfter + 3600_000L * (24 + (i % 168))
                else -> null
            }

            items.add(
                Coursework(
                    id = "item-$i",
                    courseId = course.id,
                    courseName = course.name,
                    title = "Bài tập ${course.name} số $i",
                    description = "Mô tả nội dung bài tập $i môn ${course.name}",
                    dueEpochMillis = dueMillis,
                    status = status,
                    isManuallyCompleted = (i % 17 == 0)
                )
            )
        }
        return items
    }

    @Test
    fun benchmarkBucketing1000Items() {
        val courses = createCourseList()
        val items = generateCourseworkItems(1_000, courses)

        val stats = BenchmarkHarness.run(
            name = "Coursework Bucketing & Sorting (1,000 Items across Active Courses)",
            warmupCycles = 4,
            timedCycles = 8,
            opsPerCycle = 1_000L
        ) {
            val buckets = BaoBaiBucketingUtils.computeBuckets(items, courses)
            buckets.widgetItems.size + buckets.allUpcoming.size
        }

        assertTrue("Bucketing 1,000 items should complete in under 20 ms", stats.meanMillis < 20.0)
        assertTrue("Bucketing throughput should exceed 50,000 items/sec", stats.opsPerSec > 50_000)
    }

    @Test
    fun benchmarkBucketing5000Items() {
        val courses = createCourseList()
        val items = generateCourseworkItems(5_000, courses)

        val stats = BenchmarkHarness.run(
            name = "Coursework Bucketing & Sorting (5,000 Items across Active Courses)",
            warmupCycles = 4,
            timedCycles = 8,
            opsPerCycle = 5_000L
        ) {
            val buckets = BaoBaiBucketingUtils.computeBuckets(items, courses)
            buckets.widgetItems.size + buckets.allUpcoming.size
        }

        assertTrue("Bucketing 5,000 items should scale linearly (< 80 ms)", stats.meanMillis < 80.0)
        assertTrue("Bucketing throughput on 5k items should exceed 60,000 items/sec", stats.opsPerSec > 60_000)
    }

    @Test
    fun benchmarkTomorrowCourseworkFallback() {
        val courses = createCourseList()
        ClassroomDateUtils.ensureDayBoundaries()
        val startOfToday = ClassroomDateUtils.startOfToday
        val startOfTomorrow = ClassroomDateUtils.startOfTomorrow
        val startOfDayAfter = ClassroomDateUtils.startOfDayAfter

        fun createItemsForScenario(
            hasTomorrow: Boolean,
            hasToday: Boolean,
            hasUpcoming: Boolean,
            hasUndated: Boolean
        ): List<Coursework> {
            val list = mutableListOf<Coursework>()
            var idCounter = 0

            if (hasTomorrow) {
                list.add(
                    Coursework(
                        id = "cw-tom-${idCounter++}",
                        courseId = "c-1",
                        courseName = "Toán Học",
                        title = "Bài tập ngày mai",
                        dueEpochMillis = startOfTomorrow + 3600_000L * 9
                    )
                )
            }
            if (hasToday) {
                list.add(
                    Coursework(
                        id = "cw-today-${idCounter++}",
                        courseId = "c-2",
                        courseName = "Vật Lý",
                        title = "Bài tập hôm nay",
                        dueEpochMillis = startOfToday + 3600_000L * 15
                    )
                )
            }
            if (hasUpcoming) {
                list.add(
                    Coursework(
                        id = "cw-up-${idCounter++}",
                        courseId = "c-3",
                        courseName = "Hóa Học",
                        title = "Bài tập tuần tới",
                        dueEpochMillis = startOfDayAfter + 3600_000L * 48
                    )
                )
            }
            if (hasUndated) {
                list.add(
                    Coursework(
                        id = "cw-no-${idCounter++}",
                        courseId = "c-5",
                        courseName = "Ngữ Văn",
                        title = "Bài đọc thêm không hạn",
                        dueEpochMillis = null
                    )
                )
            }
            return list
        }

        val scenarioTomorrow = createItemsForScenario(hasTomorrow = true, hasToday = true, hasUpcoming = true, hasUndated = true)
        val scenarioTodayFallback = createItemsForScenario(hasTomorrow = false, hasToday = true, hasUpcoming = true, hasUndated = true)
        val scenarioUpcomingFallback = createItemsForScenario(hasTomorrow = false, hasToday = false, hasUpcoming = true, hasUndated = true)
        val scenarioUndatedFallback = createItemsForScenario(hasTomorrow = false, hasToday = false, hasUpcoming = false, hasUndated = true)
        val scenarioEmptyFallback = emptyList<Coursework>()

        val scenarios = listOf(
            "Hit: Due Tomorrow" to scenarioTomorrow,
            "Fallback 1: Due Today" to scenarioTodayFallback,
            "Fallback 2: Later Upcoming" to scenarioUpcomingFallback,
            "Fallback 3: Undated Items" to scenarioUndatedFallback,
            "Fallback 4: Empty Exhaused" to scenarioEmptyFallback
        )

        val totalOps = 50_000L
        val iterationsPerScenario = (totalOps / scenarios.size).toInt()

        val stats = BenchmarkHarness.run(
            name = "Tomorrow Coursework Fallback Chain (50,000 iterations across 5 fallback states)",
            warmupCycles = 4,
            timedCycles = 8,
            opsPerCycle = totalOps
        ) {
            var totalResolved = 0
            for ((_, items) in scenarios) {
                for (i in 0 until iterationsPerScenario) {
                    val result = BaoBaiBucketingUtils.getTomorrowCoursework(items, courses)
                    totalResolved += result.size
                }
            }
            totalResolved
        }

        assertTrue("Fallback chain throughput should exceed 500,000 ops/sec", stats.opsPerSec > 500_000)
        assertTrue("Mean latency for 50k fallback evaluations should be < 50 ms", stats.meanMillis < 50.0)
    }

    @Test
    fun benchmarkSortingCoursework() {
        val courses = createCourseList()
        val items = generateCourseworkItems(1_000, courses)

        val statsDefault = BenchmarkHarness.run(
            name = "Coursework Default Sort (1,000 Items, Comparator only)",
            warmupCycles = 4,
            timedCycles = 10,
            opsPerCycle = 1_000L
        ) {
            val sorted = BaoBaiBucketingUtils.sortCoursework(items)
            sorted.size
        }

        val searchTokens = listOf("toan", "12")
        val rawNormalizedQuery = "toan 12"

        val statsSearch = BenchmarkHarness.run(
            name = "Coursework Search & Relevance Sort (1,000 Items, 2-token query)",
            warmupCycles = 4,
            timedCycles = 10,
            opsPerCycle = 1_000L
        ) {
            val sorted = BaoBaiBucketingUtils.sortCoursework(
                items = items,
                searchTokens = searchTokens,
                rawNormalizedQuery = rawNormalizedQuery
            )
            sorted.size
        }

        assertTrue("Default sort on 1,000 items should complete in < 5 ms", statsDefault.meanMillis < 5.0)
        assertTrue("Search-filtered sort on 1,000 items should complete in < 10 ms", statsSearch.meanMillis < 10.0)
    }
}
