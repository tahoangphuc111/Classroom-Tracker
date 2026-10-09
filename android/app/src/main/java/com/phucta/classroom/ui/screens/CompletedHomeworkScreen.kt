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
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
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
import com.phucta.classroom.ui.theme.ChunkyColor

@OptIn(androidx.compose.foundation.ExperimentalFoundationApi::class)
@Composable
fun CompletedHomeworkScreen(
    completedItems: List<Coursework>,
    onToggleCompletion: (String, Boolean) -> Unit,
    onSelectAssignment: (Coursework) -> Unit,
    modifier: Modifier = Modifier
) {
    if (completedItems.isEmpty()) {
        Box(
            modifier = modifier
                .fillMaxSize()
                .background(ChunkyColor.WindowBackground)
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
                    Spacer(modifier = Modifier.height(14.dp))
                    Text(
                        text = "Chưa có bài tập hoàn thành",
                        fontWeight = FontWeight.Bold,
                        fontSize = 16.sp,
                        color = ChunkyColor.TextPrimary
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Text(
                        text = "Chạm vào ô tròn bên cạnh bài tập ở danh sách Báo bài để đánh dấu hoàn thành.",
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
            modifier = modifier
                .fillMaxSize()
                .background(ChunkyColor.WindowBackground),
            contentPadding = PaddingValues(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            item {
                Text(
                    text = "ĐÃ HOÀN THÀNH (${completedItems.size})",
                    color = ChunkyColor.SuccessGreen,
                    fontWeight = FontWeight.Bold,
                    fontSize = 11.5.sp,
                    letterSpacing = 0.5.sp,
                    modifier = Modifier.padding(bottom = 4.dp)
                )
            }
            items(completedItems, key = { it.id }) { item ->
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
