package com.phucta.classroom.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.animation.core.spring
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextAlign
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.ui.components.AssignmentCard
import com.phucta.classroom.ui.components.SectionHeaderPill
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
        LazyColumn(
            modifier = modifier
                .fillMaxSize()
                .background(ChunkyColor.WindowBackground),
            contentPadding = PaddingValues(start = 16.dp, top = 16.dp, end = 16.dp, bottom = 28.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            item(key = "header_completed", contentType = "section_header") {
                SectionHeaderPill(
                    title = "ĐÃ HOÀN THÀNH",
                    count = completedItems.size,
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
            items(
                items = completedItems,
                key = { it.id },
                contentType = { "assignment_card" }
            ) { item ->
                val currentItem by rememberUpdatedState(item)
                val currentOnToggleCompletion by rememberUpdatedState(onToggleCompletion)
                val currentOnSelectAssignment by rememberUpdatedState(onSelectAssignment)
                val onToggle = remember(item.id) {
                    { completed: Boolean -> currentOnToggleCompletion(item.id, completed) }
                }
                val onClickCard = remember(item.id) {
                    { currentOnSelectAssignment(currentItem) }
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
