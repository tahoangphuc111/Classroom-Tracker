package com.phucta.classroom.ui.screens

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.material3.ripple
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.graphicsLayer
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
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.RadioButton
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
    modifier: Modifier = Modifier
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

    val searchTokens = remember(normalizedQuery) {
        com.phucta.classroom.data.model.tokenizeSearchQuery(normalizedQuery)
    }

    var showCreateDialog by rememberSaveable { mutableStateOf(false) }
    var noteToEdit by remember { mutableStateOf<PersonalNote?>(null) }

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
                            fontSize = 13.5.sp,
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
                            fontSize = 13.5.sp,
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
                            fontSize = 13.5.sp,
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
                    item {
                        val isAllSelected = selectedCourseId == null
                        FilterChip(
                            selected = isAllSelected,
                            onClick = { selectedCourseId = null },
                            label = { Text("Tất cả môn", fontSize = 12.5.sp, fontWeight = if (isAllSelected) FontWeight.Bold else FontWeight.Medium) },
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
                    items(courses, key = { it.id }) { course ->
                        val isSelected = selectedCourseId == course.id
                        FilterChip(
                            selected = isSelected,
                            onClick = {
                                selectedCourseId = if (selectedCourseId == course.id) null else course.id
                            },
                            label = { Text(course.name, fontSize = 12.5.sp, fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium) },
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
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(
                            text = if (searchQuery.isNotBlank()) "Thử tìm kiếm với từ khóa khác hoặc xoá bộ lọc." else "Nhấn nút + bên dưới để tạo ghi chú mới cho việc học nhé!",
                            fontSize = 13.5.sp,
                            color = ChunkyColor.TextMuted,
                            textAlign = TextAlign.Center
                        )
                    }
                }
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 12.dp, bottom = 88.dp),
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    items(
                        items = filteredNotes,
                        key = { it.id },
                        contentType = { "personal_note" }
                    ) { note ->
                        PersonalNoteCard(
                            note = note,
                            onToggle = { onToggleCompletion(note.id, !note.isCompleted) },
                            onEdit = { noteToEdit = note },
                            onDelete = { onDeleteNote(note.id) },
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

        val fabInteractionSource = remember { MutableInteractionSource() }
        val isFabPressed by fabInteractionSource.collectIsPressedAsState()
        val fabScale = animateFloatAsState(
            targetValue = if (isFabPressed) 0.92f else 1.0f,
            animationSpec = spring(
                dampingRatio = Spring.DampingRatioMediumBouncy,
                stiffness = Spring.StiffnessLow
            ),
            label = "fabScale"
        )

        FloatingActionButton(
            onClick = { showCreateDialog = true },
            interactionSource = fabInteractionSource,
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(20.dp)
                .graphicsLayer {
                    scaleX = fabScale.value
                    scaleY = fabScale.value
                },
            containerColor = ChunkyColor.SkyBottom,
            contentColor = Color.White
        ) {
            Icon(Icons.Default.Add, contentDescription = "Thêm ghi chú")
        }
    }

    if (showCreateDialog) {
        CreateOrEditNoteDialog(
            existingNote = null,
            courses = courses,
            onDismiss = { showCreateDialog = false },
            onSave = { note ->
                onSaveNote(note)
                showCreateDialog = false
            }
        )
    }

    noteToEdit?.let { note ->
        CreateOrEditNoteDialog(
            existingNote = note,
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
    modifier: Modifier = Modifier
) {
    var showMenu by remember { mutableStateOf(false) }

    // Tactile card press animation with snappy spring (deferred to draw phase)
    val cardInteractionSource = remember { MutableInteractionSource() }
    val isCardPressed by cardInteractionSource.collectIsPressedAsState()
    val cardScale = animateFloatAsState(
        targetValue = if (isCardPressed) 0.985f else 1.0f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessLow
        ),
        label = "noteCardScale"
    )

    // Checkbox press feedback & elastic bounce/scale pop (1.15f -> 1.0f)
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

    val iconAlpha = animateFloatAsState(
        targetValue = if (note.isCompleted) 1.0f else 0.0f,
        animationSpec = tween(durationMillis = 180, easing = FastOutSlowInEasing),
        label = "noteIconAlpha"
    )

    val checkBgColor by animateColorAsState(
        targetValue = if (note.isCompleted) ChunkyColor.SuccessGreen else Color.Transparent,
        animationSpec = tween(durationMillis = 200),
        label = "noteCheckBgColor"
    )

    val checkBorderColor by animateColorAsState(
        targetValue = if (note.isCompleted) ChunkyColor.SuccessGreen else ChunkyColor.TextMuted.copy(alpha = 0.5f),
        animationSpec = tween(durationMillis = 200),
        label = "noteCheckBorderColor"
    )

    // Smooth strikethrough transition & color fade
    val strikethroughProgress = animateFloatAsState(
        targetValue = if (note.isCompleted) 1.0f else 0.0f,
        animationSpec = tween(durationMillis = 260, easing = FastOutSlowInEasing),
        label = "noteStrikethroughProgress"
    )

    val titleColor by animateColorAsState(
        targetValue = if (note.isCompleted) ChunkyColor.TextMuted else ChunkyColor.TextPrimary,
        animationSpec = tween(durationMillis = 220),
        label = "noteTitleColor"
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
                scaleX = cardScale.value
                scaleY = cardScale.value
            }
            .clip(RoundedCornerShape(14.dp))
            .background(ChunkyColor.SurfaceWhite)
            .border(1.dp, ChunkyColor.CardBorder, RoundedCornerShape(14.dp)),
        verticalAlignment = Alignment.Top
    ) {
        Box(
            modifier = Modifier
                .padding(start = 6.dp, top = 4.dp)
                .size(44.dp)
                .clip(CircleShape)
                .clickable(
                    interactionSource = checkInteractionSource,
                    indication = ripple(bounded = false, radius = 20.dp),
                    role = Role.Checkbox,
                    onClick = onToggle
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
                    .clip(CircleShape)
                    .background(color = checkBgColor)
                    .border(
                        1.5.dp,
                        color = checkBorderColor,
                        shape = CircleShape
                    ),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Check,
                    contentDescription = "Hoàn thành",
                    tint = Color.White,
                    modifier = Modifier
                        .size(15.dp)
                        .graphicsLayer {
                            scaleX = iconScale.value
                            scaleY = iconScale.value
                            alpha = iconAlpha.value
                        }
                )
            }
        }

        Row(
            modifier = Modifier
                .weight(1f)
                .clip(RoundedCornerShape(topEnd = 14.dp, bottomEnd = 14.dp))
                .clickable(
                    interactionSource = cardInteractionSource,
                    indication = ripple(),
                    onClick = onEdit
                )
                .padding(start = 4.dp, end = 12.dp, top = 14.dp, bottom = 14.dp),
            verticalAlignment = Alignment.Top
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Row(
                    verticalAlignment = Alignment.Top,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Text(
                        text = note.title,
                        fontWeight = FontWeight.Bold,
                        fontSize = 16.sp,
                        color = titleColor,
                        onTextLayout = { titleLayoutResultHolder[0] = it },
                        modifier = Modifier
                            .weight(1f)
                            .graphicsLayer { alpha = titleAlpha.value }
                            .drawWithContent {
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
                                                strokeWidth = 1.75.dp.toPx(),
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
                                            strokeWidth = 1.75.dp.toPx(),
                                            cap = StrokeCap.Round
                                        )
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
                            fontSize = 11.5.sp,
                            modifier = Modifier.padding(top = 1.dp)
                        )
                    } else if (note.isDueToday) {
                        Spacer(modifier = Modifier.width(8.dp))
                        DueDateBadge(
                            text = "Hôm nay",
                            isCompleted = note.isCompleted,
                            isDueToday = true,
                            fontSize = 11.5.sp,
                            modifier = Modifier.padding(top = 1.dp)
                        )
                    } else if (note.dueEpochMillis != null) {
                        val dateStr = ClassroomDateUtils.formatShortDate(note.dueEpochMillis)
                        Spacer(modifier = Modifier.width(8.dp))
                        DueDateBadge(
                            text = dateStr,
                            isCompleted = note.isCompleted,
                            fontSize = 11.5.sp,
                            modifier = Modifier.padding(top = 1.dp)
                        )
                    }
                }

                if (note.content.isNotBlank()) {
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = note.content,
                        fontSize = 13.5.sp,
                        color = if (note.isCompleted) ChunkyColor.TextMuted.copy(alpha = 0.7f) else ChunkyColor.TextMuted,
                        maxLines = 3,
                        overflow = TextOverflow.Ellipsis
                    )
                }

                if (!note.courseName.isNullOrBlank()) {
                    Spacer(modifier = Modifier.height(8.dp))
                    SubjectBadgePill(courseName = note.courseName)
                }
            }

            Spacer(modifier = Modifier.width(6.dp))

            Box {
                IconButton(
                    onClick = { showMenu = true },
                    modifier = Modifier.size(32.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.MoreVert,
                        contentDescription = "Tùy chọn",
                        tint = ChunkyColor.TextMuted,
                        modifier = Modifier.size(18.dp)
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
}

@Composable
private fun CreateOrEditNoteDialog(
    existingNote: PersonalNote?,
    courses: List<Course>,
    onDismiss: () -> Unit,
    onSave: (PersonalNote) -> Unit
) {
    var title by rememberSaveable { mutableStateOf(existingNote?.title ?: "") }
    var content by rememberSaveable { mutableStateOf(existingNote?.content ?: "") }
    var selectedCourseId by rememberSaveable { mutableStateOf(existingNote?.courseId ?: "") }
    var dueDateMode by rememberSaveable {
        mutableIntStateOf(
            when {
                existingNote?.isDueToday == true -> 1
                existingNote?.isDueTomorrow == true -> 2
                existingNote?.dueEpochMillis != null -> 3
                else -> 0
            }
        )
    }
    val hasCustomDueDate = existingNote?.dueEpochMillis != null && !existingNote.isDueToday && !existingNote.isDueTomorrow
    val customDateStr = remember(existingNote?.dueEpochMillis) {
        existingNote?.dueEpochMillis?.let {
            SimpleDateFormat("d/M", Locale.getDefault()).format(Date(it))
        } ?: ""
    }

    AlertDialog(
        onDismissRequest = onDismiss,
        properties = DialogProperties(usePlatformDefaultWidth = false),
        modifier = Modifier
            .fillMaxWidth(0.92f)
            .heightIn(max = 620.dp)
            .imePadding(),
        title = {
            Text(
                text = if (existingNote == null) "Ghi chú mới" else "Chỉnh sửa ghi chú",
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
                    label = { Text("Tiêu đề ghi chú") },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(10.dp)
                )

                Spacer(modifier = Modifier.height(10.dp))

                OutlinedTextField(
                    value = content,
                    onValueChange = { content = it },
                    label = { Text("Nội dung chi tiết (tùy chọn)") },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(110.dp),
                    shape = RoundedCornerShape(10.dp)
                )

                Spacer(modifier = Modifier.height(12.dp))

                Text(
                    text = "Thời hạn (Báo bài):",
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 13.sp,
                    color = ChunkyColor.TextPrimary
                )

                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                    modifier = Modifier.padding(top = 4.dp)
                ) {
                    item {
                        FilterChip(
                            selected = dueDateMode == 0,
                            onClick = { dueDateMode = 0 },
                            label = { Text("Không hạn", fontSize = 11.5.sp) }
                        )
                    }
                    item {
                        FilterChip(
                            selected = dueDateMode == 1,
                            onClick = { dueDateMode = 1 },
                            label = { Text("Hôm nay", fontSize = 11.5.sp) }
                        )
                    }
                    item {
                        FilterChip(
                            selected = dueDateMode == 2,
                            onClick = { dueDateMode = 2 },
                            label = { Text("Ngày mai", fontSize = 11.5.sp) }
                        )
                    }
                    if (hasCustomDueDate) {
                        item {
                            FilterChip(
                                selected = dueDateMode == 3,
                                onClick = { dueDateMode = 3 },
                                label = { Text("Ngày khác ($customDateStr)", fontSize = 11.5.sp) }
                            )
                        }
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
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                        modifier = Modifier.padding(top = 4.dp)
                    ) {
                        item {
                            FilterChip(
                                selected = selectedCourseId.isEmpty(),
                                onClick = { selectedCourseId = "" },
                                label = { Text("Không gắn", fontSize = 11.5.sp) }
                            )
                        }
                        items(courses) { course ->
                            FilterChip(
                                selected = selectedCourseId == course.id,
                                onClick = { selectedCourseId = course.id },
                                label = { Text(course.name, fontSize = 11.5.sp) }
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
                                val cal = Calendar.getInstance().apply {
                                    set(Calendar.HOUR_OF_DAY, 23)
                                    set(Calendar.MINUTE, 59)
                                    set(Calendar.SECOND, 59)
                                    set(Calendar.MILLISECOND, 999)
                                }
                                cal.timeInMillis
                            }
                            2 -> {
                                val cal = Calendar.getInstance().apply {
                                    add(Calendar.DAY_OF_YEAR, 1)
                                    set(Calendar.HOUR_OF_DAY, 23)
                                    set(Calendar.MINUTE, 59)
                                    set(Calendar.SECOND, 59)
                                    set(Calendar.MILLISECOND, 999)
                                }
                                cal.timeInMillis
                            }
                            0 -> null
                            else -> existingNote?.dueEpochMillis
                        }
                        val courseObj = courses.find { it.id == selectedCourseId }
                        val finalNote = PersonalNote(
                            id = existingNote?.id ?: java.util.UUID.randomUUID().toString(),
                            courseworkId = existingNote?.courseworkId,
                            courseId = courseObj?.id,
                            courseName = courseObj?.name,
                            title = trimmedTitle,
                            content = content.trim(),
                            dueEpochMillis = computedDueEpochMillis,
                            isCompleted = existingNote?.isCompleted ?: false,
                            createdAt = existingNote?.createdAt ?: System.currentTimeMillis(),
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
                enabled = title.isNotBlank(),
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
