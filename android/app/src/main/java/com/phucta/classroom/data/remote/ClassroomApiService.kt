package com.phucta.classroom.data.remote

import com.phucta.classroom.data.model.ClassroomDateUtils
import com.phucta.classroom.data.model.Course
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.data.model.SubmissionStatus
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import okhttp3.HttpUrl.Companion.toHttpUrl
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.IOException
import java.util.concurrent.TimeUnit

@Serializable
private data class GoogleCoursesResponse(
    val courses: List<GoogleCourseItem>? = null,
    val nextPageToken: String? = null
)

@Serializable
private data class GoogleCourseItem(
    val id: String = "",
    val name: String = "",
    val section: String? = null,
    val descriptionHeading: String? = null,
    val room: String? = null,
    val alternateLink: String? = null
)

@Serializable
private data class GoogleCourseworkResponse(
    val courseWork: List<GoogleCourseworkRawItem>? = null,
    val nextPageToken: String? = null
)

@Serializable
private data class GoogleCourseworkRawItem(
    val id: String = "",
    val title: String = "",
    val description: String? = null,
    val alternateLink: String? = null,
    val dueDate: GoogleDateItem? = null,
    val dueTime: GoogleTimeItem? = null,
    val maxPoints: Double? = null
)

@Serializable
private data class GoogleDateItem(
    val year: Int? = null,
    val month: Int? = null,
    val day: Int? = null
)

@Serializable
private data class GoogleTimeItem(
    val hours: Int? = null,
    val minutes: Int? = null,
    val seconds: Int? = null
)

@Serializable
private data class GoogleSubmissionsResponse(
    val studentSubmissions: List<GoogleSubmissionItem>? = null,
    val nextPageToken: String? = null
)

@Serializable
private data class GoogleSubmissionItem(
    val id: String = "",
    val courseWorkId: String = "",
    val state: String? = null,
    val late: Boolean? = null
)

class ClassroomApiService(
    private val httpClient: OkHttpClient = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .build()
) {
    private val json = Json { ignoreUnknownKeys = true }

    suspend fun fetchActiveCourses(accessToken: String): List<Course> = withContext(Dispatchers.IO) {
        val coursesMap = LinkedHashMap<String, Course>()
        var lastError: Exception? = null

        try {
            val studentCourses = fetchCoursesPage(accessToken, filterKey = "studentId", filterValue = "me", courseState = "ACTIVE")
            for (course in studentCourses) {
                coursesMap[course.id] = course
            }
        } catch (e: Exception) {
            lastError = e
        }

        try {
            val teacherCourses = fetchCoursesPage(accessToken, filterKey = "teacherId", filterValue = "me", courseState = "ACTIVE")
            for (course in teacherCourses) {
                coursesMap[course.id] = course
            }
        } catch (e: Exception) {
            if (lastError == null) lastError = e
        }

        // Fallback for admins and creators without an explicit role filter
        if (coursesMap.isEmpty()) {
            try {
                val adminCourses = fetchCoursesPage(accessToken, filterKey = null, filterValue = null, courseState = "ACTIVE")
                for (course in adminCourses) {
                    coursesMap[course.id] = course
                }
            } catch (e: Exception) {
                if (lastError == null) lastError = e
            }
        }

        // Fallback if courses have states other than ACTIVE
        if (coursesMap.isEmpty() && lastError == null) {
            try {
                val studentAllStateCourses = fetchCoursesPage(accessToken, filterKey = "studentId", filterValue = "me", courseState = null)
                for (course in studentAllStateCourses) {
                    coursesMap[course.id] = course
                }
            } catch (_: Exception) {}
            try {
                val teacherAllStateCourses = fetchCoursesPage(accessToken, filterKey = "teacherId", filterValue = "me", courseState = null)
                for (course in teacherAllStateCourses) {
                    coursesMap[course.id] = course
                }
            } catch (_: Exception) {}
        }

        if (coursesMap.isEmpty() && lastError != null) {
            throw lastError
        }

        return@withContext coursesMap.values.toList()
    }

    private fun fetchCoursesPage(
        accessToken: String,
        filterKey: String?,
        filterValue: String?,
        courseState: String? = "ACTIVE"
    ): List<Course> {
        val pageCourses = mutableListOf<Course>()
        var pageToken: String? = null
        var pageCount = 0

        do {
            val urlBuilder = "https://classroom.googleapis.com/v1/courses".toHttpUrl().newBuilder()
                .addQueryParameter("pageSize", "50")

            if (courseState != null) {
                urlBuilder.addQueryParameter("courseStates", courseState)
            }
            if (filterKey != null && filterValue != null) {
                urlBuilder.addQueryParameter(filterKey, filterValue)
            }
            if (!pageToken.isNullOrBlank()) {
                urlBuilder.addQueryParameter("pageToken", pageToken)
            }

            val request = Request.Builder()
                .url(urlBuilder.build())
                .addHeader("Authorization", "Bearer $accessToken")
                .build()

            val (shouldContinue, newPageToken) = try {
                httpClient.newCall(request).execute().use { response ->
                    if (!response.isSuccessful) {
                        if (pageCourses.isEmpty()) {
                            throw IllegalStateException("Không lấy được danh sách lớp học (${response.code})")
                        }
                        return@use Pair(false, null)
                    }

                    val body = response.body?.string() ?: return@use Pair(false, null)
                    val decoded = json.decodeFromString<GoogleCoursesResponse>(body)
                    decoded.courses?.forEach { item ->
                        if (item.id.isNotBlank() && item.name.isNotBlank()) {
                            pageCourses.add(
                                Course(
                                    id = item.id,
                                    name = item.name,
                                    section = item.section,
                                    descriptionHeading = item.descriptionHeading,
                                    room = item.room,
                                    alternateLink = item.alternateLink,
                                    isSelectedForWidget = true
                                )
                            )
                        }
                    }
                    Pair(true, decoded.nextPageToken)
                }
            } catch (e: Exception) {
                if (pageCourses.isEmpty()) throw e
                Pair(false, null)
            }
            if (!shouldContinue) break
            pageToken = newPageToken
            pageCount++
        } while (pageToken != null && pageCount < 10)

        return pageCourses
    }

    suspend fun fetchCourseworkForCourse(course: Course, accessToken: String): List<Coursework> = withContext(Dispatchers.IO) {
        val rawItems = fetchRawCoursework(course.id, accessToken)
        val submissionsMap = fetchSubmissionsMap(course.id, accessToken)
        val now = System.currentTimeMillis()

        return@withContext rawItems.map { raw ->
            val submission = submissionsMap[raw.id]
            val dueEpoch = ClassroomDateUtils.parseGoogleDueDateTime(
                year = raw.dueDate?.year,
                month = raw.dueDate?.month,
                day = raw.dueDate?.day,
                hours = raw.dueTime?.hours,
                minutes = raw.dueTime?.minutes,
                seconds = raw.dueTime?.seconds,
                hasDueTime = raw.dueTime != null
            )

            val status: SubmissionStatus = when (submission?.state) {
                "TURNED_IN", "STUDENT_EDITED_AFTER_TURN_IN" -> SubmissionStatus.TURNED_IN
                "RETURNED" -> SubmissionStatus.RETURNED
                else -> {
                    if (submission?.late == true || (dueEpoch != null && dueEpoch < now)) {
                        SubmissionStatus.LATE
                    } else {
                        SubmissionStatus.PENDING
                    }
                }
            }

            Coursework(
                id = raw.id,
                courseId = course.id,
                courseName = course.name,
                title = raw.title,
                description = raw.description,
                alternateLink = raw.alternateLink,
                dueEpochMillis = dueEpoch,
                status = status,
                maxPoints = raw.maxPoints
            )
        }
    }

    private fun fetchRawCoursework(courseId: String, accessToken: String): List<GoogleCourseworkRawItem> {
        val allItems = mutableListOf<GoogleCourseworkRawItem>()
        var pageToken: String? = null
        var pageCount = 0

        do {
            val urlBuilder = "https://classroom.googleapis.com/v1/courses/$courseId/courseWork".toHttpUrl().newBuilder()
                .addQueryParameter("courseWorkStates", "PUBLISHED")
                .addQueryParameter("pageSize", "50")

            if (!pageToken.isNullOrBlank()) {
                urlBuilder.addQueryParameter("pageToken", pageToken)
            }

            val request = Request.Builder()
                .url(urlBuilder.build())
                .addHeader("Authorization", "Bearer $accessToken")
                .build()

            val (shouldContinue, newPageToken) = try {
                httpClient.newCall(request).execute().use { response ->
                    if (!response.isSuccessful) {
                        if (allItems.isEmpty()) {
                            throw IOException("HTTP ${response.code} khi tải bài tập lớp $courseId")
                        }
                        return@use Pair(false, null)
                    }
                    val body = response.body?.string() ?: return@use Pair(false, null)
                    val decoded = json.decodeFromString<GoogleCourseworkResponse>(body)
                    decoded.courseWork?.let { allItems.addAll(it) }
                    Pair(true, decoded.nextPageToken)
                }
            } catch (e: Exception) {
                if (allItems.isEmpty()) throw e
                Pair(false, null)
            }
            if (!shouldContinue) break
            pageToken = newPageToken
            pageCount++
        } while (pageToken != null && pageCount < 10)

        // Retry without PUBLISHED filter if nothing came back (matching Swift implementation)
        if (allItems.isEmpty()) {
            try {
                val urlBuilder = "https://classroom.googleapis.com/v1/courses/$courseId/courseWork".toHttpUrl().newBuilder()
                    .addQueryParameter("pageSize", "50")

                val request = Request.Builder()
                    .url(urlBuilder.build())
                    .addHeader("Authorization", "Bearer $accessToken")
                    .build()

                httpClient.newCall(request).execute().use { response ->
                    if (response.isSuccessful) {
                        response.body?.string()?.let { body ->
                            val decoded = json.decodeFromString<GoogleCourseworkResponse>(body)
                            decoded.courseWork?.let { allItems.addAll(it) }
                        }
                    }
                }
            } catch (_: Exception) {}
        }

        return allItems
    }

    private fun fetchSubmissionsMap(courseId: String, accessToken: String): Map<String, GoogleSubmissionItem> {
        val map = mutableMapOf<String, GoogleSubmissionItem>()
        var pageToken: String? = null
        var pageCount = 0

        do {
            val urlBuilder = "https://classroom.googleapis.com/v1/courses/$courseId/courseWork/-/studentSubmissions".toHttpUrl().newBuilder()
                .addQueryParameter("userId", "me")
                .addQueryParameter("pageSize", "50")

            if (!pageToken.isNullOrBlank()) {
                urlBuilder.addQueryParameter("pageToken", pageToken)
            }

            val request = Request.Builder()
                .url(urlBuilder.build())
                .addHeader("Authorization", "Bearer $accessToken")
                .build()

            val (shouldContinue, newPageToken) = try {
                httpClient.newCall(request).execute().use { response ->
                    if (!response.isSuccessful) {
                        if (map.isEmpty()) {
                            throw IOException("HTTP ${response.code} khi tải trạng thái nộp bài lớp $courseId")
                        }
                        return@use Pair(false, null)
                    }
                    val body = response.body?.string() ?: return@use Pair(false, null)
                    val decoded = json.decodeFromString<GoogleSubmissionsResponse>(body)
                    decoded.studentSubmissions?.forEach { item ->
                        map[item.courseWorkId] = item
                    }
                    Pair(true, decoded.nextPageToken)
                }
            } catch (e: Exception) {
                if (map.isEmpty()) throw e
                Pair(false, null)
            }
            if (!shouldContinue) break
            pageToken = newPageToken
            pageCount++
        } while (pageToken != null && pageCount < 10)

        return map
    }
}
