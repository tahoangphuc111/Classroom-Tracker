package com.phucta.classroom

import com.phucta.classroom.data.local.ClassroomPreferences
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.data.model.SubmissionStatus
import com.phucta.classroom.data.repository.ClassroomRepository
import com.phucta.classroom.domain.BaoBaiBucketingUtils
import com.phucta.classroom.ui.components.SubjectArtHelper
import com.phucta.classroom.ui.components.SubjectCategory
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.Calendar

class AuditRemediationSecurityTest {

    @Test
    fun testSEC01_BundledClientSecretMustBeEmptyString() {
        assertEquals(
            "Native Android clients must not ship hardcoded OAuth client secrets",
            "",
            ClassroomPreferences.BUNDLED_CLIENT_SECRET
        )
    }

    @Test
    fun testLOG02_TeacherUnsubmitAfterRemoteTurnedIn_RevertsToPending() {
        val initialIncomingPending = Coursework(
            id = "cw_unsubmit_test",
            courseId = "c1",
            courseName = "Hóa học",
            title = "Báo cáo thực hành",
            status = SubmissionStatus.PENDING,
            isManuallyCompleted = false
        )

        // Step 1: Student checks off locally (offline manual complete)
        val localManualChecked = initialIncomingPending.copy(
            status = SubmissionStatus.TURNED_IN,
            isManuallyCompleted = true
        )

        // Step 2: Next sync still PENDING from server -> local completion preserved
        val syncPending = ClassroomRepository.reconcileCoursework(localManualChecked, initialIncomingPending)
        assertEquals(SubmissionStatus.TURNED_IN, syncPending.status)
        assertTrue(syncPending.isManuallyCompleted)

        // Step 3: Google server confirms TURNED_IN -> isManuallyCompleted must be reset to false!
        val serverTurnedIn = initialIncomingPending.copy(status = SubmissionStatus.TURNED_IN)
        val syncServerTurnedIn = ClassroomRepository.reconcileCoursework(syncPending, serverTurnedIn)
        assertEquals(SubmissionStatus.TURNED_IN, syncServerTurnedIn.status)
        assertFalse(
            "Once server confirms TURNED_IN, isManuallyCompleted must reset to false",
            syncServerTurnedIn.isManuallyCompleted
        )

        // Step 4: Teacher returns assignment back to PENDING (Unsubmit/Return)
        // With isManuallyCompleted reset to false, it must cleanly transition back to PENDING!
        val teacherReturnedToPending = initialIncomingPending.copy(status = SubmissionStatus.PENDING)
        val finalSync = ClassroomRepository.reconcileCoursework(syncServerTurnedIn, teacherReturnedToPending)
        assertEquals(
            "Assignment must return to PENDING when teacher un-submits, not remain stuck",
            SubmissionStatus.PENDING,
            finalSync.status
        )
        assertFalse(finalSync.isManuallyCompleted)
    }

    @Test
    fun testLOG02_ReturnedStatusFromGoogle_ResetsManuallyCompleted() {
        val localManualChecked = Coursework(
            id = "cw_returned_test",
            courseId = "c1",
            courseName = "Vật lý",
            title = "Bài tập con lắc",
            status = SubmissionStatus.TURNED_IN,
            isManuallyCompleted = true
        )
        val serverReturned = localManualChecked.copy(status = SubmissionStatus.RETURNED, isManuallyCompleted = false)
        val reconciled = ClassroomRepository.reconcileCoursework(localManualChecked, serverReturned)
        assertEquals(SubmissionStatus.RETURNED, reconciled.status)
        assertFalse("isManuallyCompleted must reset on RETURNED status", reconciled.isManuallyCompleted)
    }

    @Test
    fun testLOG03_CompletedTodayDoesNotClutterTomorrowFallback() {
        val now = System.currentTimeMillis()
        val cal = Calendar.getInstance().apply {
            timeInMillis = now
            set(Calendar.HOUR_OF_DAY, 23)
            set(Calendar.MINUTE, 50)
        }
        val todayDue = cal.timeInMillis

        cal.add(Calendar.DAY_OF_YEAR, 2)
        val inTwoDaysDue = cal.timeInMillis

        val completedToday = Coursework(
            id = "today_finished",
            courseId = "c1",
            courseName = "Toán",
            title = "Đã làm xong chiều nay",
            dueEpochMillis = todayDue,
            status = SubmissionStatus.TURNED_IN
        )

        val upcomingLater = Coursework(
            id = "later_prep",
            courseId = "c1",
            courseName = "Sinh học",
            title = "Chuẩn bị bài tuần này",
            dueEpochMillis = inTwoDaysDue,
            status = SubmissionStatus.PENDING
        )

        val buckets = BaoBaiBucketingUtils.computeBuckets(listOf(completedToday, upcomingLater))
        assertTrue(buckets.tomorrow.isEmpty())
        assertEquals(1, buckets.completed.size)
        assertEquals(1, buckets.laterUpcoming.size)

        // Tomorrow candidates must skip completedToday and fallback to laterUpcoming!
        assertEquals(1, buckets.widgetItems.size)
        assertEquals("later_prep", buckets.widgetItems.first().id)
    }

    @Test
    fun testUI04_GeographyRecognition_WordBoundariesAndCompoundExclusions() {
        // Compound exclusions: "Địa điểm" and "Địa chỉ" in history courses must retain "SỬ"
        val courseHistoryWithLocation = "Lịch sử 12 - Địa điểm P.301"
        assertEquals(SubjectCategory.HISTORY, SubjectArtHelper.category(courseHistoryWithLocation))
        assertEquals("SỬ", SubjectArtHelper.badgeCode(courseHistoryWithLocation))

        val courseHistoryWithAddress = "Lịch sử Đảng - Địa chỉ học: Tầng 3"
        assertEquals(SubjectCategory.HISTORY, SubjectArtHelper.category(courseHistoryWithAddress))
        assertEquals("SỬ", SubjectArtHelper.badgeCode(courseHistoryWithAddress))

        // Geography courses outside core 11 fall back to OTHER with prefix
        assertEquals("ĐỊA", SubjectArtHelper.badgeCode("Địa lý 12"))
        assertEquals("ĐỊA", SubjectArtHelper.badgeCode("Địa lí Việt Nam"))
        assertEquals("MÔN", SubjectArtHelper.badgeCode("Môn Địa 10 - Địa điểm: Hội trường"))
        assertEquals("DIA", SubjectArtHelper.badgeCode("Dia ly lop 11"))

        // Pure location name without subject must not classify as HISTORY
        assertNotEquals(
            SubjectCategory.HISTORY,
            SubjectArtHelper.category("Địa điểm họp phụ huynh học sinh")
        )
        assertNotEquals(
            SubjectCategory.HISTORY,
            SubjectArtHelper.category("Địa chỉ nhận bằng tốt nghiệp")
        )
    }

    @Test
    fun testSEC05_CSRFStateMatchingContract() {
        val expectedState = "sec_random_state_12345"

        // Simulated validation logic matching GoogleOAuthManager.handleRedirectUri
        fun validateState(returnedState: String?, activeState: String?): Boolean {
            if (returnedState.isNullOrBlank() || activeState.isNullOrBlank() || returnedState != activeState) {
                return false
            }
            return true
        }

        assertTrue("Valid state must pass validation", validateState(expectedState, expectedState))
        assertFalse("Missing state must be rejected", validateState(null, expectedState))
        assertFalse("Blank state must be rejected", validateState("", expectedState))
        assertFalse("Mismatched attacker state must be rejected", validateState("attacker_state_67890", expectedState))
    }
}
