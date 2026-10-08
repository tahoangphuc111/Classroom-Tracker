package com.phucta.classroom.data.repository

import android.content.Context
import androidx.glance.appwidget.GlanceAppWidgetManager
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

    // Observable Flows from Room
    val coursesFlow: Flow<List<Course>> = combine(
        courseDao.observeAllCourses(),
        preferences.hasUserLoggedInFlow
    ) { entities, hasLoggedIn ->
        if (entities.isNotEmpty()) {
            entities.map { it.toDomain() }
        } else if (!hasLoggedIn) {
            MockDataProvider.mockCourses
        } else {
            emptyList()
        }
    }

    val courseworkFlow: Flow<List<Coursework>> = combine(
        courseworkDao.observeAllCoursework(),
        preferences.hasUserLoggedInFlow
    ) { entities, hasLoggedIn ->
        if (entities.isNotEmpty()) {
            entities.map { it.toDomain() }
        } else if (!hasLoggedIn) {
            MockDataProvider.getMockCoursework()
        } else {
            emptyList()
        }
    }

    suspend fun ensureInitialData() = withContext(Dispatchers.IO) {
        val hasLoggedIn = preferences.hasUserLoggedInFlow.first()
        if (!hasLoggedIn) {
            val existingCourses = courseDao.getAllCourses()
            if (existingCourses.isEmpty()) {
                courseDao.upsertCourses(MockDataProvider.mockCourses.map { CourseEntity.fromDomain(it) })
                courseworkDao.upsertCourseworks(MockDataProvider.getMockCoursework().map { CourseworkEntity.fromDomain(it) })
            }
        }
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
     * Synchronizes Google Classroom courses and coursework.
     * Enforces:
     * 1. 10 QPS Quota Shield: Chunks course queries by 3 with delay.
     * 2. Checklist State Preservation: Never overwrites locally completed tasks, accepts Google completions.
     * 3. Selection State Preservation: Merges existing course widget selection flags.
     * 4. Cache Hygiene: Removes mock data on first sync and purges stale courses/tasks.
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

            // 1. Fetch active courses
            val fetchedCourses = apiService.fetchActiveCourses(accessToken)

            // If database currently holds mock data, purge mock data before saving real data
            val existingCourseEntities = courseDao.getAllCourses()
            val hasOnlyMockCourses = existingCourseEntities.isNotEmpty() &&
                    existingCourseEntities.all { MockDataProvider.isMockCourse(it.id) }
            if (hasOnlyMockCourses) {
                courseDao.deleteAllCourses()
                courseworkDao.deleteAllCoursework()
            }

            // Merge existing isSelectedForWidget states
            val existingCourses = if (hasOnlyMockCourses) emptyList() else courseDao.getAllCourses().map { it.toDomain() }
            val existingSelectionMap = existingCourses.associate { it.id to it.isSelectedForWidget }

            val mergedCourses = fetchedCourses.map { course ->
                val preservedSelection = existingSelectionMap[course.id] ?: true
                course.copy(isSelectedForWidget = preservedSelection)
            }
            courseDao.upsertCourses(mergedCourses.map { CourseEntity.fromDomain(it) })

            // Clean up stale courses that were archived or deleted on Google
            val activeCourseIds = mergedCourses.map { it.id }
            if (activeCourseIds.isNotEmpty()) {
                courseDao.deleteCoursesNotIn(activeCourseIds)
            }

            // 2. Fetch coursework for selected courses using 10 QPS Quota Shield
            val selectedCourses = mergedCourses.filter { it.isSelectedForWidget }
            val existingCoursework = if (hasOnlyMockCourses) emptyList() else courseworkDao.getAllCoursework().map { it.toDomain() }
            val allCoursework = mutableListOf<Coursework>()

            val chunkSize = 3
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
                delay(200) // 10 QPS protection breathing room
            }

            // Preserve unselected courses' coursework in cache
            val unselectedIds = mergedCourses.filter { !it.isSelectedForWidget }.map { it.id }.toSet()
            val preservedItems = existingCoursework.filter { unselectedIds.contains(it.courseId) }
            allCoursework.addAll(preservedItems)

            // 3. Preserve manual checklist completion if not yet turned in on Google Classroom
            val existingStatusMap = existingCoursework.associateBy { it.id }
            val finalCoursework = allCoursework.map { incoming ->
                val existing = existingStatusMap[incoming.id]
                // If Google reports completed (TURNED_IN or RETURNED), accept Google's status.
                // If Google reports incomplete, keep local checkmark if user previously marked it complete.
                val wasManuallyCompleted = !incoming.isCompleted &&
                        (existing?.isManuallyCompleted == true || existing?.status == SubmissionStatus.TURNED_IN)

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

            // Clean up stale coursework that was removed on Google
            val validCourseworkIds = finalCoursework.map { it.id }
            if (validCourseworkIds.isNotEmpty()) {
                courseworkDao.deleteCourseworkNotIn(validCourseworkIds)
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
