package com.phucta.classroom.ui.screens

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.ui.draw.clip
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.graphics.Color
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.HelpOutline
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Upcoming
import androidx.compose.material.icons.filled.Warning
import androidx.compose.ui.res.painterResource
import com.phucta.classroom.ui.components.EmberEmotion
import com.phucta.classroom.ui.components.EmberFlameCanvas
import com.phucta.classroom.ui.components.SectionHeaderPill
import com.phucta.classroom.ui.components.SubjectArtHelper
import com.phucta.classroom.ui.components.SubjectCategory
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.phucta.classroom.data.model.ClassroomDateUtils
import com.phucta.classroom.data.model.Course
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.data.model.normalizeForVietnameseSearch
import com.phucta.classroom.domain.BaoBaiBucketingUtils
import com.phucta.classroom.ui.components.AssignmentCard
import com.phucta.classroom.ui.theme.ChunkyColor

import androidx.compose.animation.core.spring
import androidx.compose.ui.unit.IntOffset
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.text.input.ImeAction

private val ItemPlacementSpring = spring<IntOffset>(dampingRatio = 0.82f, stiffness = 380f)
private val ItemFadeSpring = spring<Float>(dampingRatio = 0.82f, stiffness = 380f)

@OptIn(androidx.compose.foundation.ExperimentalFoundationApi::class)
@Composable
fun AllUpcomingScreen(
    allCoursework: List<Coursework>,
    courses: List<Course>,
    onToggleCompletion: (String, Boolean) -> Unit,
    onSelectAssignment: (Coursework) -> Unit,
    modifier: Modifier = Modifier,
    courseworkIdsWithNotes: Set<String> = emptySet(),
    currentDayEpoch: Long = ClassroomDateUtils.startOfToday
) {
    var searchQuery by rememberSaveable { mutableStateOf("") }
    val currentOnToggleCompletion by rememberUpdatedState(onToggleCompletion)
    val currentOnSelectAssignment by rememberUpdatedState(onSelectAssignment)
    val normalizedQuery = remember(searchQuery) { searchQuery.normalizeForVietnameseSearch() }
    val keyboardController = LocalSoftwareKeyboardController.current
    val focusManager = LocalFocusManager.current
    val listState = rememberLazyListState()

    LaunchedEffect(listState.isScrollInProgress) {
        if (listState.isScrollInProgress) {
            focusManager.clearFocus()
            keyboardController?.hide()
        }
    }

    BackHandler(enabled = searchQuery.isNotEmpty()) {
        searchQuery = ""
    }

    val activeCoursework = remember(allCoursework, courses) {
        BaoBaiBucketingUtils.filterByActiveCourses(allCoursework, courses)
    }

    val searchTokens = remember(normalizedQuery) {
        com.phucta.classroom.data.model.tokenizeSearchQuery(normalizedQuery)
    }

    val filteredItems = remember(activeCoursework, searchTokens) {
        if (searchTokens.isEmpty()) {
            activeCoursework
        } else {
            activeCoursework.filter { item ->
                for (token in searchTokens) {
                    if (!item.searchIndex.contains(token)) {
                        val altTok = com.phucta.classroom.data.model.cleanTelexKeystrokes(token)
                        if (altTok == token || !item.searchIndex.contains(altTok)) return@filter false
                    }
                }
                true
            }
        }
    }

    val buckets = remember(filteredItems, searchTokens, normalizedQuery, currentDayEpoch) {
        BaoBaiBucketingUtils.computeBuckets(
            items = filteredItems,
            searchTokens = searchTokens,
            rawNormalizedQuery = normalizedQuery
        )
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(ChunkyColor.WindowBackground)
    ) {
        OutlinedTextField(
            value = searchQuery,
            onValueChange = { searchQuery = it },
            placeholder = { Text("Tìm bài tập...", fontSize = 15.sp) },
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
                .padding(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 4.dp)
        )

        if (searchQuery.isNotBlank()) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 2.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Tìm thấy ${filteredItems.size} bài tập",
                    fontSize = 13.5.sp,
                    color = ChunkyColor.TextMuted,
                    fontWeight = FontWeight.SemiBold
                )
                androidx.compose.material3.TextButton(
                    onClick = { searchQuery = "" },
                    contentPadding = PaddingValues(horizontal = 4.dp, vertical = 0.dp)
                ) {
                    Text(
                        text = "Xóa tìm kiếm",
                        fontSize = 13.5.sp,
                        color = ChunkyColor.TextLink,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }
        }

        val hasAnyUpcoming = buckets.overdue.isNotEmpty() ||
                buckets.today.isNotEmpty() ||
                buckets.tomorrow.isNotEmpty() ||
                buckets.laterUpcoming.isNotEmpty() ||
                buckets.noDueDate.isNotEmpty()

        val hasAnyCompletedMatches = searchQuery.isNotBlank() && buckets.completed.isNotEmpty()

        val upcomingIncompleteCount = remember(buckets) {
            buckets.overdue.count { !it.isCompleted } +
                    buckets.today.count { !it.isCompleted } +
                    buckets.tomorrow.count { !it.isCompleted } +
                    buckets.laterUpcoming.count { !it.isCompleted } +
                    buckets.noDueDate.count { !it.isCompleted }
        }

        if (searchQuery.isBlank() && hasAnyUpcoming && upcomingIncompleteCount > 0) {
            val upcomingEmotion = when {
                buckets.overdue.isNotEmpty() || upcomingIncompleteCount >= 5 -> EmberEmotion.STRESSED
                else -> EmberEmotion.STUDYING
            }
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 4.dp)
                    .clip(RoundedCornerShape(14.dp))
                    .background(
                        if (upcomingEmotion == EmberEmotion.STRESSED) Color(0xFFFEF2F2)
                        else ChunkyColor.SurfaceWhite
                    )
                    .border(
                        1.dp,
                        if (upcomingEmotion == EmberEmotion.STRESSED) Color(0xFFFECACA)
                        else ChunkyColor.CardBorder,
                        RoundedCornerShape(14.dp)
                    )
                    .padding(horizontal = 16.dp, vertical = 12.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    EmberFlameCanvas(
                        size = 50.dp,
                        emotion = upcomingEmotion
                    )
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = if (upcomingEmotion == EmberEmotion.STRESSED) {
                                "$upcomingIncompleteCount bài cần chú ý"
                            } else {
                                "Đang có $upcomingIncompleteCount bài sắp tới"
                            },
                            fontWeight = FontWeight.Bold,
                            fontSize = 15.5.sp,
                            color = ChunkyColor.TextPrimary
                        )
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(
                            text = if (upcomingEmotion == EmberEmotion.STRESSED) {
                                "Có bài quá hạn hoặc sắp đến hạn nộp rồi."
                            } else {
                                "Xếp theo thời gian nộp từ gần đến xa để dễ theo dõi."
                            },
                            fontSize = 13.5.sp,
                            color = ChunkyColor.TextMuted,
                            lineHeight = 18.sp
                        )
                    }
                }
            }
        }

        if (filteredItems.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 16.dp, vertical = 20.dp),
                contentAlignment = Alignment.Center
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(16.dp))
                        .background(ChunkyColor.SurfaceWhite)
                        .border(1.dp, ChunkyColor.CardBorder, RoundedCornerShape(16.dp))
                        .padding(horizontal = 20.dp, vertical = 32.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        EmberFlameCanvas(
                            size = 80.dp,
                            emotion = if (searchQuery.isNotBlank()) EmberEmotion.NORMAL else EmberEmotion.SLEEPING
                        )
                        Spacer(modifier = Modifier.height(14.dp))
                        Text(
                            text = if (searchQuery.isNotBlank()) "Không tìm thấy bài tập" else "Chưa có bài tập nào",
                            fontWeight = FontWeight.Bold,
                            fontSize = 18.sp,
                            color = ChunkyColor.TextPrimary
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = if (searchQuery.isNotBlank()) {
                                "Không có bài tập nào khớp với từ khóa \"$searchQuery\"."
                            } else {
                                "Danh sách bài tập sắp tới hiện đang trống."
                            },
                            fontSize = 14.5.sp,
                            color = ChunkyColor.TextMuted,
                            textAlign = TextAlign.Center,
                            lineHeight = 20.sp
                        )
                    }
                }
            }
        } else if (!hasAnyUpcoming && !hasAnyCompletedMatches) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(horizontal = 16.dp, vertical = 20.dp),
                contentAlignment = Alignment.Center
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(16.dp))
                        .background(ChunkyColor.SurfaceWhite)
                        .border(1.dp, ChunkyColor.CardBorder, RoundedCornerShape(16.dp))
                        .padding(horizontal = 20.dp, vertical = 32.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        EmberFlameCanvas(
                            size = 80.dp,
                            emotion = EmberEmotion.CELEBRATING
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "Hết bài cần nộp rồi",
                            fontWeight = FontWeight.Bold,
                            fontSize = 18.sp,
                            color = ChunkyColor.TextPrimary,
                            textAlign = TextAlign.Center
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "Tất cả bài tập trong danh sách đều đã xong.",
                            fontSize = 14.5.sp,
                            color = ChunkyColor.TextMuted,
                            textAlign = TextAlign.Center,
                            lineHeight = 20.sp
                        )
                    }
                }
            }
        } else {
            LazyColumn(
                state = listState,
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(start = 16.dp, top = 8.dp, end = 16.dp, bottom = 28.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                if (buckets.overdue.isNotEmpty()) {
                    item(key = "header_overdue", contentType = "section_header") {
                        SectionHeaderPill(
                            title = "QUÁ HẠN",
                            count = buckets.overdue.size,
                            icon = Icons.Default.Warning,
                            color = ChunkyColor.HeaderOverdue,
                            modifier = Modifier
                                .padding(top = 4.dp)
                                .animateItem(
                                    fadeInSpec = ItemFadeSpring,
                                    placementSpec = ItemPlacementSpring,
                                    fadeOutSpec = ItemFadeSpring
                                )
                        )
                    }
                    items(
                        items = buckets.overdue,
                        key = { it.id },
                        contentType = { "assignment_card" }
                    ) { item ->
                        val onToggle = remember(item.id) {
                            { completed: Boolean -> currentOnToggleCompletion(item.id, completed) }
                        }
                        val onClickCard = remember(item.id) {
                            { currentOnSelectAssignment(item) }
                        }
                        AssignmentCard(
                            coursework = item,
                            hasNote = courseworkIdsWithNotes.contains(item.id),
                            onToggleCompletion = onToggle,
                            onClick = onClickCard,
                            modifier = Modifier.animateItem(
                                fadeInSpec = ItemFadeSpring,
                                placementSpec = ItemPlacementSpring,
                                fadeOutSpec = ItemFadeSpring
                            )
                        )
                    }
                }

                if (buckets.today.isNotEmpty()) {
                    item(key = "header_today", contentType = "section_header") {
                        SectionHeaderPill(
                            title = "HÔM NAY",
                            count = buckets.today.size,
                            icon = Icons.Default.Schedule,
                            color = ChunkyColor.HeaderToday,
                            modifier = Modifier
                                .padding(top = 4.dp)
                                .animateItem(
                                    fadeInSpec = ItemFadeSpring,
                                    placementSpec = ItemPlacementSpring,
                                    fadeOutSpec = ItemFadeSpring
                                )
                        )
                    }
                    items(
                        items = buckets.today,
                        key = { it.id },
                        contentType = { "assignment_card" }
                    ) { item ->
                        val onToggle = remember(item.id) {
                            { completed: Boolean -> currentOnToggleCompletion(item.id, completed) }
                        }
                        val onClickCard = remember(item.id) {
                            { currentOnSelectAssignment(item) }
                        }
                        AssignmentCard(
                            coursework = item,
                            hasNote = courseworkIdsWithNotes.contains(item.id),
                            onToggleCompletion = onToggle,
                            onClick = onClickCard,
                            modifier = Modifier.animateItem(
                                fadeInSpec = ItemFadeSpring,
                                placementSpec = ItemPlacementSpring,
                                fadeOutSpec = ItemFadeSpring
                            )
                        )
                    }
                }

                if (buckets.tomorrow.isNotEmpty()) {
                    item(key = "header_tomorrow", contentType = "section_header") {
                        SectionHeaderPill(
                            title = "NGÀY MAI",
                            count = buckets.tomorrow.size,
                            icon = Icons.Default.CalendarToday,
                            color = ChunkyColor.HeaderTomorrow,
                            modifier = Modifier
                                .padding(top = 4.dp)
                                .animateItem(
                                    fadeInSpec = ItemFadeSpring,
                                    placementSpec = ItemPlacementSpring,
                                    fadeOutSpec = ItemFadeSpring
                                )
                        )
                    }
                    items(
                        items = buckets.tomorrow,
                        key = { it.id },
                        contentType = { "assignment_card" }
                    ) { item ->
                        val onToggle = remember(item.id) {
                            { completed: Boolean -> currentOnToggleCompletion(item.id, completed) }
                        }
                        val onClickCard = remember(item.id) {
                            { currentOnSelectAssignment(item) }
                        }
                        AssignmentCard(
                            coursework = item,
                            hasNote = courseworkIdsWithNotes.contains(item.id),
                            onToggleCompletion = onToggle,
                            onClick = onClickCard,
                            modifier = Modifier.animateItem(
                                fadeInSpec = ItemFadeSpring,
                                placementSpec = ItemPlacementSpring,
                                fadeOutSpec = ItemFadeSpring
                            )
                        )
                    }
                }

                if (buckets.laterUpcoming.isNotEmpty()) {
                    item(key = "header_later", contentType = "section_header") {
                        SectionHeaderPill(
                            title = "SẮP TỚI",
                            count = buckets.laterUpcoming.size,
                            icon = Icons.Default.Upcoming,
                            color = ChunkyColor.HeaderUpcoming,
                            modifier = Modifier
                                .padding(top = 4.dp)
                                .animateItem(
                                    fadeInSpec = ItemFadeSpring,
                                    placementSpec = ItemPlacementSpring,
                                    fadeOutSpec = ItemFadeSpring
                                )
                        )
                    }
                    items(
                        items = buckets.laterUpcoming,
                        key = { it.id },
                        contentType = { "assignment_card" }
                    ) { item ->
                        val onToggle = remember(item.id) {
                            { completed: Boolean -> currentOnToggleCompletion(item.id, completed) }
                        }
                        val onClickCard = remember(item.id) {
                            { currentOnSelectAssignment(item) }
                        }
                        AssignmentCard(
                            coursework = item,
                            hasNote = courseworkIdsWithNotes.contains(item.id),
                            onToggleCompletion = onToggle,
                            onClick = onClickCard,
                            modifier = Modifier.animateItem(
                                fadeInSpec = ItemFadeSpring,
                                placementSpec = ItemPlacementSpring,
                                fadeOutSpec = ItemFadeSpring
                            )
                        )
                    }
                }

                if (buckets.noDueDate.isNotEmpty()) {
                    item(key = "header_no_due_date", contentType = "section_header") {
                        SectionHeaderPill(
                            title = "KHÔNG CÓ HẠN",
                            count = buckets.noDueDate.size,
                            icon = Icons.AutoMirrored.Filled.HelpOutline,
                            color = ChunkyColor.HeaderUpcoming,
                            modifier = Modifier
                                .padding(top = 4.dp)
                                .animateItem(
                                    fadeInSpec = ItemFadeSpring,
                                    placementSpec = ItemPlacementSpring,
                                    fadeOutSpec = ItemFadeSpring
                                )
                        )
                    }
                    items(
                        items = buckets.noDueDate,
                        key = { it.id },
                        contentType = { "assignment_card" }
                    ) { item ->
                        val onToggle = remember(item.id) {
                            { completed: Boolean -> currentOnToggleCompletion(item.id, completed) }
                        }
                        val onClickCard = remember(item.id) {
                            { currentOnSelectAssignment(item) }
                        }
                        AssignmentCard(
                            coursework = item,
                            hasNote = courseworkIdsWithNotes.contains(item.id),
                            onToggleCompletion = onToggle,
                            onClick = onClickCard,
                            modifier = Modifier.animateItem(
                                fadeInSpec = ItemFadeSpring,
                                placementSpec = ItemPlacementSpring,
                                fadeOutSpec = ItemFadeSpring
                            )
                        )
                    }
                }

                if (searchQuery.isNotBlank() && buckets.completed.isNotEmpty()) {
                    item(key = "header_completed", contentType = "section_header") {
                        SectionHeaderPill(
                            title = "ĐÃ HOÀN THÀNH",
                            count = buckets.completed.size,
                            icon = Icons.Default.CheckCircle,
                            color = ChunkyColor.HeaderCompleted,
                            modifier = Modifier
                                .padding(top = 4.dp)
                                .animateItem(
                                    fadeInSpec = ItemFadeSpring,
                                    placementSpec = ItemPlacementSpring,
                                    fadeOutSpec = ItemFadeSpring
                                )
                        )
                    }
                    items(
                        items = buckets.completed,
                        key = { it.id },
                        contentType = { "assignment_card" }
                    ) { item ->
                        val onToggle = remember(item.id) {
                            { completed: Boolean -> currentOnToggleCompletion(item.id, completed) }
                        }
                        val onClickCard = remember(item.id) {
                            { currentOnSelectAssignment(item) }
                        }
                        AssignmentCard(
                            coursework = item,
                            hasNote = courseworkIdsWithNotes.contains(item.id),
                            onToggleCompletion = onToggle,
                            onClick = onClickCard,
                            modifier = Modifier.animateItem(
                                fadeInSpec = ItemFadeSpring,
                                placementSpec = ItemPlacementSpring,
                                fadeOutSpec = ItemFadeSpring
                            )
                        )
                    }
                }
            }
        }
    }
}
