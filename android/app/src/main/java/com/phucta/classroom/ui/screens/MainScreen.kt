package com.phucta.classroom.ui.screens

import android.content.Context
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
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
import com.phucta.classroom.ClassroomApplication
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.domain.BaoBaiBucketingUtils
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

    var selectedTabIndex by remember { mutableIntStateOf(0) }
    var showSettingsDialog by remember { mutableStateOf(false) }
    var selectedCoursework by remember { mutableStateOf<Coursework?>(null) }
    var isDemoMode by remember { mutableStateOf(false) }
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    // Reactive State Flows
    val courses by repository.coursesFlow.collectAsState(initial = emptyList())
    val allCoursework by repository.courseworkFlow.collectAsState(initial = emptyList())
    val isSyncing by repository.isSyncing.collectAsState()
    val syncErrorMessage by repository.syncErrorMessage.collectAsState()
    val authErrorMessage by oauthManager.authErrorMessage.collectAsState()
    val isAuthenticated by oauthManager.isAuthenticated.collectAsState()
    val userEmail by preferences.userEmailFlow.collectAsState(initial = null)
    val userName by preferences.userNameFlow.collectAsState(initial = null)
    val customClientId by preferences.customClientIdFlow.collectAsState(initial = null)
    val customClientSecret by preferences.customClientSecretFlow.collectAsState(initial = null)

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

    val tomorrowItems = remember(allCoursework, courses) {
        BaoBaiBucketingUtils.getTomorrowCoursework(allCoursework, courses)
    }

    val completedItems = remember(allCoursework, courses) {
        BaoBaiBucketingUtils.filterByActiveCourses(allCoursework, courses).filter { it.isCompleted }
    }

    // Infinite rotation animation when syncing
    val infiniteTransition = rememberInfiniteTransition(label = "syncRotation")
    val syncRotation by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 360f,
        animationSpec = infiniteRepeatable(
            animation = tween(1000, easing = LinearEasing)
        ),
        label = "syncAngle"
    )

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

                LazyColumn(modifier = Modifier.fillMaxSize()) {
                    items(courses, key = { it.id }) { course ->
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable {
                                    scope.launch {
                                        repository.updateCourseWidgetSelection(
                                            course.id,
                                            !course.isSelectedForWidget
                                        )
                                    }
                                }
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
                                onCheckedChange = { checked ->
                                    scope.launch {
                                        repository.updateCourseWidgetSelection(course.id, checked)
                                    }
                                },
                                colors = CheckboxDefaults.colors(checkedColor = ChunkyColor.SkyBottom)
                            )
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
                            fontSize = 18.sp,
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
                        IconButton(
                            onClick = { scope.launch { repository.syncAll() } },
                            enabled = !isSyncing
                        ) {
                            Icon(
                                imageVector = Icons.Default.Refresh,
                                contentDescription = "Sync",
                                tint = ChunkyColor.SkyBottom,
                                modifier = Modifier.graphicsLayer {
                                    rotationZ = if (isSyncing) syncRotation else 0f
                                }
                            )
                        }
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
                        icon = { Icon(Icons.Default.CalendarToday, contentDescription = null) },
                        label = { Text("Báo bài Ngày mai", fontWeight = FontWeight.SemiBold, fontSize = 11.sp) },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = ChunkyColor.SkyBottom,
                            selectedTextColor = ChunkyColor.SkyBottom,
                            indicatorColor = ChunkyColor.SkyBottom.copy(alpha = 0.12f)
                        )
                    )
                    NavigationBarItem(
                        selected = selectedTabIndex == 1,
                        onClick = { selectedTabIndex = 1 },
                        icon = { Icon(Icons.Default.Upcoming, contentDescription = null) },
                        label = { Text("Tất cả sắp tới", fontWeight = FontWeight.SemiBold, fontSize = 11.sp) },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = ChunkyColor.SkyBottom,
                            selectedTextColor = ChunkyColor.SkyBottom,
                            indicatorColor = ChunkyColor.SkyBottom.copy(alpha = 0.12f)
                        )
                    )
                    NavigationBarItem(
                        selected = selectedTabIndex == 2,
                        onClick = { selectedTabIndex = 2 },
                        icon = { Icon(Icons.Default.CheckCircle, contentDescription = null) },
                        label = { Text("Đã hoàn thành", fontWeight = FontWeight.SemiBold, fontSize = 11.sp) },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = ChunkyColor.SuccessGreen,
                            selectedTextColor = ChunkyColor.SuccessGreen,
                            indicatorColor = ChunkyColor.SuccessGreen.copy(alpha = 0.12f)
                        )
                    )
                }
            }
        ) { paddingValues ->
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(paddingValues)
            ) {
                when (selectedTabIndex) {
                    0 -> TomorrowHomeworkScreen(
                        tomorrowItems = tomorrowItems,
                        onToggleCompletion = { id, completed ->
                            scope.launch { repository.toggleTaskCompletion(id, completed) }
                        },
                        onSelectAssignment = { coursework ->
                            selectedCoursework = coursework
                        }
                    )
                    1 -> AllUpcomingScreen(
                        allCoursework = allCoursework,
                        courses = courses,
                        onToggleCompletion = { id, completed ->
                            scope.launch { repository.toggleTaskCompletion(id, completed) }
                        },
                        onSelectAssignment = { coursework ->
                            selectedCoursework = coursework
                        }
                    )
                    2 -> CompletedHomeworkScreen(
                        completedItems = completedItems,
                        onToggleCompletion = { id, completed ->
                            scope.launch { repository.toggleTaskCompletion(id, completed) }
                        },
                        onSelectAssignment = { coursework ->
                            selectedCoursework = coursework
                        }
                    )
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

    // Detail Bottom Sheet
    val activeSelectedCoursework = selectedCoursework?.let { current ->
        allCoursework.find { it.id == current.id } ?: current
    }

    if (activeSelectedCoursework != null) {
        HomeworkDetailBottomSheet(
            coursework = activeSelectedCoursework,
            sheetState = sheetState,
            onDismiss = { selectedCoursework = null },
            onToggleCompletion = { id, completed ->
                scope.launch {
                    repository.toggleTaskCompletion(id, completed)
                    selectedCoursework = activeSelectedCoursework.copy(
                        isManuallyCompleted = completed,
                        status = if (completed) com.phucta.classroom.data.model.SubmissionStatus.TURNED_IN else com.phucta.classroom.data.model.SubmissionStatus.PENDING
                    )
                }
            }
        )
    }

    // Settings Dialog
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
                            contentDescription = "Cài đặt nâng cao",
                            tint = ChunkyColor.TextMuted
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.Transparent)
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            // App Branding Icon
            Box(
                modifier = Modifier
                    .size(80.dp)
                    .background(ChunkyColor.SkyGradient, RoundedCornerShape(22.dp)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.CalendarToday,
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier.size(40.dp)
                )
            }

            Spacer(modifier = Modifier.height(18.dp))

            Text(
                text = "Classroom Tracker",
                fontWeight = FontWeight.Bold,
                fontSize = 24.sp,
                color = ChunkyColor.TextPrimary
            )

            Text(
                text = "Theo dõi bài tập Google Classroom thông minh cho học sinh, sinh viên",
                fontSize = 13.5.sp,
                color = ChunkyColor.TextMuted,
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(top = 6.dp, bottom = 24.dp)
            )

            // Features Card
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(ChunkyColor.SurfaceWhite, RoundedCornerShape(16.dp))
                    .padding(18.dp)
            ) {
                WelcomeFeatureRow(
                    title = "Báo bài Ngày mai",
                    desc = "Tự động phân loại bài tập cần nộp vào ngày mai, không lo sót hạn."
                )
                Spacer(modifier = Modifier.height(12.dp))
                WelcomeFeatureRow(
                    title = "Widget Màn hình chính",
                    desc = "Theo dõi bài tập nhanh chóng ngay trên Widget màn hình chính Android."
                )
                Spacer(modifier = Modifier.height(12.dp))
                WelcomeFeatureRow(
                    title = "Tự động đồng bộ",
                    desc = "Kết nối trực tiếp tài khoản Google Classroom, an toàn và bảo mật."
                )
            }

            Spacer(modifier = Modifier.height(28.dp))

            // Primary Google Sign-in Button
            androidx.compose.material3.Button(
                onClick = onSignIn,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(50.dp),
                shape = RoundedCornerShape(12.dp),
                colors = androidx.compose.material3.ButtonDefaults.buttonColors(
                    containerColor = ChunkyColor.SkyBottom
                )
            ) {
                Text(
                    text = "Đăng nhập bằng Google",
                    fontWeight = FontWeight.Bold,
                    fontSize = 15.sp,
                    color = Color.White
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Demo Mode
            androidx.compose.material3.TextButton(onClick = onDemoMode) {
                Text(
                    text = "Xem thử giao diện với dữ liệu mẫu",
                    fontSize = 13.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = ChunkyColor.TextMuted
                )
            }
        }
    }
}

@Composable
private fun WelcomeFeatureRow(title: String, desc: String) {
    Column {
        Text(
            text = title,
            fontWeight = FontWeight.Bold,
            fontSize = 13.5.sp,
            color = ChunkyColor.TextPrimary
        )
        Text(
            text = desc,
            fontSize = 12.sp,
            color = ChunkyColor.TextMuted
        )
    }
}
