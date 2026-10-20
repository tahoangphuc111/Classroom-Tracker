package com.phucta.classroom.ui.screens

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.ui.draw.clip
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.HelpOutline
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Upcoming
import androidx.compose.material.icons.filled.Warning
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
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.phucta.classroom.data.model.Course
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.data.model.normalizeForVietnameseSearch
import com.phucta.classroom.domain.BaoBaiBucketingUtils
import com.phucta.classroom.ui.components.AssignmentCard
import com.phucta.classroom.ui.theme.ChunkyColor

import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.text.input.ImeAction

@OptIn(androidx.compose.foundation.ExperimentalFoundationApi::class)
@Composable
fun AllUpcomingScreen(
    allCoursework: List<Coursework>,
    courses: List<Course>,
    onToggleCompletion: (String, Boolean) -> Unit,
    onSelectAssignment: (Coursework) -> Unit,
    modifier: Modifier = Modifier,
    courseworkIdsWithNotes: Set<String> = emptySet()
) {
    var searchQuery by rememberSaveable { mutableStateOf("") }
    var selectedSubjectCategory by rememberSaveable { mutableStateOf<String?>(null) }
    val normalizedQuery = remember(searchQuery) { searchQuery.normalizeForVietnameseSearch() }
    val keyboardController = LocalSoftwareKeyboardController.current

    val selectedSubjectCategoryDisplayName = remember(selectedSubjectCategory) {
        selectedSubjectCategory?.let { name ->
            try {
                when (SubjectCategory.valueOf(name)) {
                    SubjectCategory.MATH -> "Toán"
                    SubjectCategory.PHYSICS -> "Vật lý"
                    SubjectCategory.CHEMISTRY -> "Hóa học"
                    SubjectCategory.BIOLOGY -> "Sinh học"
                    SubjectCategory.HISTORY_OR_GEOGRAPHY -> "Lịch sử - Địa lý"
                    SubjectCategory.LITERATURE -> "Ngữ văn"
                    SubjectCategory.ENGLISH -> "Tiếng Anh"
                    SubjectCategory.CIVICS_OR_PHILOSOPHY -> "GDCD"
                    SubjectCategory.ECONOMICS -> "Kinh tế"
                    SubjectCategory.ART_AND_DESIGN -> "Thiết kế"
                    SubjectCategory.COMPUTER_SCIENCE -> "Tin học"
                    SubjectCategory.NETWORKING -> "Mạng máy tính"
                    SubjectCategory.GENERAL_ASSIGNMENT -> "Bài tập chung"
                    SubjectCategory.OTHER -> "Khác"
                }
            } catch (_: Exception) {
                name
            }
        }
    }

    val activeCoursework = remember(allCoursework, courses) {
        BaoBaiBucketingUtils.filterByActiveCourses(allCoursework, courses)
    }

    val availableSubjectCategories = remember(activeCoursework) {
        activeCoursework.map { SubjectArtHelper.category(it.courseName, it.title) }
            .filter { it != SubjectCategory.OTHER }
            .distinct()
            .sortedBy { it.name }
    }

    val searchTokens = remember(normalizedQuery) {
        normalizedQuery.split("\\s+".toRegex()).filter { it.isNotBlank() }
    }

    val filteredItems = remember(activeCoursework, searchTokens, selectedSubjectCategory) {
        var items = activeCoursework
        if (selectedSubjectCategory != null) {
            items = items.filter { SubjectArtHelper.category(it.courseName, it.title).name == selectedSubjectCategory }
        }
        if (searchTokens.isNotEmpty()) {
            items = items.filter { item ->
                searchTokens.all { token -> item.searchIndex.contains(token) }
            }
        }
        items
    }

    val buckets = remember(filteredItems, searchTokens, normalizedQuery) {
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
            placeholder = { Text("Tìm bài tập...", fontSize = 14.5.sp) },
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
                .padding(start = 16.dp, end = 16.dp, top = 10.dp, bottom = 6.dp)
        )

        if (availableSubjectCategories.isNotEmpty()) {
            LazyRow(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 6.dp),
                contentPadding = PaddingValues(horizontal = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                item {
                    FilterChip(
                        selected = selectedSubjectCategory == null,
                        onClick = { selectedSubjectCategory = null },
                        label = { Text("Tất cả", fontSize = 12.5.sp, fontWeight = FontWeight.SemiBold) },
                        colors = FilterChipDefaults.filterChipColors(
                            containerColor = ChunkyColor.SurfaceWhite,
                            labelColor = ChunkyColor.TextPrimary,
                            selectedContainerColor = ChunkyColor.SkyBottom.copy(alpha = 0.14f),
                            selectedLabelColor = ChunkyColor.SkyBottom
                        ),
                        border = FilterChipDefaults.filterChipBorder(
                            borderColor = ChunkyColor.CardBorder,
                            selectedBorderColor = ChunkyColor.SkyBottom.copy(alpha = 0.5f),
                            borderWidth = 1.dp,
                            selectedBorderWidth = 1.dp,
                            enabled = true,
                            selected = selectedSubjectCategory == null
                        )
                    )
                }
                items(availableSubjectCategories, key = { it.name }) { cat ->
                    val themeColor = SubjectArtHelper.themeColor(cat)
                    val badge = SubjectArtHelper.badgeCode(cat, "", null)
                    val isSelected = selectedSubjectCategory == cat.name
                    FilterChip(
                        selected = isSelected,
                        onClick = {
                            selectedSubjectCategory = if (isSelected) null else cat.name
                        },
                        label = {
                            Text(
                                text = badge,
                                fontSize = 12.5.sp,
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

        val hasAnyUpcoming = buckets.overdue.isNotEmpty() ||
                buckets.today.isNotEmpty() ||
                buckets.tomorrow.isNotEmpty() ||
                buckets.laterUpcoming.isNotEmpty() ||
                buckets.noDueDate.isNotEmpty()

        val hasAnyCompletedMatches = searchQuery.isNotBlank() && buckets.completed.isNotEmpty()

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
                        Box(
                            modifier = Modifier
                                .size(56.dp)
                                .clip(androidx.compose.foundation.shape.CircleShape)
                                .background(ChunkyColor.SkyBottom.copy(alpha = 0.1f)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Default.Search,
                                contentDescription = null,
                                tint = ChunkyColor.SkyBottom,
                                modifier = Modifier.size(28.dp)
                            )
                        }
                        Spacer(modifier = Modifier.height(14.dp))
                        if (selectedSubjectCategory != null) {
                            Text(
                                text = "Không có bài tập môn $selectedSubjectCategoryDisplayName",
                                fontWeight = FontWeight.Bold,
                                fontSize = 16.sp,
                                color = ChunkyColor.TextPrimary,
                                textAlign = TextAlign.Center
                            )
                            Spacer(modifier = Modifier.height(6.dp))
                            Text(
                                text = if (searchQuery.isNotBlank()) {
                                    "Không có bài tập nào môn $selectedSubjectCategoryDisplayName khớp với từ khóa \"$searchQuery\"."
                                } else {
                                    "Danh sách bài tập sắp tới của môn này hiện đang trống."
                                },
                                fontSize = 13.sp,
                                color = ChunkyColor.TextMuted,
                                textAlign = TextAlign.Center,
                                lineHeight = 18.sp
                            )
                            Spacer(modifier = Modifier.height(14.dp))
                            OutlinedButton(
                                onClick = { selectedSubjectCategory = null },
                                shape = RoundedCornerShape(10.dp),
                                border = BorderStroke(1.dp, ChunkyColor.SkyBottom.copy(alpha = 0.6f)),
                                colors = ButtonDefaults.outlinedButtonColors(
                                    contentColor = ChunkyColor.SkyBottom
                                )
                            ) {
                                Text(
                                    text = "Xoá bộ lọc môn",
                                    fontWeight = FontWeight.SemiBold,
                                    fontSize = 13.5.sp
                                )
                            }
                        } else {
                            Text(
                                text = if (searchQuery.isNotBlank()) "Không tìm thấy bài tập" else "Chưa có bài tập nào",
                                fontWeight = FontWeight.Bold,
                                fontSize = 16.sp,
                                color = ChunkyColor.TextPrimary
                            )
                            Spacer(modifier = Modifier.height(6.dp))
                            Text(
                                text = if (searchQuery.isNotBlank()) {
                                    "Không có bài tập nào khớp với từ khóa \"$searchQuery\"."
                                } else {
                                    "Danh sách bài tập sắp tới hiện đang trống."
                                },
                                fontSize = 13.sp,
                                color = ChunkyColor.TextMuted,
                                textAlign = TextAlign.Center,
                                lineHeight = 18.sp
                            )
                        }
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
                        Box(
                            modifier = Modifier
                                .size(56.dp)
                                .clip(androidx.compose.foundation.shape.CircleShape)
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
                        Spacer(modifier = Modifier.height(14.dp))
                        Text(
                            text = if (selectedSubjectCategory != null) "Không có bài tập môn $selectedSubjectCategoryDisplayName cần nộp!" else "Không có bài tập cần nộp!",
                            fontWeight = FontWeight.Bold,
                            fontSize = 16.sp,
                            color = ChunkyColor.TextPrimary,
                            textAlign = TextAlign.Center
                        )
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(
                            text = if (selectedSubjectCategory != null) {
                                "Tất cả bài tập môn $selectedSubjectCategoryDisplayName đã được đánh dấu hoàn thành xuất sắc."
                            } else {
                                "Tất cả bài tập đã được đánh dấu hoàn thành xuất sắc."
                            },
                            fontSize = 13.sp,
                            color = ChunkyColor.TextMuted,
                            textAlign = TextAlign.Center,
                            lineHeight = 18.sp
                        )
                        if (selectedSubjectCategory != null) {
                            Spacer(modifier = Modifier.height(14.dp))
                            OutlinedButton(
                                onClick = { selectedSubjectCategory = null },
                                shape = RoundedCornerShape(10.dp),
                                border = BorderStroke(1.dp, ChunkyColor.SkyBottom.copy(alpha = 0.6f)),
                                colors = ButtonDefaults.outlinedButtonColors(
                                    contentColor = ChunkyColor.SkyBottom
                                )
                            ) {
                                Text(
                                    text = "Xoá bộ lọc môn",
                                    fontWeight = FontWeight.SemiBold,
                                    fontSize = 13.5.sp
                                )
                            }
                        }
                    }
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(start = 16.dp, top = 6.dp, end = 16.dp, bottom = 28.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                if (buckets.overdue.isNotEmpty()) {
                    item(key = "header_overdue") {
                        SectionHeaderPill(
                            title = "QUÁ HẠN",
                            count = buckets.overdue.size,
                            icon = Icons.Default.Warning,
                            color = ChunkyColor.HeaderOverdue,
                            modifier = Modifier.animateItem(
                                fadeInSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f),
                                placementSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f),
                                fadeOutSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f)
                            )
                        )
                    }
                    items(buckets.overdue, key = { it.id }) { item ->
                        AssignmentCard(
                            coursework = item,
                            hasNote = courseworkIdsWithNotes.contains(item.id),
                            onToggleCompletion = { onToggleCompletion(item.id, it) },
                            onClick = { onSelectAssignment(item) },
                            modifier = Modifier.animateItem(
                                fadeInSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f),
                                placementSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f),
                                fadeOutSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f)
                            )
                        )
                    }
                    item(key = "spacer_overdue") { Spacer(modifier = Modifier.height(6.dp)) }
                }

                if (buckets.today.isNotEmpty()) {
                    item(key = "header_today") {
                        SectionHeaderPill(
                            title = "HÔM NAY",
                            count = buckets.today.size,
                            icon = Icons.Default.Schedule,
                            color = ChunkyColor.HeaderToday,
                            modifier = Modifier.animateItem(
                                fadeInSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f),
                                placementSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f),
                                fadeOutSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f)
                            )
                        )
                    }
                    items(buckets.today, key = { it.id }) { item ->
                        AssignmentCard(
                            coursework = item,
                            hasNote = courseworkIdsWithNotes.contains(item.id),
                            onToggleCompletion = { onToggleCompletion(item.id, it) },
                            onClick = { onSelectAssignment(item) },
                            modifier = Modifier.animateItem(
                                fadeInSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f),
                                placementSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f),
                                fadeOutSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f)
                            )
                        )
                    }
                    item(key = "spacer_today") { Spacer(modifier = Modifier.height(6.dp)) }
                }

                if (buckets.tomorrow.isNotEmpty()) {
                    item(key = "header_tomorrow") {
                        SectionHeaderPill(
                            title = "NGÀY MAI",
                            count = buckets.tomorrow.size,
                            icon = Icons.Default.CalendarToday,
                            color = ChunkyColor.HeaderTomorrow,
                            modifier = Modifier.animateItem(
                                fadeInSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f),
                                placementSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f),
                                fadeOutSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f)
                            )
                        )
                    }
                    items(buckets.tomorrow, key = { it.id }) { item ->
                        AssignmentCard(
                            coursework = item,
                            hasNote = courseworkIdsWithNotes.contains(item.id),
                            onToggleCompletion = { onToggleCompletion(item.id, it) },
                            onClick = { onSelectAssignment(item) },
                            modifier = Modifier.animateItem(
                                fadeInSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f),
                                placementSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f),
                                fadeOutSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f)
                            )
                        )
                    }
                    item(key = "spacer_tomorrow") { Spacer(modifier = Modifier.height(6.dp)) }
                }

                if (buckets.laterUpcoming.isNotEmpty()) {
                    item(key = "header_later") {
                        SectionHeaderPill(
                            title = "SẮP TỚI",
                            count = buckets.laterUpcoming.size,
                            icon = Icons.Default.Upcoming,
                            color = ChunkyColor.HeaderUpcoming,
                            modifier = Modifier.animateItem(
                                fadeInSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f),
                                placementSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f),
                                fadeOutSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f)
                            )
                        )
                    }
                    items(buckets.laterUpcoming, key = { it.id }) { item ->
                        AssignmentCard(
                            coursework = item,
                            hasNote = courseworkIdsWithNotes.contains(item.id),
                            onToggleCompletion = { onToggleCompletion(item.id, it) },
                            onClick = { onSelectAssignment(item) },
                            modifier = Modifier.animateItem(
                                fadeInSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f),
                                placementSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f),
                                fadeOutSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f)
                            )
                        )
                    }
                    item(key = "spacer_later") { Spacer(modifier = Modifier.height(6.dp)) }
                }

                if (buckets.noDueDate.isNotEmpty()) {
                    item(key = "header_no_due_date") {
                        SectionHeaderPill(
                            title = "KHÔNG CÓ HẠN",
                            count = buckets.noDueDate.size,
                            icon = Icons.AutoMirrored.Filled.HelpOutline,
                            color = ChunkyColor.HeaderUpcoming,
                            modifier = Modifier.animateItem(
                                fadeInSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f),
                                placementSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f),
                                fadeOutSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f)
                            )
                        )
                    }
                    items(buckets.noDueDate, key = { it.id }) { item ->
                        AssignmentCard(
                            coursework = item,
                            hasNote = courseworkIdsWithNotes.contains(item.id),
                            onToggleCompletion = { onToggleCompletion(item.id, it) },
                            onClick = { onSelectAssignment(item) },
                            modifier = Modifier.animateItem(
                                fadeInSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f),
                                placementSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f),
                                fadeOutSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f)
                            )
                        )
                    }
                }

                if (searchQuery.isNotBlank() && buckets.completed.isNotEmpty()) {
                    item(key = "header_completed") {
                        Spacer(modifier = Modifier.height(6.dp))
                        SectionHeaderPill(
                            title = "ĐÃ HOÀN THÀNH",
                            count = buckets.completed.size,
                            icon = Icons.Default.CheckCircle,
                            color = ChunkyColor.HeaderCompleted,
                            modifier = Modifier.animateItem(
                                fadeInSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f),
                                placementSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f),
                                fadeOutSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f)
                            )
                        )
                    }
                    items(buckets.completed, key = { it.id }) { item ->
                        AssignmentCard(
                            coursework = item,
                            hasNote = courseworkIdsWithNotes.contains(item.id),
                            onToggleCompletion = { onToggleCompletion(item.id, it) },
                            onClick = { onSelectAssignment(item) },
                            modifier = Modifier.animateItem(
                                fadeInSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f),
                                placementSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f),
                                fadeOutSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f)
                            )
                        )
                    }
                }
            }
        }
    }
}
