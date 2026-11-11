package com.phucta.classroom

import com.phucta.classroom.data.model.Course
import com.phucta.classroom.data.model.SubmissionStatus
import com.phucta.classroom.data.remote.ClassroomApiService
import kotlinx.coroutines.runBlocking
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Protocol
import okhttp3.Request
import okhttp3.Response
import okhttp3.ResponseBody.Companion.toResponseBody
import org.junit.Assert.*
import org.junit.Test

class ClassroomApiServiceTest {
    private fun service(handler: (Request) -> Pair<Int, String>): ClassroomApiService =
        ClassroomApiService(OkHttpClient.Builder().addInterceptor { chain ->
            val (code, body) = handler(chain.request())
            Response.Builder().request(chain.request()).protocol(Protocol.HTTP_1_1)
                .code(code).message("test").body(body.toResponseBody("application/json".toMediaType())).build()
        }.build())

    @Test
    fun courseworkAndSubmissionsLoadBeyondTenPages() = runBlocking {
        val api = service { request ->
            val page = request.url.queryParameter("pageToken")?.toInt() ?: 0
            val next = if (page < 10) ",\"nextPageToken\":\"${page + 1}\"" else ""
            val body = if (request.url.encodedPath.endsWith("studentSubmissions")) {
                "{\"studentSubmissions\":[{\"courseWorkId\":\"cw$page\",\"state\":\"TURNED_IN\"}]$next}"
            } else {
                "{\"courseWork\":[{\"id\":\"cw$page\",\"title\":\"Task $page\"}]$next}"
            }
            200 to body
        }
        val items = api.fetchCourseworkForCourse(Course(id = "c", name = "Math"), "test")
        assertEquals(11, items.size)
        assertEquals(SubmissionStatus.TURNED_IN, items.last().status)
    }

    @Test
    fun partialCourseListMustNotBeReportedAsComplete() = runBlocking {
        val api = service { request ->
            if (request.url.queryParameter("studentId") != null) {
                200 to "{\"courses\":[{\"id\":\"student\",\"name\":\"Math\"}]}"
            } else 403 to "{}"
        }
        assertTrue(runCatching { api.fetchActiveCourses("test") }.isFailure)
    }

    @Test
    fun authoritativeFallbackRecoversAfterRoleQueryFailure() = runBlocking {
        val api = service { request ->
            if (request.url.queryParameter("studentId") != null) 403 to "{}"
            else if (request.url.queryParameter("teacherId") != null) 200 to "{}"
            else 200 to "{\"courses\":[{\"id\":\"all\",\"name\":\"Math\"}]}"
        }
        assertEquals(listOf("all"), api.fetchActiveCourses("test").map { it.id })
    }

    @Test
    fun emptyActiveCoursesMustNotImportArchivedCourses() = runBlocking {
        val api = service { request ->
            if (request.url.queryParameter("courseStates") == "ACTIVE") 200 to "{}"
            else 200 to "{\"courses\":[{\"id\":\"archived\",\"name\":\"Old\"}]}"
        }
        assertTrue(api.fetchActiveCourses("test").isEmpty())
    }

    @Test
    fun repeatedPageTokenFailsInsteadOfReturningTruncatedData() = runBlocking {
        val api = service {
            200 to "{\"courseWork\":[{\"id\":\"cw\",\"title\":\"Task\"}],\"nextPageToken\":\"repeat\"}"
        }
        assertTrue(runCatching { api.fetchCourseworkForCourse(Course(id = "c", name = "Math"), "test") }.isFailure)
    }
}
