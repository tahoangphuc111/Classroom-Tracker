package com.phucta.classroom.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
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
        normalizedQuery.split("\\s+".toRegex()).filter { it.isNotBlank() }
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
            matches.sortedWith(
                compareByDescending<PersonalNote> { note ->
                    com.phucta.classroom.data.model.calculateSearchRelevance(
                        queryTokens = searchTokens,
                        rawNormalizedQuery = normalizedQuery,
                        title = note.title,
                        courseName = note.courseName,
                        content = note.content
                    )
                }.then(defaultComparator)
            )
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
                    items(filteredNotes, key = { it.id }) { note ->
                        PersonalNoteCard(
                            note = note,
                            onToggle = { onToggleCompletion(note.id, !note.isCompleted) },
                            onEdit = { noteToEdit = note },
                            onDelete = { onDeleteNote(note.id) }
                        )
                    }
                }
            }
        }

        FloatingActionButton(
            onClick = { showCreateDialog = true },
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(20.dp),
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
    onDelete: () -> Unit
) {
    var showMenu by remember { mutableStateOf(false) }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(ChunkyColor.SurfaceWhite)
            .border(1.dp, ChunkyColor.CardBorder, RoundedCornerShape(14.dp))
            .padding(14.dp),
        verticalAlignment = Alignment.Top
    ) {
        Box(
            modifier = Modifier
                .size(26.dp)
                .clip(CircleShape)
                .background(if (note.isCompleted) ChunkyColor.SuccessGreen else Color.Transparent)
                .border(
                    1.5.dp,
                    if (note.isCompleted) ChunkyColor.SuccessGreen else ChunkyColor.TextMuted.copy(alpha = 0.5f),
                    CircleShape
                )
                .clickable(onClick = onToggle),
            contentAlignment = Alignment.Center
        ) {
            if (note.isCompleted) {
                Icon(
                    imageVector = Icons.Default.Check,
                    contentDescription = "Hoàn thành",
                    tint = Color.White,
                    modifier = Modifier.size(16.dp)
                )
            }
        }

        Spacer(modifier = Modifier.width(12.dp))

        Column(modifier = Modifier.weight(1f)) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text(
                    text = note.title,
                    fontWeight = FontWeight.Bold,
                    fontSize = 16.sp,
                    color = if (note.isCompleted) ChunkyColor.TextMuted else ChunkyColor.TextPrimary,
                    textDecoration = if (note.isCompleted) TextDecoration.LineThrough else TextDecoration.None,
                    modifier = Modifier.weight(1f)
                )

                if (note.isDueTomorrow) {
                    DueDateBadge(
                        text = "Ngày mai",
                        isCompleted = note.isCompleted,
                        isDueTomorrow = true,
                        fontSize = 11.5.sp
                    )
                } else if (note.isDueToday) {
                    DueDateBadge(
                        text = "Hôm nay",
                        isCompleted = note.isCompleted,
                        isDueToday = true,
                        fontSize = 11.5.sp
                    )
                } else if (note.dueEpochMillis != null) {
                    val dateStr = remember(note.dueEpochMillis) {
                        SimpleDateFormat("d/M", Locale.getDefault()).format(Date(note.dueEpochMillis))
                    }
                    DueDateBadge(
                        text = dateStr,
                        isCompleted = note.isCompleted,
                        fontSize = 11.5.sp
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

        Box {
            IconButton(
                onClick = { showMenu = true },
                modifier = Modifier.size(28.dp)
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
                onDismissRequest = { showMenu = false }
            ) {
                DropdownMenuItem(
                    text = { Text("Chỉnh sửa") },
                    leadingIcon = { Icon(Icons.Default.Edit, contentDescription = null, modifier = Modifier.size(18.dp)) },
                    onClick = {
                        showMenu = false
                        onEdit()
                    }
                )
                DropdownMenuItem(
                    text = { Text("Xoá ghi chú", color = ChunkyColor.UrgentAccent) },
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
        title = {
            Text(
                text = if (existingNote == null) "Ghi chú mới" else "Chỉnh sửa ghi chú",
                fontWeight = FontWeight.Bold,
                fontSize = 18.sp
            )
        },
        text = {
            Column(modifier = Modifier.fillMaxWidth()) {
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
                enabled = title.isNotBlank(),
                colors = ButtonDefaults.buttonColors(containerColor = ChunkyColor.SkyBottom)
            ) {
                Text("Lưu ghi chú")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Huỷ")
            }
        }
    )
}
