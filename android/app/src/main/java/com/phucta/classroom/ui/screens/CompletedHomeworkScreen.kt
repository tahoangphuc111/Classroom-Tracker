package com.phucta.classroom.ui.screens

import androidx.activity.compose.BackHandler
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.data.model.normalizeForVietnameseSearch
import com.phucta.classroom.data.model.tokenizeSearchQuery
import com.phucta.classroom.ui.components.AssignmentCard
import com.phucta.classroom.ui.components.SectionHeaderPill
import com.phucta.classroom.ui.components.SubjectArtHelper
import com.phucta.classroom.ui.components.SubjectCategory
import com.phucta.classroom.ui.theme.ChunkyColor

private val ItemPlacementSpring = spring<IntOffset>(dampingRatio = 0.82f, stiffness = 380f)
private val ItemFadeSpring = spring<Float>(dampingRatio = 0.82f, stiffness = 380f)

@OptIn(androidx.compose.foundation.ExperimentalFoundationApi::class)
@Composable
fun CompletedHomeworkScreen(
    completedItems: List<Coursework>,
    onToggleCompletion: (String, Boolean) -> Unit,
    onSelectAssignment: (Coursework) -> Unit,
    modifier: Modifier = Modifier,
    courseworkIdsWithNotes: Set<String> = emptySet()
) {
    val currentOnToggleCompletion by rememberUpdatedState(onToggleCompletion)
    val currentOnSelectAssignment by rememberUpdatedState(onSelectAssignment)
    var selectedSubjectCategory by remember { mutableStateOf<SubjectCategory?>(null) }
    var searchQuery by rememberSaveable { mutableStateOf("") }
    val keyboardController = LocalSoftwareKeyboardController.current
    val normalizedQuery = remember(searchQuery) { searchQuery.normalizeForVietnameseSearch() }
    val searchTokens = remember(normalizedQuery) {
        tokenizeSearchQuery(normalizedQuery)
    }

    val availableSubjectCategories = remember(completedItems) {
        val categories = java.util.EnumSet.noneOf(SubjectCategory::class.java)
        for (item in completedItems) {
            val cat = SubjectArtHelper.category(item.courseName, item.title)
            if (cat != SubjectCategory.OTHER) {
                categories.add(cat)
            }
        }
        categories.sortedBy { it.name }
    }

    val filteredItems = remember(completedItems, selectedSubjectCategory, searchTokens) {
        val target = selectedSubjectCategory
        val byCat = if (target == null) {
            completedItems
        } else {
            completedItems.filter { item ->
                SubjectArtHelper.category(item.courseName, item.title) == target
            }
        }
        if (searchTokens.isEmpty()) {
            byCat
        } else {
            byCat.filter { item ->
                for (token in searchTokens) {
                    if (!item.searchIndex.contains(token)) return@filter false
                }
                true
            }
        }
    }

    var displayLimit by remember(selectedSubjectCategory, searchQuery) { mutableIntStateOf(30) }
    val displayedItems = remember(filteredItems, displayLimit) {
        filteredItems.take(displayLimit)
    }

    BackHandler(enabled = searchQuery.isNotEmpty() || selectedSubjectCategory != null) {
        if (searchQuery.isNotEmpty()) {
            searchQuery = ""
        } else {
            selectedSubjectCategory = null
        }
    }

    if (completedItems.isEmpty()) {
        Box(
            modifier = modifier
                .fillMaxSize()
                .background(ChunkyColor.WindowBackground)
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
                    Box(
                        modifier = Modifier
                            .size(56.dp)
                            .clip(CircleShape)
                            .background(ChunkyColor.SuccessGreen.copy(alpha = 0.12f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.CheckCircle,
                            contentDescription = null,
                            tint = ChunkyColor.SuccessGreen,
                            modifier = Modifier.size(28.dp)
                        )
                    }
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "Chưa có bài tập hoàn thành",
                        fontWeight = FontWeight.Bold,
                        fontSize = 18.sp,
                        color = ChunkyColor.TextPrimary
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "Đánh dấu bài tập đã hoàn thành từ danh sách Báo bài để xem lại tại đây.",
                        fontSize = 14.sp,
                        color = ChunkyColor.TextMuted,
                        textAlign = TextAlign.Center,
                        lineHeight = 18.sp
                    )
                }
            }
        }
    } else {
        Column(
            modifier = modifier
                .fillMaxSize()
                .background(ChunkyColor.WindowBackground)
        ) {
            OutlinedTextField(
                value = searchQuery,
                onValueChange = {
                    searchQuery = it
                    displayLimit = 30
                },
                placeholder = { Text("Tìm bài tập đã hoàn thành...", fontSize = 14.sp) },
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, tint = ChunkyColor.TextMuted) },
                trailingIcon = {
                    if (searchQuery.isNotEmpty()) {
                        IconButton(onClick = {
                            searchQuery = ""
                            displayLimit = 30
                        }) {
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
                    .padding(horizontal = 16.dp, vertical = 6.dp)
            )

            if (availableSubjectCategories.isNotEmpty()) {
                LazyRow(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 6.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    item(key = "all_subjects", contentType = "filter_chip") {
                        FilterChip(
                            selected = selectedSubjectCategory == null,
                            onClick = {
                                selectedSubjectCategory = null
                                displayLimit = 30
                            },
                            label = {
                                Text(
                                    text = "Tất cả",
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold
                                )
                            },
                            colors = FilterChipDefaults.filterChipColors(
                                containerColor = ChunkyColor.SurfaceWhite,
                                labelColor = ChunkyColor.TextPrimary,
                                selectedContainerColor = ChunkyColor.SkyBottom.copy(alpha = 0.14f),
                                selectedLabelColor = ChunkyColor.SkyBottom
                            ),
                            border = FilterChipDefaults.filterChipBorder(
                                borderColor = ChunkyColor.CardBorder,
                                selectedBorderColor = ChunkyColor.SkyBottom.copy(alpha = 0.6f),
                                borderWidth = 1.dp,
                                selectedBorderWidth = 1.dp,
                                enabled = true,
                                selected = selectedSubjectCategory == null
                            )
                        )
                    }
                    items(
                        items = availableSubjectCategories,
                        key = { it.name },
                        contentType = { "filter_chip" }
                    ) { cat ->
                        val themeColor = SubjectArtHelper.themeColor(cat)
                        val badge = SubjectArtHelper.badgeCode(cat, "", null)
                        val isSelected = selectedSubjectCategory == cat
                        FilterChip(
                            selected = isSelected,
                            onClick = {
                                selectedSubjectCategory = if (isSelected) null else cat
                                displayLimit = 30
                            },
                            label = {
                                Text(
                                    text = badge,
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.Bold
                                )
                            },
                            colors = FilterChipDefaults.filterChipColors(
                                containerColor = ChunkyColor.SurfaceWhite,
                                labelColor = themeColor,
                                selectedContainerColor = themeColor.copy(alpha = 0.14f),
                                selectedLabelColor = themeColor
                            ),
                            border = FilterChipDefaults.filterChipBorder(
                                borderColor = ChunkyColor.CardBorder,
                                selectedBorderColor = themeColor.copy(alpha = 0.6f),
                                borderWidth = 1.dp,
                                selectedBorderWidth = 1.dp,
                                enabled = true,
                                selected = isSelected
                            )
                        )
                    }
                }
            }

            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .background(ChunkyColor.WindowBackground),
                contentPadding = PaddingValues(start = 16.dp, top = 4.dp, end = 16.dp, bottom = 28.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                item(key = "header_completed", contentType = "section_header") {
                    SectionHeaderPill(
                        title = "ĐÃ HOÀN THÀNH",
                        count = filteredItems.size,
                        icon = Icons.Default.CheckCircle,
                        color = ChunkyColor.HeaderCompleted,
                        modifier = Modifier
                            .padding(bottom = 2.dp)
                            .animateItem(
                                fadeInSpec = ItemFadeSpring,
                                placementSpec = ItemPlacementSpring,
                                fadeOutSpec = ItemFadeSpring
                            )
                    )
                }

                if (filteredItems.isEmpty()) {
                    item(key = "empty_filter_result", contentType = "empty_state") {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 32.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Text(
                                    text = if (searchQuery.isNotEmpty()) "Không tìm thấy bài tập phù hợp" else "Không có bài tập đã hoàn thành cho môn này",
                                    fontSize = 14.sp,
                                    color = ChunkyColor.TextMuted
                                )
                                if (searchQuery.isNotEmpty() || selectedSubjectCategory != null) {
                                    Spacer(modifier = Modifier.height(8.dp))
                                    TextButton(onClick = {
                                        searchQuery = ""
                                        selectedSubjectCategory = null
                                    }) {
                                        Text("Xoá bộ lọc", color = ChunkyColor.SkyBottom, fontWeight = FontWeight.Bold)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    items(
                        items = displayedItems,
                        key = { it.id },
                        contentType = { "assignment_card" }
                    ) { item ->
                        val onToggle = remember(item.id) {
                            { completed: Boolean -> currentOnToggleCompletion(item.id, completed) }
                        }
                        val onClickCard = remember(item) {
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

                    if (filteredItems.size > displayLimit) {
                        item(key = "load_more_footer", contentType = "load_more") {
                            Column(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 12.dp),
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Text(
                                    text = "Đang hiển thị ${displayedItems.size}/${filteredItems.size} bài đã hoàn thành",
                                    fontSize = 12.sp,
                                    color = ChunkyColor.TextMuted,
                                    fontWeight = FontWeight.Medium
                                )
                                Spacer(modifier = Modifier.height(8.dp))
                                Row(
                                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    OutlinedButton(
                                        onClick = { displayLimit += 30 },
                                        shape = RoundedCornerShape(12.dp)
                                    ) {
                                        Icon(
                                            imageVector = Icons.Default.KeyboardArrowDown,
                                            contentDescription = null,
                                            modifier = Modifier.size(16.dp)
                                        )
                                        Spacer(modifier = Modifier.width(4.dp))
                                        Text("Xem thêm 30 bài cũ hơn", fontSize = 12.5.sp)
                                    }
                                    if (filteredItems.size > displayLimit + 30) {
                                        TextButton(
                                            onClick = { displayLimit = filteredItems.size }
                                        ) {
                                            Text("Xem tất cả", fontSize = 12.5.sp, color = ChunkyColor.SkyBottom)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
