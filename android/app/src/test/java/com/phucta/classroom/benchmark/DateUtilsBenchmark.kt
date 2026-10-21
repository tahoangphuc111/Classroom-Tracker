package com.phucta.classroom.benchmark

import com.phucta.classroom.data.model.ClassroomDateUtils
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar

class DateUtilsBenchmark {
    @Test
    fun benchmarkEnsureDayBoundaries() {
        val callCount = 100_000
        val baseNow = System.currentTimeMillis()

        val timestamps = LongArray(callCount) { index ->
            baseNow + (index % 50_000L)
        }

        val stats = BenchmarkHarness.run(
            name = "ClassroomDateUtils.ensureDayBoundaries (100,000 calls)",
            warmupCycles = 4,
            timedCycles = 8,
            opsPerCycle = callCount.toLong()
        ) {
            var sumStartOfToday = 0L
            for (i in 0 until callCount) {
                ClassroomDateUtils.ensureDayBoundaries(timestamps[i])
                sumStartOfToday += ClassroomDateUtils.startOfToday
            }
            sumStartOfToday
        }

        assertTrue("Boundary checking throughput should exceed 5,000,000 ops/sec", stats.opsPerSec > 5_000_000)
        assertTrue("Mean latency for 100k boundary checks should be < 20 ms", stats.meanMillis < 20.0)
    }

    @Test
    fun benchmarkFriendlyDueStringFormatting() {
        ClassroomDateUtils.ensureDayBoundaries()
        val now = System.currentTimeMillis()
        val startOfToday = ClassroomDateUtils.startOfToday
        val startOfTomorrow = ClassroomDateUtils.startOfTomorrow
        val startOfDayAfter = ClassroomDateUtils.startOfDayAfter

        val timestampTemplates = listOf(
            null,
            startOfToday - 3600_000L * 24,
            startOfToday - 3600_000L * 72,
            now - 1800_000L,
            startOfToday + 3600_000L * 9,
            startOfToday + 3600_000L * 14 + 1800_000L,
            startOfTomorrow - 60_000L,
            startOfTomorrow + 3600_000L * 8,
            startOfTomorrow + 3600_000L * 16,
            startOfDayAfter - 60_000L,
            startOfDayAfter + 3600_000L * 24,
            startOfDayAfter + 3600_000L * 72,
            startOfDayAfter + 3600_000L * 168
        )

        val datasetSize = 10_000
        val testTimestamps = ArrayList<Pair<Long?, Boolean>>(datasetSize)
        for (i in 0 until datasetSize) {
            val ts = timestampTemplates[i % timestampTemplates.size]
            val isCompleted = (i % 5 == 0)
            testTimestamps.add(ts to isCompleted)
        }

        val stats = BenchmarkHarness.run(
            name = "Friendly Due Date String Formatting (10,000 timestamps)",
            warmupCycles = 4,
            timedCycles = 8,
            opsPerCycle = datasetSize.toLong()
        ) {
            var totalStringLength = 0
            for ((dueMillis, isCompleted) in testTimestamps) {
                val formatted = ClassroomDateUtils.friendlyDueString(dueMillis, isCompleted)
                totalStringLength += formatted.length
            }
            totalStringLength
        }

        assertTrue("Date formatting throughput should exceed 100,000 ops/sec", stats.opsPerSec > 100_000)
        assertTrue("Formatting 10k timestamps should complete in < 100 ms", stats.meanMillis < 100.0)
    }
}
