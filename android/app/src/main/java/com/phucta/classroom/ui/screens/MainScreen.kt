package com.phucta.classroom.ui.screens

import android.content.Context
import androidx.activity.compose.BackHandler
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.Offset
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import coil.compose.AsyncImage
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.Refresh
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.automirrored.filled.StickyNote2
import androidx.compose.material.icons.filled.Upcoming
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CheckboxDefaults
import androidx.compose.material3.DrawerValue
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalDrawerSheet
import androidx.compose.material3.ModalNavigationDrawer
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.NavigationRail
import androidx.compose.material3.NavigationRailItem
import androidx.compose.material3.NavigationRailItemDefaults
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.TopAppBarScrollBehavior
import androidx.compose.material3.VerticalDivider
import androidx.compose.material3.rememberDrawerState
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.produceState
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableLongStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.material3.pulltorefresh.PullToRefreshDefaults
import androidx.compose.material3.pulltorefresh.rememberPullToRefreshState
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.ui.semantics.Role
import com.phucta.classroom.ClassroomApplication
import com.phucta.classroom.data.model.Course
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.data.model.PersonalNote
import com.phucta.classroom.domain.BaoBaiBucketingUtils
import com.phucta.classroom.ui.components.EmberFlameCanvas
import com.phucta.classroom.ui.components.HomeworkDetailBottomSheet
import com.phucta.classroom.ui.components.SubjectBadgePill
import com.phucta.classroom.ui.theme.ChunkyColor
import androidx.compose.runtime.Immutable
import kotlinx.coroutines.launch

@Immutable
private data class MainScreenCourseworkState(
    val tomorrowItems: List<Coursework> = emptyList(),
    val completedItems: List<Coursework> = emptyList(),
    val upcomingIncompleteCount: Int = 0
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen() {
    val context = LocalContext.current
    val app = context.applicationContext as ClassroomApplication
    val repository = app.repository
    val oauthManager = app.oauthManager
    val preferences = app.preferences

    val scope = rememberCoroutineScope()
    val drawerState = rememberDrawerState(initialValue = DrawerValue.Closed)
    val snackbarHostState = remember { SnackbarHostState() }

    var selectedTabIndex by rememberSaveable { mutableIntStateOf(0) }
    val tabStates = rememberSaveableStateHolder()
    var showSettingsDialog by rememberSaveable { mutableStateOf(false) }
    var selectedCourseworkId by rememberSaveable { mutableStateOf<String?>(null) }
    var noteToEditFromExternal by remember { mutableStateOf<PersonalNote?>(null) }
    var isDemoMode by rememberSaveable { mutableStateOf(false) }
    var currentDayEpoch by remember { mutableLongStateOf(com.phucta.classroom.data.model.ClassroomDateUtils.startOfToday) }
    var drawerSearchQuery by rememberSaveable { mutableStateOf("") }
    val view = LocalView.current

    LaunchedEffect(Unit) {
        while (true) {
            kotlinx.coroutines.delay(30_000L)
            com.phucta.classroom.data.model.ClassroomDateUtils.ensureDayBoundaries()
            val today = com.phucta.classroom.data.model.ClassroomDateUtils.startOfToday
            if (today != currentDayEpoch) {
                currentDayEpoch = today
            }
        }
    }

    val courses by repository.coursesFlow.collectAsStateWithLifecycle(initialValue = emptyList())
    val allCoursework by repository.courseworkFlow.collectAsStateWithLifecycle(initialValue = emptyList())
    val personalNotes by repository.personalNotesFlow.collectAsStateWithLifecycle(initialValue = emptyList())
    val isSyncing by repository.isSyncing.collectAsStateWithLifecycle()
    val syncErrorMessage by repository.syncErrorMessage.collectAsStateWithLifecycle()
    val authErrorMessage by oauthManager.authErrorMessage.collectAsStateWithLifecycle()
    val isAuthenticated by oauthManager.isAuthenticated.collectAsStateWithLifecycle()
    val userEmail by preferences.userEmailFlow.collectAsStateWithLifecycle(initialValue = null)
    val userName by preferences.userNameFlow.collectAsStateWithLifecycle(initialValue = null)
    val userAvatar by preferences.userAvatarFlow.collectAsStateWithLifecycle(initialValue = null)
    val customClientId by preferences.customClientIdFlow.collectAsStateWithLifecycle(initialValue = null)

    LaunchedEffect(syncErrorMessage) {
        syncErrorMessage?.let { message ->
            snackbarHostState.showSnackbar(message)
        }
    }

    LaunchedEffect(authErrorMessage) {
        authErrorMessage?.let { message ->
            snackbarHostState.showSnackbar(message)
        }
    }

    // Sorting and note conversion must not compete with gesture/animation frames.
    // produceState cancels obsolete results when a newer database snapshot arrives.
    val courseworkState by produceState(
        MainScreenCourseworkState(), allCoursework, courses, personalNotes, currentDayEpoch
    ) {
        value = withContext(Dispatchers.Default) {
            val now = System.currentTimeMillis()
            val active = BaoBaiBucketingUtils.filterByActiveCourses(allCoursework, courses)

            val tomorrow = BaoBaiBucketingUtils.getTomorrowCoursework(
                filteredItems = active,
                courses = courses,
                personalNotes = personalNotes,
                now = now
            )
            val completed = active.filter { it.isCompletedAt(now) }.sortedWith { first, second ->
                when {
                    first.dueEpochMillis != null && second.dueEpochMillis != null -> {
                        val dueDiff = second.dueEpochMillis.compareTo(first.dueEpochMillis)
                        if (dueDiff != 0) dueDiff else first.id.compareTo(second.id)
                    }
                    first.dueEpochMillis != null -> -1
                    second.dueEpochMillis != null -> 1
                    else -> {
                        val titleDiff = first.title.compareTo(second.title, ignoreCase = true)
                        if (titleDiff != 0) titleDiff else first.id.compareTo(second.id)
                    }
                }
            }
            MainScreenCourseworkState(
                tomorrowItems = tomorrow,
                completedItems = completed,
                upcomingIncompleteCount = active.size - completed.size
            )
        }
    }

    val tomorrowItems = courseworkState.tomorrowItems
    val completedItems = courseworkState.completedItems
    val upcomingIncompleteCount = courseworkState.upcomingIncompleteCount

    val tomorrowIncompleteCount = remember(tomorrowItems) {
        tomorrowItems.count { !it.isCompleted }
    }

    val incompleteNotesCount = remember(personalNotes) {
        personalNotes.count { it.courseworkId == null && !it.isCompleted }
    }

    val courseworkIdsWithNotes = remember(personalNotes) {
        val set = HashSet<String>()
        for (note in personalNotes) {
            val cid = note.courseworkId
            if (cid != null && (note.content.isNotBlank() || note.checklist.isNotEmpty())) {
                set.add(cid)
            }
        }
        set
    }

    val pullToRefreshState = rememberPullToRefreshState()

    val onToggleAssignmentCompletion = remember(scope, repository, snackbarHostState) {
        { id: String, completed: Boolean ->
            if (id.startsWith("note_")) {
                val noteId = id.removePrefix("note_")
                scope.launch {
                    try {
                        repository.togglePersonalNoteCompletion(noteId, completed)
                        if (completed) {
                            val result = snackbarHostState.showSnackbar(
                                message = "Đã hoàn thành ghi chú!",
                                actionLabel = "Hoàn tác",
                                duration = androidx.compose.material3.SnackbarDuration.Short
                            )
                            if (result == androidx.compose.material3.SnackbarResult.ActionPerformed) {
                                repository.togglePersonalNoteCompletion(noteId, false)
                            }
                        }
                    } catch (e: Exception) {
                        snackbarHostState.showSnackbar("Không thể cập nhật ghi chú: ${e.localizedMessage ?: "Đã xảy ra lỗi"}")
                    }
                }
            } else {
                scope.launch {
                    try {
                        repository.toggleTaskCompletion(id, completed)
                        if (completed) {
                            val result = snackbarHostState.showSnackbar(
                                message = "Đã hoàn thành bài tập!",
                                actionLabel = "Hoàn tác",
                                duration = androidx.compose.material3.SnackbarDuration.Short
                            )
                            if (result == androidx.compose.material3.SnackbarResult.ActionPerformed) {
                                repository.toggleTaskCompletion(id, false)
                            }
                        }
                    } catch (e: Exception) {
                        snackbarHostState.showSnackbar("Không thể cập nhật bài tập: ${e.localizedMessage ?: "Đã xảy ra lỗi"}")
                    }
                }
            }
            Unit
        }
    }

    val onTogglePersonalNoteCompletion = remember(scope, repository, snackbarHostState) {
        { noteId: String, completed: Boolean ->
            scope.launch {
                try {
                    repository.togglePersonalNoteCompletion(noteId, completed)
                } catch (e: Exception) {
                    snackbarHostState.showSnackbar("Không thể cập nhật ghi chú: ${e.localizedMessage ?: "Đã xảy ra lỗi"}")
                }
            }
            Unit
        }
    }

    val onToggleChecklistItem = remember(scope, repository, snackbarHostState) {
        { noteId: String, itemId: String ->
            scope.launch {
                try {
                    repository.toggleChecklistItem(noteId, itemId)
                } catch (e: Exception) {
                    snackbarHostState.showSnackbar("Không thể cập nhật mục: ${e.localizedMessage ?: "Đã xảy ra lỗi"}")
                }
            }
            Unit
        }
    }

    val onSavePersonalNote = remember(scope, repository, snackbarHostState) {
        { note: PersonalNote ->
            scope.launch {
                try {
                    repository.savePersonalNote(note)
                } catch (e: Exception) {
                    snackbarHostState.showSnackbar("Không thể lưu ghi chú: ${e.localizedMessage ?: "Đã xảy ra lỗi"}")
                }
            }
            Unit
        }
    }

    val onDeletePersonalNote = remember(scope, repository, snackbarHostState) {
        { noteId: String ->
            scope.launch {
                try {
                    repository.deletePersonalNote(noteId)
                } catch (e: Exception) {
                    snackbarHostState.showSnackbar("Không thể xóa ghi chú: ${e.localizedMessage ?: "Đã xảy ra lỗi"}")
                }
            }
            Unit
        }
    }

    val onSelectAssignment = remember(personalNotes) {
        { coursework: Coursework ->
            if (coursework.id.startsWith("note_")) {
                val noteId = coursework.id.removePrefix("note_")
                noteToEditFromExternal = personalNotes.find { it.id == noteId }
                selectedTabIndex = 3
            } else {
                selectedCourseworkId = coursework.id
            }
        }
    }

    val isAnyCourseFiltered = remember(courses) { courses.any { !it.isSelectedForWidget } }
    val displayedCoursesInDrawer = remember(courses, drawerSearchQuery) {
        if (drawerSearchQuery.isBlank()) {
            courses
        } else {
            val q = drawerSearchQuery.trim().lowercase()
            courses.filter { it.name.lowercase().contains(q) }
        }
    }

    if (isAuthenticated || isDemoMode) {
        BackHandler(enabled = drawerState.isOpen) {
            scope.launch { drawerState.close() }
        }
        BackHandler(enabled = !drawerState.isOpen && selectedCourseworkId == null && !showSettingsDialog && selectedTabIndex != 0) {
            selectedTabIndex = 0
        }

        val colorScheme = MaterialTheme.colorScheme
        val topAppBarScrollBehavior = TopAppBarDefaults.pinnedScrollBehavior()

        BoxWithConstraints(modifier = Modifier.fillMaxSize()) {
            val useNavigationRail = maxWidth >= 600.dp

            ModalNavigationDrawer(
                drawerState = drawerState,
                drawerContent = {
                    ModalDrawerSheet(
                        drawerContainerColor = colorScheme.surfaceContainerLow,
                        modifier = Modifier.width(310.dp)
                    ) {
                        CourseFilterDrawerContent(
                            courses = courses,
                            displayedCourses = displayedCoursesInDrawer,
                            searchQuery = drawerSearchQuery,
                            onSearchQueryChange = { drawerSearchQuery = it },
                            onToggleCourse = { course ->
                                scope.launch {
                                    try {
                                        repository.updateCourseWidgetSelection(
                                            course.id,
                                            !course.isSelectedForWidget
                                        )
                                    } catch (e: Exception) {
                                        snackbarHostState.showSnackbar("Không thể cập nhật môn học: ${e.localizedMessage ?: "Đã xảy ra lỗi"}")
                                    }
                                }
                            },
                            onToggleAllCourses = { selectAll ->
                                scope.launch {
                                    try {
                                        repository.updateAllCoursesWidgetSelection(selectAll)
                                    } catch (e: Exception) {
                                        snackbarHostState.showSnackbar("Không thể cập nhật danh sách lớp: ${e.localizedMessage ?: "Đã xảy ra lỗi"}")
                                    }
                                }
                            }
                        )
                    }
                }
            ) {
                Scaffold(
                    modifier = Modifier.nestedScroll(topAppBarScrollBehavior.nestedScrollConnection),
                    containerColor = colorScheme.surface,
                    snackbarHost = { SnackbarHost(snackbarHostState) },
                    topBar = {
                        MainTopAppBar(
                            currentDayEpoch = currentDayEpoch,
                            isAnyCourseFiltered = isAnyCourseFiltered,
                            isSyncing = isSyncing,
                            userAvatar = userAvatar,
                            scrollBehavior = topAppBarScrollBehavior,
                            onOpenDrawer = { scope.launch { drawerState.open() } },
                            onSyncClick = {
                                scope.launch {
                                    try {
                                        val result = repository.syncAll()
                                        if (result.isSuccess) {
                                            snackbarHostState.showSnackbar("Đã cập nhật bài tập mới nhất!")
                                        } else {
                                            result.exceptionOrNull()?.let { e ->
                                                snackbarHostState.showSnackbar("Đồng bộ không thành công: ${e.localizedMessage ?: "Vui lòng thử lại"}")
                                            }
                                        }
                                    } catch (e: Exception) {
                                        snackbarHostState.showSnackbar("Đồng bộ không thành công: ${e.localizedMessage ?: "Vui lòng thử lại"}")
                                    }
                                }
                            },
                            onOpenSettings = { showSettingsDialog = true }
                        )
                    },
                    bottomBar = {
                        if (!useNavigationRail) {
                            MainBottomNavigationBar(
                                selectedTabIndex = selectedTabIndex,
                                tomorrowIncompleteCount = tomorrowIncompleteCount,
                                upcomingIncompleteCount = upcomingIncompleteCount,
                                incompleteNotesCount = incompleteNotesCount,
                                onTabSelected = { selectedTabIndex = it }
                            )
                        }
                    }
                ) { paddingValues ->
                    Row(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(paddingValues)
                    ) {
                        if (useNavigationRail) {
                            MainNavigationRail(
                                selectedTabIndex = selectedTabIndex,
                                tomorrowIncompleteCount = tomorrowIncompleteCount,
                                upcomingIncompleteCount = upcomingIncompleteCount,
                                incompleteNotesCount = incompleteNotesCount,
                                onTabSelected = { selectedTabIndex = it }
                            )
                            VerticalDivider(color = colorScheme.outlineVariant)
                        }

                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .fillMaxHeight(),
                            contentAlignment = Alignment.TopCenter
                        ) {
                            PullToRefreshBox(
                                isRefreshing = isSyncing,
                                onRefresh = {
                                    scope.launch {
                                        try {
                                            val result = repository.syncAll()
                                            if (result.isSuccess) {
                                                snackbarHostState.showSnackbar("Đã cập nhật bài tập mới nhất!")
                                            } else {
                                                result.exceptionOrNull()?.let { e ->
                                                    snackbarHostState.showSnackbar("Đồng bộ không thành công: ${e.localizedMessage ?: "Vui lòng thử lại"}")
                                                }
                                            }
                                        } catch (e: Exception) {
                                            snackbarHostState.showSnackbar("Đồng bộ không thành công: ${e.localizedMessage ?: "Vui lòng thử lại"}")
                                        }
                                    }
                                },
                                state = pullToRefreshState,
                                modifier = Modifier
                                    .fillMaxSize()
                                    .widthIn(max = 840.dp),
                                indicator = {
                                    PullToRefreshDefaults.Indicator(
                                        state = pullToRefreshState,
                                        isRefreshing = isSyncing,
                                        modifier = Modifier.align(Alignment.TopCenter),
                                        containerColor = colorScheme.surfaceContainerLowest,
                                        color = colorScheme.primary
                                    )
                                }
                            ) {
                                tabStates.SaveableStateProvider(selectedTabIndex) {
                                    when (selectedTabIndex) {
                                        0 -> TomorrowHomeworkScreen(
                                            tomorrowItems = tomorrowItems,
                                            courseworkIdsWithNotes = courseworkIdsWithNotes,
                                            currentDayEpoch = currentDayEpoch,
                                            onToggleCompletion = onToggleAssignmentCompletion,
                                            onSelectAssignment = onSelectAssignment
                                        )
                                        1 -> AllUpcomingScreen(
                                            allCoursework = allCoursework,
                                            courses = courses,
                                            courseworkIdsWithNotes = courseworkIdsWithNotes,
                                            currentDayEpoch = currentDayEpoch,
                                            onToggleCompletion = onToggleAssignmentCompletion,
                                            onSelectAssignment = onSelectAssignment
                                        )
                                        2 -> CompletedHomeworkScreen(
                                            completedItems = completedItems,
                                            courseworkIdsWithNotes = courseworkIdsWithNotes,
                                            onToggleCompletion = onToggleAssignmentCompletion,
                                            onSelectAssignment = onSelectAssignment
                                        )
                                        3 -> PersonalNotesScreen(
                                            notes = personalNotes,
                                            courses = courses,
                                            onToggleCompletion = onTogglePersonalNoteCompletion,
                                            onToggleChecklistItem = onToggleChecklistItem,
                                            onSaveNote = onSavePersonalNote,
                                            onDeleteNote = onDeletePersonalNote,
                                            initialNoteToEdit = noteToEditFromExternal,
                                            onClearInitialNoteToEdit = { noteToEditFromExternal = null }
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    } else {
        WelcomeLoginScreen(
            snackbarHostState = snackbarHostState,
            onSignIn = {
                scope.launch {
                    try {
                        oauthManager.startSignIn(context)
                    } catch (e: Exception) {
                        snackbarHostState.showSnackbar("Không thể đăng nhập: ${e.localizedMessage ?: "Đã xảy ra lỗi"}")
                    }
                }
            },
            onDemoMode = {
                scope.launch {
                    try {
                        repository.populateMockDataManually()
                        isDemoMode = true
                    } catch (e: Exception) {
                        snackbarHostState.showSnackbar("Không thể tải dữ liệu mẫu: ${e.localizedMessage ?: "Đã xảy ra lỗi"}")
                    }
                }
            },
            onOpenSettings = { showSettingsDialog = true }
        )
    }

    val activeSelectedCoursework = remember(selectedCourseworkId, allCoursework) {
        selectedCourseworkId?.let { id -> allCoursework.find { it.id == id } }
    }

    LaunchedEffect(selectedCourseworkId, allCoursework) {
        if (selectedCourseworkId != null && allCoursework.isNotEmpty() && activeSelectedCoursework == null) {
            selectedCourseworkId = null
        }
    }

    if (activeSelectedCoursework != null) {
        val attachedNote = remember(personalNotes, activeSelectedCoursework.id) {
            personalNotes.find { it.courseworkId == activeSelectedCoursework.id }
        }
        HomeworkDetailBottomSheet(
            coursework = activeSelectedCoursework,
            initialNoteContent = attachedNote?.content,
            attachedNote = attachedNote,
            onToggleChecklistItem = onToggleChecklistItem,
            onEditNoteInNotes = { note ->
                selectedCourseworkId = null
                noteToEditFromExternal = note
                selectedTabIndex = 3
            },
            onDismiss = { selectedCourseworkId = null },
            onToggleCompletion = { id, completed ->
                scope.launch {
                    try {
                        repository.toggleTaskCompletion(id, completed)
                    } catch (e: Exception) {
                        snackbarHostState.showSnackbar("Không thể cập nhật trạng thái bài tập: ${e.localizedMessage}")
                    }
                }
            },
            onSaveNote = { content ->
                scope.launch {
                    try {
                        repository.saveNoteForCoursework(
                            courseworkId = activeSelectedCoursework.id,
                            courseId = activeSelectedCoursework.courseId,
                            courseName = activeSelectedCoursework.courseName,
                            title = activeSelectedCoursework.title,
                            content = content
                        )
                    } catch (e: Exception) {
                        snackbarHostState.showSnackbar("Không thể lưu ghi chú: ${e.localizedMessage}")
                    }
                }
            }
        )
    }

    if (showSettingsDialog) {
        SettingsDialog(
            isAuthenticated = isAuthenticated,
            userEmail = userEmail,
            userName = userName,
            userAvatar = userAvatar,
            isSyncing = isSyncing,
            initialClientId = customClientId,
            onDismiss = { showSettingsDialog = false },
            onSignIn = {
                scope.launch {
                    try {
                        oauthManager.startSignIn(context)
                    } catch (e: Exception) {
                        snackbarHostState.showSnackbar("Không thể đăng nhập: ${e.localizedMessage ?: "Đã xảy ra lỗi"}")
                    }
                }
            },
            onSignOut = {
                isDemoMode = false
                scope.launch {
                    try {
                        repository.clearAllData(includePersonalNotes = false)
                    } catch (e: Exception) {
                        snackbarHostState.showSnackbar("Không thể đăng xuất: ${e.localizedMessage ?: "Đã xảy ra lỗi"}")
                    }
                }
            },
            onSyncNow = {
                scope.launch {
                    try {
                        repository.syncAll()
                    } catch (e: Exception) {
                        snackbarHostState.showSnackbar("Đồng bộ thất bại: ${e.localizedMessage ?: "Đã xảy ra lỗi"}")
                    }
                }
            },
            onSaveCustomCredentials = { customId ->
                scope.launch {
                    try {
                        preferences.saveCustomCredentials(customId, null)
                    } catch (e: Exception) {
                        snackbarHostState.showSnackbar("Không thể lưu cấu hình: ${e.localizedMessage ?: "Đã xảy ra lỗi"}")
                    }
                }
            }
        )
    }
}

@Composable
private fun CourseFilterDrawerContent(
    courses: List<Course>,
    displayedCourses: List<Course>,
    searchQuery: String,
    onSearchQueryChange: (String) -> Unit,
    onToggleCourse: (Course) -> Unit,
    onToggleAllCourses: (Boolean) -> Unit
) {
    val colorScheme = MaterialTheme.colorScheme

    Column(modifier = Modifier.padding(20.dp)) {
        Text(
            text = "Lọc môn học",
            style = MaterialTheme.typography.titleLarge,
            color = colorScheme.onSurface
        )
        Text(
            text = "Chọn các môn tham gia Báo bài & hiển thị trên Widget",
            style = MaterialTheme.typography.bodyMedium,
            color = colorScheme.onSurfaceVariant,
            modifier = Modifier.padding(top = 4.dp, bottom = 12.dp)
        )

        HorizontalDivider(color = colorScheme.outlineVariant)

        if (courses.isNotEmpty()) {
            val allSelected = courses.all { it.isSelectedForWidget }
            val selectedCount = courses.count { it.isSelectedForWidget }
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 8.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Lớp hiển thị ($selectedCount/${courses.size})",
                    style = MaterialTheme.typography.labelLarge,
                    color = colorScheme.onSurfaceVariant
                )
                TextButton(
                    onClick = { onToggleAllCourses(!allSelected) },
                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 2.dp)
                ) {
                    Text(
                        text = if (allSelected) "Bỏ chọn hết" else "Tất cả",
                        style = MaterialTheme.typography.labelLarge,
                        color = colorScheme.primary
                    )
                }
            }

            if (courses.size > 5) {
                Spacer(modifier = Modifier.height(8.dp))
                OutlinedTextField(
                    value = searchQuery,
                    onValueChange = onSearchQueryChange,
                    placeholder = { Text("Tìm tên môn học...", style = MaterialTheme.typography.bodyMedium) },
                    leadingIcon = {
                        Icon(
                            Icons.Default.Search,
                            contentDescription = null,
                            tint = colorScheme.onSurfaceVariant,
                            modifier = Modifier.size(18.dp)
                        )
                    },
                    trailingIcon = {
                        if (searchQuery.isNotEmpty()) {
                            IconButton(onClick = { onSearchQueryChange("") }) {
                                Icon(
                                    Icons.Default.Clear,
                                    contentDescription = "Xóa tìm kiếm",
                                    tint = colorScheme.onSurfaceVariant,
                                    modifier = Modifier.size(18.dp)
                                )
                            }
                        }
                    },
                    singleLine = true,
                    shape = RoundedCornerShape(28.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedContainerColor = colorScheme.surfaceContainerLowest,
                        unfocusedContainerColor = colorScheme.surfaceContainerLowest,
                        focusedBorderColor = colorScheme.primary,
                        unfocusedBorderColor = colorScheme.outlineVariant
                    ),
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(min = 48.dp)
                )
            }
        }
    }

    if (courses.isEmpty()) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 24.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "Chưa có môn học nào được đồng bộ.",
                style = MaterialTheme.typography.bodyMedium,
                color = colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
        }
    } else {
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(bottom = 24.dp)
        ) {
            items(
                items = displayedCourses,
                key = { it.id },
                contentType = { "course_filter_item" }
            ) { course ->
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(min = 48.dp)
                        .clickable(
                            role = Role.Checkbox,
                            onClick = { onToggleCourse(course) }
                        )
                        .padding(horizontal = 20.dp, vertical = 10.dp)
                ) {
                    SubjectBadgePill(courseName = course.name)
                    Spacer(modifier = Modifier.width(10.dp))
                    Text(
                        text = course.name,
                        style = MaterialTheme.typography.bodyLarge,
                        color = colorScheme.onSurface,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f)
                    )
                    Checkbox(
                        checked = course.isSelectedForWidget,
                        onCheckedChange = null,
                        colors = CheckboxDefaults.colors(checkedColor = colorScheme.primary)
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun MainTopAppBar(
    currentDayEpoch: Long,
    isAnyCourseFiltered: Boolean,
    isSyncing: Boolean,
    userAvatar: String? = null,
    scrollBehavior: TopAppBarScrollBehavior,
    onOpenDrawer: () -> Unit,
    onSyncClick: () -> Unit,
    onOpenSettings: () -> Unit
) {
    val colorScheme = MaterialTheme.colorScheme

    TopAppBar(
        scrollBehavior = scrollBehavior,
        title = {
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(
                    text = "Classroom Tracker",
                    style = MaterialTheme.typography.titleLarge,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    color = colorScheme.onSurface
                )
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(6.dp))
                        .background(colorScheme.primaryContainer)
                        .padding(horizontal = 7.dp, vertical = 1.dp)
                ) {
                    Text(
                        text = com.phucta.classroom.data.model.ClassroomDateUtils.formatDayAndDate(currentDayEpoch),
                        style = MaterialTheme.typography.labelSmall,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        color = colorScheme.onPrimaryContainer
                    )
                }
            }
        },
        colors = TopAppBarDefaults.topAppBarColors(
            containerColor = colorScheme.surfaceContainerLowest,
            scrolledContainerColor = colorScheme.surfaceContainer
        ),
        navigationIcon = {
            IconButton(onClick = onOpenDrawer) {
                BadgedBox(
                    badge = {
                        if (isAnyCourseFiltered) {
                            Badge(
                                containerColor = colorScheme.primary,
                                modifier = Modifier.size(6.dp)
                            )
                        }
                    }
                ) {
                    Icon(
                        Icons.Default.FilterList,
                        contentDescription = "Lọc môn học",
                        tint = if (isAnyCourseFiltered) colorScheme.primary else colorScheme.onSurface
                    )
                }
            }
        },
        actions = {
            SyncActionButton(
                isSyncing = isSyncing,
                onSyncClick = onSyncClick
            )
            IconButton(onClick = onOpenSettings) {
                if (!userAvatar.isNullOrBlank()) {
                    AsyncImage(
                        model = userAvatar,
                        contentDescription = "Cài đặt",
                        modifier = Modifier
                            .size(28.dp)
                            .clip(CircleShape)
                            .border(1.dp, colorScheme.outlineVariant, CircleShape)
                    )
                } else {
                    Icon(Icons.Default.Settings, contentDescription = "Cài đặt", tint = colorScheme.onSurface)
                }
            }
        }
    )
}

@Composable
private fun NavDestinationBadge(
    count: Int,
    isUrgent: Boolean
) {
    if (count <= 0) return
    val colorScheme = MaterialTheme.colorScheme
    Badge(
        containerColor = if (isUrgent) colorScheme.error else colorScheme.tertiaryContainer,
        contentColor = if (isUrgent) colorScheme.onError else colorScheme.onTertiaryContainer
    ) {
        Text(
            text = if (count > 99) "99+" else "$count",
            style = MaterialTheme.typography.labelSmall
        )
    }
}

@Composable
private fun MainBottomNavigationBar(
    selectedTabIndex: Int,
    tomorrowIncompleteCount: Int,
    upcomingIncompleteCount: Int,
    incompleteNotesCount: Int,
    onTabSelected: (Int) -> Unit
) {
    val view = LocalView.current
    val colorScheme = MaterialTheme.colorScheme
    val handleTabClick = { index: Int ->
        if (selectedTabIndex != index) {
            view.performHapticFeedback(android.view.HapticFeedbackConstants.CLOCK_TICK)
            onTabSelected(index)
        }
    }

    val standardNavColors = NavigationBarItemDefaults.colors(
        selectedIconColor = colorScheme.onPrimaryContainer,
        selectedTextColor = colorScheme.primary,
        indicatorColor = colorScheme.primaryContainer,
        unselectedIconColor = colorScheme.onSurfaceVariant,
        unselectedTextColor = colorScheme.onSurfaceVariant
    )
    NavigationBar(
        containerColor = colorScheme.surfaceContainerLowest,
        tonalElevation = 0.dp,
        modifier = Modifier.drawBehind {
            drawLine(
                color = colorScheme.outlineVariant,
                start = Offset(0f, 0f),
                end = Offset(size.width, 0f),
                strokeWidth = 1.dp.toPx()
            )
        }
    ) {
        NavigationBarItem(
            selected = selectedTabIndex == 0,
            onClick = { handleTabClick(0) },
            icon = {
                BadgedBox(badge = { NavDestinationBadge(tomorrowIncompleteCount, isUrgent = true) }) {
                    Icon(Icons.Default.CalendarToday, contentDescription = "Báo bài")
                }
            },
            label = {
                Text(
                    text = "Báo bài",
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = if (selectedTabIndex == 0) FontWeight.Bold else FontWeight.Medium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            },
            colors = standardNavColors
        )
        NavigationBarItem(
            selected = selectedTabIndex == 1,
            onClick = { handleTabClick(1) },
            icon = {
                BadgedBox(badge = { NavDestinationBadge(upcomingIncompleteCount, isUrgent = true) }) {
                    Icon(Icons.Default.Upcoming, contentDescription = "Sắp tới")
                }
            },
            label = {
                Text(
                    text = "Sắp tới",
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = if (selectedTabIndex == 1) FontWeight.Bold else FontWeight.Medium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            },
            colors = standardNavColors
        )
        NavigationBarItem(
            selected = selectedTabIndex == 2,
            onClick = { handleTabClick(2) },
            icon = {
                Icon(Icons.Default.CheckCircle, contentDescription = "Đã xong")
            },
            label = {
                Text(
                    text = "Đã xong",
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = if (selectedTabIndex == 2) FontWeight.Bold else FontWeight.Medium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            },
            colors = standardNavColors
        )
        NavigationBarItem(
            selected = selectedTabIndex == 3,
            onClick = { handleTabClick(3) },
            icon = {
                BadgedBox(badge = { NavDestinationBadge(incompleteNotesCount, isUrgent = false) }) {
                    Icon(Icons.AutoMirrored.Filled.StickyNote2, contentDescription = "Ghi chú")
                }
            },
            label = {
                Text(
                    text = "Ghi chú",
                    style = MaterialTheme.typography.labelMedium,
                    fontWeight = if (selectedTabIndex == 3) FontWeight.Bold else FontWeight.Medium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            },
            colors = standardNavColors
        )
    }
}

@Composable
private fun MainNavigationRail(
    selectedTabIndex: Int,
    tomorrowIncompleteCount: Int,
    upcomingIncompleteCount: Int,
    incompleteNotesCount: Int,
    onTabSelected: (Int) -> Unit
) {
    val view = LocalView.current
    val colorScheme = MaterialTheme.colorScheme
    val handleTabClick = { index: Int ->
        if (selectedTabIndex != index) {
            view.performHapticFeedback(android.view.HapticFeedbackConstants.CLOCK_TICK)
            onTabSelected(index)
        }
    }

    val railColors = NavigationRailItemDefaults.colors(
        selectedIconColor = colorScheme.onPrimaryContainer,
        selectedTextColor = colorScheme.primary,
        indicatorColor = colorScheme.primaryContainer,
        unselectedIconColor = colorScheme.onSurfaceVariant,
        unselectedTextColor = colorScheme.onSurfaceVariant
    )

    NavigationRail(
        containerColor = colorScheme.surfaceContainerLowest
    ) {
        Spacer(modifier = Modifier.height(12.dp))
        NavigationRailItem(
            selected = selectedTabIndex == 0,
            onClick = { handleTabClick(0) },
            icon = {
                BadgedBox(badge = { NavDestinationBadge(tomorrowIncompleteCount, isUrgent = true) }) {
                    Icon(Icons.Default.CalendarToday, contentDescription = "Báo bài")
                }
            },
            label = { Text("Báo bài", maxLines = 1) },
            colors = railColors
        )
        NavigationRailItem(
            selected = selectedTabIndex == 1,
            onClick = { handleTabClick(1) },
            icon = {
                BadgedBox(badge = { NavDestinationBadge(upcomingIncompleteCount, isUrgent = true) }) {
                    Icon(Icons.Default.Upcoming, contentDescription = "Sắp tới")
                }
            },
            label = { Text("Sắp tới", maxLines = 1) },
            colors = railColors
        )
        NavigationRailItem(
            selected = selectedTabIndex == 2,
            onClick = { handleTabClick(2) },
            icon = { Icon(Icons.Default.CheckCircle, contentDescription = "Đã xong") },
            label = { Text("Đã xong", maxLines = 1) },
            colors = railColors
        )
        NavigationRailItem(
            selected = selectedTabIndex == 3,
            onClick = { handleTabClick(3) },
            icon = {
                BadgedBox(badge = { NavDestinationBadge(incompleteNotesCount, isUrgent = false) }) {
                    Icon(Icons.AutoMirrored.Filled.StickyNote2, contentDescription = "Ghi chú")
                }
            },
            label = { Text("Ghi chú", maxLines = 1) },
            colors = railColors
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun WelcomeLoginScreen(
    snackbarHostState: SnackbarHostState,
    onSignIn: () -> Unit,
    onDemoMode: () -> Unit,
    onOpenSettings: () -> Unit
) {
    val colorScheme = MaterialTheme.colorScheme

    Scaffold(
        containerColor = colorScheme.surface,
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(
                title = { },
                actions = {
                    IconButton(onClick = onOpenSettings) {
                        Icon(
                            Icons.Default.Settings,
                            contentDescription = "Cài đặt",
                            tint = colorScheme.onSurfaceVariant
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.Transparent)
            )
        }
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentAlignment = Alignment.Center
        ) {
            Column(
                modifier = Modifier
                    .widthIn(max = 420.dp)
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 28.dp, vertical = 16.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                EmberFlameCanvas(size = 80.dp)

                Spacer(modifier = Modifier.height(20.dp))

                Text(
                    text = "Classroom Tracker",
                    style = MaterialTheme.typography.headlineMedium,
                    color = colorScheme.onSurface
                )

                Text(
                    text = "Theo dõi bài tập Google Classroom",
                    style = MaterialTheme.typography.bodyLarge,
                    color = colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center,
                    modifier = Modifier.padding(top = 6.dp, bottom = 32.dp)
                )

                androidx.compose.material3.Button(
                    onClick = onSignIn,
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(min = 52.dp),
                    shape = RoundedCornerShape(14.dp),
                    colors = androidx.compose.material3.ButtonDefaults.buttonColors(
                        containerColor = colorScheme.primary,
                        contentColor = colorScheme.onPrimary
                    )
                ) {
                    Text(
                        text = "Đăng nhập bằng Google",
                        style = MaterialTheme.typography.titleSmall.copy(fontSize = 16.sp, fontWeight = FontWeight.Bold)
                    )
                }

                Spacer(modifier = Modifier.height(12.dp))

                OutlinedButton(
                    onClick = onDemoMode,
                    modifier = Modifier
                        .fillMaxWidth()
                        .heightIn(min = 48.dp),
                    shape = RoundedCornerShape(14.dp),
                    border = androidx.compose.foundation.BorderStroke(1.dp, colorScheme.outlineVariant)
                ) {
                    Text(
                        text = "Xem thử dữ liệu mẫu",
                        style = MaterialTheme.typography.labelLarge,
                        color = colorScheme.onSurfaceVariant
                    )
                }
            }
        }
    }
}

@Composable
private fun SyncActionButton(
    isSyncing: Boolean,
    onSyncClick: () -> Unit
) {
    val syncTint = MaterialTheme.colorScheme.primary
    if (isSyncing) {
        val infiniteTransition = rememberInfiniteTransition(label = "syncSpin")
        val spinningRotation = infiniteTransition.animateFloat(
            initialValue = 0f,
            targetValue = 360f,
            animationSpec = infiniteRepeatable(
                animation = tween(900, easing = LinearEasing),
                repeatMode = RepeatMode.Restart
            ),
            label = "syncRotation"
        )

        IconButton(
            onClick = onSyncClick,
            enabled = false
        ) {
            Icon(
                imageVector = Icons.Default.Refresh,
                contentDescription = "Đang đồng bộ",
                tint = syncTint,
                modifier = Modifier.graphicsLayer {
                    rotationZ = spinningRotation.value
                }
            )
        }
    } else {
        IconButton(
            onClick = onSyncClick,
            enabled = true
        ) {
            Icon(
                imageVector = Icons.Default.Refresh,
                contentDescription = "Đồng bộ bài tập",
                tint = syncTint
            )
        }
    }
}
