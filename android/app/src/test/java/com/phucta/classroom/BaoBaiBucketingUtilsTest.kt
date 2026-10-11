package com.phucta.classroom

import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.data.model.SubmissionStatus
import com.phucta.classroom.domain.BaoBaiBucketingUtils
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar

class BaoBaiBucketingUtilsTest {

    @Test
    fun testSorting_IncompleteFirst() {
        val now = System.currentTimeMillis()
        val item1 = Coursework(
            id = "1",
            courseId = "c1",
            courseName = "Toán",
            title = "Bài 1",
            dueEpochMillis = now + 10000,
            status = SubmissionStatus.TURNED_IN
        )
        val item2 = Coursework(
            id = "2",
            courseId = "c1",
            courseName = "Toán",
            title = "Bài 2",
            dueEpochMillis = now + 50000,
            status = SubmissionStatus.PENDING
        )

        val sorted = BaoBaiBucketingUtils.sortCoursework(listOf(item1, item2))
        assertEquals("2", sorted.first().id) // Incomplete first
        assertEquals("1", sorted.last().id)
    }

    @Test
    fun testBaoBaiTomorrowPriority() {
        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 12)
            set(Calendar.MINUTE, 0)
        }
        val today = cal.timeInMillis

        cal.add(Calendar.DAY_OF_YEAR, 1)
        val tomorrow = cal.timeInMillis

        val taskToday = Coursework(
            id = "today_task",
            courseId = "c1",
            courseName = "Lý",
            title = "Bài nộp hôm nay",
            dueEpochMillis = today,
            status = SubmissionStatus.PENDING
        )
        val taskTomorrow = Coursework(
            id = "tomorrow_task",
            courseId = "c1",
            courseName = "Hóa",
            title = "Bài nộp ngày mai",
            dueEpochMillis = tomorrow,
            status = SubmissionStatus.PENDING
        )

        val tomorrowBatch = BaoBaiBucketingUtils.getTomorrowCoursework(listOf(taskToday, taskTomorrow))
        assertTrue(tomorrowBatch.any { it.id == "tomorrow_task" })
    }

    @Test
    fun testBaoBaiFallback_WhenTomorrowEmpty() {
        val cal = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 4) // In 4 days
        }
        val inFourDays = cal.timeInMillis

        val futureTask = Coursework(
            id = "future_task",
            courseId = "c1",
            courseName = "Sinh",
            title = "Bài tuần sau",
            dueEpochMillis = inFourDays,
            status = SubmissionStatus.PENDING
        )

        // Tomorrow is empty, should fallback to future upcoming task
        val fallbackBatch = BaoBaiBucketingUtils.getTomorrowCoursework(listOf(futureTask))
        assertFalse(fallbackBatch.isEmpty())
        assertEquals("future_task", fallbackBatch.first().id)
    }

    @Test
    fun testBaoBaiTomorrowPriority_DoesNotMixPastOverdue() {
        val cal = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, -2) // 2 days ago (overdue)
        }
        val pastDue = cal.timeInMillis

        cal.timeInMillis = System.currentTimeMillis()
        cal.add(Calendar.DAY_OF_YEAR, 1) // Tomorrow
        val tomorrow = cal.timeInMillis

        val taskOverdue = Coursework(
            id = "overdue_task",
            courseId = "c1",
            courseName = "Lý",
            title = "Bài quá hạn 2 ngày trước",
            dueEpochMillis = pastDue,
            status = SubmissionStatus.PENDING
        )
        val taskTomorrow = Coursework(
            id = "tomorrow_task",
            courseId = "c1",
            courseName = "Hóa",
            title = "Bài nộp ngày mai",
            dueEpochMillis = tomorrow,
            status = SubmissionStatus.PENDING
        )

        val tomorrowBatch = BaoBaiBucketingUtils.getTomorrowCoursework(listOf(taskOverdue, taskTomorrow))
        assertEquals(1, tomorrowBatch.size)
        assertEquals("tomorrow_task", tomorrowBatch.first().id)
    }

    @Test
    fun testBaoBai_OverdueIsConsideredCompleted_AndNotShownAsPending() {
        val cal = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, -1) // Yesterday
        }
        val yesterday = cal.timeInMillis

        val taskOverdue = Coursework(
            id = "overdue_task",
            courseId = "c1",
            courseName = "Sử",
            title = "Bài chưa nộp hôm qua",
            dueEpochMillis = yesterday,
            status = SubmissionStatus.PENDING
        )

        // Triết lý: Cứ hết hạn thì tính là đã hoàn thành
        assertTrue(taskOverdue.isCompleted)
        assertFalse(taskOverdue.isOverdue)

        val batch = BaoBaiBucketingUtils.getTomorrowCoursework(listOf(taskOverdue))
        assertTrue(batch.isEmpty())
    }

    @Test
    fun testComputeBuckets_OverdueEarlierTodayIsCompleted() {
        val oneHourAgo = System.currentTimeMillis() - 3600_000

        val taskEarlierToday = Coursework(
            id = "earlier_today",
            courseId = "c1",
            courseName = "Toán",
            title = "Bài hạn 1 tiếng trước",
            dueEpochMillis = oneHourAgo,
            status = SubmissionStatus.PENDING
        )

        assertTrue(taskEarlierToday.isCompleted)
        val buckets = BaoBaiBucketingUtils.computeBuckets(listOf(taskEarlierToday), emptyList())
        assertEquals(0, buckets.overdue.size)
        assertEquals(1, buckets.completed.size)
        assertEquals("earlier_today", buckets.completed.first().id)
        assertEquals(0, buckets.today.size)
    }

    @Test
    fun testBaoBaiExcludesTodayCompletedTask() {
        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 12)
            set(Calendar.MINUTE, 0)
        }
        val today = cal.timeInMillis

        cal.add(Calendar.DAY_OF_YEAR, 1)
        val tomorrow = cal.timeInMillis

        val taskTodayCompleted = Coursework(
            id = "today_completed",
            courseId = "c1",
            courseName = "Lý",
            title = "Bài đã làm xong hôm nay",
            dueEpochMillis = today,
            status = SubmissionStatus.TURNED_IN
        )
        val taskTomorrow = Coursework(
            id = "tomorrow_task",
            courseId = "c1",
            courseName = "Hóa",
            title = "Bài ngày mai",
            dueEpochMillis = tomorrow,
            status = SubmissionStatus.PENDING
        )

        val batch = BaoBaiBucketingUtils.getTomorrowCoursework(listOf(taskTodayCompleted, taskTomorrow))
        assertEquals(1, batch.size)
        assertEquals("tomorrow_task", batch.first().id)
    }

    @Test
    fun testSorting_DeterministicTieBreakerById() {
        val now = System.currentTimeMillis()
        val itemA = Coursework(
            id = "task_a",
            courseId = "c1",
            courseName = "Toán",
            title = "Cùng tiêu đề",
            dueEpochMillis = now + 10000,
            status = SubmissionStatus.PENDING
        )
        val itemB = Coursework(
            id = "task_b",
            courseId = "c1",
            courseName = "Toán",
            title = "Cùng tiêu đề",
            dueEpochMillis = now + 10000,
            status = SubmissionStatus.PENDING
        )

        val sorted1 = BaoBaiBucketingUtils.sortCoursework(listOf(itemB, itemA))
        assertEquals("task_a", sorted1[0].id)
        assertEquals("task_b", sorted1[1].id)

        val sorted2 = BaoBaiBucketingUtils.sortCoursework(listOf(itemA, itemB))
        assertEquals("task_a", sorted2[0].id)
        assertEquals("task_b", sorted2[1].id)
    }

    @Test
    fun testManualCompletion_OverridesPendingAndFutureDue() {
        val futureDue = System.currentTimeMillis() + 86400_000
        val normalPending = Coursework(
            id = "pending_task",
            courseId = "c1",
            courseName = "Vật lý",
            title = "Bài tập con lắc",
            dueEpochMillis = futureDue,
            status = SubmissionStatus.PENDING,
            isManuallyCompleted = false
        )
        assertFalse(normalPending.isCompleted)

        val manuallyChecked = normalPending.copy(isManuallyCompleted = true)
        assertTrue(manuallyChecked.isCompleted)
    }

    @Test
    fun testCourseFiltering_ExcludesUnselectedCourses() {
        val course1 = com.phucta.classroom.data.model.Course(id = "c1", name = "Toán", isSelectedForWidget = true)
        val course2 = com.phucta.classroom.data.model.Course(id = "c2", name = "Văn", isSelectedForWidget = false)

        val task1 = Coursework(id = "t1", courseId = "c1", courseName = "Toán", title = "Toán 1")
        val task2 = Coursework(id = "t2", courseId = "c2", courseName = "Văn", title = "Văn 1")

        val filtered = BaoBaiBucketingUtils.filterByActiveCourses(listOf(task1, task2), listOf(course1, course2))
        assertEquals(1, filtered.size)
        assertEquals("t1", filtered.first().id)
    }

    @Test
    fun testSorting_PlacesCompletedItemsAtTheBottom() {
        val now = System.currentTimeMillis()
        val completedTask = Coursework(
            id = "done_task",
            courseId = "c1",
            courseName = "Toán",
            title = "A Task Done",
            dueEpochMillis = now + 1000,
            status = SubmissionStatus.TURNED_IN
        )
        val incompleteTask = Coursework(
            id = "pending_task",
            courseId = "c1",
            courseName = "Toán",
            title = "Z Task Pending",
            dueEpochMillis = now + 5000,
            status = SubmissionStatus.PENDING
        )

        val sorted = BaoBaiBucketingUtils.sortCoursework(listOf(completedTask, incompleteTask))
        assertEquals("pending_task", sorted[0].id)
        assertEquals("done_task", sorted[1].id)
    }
}
