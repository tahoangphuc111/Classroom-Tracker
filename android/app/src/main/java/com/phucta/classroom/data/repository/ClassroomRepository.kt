package com.phucta.classroom.data.repository

import android.content.Context
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.room.withTransaction
import com.phucta.classroom.data.local.ClassroomDatabase
import com.phucta.classroom.data.local.ClassroomPreferences
import com.phucta.classroom.data.local.CourseEntity
import com.phucta.classroom.data.local.CourseworkEntity
import com.phucta.classroom.data.local.MockDataProvider
import com.phucta.classroom.data.model.Course
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.data.model.SubmissionStatus
import com.phucta.classroom.data.remote.ClassroomApiService
import com.phucta.classroom.data.remote.GoogleOAuthManager
import com.phucta.classroom.widget.ClassroomGlanceWidget
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext

class ClassroomRepository(
    private val context: Context,
    private val database: ClassroomDatabase,
    private val preferences: ClassroomPreferences,
    private val oauthManager: GoogleOAuthManager,
    private val apiService: ClassroomApiService = ClassroomApiService()
) {
    private val courseDao = database.courseDao()
    private val courseworkDao = database.courseworkDao()

    private val _isSyncing = MutableStateFlow(false)
    val isSyncing: StateFlow<Boolean> = _isSyncing.asStateFlow()

    private val _syncErrorMessage = MutableStateFlow<String?>(null)
    val syncErrorMessage: StateFlow<String?> = _syncErrorMessage.asStateFlow()

    val coursesFlow: Flow<List<Course>> = courseDao.observeAllCourses().map { entities ->
        entities.map { it.toDomain() }
    }

    val courseworkFlow: Flow<List<Coursework>> = courseworkDao.observeAllCoursework().map { entities ->
        entities.map { it.toDomain() }
    }

    suspend fun ensureInitialData() = withContext(Dispatchers.IO) {
        // Cold start does not auto-populate mock data so unauthenticated users see clean login screen
    }

    suspend fun populateMockDataManually() = withContext(Dispatchers.IO) {
        courseDao.upsertCourses(MockDataProvider.mockCourses.map { CourseEntity.fromDomain(it) })
        courseworkDao.upsertCourseworks(MockDataProvider.getMockCoursework().map { CourseworkEntity.fromDomain(it) })
        notifyWidgetReload()
    }

    suspend fun updateCourseWidgetSelection(courseId: String, isSelected: Boolean) = withContext(Dispatchers.IO) {
        courseDao.updateWidgetSelection(courseId, isSelected)
        notifyWidgetReload()
    }

    suspend fun toggleTaskCompletion(id: String, completed: Boolean) = withContext(Dispatchers.IO) {
        val newStatus = if (completed) SubmissionStatus.TURNED_IN.rawValue else SubmissionStatus.PENDING.rawValue
        courseworkDao.updateCompletionStatus(id, newStatus, isManuallyCompleted = completed)
        notifyWidgetReload()
    }

    /**
     * Syncs active courses and coursework from Google Classroom.
     * Preserves locally checked tasks and widget course selections.
     */
    suspend fun syncAll(): Result<Unit> = withContext(Dispatchers.IO) {
        if (_isSyncing.value) return@withContext Result.success(Unit)
        if (!oauthManager.isAuthenticated.value) {
            _syncErrorMessage.value = "Chưa kết nối Google."
            return@withContext Result.failure(IllegalStateException("Chưa kết nối Google."))
        }

        _isSyncing.value = true
        _syncErrorMessage.value = null

        try {
            val accessToken = oauthManager.getValidAccessToken()

            val fetchedCourses = apiService.fetchActiveCourses(accessToken)

            val existingCourseEntities = courseDao.getAllCourses()
            val hasOnlyMockCourses = existingCourseEntities.isNotEmpty() &&
                    existingCourseEntities.all { MockDataProvider.isMockCourse(it.id) }

            // Preserve widget selection preferences
            val existingCourses = if (hasOnlyMockCourses) emptyList() else existingCourseEntities.map { it.toDomain() }
            val existingSelectionMap = existingCourses.associate { it.id to it.isSelectedForWidget }

            val mergedCourses = fetchedCourses.map { course ->
                val preservedSelection = existingSelectionMap[course.id] ?: true
                course.copy(isSelectedForWidget = preservedSelection)
            }

            // Fetch in small batches to respect Google's rate limits
            val selectedCourses = mergedCourses.filter { it.isSelectedForWidget }
            val existingCoursework = if (hasOnlyMockCourses) emptyList() else courseworkDao.getAllCoursework().map { it.toDomain() }
            val allCoursework = mutableListOf<Coursework>()

            val chunkSize = 2
            for (chunk in selectedCourses.chunked(chunkSize)) {
                coroutineScope {
                    val deferredResults = chunk.map { course ->
                        async {
                            try {
                                apiService.fetchCourseworkForCourse(course, accessToken)
                            } catch (e: Exception) {
                                // Preserve cached coursework if individual course fetch fails
                                existingCoursework.filter { it.courseId == course.id }
                            }
                        }
                    }
                    val results = deferredResults.awaitAll()
                    results.forEach { allCoursework.addAll(it) }
                }
                delay(350)
            }

            // Preserve unselected courses' coursework in cache
            val unselectedIds = mergedCourses.filter { !it.isSelectedForWidget }.map { it.id }.toSet()
            val preservedItems = existingCoursework.filter { unselectedIds.contains(it.courseId) }
            allCoursework.addAll(preservedItems)

            database.withTransaction {
                if (hasOnlyMockCourses) {
                    courseDao.deleteAllCourses()
                    courseworkDao.deleteAllCoursework()
                }

                courseDao.upsertCourses(mergedCourses.map { CourseEntity.fromDomain(it) })

                // Remove deleted or archived courses
                val activeCourseIds = mergedCourses.map { it.id }
                if (activeCourseIds.isNotEmpty()) {
                    courseDao.deleteCoursesNotIn(activeCourseIds)
                }

                // Re-read local status to avoid overwriting checkmarks toggled during fetch
                val latestCoursework = courseworkDao.getAllCoursework().map { it.toDomain() }
                val latestStatusMap = latestCoursework.associateBy { it.id }

                val finalCoursework = allCoursework.map { incoming ->
                    val latest = latestStatusMap[incoming.id]
                    // Keep local completion if not yet turned in on Classroom
                    val wasManuallyCompleted = !incoming.isCompleted &&
                            (latest?.isManuallyCompleted == true || latest?.status == SubmissionStatus.TURNED_IN)

                    if (wasManuallyCompleted) {
                        incoming.copy(
                            status = SubmissionStatus.TURNED_IN,
                            isManuallyCompleted = true
                        )
                    } else {
                        incoming
                    }
                }

                courseworkDao.upsertCourseworks(finalCoursework.map { CourseworkEntity.fromDomain(it) })

                // Remove deleted assignments
                val validCourseworkIds = finalCoursework.map { it.id }
                if (validCourseworkIds.isNotEmpty()) {
                    courseworkDao.deleteCourseworkNotIn(validCourseworkIds)
                }
            }

            preferences.saveLastSyncTime(System.currentTimeMillis())
            notifyWidgetReload()
            Result.success(Unit)
        } catch (e: Exception) {
            _syncErrorMessage.value = "Lỗi đồng bộ: ${e.localizedMessage}"
            Result.failure(e)
        } finally {
            _isSyncing.value = false
        }
    }

    suspend fun clearAllData() = withContext(Dispatchers.IO) {
        courseDao.deleteAllCourses()
        courseworkDao.deleteAllCoursework()
        preferences.clear()
        oauthManager.signOut()
        ensureInitialData()
        notifyWidgetReload()
    }

    suspend fun notifyWidgetReload() {
        try {
            val manager = GlanceAppWidgetManager(context)
            val glanceIds = manager.getGlanceIds(ClassroomGlanceWidget::class.java)
            glanceIds.forEach { glanceId ->
                ClassroomGlanceWidget().update(context, glanceId)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
