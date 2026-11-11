package com.phucta.classroom.data.repository

import android.content.Context
import androidx.glance.appwidget.GlanceAppWidgetManager
import androidx.room.withTransaction
import com.phucta.classroom.data.local.ClassroomDatabase
import com.phucta.classroom.data.local.ClassroomPreferences
import com.phucta.classroom.data.local.CourseEntity
import com.phucta.classroom.data.local.CourseworkEntity
import com.phucta.classroom.data.local.toCoursework
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
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext

class ClassroomRepository(
    context: Context,
    private val database: ClassroomDatabase,
    private val preferences: ClassroomPreferences,
    private val oauthManager: GoogleOAuthManager,
    private val apiService: ClassroomApiService = ClassroomApiService()
) {
    private val appContext = context.applicationContext
    private val courseDao = database.courseDao()
    private val courseworkDao = database.courseworkDao()
    private val personalNoteDao = database.personalNoteDao()
    private val syncMutex = Mutex()

    private val _isSyncing = MutableStateFlow(false)
    val isSyncing: StateFlow<Boolean> = _isSyncing.asStateFlow()

    private val _syncErrorMessage = MutableStateFlow<String?>(null)
    val syncErrorMessage: StateFlow<String?> = _syncErrorMessage.asStateFlow()

    val coursesFlow: Flow<List<Course>> = courseDao.observeAllCourses().distinctUntilChanged().map { entities ->
        entities.map { it.toDomain() }
    }.flowOn(Dispatchers.Default)

    val courseworkFlow: Flow<List<Coursework>> = courseworkDao.observeAllCoursework().distinctUntilChanged().map { entities ->
        entities.toCoursework()
    }.flowOn(Dispatchers.Default)

    val personalNotesFlow: Flow<List<PersonalNote>> = personalNoteDao.observeAllNotes().distinctUntilChanged().map { entities ->
        entities.map { it.toDomain() }
    }.flowOn(Dispatchers.Default)

    suspend fun ensureInitialData() = withContext(Dispatchers.IO) {
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

    suspend fun updateAllCoursesWidgetSelection(isSelected: Boolean) = withContext(Dispatchers.IO) {
        courseDao.updateAllWidgetSelection(isSelected)
        notifyWidgetReload()
    }

    suspend fun toggleTaskCompletion(id: String, completed: Boolean) = withContext(Dispatchers.IO) {
        if (id.startsWith("note_")) {
            val noteId = id.removePrefix("note_")
            togglePersonalNoteCompletion(noteId, completed)
        } else {
            val newStatus = if (completed) SubmissionStatus.TURNED_IN.rawValue else SubmissionStatus.PENDING.rawValue
            courseworkDao.updateCompletionStatus(id, newStatus, isManuallyCompleted = completed)
            notifyWidgetReload()
        }
    }

    suspend fun syncAll(): Result<Unit> = withContext(Dispatchers.IO) {
        if (!syncMutex.tryLock()) {
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
                if (fetchedCourses.isNotEmpty()) {
                    delay(300)
                }
                val existingCourseEntities = courseDao.getAllCourses()
                val hasOnlyMockCourses = existingCourseEntities.isNotEmpty() &&
                        existingCourseEntities.all { MockDataProvider.isMockCourse(it.id) }
                val existingCourses = if (hasOnlyMockCourses) emptyList() else existingCourseEntities.map { it.toDomain() }.filter { !MockDataProvider.isMockCourse(it.id) }
                val existingSelectionMap = existingCourses.associate { it.id to it.isSelectedForWidget }
                val mergedCourses = fetchedCourses.map { course ->
                    val preservedSelection = existingSelectionMap[course.id] ?: true
                    course.copy(isSelectedForWidget = preservedSelection)
                }
                val selectedCourses = mergedCourses.filter { it.isSelectedForWidget }
                val existingCoursework = if (hasOnlyMockCourses) emptyList() else courseworkDao.getAllCoursework().toCoursework().filter { !MockDataProvider.isMockCourseworkId(it.id) }
                val allCoursework = mutableListOf<Coursework>()
                var hasAnyFetchErrors = false
                val fetchedCourseIds = mutableSetOf<String>()
                val chunkSize = 2
                val courseChunks = selectedCourses.chunked(chunkSize)
                for ((chunkIndex, chunk) in courseChunks.withIndex()) {
                    coroutineScope {
                        val deferredResults = chunk.map { course ->
                            async {
                                try {
                                    course.id to apiService.fetchCourseworkForCourse(course, accessToken)
                                } catch (e: Exception) {
                                    if (e is CancellationException) throw e
                                    course.id to null
                                }
                            }
                        }
                        val results = deferredResults.awaitAll()
                        results.forEach { (courseId, items) ->
                            if (items != null) {
                                fetchedCourseIds.add(courseId)
                                allCoursework.addAll(items)
                            } else {
                                hasAnyFetchErrors = true
                                allCoursework.addAll(existingCoursework.filter { it.courseId == courseId })
                            }
                        }
                    }
                    if (chunkIndex < courseChunks.lastIndex) {
                        delay(500)
                    }
                }
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

                    val activeCourseIds = uniqueCourses.map { it.id }
                    if (activeCourseIds.isNotEmpty()) {
                        courseDao.deleteCoursesNotIn(activeCourseIds)
                    } else {
                        courseDao.deleteAllCourses()
                    }
                    val latestCoursework = courseworkDao.getAllCoursework().toCoursework()
                    val latestStatusMap = latestCoursework.associateBy { it.id }
                    val finalCoursework = allCoursework.distinctBy { it.id }.map { incoming ->
                        reconcileCoursework(latestStatusMap[incoming.id], incoming, isRemote = incoming.courseId in fetchedCourseIds)
                    }
                    courseworkDao.upsertCourseworks(finalCoursework.map { CourseworkEntity.fromDomain(it) })

                    val validCourseworkIds = finalCoursework.map { it.id }
                    if (!hasAnyFetchErrors) {
                        if (validCourseworkIds.isNotEmpty()) {
                            courseworkDao.deleteCourseworkNotIn(validCourseworkIds)
                            database.personalNoteDao().deleteNotesWithCourseworkNotIn(validCourseworkIds)
                        } else {
                            courseworkDao.deleteAllCoursework()
                            database.personalNoteDao().deleteAllCourseworkAttachedNotes()
                        }
                    }
                }
                notifyWidgetReload()
                if (hasAnyFetchErrors) {
                    val message = "Một số lớp chưa đồng bộ được. Đã giữ dữ liệu cũ; vui lòng thử lại."
                    _syncErrorMessage.value = message
                    Result.failure(java.io.IOException(message))
                } else {
                    preferences.saveLastSyncTime(System.currentTimeMillis())
                    Result.success(Unit)
                }
            } catch (e: Exception) {
                if (e is CancellationException) throw e
                val friendlyMessage = when {
                    e is java.net.UnknownHostException ->
                        "Không có kết nối mạng. Vui lòng kiểm tra lại đường truyền."
                    e is java.net.SocketTimeoutException ->
                        "Kết nối mạng quá hạn. Vui lòng thử lại sau."
                    e.message?.contains("Phiên đăng nhập") == true ||
                    e.message?.contains("Chưa đăng nhập") == true ||
                    e.message?.contains("401") == true ->
                        "Phiên đăng nhập đã hết hạn hoặc bị thu hồi. Vui lòng đăng nhập lại."
                    e.message?.contains("429") == true ->
                        "Đã đạt giới hạn yêu cầu Google Classroom. Vui lòng đợi trong giây lát."
                    !e.localizedMessage.isNullOrBlank() ->
                        "Lỗi đồng bộ: ${e.localizedMessage}"
                    else ->
                        "Lỗi đồng bộ dữ liệu. Vui lòng thử lại sau."
                }
                _syncErrorMessage.value = friendlyMessage
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
        if (note.courseworkId != null && note.content.trim().isEmpty() && note.checklist.isEmpty()) {
            personalNoteDao.deleteNoteById(note.id)
        } else {
            personalNoteDao.upsertNote(PersonalNoteEntity.fromDomain(note))
        }
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
            val existingDomain = existing.toDomain()
            if (trimmed.isEmpty() && existingDomain.checklist.isEmpty()) {
                personalNoteDao.deleteNoteById(existing.id)
            } else {
                val updated = existing.copy(
                    content = trimmed,
                    courseId = courseId ?: existing.courseId,
                    courseName = courseName ?: existing.courseName,
                    updatedAt = System.currentTimeMillis(),
                    searchIndex = PersonalNote.buildSearchIndex(
                        existing.title,
                        trimmed,
                        courseName ?: existing.courseName,
                        existingDomain.checklist
                    )
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
        val existing = personalNoteDao.getNoteById(id)
        if (existing != null) {
            val domain = existing.toDomain()
            if (domain.checklist.isNotEmpty()) {
                val updatedChecklist = domain.checklist.map { it.copy(isCompleted = isCompleted) }
                val updatedNote = domain.copy(
                    isCompleted = isCompleted,
                    checklist = updatedChecklist,
                    updatedAt = System.currentTimeMillis()
                )
                personalNoteDao.upsertNote(PersonalNoteEntity.fromDomain(updatedNote))
            } else {
                personalNoteDao.updateCompletionStatus(id, isCompleted)
            }
        } else {
            personalNoteDao.updateCompletionStatus(id, isCompleted)
        }
        notifyWidgetReload()
    }
    suspend fun toggleChecklistItem(noteId: String, itemId: String) = withContext(Dispatchers.IO) {
        val entity = personalNoteDao.getNoteById(noteId) ?: return@withContext
        val note = entity.toDomain()
        val updatedChecklist = note.checklist.map { item ->
            if (item.id == itemId) item.copy(isCompleted = !item.isCompleted) else item
        }
        val allDone = updatedChecklist.isNotEmpty() && updatedChecklist.all { it.isCompleted }
        val anyPending = updatedChecklist.any { !it.isCompleted }
        val newNoteCompleted = when {
            allDone -> true
            anyPending && note.isCompleted -> false
            else -> note.isCompleted
        }
        val updatedNote = note.copy(
            checklist = updatedChecklist,
            isCompleted = newNoteCompleted,
            updatedAt = System.currentTimeMillis()
        )
        personalNoteDao.upsertNote(PersonalNoteEntity.fromDomain(updatedNote))
        notifyWidgetReload()
    }
    suspend fun deletePersonalNote(id: String) = withContext(Dispatchers.IO) {
        personalNoteDao.deleteNoteById(id)
        notifyWidgetReload()
    }
    suspend fun notifyWidgetReload() {
        try {
            val manager = GlanceAppWidgetManager(appContext)
            val widgets: List<androidx.glance.appwidget.GlanceAppWidget> = listOf(
                com.phucta.classroom.widget.ClassroomGlanceWidget(),
                com.phucta.classroom.widget.ClassroomSmallGlanceWidget(),
                com.phucta.classroom.widget.ClassroomMediumGlanceWidget(),
                com.phucta.classroom.widget.ClassroomLargeGlanceWidget()
            )
            for (widget in widgets) {
                try {
                    val glanceIds = manager.getGlanceIds(widget.javaClass)
                    glanceIds.forEach { glanceId ->
                        widget.update(appContext, glanceId)
                    }
                } catch (_: Exception) {}
            }
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
    companion object {
        fun reconcileCoursework(latest: Coursework?, incoming: Coursework, isRemote: Boolean = true): Coursework {
            if (latest == null) return incoming
            if (!isRemote) return latest
            val localIsManuallyCompleted = latest.isManuallyCompleted
            val incomingIsPendingOrLate = incoming.status == SubmissionStatus.PENDING ||
                    incoming.status == SubmissionStatus.LATE
            val shouldPreserveLocalStatus = incomingIsPendingOrLate && localIsManuallyCompleted
            val resolvedStatus = if (shouldPreserveLocalStatus) {
                if (latest.status == SubmissionStatus.RETURNED) SubmissionStatus.RETURNED else SubmissionStatus.TURNED_IN
            } else {
                incoming.status
            }
            val resolvedManuallyCompleted = if (incoming.status == SubmissionStatus.TURNED_IN || incoming.status == SubmissionStatus.RETURNED) {
                false
            } else {
                localIsManuallyCompleted || incoming.isManuallyCompleted
            }
            return incoming.copy(
                status = resolvedStatus,
                isManuallyCompleted = resolvedManuallyCompleted
            )
        }
    }
}
