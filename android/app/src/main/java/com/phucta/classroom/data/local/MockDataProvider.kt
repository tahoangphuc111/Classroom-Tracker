package com.phucta.classroom.data.local

import com.phucta.classroom.data.model.Course
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.data.model.SubmissionStatus
import java.util.Calendar

object MockDataProvider {

    val mockCourses: List<Course> = listOf(
        Course(id = "c1", name = "Nhập môn Lập trình", section = "CS101", descriptionHeading = "Khoa học Máy tính", isSelectedForWidget = true),
        Course(id = "c2", name = "Tiếng Anh Tổng quát", section = "ENG01", descriptionHeading = "Kỹ năng Giao tiếp & Thuyết trình", isSelectedForWidget = true),
        Course(id = "c3", name = "Kỹ năng Làm việc nhóm", section = "SKL02", descriptionHeading = "Kỹ năng mềm & Quản lý thời gian", isSelectedForWidget = true),
        Course(id = "c4", name = "Thiết kế Giao diện", section = "DES03", descriptionHeading = "Giao diện & Trải nghiệm người dùng", isSelectedForWidget = true)
    )

    fun getMockCoursework(): List<Coursework> {
        val now = System.currentTimeMillis()
        val cal = Calendar.getInstance()

        // Tomorrow at 17:30
        cal.timeInMillis = now
        cal.add(Calendar.DAY_OF_YEAR, 1)
        cal.set(Calendar.HOUR_OF_DAY, 17)
        cal.set(Calendar.MINUTE, 30)
        cal.set(Calendar.SECOND, 0)
        val tomorrowAfternoon = cal.timeInMillis

        // Tomorrow at 23:59 (Cuối ngày)
        cal.set(Calendar.HOUR_OF_DAY, 23)
        cal.set(Calendar.MINUTE, 59)
        cal.set(Calendar.SECOND, 0)
        val tomorrowNight = cal.timeInMillis

        // In 3 days
        cal.timeInMillis = now
        cal.add(Calendar.DAY_OF_YEAR, 3)
        cal.set(Calendar.HOUR_OF_DAY, 23)
        cal.set(Calendar.MINUTE, 59)
        val inThreeDays = cal.timeInMillis

        // In 5 days
        cal.timeInMillis = now
        cal.add(Calendar.DAY_OF_YEAR, 5)
        cal.set(Calendar.HOUR_OF_DAY, 23)
        cal.set(Calendar.MINUTE, 59)
        val inFiveDays = cal.timeInMillis

        return listOf(
            Coursework(
                id = "cw1",
                courseId = "c1",
                courseName = "Nhập môn Lập trình",
                title = "Bài tập thực hành tuần 1",
                description = """
                Yêu cầu hoàn thành bài tập tuần 1:
                1. Đọc kỹ tài liệu và yêu cầu đề bài được đính kèm.
                2. Hoàn thành phần bài tập theo đúng hướng dẫn.
                3. Kiểm tra lại kết quả trước khi nộp.
                4. Nộp bài trực tiếp qua hệ thống trước hạn chót.
                """.trimIndent(),
                alternateLink = "https://classroom.google.com",
                dueEpochMillis = tomorrowNight,
                status = SubmissionStatus.PENDING,
                maxPoints = 10.0
            ),
            Coursework(
                id = "cw2",
                courseId = "c2",
                courseName = "Tiếng Anh Tổng quát",
                title = "Bài luận ngắn tuần 2",
                description = """
                Nội dung bài tập tuần 2:
                - Viết bài luận ngắn khoảng 300 - 500 từ theo chủ đề đã giao.
                - Trình bày rõ ràng, mạch lạc và kiểm tra lỗi chính tả trước khi nộp.
                - Đính kèm tệp văn bản hoặc liên kết tài liệu trực tiếp vào bài tập.
                """.trimIndent(),
                alternateLink = "https://classroom.google.com",
                dueEpochMillis = tomorrowAfternoon,
                status = SubmissionStatus.PENDING,
                maxPoints = 100.0
            ),
            Coursework(
                id = "cw3",
                courseId = "c3",
                courseName = "Kỹ năng Làm việc nhóm",
                title = "Báo cáo tiến độ làm việc nhóm",
                description = """
                Nội dung báo cáo nhóm:
                1. Tổng hợp kết quả thực hiện các mục tiêu trong tuần vừa qua.
                2. Phân công nhiệm vụ cụ thể cho từng thành viên trong tuần tiếp theo.
                3. Đại diện nhóm nộp báo cáo tổng hợp trước thời hạn quy định.
                """.trimIndent(),
                alternateLink = "https://classroom.google.com",
                dueEpochMillis = inThreeDays,
                status = SubmissionStatus.PENDING,
                maxPoints = 10.0
            ),
            Coursework(
                id = "cw4",
                courseId = "c4",
                courseName = "Thiết kế Giao diện",
                title = "Đề cương ý tưởng dự án",
                description = """
                Yêu cầu nộp đề cương ý tưởng:
                - Trình bày tóm tắt ý tưởng, mục tiêu và đối tượng sử dụng của dự án.
                - Liệt kê các tính năng chính dự kiến sẽ triển khai.
                - Chuẩn bị slide tóm tắt để trình bày trong buổi học tới.
                """.trimIndent(),
                alternateLink = "https://classroom.google.com",
                dueEpochMillis = inFiveDays,
                status = SubmissionStatus.PENDING,
                maxPoints = 10.0
            )
        )
    }

    fun isMockCourse(courseId: String): Boolean {
        return courseId.startsWith("c") && courseId.drop(1).toIntOrNull() != null
    }

    fun isMockCourses(courses: List<Course>): Boolean {
        if (courses.isEmpty()) return true
        return courses.all { isMockCourse(it.id) }
    }

    fun isMockCoursework(items: List<Coursework>): Boolean {
        if (items.isEmpty()) return true
        return items.all { isMockCourseworkId(it.id) }
    }

    fun isMockCourseworkId(courseworkId: String): Boolean {
        return courseworkId.startsWith("cw") && courseworkId.drop(2).toIntOrNull() != null
    }
}
