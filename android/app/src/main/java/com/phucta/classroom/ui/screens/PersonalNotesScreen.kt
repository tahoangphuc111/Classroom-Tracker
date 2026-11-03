package com.phucta.classroom.ui.screens

import android.app.Activity
import android.content.Context
import android.content.ContextWrapper
import androidx.activity.compose.BackHandler
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import android.view.HapticFeedbackConstants
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.material3.ripple
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.window.DialogProperties
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.RadioButton
import androidx.compose.material3.Surface
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.TabRowDefaults
import androidx.compose.material3.TabRowDefaults.tabIndicatorOffset
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.phucta.classroom.data.model.ClassroomDateUtils
import com.phucta.classroom.data.model.Course
import com.phucta.classroom.data.model.PersonalNote
import com.phucta.classroom.data.model.normalizeForVietnameseSearch
import com.phucta.classroom.ui.components.DueDateBadge
import com.phucta.classroom.ui.components.EmberEmotion
import com.phucta.classroom.ui.components.EmberFlameCanvas
import com.phucta.classroom.ui.components.SubjectBadgePill
import com.phucta.classroom.ui.theme.ChunkyColor
import com.phucta.classroom.ui.theme.OutfitFontFamily
import kotlinx.coroutines.delay
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

@Composable
fun PersonalNotesScreen(
    notes: List<PersonalNote>,
    courses: List<Course>,
    onToggleCompletion: (String, Boolean) -> Unit,
    onSaveNote: (PersonalNote) -> Unit,
    onDeleteNote: (String) -> Unit,
    modifier: Modifier = Modifier,
    onToggleChecklistItem: (String, String) -> Unit = { _, _ -> },
    initialNoteToEdit: PersonalNote? = null,
    onClearInitialNoteToEdit: () -> Unit = {}
) {
    var selectedStatusTab by rememberSaveable { mutableIntStateOf(0) }
    var selectedCourseId by rememberSaveable { mutableStateOf<String?>(null) }
    var searchQuery by rememberSaveable { mutableStateOf("") }
    var debouncedQuery by rememberSaveable { mutableStateOf("") }

    LaunchedEffect(searchQuery) {
        if (searchQuery.isBlank()) {
            debouncedQuery = ""
        } else {
            delay(250)
            debouncedQuery = searchQuery
        }
    }

    val normalizedQuery = remember(debouncedQuery) { debouncedQuery.normalizeForVietnameseSearch() }
    val keyboardController = LocalSoftwareKeyboardController.current

    BackHandler(enabled = searchQuery.isNotEmpty() || selectedCourseId != null) {
        if (searchQuery.isNotEmpty()) {
            searchQuery = ""
        } else {
            selectedCourseId = null
        }
    }

    val searchTokens = remember(normalizedQuery) {
        com.phucta.classroom.data.model.tokenizeSearchQuery(normalizedQuery)
    }

    var showCreateDialog by rememberSaveable { mutableStateOf(false) }
    var draftForDialog by remember { mutableStateOf<PersonalNote?>(null) }
    var noteToEdit by remember { mutableStateOf<PersonalNote?>(null) }

    LaunchedEffect(initialNoteToEdit) {
        if (initialNoteToEdit != null) {
            selectedStatusTab = if (initialNoteToEdit.isCompleted) 2 else 1
            selectedCourseId = null
            noteToEdit = initialNoteToEdit
            onClearInitialNoteToEdit()
        }
    }

    val standaloneNotes = remember(notes) {
        notes.filter { it.courseworkId == null }
    }

    val filteredNotes = remember(standaloneNotes, selectedStatusTab, selectedCourseId, searchTokens, normalizedQuery) {
        val matches = standaloneNotes.filter { note ->
            val matchesStatus = when (selectedStatusTab) {
                1 -> !note.isCompleted
                2 -> note.isCompleted
                else -> true
            }
            val matchesCourse = selectedCourseId == null || note.courseId == selectedCourseId
            val matchesSearch = if (searchTokens.isEmpty()) true else {
                searchTokens.all { token -> note.searchIndex.contains(token) }
            }
            matchesStatus && matchesCourse && matchesSearch
        }

        val defaultComparator = Comparator<PersonalNote> { first, second ->
            if (first.isCompleted != second.isCompleted) {
                if (first.isCompleted) 1 else -1
            } else {
                when {
                    first.dueEpochMillis != null && second.dueEpochMillis != null -> {
                        first.dueEpochMillis.compareTo(second.dueEpochMillis)
                    }
                    first.dueEpochMillis != null -> -1
                    second.dueEpochMillis != null -> 1
                    else -> second.updatedAt.compareTo(first.updatedAt)
                }
            }
        }

        if (searchTokens.isNotEmpty()) {
            val scores = IntArray(matches.size) { index ->
                val note = matches[index]
                com.phucta.classroom.data.model.calculateSearchRelevance(
                    queryTokens = searchTokens,
                    rawNormalizedQuery = normalizedQuery,
                    title = note.title,
                    courseName = note.courseName,
                    content = note.content
                )
            }
            val indices = Array(matches.size) { it }
            indices.sortWith { a, b ->
                val scoreDiff = scores[b].compareTo(scores[a])
                if (scoreDiff != 0) scoreDiff else defaultComparator.compare(matches[a], matches[b])
            }
            indices.map { matches[it] }
        } else {
            matches.sortedWith(defaultComparator)
        }
    }

    Box(modifier = modifier.fillMaxSize()) {
        Column(modifier = Modifier.fillMaxSize()) {
            val activeTabColor = when (selectedStatusTab) {
                1 -> ChunkyColor.HeaderToday
                2 -> ChunkyColor.HeaderCompleted
                else -> ChunkyColor.SkyBottom
            }

            TabRow(
                selectedTabIndex = selectedStatusTab,
                containerColor = ChunkyColor.SurfaceWhite,
                contentColor = activeTabColor,
                indicator = { tabPositions ->
                    TabRowDefaults.SecondaryIndicator(
                        Modifier.tabIndicatorOffset(tabPositions[selectedStatusTab]),
                        color = activeTabColor
                    )
                }
            ) {
                Tab(
                    selected = selectedStatusTab == 0,
                    onClick = { selectedStatusTab = 0 },
                    text = {
                        Text(
                            text = "Tất cả",
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.sp,
                            color = if (selectedStatusTab == 0) ChunkyColor.SkyBottom else ChunkyColor.TextMuted
                        )
                    }
                )
                Tab(
                    selected = selectedStatusTab == 1,
                    onClick = { selectedStatusTab = 1 },
                    text = {
                        Text(
                            text = "Đang làm",
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.sp,
                            color = if (selectedStatusTab == 1) ChunkyColor.HeaderToday else ChunkyColor.TextMuted
                        )
                    }
                )
                Tab(
                    selected = selectedStatusTab == 2,
                    onClick = { selectedStatusTab = 2 },
                    text = {
                        Text(
                            text = "Đã xong",
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.sp,
                            color = if (selectedStatusTab == 2) ChunkyColor.HeaderCompleted else ChunkyColor.TextMuted
                        )
                    }
                )
            }

            if (courses.isNotEmpty()) {
                LazyRow(
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.background(ChunkyColor.WindowBackground)
                ) {
                    item(key = "all_courses", contentType = "filter_chip") {
                        val isAllSelected = selectedCourseId == null
                        FilterChip(
                            selected = isAllSelected,
                            onClick = { selectedCourseId = null },
                            label = { Text("Tất cả môn", fontSize = 12.sp, fontWeight = if (isAllSelected) FontWeight.Bold else FontWeight.Medium) },
                            border = FilterChipDefaults.filterChipBorder(
                                enabled = true,
                                selected = isAllSelected,
                                borderColor = if (isAllSelected) Color(0xFFBAE6FD) else ChunkyColor.CardBorder,
                                borderWidth = 1.dp
                            ),
                            colors = FilterChipDefaults.filterChipColors(
                                containerColor = ChunkyColor.SurfaceWhite,
                                labelColor = ChunkyColor.TextPrimary,
                                selectedContainerColor = Color(0xFFE0F2FE),
                                selectedLabelColor = Color(0xFF0369A1)
                            )
                        )
                    }
                    items(
                        items = courses,
                        key = { it.id },
                        contentType = { "filter_chip" }
                    ) { course ->
                        val isSelected = selectedCourseId == course.id
                        FilterChip(
                            selected = isSelected,
                            onClick = {
                                selectedCourseId = if (selectedCourseId == course.id) null else course.id
                            },
                            label = { Text(course.name, fontSize = 12.sp, fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium) },
                            border = FilterChipDefaults.filterChipBorder(
                                enabled = true,
                                selected = isSelected,
                                borderColor = if (isSelected) Color(0xFFBAE6FD) else ChunkyColor.CardBorder,
                                borderWidth = 1.dp
                            ),
                            colors = FilterChipDefaults.filterChipColors(
                                containerColor = ChunkyColor.SurfaceWhite,
                                labelColor = ChunkyColor.TextPrimary,
                                selectedContainerColor = Color(0xFFE0F2FE),
                                selectedLabelColor = Color(0xFF0369A1)
                            )
                        )
                    }
                }
            }

            OutlinedTextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                placeholder = { Text("Tìm ghi chú...", fontSize = 14.sp) },
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, tint = ChunkyColor.TextMuted) },
                trailingIcon = {
                    if (searchQuery.isNotEmpty()) {
                        IconButton(onClick = { searchQuery = "" }) {
                            Icon(Icons.Default.Clear, contentDescription = "Clear", tint = ChunkyColor.TextMuted)
                        }
                    }
                },
                singleLine = true,
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                keyboardActions = KeyboardActions(onSearch = { keyboardController?.hide() }),
                shape = RoundedCornerShape(12.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedContainerColor = ChunkyColor.SurfaceWhite,
                    unfocusedContainerColor = ChunkyColor.SurfaceWhite,
                    focusedBorderColor = ChunkyColor.SkyBottom,
                    unfocusedBorderColor = ChunkyColor.CardBorder
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp)
            )

            if (filteredNotes.isEmpty()) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(24.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        EmberFlameCanvas(size = 72.dp, emotion = EmberEmotion.NORMAL)
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = if (searchQuery.isNotBlank()) "Không tìm thấy ghi chú" else "Chưa có ghi chú nào",
                            fontWeight = FontWeight.Bold,
                            fontSize = 18.sp,
                            color = ChunkyColor.TextPrimary
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = if (searchQuery.isNotBlank()) "Thử tìm kiếm với từ khóa khác hoặc xoá bộ lọc." else "Nhập vào thanh bên dưới để tạo nhanh ghi chú việc học nhé!",
                            fontSize = 14.sp,
                            color = ChunkyColor.TextMuted,
                            textAlign = TextAlign.Center
                        )
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 12.dp, bottom = 136.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(
                        items = filteredNotes,
                        key = { it.id },
                        contentType = { "personal_note" }
                    ) { note ->
                        val onToggle = remember(note.id, note.isCompleted) {
                            { onToggleCompletion(note.id, !note.isCompleted) }
                        }
                        val onEdit = remember(note) {
                            { noteToEdit = note }
                        }
                        val onDelete = remember(note.id) {
                            { onDeleteNote(note.id) }
                        }
                        PersonalNoteCard(
                            note = note,
                            onToggle = onToggle,
                            onEdit = onEdit,
                            onDelete = onDelete,
                            onToggleChecklistItem = onToggleChecklistItem,
                            modifier = Modifier.animateItem(
                                fadeInSpec = spring(dampingRatio = 0.82f, stiffness = 380f),
                                placementSpec = spring(dampingRatio = 0.82f, stiffness = 380f),
                                fadeOutSpec = spring(dampingRatio = 0.82f, stiffness = 380f)
                            )
                        )
                    }
                }
            }
        }

        BottomQuickCaptureBar(
            courses = courses,
            onSaveQuickNote = { quickTitle, quickDue, quickCourseId, quickCourseName ->
                val targetCourseId = quickCourseId ?: selectedCourseId
                val targetCourse = courses.find { it.id == targetCourseId }
                val newNote = PersonalNote(
                    title = quickTitle,
                    dueEpochMillis = quickDue,
                    courseId = targetCourse?.id,
                    courseName = targetCourse?.name ?: quickCourseName
                )
                onSaveNote(newNote)
            },
            onOpenFullDialog = { draftTitle, draftDue ->
                val targetCourse = courses.find { it.id == selectedCourseId }
                draftForDialog = if (draftTitle.isNotBlank() || draftDue != null || targetCourse != null) {
                    PersonalNote(
                        title = draftTitle,
                        dueEpochMillis = draftDue,
                        courseId = targetCourse?.id,
                        courseName = targetCourse?.name
                    )
                } else {
                    null
                }
                showCreateDialog = true
            },
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .imePadding()
        )
    }

    if (showCreateDialog) {
        CreateOrEditNoteDialog(
            existingNote = draftForDialog,
            isDraft = true,
            courses = courses,
            onDismiss = {
                showCreateDialog = false
                draftForDialog = null
            },
            onSave = { note ->
                onSaveNote(note)
                showCreateDialog = false
                draftForDialog = null
            }
        )
    }

    noteToEdit?.let { note ->
        CreateOrEditNoteDialog(
            existingNote = note,
            isDraft = false,
            courses = courses,
            onDismiss = { noteToEdit = null },
            onSave = { updated ->
                onSaveNote(updated)
                noteToEdit = null
            }
        )
    }
}

@Composable
private fun PersonalNoteCard(
    note: PersonalNote,
    onToggle: () -> Unit,
    onEdit: () -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier,
    onToggleChecklistItem: ((String, String) -> Unit)? = null
) {
    var showMenu by remember { mutableStateOf(false) }
    val view = LocalView.current

    val cardInteractionSource = remember { MutableInteractionSource() }
    val isCardPressed by cardInteractionSource.collectIsPressedAsState()
    val cardPressScale = animateFloatAsState(
        targetValue = if (isCardPressed) 1f else 0f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = 400f
        ),
        label = "noteCardPressScale"
    )

    val checkInteractionSource = remember { MutableInteractionSource() }
    val isCheckPressed by checkInteractionSource.collectIsPressedAsState()
    val checkPressScale = animateFloatAsState(
        targetValue = if (isCheckPressed) 0.88f else 1.0f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessMedium
        ),
        label = "noteCheckPressScale"
    )

    val checkScale = remember { Animatable(if (note.isCompleted) 1.0f else 0.88f) }
    var isFirstComposition by remember { mutableStateOf(true) }
    LaunchedEffect(note.isCompleted) {
        if (isFirstComposition) {
            isFirstComposition = false
            return@LaunchedEffect
        }
        if (note.isCompleted) {
            checkScale.animateTo(
                targetValue = 1.15f,
                animationSpec = tween(durationMillis = 110, easing = FastOutSlowInEasing)
            )
            checkScale.animateTo(
                targetValue = 1.0f,
                animationSpec = spring(
                    dampingRatio = Spring.DampingRatioMediumBouncy,
                    stiffness = Spring.StiffnessLow
                )
            )
        } else {
            checkScale.animateTo(
                targetValue = 0.88f,
                animationSpec = spring(
                    dampingRatio = Spring.DampingRatioNoBouncy,
                    stiffness = Spring.StiffnessMedium
                )
            )
        }
    }

    val iconScale = animateFloatAsState(
        targetValue = if (note.isCompleted) 1.0f else 0.0f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessMedium
        ),
        label = "noteIconScale"
    )

    val iconRotation = animateFloatAsState(
        targetValue = if (note.isCompleted) 0f else -12f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessMedium
        ),
        label = "noteIconRotation"
    )

    val iconAlpha = animateFloatAsState(
        targetValue = if (note.isCompleted) 1.0f else 0.0f,
        animationSpec = tween(durationMillis = 180, easing = FastOutSlowInEasing),
        label = "noteIconAlpha"
    )

    val checkBgColor = animateColorAsState(
        targetValue = if (note.isCompleted) ChunkyColor.SuccessGreen else Color.Transparent,
        animationSpec = tween(durationMillis = 200),
        label = "noteCheckBgColor"
    )

    val checkBorderColor = animateColorAsState(
        targetValue = if (note.isCompleted) ChunkyColor.SuccessGreen else ChunkyColor.TextMuted.copy(alpha = 0.5f),
        animationSpec = tween(durationMillis = 200),
        label = "noteCheckBorderColor"
    )

    val strikethroughProgress = animateFloatAsState(
        targetValue = if (note.isCompleted) 1.0f else 0.0f,
        animationSpec = tween(durationMillis = 260, easing = FastOutSlowInEasing),
        label = "noteStrikethroughProgress"
    )

    val titleAlpha = animateFloatAsState(
        targetValue = if (note.isCompleted) 0.60f else 1.0f,
        animationSpec = tween(durationMillis = 220),
        label = "noteTitleAlpha"
    )

    val titleLayoutResultHolder = remember(note.id, note.title) { arrayOfNulls<TextLayoutResult>(1) }

    Row(
        modifier = modifier
            .fillMaxWidth()
            .graphicsLayer {
                val scale = 0.015f * cardPressScale.value
                scaleX = 1.0f - scale
                scaleY = 1.0f - scale
            }
            .clip(RoundedCornerShape(12.dp))
            .background(ChunkyColor.SurfaceWhite)
            .border(1.dp, ChunkyColor.CardBorder, RoundedCornerShape(12.dp)),
        verticalAlignment = Alignment.Top
    ) {
        Box(
            modifier = Modifier
                .padding(start = 4.dp, top = 2.dp)
                .size(48.dp)
                .clickable(
                    interactionSource = checkInteractionSource,
                    indication = ripple(bounded = false, radius = 22.dp),
                    role = Role.Checkbox,
                    onClick = {
                        val newCompleted = !note.isCompleted
                        if (newCompleted) {
                            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                                view.performHapticFeedback(HapticFeedbackConstants.CONFIRM)
                            } else {
                                view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
                            }
                        } else {
                            view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK)
                        }
                        onToggle()
                    }
                ),
            contentAlignment = Alignment.Center
        ) {
            Box(
                modifier = Modifier
                    .size(24.dp)
                    .graphicsLayer {
                        val combinedScale = checkScale.value * checkPressScale.value
                        scaleX = combinedScale
                        scaleY = combinedScale
                    }
                    .drawWithCache {
                        val strokeWidthPx = 2.dp.toPx()
                        val stroke = Stroke(width = strokeWidthPx)
                        val radius = (size.minDimension - strokeWidthPx) / 2f
                        onDrawBehind {
                            drawCircle(color = checkBgColor.value)
                            drawCircle(
                                color = checkBorderColor.value,
                                radius = radius,
                                style = stroke
                            )
                        }
                    },
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Check,
                    contentDescription = "Hoàn thành",
                    tint = Color.White,
                    modifier = Modifier
                        .size(16.dp)
                        .graphicsLayer {
                            scaleX = iconScale.value
                            scaleY = iconScale.value
                            rotationZ = iconRotation.value
                            alpha = iconAlpha.value
                        }
                )
            }
        }

        Row(
            modifier = Modifier
                .weight(1f)
                .padding(start = 4.dp, end = 16.dp, top = 12.dp, bottom = 12.dp),
            verticalAlignment = Alignment.Top
        ) {
            Column(
                modifier = Modifier
                    .weight(1f)
                    .clip(RoundedCornerShape(8.dp))
                    .clickable(
                        interactionSource = cardInteractionSource,
                        indication = ripple(),
                        onClick = onEdit
                    )
            ) {
                Column(
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Row(
                        verticalAlignment = Alignment.Top,
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text(
                            text = note.title,
                            fontWeight = FontWeight.Bold,
                            fontSize = 16.sp,
                            color = ChunkyColor.TextPrimary,
                            onTextLayout = { titleLayoutResultHolder[0] = it },
                            modifier = Modifier
                                .weight(1f)
                                .graphicsLayer { alpha = titleAlpha.value }
                                .drawWithCache {
                                    val strokeWidthPx = 2.dp.toPx()
                                    onDrawWithContent {
                                        drawContent()
                                        val progress = strikethroughProgress.value
                                        if (progress > 0.001f) {
                                            val layout = titleLayoutResultHolder[0]
                                            if (layout != null) {
                                                for (i in 0 until layout.lineCount) {
                                                    val lineTop = layout.getLineTop(i)
                                                    val lineBottom = layout.getLineBottom(i)
                                                    val lineLeft = layout.getLineLeft(i)
                                                    val lineRight = layout.getLineRight(i)
                                                    val y = (lineTop + lineBottom) / 2f
                                                    val endX = lineLeft + (lineRight - lineLeft) * progress
                                                    drawLine(
                                                        color = ChunkyColor.TextMuted.copy(alpha = 0.85f),
                                                        start = Offset(lineLeft, y),
                                                        end = Offset(endX, y),
                                                        strokeWidth = strokeWidthPx,
                                                        cap = StrokeCap.Round
                                                    )
                                                }
                                            } else {
                                                val y = size.height / 2f
                                                val endX = size.width * progress
                                                drawLine(
                                                    color = ChunkyColor.TextMuted.copy(alpha = 0.85f),
                                                    start = Offset(0f, y),
                                                    end = Offset(endX, y),
                                                    strokeWidth = strokeWidthPx,
                                                    cap = StrokeCap.Round
                                                )
                                            }
                                        }
                                    }
                                }
                        )

                        if (note.isDueTomorrow) {
                            Spacer(modifier = Modifier.width(8.dp))
                            DueDateBadge(
                                text = "Ngày mai",
                                isCompleted = note.isCompleted,
                                isDueTomorrow = true,
                                fontSize = 12.sp,
                                modifier = Modifier.padding(top = 1.dp)
                            )
                        } else if (note.isDueToday) {
                            Spacer(modifier = Modifier.width(8.dp))
                            DueDateBadge(
                                text = "Hôm nay",
                                isCompleted = note.isCompleted,
                                isDueToday = true,
                                fontSize = 12.sp,
                                modifier = Modifier.padding(top = 1.dp)
                            )
                        } else if (note.dueEpochMillis != null) {
                            val dateStr = ClassroomDateUtils.formatShortDate(note.dueEpochMillis)
                            Spacer(modifier = Modifier.width(8.dp))
                            DueDateBadge(
                                text = dateStr,
                                isCompleted = note.isCompleted,
                                fontSize = 12.sp,
                                modifier = Modifier.padding(top = 1.dp)
                            )
                        }
                    }

                    if (note.content.isNotBlank()) {
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = note.content,
                            fontSize = 14.sp,
                            color = if (note.isCompleted) ChunkyColor.TextMuted.copy(alpha = 0.7f) else ChunkyColor.TextMuted,
                            maxLines = 3,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }

                if (note.hasChecklist) {
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 2.dp)
                    ) {
                        Text(
                            text = "${note.completedChecklistCount}/${note.totalChecklistCount} việc con",
                            fontSize = 11.5.sp,
                            fontWeight = FontWeight.Bold,
                            color = if (note.completedChecklistCount == note.totalChecklistCount) ChunkyColor.SuccessGreen else ChunkyColor.TextMuted
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .height(4.dp)
                                .clip(RoundedCornerShape(2.dp))
                                .background(ChunkyColor.CardBorder)
                        ) {
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth(note.checklistProgress)
                                    .height(4.dp)
                                    .clip(RoundedCornerShape(2.dp))
                                    .background(if (note.completedChecklistCount == note.totalChecklistCount) ChunkyColor.SuccessGreen else ChunkyColor.SkyBottom)
                            )
                        }
                    }

                    if (onToggleChecklistItem != null) {
                        Spacer(modifier = Modifier.height(6.dp))
                        Column(
                            verticalArrangement = Arrangement.spacedBy(4.dp),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            note.checklist.take(4).forEach { item ->
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    modifier = Modifier
                                        .clip(RoundedCornerShape(6.dp))
                                        .clickable {
                                            view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK)
                                            onToggleChecklistItem(note.id, item.id)
                                        }
                                        .padding(vertical = 2.dp, horizontal = 2.dp)
                                ) {
                                    if (item.isCompleted) {
                                        Icon(
                                            imageVector = Icons.Default.CheckCircle,
                                            contentDescription = null,
                                            tint = ChunkyColor.SuccessGreen,
                                            modifier = Modifier.size(15.dp)
                                        )
                                    } else {
                                        Box(
                                            modifier = Modifier
                                                .size(15.dp)
                                                .border(1.3.dp, ChunkyColor.TextMuted.copy(alpha = 0.5f), CircleShape)
                                        )
                                    }
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text(
                                        text = item.title,
                                        fontSize = 12.5.sp,
                                        color = if (item.isCompleted) ChunkyColor.TextMuted else ChunkyColor.TextPrimary,
                                        textDecoration = if (item.isCompleted) TextDecoration.LineThrough else null,
                                        maxLines = 1,
                                        overflow = TextOverflow.Ellipsis
                                    )
                                }
                            }
                            if (note.checklist.size > 4) {
                                Text(
                                    text = "+ ${note.checklist.size - 4} mục khác...",
                                    fontSize = 11.5.sp,
                                    fontWeight = FontWeight.Medium,
                                    color = ChunkyColor.TextMuted,
                                    modifier = Modifier
                                        .clip(RoundedCornerShape(4.dp))
                                        .clickable(onClick = onEdit)
                                        .padding(start = 23.dp, top = 2.dp)
                                )
                            }
                        }
                    }
                }

                if (!note.courseName.isNullOrBlank()) {
                    Spacer(modifier = Modifier.height(8.dp))
                    SubjectBadgePill(courseName = note.courseName)
                }
            }

            Spacer(modifier = Modifier.width(4.dp))
        }

        Box(
            modifier = Modifier.padding(top = 2.dp, end = 4.dp)
        ) {
            IconButton(
                onClick = { showMenu = true },
                modifier = Modifier.size(44.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.MoreVert,
                    contentDescription = "Tùy chọn",
                    tint = ChunkyColor.TextMuted,
                    modifier = Modifier.size(20.dp)
                )
            }

            DropdownMenu(
                expanded = showMenu,
                onDismissRequest = { showMenu = false },
                containerColor = ChunkyColor.SurfaceWhite,
                shape = RoundedCornerShape(12.dp),
                border = BorderStroke(1.dp, ChunkyColor.CardBorder)
            ) {
                DropdownMenuItem(
                    text = { Text("Chỉnh sửa", fontWeight = FontWeight.Medium, fontSize = 14.sp) },
                    leadingIcon = { Icon(Icons.Default.Edit, contentDescription = null, tint = ChunkyColor.SkyBottom, modifier = Modifier.size(18.dp)) },
                    onClick = {
                        showMenu = false
                        onEdit()
                    }
                )
                DropdownMenuItem(
                    text = { Text("Xoá ghi chú", color = ChunkyColor.UrgentAccent, fontWeight = FontWeight.Medium, fontSize = 14.sp) },
                    leadingIcon = { Icon(Icons.Default.Delete, contentDescription = null, tint = ChunkyColor.UrgentAccent, modifier = Modifier.size(18.dp)) },
                    onClick = {
                        showMenu = false
                        onDelete()
                    }
                )
            }
        }
    }
}

private tailrec fun Context.findActivity(): Activity? = when (this) {
    is Activity -> this
    is ContextWrapper -> baseContext.findActivity()
    else -> null
}

@Composable
private fun CreateOrEditNoteDialog(
    existingNote: PersonalNote?,
    courses: List<Course>,
    isDraft: Boolean = false,
    onDismiss: () -> Unit,
    onSave: (PersonalNote) -> Unit
) {
    val context = LocalContext.current
    val dialogKey = existingNote?.id ?: if (isDraft) "draft_${existingNote?.title ?: ""}" else "new_note"
    var title by rememberSaveable(dialogKey) { mutableStateOf(existingNote?.title ?: "") }
    var content by rememberSaveable(dialogKey) { mutableStateOf(existingNote?.content ?: "") }
    var checklist by remember(dialogKey) {
        mutableStateOf(existingNote?.checklist ?: emptyList())
    }
    var newChecklistItemTitle by remember(dialogKey) { mutableStateOf("") }
    var selectedCourseId by rememberSaveable(dialogKey) { mutableStateOf(existingNote?.courseId ?: "") }
    val isEndOfDay = remember(dialogKey, existingNote?.dueEpochMillis) {
        existingNote?.dueEpochMillis?.let { epoch ->
            val cal = com.phucta.classroom.data.model.ClassroomDateUtils.createLocalCalendar(epoch)
            (cal.get(Calendar.HOUR_OF_DAY) == 23 && cal.get(Calendar.MINUTE) >= 55) ||
            (cal.get(Calendar.HOUR_OF_DAY) == 0 && cal.get(Calendar.MINUTE) == 0 && cal.get(Calendar.SECOND) == 0)
        } ?: false
    }
    var dueDateMode by rememberSaveable(dialogKey) {
        mutableIntStateOf(
            when {
                existingNote?.isDueToday == true && isEndOfDay -> 1
                existingNote?.isDueTomorrow == true && isEndOfDay -> 2
                existingNote?.dueEpochMillis != null -> 3
                else -> 0
            }
        )
    }
    var customDueDateEpoch by remember(dialogKey) { mutableStateOf(existingNote?.dueEpochMillis) }
    val customDateStr = remember(customDueDateEpoch) {
        customDueDateEpoch?.let {
            val cal = com.phucta.classroom.data.model.ClassroomDateUtils.createLocalCalendar(it)
            val hasTime = !(cal.get(Calendar.HOUR_OF_DAY) == 23 && cal.get(Calendar.MINUTE) >= 55) &&
                          !(cal.get(Calendar.HOUR_OF_DAY) == 0 && cal.get(Calendar.MINUTE) == 0 && cal.get(Calendar.SECOND) == 0)
            val pattern = if (hasTime) "HH:mm d/M" else "d/M"
            SimpleDateFormat(pattern, com.phucta.classroom.data.model.ClassroomDateUtils.VIETNAMESE_LOCALE).format(Date(it))
        } ?: ""
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(
            usePlatformDefaultWidth = false,
            decorFitsSystemWindows = false
        ),
        modifier = Modifier
            .fillMaxWidth(0.92f)
            .heightIn(max = 620.dp)
            .imePadding(),
        title = {
            Text(
                text = if (existingNote == null || isDraft) "Ghi chú mới" else "Chỉnh sửa ghi chú",
                fontWeight = FontWeight.Bold,
                fontSize = 18.sp
            )
        },
        text = {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .verticalScroll(rememberScrollState())
            ) {
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    label = { Text("Tiêu đề việc cần làm") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp)
                )

                Spacer(modifier = Modifier.height(12.dp))

                Text(
                    text = "Danh sách việc con (Checklist):",
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 13.sp,
                    color = ChunkyColor.TextPrimary
                )

                if (checklist.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(4.dp))
                    Column(
                        verticalArrangement = Arrangement.spacedBy(4.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        checklist.forEachIndexed { index, item ->
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(ChunkyColor.WindowBackground)
                                    .padding(horizontal = 8.dp, vertical = 4.dp)
                            ) {
                                IconButton(
                                    onClick = {
                                        checklist = checklist.toMutableList().also { list ->
                                            list[index] = item.copy(isCompleted = !item.isCompleted)
                                        }
                                    },
                                    modifier = Modifier.size(28.dp)
                                ) {
                                    if (item.isCompleted) {
                                        Icon(
                                            imageVector = Icons.Default.CheckCircle,
                                            contentDescription = null,
                                            tint = ChunkyColor.SuccessGreen,
                                            modifier = Modifier.size(18.dp)
                                        )
                                    } else {
                                        Box(
                                            modifier = Modifier
                                                .size(18.dp)
                                                .border(1.5.dp, ChunkyColor.TextMuted.copy(alpha = 0.5f), CircleShape)
                                        )
                                    }
                                }
                                Spacer(modifier = Modifier.width(6.dp))
                                Text(
                                    text = item.title,
                                    fontSize = 13.sp,
                                    color = if (item.isCompleted) ChunkyColor.TextMuted else ChunkyColor.TextPrimary,
                                    textDecoration = if (item.isCompleted) TextDecoration.LineThrough else null,
                                    modifier = Modifier.weight(1f)
                                )
                                IconButton(
                                    onClick = {
                                        checklist = checklist.toMutableList().also { list ->
                                            list.removeAt(index)
                                        }
                                    },
                                    modifier = Modifier.size(28.dp)
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Clear,
                                        contentDescription = "Xoá",
                                        tint = ChunkyColor.TextMuted,
                                        modifier = Modifier.size(16.dp)
                                    )
                                }
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(6.dp))

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    OutlinedTextField(
                        value = newChecklistItemTitle,
                        onValueChange = { newChecklistItemTitle = it },
                        placeholder = { Text("Thêm việc cần làm (nhấn Enter)...", fontSize = 12.5.sp) },
                        singleLine = true,
                        textStyle = MaterialTheme.typography.bodyMedium.copy(fontSize = 13.sp),
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                        keyboardActions = KeyboardActions(onDone = {
                            val trimmed = newChecklistItemTitle.trim()
                            if (trimmed.isNotEmpty()) {
                                checklist = checklist + com.phucta.classroom.data.model.ChecklistItem(title = trimmed)
                                newChecklistItemTitle = ""
                            }
                        }),
                        shape = RoundedCornerShape(10.dp),
                        modifier = Modifier.weight(1f)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    IconButton(
                        onClick = {
                            val trimmed = newChecklistItemTitle.trim()
                            if (trimmed.isNotEmpty()) {
                                checklist = checklist + com.phucta.classroom.data.model.ChecklistItem(title = trimmed)
                                newChecklistItemTitle = ""
                            }
                        },
                        enabled = newChecklistItemTitle.trim().isNotEmpty(),
                        modifier = Modifier
                            .size(42.dp)
                            .clip(RoundedCornerShape(10.dp))
                            .background(if (newChecklistItemTitle.trim().isNotEmpty()) ChunkyColor.SkyBottom else ChunkyColor.WindowBackground)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Add,
                            contentDescription = "Thêm mục",
                            tint = if (newChecklistItemTitle.trim().isNotEmpty()) Color.White else ChunkyColor.TextMuted,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }

                Spacer(modifier = Modifier.height(12.dp))

                OutlinedTextField(
                    value = content,
                    onValueChange = { content = it },
                    label = { Text("Nội dung chi tiết (tùy chọn)") },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(110.dp),
                    shape = RoundedCornerShape(12.dp)
                )

                Spacer(modifier = Modifier.height(12.dp))

                Text(
                    text = "Thời hạn (Báo bài):",
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 13.sp,
                    color = ChunkyColor.TextPrimary
                )

                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    modifier = Modifier.padding(top = 4.dp)
                ) {
                    item {
                        FilterChip(
                            selected = dueDateMode == 0,
                            onClick = { dueDateMode = 0 },
                            label = { Text("Không hạn", fontSize = 12.sp) }
                        )
                    }
                    item {
                        FilterChip(
                            selected = dueDateMode == 1,
                            onClick = { dueDateMode = 1 },
                            label = { Text("Hôm nay", fontSize = 12.sp) }
                        )
                    }
                    item {
                        FilterChip(
                            selected = dueDateMode == 2,
                            onClick = { dueDateMode = 2 },
                            label = { Text("Ngày mai", fontSize = 12.sp) }
                        )
                    }
                    item {
                        FilterChip(
                            selected = dueDateMode == 3,
                            onClick = {
                                val targetContext = context.findActivity() ?: context
                                val currentCal = com.phucta.classroom.data.model.ClassroomDateUtils.createLocalCalendar(
                                    customDueDateEpoch ?: (System.currentTimeMillis() + 86400000L * 2)
                                )
                                val activity = targetContext as? Activity
                                if (activity == null || (!activity.isFinishing && !activity.isDestroyed)) {
                                    try {
                                        android.app.DatePickerDialog(
                                            targetContext,
                                            { _, year, month, dayOfMonth ->
                                                val pickedCal = com.phucta.classroom.data.model.ClassroomDateUtils.createLocalCalendar().apply {
                                                    set(Calendar.YEAR, year)
                                                    set(Calendar.MONTH, month)
                                                    set(Calendar.DAY_OF_MONTH, dayOfMonth)
                                                    set(Calendar.HOUR_OF_DAY, 23)
                                                    set(Calendar.MINUTE, 59)
                                                    set(Calendar.SECOND, 59)
                                                    set(Calendar.MILLISECOND, 999)
                                                }
                                                customDueDateEpoch = pickedCal.timeInMillis
                                                dueDateMode = 3
                                            },
                                            currentCal.get(Calendar.YEAR),
                                            currentCal.get(Calendar.MONTH),
                                            currentCal.get(Calendar.DAY_OF_MONTH)
                                        ).show()
                                    } catch (_: Exception) {
                                    }
                                }
                            },
                            label = {
                                Text(
                                    if (customDateStr.isNotEmpty() && dueDateMode == 3) "Ngày khác ($customDateStr)" else "Chọn ngày...",
                                    fontSize = 12.sp
                                )
                            }
                        )
                    }
                }

                if (courses.isNotEmpty()) {
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "Môn học liên quan:",
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 13.sp,
                        color = ChunkyColor.TextPrimary
                    )
                    LazyRow(
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier.padding(top = 4.dp)
                    ) {
                        item {
                            FilterChip(
                                selected = selectedCourseId.isEmpty(),
                                onClick = { selectedCourseId = "" },
                                label = { Text("Không gắn", fontSize = 12.sp) }
                            )
                        }
                        items(courses, key = { it.id }) { course ->
                            FilterChip(
                                selected = selectedCourseId == course.id,
                                onClick = { selectedCourseId = course.id },
                                label = { Text(course.name, fontSize = 12.sp) }
                            )
                        }
                    }
                }
            }
        },
        confirmButton = {
            val saveInteractionSource = remember { MutableInteractionSource() }
            val isSavePressed by saveInteractionSource.collectIsPressedAsState()
            val saveScale by animateFloatAsState(
                targetValue = if (isSavePressed) 0.94f else 1.0f,
                animationSpec = spring(
                    dampingRatio = Spring.DampingRatioMediumBouncy,
                    stiffness = Spring.StiffnessLow
                ),
                label = "saveScale"
            )

            Button(
                onClick = {
                    val trimmedTitle = title.trim()
                    if (trimmedTitle.isNotBlank()) {
                        val computedDueEpochMillis: Long? = when (dueDateMode) {
                            1 -> {
                                val cal = com.phucta.classroom.data.model.ClassroomDateUtils.createLocalCalendar().apply {
                                    set(Calendar.HOUR_OF_DAY, 23)
                                    set(Calendar.MINUTE, 59)
                                    set(Calendar.SECOND, 59)
                                    set(Calendar.MILLISECOND, 999)
                                }
                                cal.timeInMillis
                            }
                            2 -> {
                                val cal = com.phucta.classroom.data.model.ClassroomDateUtils.createLocalCalendar().apply {
                                    add(Calendar.DAY_OF_YEAR, 1)
                                    set(Calendar.HOUR_OF_DAY, 23)
                                    set(Calendar.MINUTE, 59)
                                    set(Calendar.SECOND, 59)
                                    set(Calendar.MILLISECOND, 999)
                                }
                                cal.timeInMillis
                            }
                            3 -> customDueDateEpoch ?: existingNote?.dueEpochMillis
                            0 -> null
                            else -> existingNote?.dueEpochMillis
                        }
                        val courseObj = courses.find { it.id == selectedCourseId }
                        val resolvedCourseId = courseObj?.id ?: selectedCourseId.ifEmpty { null }
                        val resolvedCourseName = courseObj?.name ?: if (existingNote?.courseId == resolvedCourseId) existingNote?.courseName else null
                        var finalChecklist = checklist
                        val pendingItem = newChecklistItemTitle.trim()
                        if (pendingItem.isNotEmpty()) {
                            finalChecklist = finalChecklist + com.phucta.classroom.data.model.ChecklistItem(title = pendingItem)
                        }
                        finalChecklist = finalChecklist.filter { it.title.trim().isNotEmpty() }
                        val isDone = if (finalChecklist.isNotEmpty()) {
                            finalChecklist.all { it.isCompleted }
                        } else {
                            existingNote?.isCompleted ?: false
                        }
                        val isNewNote = existingNote == null || isDraft
                        val finalNote = PersonalNote(
                            id = if (isNewNote) java.util.UUID.randomUUID().toString() else existingNote.id,
                            courseworkId = if (isNewNote) null else existingNote.courseworkId,
                            courseId = resolvedCourseId,
                            courseName = resolvedCourseName,
                            title = trimmedTitle,
                            content = content.trim(),
                            checklist = finalChecklist,
                            dueEpochMillis = computedDueEpochMillis,
                            isCompleted = isDone,
                            createdAt = if (isNewNote) System.currentTimeMillis() else existingNote.createdAt,
                            updatedAt = System.currentTimeMillis()
                        )
                        onSave(finalNote)
                    }
                },
                interactionSource = saveInteractionSource,
                modifier = Modifier.graphicsLayer {
                    scaleX = saveScale
                    scaleY = saveScale
                },
                enabled = title.trim().isNotBlank(),
                colors = ButtonDefaults.buttonColors(containerColor = ChunkyColor.SkyBottom)
            ) {
                Text("Lưu ghi chú")
            }
        },
        dismissButton = {
            val dismissInteractionSource = remember { MutableInteractionSource() }
            val isDismissPressed by dismissInteractionSource.collectIsPressedAsState()
            val dismissScale by animateFloatAsState(
                targetValue = if (isDismissPressed) 0.94f else 1.0f,
                animationSpec = spring(
                    dampingRatio = Spring.DampingRatioMediumBouncy,
                    stiffness = Spring.StiffnessLow
                ),
                label = "dismissScale"
            )

            TextButton(
                onClick = onDismiss,
                interactionSource = dismissInteractionSource,
                modifier = Modifier.graphicsLayer {
                    scaleX = dismissScale
                    scaleY = dismissScale
                }
            ) {
                Text("Huỷ")
            }
        }
    )
}

@Composable
private fun BottomQuickCaptureBar(
    courses: List<Course>,
    onSaveQuickNote: (title: String, dueEpoch: Long?, courseId: String?, courseName: String?) -> Unit,
    onOpenFullDialog: (draftTitle: String, draftDue: Long?) -> Unit,
    modifier: Modifier = Modifier
) {
    var title by rememberSaveable { mutableStateOf("") }
    var selectedDeadlineMode by rememberSaveable { mutableIntStateOf(1) } // 0: none, 1: tomorrow, 2: today
    val view = LocalView.current

    val openDialogWithDraft = {
        val currentTitle = title.trim()
        val due = when (selectedDeadlineMode) {
            1 -> ClassroomDateUtils.startOfTomorrow + 23 * 3600 * 1000L + 59 * 60 * 1000L + 59 * 1000L + 999L
            2 -> ClassroomDateUtils.startOfToday + 23 * 3600 * 1000L + 59 * 60 * 1000L + 59 * 1000L + 999L
            else -> null
        }
        title = ""
        onOpenFullDialog(currentTitle, due)
    }

    Surface(
        modifier = modifier
            .fillMaxWidth()
            .border(BorderStroke(1.dp, ChunkyColor.CardBorder), RoundedCornerShape(topStart = 18.dp, topEnd = 18.dp)),
        shape = RoundedCornerShape(topStart = 18.dp, topEnd = 18.dp),
        color = Color.White.copy(alpha = 0.96f),
        shadowElevation = 8.dp
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 14.dp, vertical = 10.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                OutlinedTextField(
                    value = title,
                    onValueChange = { title = it },
                    placeholder = {
                        Text(
                            text = "Thêm việc cần làm nhanh...",
                            fontSize = 13.5.sp,
                            color = ChunkyColor.TextMuted
                        )
                    },
                    singleLine = true,
                    textStyle = MaterialTheme.typography.bodyMedium.copy(fontSize = 14.sp, color = ChunkyColor.TextPrimary),
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                    keyboardActions = KeyboardActions(onDone = {
                        val trimmed = title.trim()
                        if (trimmed.isNotEmpty()) {
                            val due = when (selectedDeadlineMode) {
                                1 -> ClassroomDateUtils.startOfTomorrow + 23 * 3600 * 1000L + 59 * 60 * 1000L + 59 * 1000L + 999L
                                2 -> ClassroomDateUtils.startOfToday + 23 * 3600 * 1000L + 59 * 60 * 1000L + 59 * 1000L + 999L
                                else -> null
                            }
                            onSaveQuickNote(trimmed, due, null, null)
                            title = ""
                            view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK)
                        }
                    }),
                    shape = RoundedCornerShape(12.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = ChunkyColor.SkyBottom,
                        unfocusedBorderColor = ChunkyColor.CardBorder,
                        focusedContainerColor = ChunkyColor.WindowBackground,
                        unfocusedContainerColor = ChunkyColor.WindowBackground
                    ),
                    modifier = Modifier.weight(1f)
                )

                Spacer(modifier = Modifier.width(8.dp))

                IconButton(
                    onClick = {
                        val trimmed = title.trim()
                        if (trimmed.isNotEmpty()) {
                            val due = when (selectedDeadlineMode) {
                                1 -> ClassroomDateUtils.startOfTomorrow + 23 * 3600 * 1000L + 59 * 60 * 1000L + 59 * 1000L + 999L
                                2 -> ClassroomDateUtils.startOfToday + 23 * 3600 * 1000L + 59 * 60 * 1000L + 59 * 1000L + 999L
                                else -> null
                            }
                            onSaveQuickNote(trimmed, due, null, null)
                            title = ""
                            view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK)
                        } else {
                            openDialogWithDraft()
                        }
                    },
                    modifier = Modifier
                        .size(44.dp)
                        .clip(CircleShape)
                        .background(if (title.trim().isNotEmpty()) ChunkyColor.SkyBottom else ChunkyColor.WindowBackground)
                        .border(1.dp, if (title.trim().isNotEmpty()) ChunkyColor.SkyBottom else ChunkyColor.CardBorder, CircleShape)
                ) {
                    Icon(
                        imageVector = if (title.trim().isNotEmpty()) Icons.Default.Check else Icons.Default.Add,
                        contentDescription = "Lưu hoặc mở rộng",
                        tint = if (title.trim().isNotEmpty()) Color.White else ChunkyColor.TextPrimary,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(6.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                QuickDeadlinePill(
                    label = "Mai",
                    selected = selectedDeadlineMode == 1,
                    onClick = { selectedDeadlineMode = if (selectedDeadlineMode == 1) 0 else 1 }
                )
                QuickDeadlinePill(
                    label = "Hôm nay",
                    selected = selectedDeadlineMode == 2,
                    onClick = { selectedDeadlineMode = if (selectedDeadlineMode == 2) 0 else 2 }
                )
                QuickDeadlinePill(
                    label = "Không hạn",
                    selected = selectedDeadlineMode == 0,
                    onClick = { selectedDeadlineMode = 0 }
                )

                Spacer(modifier = Modifier.weight(1f))

                Text(
                    text = "Mở rộng",
                    fontSize = 11.5.sp,
                    fontWeight = FontWeight.SemiBold,
                    color = ChunkyColor.PillBlue,
                    modifier = Modifier
                        .clip(RoundedCornerShape(6.dp))
                        .clickable(onClick = openDialogWithDraft)
                        .padding(horizontal = 6.dp, vertical = 2.dp)
                )
            }
        }
    }
}

@Composable
private fun QuickDeadlinePill(
    label: String,
    selected: Boolean,
    onClick: () -> Unit
) {
    val bg = if (selected) ChunkyColor.PillBlue.copy(alpha = 0.14f) else Color.Transparent
    val border = if (selected) ChunkyColor.PillBlue else ChunkyColor.CardBorder
    val textCol = if (selected) ChunkyColor.PillBlue else ChunkyColor.TextMuted

    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(8.dp))
            .background(bg)
            .border(1.dp, border, RoundedCornerShape(8.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = 9.dp, vertical = 3.dp)
    ) {
        Text(
            text = label,
            fontSize = 11.5.sp,
            fontWeight = if (selected) FontWeight.Bold else FontWeight.Medium,
            color = textCol
        )
    }
}
