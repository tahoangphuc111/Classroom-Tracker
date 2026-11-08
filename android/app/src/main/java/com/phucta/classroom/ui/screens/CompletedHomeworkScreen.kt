package com.phucta.classroom.ui.screens

import androidx.activity.compose.BackHandler
import androidx.compose.animation.core.spring
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
import androidx.compose.ui.graphics.Color
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.Search
import androidx.compose.ui.res.painterResource
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
import com.phucta.classroom.ui.components.EmberEmotion
import com.phucta.classroom.ui.components.EmberFlameCanvas
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
    var searchQuery by rememberSaveable { mutableStateOf("") }
    val keyboardController = LocalSoftwareKeyboardController.current
    val normalizedQuery = remember(searchQuery) { searchQuery.normalizeForVietnameseSearch() }
    val searchTokens = remember(normalizedQuery) {
        tokenizeSearchQuery(normalizedQuery)
    }

    val filteredItems = remember(completedItems, searchTokens) {
        if (searchTokens.isEmpty()) {
            completedItems
        } else {
            completedItems.filter { item ->
                for (token in searchTokens) {
                    if (!item.searchIndex.contains(token)) return@filter false
                }
                true
            }
        }
    }

    var displayLimit by remember(searchQuery) { mutableIntStateOf(30) }
    val displayedItems = remember(filteredItems, displayLimit) {
        filteredItems.take(displayLimit)
    }

    BackHandler(enabled = searchQuery.isNotEmpty()) {
        searchQuery = ""
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
                    EmberFlameCanvas(
                        size = 80.dp,
                        emotion = EmberEmotion.STUDYING
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "Chưa có bài nào xong",
                        fontWeight = FontWeight.Bold,
                        fontSize = 19.sp,
                        color = ChunkyColor.TextPrimary
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "Các bài bạn đánh dấu hoàn thành sẽ nằm ở đây.",
                        fontSize = 15.sp,
                        color = ChunkyColor.TextMuted,
                        textAlign = TextAlign.Center,
                        lineHeight = 20.sp
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
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 6.dp)
                    .clip(RoundedCornerShape(14.dp))
                    .background(ChunkyColor.CompletedBadgeBackground)
                    .border(1.dp, ChunkyColor.CompletedBadgeBorder, RoundedCornerShape(14.dp))
                    .padding(horizontal = 16.dp, vertical = 12.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    EmberFlameCanvas(
                        size = 50.dp,
                        emotion = EmberEmotion.CELEBRATING
                    )
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "Đã làm xong ${completedItems.size} bài tập",
                            fontWeight = FontWeight.Bold,
                            fontSize = 15.5.sp,
                            color = ChunkyColor.CompletedBadgeText
                        )
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(
                            text = "Tất cả các bài bạn đã nộp hoặc đánh dấu xong.",
                            fontSize = 13.5.sp,
                            color = ChunkyColor.TextMuted
                        )
                    }
                }
            }

            OutlinedTextField(
                value = searchQuery,
                onValueChange = {
                    searchQuery = it
                    displayLimit = 30
                },
                placeholder = { Text("Tìm bài tập đã hoàn thành...", fontSize = 15.sp) },
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

            if (searchQuery.isNotBlank()) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 2.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Tìm thấy ${filteredItems.size} bài tập đã xong",
                        fontSize = 13.5.sp,
                        color = ChunkyColor.TextMuted,
                        fontWeight = FontWeight.SemiBold
                    )
                    TextButton(
                        onClick = {
                            searchQuery = ""
                            displayLimit = 30
                        },
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
                                EmberFlameCanvas(
                                    size = 56.dp,
                                    emotion = EmberEmotion.NORMAL
                                )
                                Spacer(modifier = Modifier.height(12.dp))
                                Text(
                                    text = if (searchQuery.isNotEmpty()) "Không tìm thấy bài tập" else "Chưa có bài tập hoàn thành",
                                    fontSize = 14.sp,
                                    color = ChunkyColor.TextMuted
                                )
                                if (searchQuery.isNotEmpty()) {
                                    Spacer(modifier = Modifier.height(8.dp))
                                    TextButton(onClick = { searchQuery = "" }) {
                                        Text("Xoá tìm kiếm", color = ChunkyColor.TextLink, fontWeight = FontWeight.Bold)
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
                                    fontWeight = FontWeight.SemiBold
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
                                            Text("Xem tất cả", fontSize = 12.5.sp, color = ChunkyColor.TextLink)
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
