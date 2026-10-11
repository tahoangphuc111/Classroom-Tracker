package com.phucta.classroom.ui.components

import android.content.Intent
import android.net.Uri
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.OpenInBrowser
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.SheetState
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.ui.theme.ChunkyColor
import com.phucta.classroom.ui.theme.OutfitFontFamily

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeworkDetailBottomSheet(
    coursework: Coursework?,
    onDismiss: () -> Unit,
    onToggleCompletion: (String, Boolean) -> Unit,
    initialNoteContent: String? = null,
    onSaveNote: (String) -> Unit = {}
) {
    if (coursework == null) return
    val context = LocalContext.current
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = ChunkyColor.SurfaceWhite,
        shape = RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 20.dp)
                .padding(bottom = 32.dp)
                .verticalScroll(rememberScrollState())
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                SubjectBadgePill(
                    courseName = coursework.courseName,
                    title = coursework.title
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = coursework.courseName,
                    color = ChunkyColor.TextMuted,
                    fontWeight = FontWeight.Medium,
                    fontSize = 14.5.sp
                )
            }

            Spacer(modifier = Modifier.height(10.dp))

            Text(
                text = coursework.title,
                color = ChunkyColor.TextPrimary,
                fontWeight = FontWeight.Bold,
                fontSize = 20.5.sp,
                lineHeight = 26.sp
            )

            Spacer(modifier = Modifier.height(12.dp))

            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                DueDateBadge(
                    text = coursework.countdownBadgeString,
                    isCompleted = coursework.isCompleted,
                    isOverdue = coursework.isOverdue || coursework.isPast,
                    isDueToday = coursework.isDueToday,
                    isDueTomorrow = coursework.isDueTomorrow,
                    fontSize = 12.5.sp
                )

                if (coursework.maxPoints != null && coursework.maxPoints > 0.0) {
                    val pointsDisplay = if (coursework.maxPoints % 1.0 == 0.0) {
                        coursework.maxPoints.toInt().toString()
                    } else {
                        coursework.maxPoints.toString()
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(6.dp))
                            .background(ChunkyColor.NeutralBadgeBackground)
                            .border(1.dp, ChunkyColor.NeutralBadgeBorder, RoundedCornerShape(6.dp))
                            .padding(horizontal = 7.5.dp, vertical = 3.5.dp)
                    ) {
                        Text(
                            text = "Thang điểm: $pointsDisplay",
                            color = ChunkyColor.NeutralBadgeText,
                            fontFamily = OutfitFontFamily,
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 12.sp
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(6.dp))

            Text(
                text = coursework.formattedFullDueDate,
                color = ChunkyColor.TextMuted,
                fontSize = 13.5.sp
            )

            Spacer(modifier = Modifier.height(16.dp))
            HorizontalDivider(color = ChunkyColor.Hairline)
            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = "HƯỚNG DẪN BÀI TẬP",
                color = ChunkyColor.TextMuted,
                fontWeight = FontWeight.Bold,
                fontSize = 12.sp,
                letterSpacing = 0.5.sp
            )

            Spacer(modifier = Modifier.height(8.dp))

            val description = coursework.description
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(ChunkyColor.WindowBackground)
                    .padding(14.dp)
            ) {
                if (!description.isNullOrBlank()) {
                    Text(
                        text = description,
                        color = ChunkyColor.TextPrimary,
                        fontSize = 14.5.sp,
                        lineHeight = 21.sp
                    )
                } else {
                    Text(
                        text = "Không có mô tả chi tiết.",
                        color = ChunkyColor.TextMuted,
                        fontSize = 14.sp
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))
            HorizontalDivider(color = ChunkyColor.Hairline)
            Spacer(modifier = Modifier.height(16.dp))

            var isEditingNote by rememberSaveable { mutableStateOf(false) }
            var noteDraft by rememberSaveable(initialNoteContent) { mutableStateOf(initialNoteContent ?: "") }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "GHI CHÚ CỦA BẠN",
                    color = ChunkyColor.TextMuted,
                    fontWeight = FontWeight.Bold,
                    fontSize = 12.sp,
                    letterSpacing = 0.5.sp
                )

                if (!isEditingNote) {
                    TextButton(
                        onClick = { isEditingNote = true },
                        contentPadding = PaddingValues(horizontal = 6.dp, vertical = 2.dp)
                    ) {
                        Text(
                            text = if (initialNoteContent.isNullOrBlank()) "+ Thêm ghi chú" else "Chỉnh sửa",
                            color = ChunkyColor.SkyBottom,
                            fontSize = 12.5.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            if (isEditingNote) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(ChunkyColor.WindowBackground)
                        .padding(12.dp)
                ) {
                    OutlinedTextField(
                        value = noteDraft,
                        onValueChange = { noteDraft = it },
                        modifier = Modifier.fillMaxWidth(),
                        placeholder = { Text("Nhập lời dặn, lưu ý cho bài tập này...") },
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = ChunkyColor.SkyBottom,
                            unfocusedBorderColor = ChunkyColor.CardBorder
                        ),
                        shape = RoundedCornerShape(8.dp)
                    )

                    Spacer(modifier = Modifier.height(8.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.End
                    ) {
                        TextButton(onClick = {
                            isEditingNote = false
                            noteDraft = initialNoteContent ?: ""
                        }) {
                            Text("Huỷ", color = ChunkyColor.TextMuted)
                        }

                        Spacer(modifier = Modifier.width(8.dp))

                        Button(
                            onClick = {
                                onSaveNote(noteDraft)
                                isEditingNote = false
                            },
                            colors = ButtonDefaults.buttonColors(containerColor = ChunkyColor.SkyBottom),
                            shape = RoundedCornerShape(8.dp)
                        ) {
                            Text("Lưu", fontWeight = FontWeight.Bold)
                        }
                    }
                }
            } else if (!initialNoteContent.isNullOrBlank()) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(Color(0xFFFFF8E1))
                        .border(1.dp, Color(0xFFFFE082), RoundedCornerShape(12.dp))
                        .padding(14.dp)
                ) {
                    Text(
                        text = initialNoteContent,
                        color = Color(0xFF5D4037),
                        fontSize = 14.5.sp,
                        lineHeight = 21.sp
                    )
                }
            } else {
                Text(
                    text = "Chưa có ghi chú nào cho bài tập này.",
                    color = ChunkyColor.TextMuted,
                    fontSize = 13.5.sp,
                    modifier = Modifier.padding(vertical = 4.dp)
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Button(
                    onClick = {
                        onToggleCompletion(coursework.id, !coursework.isCompleted)
                    },
                    modifier = Modifier
                        .weight(1f)
                        .height(48.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = if (coursework.isCompleted) ChunkyColor.SuccessGreen else ChunkyColor.SkyBottom
                    ),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Icon(
                        imageVector = if (coursework.isCompleted) Icons.Default.CheckCircle else Icons.Outlined.CheckCircle,
                        contentDescription = null,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = if (coursework.isCompleted) "Đã làm xong" else "Đánh dấu đã nộp",
                        fontWeight = FontWeight.Bold,
                        fontSize = 14.5.sp,
                        maxLines = 1
                    )
                }

                Spacer(modifier = Modifier.width(10.dp))

                OutlinedButton(
                    onClick = {
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, Uri.parse(coursework.destinationURL)).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            context.startActivity(intent)
                        } catch (e: Exception) {
                            android.widget.Toast.makeText(
                                context,
                                "Không thể mở liên kết: ${e.localizedMessage ?: "Lỗi không xác định"}",
                                android.widget.Toast.LENGTH_SHORT
                            ).show()
                        }
                    },
                    modifier = Modifier.height(48.dp),
                    border = BorderStroke(1.dp, ChunkyColor.SkyBottom.copy(alpha = 0.5f)),
                    colors = ButtonDefaults.outlinedButtonColors(
                        containerColor = ChunkyColor.SkyBottom.copy(alpha = 0.08f),
                        contentColor = ChunkyColor.SkyBottom
                    ),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.OpenInBrowser,
                        contentDescription = "Mở trên Classroom",
                        tint = ChunkyColor.SkyBottom,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "Mở Classroom",
                        color = ChunkyColor.SkyBottom,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 14.sp
                    )
                }
            }
        }
    }
}
