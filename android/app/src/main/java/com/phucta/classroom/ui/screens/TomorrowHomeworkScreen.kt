package com.phucta.classroom.ui.screens

import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
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
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
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
    modifier: Modifier = Modifier
) {
    val incompleteCount = remember(tomorrowItems) { tomorrowItems.count { !it.isCompleted } }
    val isAllDone = remember(tomorrowItems, incompleteCount) { tomorrowItems.isNotEmpty() && incompleteCount == 0 }

    val emotion = remember(tomorrowItems.isEmpty(), isAllDone, incompleteCount) {
        when {
            isAllDone -> EmberEmotion.CELEBRATING
            tomorrowItems.isEmpty() -> EmberEmotion.SLEEPING
            incompleteCount >= 3 -> EmberEmotion.STRESSED
            else -> EmberEmotion.NORMAL
        }
    }

    val emberTransition = rememberInfiniteTransition(label = "emberFloating")
    val emberFloatOffset by emberTransition.animateFloat(
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
        item {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(ChunkyColor.SkyGradient)
                    .padding(16.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    EmberFlameCanvas(
                        size = 72.dp,
                        emotion = emotion,
                        isUrgent = incompleteCount >= 3,
                        modifier = Modifier.graphicsLayer {
                            translationY = emberFloatOffset
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
                                fontSize = 18.sp
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "Không có bài tập nào cần chuẩn bị cho ngày mai. Nghỉ ngơi nhé.",
                                color = Color.White.copy(alpha = 0.95f),
                                fontSize = 12.5.sp,
                                lineHeight = 17.sp
                            )
                        } else if (isAllDone) {
                            Text(
                                text = "Xuất sắc! Đã hoàn thành!",
                                color = Color.White,
                                fontWeight = FontWeight.ExtraBold,
                                fontSize = 18.sp
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "Tất cả bài tập ngày mai đã được giải quyết xong xuôi.",
                                color = Color.White.copy(alpha = 0.95f),
                                fontSize = 12.5.sp,
                                lineHeight = 17.sp
                            )
                        } else {
                            Text(
                                text = "Báo bài Ngày mai",
                                color = Color.White,
                                fontWeight = FontWeight.ExtraBold,
                                fontSize = 18.sp
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "Còn $incompleteCount bài tập cần chuẩn bị trước khi đến lớp.",
                                color = Color.White.copy(alpha = 0.95f),
                                fontSize = 12.5.sp,
                                lineHeight = 17.sp
                            )
                        }
                    }
                }
            }
        }

        if (tomorrowItems.isEmpty()) {
            item {
                Box(
                    modifier = Modifier
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
                            fontSize = 15.5.sp,
                            color = ChunkyColor.TextPrimary
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Bạn có thể dành thời gian thư giãn hoặc tự ôn tập theo lịch riêng nhé!",
                            fontSize = 12.5.sp,
                            color = ChunkyColor.TextMuted,
                            textAlign = TextAlign.Center,
                            lineHeight = 17.sp
                        )
                    }
                }
            }
        } else {
            if (isAllDone) {
                item {
                    Box(
                        modifier = Modifier
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
                                text = "Bạn đã hoàn thành tất cả bài tập cho ngày mai!",
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 13.sp,
                                color = ChunkyColor.SuccessGreen
                            )
                        }
                    }
                }
            }

            item {
                Text(
                    text = "DANH SÁCH BÀI TẬP",
                    color = ChunkyColor.TextMuted,
                    fontWeight = FontWeight.Bold,
                    fontSize = 11.5.sp,
                    letterSpacing = 0.5.sp,
                    modifier = Modifier.padding(top = 4.dp, bottom = 2.dp)
                )
            }

            items(tomorrowItems, key = { it.id }) { item ->
                AssignmentCard(
                    coursework = item,
                    onToggleCompletion = { completed -> onToggleCompletion(item.id, completed) },
                    onClick = { onSelectAssignment(item) },
                    modifier = Modifier.animateItemPlacement(
                        animationSpec = spring(
                            dampingRatio = 0.82f,
                            stiffness = 380f
                        )
                    )
                )
            }
        }
    }
}
