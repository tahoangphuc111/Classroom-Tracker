package com.phucta.classroom

import com.phucta.classroom.data.local.toCoursework
import com.phucta.classroom.data.model.ClassroomDateUtils
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.data.model.PersonalNote
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
        assertEquals("2", sorted.first().id)
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
            add(Calendar.DAY_OF_YEAR, 4)
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

        val fallbackBatch = BaoBaiBucketingUtils.getTomorrowCoursework(listOf(futureTask))
        assertFalse(fallbackBatch.isEmpty())
        assertEquals("future_task", fallbackBatch.first().id)

        // Completed task due today must not block fallback to futureTask
        val now = System.currentTimeMillis()
        val todayEveningCal = Calendar.getInstance().apply {
            timeInMillis = now
            set(Calendar.HOUR_OF_DAY, 23)
            set(Calendar.MINUTE, 50)
        }
        val completedToday = Coursework(
            id = "today_finished",
            courseId = "c1",
            courseName = "Toán",
            title = "Đã làm xong chiều nay",
            dueEpochMillis = todayEveningCal.timeInMillis,
            status = SubmissionStatus.TURNED_IN,
            isManuallyCompleted = true
        )
        val fallbackWithCompletedToday = BaoBaiBucketingUtils.getTomorrowCoursework(
            listOf(completedToday, futureTask),
            includeCompleted = true
        )
        assertEquals(1, fallbackWithCompletedToday.size)
        assertEquals("future_task", fallbackWithCompletedToday.first().id)
    }

    @Test
    fun testBaoBaiTomorrowPriority_DoesNotMixPastOverdue() {
        val cal = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, -2)
        }
        val pastDue = cal.timeInMillis

        cal.timeInMillis = System.currentTimeMillis()
        cal.add(Calendar.DAY_OF_YEAR, 1)
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
            add(Calendar.DAY_OF_YEAR, -1)
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

    @Test
    fun testReconciliation_RemoteUnsubmitResetsToPending() {
        val cachedFromPreviousTurnIn = Coursework(
            id = "task_hw1",
            courseId = "c1",
            courseName = "Toán",
            title = "Bài tập đại số",
            status = SubmissionStatus.TURNED_IN,
            isManuallyCompleted = false
        )

        val incomingFromSync = Coursework(
            id = "task_hw1",
            courseId = "c1",
            courseName = "Toán",
            title = "Bài tập đại số",
            status = SubmissionStatus.PENDING,
            isManuallyCompleted = false
        )

        val wasManuallyCompleted = !incomingFromSync.isCompleted &&
                (cachedFromPreviousTurnIn.isManuallyCompleted)

        val reconciled = if (wasManuallyCompleted) {
            incomingFromSync.copy(status = SubmissionStatus.TURNED_IN, isManuallyCompleted = true)
        } else {
            incomingFromSync
        }

        assertEquals("Unsubmitted task must become PENDING again, not stuck in TURNED_IN", SubmissionStatus.PENDING, reconciled.status)
        assertFalse(reconciled.isCompleted)
    }

    @Test
    fun testReconciliation_LocalManualCompletionPreserved() {
        val locallyChecked = Coursework(
            id = "task_hw2",
            courseId = "c1",
            courseName = "Lý",
            title = "Bài tập quang học",
            status = SubmissionStatus.TURNED_IN,
            isManuallyCompleted = true
        )

        val incomingFromSync = Coursework(
            id = "task_hw2",
            courseId = "c1",
            courseName = "Lý",
            title = "Bài tập quang học",
            status = SubmissionStatus.PENDING,
            isManuallyCompleted = false
        )

        val wasManuallyCompleted = !incomingFromSync.isCompleted &&
                (locallyChecked.isManuallyCompleted)

        val reconciled = if (wasManuallyCompleted) {
            incomingFromSync.copy(status = SubmissionStatus.TURNED_IN, isManuallyCompleted = true)
        } else {
            incomingFromSync
        }

        assertEquals("Manual local completion must be preserved during sync", SubmissionStatus.TURNED_IN, reconciled.status)
        assertTrue(reconciled.isManuallyCompleted)
        assertTrue(reconciled.isCompleted)
    }

    @Test
    fun testReconciliation_LocalCompletionOverridesRemoteSync() {
        fun merge(latest: Coursework?, incoming: Coursework): Coursework {
            if (latest != null) {
                val localIsManuallyCompleted = latest.isManuallyCompleted
                val localIsCompleted = localIsManuallyCompleted ||
                        latest.status == SubmissionStatus.TURNED_IN ||
                        latest.status == SubmissionStatus.RETURNED

                val incomingIsPendingOrLate = incoming.status == SubmissionStatus.PENDING ||
                        incoming.status == SubmissionStatus.LATE

                val shouldPreserveLocalStatus = incomingIsPendingOrLate && localIsCompleted

                val resolvedStatus = if (shouldPreserveLocalStatus) latest.status else incoming.status
                val resolvedManuallyCompleted = localIsManuallyCompleted || incoming.isManuallyCompleted

                return incoming.copy(
                    status = resolvedStatus,
                    isManuallyCompleted = resolvedManuallyCompleted
                )
            } else {
                return incoming
            }
        }

        val localManual = Coursework(id = "1", courseId = "c", courseName = "Math", title = "T1", status = SubmissionStatus.TURNED_IN, isManuallyCompleted = true)
        val incomingPending = Coursework(id = "1", courseId = "c", courseName = "Math", title = "T1", status = SubmissionStatus.PENDING, isManuallyCompleted = false)
        val res1 = merge(localManual, incomingPending)
        assertEquals(SubmissionStatus.TURNED_IN, res1.status)
        assertTrue(res1.isManuallyCompleted)

        val incomingLate = Coursework(id = "1", courseId = "c", courseName = "Math", title = "T1", status = SubmissionStatus.LATE, isManuallyCompleted = false)
        val res2 = merge(localManual, incomingLate)
        assertEquals(SubmissionStatus.TURNED_IN, res2.status)
        assertTrue(res2.isManuallyCompleted)

        val incomingTurnedIn = Coursework(id = "1", courseId = "c", courseName = "Math", title = "T1", status = SubmissionStatus.TURNED_IN, isManuallyCompleted = false)
        val res3 = merge(localManual, incomingTurnedIn)
        assertEquals(SubmissionStatus.TURNED_IN, res3.status)
        assertTrue(res3.isManuallyCompleted)

        val localTurnedIn = Coursework(id = "2", courseId = "c", courseName = "Math", title = "T2", status = SubmissionStatus.TURNED_IN, isManuallyCompleted = false)
        val incomingPending2 = Coursework(id = "2", courseId = "c", courseName = "Math", title = "T2", status = SubmissionStatus.PENDING, isManuallyCompleted = false)
        val res4 = merge(localTurnedIn, incomingPending2)
        assertEquals(SubmissionStatus.TURNED_IN, res4.status)

        val localPending = Coursework(id = "3", courseId = "c", courseName = "Math", title = "T3", status = SubmissionStatus.PENDING, isManuallyCompleted = false)
        val res5 = merge(localPending, incomingTurnedIn)
        assertEquals(SubmissionStatus.TURNED_IN, res5.status)
        assertFalse(res5.isManuallyCompleted)
    }

    @Test
    fun testBaoBaiFallback_TodayCompletedTasksIncludedWhenIncludeCompletedTrue() {
        val cal = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 23)
            set(Calendar.MINUTE, 30)
        }
        val taskTodayCompleted = Coursework(
            id = "today_done",
            courseId = "c1",
            courseName = "Hóa",
            title = "Hóa hữu cơ",
            dueEpochMillis = cal.timeInMillis,
            status = SubmissionStatus.TURNED_IN
        )

        val batchWithCompleted = BaoBaiBucketingUtils.getTomorrowCoursework(
            listOf(taskTodayCompleted),
            includeCompleted = true
        )
        assertEquals(1, batchWithCompleted.size)
        assertEquals("today_done", batchWithCompleted.first().id)

        val batchWithoutCompleted = BaoBaiBucketingUtils.getTomorrowCoursework(
            listOf(taskTodayCompleted),
            includeCompleted = false
        )
        assertTrue(batchWithoutCompleted.isEmpty())
    }

    @Test
    fun testCourseworkBuckets_WidgetItems() {
        val dueTomorrow = ClassroomDateUtils.startOfTomorrow + 3600_000L
        val taskTomorrow = Coursework(
            id = "tomorrow_task",
            courseId = "c1",
            courseName = "Toán",
            title = "Toán 12",
            dueEpochMillis = dueTomorrow,
            status = SubmissionStatus.PENDING
        )

        val buckets = BaoBaiBucketingUtils.computeBuckets(listOf(taskTomorrow))
        assertEquals(1, buckets.widgetItems.size)
        assertEquals("tomorrow_task", buckets.widgetItems.first().id)
        assertEquals(
            buckets.widgetItems,
            BaoBaiBucketingUtils.getTomorrowCoursework(listOf(taskTomorrow), includeCompleted = true)
        )
    }

    @Test
    fun testCourseworkBuckets_WidgetItems_CompletedTomorrowRemainsTier1() {
        val dueTomorrow = ClassroomDateUtils.startOfTomorrow + 3600_000L
        val dueLater = ClassroomDateUtils.startOfDayAfter + 86400_000L
        val taskTomorrowDone = Coursework(
            id = "tomorrow_done_task",
            courseId = "c1",
            courseName = "Toán",
            title = "Toán 12 Đã nộp",
            dueEpochMillis = dueTomorrow,
            status = SubmissionStatus.TURNED_IN
        )
        val taskLaterPending = Coursework(
            id = "later_task",
            courseId = "c1",
            courseName = "Lý",
            title = "Lý 12 Sắp tới",
            dueEpochMillis = dueLater,
            status = SubmissionStatus.PENDING
        )

        val buckets = BaoBaiBucketingUtils.computeBuckets(listOf(taskTomorrowDone, taskLaterPending))
        assertEquals(1, buckets.widgetItems.size)
        assertEquals("tomorrow_done_task", buckets.widgetItems.first().id)
        assertEquals(
            buckets.widgetItems,
            BaoBaiBucketingUtils.getTomorrowCoursework(listOf(taskTomorrowDone, taskLaterPending), includeCompleted = true)
        )
    }

    @Test
    fun testSorting_SearchFilter_PreFiltersUsingSearchIndex() {
        val item1 = Coursework(
            id = "1",
            courseId = "c1",
            courseName = "Vật lý",
            title = "Dao động điều hòa"
        )
        val item2 = Coursework(
            id = "2",
            courseId = "c1",
            courseName = "Hóa học",
            title = "Este lipit"
        )

        val filtered = BaoBaiBucketingUtils.sortCoursework(
            items = listOf(item1, item2),
            searchTokens = listOf("dao", "dong"),
            rawNormalizedQuery = "dao dong"
        )
        assertEquals(1, filtered.size)
        assertEquals("1", filtered.first().id)
    }

    @Test
    fun testFilterByActiveCourses_FastPath_WhenAllCoursesActive() {
        val course1 = com.phucta.classroom.data.model.Course(id = "c1", name = "Toán", isSelectedForWidget = true)
        val course2 = com.phucta.classroom.data.model.Course(id = "c2", name = "Lý", isSelectedForWidget = true)

        val task1 = Coursework(id = "t1", courseId = "c1", courseName = "Toán", title = "Toán 1")
        val task2 = Coursework(id = "t2", courseId = "c2", courseName = "Lý", title = "Lý 1")
        val items = listOf(task1, task2)

        val result = BaoBaiBucketingUtils.filterByActiveCourses(items, listOf(course1, course2))
        org.junit.Assert.assertSame(items, result)
    }

    @Test
    fun testToCourseworkExtension_MapsFieldsProperly() {
        val entity = com.phucta.classroom.data.local.CourseworkEntity(
            id = "cw_test",
            courseId = "course_1",
            courseName = "Hóa học",
            title = "Phản ứng este hóa",
            description = "Chi tiết bài tập",
            alternateLink = "https://classroom.google.com/test",
            dueEpochMillis = 1700000000000L,
            status = "turnedIn",
            maxPoints = 10.0,
            isManuallyCompleted = true,
            searchIndex = "hoa hoc phan ung este hoa chi tiet bai tap"
        )
        val coursework = entity.toCoursework()
        assertEquals("cw_test", coursework.id)
        assertEquals("course_1", coursework.courseId)
        assertEquals("Hóa học", coursework.courseName)
        assertEquals("Phản ứng este hóa", coursework.title)
        assertEquals(SubmissionStatus.TURNED_IN, coursework.status)
        assertEquals(true, coursework.isManuallyCompleted)
        assertEquals("hoa hoc", coursework.normalizedCourseName)
        assertEquals("phan ung este hoa", coursework.normalizedTitle)

        val list = listOf(entity)
        val courseworkList = list.toCoursework()
        assertEquals(1, courseworkList.size)
        assertEquals("cw_test", courseworkList[0].id)
    }

    @Test
    fun testSortCoursework_DoesNotMutateCallerArrayList() {
        val now = System.currentTimeMillis()
        val itemA = Coursework(id = "item_a", courseId = "c1", courseName = "Toán", title = "A Task", dueEpochMillis = now + 1000)
        val itemB = Coursework(id = "item_b", courseId = "c1", courseName = "Toán", title = "B Task", dueEpochMillis = now + 5000)

        val callerList = arrayListOf(itemB, itemA)
        val sorted = BaoBaiBucketingUtils.sortCoursework(callerList)

        assertEquals("item_a", sorted[0].id)
        assertEquals("item_b", sorted[1].id)

        assertEquals("item_b", callerList[0].id)
        assertEquals("item_a", callerList[1].id)
    }

    @Test
    fun testToCourseworkList_CachesNormalizedCourseNames() {
        val entity1 = com.phucta.classroom.data.local.CourseworkEntity(
            id = "cw_1",
            courseId = "c1",
            courseName = "Vật lý nâng cao",
            title = "Bài tập cơ học",
            status = "pending",
            searchIndex = "vat ly nang cao bai tap co hoc"
        )
        val entity2 = com.phucta.classroom.data.local.CourseworkEntity(
            id = "cw_2",
            courseId = "c1",
            courseName = "Vật lý nâng cao",
            title = "Bài tập nhiệt học",
            status = "pending",
            searchIndex = "vat ly nang cao bai tap nhiet hoc"
        )

        val list = listOf(entity1, entity2).toCoursework()
        assertEquals(2, list.size)
        assertEquals("vat ly nang cao", list[0].normalizedCourseName)
        assertEquals("vat ly nang cao", list[1].normalizedCourseName)
    }

    @Test
    fun testClassroomRepository_ReconcileCoursework_GuaranteesLocalCompletionOverridesSync() {
        val localManualDone = Coursework(
            id = "cw_sync_1",
            courseId = "c1",
            courseName = "Tin học",
            title = "Lập trình Kotlin",
            status = SubmissionStatus.TURNED_IN,
            isManuallyCompleted = true
        )
        val incomingPending = Coursework(
            id = "cw_sync_1",
            courseId = "c1",
            courseName = "Tin học",
            title = "Lập trình Kotlin (cập nhật từ Google)",
            status = SubmissionStatus.PENDING,
            isManuallyCompleted = false
        )

        val res1 = com.phucta.classroom.data.repository.ClassroomRepository.reconcileCoursework(localManualDone, incomingPending)
        assertEquals("Local completion must override remote PENDING sync", SubmissionStatus.TURNED_IN, res1.status)
        assertTrue("isManuallyCompleted must remain true", res1.isManuallyCompleted)
        assertTrue("isCompleted must remain true", res1.isCompleted)
        assertEquals("Lập trình Kotlin (cập nhật từ Google)", res1.title)

        val incomingLate = incomingPending.copy(status = SubmissionStatus.LATE)
        val res2 = com.phucta.classroom.data.repository.ClassroomRepository.reconcileCoursework(localManualDone, incomingLate)
        assertEquals("Local completion must override remote LATE sync", SubmissionStatus.TURNED_IN, res2.status)
        assertTrue("isManuallyCompleted must remain true", res2.isManuallyCompleted)

        val incomingTurnedIn = incomingPending.copy(status = SubmissionStatus.TURNED_IN)
        val res3 = com.phucta.classroom.data.repository.ClassroomRepository.reconcileCoursework(localManualDone, incomingTurnedIn)
        assertEquals("Status remains TURNED_IN", SubmissionStatus.TURNED_IN, res3.status)
        assertFalse("isManuallyCompleted must be reset when incoming is TURNED_IN", res3.isManuallyCompleted)

        // Verify that after server confirmed TURNED_IN, if teacher unsubmits/returns to PENDING, it does not get stuck
        val res3ReturnedToPending = com.phucta.classroom.data.repository.ClassroomRepository.reconcileCoursework(res3, incomingPending)
        assertEquals("Unsubmitted task must return to PENDING after server TURNED_IN reset", SubmissionStatus.PENDING, res3ReturnedToPending.status)
        assertFalse(res3ReturnedToPending.isManuallyCompleted)

        val localUnchecked = localManualDone.copy(status = SubmissionStatus.PENDING, isManuallyCompleted = false)
        val res4 = com.phucta.classroom.data.repository.ClassroomRepository.reconcileCoursework(localUnchecked, incomingPending)
        assertEquals("Unchecked task remains PENDING", SubmissionStatus.PENDING, res4.status)
        assertFalse("isManuallyCompleted remains false", res4.isManuallyCompleted)

        val res5 = com.phucta.classroom.data.repository.ClassroomRepository.reconcileCoursework(null, incomingPending)
        assertEquals(incomingPending, res5)

        // Case 6: Remote unsubmit without offline checkmark must revert to PENDING
        val localRemoteTurnedInNotManual = localManualDone.copy(status = SubmissionStatus.TURNED_IN, isManuallyCompleted = false)
        val res6 = com.phucta.classroom.data.repository.ClassroomRepository.reconcileCoursework(localRemoteTurnedInNotManual, incomingPending)
        assertEquals("Remote unsubmit without local manual check must revert to PENDING", SubmissionStatus.PENDING, res6.status)
        assertFalse("isManuallyCompleted must remain false", res6.isManuallyCompleted)

        // Case 7: Remote unsubmit WITH offline checkmark must preserve TURNED_IN
        val localRemoteTurnedInManual = localManualDone.copy(status = SubmissionStatus.TURNED_IN, isManuallyCompleted = true)
        val res7 = com.phucta.classroom.data.repository.ClassroomRepository.reconcileCoursework(localRemoteTurnedInManual, incomingPending)
        assertEquals("Remote unsubmit with local manual check must stay TURNED_IN", SubmissionStatus.TURNED_IN, res7.status)
        assertTrue("isManuallyCompleted must remain true", res7.isManuallyCompleted)
    }

    @Test
    fun testPersonalNotesCheckmark_TogglingReflectsInTomorrowCoursework() {
        val cal = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 14)
            set(Calendar.MINUTE, 0)
        }
        val noteTomorrow = PersonalNote(
            id = "note_hw_chem",
            courseId = "c1",
            courseName = "Hóa",
            title = "Làm bài tập trắc nghiệm",
            dueEpochMillis = cal.timeInMillis,
            isCompleted = false
        )

        val listBefore = BaoBaiBucketingUtils.getTomorrowCoursework(
            items = emptyList(),
            personalNotes = listOf(noteTomorrow),
            includeCompleted = true
        )
        assertEquals(1, listBefore.size)
        assertEquals("note_note_hw_chem", listBefore[0].id)
        assertEquals(SubmissionStatus.PENDING, listBefore[0].status)
        assertFalse(listBefore[0].isCompleted)

        val completedNote = noteTomorrow.copy(isCompleted = true)
        val listAfter = BaoBaiBucketingUtils.getTomorrowCoursework(
            items = emptyList(),
            personalNotes = listOf(completedNote),
            includeCompleted = true
        )
        assertEquals(1, listAfter.size)
        assertEquals("note_note_hw_chem", listAfter[0].id)
        assertEquals(SubmissionStatus.TURNED_IN, listAfter[0].status)
        assertTrue(listAfter[0].isManuallyCompleted)
        assertTrue(listAfter[0].isCompleted)

        val listPendingOnly = BaoBaiBucketingUtils.getTomorrowCoursework(
            items = emptyList(),
            personalNotes = listOf(completedNote),
            includeCompleted = false
        )
        assertTrue("Completed note must be excluded when includeCompleted is false", listPendingOnly.isEmpty())
    }

    @Test
    fun testPersonalNoteChecklist_SerializationAndParity() {
        val checklist = listOf(
            com.phucta.classroom.data.model.ChecklistItem(id = "item_1", title = "Đọc trang 1-20", isCompleted = false),
            com.phucta.classroom.data.model.ChecklistItem(id = "item_2", title = "Làm bài 1, 2, 3", isCompleted = true)
        )
        val originalNote = PersonalNote(
            id = "note_complex_hw",
            courseId = "c1",
            courseName = "Vật lý",
            title = "Bài tập con lắc đơn",
            content = "Ghi chú chi tiết",
            checklist = checklist,
            isCompleted = false
        )

        val entity = com.phucta.classroom.data.local.PersonalNoteEntity.fromDomain(originalNote)
        val reconstructed = entity.toDomain()

        assertEquals(originalNote.id, reconstructed.id)
        assertEquals(originalNote.checklist.size, reconstructed.checklist.size)
        assertEquals("Đọc trang 1-20", reconstructed.checklist[0].title)
        assertFalse(reconstructed.checklist[0].isCompleted)
        assertEquals("Làm bài 1, 2, 3", reconstructed.checklist[1].title)
        assertTrue(reconstructed.checklist[1].isCompleted)
        assertEquals(0.5f, reconstructed.checklistProgress, 0.01f)
    }

    @Test
    fun testPersonalNoteChecklist_TogglingAllItemsCompletesParent() {
        val checklist = listOf(
            com.phucta.classroom.data.model.ChecklistItem(id = "item_1", title = "Viết dàn ý", isCompleted = true),
            com.phucta.classroom.data.model.ChecklistItem(id = "item_2", title = "Viết mở bài", isCompleted = false)
        )
        val note = PersonalNote(
            id = "note_essay",
            title = "Bài văn nghị luận",
            checklist = checklist,
            isCompleted = false
        )

        // Toggle item_2 to true
        val updatedChecklist = note.checklist.map {
            if (it.id == "item_2") it.copy(isCompleted = !it.isCompleted) else it
        }
        val allDone = updatedChecklist.isNotEmpty() && updatedChecklist.all { it.isCompleted }
        val updatedNote = note.copy(
            checklist = updatedChecklist,
            isCompleted = allDone
        )

        assertTrue("Note should be completed when all subitems are completed", updatedNote.isCompleted)
        assertEquals(1.0f, updatedNote.checklistProgress, 0.01f)

        // Untoggle item_1 to false
        val revertedChecklist = updatedNote.checklist.map {
            if (it.id == "item_1") it.copy(isCompleted = !it.isCompleted) else it
        }
        val hasIncomplete = revertedChecklist.any { !it.isCompleted }
        val revertedNote = updatedNote.copy(
            checklist = revertedChecklist,
            isCompleted = if (hasIncomplete) false else updatedNote.isCompleted
        )

        assertFalse("Note should be incomplete when at least one subitem is incomplete", revertedNote.isCompleted)
        assertEquals(0.5f, revertedNote.checklistProgress, 0.01f)
    }

    @Test
    fun testOAuthTokens_ExpirationAndValidityContract() {
        val now = System.currentTimeMillis()
        val validToken = com.phucta.classroom.data.local.OAuthTokens(
            accessToken = "valid_access_token",
            refreshToken = "refresh_token_123",
            expiresIn = 3600,
            expiresAt = now + 1800_000L
        )
        assertFalse("Token expiring in 30 mins should not be expired", validToken.isExpired)

        val expiredTokenWithRefresh = com.phucta.classroom.data.local.OAuthTokens(
            accessToken = "expired_access_token",
            refreshToken = "refresh_token_123",
            expiresIn = 3600,
            expiresAt = now - 1000L
        )
        assertTrue("Token past expiration should be expired", expiredTokenWithRefresh.isExpired)

        val expiredTokenWithoutRefresh = com.phucta.classroom.data.local.OAuthTokens(
            accessToken = "expired_access_token",
            refreshToken = null,
            expiresIn = 3600,
            expiresAt = now - 1000L
        )
        assertTrue("Token past expiration should be expired", expiredTokenWithoutRefresh.isExpired)
    }

    @Test
    fun testStandalonePersonalNotes_PreservedDuringCourseworkPruning() {
        val validCourseworkIds = listOf("cw_active_1", "cw_active_2")
        val validSet = validCourseworkIds.toHashSet()

        val attachedNote = com.phucta.classroom.data.local.AttachedCourseworkNoteRef(
            id = "note_attached_1",
            courseworkId = "cw_deleted_9"
        )
        val standaloneNoteNull = com.phucta.classroom.data.local.AttachedCourseworkNoteRef(
            id = "note_standalone_null",
            courseworkId = null
        )
        val standaloneNoteEmpty = com.phucta.classroom.data.local.AttachedCourseworkNoteRef(
            id = "note_standalone_empty",
            courseworkId = ""
        )
        val standaloneNoteBlank = com.phucta.classroom.data.local.AttachedCourseworkNoteRef(
            id = "note_standalone_blank",
            courseworkId = "   "
        )

        val candidateRefs = listOf(attachedNote, standaloneNoteNull, standaloneNoteEmpty, standaloneNoteBlank)
        val toDelete = ArrayList<String>()
        for (note in candidateRefs) {
            val cwId = note.courseworkId
            if (!cwId.isNullOrBlank() && !validSet.contains(cwId)) {
                toDelete.add(note.id)
            }
        }

        assertEquals("Only attached notes with deleted coursework should be marked for deletion", 1, toDelete.size)
        assertEquals("note_attached_1", toDelete.first())
        assertFalse("Standalone notes with null courseworkId must not be deleted", toDelete.contains("note_standalone_null"))
        assertFalse("Standalone notes with empty courseworkId must not be deleted", toDelete.contains("note_standalone_empty"))
        assertFalse("Standalone notes with blank courseworkId must not be deleted", toDelete.contains("note_standalone_blank"))
    }

    @Test
    fun testLOG03_CompletedTodayMustNotPolluteTomorrowFallback() {
        val now = System.currentTimeMillis()
        ClassroomDateUtils.ensureDayBoundaries(now)
        val cal = Calendar.getInstance().apply {
            timeInMillis = now
            set(Calendar.HOUR_OF_DAY, 23)
            set(Calendar.MINUTE, 30)
        }
        val todayDue = cal.timeInMillis

        cal.add(Calendar.DAY_OF_YEAR, 3)
        val laterDue = cal.timeInMillis

        val completedTodayCoursework = Coursework(
            id = "today_done",
            courseId = "c1",
            courseName = "Văn",
            title = "Bài tập hoàn thành hôm nay",
            dueEpochMillis = todayDue,
            status = SubmissionStatus.TURNED_IN
        )

        val upcomingLaterCoursework = Coursework(
            id = "later_pending",
            courseId = "c1",
            courseName = "Toán",
            title = "Bài tập tuần tới",
            dueEpochMillis = laterDue,
            status = SubmissionStatus.PENDING
        )

        val buckets = BaoBaiBucketingUtils.computeBuckets(listOf(completedTodayCoursework, upcomingLaterCoursework))
        assertEquals(1, buckets.completed.size)
        assertEquals("today_done", buckets.completed.first().id)
        assertEquals(0, buckets.tomorrow.size)
        assertEquals(1, buckets.laterUpcoming.size)

        // Fallback widgetItems must pick 'later', NOT 'completedToday'
        assertEquals(1, buckets.widgetItems.size)
        assertEquals("later_pending", buckets.widgetItems.first().id)
    }

    @Test
    fun testLOG06_EmptyTomorrowCandidatesDoesNotThrowClassCastException() {
        val buckets = BaoBaiBucketingUtils.computeBuckets(emptyList())
        assertTrue(buckets.widgetItems.isEmpty())
    }

    @Test
    fun testLOG07_WhenNoTomorrowOrUpcomingOrUndated_CompletedTodayIsLastResortFallback() {
        val now = System.currentTimeMillis()
        val cal = Calendar.getInstance().apply {
            timeInMillis = now
            set(Calendar.HOUR_OF_DAY, 23)
            set(Calendar.MINUTE, 50)
        }
        val todayDue = cal.timeInMillis

        val completedTodayCoursework = Coursework(
            id = "today_done_only",
            courseId = "c1",
            courseName = "Toán",
            title = "Đã làm xong chiều nay",
            dueEpochMillis = todayDue,
            status = SubmissionStatus.TURNED_IN
        )

        val buckets = BaoBaiBucketingUtils.computeBuckets(listOf(completedTodayCoursework))
        assertEquals(1, buckets.completed.size)
        assertEquals(0, buckets.tomorrow.size)
        assertEquals(0, buckets.laterUpcoming.size)
        // With no tomorrow, no upcoming, and no undated tasks, completedToday is the last-resort fallback
        assertEquals(1, buckets.widgetItems.size)
        assertEquals("today_done_only", buckets.widgetItems.first().id)
    }
}
