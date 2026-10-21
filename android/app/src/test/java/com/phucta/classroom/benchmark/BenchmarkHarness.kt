package com.phucta.classroom.benchmark

import java.util.Locale
import kotlin.math.sqrt

object BenchmarkHarness {
    data class BenchmarkStats(
        val name: String,
        val iterations: Int,
        val warmupIterations: Int,
        val operationsPerIteration: Long,
        val totalBytesProcessed: Long = 0L,
        val runDurationsNanos: List<Long>,
        val memoryDeltaBytes: Long = 0L
    ) {
        val totalOperations: Long = operationsPerIteration * iterations
        val meanNanos: Double = runDurationsNanos.average()
        val minNanos: Long = runDurationsNanos.minOrNull() ?: 0L
        val maxNanos: Long = runDurationsNanos.maxOrNull() ?: 0L

        val stdDevNanos: Double = run {
            if (runDurationsNanos.size <= 1) 0.0
            else {
                val variance = runDurationsNanos.map { (it - meanNanos) * (it - meanNanos) }.sum() / (runDurationsNanos.size - 1)
                sqrt(variance)
            }
        }
        val meanMillis: Double = meanNanos / 1_000_000.0
        val minMillis: Double = minNanos / 1_000_000.0
        val maxMillis: Double = maxNanos / 1_000_000.0
        val stdDevMillis: Double = stdDevNanos / 1_000_000.0
        val meanMicros: Double = meanNanos / 1_000.0
        val minMicros: Double = minNanos / 1_000.0
        val maxMicros: Double = maxNanos / 1_000.0
        val stdDevMicros: Double = stdDevNanos / 1_000.0
        val opsPerSec: Double = if (meanNanos > 0) {
            (operationsPerIteration * 1_000_000_000.0) / meanNanos
        } else 0.0

        val throughputMBPerSec: Double? = if (totalBytesProcessed > 0 && meanNanos > 0) {
            val bytesPerSec = (totalBytesProcessed * 1_000_000_000.0) / meanNanos
            bytesPerSec / (1024.0 * 1024.0)
        } else null
        val avgLatencyPerOpNanos: Double = if (operationsPerIteration > 0) {
            meanNanos / operationsPerIteration
        } else 0.0

        fun printReport() {
            val width = 78
            val divider = "=".repeat(width)
            val subDivider = "-".repeat(width)
            println("\n$divider")
            println(String.format(Locale.US, " BENCHMARK: %s", name))
            println(divider)
            println(String.format(Locale.US, " Warmup cycles : %d | Timed iterations: %d", warmupIterations, iterations))
            println(String.format(Locale.US, " Operations/iter: %,d | Total measured ops: %,d", operationsPerIteration, totalOperations))
            println(subDivider)
            println(" Execution Latency:")
            println(String.format(Locale.US, "   • Mean Time     : %10.3f ms  (%10.2f µs)", meanMillis, meanMicros))
            println(String.format(Locale.US, "   • Std Deviation : ±%9.3f ms  (±%9.2f µs)", stdDevMillis, stdDevMicros))
            println(String.format(Locale.US, "   • Min / Max     : %10.3f ms / %10.3f ms", minMillis, maxMillis))
            println(String.format(Locale.US, "   • Per-op Latency: %10.3f ns/op (%7.3f µs/op)", avgLatencyPerOpNanos, avgLatencyPerOpNanos / 1000.0))
            println(subDivider)
            println(" Throughput & Efficiency:")
            println(String.format(Locale.US, "   • Throughput    : %,12.0f ops/sec", opsPerSec))
            if (throughputMBPerSec != null) {
                println(String.format(Locale.US, "   • Data Rate     : %10.2f MB/sec (%,d bytes/iter)", throughputMBPerSec, totalBytesProcessed))
            }
            if (memoryDeltaBytes != 0L) {
                val memMb = memoryDeltaBytes / (1024.0 * 1024.0)
                println(String.format(Locale.US, "   • Memory Footprint: %+.2f MB heap delta across iterations", memMb))
            }
            println("$divider\n")
        }
    }
    fun run(
        name: String,
        warmupCycles: Int = 4,
        timedCycles: Int = 8,
        opsPerCycle: Long = 1L,
        totalBytesProcessed: Long = 0L,
        action: (iteration: Int) -> Any?
    ): BenchmarkStats {
        var blackhole: Any? = null
        for (i in 0 until warmupCycles) {
            blackhole = action(i)
        }
        System.gc()
        Thread.sleep(50)
        val initialMemory = Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory()
        val durations = ArrayList<Long>(timedCycles)
        for (i in 0 until timedCycles) {
            val startTime = System.nanoTime()
            blackhole = action(warmupCycles + i)
            val duration = System.nanoTime() - startTime
            durations.add(duration)
        }
        val finalMemory = Runtime.getRuntime().totalMemory() - Runtime.getRuntime().freeMemory()
        val memoryDelta = (finalMemory - initialMemory).coerceAtLeast(0L)

        if (blackhole == null && System.currentTimeMillis() == 0L) {
            println(blackhole)
        }
        val stats = BenchmarkStats(
            name = name,
            iterations = timedCycles,
            warmupIterations = warmupCycles,
            operationsPerIteration = opsPerCycle,
            totalBytesProcessed = totalBytesProcessed,
            runDurationsNanos = durations,
            memoryDeltaBytes = memoryDelta
        )
        stats.printReport()
        return stats
    }
}
