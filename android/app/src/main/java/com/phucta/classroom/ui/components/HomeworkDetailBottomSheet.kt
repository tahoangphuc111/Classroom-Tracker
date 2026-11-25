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
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Checklist
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Description
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.EditNote
import androidx.compose.material.icons.filled.Grade
import androidx.compose.material.icons.filled.OpenInBrowser
import androidx.compose.ui.text.LinkAnnotation
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextLinkStyles
import androidx.compose.ui.text.buildAnnotatedString
import java.util.regex.Pattern
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.consumeWindowInsets
import androidx.compose.foundation.layout.ime
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
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
import androidx.compose.ui.platform.LocalDensity
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

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
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

    val colorScheme = MaterialTheme.colorScheme

    ModalBottomSheet(
        onDismissRequest = safeDismiss,
        sheetState = sheetState,
        containerColor = colorScheme.surfaceContainerLow,
        shape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp),
        modifier = modifier
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()

                .imePadding()
                .consumeWindowInsets(WindowInsets.ime)
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
                    color = colorScheme.onSurfaceVariant,
                    style = MaterialTheme.typography.titleSmall,
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
                        tint = colorScheme.onSurfaceVariant
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = coursework.title,
                color = colorScheme.onSurface,
                style = MaterialTheme.typography.headlineSmall
            )

            Spacer(modifier = Modifier.height(12.dp))

            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                DueDateBadge(
                    text = coursework.countdownBadgeString,
                    isCompleted = coursework.isCompleted,

                    isOverdue = !coursework.isCompleted && (coursework.isOverdue || coursework.isPast),
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
                    tint = colorScheme.onSurfaceVariant,
                    modifier = Modifier.size(15.dp)
                )
                Text(
                    text = coursework.conciseDueString,
                    color = colorScheme.onSurfaceVariant,
                    style = MaterialTheme.typography.bodyMedium,
                    maxLines = 1
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
                            coursework.isCompleted -> ChunkyColor.CompletedBadgeBackground
                            coursework.isUrgent -> colorScheme.errorContainer
                            else -> colorScheme.surfaceContainerLowest
                        }
                    )
                    .border(
                        1.dp,
                        when {
                            coursework.isCompleted -> ChunkyColor.CompletedBadgeBorder
                            coursework.isUrgent -> colorScheme.error.copy(alpha = 0.3f)
                            else -> colorScheme.outlineVariant
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
                            style = MaterialTheme.typography.titleMedium,
                            color = when {
                                coursework.isCompleted -> ChunkyColor.CompletedBadgeText
                                coursework.isUrgent -> colorScheme.onErrorContainer
                                else -> colorScheme.onSurface
                            }
                        )
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(
                            text = when {
                                coursework.isCompleted -> "Bài đã được đánh dấu hoàn thành."
                                coursework.isUrgent -> "Ưu tiên bài này trước để nộp cho kịp nhé."
                                else -> "Đọc kỹ yêu cầu bên dưới rồi tick dần từng việc."
                            },
                            style = MaterialTheme.typography.bodyMedium,
                            color = when {
                                coursework.isCompleted -> ChunkyColor.CompletedBadgeText.copy(alpha = 0.85f)
                                coursework.isUrgent -> colorScheme.onErrorContainer.copy(alpha = 0.85f)
                                else -> colorScheme.onSurfaceVariant
                            }
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))
            HorizontalDivider(color = colorScheme.outlineVariant)
            Spacer(modifier = Modifier.height(16.dp))

            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Icon(
                    imageVector = Icons.Default.Description,
                    contentDescription = null,
                    tint = colorScheme.primary,
                    modifier = Modifier.size(16.dp)
                )
                Text(
                    text = "HƯỚNG DẪN BÀI TẬP",
                    color = colorScheme.onSurface,
                    style = MaterialTheme.typography.labelLarge,
                    letterSpacing = 0.5.sp
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            val description = coursework.description
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(colorScheme.surfaceContainerLowest)
                    .border(1.dp, colorScheme.outlineVariant, RoundedCornerShape(12.dp))
                    .padding(16.dp)
            ) {
                if (!description.isNullOrBlank()) {
                    Text(
                        text = buildClickableUrlString(description, colorScheme.primary),
                        color = colorScheme.onSurface,
                        style = MaterialTheme.typography.bodyLarge
                    )
                } else {
                    Text(
                        text = "Không có mô tả chi tiết.",
                        color = colorScheme.onSurfaceVariant,
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }

            if (attachedNote != null && attachedNote.checklist.isNotEmpty()) {
                Spacer(modifier = Modifier.height(16.dp))
                HorizontalDivider(color = colorScheme.outlineVariant)
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
                            color = colorScheme.onSurface,
                            style = MaterialTheme.typography.labelLarge,
                            letterSpacing = 0.5.sp
                        )
                    }

                    Text(
                        text = "${attachedNote.completedChecklistCount}/${attachedNote.totalChecklistCount}",
                        color = colorScheme.onSurfaceVariant,
                        style = MaterialTheme.typography.labelMedium
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))

                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(colorScheme.surfaceContainerLowest)
                        .border(1.dp, colorScheme.outlineVariant, RoundedCornerShape(12.dp))
                        .padding(horizontal = 12.dp, vertical = 6.dp),
                    verticalArrangement = Arrangement.spacedBy(2.dp)
                ) {
                    attachedNote.checklist.forEach { item ->
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .heightIn(min = 48.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .clickable {
                                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                                        view.performHapticFeedback(HapticFeedbackConstants.CONFIRM)
                                    } else {
                                        view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
                                    }
                                    onToggleChecklistItem?.invoke(attachedNote.id, item.id)
                                }
                                .padding(vertical = 8.dp, horizontal = 6.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            if (item.isCompleted) {
                                Icon(
                                    imageVector = Icons.Default.CheckCircle,
                                    contentDescription = null,
                                    tint = ChunkyColor.SuccessGreen,
                                    modifier = Modifier.size(20.dp)
                                )
                            } else {
                                Box(
                                    modifier = Modifier
                                        .size(20.dp)
                                        .border(1.5.dp, colorScheme.onSurfaceVariant.copy(alpha = 0.5f), CircleShape)
                                )
                            }
                            Spacer(modifier = Modifier.width(10.dp))
                            Text(
                                text = item.title,
                                color = if (item.isCompleted) colorScheme.onSurfaceVariant else colorScheme.onSurface,
                                style = MaterialTheme.typography.bodyLarge,
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
                                        style = MaterialTheme.typography.labelMedium,
                                        color = colorScheme.onSurface
                                    )
                                    Text(
                                        text = "Đánh dấu bài tập này hoàn thành?",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = colorScheme.onSurfaceVariant
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
                                shape = RoundedCornerShape(10.dp),
                                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp),
                                modifier = Modifier.heightIn(min = 48.dp)
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                                ) {
                                    Icon(
                                        imageVector = Icons.Default.Check,
                                        contentDescription = null,
                                        tint = Color.White,
                                        modifier = Modifier.size(16.dp)
                                    )
                                    Text("Xong", style = MaterialTheme.typography.labelMedium, color = Color.White)
                                }
                            }
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))
            HorizontalDivider(color = colorScheme.outlineVariant)
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
                        tint = colorScheme.primary,
                        modifier = Modifier.size(18.dp)
                    )
                    Text(
                        text = "GHI CHÚ CỦA BẠN",
                        color = colorScheme.onSurface,
                        style = MaterialTheme.typography.labelLarge,
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
                                tint = colorScheme.primary,
                                modifier = Modifier.size(15.dp)
                            )
                            Spacer(modifier = Modifier.width(4.dp))
                            Text(
                                text = "Mở trong Ghi chú",
                                color = colorScheme.primary,
                                style = MaterialTheme.typography.labelMedium
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
                                color = colorScheme.primary,
                                style = MaterialTheme.typography.labelMedium
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
                        .background(colorScheme.surfaceContainerLowest)
                        .border(1.dp, colorScheme.outlineVariant, RoundedCornerShape(12.dp))
                        .padding(12.dp)
                ) {
                    OutlinedTextField(
                        value = noteDraft,
                        onValueChange = { noteDraft = it },
                        modifier = Modifier.fillMaxWidth(),
                        placeholder = { Text("Nhập lời dặn, lưu ý cho bài tập này...") },
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = colorScheme.primary,
                            unfocusedBorderColor = colorScheme.outlineVariant
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
                            Text("Hủy", color = colorScheme.onSurfaceVariant)
                        }

                        Spacer(modifier = Modifier.width(8.dp))

                        Button(
                            onClick = {
                                onSaveNote(noteDraft)
                                isEditingNote = false
                            },
                            modifier = Modifier.heightIn(min = 48.dp),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = colorScheme.primary,
                                contentColor = colorScheme.onPrimary
                            ),
                            shape = RoundedCornerShape(10.dp)
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
                        .background(colorScheme.tertiaryContainer)
                        .border(1.dp, colorScheme.tertiary.copy(alpha = 0.25f), RoundedCornerShape(12.dp))
                        .padding(16.dp)
                ) {
                    Text(
                        text = initialNoteContent,
                        color = colorScheme.onTertiaryContainer,
                        style = MaterialTheme.typography.bodyLarge
                    )
                }
            } else if (attachedNote != null && attachedNote.checklist.isNotEmpty()) {
                Text(
                    text = "Chưa có ghi chú bổ sung (đang có ${attachedNote.checklist.size} việc cần làm ở trên).",
                    color = colorScheme.onSurfaceVariant,
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.padding(vertical = 4.dp)
                )
            } else {
                Text(
                    text = "Chưa có ghi chú nào cho bài tập này.",
                    color = colorScheme.onSurfaceVariant,
                    style = MaterialTheme.typography.bodyMedium,
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
                val isNarrow = maxWidth < 540.dp * maxOf(1f, LocalDensity.current.fontScale)
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
                                containerColor = if (coursework.isCompleted) ChunkyColor.SuccessGreen else colorScheme.primary,
                                contentColor = if (coursework.isCompleted) Color.White else colorScheme.onPrimary
                            ),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Icon(
                                imageVector = if (coursework.isCompleted) Icons.Default.CheckCircle else Icons.Outlined.CheckCircle,
                                contentDescription = null,
                                modifier = Modifier.size(19.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = if (coursework.isCompleted) "Đã làm xong" else "Đánh dấu đã nộp",
                                fontWeight = FontWeight.Bold,
                                fontSize = 15.sp,
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
                                border = BorderStroke(1.dp, colorScheme.outlineVariant),
                                colors = ButtonDefaults.outlinedButtonColors(
                                    containerColor = colorScheme.surfaceContainerLowest,
                                    contentColor = colorScheme.onSurface
                                ),
                                shape = RoundedCornerShape(12.dp),
                                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 12.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.ContentCopy,
                                    contentDescription = null,
                                    modifier = Modifier.size(19.dp)
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = "Sao chép",
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
                                border = BorderStroke(1.dp, colorScheme.primary.copy(alpha = 0.4f)),
                                colors = ButtonDefaults.outlinedButtonColors(
                                    containerColor = colorScheme.primaryContainer,
                                    contentColor = colorScheme.onPrimaryContainer
                                ),
                                shape = RoundedCornerShape(12.dp),
                                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 12.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Default.OpenInBrowser,
                                    contentDescription = null,
                                    modifier = Modifier.size(19.dp)
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = "Mở link",
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
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
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
                            contentPadding = PaddingValues(horizontal = 10.dp, vertical = 8.dp),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = if (coursework.isCompleted) ChunkyColor.SuccessGreen else colorScheme.primary,
                                contentColor = if (coursework.isCompleted) Color.White else colorScheme.onPrimary
                            ),
                            shape = RoundedCornerShape(12.dp)
                        ) {
                            Icon(
                                imageVector = if (coursework.isCompleted) Icons.Default.CheckCircle else Icons.Outlined.CheckCircle,
                                contentDescription = null,
                                modifier = Modifier.size(19.dp)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = if (coursework.isCompleted) "Đã làm xong" else "Đánh dấu đã nộp",
                                fontWeight = FontWeight.Bold,
                                fontSize = 14.sp,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        }

                        OutlinedButton(
                            onClick = onCopyClick,
                            modifier = Modifier
                                .weight(1f)
                                .heightIn(min = 50.dp),
                            border = BorderStroke(1.dp, colorScheme.outlineVariant),
                            colors = ButtonDefaults.outlinedButtonColors(
                                containerColor = colorScheme.surfaceContainerLowest,
                                contentColor = colorScheme.onSurface
                            ),
                            shape = RoundedCornerShape(12.dp),
                            contentPadding = PaddingValues(horizontal = 10.dp, vertical = 8.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.ContentCopy,
                                contentDescription = null,
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = "Sao chép",
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 14.sp,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        }

                        OutlinedButton(
                            onClick = onOpenBrowserClick,
                            modifier = Modifier
                                .weight(1f)
                                .heightIn(min = 50.dp),
                            border = BorderStroke(1.dp, colorScheme.primary.copy(alpha = 0.4f)),
                            colors = ButtonDefaults.outlinedButtonColors(
                                containerColor = colorScheme.primaryContainer,
                                contentColor = colorScheme.onPrimaryContainer
                            ),
                            shape = RoundedCornerShape(12.dp),
                            contentPadding = PaddingValues(horizontal = 10.dp, vertical = 8.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Default.OpenInBrowser,
                                contentDescription = null,
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = "Mở",
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 14.sp,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis
                            )
                        }
                    }
                }
            }
        }
    }
}

private val URL_REGEX = Pattern.compile("https?://[a-zA-Z0-9-._~:/?#\\[\\]@!$&'()*+,;=%]+")

internal fun buildClickableUrlString(text: String, linkColor: androidx.compose.ui.graphics.Color): androidx.compose.ui.text.AnnotatedString {
    return buildAnnotatedString {
        val matcher = URL_REGEX.matcher(text)
        var lastIndex = 0
        while (matcher.find()) {
            val start = matcher.start()
            val end = matcher.end()
            if (start > lastIndex) {
                append(text.substring(lastIndex, start))
            }
            val matchedUrl = matcher.group()
            var cleanUrl = matchedUrl
            var trailingPunctuation = ""
            while (cleanUrl.isNotEmpty() && (cleanUrl.endsWith(".") || cleanUrl.endsWith(",") || cleanUrl.endsWith(";") || cleanUrl.endsWith("!") || cleanUrl.endsWith("?"))) {
                trailingPunctuation = cleanUrl.takeLast(1) + trailingPunctuation
                cleanUrl = cleanUrl.dropLast(1)
            }
            if (cleanUrl.endsWith(")") && cleanUrl.count { it == '(' } < cleanUrl.count { it == ')' }) {
                trailingPunctuation = cleanUrl.takeLast(1) + trailingPunctuation
                cleanUrl = cleanUrl.dropLast(1)
            }
            pushLink(LinkAnnotation.Url(cleanUrl, TextLinkStyles(style = SpanStyle(color = linkColor, textDecoration = TextDecoration.Underline))))
            append(cleanUrl)
            pop()
            if (trailingPunctuation.isNotEmpty()) {
                append(trailingPunctuation)
            }
            lastIndex = end
        }
        if (lastIndex < text.length) {
            append(text.substring(lastIndex))
        }
    }
}
