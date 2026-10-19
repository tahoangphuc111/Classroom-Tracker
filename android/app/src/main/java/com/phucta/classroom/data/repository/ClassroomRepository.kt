package com.phucta.classroom.data.repository

import android.content.Context
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.room.withTransaction
import com.phucta.classroom.data.local.ClassroomDatabase
import com.phucta.classroom.data.local.ClassroomPreferences
import com.phucta.classroom.data.local.CourseEntity
import com.phucta.classroom.data.local.CourseworkEntity
import com.phucta.classroom.data.local.MockDataProvider
import com.phucta.classroom.data.local.PersonalNoteEntity
import com.phucta.classroom.data.model.Course
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.data.model.PersonalNote
import com.phucta.classroom.data.model.SubmissionStatus
import com.phucta.classroom.data.remote.ClassroomApiService
import com.phucta.classroom.data.remote.GoogleOAuthManager
import com.phucta.classroom.widget.ClassroomGlanceWidget
import kotlinx.coroutines.CancellationException
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
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
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
    private val personalNoteDao = database.personalNoteDao()
    private val syncMutex = Mutex()

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

    val personalNotesFlow: Flow<List<PersonalNote>> = personalNoteDao.observeAllNotes().map { entities ->
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
        if (!syncMutex.tryLock()) {
            // Already syncing, do not pile up redundant background sync requests
            return@withContext Result.success(Unit)
        }
        try {
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
                var hasAnyFetchErrors = false

                val chunkSize = 2
                for (chunk in selectedCourses.chunked(chunkSize)) {
                    coroutineScope {
                        val deferredResults = chunk.map { course ->
                            async {
                                try {
                                    apiService.fetchCourseworkForCourse(course, accessToken)
                                } catch (e: Exception) {
                                    if (e is CancellationException) throw e
                                    hasAnyFetchErrors = true
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

                    val uniqueCourses = mergedCourses.distinctBy { it.id }
                    courseDao.upsertCourses(uniqueCourses.map { CourseEntity.fromDomain(it) })

                    // Remove deleted or archived courses
                    val activeCourseIds = uniqueCourses.map { it.id }
                    if (activeCourseIds.isNotEmpty()) {
                        courseDao.deleteCoursesNotIn(activeCourseIds)
                    }

                    // Re-read local status to avoid overwriting checkmarks toggled during fetch
                    val latestCoursework = courseworkDao.getAllCoursework().map { it.toDomain() }
                    val latestStatusMap = latestCoursework.associateBy { it.id }

                    val finalCoursework = allCoursework.distinctBy { it.id }.map { incoming ->
                        val latest = latestStatusMap[incoming.id]
                        // Only keep local completion if the user explicitly manually checked it off in this app
                        val wasManuallyCompleted = !incoming.isCompleted &&
                                (latest?.isManuallyCompleted == true)

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

                    // Remove deleted assignments only if all selected courses fetched successfully without errors
                    val validCourseworkIds = finalCoursework.map { it.id }
                    if (validCourseworkIds.isNotEmpty() && !hasAnyFetchErrors) {
                        courseworkDao.deleteCourseworkNotIn(validCourseworkIds)
                    }
                }

                preferences.saveLastSyncTime(System.currentTimeMillis())
                notifyWidgetReload()
                Result.success(Unit)
            } catch (e: Exception) {
                if (e is CancellationException) throw e
                _syncErrorMessage.value = "Lỗi đồng bộ: ${e.localizedMessage}"
                Result.failure(e)
            } finally {
                _isSyncing.value = false
            }
        } finally {
            syncMutex.unlock()
        }
    }

    suspend fun clearAllData(includePersonalNotes: Boolean = true) = withContext(Dispatchers.IO) {
        database.withTransaction {
            courseDao.deleteAllCourses()
            courseworkDao.deleteAllCoursework()
            if (includePersonalNotes) {
                personalNoteDao.deleteAllNotes()
            }
        }
        preferences.clear()
        oauthManager.signOut()
        ensureInitialData()
        notifyWidgetReload()
    }

    fun observeNoteForCoursework(courseworkId: String): Flow<PersonalNote?> {
        return personalNoteDao.observeNoteForCoursework(courseworkId).map { it?.toDomain() }
    }

    suspend fun getNoteForCoursework(courseworkId: String): PersonalNote? = withContext(Dispatchers.IO) {
        personalNoteDao.getNoteForCoursework(courseworkId)?.toDomain()
    }

    suspend fun savePersonalNote(note: PersonalNote) = withContext(Dispatchers.IO) {
        personalNoteDao.upsertNote(PersonalNoteEntity.fromDomain(note))
        notifyWidgetReload()
    }

    suspend fun saveNoteForCoursework(
        courseworkId: String,
        courseId: String? = null,
        courseName: String? = null,
        title: String,
        content: String
    ) = withContext(Dispatchers.IO) {
        val trimmed = content.trim()
        val existing = personalNoteDao.getNoteForCoursework(courseworkId)
        if (existing != null) {
            if (trimmed.isEmpty()) {
                personalNoteDao.deleteNoteById(existing.id)
            } else {
                val updated = existing.copy(
                    content = trimmed,
                    courseId = courseId ?: existing.courseId,
                    courseName = courseName ?: existing.courseName,
                    updatedAt = System.currentTimeMillis(),
                    searchIndex = PersonalNote.buildSearchIndex(existing.title, trimmed, courseName ?: existing.courseName)
                )
                personalNoteDao.upsertNote(updated)
            }
        } else if (trimmed.isNotEmpty()) {
            val newNote = PersonalNote(
                courseworkId = courseworkId,
                courseId = courseId,
                courseName = courseName,
                title = title,
                content = trimmed
            )
            personalNoteDao.upsertNote(PersonalNoteEntity.fromDomain(newNote))
        }
        notifyWidgetReload()
    }

    suspend fun togglePersonalNoteCompletion(id: String, isCompleted: Boolean) = withContext(Dispatchers.IO) {
        personalNoteDao.updateCompletionStatus(id, isCompleted)
        notifyWidgetReload()
    }

    suspend fun deletePersonalNote(id: String) = withContext(Dispatchers.IO) {
        personalNoteDao.deleteNoteById(id)
        notifyWidgetReload()
    }

    suspend fun notifyWidgetReload() {
        try {
            val manager = GlanceAppWidgetManager(context)
            val glanceIds = manager.getGlanceIds(ClassroomGlanceWidget::class.java)
            glanceIds.forEach { glanceId ->
                ClassroomGlanceWidget().update(context, glanceId)
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
