package com.phucta.classroom.ui.screens

import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.ExperimentalFoundationApi
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
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Upcoming
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import com.phucta.classroom.ui.components.SectionHeaderPill
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.ui.components.AssignmentCard
import com.phucta.classroom.ui.components.EmberEmotion
import com.phucta.classroom.ui.components.EmberFlameCanvas
import com.phucta.classroom.ui.theme.ChunkyColor

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun TomorrowHomeworkScreen(
    tomorrowItems: List<Coursework>,
    onToggleCompletion: (String, Boolean) -> Unit,
    onSelectAssignment: (Coursework) -> Unit,
    modifier: Modifier = Modifier,
    courseworkIdsWithNotes: Set<String> = emptySet()
) {
    val incompleteCount = remember(tomorrowItems) { tomorrowItems.count { !it.isCompleted } }
    val isAllDone = remember(tomorrowItems, incompleteCount) { tomorrowItems.isNotEmpty() && incompleteCount == 0 }
    val hasTomorrowTasks = remember(tomorrowItems) { tomorrowItems.any { it.isDueTomorrow } }
    val hasTodayTasks = remember(tomorrowItems) { tomorrowItems.isNotEmpty() && tomorrowItems.all { it.isDueToday } }

    val totalCount = tomorrowItems.size
    val completedCount = totalCount - incompleteCount
    val progressFraction = if (totalCount > 0) completedCount.toFloat() / totalCount.toFloat() else 0f
    val animatedProgress by animateFloatAsState(
        targetValue = progressFraction,
        animationSpec = tween(durationMillis = 400, easing = FastOutSlowInEasing),
        label = "progressAnim"
    )

    val emotion = remember(tomorrowItems.isEmpty(), isAllDone, incompleteCount) {
        when {
            isAllDone -> EmberEmotion.CELEBRATING
            tomorrowItems.isEmpty() -> EmberEmotion.SLEEPING
            incompleteCount >= 3 -> EmberEmotion.STRESSED
            else -> EmberEmotion.NORMAL
        }
    }

    val emberTransition = rememberInfiniteTransition(label = "emberFloating")
    val emberFloatOffset = emberTransition.animateFloat(
        initialValue = -3f,
        targetValue = 3f,
        animationSpec = infiniteRepeatable(
            animation = tween(2400, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "emberFloat"
    )

    LazyColumn(
        modifier = modifier
            .fillMaxSize()
            .background(ChunkyColor.WindowBackground),
        contentPadding = PaddingValues(start = 16.dp, top = 16.dp, end = 16.dp, bottom = 28.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        item(key = "tomorrow_summary_card") {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(ChunkyColor.SkyGradient)
                    .padding(16.dp)
            ) {
                Column(modifier = Modifier.fillMaxWidth()) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        EmberFlameCanvas(
                            size = 72.dp,
                            emotion = emotion,
                            isUrgent = incompleteCount >= 3,
                            modifier = Modifier.graphicsLayer {
                                translationY = emberFloatOffset.value
                            }
                        )

                        Spacer(modifier = Modifier.width(16.dp))

                        Column(
                            modifier = Modifier.weight(1f)
                        ) {
                            if (tomorrowItems.isEmpty()) {
                                Text(
                                    text = "Ngày mai rảnh rồi!",
                                    color = Color.White,
                                    fontWeight = FontWeight.ExtraBold,
                                    fontSize = 20.sp
                                )
                                Spacer(modifier = Modifier.height(4.dp))
                                Text(
                                    text = "Không có bài tập cho ngày mai. Nghỉ ngơi nhé!",
                                    color = Color.White.copy(alpha = 0.95f),
                                    fontSize = 13.5.sp,
                                    lineHeight = 18.sp
                                )
                            } else if (isAllDone) {
                                val doneMessage = when {
                                    hasTomorrowTasks -> "Đã hoàn thành toàn bộ bài tập ngày mai."
                                    hasTodayTasks -> "Đã hoàn thành toàn bộ bài tập hôm nay."
                                    else -> "Đã hoàn thành toàn bộ bài tập sắp tới."
                                }
                                Text(
                                    text = "Xuất sắc! Đã xong hết",
                                    color = Color.White,
                                    fontWeight = FontWeight.ExtraBold,
                                    fontSize = 20.sp
                                )
                                Spacer(modifier = Modifier.height(4.dp))
                                Text(
                                    text = doneMessage,
                                    color = Color.White.copy(alpha = 0.95f),
                                    fontSize = 13.5.sp,
                                    lineHeight = 18.sp
                                )
                            } else {
                                val headerTitle = when {
                                    hasTomorrowTasks -> "Báo bài ngày mai"
                                    hasTodayTasks -> "Báo bài hôm nay"
                                    else -> "Báo bài sắp tới"
                                }
                                Text(
                                    text = headerTitle,
                                    color = Color.White,
                                    fontWeight = FontWeight.ExtraBold,
                                    fontSize = 20.sp
                                )
                                Spacer(modifier = Modifier.height(4.dp))
                                Text(
                                    text = "Còn $incompleteCount bài tập cần nộp.",
                                    color = Color.White.copy(alpha = 0.95f),
                                    fontSize = 13.5.sp,
                                    lineHeight = 18.sp
                                )
                            }
                        }
                    }

                    if (tomorrowItems.isNotEmpty()) {
                        Spacer(modifier = Modifier.height(14.dp))
                        Column(modifier = Modifier.fillMaxWidth()) {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(
                                    text = if (isAllDone) "Hoàn thành 100%! 🎉" else "Tiến độ: $completedCount/$totalCount bài tập",
                                    color = Color.White.copy(alpha = 0.95f),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 12.sp
                                )
                                Text(
                                    text = "${(progressFraction * 100).toInt()}%",
                                    color = Color.White.copy(alpha = 0.90f),
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 12.sp
                                )
                            }
                            Spacer(modifier = Modifier.height(6.dp))
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(6.dp)
                                    .clip(RoundedCornerShape(3.dp))
                                    .background(Color.White.copy(alpha = 0.25f))
                            ) {
                                if (animatedProgress > 0.001f) {
                                    Box(
                                        modifier = Modifier
                                            .fillMaxWidth(animatedProgress.coerceIn(0f, 1f))
                                            .height(6.dp)
                                            .clip(RoundedCornerShape(3.dp))
                                            .background(if (isAllDone) Color(0xFF6EE7B7) else Color.White)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }

        if (tomorrowItems.isEmpty()) {
            item(key = "empty_state_card") {
                Box(
                    modifier = Modifier
                        .animateItem(
                            fadeInSpec = spring(dampingRatio = 0.82f, stiffness = 380f),
                            placementSpec = spring(dampingRatio = 0.82f, stiffness = 380f),
                            fadeOutSpec = spring(dampingRatio = 0.82f, stiffness = 380f)
                        )
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(16.dp))
                        .background(ChunkyColor.SurfaceWhite)
                        .border(1.dp, ChunkyColor.CardBorder, RoundedCornerShape(16.dp))
                        .padding(vertical = 36.dp, horizontal = 24.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.CheckCircle,
                            contentDescription = null,
                            tint = ChunkyColor.SkyBottom,
                            modifier = Modifier.size(36.dp)
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "Không có bài tập ngày mai",
                            fontWeight = FontWeight.Bold,
                            fontSize = 17.sp,
                            color = ChunkyColor.TextPrimary
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Bạn có thể thư giãn hoặc tự ôn tập theo lịch riêng nhé!",
                            fontSize = 13.5.sp,
                            color = ChunkyColor.TextMuted,
                            textAlign = TextAlign.Center,
                            lineHeight = 18.sp
                        )
                    }
                }
            }
        } else {
            if (isAllDone) {
                item(key = "celebration_banner") {
                    val bannerText = when {
                        hasTomorrowTasks -> "Đã hoàn thành toàn bộ bài tập ngày mai!"
                        hasTodayTasks -> "Đã hoàn thành toàn bộ bài tập hôm nay!"
                        else -> "Đã hoàn thành toàn bộ bài tập sắp tới!"
                    }
                    Box(
                        modifier = Modifier
                            .animateItem(
                                fadeInSpec = spring(dampingRatio = 0.82f, stiffness = 380f),
                                placementSpec = spring(dampingRatio = 0.82f, stiffness = 380f),
                                fadeOutSpec = spring(dampingRatio = 0.82f, stiffness = 380f)
                            )
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(ChunkyColor.SuccessGreen.copy(alpha = 0.08f))
                            .border(1.dp, ChunkyColor.SuccessGreen.copy(alpha = 0.2f), RoundedCornerShape(12.dp))
                            .padding(horizontal = 14.dp, vertical = 10.dp)
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                imageVector = Icons.Default.CheckCircle,
                                contentDescription = null,
                                tint = ChunkyColor.SuccessGreen,
                                modifier = Modifier.size(20.dp)
                            )
                            Spacer(modifier = Modifier.width(10.dp))
                            Text(
                                text = bannerText,
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 14.sp,
                                color = ChunkyColor.SuccessGreen
                            )
                        }
                    }
                }
            }

            item(key = "section_header") {
                val (sectionTitle, sectionIcon, sectionColor) = when {
                    hasTomorrowTasks -> Triple("BÀI TẬP NGÀY MAI", Icons.Default.CalendarToday, ChunkyColor.HeaderTomorrow)
                    hasTodayTasks -> Triple("BÀI TẬP HÔM NAY", Icons.Default.Schedule, ChunkyColor.HeaderToday)
                    else -> Triple("BÀI TẬP SẮP TỚI", Icons.Default.Upcoming, ChunkyColor.HeaderTomorrow)
                }
                SectionHeaderPill(
                    title = sectionTitle,
                    count = tomorrowItems.size,
                    icon = sectionIcon,
                    color = sectionColor,
                    modifier = Modifier.animateItem(
                        fadeInSpec = spring(dampingRatio = 0.82f, stiffness = 380f),
                        placementSpec = spring(dampingRatio = 0.82f, stiffness = 380f),
                        fadeOutSpec = spring(dampingRatio = 0.82f, stiffness = 380f)
                    )
                )
            }

            items(tomorrowItems, key = { it.id }) { item ->
                AssignmentCard(
                    coursework = item,
                    hasNote = courseworkIdsWithNotes.contains(item.id),
                    onToggleCompletion = { completed -> onToggleCompletion(item.id, completed) },
                    onClick = { onSelectAssignment(item) },
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
