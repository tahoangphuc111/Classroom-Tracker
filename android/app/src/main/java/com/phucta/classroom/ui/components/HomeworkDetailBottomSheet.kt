package com.phucta.classroom.ui.components

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.view.HapticFeedbackConstants
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.sizeIn
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Checklist
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.EditNote
import androidx.compose.material.icons.filled.Grade
import androidx.compose.material.icons.filled.OpenInBrowser
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
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
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.data.model.PersonalNote
import com.phucta.classroom.ui.theme.BeVietnamProFontFamily
import com.phucta.classroom.ui.theme.ChunkyColor

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeworkDetailBottomSheet(
    coursework: Coursework?,
    onDismiss: () -> Unit,
    onToggleCompletion: (String, Boolean) -> Unit,
    modifier: Modifier = Modifier,
    initialNoteContent: String? = null,
    attachedNote: PersonalNote? = null,
    onToggleChecklistItem: ((String, String) -> Unit)? = null,
    onEditNoteInNotes: ((PersonalNote) -> Unit)? = null,
    onSaveNote: (String) -> Unit = {}
) {
    if (coursework == null) return
    val context = LocalContext.current
    val view = androidx.compose.ui.platform.LocalView.current
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    val safeDismiss: () -> Unit = {
        try {
            onDismiss()
        } catch (_: Exception) {
        }
    }

    ModalBottomSheet(
        onDismissRequest = safeDismiss,
        sheetState = sheetState,
        containerColor = ChunkyColor.SurfaceWhite,
        shape = RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp),
        modifier = modifier
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .imePadding()
                .padding(horizontal = 20.dp)
                .padding(bottom = 32.dp)
                .verticalScroll(rememberScrollState())
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = coursework.courseName,
                    color = ChunkyColor.TextMuted,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 15.5.sp,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f, fill = false)
                )

                IconButton(
                    onClick = safeDismiss,
                    modifier = Modifier.size(48.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.Close,
                        contentDescription = "Đóng chi tiết bài tập",
                        tint = ChunkyColor.TextMuted
                    )
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            Text(
                text = coursework.title,
                color = ChunkyColor.TextPrimary,
                fontWeight = FontWeight.Bold,
                fontSize = 22.sp,
                lineHeight = 28.sp
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
                    fontSize = 13.sp
                )

                if (coursework.maxPoints != null && coursework.maxPoints > 0.0) {
                    val pointsDisplay = if (coursework.maxPoints % 1.0 == 0.0) {
                        coursework.maxPoints.toInt().toString()
                    } else {
                        coursework.maxPoints.toString()
                    }
                    Spacer(modifier = Modifier.width(8.dp))
                    Row(
                        modifier = Modifier
                            .clip(RoundedCornerShape(8.dp))
                            .background(ChunkyColor.NeutralBadgeBackground)
                            .border(1.dp, ChunkyColor.NeutralBadgeBorder, RoundedCornerShape(8.dp))
                            .padding(horizontal = 8.dp, vertical = 4.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Default.Grade,
                            contentDescription = null,
                            tint = ChunkyColor.NeutralBadgeText,
                            modifier = Modifier.size(14.dp)
                        )
                        Text(
                            text = "Thang điểm: $pointsDisplay",
                            color = ChunkyColor.NeutralBadgeText,
                            fontFamily = BeVietnamProFontFamily,
                            fontWeight = FontWeight.Bold,
                            fontSize = 13.sp
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.CalendarToday,
                    contentDescription = null,
                    tint = ChunkyColor.TextMuted,
                    modifier = Modifier.size(15.dp)
                )
                Text(
                    text = coursework.formattedFullDueDate,
                    color = ChunkyColor.TextMuted,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 14.5.sp
                )
            }

            Spacer(modifier = Modifier.height(14.dp))

            val detailEmotion = when {
                coursework.isCompleted -> EmberEmotion.CELEBRATING
                coursework.isUrgent -> EmberEmotion.STRESSED
                else -> EmberEmotion.STUDYING
            }

            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(
                        when {
                            coursework.isCompleted -> Color(0xFFF0FDF4)
                            coursework.isUrgent -> Color(0xFFFEF2F2)
                            else -> ChunkyColor.WindowBackground
                        }
                    )
                    .border(
                        1.dp,
                        when {
                            coursework.isCompleted -> Color(0xFFBBF7D0)
                            coursework.isUrgent -> Color(0xFFFECACA)
                            else -> ChunkyColor.CardBorder
                        },
                        RoundedCornerShape(14.dp)
                    )
                    .padding(horizontal = 16.dp, vertical = 12.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(14.dp)
                ) {
                    EmberFlameCanvas(
                        size = 50.dp,
                        emotion = detailEmotion
                    )
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = when {
                                coursework.isCompleted -> "Đã làm xong bài!"
                                coursework.isUrgent -> "Sắp tới hạn nộp rồi"
                                else -> "Cùng làm bài nào"
                            },
                            fontWeight = FontWeight.Bold,
                            fontSize = 15.5.sp,
                            color = ChunkyColor.TextPrimary
                        )
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(
                            text = when {
                                coursework.isCompleted -> "Bài đã được đánh dấu hoàn thành."
                                coursework.isUrgent -> "Ưu tiên bài này trước để nộp cho kịp nhé."
                                else -> "Đọc kỹ yêu cầu bên dưới rồi tick dần từng việc."
                            },
                            fontSize = 13.5.sp,
                            color = ChunkyColor.TextMuted,
                            lineHeight = 18.sp
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))
            HorizontalDivider(color = ChunkyColor.Hairline)
            Spacer(modifier = Modifier.height(16.dp))

            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Description,
                    contentDescription = null,
                    tint = ChunkyColor.TextLink,
                    modifier = Modifier.size(16.dp)
                )
                Text(
                    text = "HƯỚNG DẪN BÀI TẬP",
                    color = ChunkyColor.TextPrimary,
                    fontWeight = FontWeight.Bold,
                    fontSize = 13.5.sp,
                    letterSpacing = 0.5.sp
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            val description = coursework.description
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(ChunkyColor.WindowBackground)
                    .padding(16.dp)
            ) {
                if (!description.isNullOrBlank()) {
                    Text(
                        text = description,
                        color = ChunkyColor.TextPrimary,
                        fontSize = 15.5.sp,
                        lineHeight = 23.sp
                    )
                } else {
                    Text(
                        text = "Không có mô tả chi tiết.",
                        color = ChunkyColor.TextMuted,
                        fontSize = 15.sp
                    )
                }
            }

            if (attachedNote != null && attachedNote.checklist.isNotEmpty()) {
                Spacer(modifier = Modifier.height(16.dp))
                HorizontalDivider(color = ChunkyColor.Hairline)
                Spacer(modifier = Modifier.height(16.dp))

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Icon(
                            imageVector = Icons.Default.Checklist,
                            contentDescription = null,
                            tint = ChunkyColor.SuccessGreen,
                            modifier = Modifier.size(17.dp)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = "DANH SÁCH CẦN LÀM (CHECKLIST)",
                            color = ChunkyColor.TextPrimary,
                            fontWeight = FontWeight.Bold,
                            fontSize = 13.5.sp,
                            letterSpacing = 0.5.sp
                        )
                    }

                    Text(
                        text = "${attachedNote.completedChecklistCount}/${attachedNote.totalChecklistCount}",
                        color = ChunkyColor.TextMuted,
                        fontWeight = FontWeight.Bold,
                        fontSize = 13.sp
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))

                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(ChunkyColor.WindowBackground)
                        .padding(12.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    attachedNote.checklist.forEach { item ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(8.dp))
                                .clickable {
                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                                        view.performHapticFeedback(HapticFeedbackConstants.CONFIRM)
                                    } else {
                                        view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
                                    }
                                    onToggleChecklistItem?.invoke(attachedNote.id, item.id)
                                }
                                .padding(vertical = 4.dp, horizontal = 4.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            if (item.isCompleted) {
                                Icon(
                                    imageVector = Icons.Default.CheckCircle,
                                    contentDescription = null,
                                    tint = ChunkyColor.SuccessGreen,
                                    modifier = Modifier.size(19.dp)
                                )
                            } else {
                                Box(
                                    modifier = Modifier
                                        .size(19.dp)
                                        .border(1.5.dp, ChunkyColor.TextMuted.copy(alpha = 0.5f), CircleShape)
                                )
                            }
                            Spacer(modifier = Modifier.width(10.dp))
                            Text(
                                text = item.title,
                                color = if (item.isCompleted) ChunkyColor.TextMuted else ChunkyColor.TextPrimary,
                                fontSize = 15.sp,
                                textDecoration = if (item.isCompleted) TextDecoration.LineThrough else null,
                                modifier = Modifier.weight(1f)
                            )
                        }
                    }

                    if (attachedNote.totalChecklistCount > 0 && attachedNote.isCompleted && !coursework.isCompleted) {
                        Spacer(modifier = Modifier.height(4.dp))
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(10.dp))
                                .background(ChunkyColor.SuccessGreen.copy(alpha = 0.12f))
                                .padding(horizontal = 12.dp, vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Row(
                                modifier = Modifier.weight(1f),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(
                                    imageVector = Icons.Default.CheckCircle,
                                    contentDescription = null,
                                    tint = ChunkyColor.SuccessGreen,
                                    modifier = Modifier.size(19.dp)
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Column {
                                    Text(
                                        text = "Các mục việc con đã xong",
                                        fontWeight = FontWeight.Bold,
                                        fontSize = 13.5.sp,
                                        color = ChunkyColor.TextPrimary
                                    )
                                    Text(
                                        text = "Đánh dấu bài tập này hoàn thành?",
                                        fontSize = 12.sp,
                                        color = ChunkyColor.TextMuted
                                    )
                                }
                            }
                            Button(
                                onClick = {
                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                                        view.performHapticFeedback(HapticFeedbackConstants.CONFIRM)
                                    } else {
                                        view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
                                    }
                                    onToggleCompletion(coursework.id, true)
                                },
                                colors = ButtonDefaults.buttonColors(containerColor = ChunkyColor.SuccessGreen),
                                shape = RoundedCornerShape(8.dp),
                                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp),
                                modifier = Modifier.height(34.dp)
                            ) {
                                Text("Xong bài", fontSize = 13.sp, fontWeight = FontWeight.Bold, color = Color.White)
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))
            HorizontalDivider(color = ChunkyColor.Hairline)
            Spacer(modifier = Modifier.height(16.dp))

            var isEditingNote by rememberSaveable(coursework.id) { mutableStateOf(false) }
            var noteDraft by rememberSaveable(coursework.id, initialNoteContent) { mutableStateOf(initialNoteContent ?: "") }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Icon(
                        imageVector = Icons.Default.EditNote,
                        contentDescription = null,
                        tint = ChunkyColor.TextLink,
                        modifier = Modifier.size(18.dp)
                    )
                    Text(
                        text = "GHI CHÚ CỦA BẠN",
                        color = ChunkyColor.TextPrimary,
                        fontWeight = FontWeight.Bold,
                        fontSize = 13.5.sp,
                        letterSpacing = 0.5.sp
                    )
                }

                Row(verticalAlignment = Alignment.CenterVertically) {
                    if (attachedNote != null && onEditNoteInNotes != null) {
                        TextButton(
                            onClick = {
                                safeDismiss()
                                onEditNoteInNotes(attachedNote)
                            },
                            modifier = Modifier.heightIn(min = 48.dp),
                            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.Edit,
                                contentDescription = null,
                                tint = ChunkyColor.TextLink,
                                modifier = Modifier.size(15.dp)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = "Mở trong Ghi chú",
                                color = ChunkyColor.TextLink,
                                fontSize = 13.sp,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }

                    if (!isEditingNote) {
                        TextButton(
                            onClick = { isEditingNote = true },
                            modifier = Modifier.heightIn(min = 48.dp),
                            contentPadding = PaddingValues(horizontal = 8.dp, vertical = 4.dp)
                        ) {
                            Text(
                                text = if (initialNoteContent.isNullOrBlank()) "+ Thêm ghi chú" else "Chỉnh sửa",
                                color = ChunkyColor.TextLink,
                                fontSize = 13.sp,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
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
                        TextButton(
                            onClick = {
                                isEditingNote = false
                                noteDraft = initialNoteContent ?: ""
                            },
                            modifier = Modifier.heightIn(min = 48.dp)
                        ) {
                            Text("Huỷ", color = ChunkyColor.TextMuted)
                        }

                        Spacer(modifier = Modifier.width(8.dp))

                        Button(
                            onClick = {
                                onSaveNote(noteDraft)
                                isEditingNote = false
                            },
                            modifier = Modifier.heightIn(min = 48.dp),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = ChunkyColor.SkyBottom,
                                contentColor = Color.White
                            ),
                            shape = RoundedCornerShape(8.dp)
                        ) {
                            Text("Lưu", fontWeight = FontWeight.Bold, color = Color.White)
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
                        .padding(16.dp)
                ) {
                    Text(
                        text = initialNoteContent,
                        color = Color(0xFF5D4037),
                        fontSize = 15.5.sp,
                        lineHeight = 23.sp
                    )
                }
            } else if (attachedNote != null && attachedNote.checklist.isNotEmpty()) {
                Text(
                    text = "Chưa có ghi chú bổ sung (đang có ${attachedNote.checklist.size} việc cần làm ở trên).",
                    color = ChunkyColor.TextMuted,
                    fontSize = 14.sp,
                    modifier = Modifier.padding(vertical = 4.dp)
                )
            } else {
                Text(
                    text = "Chưa có ghi chú nào cho bài tập này.",
                    color = ChunkyColor.TextMuted,
                    fontSize = 15.sp,
                    modifier = Modifier.padding(vertical = 4.dp)
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            val onCopyClick: () -> Unit = {
                try {
                    val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as? android.content.ClipboardManager
                    val clipText = buildString {
                        append(coursework.title)
                        append(" - ")
                        append(coursework.courseName)
                        if (coursework.dueEpochMillis != null) {
                            append("\nHạn nộp: ")
                            append(coursework.formattedFullDueDate)
                        }
                        if (!coursework.description.isNullOrBlank()) {
                            append("\n\n")
                            append(coursework.description)
                        }
                        if (!coursework.alternateLink.isNullOrBlank()) {
                            append("\n\nLink: ")
                            append(coursework.alternateLink)
                        }
                    }
                    val clip = android.content.ClipData.newPlainText("Bài tập", clipText)
                    clipboard?.setPrimaryClip(clip)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        view.performHapticFeedback(HapticFeedbackConstants.CONFIRM)
                    } else {
                        view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
                    }
                    android.widget.Toast.makeText(context, "Đã sao chép thông tin bài tập", android.widget.Toast.LENGTH_SHORT).show()
                } catch (e: Exception) {
                    android.widget.Toast.makeText(
                        context,
                        "Không thể sao chép thông tin bài tập",
                        android.widget.Toast.LENGTH_SHORT
                    ).show()
                }
            }

            val onOpenBrowserClick: () -> Unit = {
                try {
                    view.performHapticFeedback(HapticFeedbackConstants.CONTEXT_CLICK)
                    val targetUrl = coursework.alternateLink?.takeIf { it.isNotBlank() } ?: coursework.destinationURL
                    val intent = Intent(Intent.ACTION_VIEW, Uri.parse(targetUrl)).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    context.startActivity(intent)
                } catch (e: Exception) {
                    android.widget.Toast.makeText(
                        context,
                        "Không thể mở trình duyệt",
                        android.widget.Toast.LENGTH_SHORT
                    ).show()
                }
            }

            BoxWithConstraints(modifier = Modifier.fillMaxWidth()) {
                val isNarrow = maxWidth < 360.dp
                if (isNarrow) {
                    Column(
                        modifier = Modifier.fillMaxWidth(),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Button(
                            onClick = {
                                val next = !coursework.isCompleted
                                if (next) {
                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                                        view.performHapticFeedback(HapticFeedbackConstants.CONFIRM)
                                    } else {
                                        view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
                                    }
                                } else {
                                    view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK)
                                }
                                onToggleCompletion(coursework.id, next)
                            },
                            modifier = Modifier
                                .fillMaxWidth()
                                .heightIn(min = 50.dp),
                            contentPadding = PaddingValues(horizontal = 16.dp, vertical = 12.dp),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = if (coursework.isCompleted) ChunkyColor.SuccessGreen else ChunkyColor.SkyBottom,
                                contentColor = Color.White
                            ),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Icon(
                                imageVector = if (coursework.isCompleted) Icons.Default.CheckCircle else Icons.Outlined.CheckCircle,
                                contentDescription = null,
                                tint = Color.White,
                                modifier = Modifier.size(19.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = if (coursework.isCompleted) "Đã làm xong" else "Đánh dấu đã nộp",
                                fontWeight = FontWeight.Bold,
                                fontSize = 15.sp,
                                color = Color.White,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        }

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            OutlinedButton(
                                onClick = onCopyClick,
                                modifier = Modifier
                                    .weight(1f)
                                    .heightIn(min = 50.dp),
                                border = BorderStroke(1.dp, ChunkyColor.CardBorder),
                                colors = ButtonDefaults.outlinedButtonColors(
                                    containerColor = ChunkyColor.SurfaceWhite,
                                    contentColor = ChunkyColor.TextPrimary
                                ),
                                shape = RoundedCornerShape(12.dp),
                                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 12.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.ContentCopy,
                                    contentDescription = "Sao chép",
                                    tint = ChunkyColor.TextPrimary,
                                    modifier = Modifier.size(19.dp)
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = "Sao chép",
                                    color = ChunkyColor.TextPrimary,
                                    fontWeight = FontWeight.SemiBold,
                                    fontSize = 15.sp,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                            }

                            OutlinedButton(
                                onClick = onOpenBrowserClick,
                                modifier = Modifier
                                    .weight(1f)
                                    .heightIn(min = 50.dp),
                                border = BorderStroke(1.dp, ChunkyColor.TextLink.copy(alpha = 0.5f)),
                                colors = ButtonDefaults.outlinedButtonColors(
                                    containerColor = ChunkyColor.TomorrowBackground,
                                    contentColor = ChunkyColor.TextLink
                                ),
                                shape = RoundedCornerShape(12.dp),
                                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 12.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.OpenInBrowser,
                                    contentDescription = "Mở trên Classroom",
                                    tint = ChunkyColor.TextLink,
                                    modifier = Modifier.size(19.dp)
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = "Mở link",
                                    color = ChunkyColor.TextLink,
                                    fontWeight = FontWeight.SemiBold,
                                    fontSize = 15.sp,
                                    maxLines = 1,
                                    overflow = TextOverflow.Ellipsis
                                )
                            }
                        }
                    }
                } else {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Button(
                            onClick = {
                                val next = !coursework.isCompleted
                                if (next) {
                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                                        view.performHapticFeedback(HapticFeedbackConstants.CONFIRM)
                                    } else {
                                        view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
                                    }
                                } else {
                                    view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK)
                                }
                                onToggleCompletion(coursework.id, next)
                            },
                            modifier = Modifier
                                .weight(1f)
                                .heightIn(min = 50.dp),
                            contentPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = if (coursework.isCompleted) ChunkyColor.SuccessGreen else ChunkyColor.SkyBottom,
                                contentColor = Color.White
                            ),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Icon(
                                imageVector = if (coursework.isCompleted) Icons.Default.CheckCircle else Icons.Outlined.CheckCircle,
                                contentDescription = null,
                                tint = Color.White,
                                modifier = Modifier.size(19.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = if (coursework.isCompleted) "Đã làm xong" else "Đánh dấu đã nộp",
                                fontWeight = FontWeight.Bold,
                                fontSize = 15.sp,
                                color = Color.White,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        }

                        Spacer(modifier = Modifier.width(8.dp))

                        OutlinedButton(
                            onClick = onCopyClick,
                            modifier = Modifier.sizeIn(minWidth = 50.dp, minHeight = 50.dp),
                            border = BorderStroke(1.dp, ChunkyColor.CardBorder),
                            colors = ButtonDefaults.outlinedButtonColors(
                                containerColor = ChunkyColor.SurfaceWhite,
                                contentColor = ChunkyColor.TextPrimary
                            ),
                            shape = RoundedCornerShape(12.dp),
                            contentPadding = PaddingValues(horizontal = 12.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.ContentCopy,
                                contentDescription = "Sao chép thông tin bài tập",
                                tint = ChunkyColor.TextPrimary,
                                modifier = Modifier.size(19.dp)
                            )
                        }

                        Spacer(modifier = Modifier.width(8.dp))

                        OutlinedButton(
                            onClick = onOpenBrowserClick,
                            modifier = Modifier.sizeIn(minWidth = 50.dp, minHeight = 50.dp),
                            border = BorderStroke(1.dp, ChunkyColor.TextLink.copy(alpha = 0.5f)),
                            colors = ButtonDefaults.outlinedButtonColors(
                                containerColor = ChunkyColor.TomorrowBackground,
                                contentColor = ChunkyColor.TextLink
                            ),
                            shape = RoundedCornerShape(12.dp),
                            contentPadding = PaddingValues(horizontal = 16.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.OpenInBrowser,
                                contentDescription = "Mở trên Classroom",
                                tint = ChunkyColor.TextLink,
                                modifier = Modifier.size(19.dp)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = "Mở",
                                color = ChunkyColor.TextLink,
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 15.sp
                            )
                        }
                    }
                }
            }
        }
    }
}
