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
import androidx.compose.ui.geometry.Size
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
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.consumeWindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.ime
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
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
import androidx.compose.material.icons.filled.Close
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
import androidx.compose.ui.platform.LocalFocusManager
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
import com.phucta.classroom.ui.components.SubjectArtHelper
import com.phucta.classroom.ui.components.SubjectBadgePill
import com.phucta.classroom.ui.theme.BeVietnamProFontFamily
import com.phucta.classroom.ui.theme.ChunkyColor
import kotlinx.coroutines.delay
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.unit.IntOffset
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch

private class CachedNoteTitleLine(val left: Float, val right: Float, val y: Float)

private val NoteItemPlacementSpring = spring<IntOffset>(dampingRatio = 0.82f, stiffness = 380f)
private val NoteItemFadeSpring = spring<Float>(dampingRatio = 0.82f, stiffness = 380f)

private val NoteCardPressSpring = spring<Float>(
    dampingRatio = Spring.DampingRatioMediumBouncy,
    stiffness = 400f
)
private val NoteCheckPressSpring = spring<Float>(
    dampingRatio = Spring.DampingRatioMediumBouncy,
    stiffness = Spring.StiffnessMedium
)
private val NoteCheckBounceOutTween = tween<Float>(durationMillis = 110, easing = FastOutSlowInEasing)
private val NoteCheckBounceSpring = spring<Float>(
    dampingRatio = Spring.DampingRatioMediumBouncy,
    stiffness = Spring.StiffnessLow
)
private val NoteCheckUncheckSpring = spring<Float>(
    dampingRatio = Spring.DampingRatioNoBouncy,
    stiffness = Spring.StiffnessMedium
)
private val NoteCompletionProgressTween = tween<Float>(durationMillis = 260, easing = FastOutSlowInEasing)
private val NoteUncheckedBorderColor = ChunkyColor.TextMuted.copy(alpha = 0.5f)
private val NoteSaveButtonSpring = spring<Float>(
    dampingRatio = Spring.DampingRatioMediumBouncy,
    stiffness = Spring.StiffnessLow
)

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
    val focusManager = LocalFocusManager.current

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
    var draftSessionKey by rememberSaveable { mutableStateOf("") }
    var draftDueDateMode by rememberSaveable { mutableIntStateOf(0) }

    var quickBarResetToken by rememberSaveable { mutableIntStateOf(0) }
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
                searchTokens.all { token ->
                    note.searchIndex.contains(token) || run {
                        val altTok = com.phucta.classroom.data.model.cleanTelexKeystrokes(token)
                        altTok != token && note.searchIndex.contains(altTok)
                    }
                }
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
                note.searchRelevanceScore(searchTokens, normalizedQuery)
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

    val colorScheme = MaterialTheme.colorScheme

    Column(modifier = modifier.fillMaxSize().background(colorScheme.surface)) {
        Column(modifier = Modifier.weight(1f)) {
            val activeTabColor = when (selectedStatusTab) {
                1 -> ChunkyColor.HeaderToday
                2 -> ChunkyColor.HeaderCompleted
                else -> colorScheme.primary
            }

            TabRow(
                selectedTabIndex = selectedStatusTab,
                containerColor = colorScheme.surfaceContainerLowest,
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
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = if (selectedStatusTab == 0) FontWeight.Bold else FontWeight.Medium,
                            color = if (selectedStatusTab == 0) colorScheme.primary else colorScheme.onSurfaceVariant
                        )
                    }
                )
                Tab(
                    selected = selectedStatusTab == 1,
                    onClick = { selectedStatusTab = 1 },
                    text = {
                        Text(
                            text = "Đang làm",
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = if (selectedStatusTab == 1) FontWeight.Bold else FontWeight.Medium,
                            color = if (selectedStatusTab == 1) ChunkyColor.HeaderToday else colorScheme.onSurfaceVariant
                        )
                    }
                )
                Tab(
                    selected = selectedStatusTab == 2,
                    onClick = { selectedStatusTab = 2 },
                    text = {
                        Text(
                            text = "Đã xong",
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = if (selectedStatusTab == 2) FontWeight.Bold else FontWeight.Medium,
                            color = if (selectedStatusTab == 2) ChunkyColor.HeaderCompleted else colorScheme.onSurfaceVariant
                        )
                    }
                )
            }

            OutlinedTextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                placeholder = { Text("Tìm ghi chú...", style = MaterialTheme.typography.bodyLarge) },
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, tint = colorScheme.onSurfaceVariant) },
                trailingIcon = {
                    if (searchQuery.isNotEmpty()) {
                        IconButton(onClick = { searchQuery = "" }) {
                            Icon(Icons.Default.Clear, contentDescription = "Xóa tìm kiếm", tint = colorScheme.onSurfaceVariant)
                        }
                    }
                },
                singleLine = true,
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                keyboardActions = KeyboardActions(onSearch = { keyboardController?.hide() }),
                shape = RoundedCornerShape(28.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedContainerColor = colorScheme.surfaceContainerLowest,
                    unfocusedContainerColor = colorScheme.surfaceContainerLowest,
                    focusedBorderColor = colorScheme.primary,
                    unfocusedBorderColor = colorScheme.outlineVariant
                ),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp)
            )

            if (filteredNotes.isEmpty()) {
                val emptyEmotion = when {
                    searchQuery.isNotBlank() -> EmberEmotion.NORMAL
                    selectedStatusTab == 1 -> EmberEmotion.CELEBRATING
                    selectedStatusTab == 2 -> EmberEmotion.STUDYING
                    else -> EmberEmotion.NORMAL
                }
                val emptyTitle = when {
                    searchQuery.isNotBlank() -> "Không tìm thấy ghi chú"
                    selectedStatusTab == 1 -> "Hết việc cần làm rồi"
                    selectedStatusTab == 2 -> "Chưa có việc nào xong"
                    else -> "Chưa có ghi chú nào"
                }
                val emptySubtitle = when {
                    searchQuery.isNotBlank() -> "Thử tìm với từ khóa khác hoặc xóa bộ lọc."
                    selectedStatusTab == 1 -> "Bạn đã hoàn thành hết các việc cần làm."
                    selectedStatusTab == 2 -> "Việc cần làm sau khi tick xong sẽ ở đây."
                    else -> "Gõ vào ô bên dưới để lưu nhanh việc cần làm."
                }
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .clickable(
                            interactionSource = remember { MutableInteractionSource() },
                            indication = null
                        ) {
                            focusManager.clearFocus()
                            keyboardController?.hide()
                        }
                        .padding(24.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        EmberFlameCanvas(size = 80.dp, emotion = emptyEmotion)
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = emptyTitle,
                            style = MaterialTheme.typography.titleLarge,
                            color = colorScheme.onSurface
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = emptySubtitle,
                            style = MaterialTheme.typography.bodyMedium,
                            color = colorScheme.onSurfaceVariant,
                            textAlign = TextAlign.Center
                        )
                    }
                }
            } else {
                val listState = rememberLazyListState()
                LaunchedEffect(listState.isScrollInProgress) {
                    if (listState.isScrollInProgress) {
                        focusManager.clearFocus()
                        keyboardController?.hide()
                    }
                }
                LazyColumn(
                    state = listState,
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp),
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
                                fadeInSpec = NoteItemFadeSpring,
                                placementSpec = NoteItemPlacementSpring,
                                fadeOutSpec = NoteItemFadeSpring
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
            onOpenFullDialog = { draftTitle, draftDue, draftCourseId, draftDeadlineMode ->
                val targetCourseId = draftCourseId ?: selectedCourseId
                val targetCourse = courses.find { it.id == targetCourseId }

                val hasContent = draftTitle.isNotBlank() || draftDue != null || targetCourse != null
                draftForDialog = if (hasContent) {
                    PersonalNote(
                        title = draftTitle,
                        dueEpochMillis = draftDue,
                        courseId = targetCourse?.id,
                        courseName = targetCourse?.name
                    )
                } else {
                    null
                }

                draftSessionKey = java.util.UUID.randomUUID().toString()

                draftDueDateMode = when (draftDeadlineMode) {
                    1 -> 2
                    2 -> 1
                    else -> 0
                }
                showCreateDialog = true
            },
            modifier = Modifier
                .fillMaxWidth()

                .then(if (showCreateDialog || noteToEdit != null) Modifier else Modifier.imePadding()),
            resetToken = quickBarResetToken
        )
    }

    if (showCreateDialog) {
        CreateOrEditNoteDialog(
            existingNote = draftForDialog,
            isDraft = true,
            draftSessionKey = draftSessionKey,
            initialDueDateMode = draftDueDateMode,
            courses = courses,
            onDismiss = {
                showCreateDialog = false
                draftForDialog = null
            },
            onSave = { note ->
                onSaveNote(note)
                showCreateDialog = false
                draftForDialog = null

                quickBarResetToken++
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
        animationSpec = NoteCardPressSpring,
        label = "noteCardPressScale"
    )

    val checkInteractionSource = remember { MutableInteractionSource() }
    val isCheckPressed by checkInteractionSource.collectIsPressedAsState()
    val checkPressScale = animateFloatAsState(
        targetValue = if (isCheckPressed) 0.88f else 1.0f,
        animationSpec = NoteCheckPressSpring,
        label = "noteCheckPressScale"
    )

    val checkScale = remember(note.id) { Animatable(if (note.isCompleted) 1.0f else 0.88f) }
    val completionProgress = remember(note.id) { Animatable(if (note.isCompleted) 1.0f else 0.0f) }
    var isFirstComposition by remember(note.id) { mutableStateOf(true) }

    LaunchedEffect(note.isCompleted) {
        if (isFirstComposition) {
            isFirstComposition = false
            return@LaunchedEffect
        }
        if (note.isCompleted) {
            coroutineScope {
                launch {
                    checkScale.animateTo(
                        targetValue = 1.15f,
                        animationSpec = NoteCheckBounceOutTween
                    )
                    checkScale.animateTo(
                        targetValue = 1.0f,
                        animationSpec = NoteCheckBounceSpring
                    )
                }
                launch {
                    completionProgress.animateTo(
                        targetValue = 1.0f,
                        animationSpec = NoteCompletionProgressTween
                    )
                }
            }
        } else {
            coroutineScope {
                launch {
                    checkScale.animateTo(
                        targetValue = 0.88f,
                        animationSpec = NoteCheckUncheckSpring
                    )
                }
                launch {
                    completionProgress.animateTo(
                        targetValue = 0.0f,
                        animationSpec = NoteCompletionProgressTween
                    )
                }
            }
        }
    }

    val cachedTitleLines = remember(note.id, note.title) { ArrayList<CachedNoteTitleLine>(2) }
    val onTitleTextLayout: (TextLayoutResult) -> Unit = remember(cachedTitleLines) {
        { layout ->
            cachedTitleLines.clear()
            val count = layout.lineCount
            for (i in 0 until count) {
                cachedTitleLines.add(
                    CachedNoteTitleLine(
                        layout.getLineLeft(i),
                        layout.getLineRight(i),
                        (layout.getLineTop(i) + layout.getLineBottom(i)) / 2f
                    )
                )
            }
        }
    }
    val subjectTheme = remember(note.courseName) {
        note.courseName?.takeIf { it.isNotBlank() }?.let { SubjectArtHelper.theme(it) }
    }

    val colorScheme = MaterialTheme.colorScheme
    val uncheckedBorderColor = colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
    val strikethroughColor = colorScheme.onSurfaceVariant.copy(alpha = 0.85f)

    Row(
        modifier = modifier
            .fillMaxWidth()
            .graphicsLayer {
                val scale = 0.015f * cardPressScale.value
                scaleX = 1.0f - scale
                scaleY = 1.0f - scale
            }
            .clip(RoundedCornerShape(16.dp))
            .background(colorScheme.surfaceContainerLowest)
            .then(
                if (subjectTheme != null) {
                    Modifier.drawBehind {
                        val barWidth = 4.5.dp.toPx()
                        val barAlpha = if (note.isCompleted) 0.35f else 0.95f
                        drawRect(
                            color = subjectTheme.color.copy(alpha = barAlpha),
                            topLeft = Offset.Zero,
                            size = Size(barWidth, size.height)
                        )
                    }
                } else Modifier
            )
            .border(1.dp, colorScheme.outlineVariant, RoundedCornerShape(16.dp)),
        verticalAlignment = Alignment.Top
    ) {
        Box(
            modifier = Modifier
                .padding(start = 4.dp, top = 4.dp)
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
                    .size(25.dp)
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
                            val progress = completionProgress.value
                            val factor = (progress / 0.769f).coerceIn(0f, 1f)
                            val bgColor = lerp(Color.Transparent, ChunkyColor.SuccessGreen, factor)
                            val borderColor = lerp(NoteUncheckedBorderColor, ChunkyColor.SuccessGreen, factor)
                            drawCircle(color = bgColor)
                            drawCircle(
                                color = borderColor,
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
                        .size(17.dp)
                        .graphicsLayer {
                            val progress = completionProgress.value
                            scaleX = progress
                            scaleY = progress
                            rotationZ = -12f + 12f * progress
                            alpha = (progress / 0.692f).coerceIn(0f, 1f)
                        }
                )
            }
        }

        Row(
            modifier = Modifier
                .weight(1f)
                .padding(start = 4.dp, end = 16.dp, top = 13.dp, bottom = 13.dp),
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
                            style = MaterialTheme.typography.titleMedium.copy(
                                fontSize = 17.sp,
                                lineHeight = 23.sp
                            ),
                            color = colorScheme.onSurface,
                            onTextLayout = onTitleTextLayout,
                            modifier = Modifier
                                .weight(1f)
                                .graphicsLayer {
                                    val progress = completionProgress.value
                                    alpha = 1.0f - 0.40f * progress
                                }
                                .drawWithCache {
                                    val strokeWidthPx = 2.dp.toPx()
                                    onDrawWithContent {
                                        drawContent()
                                        val progress = completionProgress.value
                                        if (progress > 0.001f) {
                                            val lines = cachedTitleLines
                                            if (lines.isNotEmpty()) {
                                                for (i in 0 until lines.size) {
                                                    val line = lines[i]
                                                    val endX = line.left + (line.right - line.left) * progress
                                                    drawLine(
                                                        color = strikethroughColor,
                                                        start = Offset(line.left, line.y),
                                                        end = Offset(endX, line.y),
                                                        strokeWidth = strokeWidthPx,
                                                        cap = StrokeCap.Round
                                                    )
                                                }
                                            } else {
                                                val y = size.height / 2f
                                                val endX = size.width * progress
                                                drawLine(
                                                    color = strikethroughColor,
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
                                fontSize = 13.sp,
                                modifier = Modifier.padding(top = 2.dp)
                            )
                        } else if (note.isDueToday) {
                            Spacer(modifier = Modifier.width(8.dp))
                            DueDateBadge(
                                text = "Hôm nay",
                                isCompleted = note.isCompleted,
                                isDueToday = true,
                                fontSize = 13.sp,
                                modifier = Modifier.padding(top = 2.dp)
                            )
                        } else if (note.dueEpochMillis != null) {
                            val dateStr = ClassroomDateUtils.formatShortDate(note.dueEpochMillis)
                            Spacer(modifier = Modifier.width(8.dp))
                            DueDateBadge(
                                text = dateStr,
                                isCompleted = note.isCompleted,
                                fontSize = 13.sp,
                                modifier = Modifier.padding(top = 2.dp)
                            )
                        }
                    }

                    if (note.content.isNotBlank()) {
                        Spacer(modifier = Modifier.height(5.dp))
                        Text(
                            text = note.content,
                            fontSize = 15.sp,
                            lineHeight = 21.sp,
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
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Bold,
                            color = if (note.completedChecklistCount == note.totalChecklistCount) ChunkyColor.SuccessGreen else ChunkyColor.TextMuted
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .height(5.dp)
                                .clip(RoundedCornerShape(2.5.dp))
                                .background(ChunkyColor.CardBorder)
                        ) {
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth(note.checklistProgress)
                                    .height(5.dp)
                                    .clip(RoundedCornerShape(2.5.dp))
                                    .background(if (note.completedChecklistCount == note.totalChecklistCount) ChunkyColor.SuccessGreen else ChunkyColor.SkyBottom)
                            )
                        }
                    }

                    if (onToggleChecklistItem != null) {
                        Spacer(modifier = Modifier.height(6.dp))
                        Column(
                            verticalArrangement = Arrangement.spacedBy(5.dp),
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
                                        .padding(vertical = 2.5.dp, horizontal = 2.dp)
                                ) {
                                    if (item.isCompleted) {
                                        Box(
                                            modifier = Modifier
                                                .size(18.dp)
                                                .background(ChunkyColor.SuccessGreen.copy(alpha = 0.16f), CircleShape),
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Icon(
                                                imageVector = Icons.Default.CheckCircle,
                                                contentDescription = null,
                                                tint = ChunkyColor.SuccessGreen,
                                                modifier = Modifier.size(15.dp)
                                            )
                                        }
                                    } else {
                                        Box(
                                            modifier = Modifier
                                                .size(18.dp)
                                                .border(1.4.dp, ChunkyColor.TextMuted.copy(alpha = 0.5f), CircleShape)
                                        )
                                    }
                                    Spacer(modifier = Modifier.width(7.dp))
                                    Text(
                                        text = item.title,
                                        fontSize = 14.sp,
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
                                    fontSize = 13.sp,
                                    fontWeight = FontWeight.SemiBold,
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
                modifier = Modifier.size(48.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.MoreVert,
                    contentDescription = "Tùy chọn",
                    tint = colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(20.dp)
                )
            }

            DropdownMenu(
                expanded = showMenu,
                onDismissRequest = { showMenu = false },
                containerColor = colorScheme.surfaceContainerHigh,
                shape = RoundedCornerShape(12.dp),
                border = BorderStroke(1.dp, colorScheme.outlineVariant)
            ) {
                DropdownMenuItem(
                    text = { Text("Chỉnh sửa", style = MaterialTheme.typography.labelLarge) },
                    leadingIcon = { Icon(Icons.Default.Edit, contentDescription = null, tint = colorScheme.primary, modifier = Modifier.size(18.dp)) },
                    onClick = {
                        showMenu = false
                        onEdit()
                    }
                )
                DropdownMenuItem(
                    text = { Text("Xóa ghi chú", color = colorScheme.error, style = MaterialTheme.typography.labelLarge) },
                    leadingIcon = { Icon(Icons.Default.Delete, contentDescription = null, tint = colorScheme.error, modifier = Modifier.size(18.dp)) },
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
    draftSessionKey: String = "",
    initialDueDateMode: Int? = null,
    onDismiss: () -> Unit,
    onSave: (PersonalNote) -> Unit
) {
    val context = LocalContext.current

    val dialogKey = when {
        isDraft -> "draft_${draftSessionKey.ifEmpty { "initial" }}"
        existingNote?.id != null -> existingNote.id
        else -> "new_note"
    }
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
            cal.get(Calendar.HOUR_OF_DAY) == 23 && cal.get(Calendar.MINUTE) >= 55
        } ?: false
    }
    var dueDateMode by rememberSaveable(dialogKey) {
        mutableIntStateOf(
            when {

                initialDueDateMode != null -> initialDueDateMode
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
            val hasTime = !(cal.get(Calendar.HOUR_OF_DAY) == 23 && cal.get(Calendar.MINUTE) >= 55)
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

            .imePadding()
            .consumeWindowInsets(WindowInsets.ime),
        title = {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                EmberFlameCanvas(
                    size = 32.dp,
                    emotion = EmberEmotion.STUDYING
                )
                Text(
                    text = if (existingNote == null || isDraft) "Ghi chú mới" else "Chỉnh sửa ghi chú",
                    fontWeight = FontWeight.Bold,
                    fontSize = 18.sp
                )
            }
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
                                        Box(
                                            modifier = Modifier
                                                .size(20.dp)
                                                .background(ChunkyColor.SuccessGreen.copy(alpha = 0.16f), CircleShape),
                                            contentAlignment = Alignment.Center
                                        ) {
                                            Icon(
                                                imageVector = Icons.Default.CheckCircle,
                                                contentDescription = null,
                                                tint = ChunkyColor.SuccessGreen,
                                                modifier = Modifier.size(17.dp)
                                            )
                                        }
                                    } else {
                                        Box(
                                            modifier = Modifier
                                                .size(20.dp)
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
                            .background(if (newChecklistItemTitle.trim().isNotEmpty()) ChunkyColor.ActionBlue else ChunkyColor.WindowBackground)
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
                animationSpec = NoteSaveButtonSpring,
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
                colors = ButtonDefaults.buttonColors(containerColor = ChunkyColor.SuccessGreen)
            ) {
                Icon(
                    imageVector = Icons.Default.Check,
                    contentDescription = null,
                    modifier = Modifier.size(17.dp)
                )
                Spacer(modifier = Modifier.width(6.dp))
                Text("Lưu ghi chú", fontWeight = FontWeight.Bold)
            }
        },
        dismissButton = {
            val dismissInteractionSource = remember { MutableInteractionSource() }
            val isDismissPressed by dismissInteractionSource.collectIsPressedAsState()
            val dismissScale by animateFloatAsState(
                targetValue = if (isDismissPressed) 0.94f else 1.0f,
                animationSpec = NoteSaveButtonSpring,
                label = "dismissScale"
            )

            TextButton(
                onClick = onDismiss,
                interactionSource = dismissInteractionSource,
                modifier = Modifier
                    .heightIn(min = 48.dp)
                    .graphicsLayer {
                        scaleX = dismissScale
                        scaleY = dismissScale
                    }
            ) {
                Text(
                    text = "Hủy",
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    style = MaterialTheme.typography.labelLarge
                )
            }
        }
    )
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun BottomQuickCaptureBar(
    courses: List<Course>,
    onSaveQuickNote: (title: String, dueEpoch: Long?, courseId: String?, courseName: String?) -> Unit,
    onOpenFullDialog: (draftTitle: String, draftDue: Long?, draftCourseId: String?, draftDeadlineMode: Int) -> Unit,
    resetToken: Int = 0,
    modifier: Modifier = Modifier
) {
    var title by rememberSaveable { mutableStateOf("") }
    var selectedDeadlineMode by rememberSaveable { mutableIntStateOf(1) }
    var selectedCourseId by rememberSaveable { mutableStateOf<String?>(null) }
    var showCourseMenu by remember { mutableStateOf(false) }
    val view = LocalView.current
    val focusManager = LocalFocusManager.current
    val keyboardController = LocalSoftwareKeyboardController.current

    LaunchedEffect(resetToken) {
        if (resetToken > 0) {
            title = ""
            selectedCourseId = null
            selectedDeadlineMode = 1
        }
    }

    val dueForMode = { mode: Int ->
        when (mode) {
            1 -> ClassroomDateUtils.startOfDayAfter - 1000L
            2 -> ClassroomDateUtils.startOfTomorrow - 1000L
            else -> null
        }
    }

    val openDialogWithDraft = {
        val currentTitle = title.trim()
        val currentMode = selectedDeadlineMode
        val currentCourse = selectedCourseId

        val hasDraftContent = currentTitle.isNotEmpty() || currentCourse != null
        val due = if (hasDraftContent) dueForMode(currentMode) else null

        focusManager.clearFocus()
        keyboardController?.hide()
        onOpenFullDialog(currentTitle, due, currentCourse, currentMode)
    }

    val submitQuickNote = {
        val trimmed = title.trim()
        if (trimmed.isNotEmpty()) {
            val due = dueForMode(selectedDeadlineMode)
            val targetCourse = courses.find { it.id == selectedCourseId }
            onSaveQuickNote(trimmed, due, selectedCourseId, targetCourse?.name)

            title = ""
            selectedCourseId = null
            selectedDeadlineMode = 1
            view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK)
            focusManager.clearFocus()
            keyboardController?.hide()
        } else {
            focusManager.clearFocus()
            keyboardController?.hide()
        }
    }

    val colorScheme = MaterialTheme.colorScheme

    Surface(
        modifier = modifier
            .fillMaxWidth()
            .border(BorderStroke(1.dp, colorScheme.outlineVariant), RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp)),
        shape = RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp),
        color = colorScheme.surfaceContainerLow,
        tonalElevation = 3.dp,
        shadowElevation = 6.dp
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
                            style = MaterialTheme.typography.bodyMedium,
                            color = colorScheme.onSurfaceVariant
                        )
                    },
                    singleLine = true,
                    textStyle = MaterialTheme.typography.bodyLarge.copy(color = colorScheme.onSurface),
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
                    keyboardActions = KeyboardActions(onDone = {
                        submitQuickNote()
                    }),
                    shape = RoundedCornerShape(24.dp),
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedBorderColor = colorScheme.primary,
                        unfocusedBorderColor = colorScheme.outlineVariant,
                        focusedContainerColor = colorScheme.surfaceContainerLowest,
                        unfocusedContainerColor = colorScheme.surfaceContainerLowest
                    ),
                    modifier = Modifier.weight(1f)
                )

                Spacer(modifier = Modifier.width(8.dp))

                IconButton(
                    onClick = {
                        val trimmed = title.trim()
                        if (trimmed.isNotEmpty()) {
                            submitQuickNote()
                        } else {
                            openDialogWithDraft()
                        }
                    },
                    modifier = Modifier
                        .size(48.dp)
                        .clip(CircleShape)
                        .background(if (title.trim().isNotEmpty()) ChunkyColor.SuccessGreen else colorScheme.primaryContainer)
                ) {
                    Icon(
                        imageVector = if (title.trim().isNotEmpty()) Icons.Default.Check else Icons.Default.Add,
                        contentDescription = if (title.trim().isNotEmpty()) "Lưu ghi chú nhanh" else "Tạo ghi chú chi tiết",
                        tint = if (title.trim().isNotEmpty()) Color.White else colorScheme.onPrimaryContainer,
                        modifier = Modifier.size(22.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(6.dp))

            FlowRow(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp)
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

                if (courses.isNotEmpty()) {
                    Box {
                        val selectedCourse = courses.find { it.id == selectedCourseId }
                        val courseLabel = selectedCourse?.name ?: "Môn"
                        val isCourseSelected = selectedCourseId != null

                        FilterChip(
                            selected = isCourseSelected,
                            onClick = { showCourseMenu = true },
                            label = {
                                Text(
                                    text = courseLabel,
                                    style = MaterialTheme.typography.labelMedium,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis,
                                    modifier = Modifier.widthIn(max = 110.dp)
                                )
                            },
                            colors = FilterChipDefaults.filterChipColors(
                                selectedContainerColor = colorScheme.primaryContainer,
                                selectedLabelColor = colorScheme.onPrimaryContainer
                            )
                        )

                        DropdownMenu(
                            expanded = showCourseMenu,
                            onDismissRequest = { showCourseMenu = false }
                        ) {
                            DropdownMenuItem(
                                text = { Text("Không gắn môn") },
                                onClick = {
                                    selectedCourseId = null
                                    showCourseMenu = false
                                }
                            )
                            courses.forEach { course ->
                                DropdownMenuItem(
                                    text = { Text(course.name) },
                                    onClick = {
                                        selectedCourseId = course.id
                                        showCourseMenu = false
                                    }
                                )
                            }
                        }
                    }
                }

                TextButton(
                    onClick = openDialogWithDraft,
                    modifier = Modifier.heightIn(min = 48.dp),
                    contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = "Mở rộng",
                        maxLines = 1,
                        style = MaterialTheme.typography.labelMedium,
                        color = colorScheme.primary
                    )
                }
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
    val colorScheme = MaterialTheme.colorScheme
    FilterChip(
        selected = selected,
        onClick = onClick,
        label = {
            Text(
                text = label,
                style = MaterialTheme.typography.labelMedium
            )
        },
        colors = FilterChipDefaults.filterChipColors(
            selectedContainerColor = colorScheme.primaryContainer,
            selectedLabelColor = colorScheme.onPrimaryContainer
        )
    )
}
