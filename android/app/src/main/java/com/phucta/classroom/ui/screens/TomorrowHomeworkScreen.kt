package com.phucta.classroom.ui.screens

import androidx.compose.foundation.background
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
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.ui.components.AssignmentCard
import com.phucta.classroom.ui.components.EmberEmotion
import com.phucta.classroom.ui.components.EmberFlameCanvas
import com.phucta.classroom.ui.theme.ChunkyColor

@Composable
fun TomorrowHomeworkScreen(
    tomorrowItems: List<Coursework>,
    onToggleCompletion: (String, Boolean) -> Unit,
    onSelectAssignment: (Coursework) -> Unit,
    modifier: Modifier = Modifier
) {
    val incompleteCount = tomorrowItems.count { !it.isCompleted }
    val isAllDone = tomorrowItems.isNotEmpty() && incompleteCount == 0

    val emotion = when {
        tomorrowItems.isEmpty() || isAllDone -> EmberEmotion.SLEEPING
        incompleteCount >= 3 -> EmberEmotion.STRESSED
        else -> EmberEmotion.NORMAL
    }

    LazyColumn(
        modifier = modifier
            .fillMaxSize()
            .background(ChunkyColor.WindowBackground),
        contentPadding = PaddingValues(16.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp)
    ) {
        // Hero Banner with Ember Flame
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
                        size = 76.dp,
                        emotion = emotion,
                        isUrgent = incompleteCount >= 3
                    )

                    Spacer(modifier = Modifier.width(16.dp))

                    Column {
                        if (tomorrowItems.isEmpty()) {
                            Text(
                                text = "Ngày mai rảnh rồi!",
                                color = Color.White,
                                fontWeight = FontWeight.ExtraBold,
                                fontSize = 18.sp
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = "Không có bài tập nào cần chuẩn bị cho ngày mai. Nghỉ ngơi nhé ✦",
                                color = Color.White.copy(alpha = 0.9f),
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
                                text = "Tất cả bài tập ngày mai đã được giải quyết xong xuôi ✦",
                                color = Color.White.copy(alpha = 0.9f),
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
                                color = Color.White.copy(alpha = 0.9f),
                                fontSize = 12.5.sp,
                                lineHeight = 17.sp
                            )
                        }
                    }
                }
            }
        }

        // Section Title
        if (tomorrowItems.isNotEmpty()) {
            item {
                Text(
                    text = "DANH SÁCH BÀI TẬP",
                    color = ChunkyColor.TextMuted,
                    fontWeight = FontWeight.Bold,
                    fontSize = 11.5.sp,
                    letterSpacing = 0.5.sp,
                    modifier = Modifier.padding(top = 6.dp, bottom = 2.dp)
                )
            }

            items(tomorrowItems, key = { it.id }) { item ->
                AssignmentCard(
                    coursework = item,
                    onToggleCompletion = { completed -> onToggleCompletion(item.id, completed) },
                    onClick = { onSelectAssignment(item) }
                )
            }
        }
    }
}
