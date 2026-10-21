package com.phucta.classroom.ui.screens

import android.content.Context
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.ui.draw.clip
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.Refresh
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
import androidx.compose.material3.ModalDrawerSheet
import androidx.compose.material3.ModalNavigationDrawer
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberDrawerState
import androidx.compose.material3.rememberModalBottomSheetState
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
import androidx.compose.ui.semantics.Role
import com.phucta.classroom.ClassroomApplication
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.data.model.PersonalNote
import com.phucta.classroom.domain.BaoBaiBucketingUtils
import com.phucta.classroom.ui.components.EmberEmotion
import com.phucta.classroom.ui.components.EmberFlameCanvas
import com.phucta.classroom.ui.components.HomeworkDetailBottomSheet
import com.phucta.classroom.ui.components.SubjectBadgePill
import com.phucta.classroom.ui.theme.ChunkyColor
import kotlinx.coroutines.launch

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
    var showSettingsDialog by rememberSaveable { mutableStateOf(false) }
    var selectedCourseworkId by rememberSaveable { mutableStateOf<String?>(null) }
    var isDemoMode by rememberSaveable { mutableStateOf(false) }
    var currentDayEpoch by remember { mutableLongStateOf(com.phucta.classroom.data.model.ClassroomDateUtils.startOfToday) }

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
    val customClientId by preferences.customClientIdFlow.collectAsStateWithLifecycle(initialValue = null)
    val customClientSecret by preferences.customClientSecretFlow.collectAsStateWithLifecycle(initialValue = null)

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

    val tomorrowItems = remember(allCoursework, courses, personalNotes, currentDayEpoch) {
        BaoBaiBucketingUtils.getTomorrowCoursework(
            items = allCoursework,
            courses = courses,
            personalNotes = personalNotes
        )
    }

    val tomorrowIncompleteCount = remember(tomorrowItems) { tomorrowItems.count { !it.isCompleted } }
    val upcomingIncompleteCount = remember(allCoursework, courses, currentDayEpoch) {
        BaoBaiBucketingUtils.filterByActiveCourses(allCoursework, courses).count { !it.isCompleted }
    }
    val incompleteNotesCount = remember(personalNotes, currentDayEpoch) {
        personalNotes.count { it.courseworkId == null && !it.isCompleted }
    }
    val courseworkIdsWithNotes = remember(personalNotes) {
        personalNotes.filter { it.courseworkId != null && it.content.isNotBlank() }
            .mapNotNull { it.courseworkId }
            .toSet()
    }

    val pullToRefreshState = rememberPullToRefreshState()

    val completedItems = remember(allCoursework, courses, currentDayEpoch) {
        val filtered = BaoBaiBucketingUtils.filterByActiveCourses(allCoursework, courses).filter { it.isCompleted }
        filtered.sortedWith { first, second ->
            when {
                first.dueEpochMillis != null && second.dueEpochMillis != null -> {
                    second.dueEpochMillis.compareTo(first.dueEpochMillis)
                }
                first.dueEpochMillis != null -> -1
                second.dueEpochMillis != null -> 1
                else -> first.title.compareTo(second.title, ignoreCase = true)
            }
        }
    }

    val onToggleTomorrowCompletion = remember(scope, repository) {
        { id: String, completed: Boolean ->
            if (id.startsWith("note_")) {
                val noteId = id.removePrefix("note_")
                scope.launch { repository.togglePersonalNoteCompletion(noteId, completed) }
            } else {
                scope.launch { repository.toggleTaskCompletion(id, completed) }
            }
            Unit
        }
    }

    val onToggleTaskCompletion = remember(scope, repository) {
        { id: String, completed: Boolean ->
            if (id.startsWith("note_")) {
                val noteId = id.removePrefix("note_")
                scope.launch { repository.togglePersonalNoteCompletion(noteId, completed) }
            } else {
                scope.launch { repository.toggleTaskCompletion(id, completed) }
            }
            Unit
        }
    }

    val onTogglePersonalNoteCompletion = remember(scope, repository) {
        { noteId: String, completed: Boolean ->
            scope.launch { repository.togglePersonalNoteCompletion(noteId, completed) }
            Unit
        }
    }

    val onSavePersonalNote = remember(scope, repository) {
        { note: PersonalNote ->
            scope.launch { repository.savePersonalNote(note) }
            Unit
        }
    }

    val onDeletePersonalNote = remember(scope, repository) {
        { noteId: String ->
            scope.launch { repository.deletePersonalNote(noteId) }
            Unit
        }
    }

    if (isAuthenticated || isDemoMode) {
        ModalNavigationDrawer(
        drawerState = drawerState,
        drawerContent = {
            ModalDrawerSheet(
                drawerContainerColor = ChunkyColor.SurfaceWhite,
                modifier = Modifier.width(310.dp)
            ) {
                Column(modifier = Modifier.padding(20.dp)) {
                    Text(
                        text = "Lọc môn học",
                        fontWeight = FontWeight.Bold,
                        fontSize = 18.sp,
                        color = ChunkyColor.TextPrimary
                    )
                    Text(
                        text = "Chọn các môn tham gia Báo bài & hiển thị trên Widget",
                        fontSize = 12.sp,
                        color = ChunkyColor.TextMuted,
                        modifier = Modifier.padding(top = 2.dp, bottom = 12.dp)
                    )
                    HorizontalDivider(color = ChunkyColor.Hairline)
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
                            fontSize = 13.sp,
                            color = ChunkyColor.TextMuted,
                            textAlign = TextAlign.Center
                        )
                    }
                } else {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(bottom = 24.dp)
                    ) {
                        items(courses, key = { it.id }) { course ->
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable(
                                        role = Role.Checkbox,
                                        onClick = {
                                            scope.launch {
                                                repository.updateCourseWidgetSelection(
                                                    course.id,
                                                    !course.isSelectedForWidget
                                                )
                                            }
                                        }
                                    )
                                    .padding(horizontal = 20.dp, vertical = 10.dp)
                            ) {
                                SubjectBadgePill(courseName = course.name)
                                Spacer(modifier = Modifier.width(10.dp))
                                Text(
                                    text = course.name,
                                    fontWeight = FontWeight.SemiBold,
                                    fontSize = 13.5.sp,
                                    color = ChunkyColor.TextPrimary,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis,
                                    modifier = Modifier.weight(1f)
                                )
                                Checkbox(
                                    checked = course.isSelectedForWidget,
                                    onCheckedChange = null,
                                    colors = CheckboxDefaults.colors(checkedColor = ChunkyColor.SkyBottom)
                                )
                            }
                        }
                    }
                }
            }
        }
    ) {
        Scaffold(
            snackbarHost = { SnackbarHost(snackbarHostState) },
            topBar = {
                TopAppBar(
                    title = {
                        Text(
                            text = "Classroom Tracker",
                            fontWeight = FontWeight.Bold,
                            fontSize = 19.sp,
                            color = ChunkyColor.TextPrimary
                        )
                    },
                    colors = TopAppBarDefaults.topAppBarColors(containerColor = ChunkyColor.SurfaceWhite),
                    navigationIcon = {
                        IconButton(onClick = { scope.launch { drawerState.open() } }) {
                            Icon(Icons.Default.FilterList, contentDescription = "Filter Courses", tint = ChunkyColor.TextPrimary)
                        }
                    },
                    actions = {
                        SyncActionButton(
                            isSyncing = isSyncing,
                            onSyncClick = {
                                scope.launch {
                                    val result = repository.syncAll()
                                    if (result.isSuccess) {
                                        snackbarHostState.showSnackbar("Đã cập nhật bài tập mới nhất!")
                                    }
                                }
                            }
                        )
                        IconButton(onClick = { showSettingsDialog = true }) {
                            Icon(Icons.Default.Settings, contentDescription = "Settings", tint = ChunkyColor.TextPrimary)
                        }
                    }
                )
            },
            bottomBar = {
                NavigationBar(
                    containerColor = ChunkyColor.SurfaceWhite,
                    tonalElevation = 4.dp
                ) {
                    NavigationBarItem(
                        selected = selectedTabIndex == 0,
                        onClick = { selectedTabIndex = 0 },
                        icon = {
                            BadgedBox(
                                badge = {
                                    if (tomorrowIncompleteCount > 0) {
                                        Badge(
                                            containerColor = if (tomorrowIncompleteCount >= 3) ChunkyColor.HeaderOverdue else ChunkyColor.HeaderToday,
                                            contentColor = Color.White
                                        ) {
                                            Text("$tomorrowIncompleteCount", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                                        }
                                    }
                                }
                            ) {
                                Icon(Icons.Default.CalendarToday, contentDescription = null)
                            }
                        },
                        label = {
                            Text(
                                text = "Báo bài",
                                fontWeight = FontWeight.Bold,
                                fontSize = 12.5.sp,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = ChunkyColor.SkyBottom,
                            selectedTextColor = ChunkyColor.SkyBottom,
                            indicatorColor = ChunkyColor.SkyBottom.copy(alpha = 0.14f),
                            unselectedIconColor = Color(0xFF64748B),
                            unselectedTextColor = Color(0xFF64748B)
                        )
                    )
                    NavigationBarItem(
                        selected = selectedTabIndex == 1,
                        onClick = { selectedTabIndex = 1 },
                        icon = {
                            BadgedBox(
                                badge = {
                                    if (upcomingIncompleteCount > 0) {
                                        Badge(
                                            containerColor = Color(0xFF2563EB),
                                            contentColor = Color.White
                                        ) {
                                            Text("$upcomingIncompleteCount", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                                        }
                                    }
                                }
                            ) {
                                Icon(Icons.Default.Upcoming, contentDescription = null)
                            }
                        },
                        label = {
                            Text(
                                text = "Sắp tới",
                                fontWeight = FontWeight.Bold,
                                fontSize = 12.5.sp,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = Color(0xFF2563EB),
                            selectedTextColor = Color(0xFF2563EB),
                            indicatorColor = Color(0xFF2563EB).copy(alpha = 0.12f),
                            unselectedIconColor = Color(0xFF64748B),
                            unselectedTextColor = Color(0xFF64748B)
                        )
                    )
                    NavigationBarItem(
                        selected = selectedTabIndex == 2,
                        onClick = { selectedTabIndex = 2 },
                        icon = { Icon(Icons.Default.CheckCircle, contentDescription = null) },
                        label = {
                            Text(
                                text = "Đã xong",
                                fontWeight = FontWeight.Bold,
                                fontSize = 12.5.sp,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = ChunkyColor.HeaderCompleted,
                            selectedTextColor = ChunkyColor.HeaderCompleted,
                            indicatorColor = ChunkyColor.HeaderCompleted.copy(alpha = 0.14f),
                            unselectedIconColor = Color(0xFF64748B),
                            unselectedTextColor = Color(0xFF64748B)
                        )
                    )
                    NavigationBarItem(
                        selected = selectedTabIndex == 3,
                        onClick = { selectedTabIndex = 3 },
                        icon = {
                            BadgedBox(
                                badge = {
                                    if (incompleteNotesCount > 0) {
                                        Badge(
                                            containerColor = Color(0xFFD97706),
                                            contentColor = Color.White
                                        ) {
                                            Text("$incompleteNotesCount", fontSize = 11.sp, fontWeight = FontWeight.Bold)
                                        }
                                    }
                                }
                            ) {
                                Icon(Icons.AutoMirrored.Filled.StickyNote2, contentDescription = null)
                            }
                        },
                        label = {
                            Text(
                                text = "Ghi chú",
                                fontWeight = FontWeight.Bold,
                                fontSize = 12.5.sp,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = Color(0xFFD97706),
                            selectedTextColor = Color(0xFFD97706),
                            indicatorColor = Color(0xFFD97706).copy(alpha = 0.14f),
                            unselectedIconColor = Color(0xFF64748B),
                            unselectedTextColor = Color(0xFF64748B)
                        )
                    )
                }
            }
        ) { paddingValues ->
            PullToRefreshBox(
                isRefreshing = isSyncing,
                onRefresh = {
                    scope.launch {
                        val result = repository.syncAll()
                        if (result.isSuccess) {
                            snackbarHostState.showSnackbar("Đã cập nhật bài tập mới nhất!")
                        }
                    }
                },
                state = pullToRefreshState,
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues),
                indicator = {
                    PullToRefreshDefaults.Indicator(
                        state = pullToRefreshState,
                        isRefreshing = isSyncing,
                        modifier = Modifier.align(Alignment.TopCenter),
                        containerColor = ChunkyColor.SurfaceWhite,
                        color = ChunkyColor.SkyBottom
                    )
                }
            ) {
                AnimatedContent(
                    targetState = selectedTabIndex,
                    transitionSpec = {
                        if (targetState > initialState) {
                            (slideInHorizontally(animationSpec = spring(dampingRatio = 0.82f, stiffness = 420f)) { width -> (width * 0.15f).toInt() } + fadeIn(animationSpec = tween(200)))
                                .togetherWith(
                                    slideOutHorizontally(animationSpec = spring(dampingRatio = 0.82f, stiffness = 420f)) { width -> -(width * 0.15f).toInt() } + fadeOut(animationSpec = tween(160))
                                )
                        } else {
                            (slideInHorizontally(animationSpec = spring(dampingRatio = 0.82f, stiffness = 420f)) { width -> -(width * 0.15f).toInt() } + fadeIn(animationSpec = tween(200)))
                                .togetherWith(
                                    slideOutHorizontally(animationSpec = spring(dampingRatio = 0.82f, stiffness = 420f)) { width -> (width * 0.15f).toInt() } + fadeOut(animationSpec = tween(160))
                                )
                        }
                    },
                    label = "tabTransition",
                    modifier = Modifier.fillMaxSize()
                ) { tabIndex ->
                    when (tabIndex) {
                        0 -> TomorrowHomeworkScreen(
                            tomorrowItems = tomorrowItems,
                            courseworkIdsWithNotes = courseworkIdsWithNotes,
                            currentDayEpoch = currentDayEpoch,
                            onToggleCompletion = onToggleTomorrowCompletion,
                            onSelectAssignment = { coursework ->
                                if (coursework.id.startsWith("note_")) {
                                    selectedTabIndex = 3
                                } else {
                                    selectedCourseworkId = coursework.id
                                }
                            }
                        )
                        1 -> AllUpcomingScreen(
                            allCoursework = allCoursework,
                            courses = courses,
                            courseworkIdsWithNotes = courseworkIdsWithNotes,
                            currentDayEpoch = currentDayEpoch,
                            onToggleCompletion = onToggleTaskCompletion,
                            onSelectAssignment = { coursework ->
                                selectedCourseworkId = coursework.id
                            }
                        )
                        2 -> CompletedHomeworkScreen(
                            completedItems = completedItems,
                            courseworkIdsWithNotes = courseworkIdsWithNotes,
                            onToggleCompletion = onToggleTaskCompletion,
                            onSelectAssignment = { coursework ->
                                selectedCourseworkId = coursework.id
                            }
                        )
                        3 -> PersonalNotesScreen(
                            notes = personalNotes,
                            courses = courses,
                            onToggleCompletion = onTogglePersonalNoteCompletion,
                            onSaveNote = onSavePersonalNote,
                            onDeleteNote = onDeletePersonalNote
                        )
                    }
                }
            }
        }
        }
    } else {
        WelcomeLoginScreen(
            onSignIn = { scope.launch { oauthManager.startSignIn(context) } },
            onDemoMode = {
                scope.launch {
                    repository.populateMockDataManually()
                    isDemoMode = true
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
            isSyncing = isSyncing,
            initialClientId = customClientId,
            initialClientSecret = customClientSecret,
            onDismiss = { showSettingsDialog = false },
            onSignIn = {
                scope.launch { oauthManager.startSignIn(context) }
            },
            onSignOut = {
                isDemoMode = false
                scope.launch { repository.clearAllData() }
            },
            onSyncNow = {
                scope.launch { repository.syncAll() }
            },
            onSaveCustomCredentials = { customId, customSecret ->
                scope.launch { preferences.saveCustomCredentials(customId, customSecret) }
            }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun WelcomeLoginScreen(
    onSignIn: () -> Unit,
    onDemoMode: () -> Unit,
    onOpenSettings: () -> Unit
) {
    Scaffold(
        containerColor = ChunkyColor.WindowBackground,
        topBar = {
            TopAppBar(
                title = { },
                actions = {
                    IconButton(onClick = onOpenSettings) {
                        Icon(
                            Icons.Default.Settings,
                            contentDescription = "Cài đặt",
                            tint = ChunkyColor.TextMuted
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = androidx.compose.ui.graphics.Color.Transparent)
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 28.dp, vertical = 16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            FloatingWelcomeEmber()

            Spacer(modifier = Modifier.height(20.dp))

            Text(
                text = "Classroom Tracker",
                fontWeight = FontWeight.Bold,
                fontSize = 24.sp,
                color = ChunkyColor.TextPrimary
            )

            Text(
                text = "Theo dõi bài tập Google Classroom",
                fontSize = 14.sp,
                color = ChunkyColor.TextMuted,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 4.dp, bottom = 32.dp)
            )

            androidx.compose.material3.Button(
                onClick = onSignIn,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(52.dp),
                shape = RoundedCornerShape(12.dp),
                colors = androidx.compose.material3.ButtonDefaults.buttonColors(
                    containerColor = ChunkyColor.SkyBottom
                )
            ) {
                Text(
                    text = "Đăng nhập bằng Google",
                    fontWeight = FontWeight.Bold,
                    fontSize = 15.sp,
                    color = androidx.compose.ui.graphics.Color.White
                )
            }

            Spacer(modifier = Modifier.height(14.dp))

            androidx.compose.material3.TextButton(onClick = onDemoMode) {
                Text(
                    text = "Xem thử dữ liệu mẫu",
                    fontSize = 13.5.sp,
                    fontWeight = FontWeight.Medium,
                    color = ChunkyColor.TextMuted
                )
            }
        }
    }
}

@Composable
private fun FloatingWelcomeEmber() {
    val infiniteTransition = rememberInfiniteTransition(label = "welcomeFloating")
    val floatOffset = infiniteTransition.animateFloat(
        initialValue = -5f,
        targetValue = 5f,
        animationSpec = infiniteRepeatable(
            animation = tween(2800, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "welcomeFloat"
    )

    Box(
        modifier = Modifier
            .graphicsLayer { translationY = floatOffset.value }
            .size(88.dp)
            .clip(RoundedCornerShape(22.dp))
            .background(ChunkyColor.SkyGradient),
        contentAlignment = Alignment.Center
    ) {
        EmberFlameCanvas(
            size = 64.dp,
            emotion = EmberEmotion.NORMAL
        )
    }
}

@Composable
private fun SyncActionButton(
    isSyncing: Boolean,
    onSyncClick: () -> Unit
) {
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
                contentDescription = "Sync",
                tint = ChunkyColor.SkyBottom,
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
                contentDescription = "Sync",
                tint = ChunkyColor.SkyBottom
            )
        }
    }
}
