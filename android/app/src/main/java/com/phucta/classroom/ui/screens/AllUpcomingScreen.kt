package com.phucta.classroom.ui.screens

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
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
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

@OptIn(androidx.compose.foundation.ExperimentalFoundationApi::class)
@Composable
fun AllUpcomingScreen(
    allCoursework: List<Coursework>,
    courses: List<Course>,
    onToggleCompletion: (String, Boolean) -> Unit,
    onSelectAssignment: (Coursework) -> Unit,
    modifier: Modifier = Modifier
) {
    var searchQuery by remember { mutableStateOf("") }
    val normalizedQuery = remember(searchQuery) { searchQuery.normalizeForVietnameseSearch() }

    val filteredItems = remember(allCoursework, normalizedQuery) {
        if (normalizedQuery.isBlank()) {
            allCoursework
        } else {
            allCoursework.filter { it.searchIndex.contains(normalizedQuery) }
        }
    }

    val buckets = remember(filteredItems, courses) {
        BaoBaiBucketingUtils.computeBuckets(filteredItems, courses)
    }

    Column(
        modifier = modifier
            .fillMaxSize()
            .background(ChunkyColor.WindowBackground)
    ) {
        // Search Bar
        OutlinedTextField(
            value = searchQuery,
            onValueChange = { searchQuery = it },
            placeholder = { Text("Tìm kiếm bài tập, môn học...", fontSize = 13.5.sp) },
            leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, tint = ChunkyColor.TextMuted) },
            trailingIcon = {
                if (searchQuery.isNotEmpty()) {
                    IconButton(onClick = { searchQuery = "" }) {
                        Icon(Icons.Default.Clear, contentDescription = "Clear", tint = ChunkyColor.TextMuted)
                    }
                }
            },
            singleLine = true,
            shape = RoundedCornerShape(12.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedContainerColor = ChunkyColor.SurfaceWhite,
                unfocusedContainerColor = ChunkyColor.SurfaceWhite,
                focusedBorderColor = ChunkyColor.SkyBottom,
                unfocusedBorderColor = ChunkyColor.CardBorder
            ),
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 10.dp)
        )

        val hasAnyUpcoming = buckets.overdue.isNotEmpty() ||
                buckets.today.isNotEmpty() ||
                buckets.tomorrow.isNotEmpty() ||
                buckets.laterUpcoming.isNotEmpty() ||
                buckets.noDueDate.isNotEmpty()

        if (filteredItems.isEmpty()) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(20.dp),
                contentAlignment = Alignment.Center
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(16.dp))
                        .background(ChunkyColor.SurfaceWhite)
                        .border(1.dp, ChunkyColor.CardBorder, RoundedCornerShape(16.dp))
                        .padding(horizontal = 24.dp, vertical = 36.dp),
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
        } else if (!hasAnyUpcoming) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(20.dp),
                contentAlignment = Alignment.Center
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(16.dp))
                        .background(ChunkyColor.SurfaceWhite)
                        .border(1.dp, ChunkyColor.CardBorder, RoundedCornerShape(16.dp))
                        .padding(horizontal = 24.dp, vertical = 36.dp),
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
                            text = "Không có bài tập cần nộp!",
                            fontWeight = FontWeight.Bold,
                            fontSize = 16.sp,
                            color = ChunkyColor.TextPrimary
                        )
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(
                            text = "Tất cả bài tập đã được đánh dấu hoàn thành xuất sắc ✦",
                            fontSize = 13.sp,
                            color = ChunkyColor.TextMuted,
                            textAlign = TextAlign.Center,
                            lineHeight = 18.sp
                        )
                    }
                }
            }
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 6.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                // Overdue section
                if (buckets.overdue.isNotEmpty()) {
                    item {
                        SectionHeader(title = "QUÁ HẠN (${buckets.overdue.size})", color = ChunkyColor.UrgentAccent)
                    }
                    items(buckets.overdue, key = { it.id }) { item ->
                        AssignmentCard(
                            coursework = item,
                            onToggleCompletion = { onToggleCompletion(item.id, it) },
                            onClick = { onSelectAssignment(item) },
                            modifier = Modifier.animateItemPlacement(
                                animationSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f)
                            )
                        )
                    }
                    item { Spacer(modifier = Modifier.height(6.dp)) }
                }

                // Today section
                if (buckets.today.isNotEmpty()) {
                    item {
                        SectionHeader(title = "HÔM NAY (${buckets.today.size})", color = ChunkyColor.EmberTop)
                    }
                    items(buckets.today, key = { it.id }) { item ->
                        AssignmentCard(
                            coursework = item,
                            onToggleCompletion = { onToggleCompletion(item.id, it) },
                            onClick = { onSelectAssignment(item) },
                            modifier = Modifier.animateItemPlacement(
                                animationSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f)
                            )
                        )
                    }
                    item { Spacer(modifier = Modifier.height(6.dp)) }
                }

                // Tomorrow section
                if (buckets.tomorrow.isNotEmpty()) {
                    item {
                        SectionHeader(title = "NGÀY MAI (${buckets.tomorrow.size})", color = ChunkyColor.SkyBottom)
                    }
                    items(buckets.tomorrow, key = { it.id }) { item ->
                        AssignmentCard(
                            coursework = item,
                            onToggleCompletion = { onToggleCompletion(item.id, it) },
                            onClick = { onSelectAssignment(item) },
                            modifier = Modifier.animateItemPlacement(
                                animationSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f)
                            )
                        )
                    }
                    item { Spacer(modifier = Modifier.height(6.dp)) }
                }

                // Later upcoming
                if (buckets.laterUpcoming.isNotEmpty()) {
                    item {
                        SectionHeader(title = "SẮP TỚI (${buckets.laterUpcoming.size})", color = ChunkyColor.TextMuted)
                    }
                    items(buckets.laterUpcoming, key = { it.id }) { item ->
                        AssignmentCard(
                            coursework = item,
                            onToggleCompletion = { onToggleCompletion(item.id, it) },
                            onClick = { onSelectAssignment(item) },
                            modifier = Modifier.animateItemPlacement(
                                animationSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f)
                            )
                        )
                    }
                    item { Spacer(modifier = Modifier.height(6.dp)) }
                }

                // No due date
                if (buckets.noDueDate.isNotEmpty()) {
                    item {
                        SectionHeader(title = "KHÔNG CÓ HẠN (${buckets.noDueDate.size})", color = ChunkyColor.TextMuted)
                    }
                    items(buckets.noDueDate, key = { it.id }) { item ->
                        AssignmentCard(
                            coursework = item,
                            onToggleCompletion = { onToggleCompletion(item.id, it) },
                            onClick = { onSelectAssignment(item) },
                            modifier = Modifier.animateItemPlacement(
                                animationSpec = androidx.compose.animation.core.spring(dampingRatio = 0.82f, stiffness = 380f)
                            )
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun SectionHeader(title: String, color: androidx.compose.ui.graphics.Color) {
    Text(
        text = title,
        color = color,
        fontWeight = FontWeight.Bold,
        fontSize = 11.5.sp,
        letterSpacing = 0.5.sp,
        modifier = Modifier.padding(top = 4.dp, bottom = 2.dp)
    )
}
