package com.phucta.classroom.ui.screens

import android.content.ActivityNotFoundException
import android.content.Intent
import android.os.Build
import android.widget.Toast
import androidx.compose.animation.core.spring
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Upcoming
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import com.phucta.classroom.data.model.ClassroomDateUtils
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.domain.BaoBaiShareHelper
import com.phucta.classroom.ui.components.AssignmentCard
import com.phucta.classroom.ui.components.SectionHeaderPill
import com.phucta.classroom.ui.theme.ChunkyColor

private val ItemPlacementSpring = spring<IntOffset>(dampingRatio = 0.82f, stiffness = 380f)
private val ItemFadeSpring = spring<Float>(dampingRatio = 0.82f, stiffness = 380f)

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun TomorrowHomeworkScreen(
    tomorrowItems: List<Coursework>,
    onToggleCompletion: (String, Boolean) -> Unit,
    onSelectAssignment: (Coursework) -> Unit,
    modifier: Modifier = Modifier,
    courseworkIdsWithNotes: Set<String> = emptySet(),
    currentDayEpoch: Long = ClassroomDateUtils.startOfToday
) {
    val currentOnToggleCompletion by rememberUpdatedState(onToggleCompletion)
    val currentOnSelectAssignment by rememberUpdatedState(onSelectAssignment)
    val (completedItems, pendingItems) = remember(tomorrowItems, currentDayEpoch) {
        tomorrowItems.partition { it.isCompleted }
    }
    val hasTomorrowTasks = remember(tomorrowItems, currentDayEpoch) { tomorrowItems.firstOrNull()?.isDueTomorrow == true }
    val hasTodayTasks = remember(tomorrowItems, currentDayEpoch) { tomorrowItems.firstOrNull()?.isDueToday == true }

    LazyColumn(
        state = rememberLazyListState(),
        modifier = modifier
            .fillMaxSize()
            .background(ChunkyColor.WindowBackground),
        contentPadding = PaddingValues(start = 16.dp, top = 16.dp, end = 16.dp, bottom = 28.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        if (tomorrowItems.isEmpty()) {
            item(key = "empty_state") {
                Text(
                    text = "Ngày mai không có bài tập",
                    modifier = Modifier.fillMaxWidth().padding(vertical = 28.dp),
                    textAlign = TextAlign.Center,
                    style = MaterialTheme.typography.titleMedium,
                    color = ChunkyColor.TextPrimary
                )
            }
        } else {
            item(key = "tomorrow_summary") {
                TomorrowSummaryCard(
                    tomorrowItems = tomorrowItems,
                    completedCount = completedItems.size,
                    hasTomorrowTasks = hasTomorrowTasks,
                    hasTodayTasks = hasTodayTasks
                )
            }
            if (pendingItems.isNotEmpty()) {
                val (sectionTitle, sectionIcon, sectionColor) = when {
                    hasTomorrowTasks -> Triple("BÀI TẬP NGÀY MAI", Icons.Default.CalendarToday, ChunkyColor.HeaderTomorrow)
                    hasTodayTasks -> Triple("BÀI TẬP HÔM NAY", Icons.Default.Schedule, ChunkyColor.HeaderToday)
                    else -> Triple("BÀI TẬP SẮP TỚI", Icons.Default.Upcoming, ChunkyColor.HeaderTomorrow)
                }
                item(key = "section_header", contentType = "section_header") {
                    SectionHeaderPill(
                        title = sectionTitle,
                        count = pendingItems.size,
                        icon = sectionIcon,
                        color = sectionColor,
                        modifier = Modifier.animateItem(
                            fadeInSpec = ItemFadeSpring,
                            placementSpec = ItemPlacementSpring,
                            fadeOutSpec = ItemFadeSpring
                        )
                    )
                }

                items(
                    items = pendingItems,
                    key = { it.id },
                    contentType = { "assignment_card" }
                ) { item ->
                    val onToggle = remember(item.id) {
                        { completed: Boolean -> currentOnToggleCompletion(item.id, completed) }
                    }
                    val onClickCard = remember(item.id) {
                        { currentOnSelectAssignment(item) }
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

            if (completedItems.isNotEmpty()) {
                item(key = "completed_section_header", contentType = "completed_section_header") {
                    SectionHeaderPill(
                        title = "ĐÃ HOÀN THÀNH",
                        count = completedItems.size,
                        icon = Icons.Default.CheckCircle,
                        color = ChunkyColor.HeaderCompleted,
                        modifier = Modifier.animateItem(
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
                    val onToggle = remember(item.id) {
                        { completed: Boolean -> currentOnToggleCompletion(item.id, completed) }
                    }
                    val onClickCard = remember(item.id) {
                        { currentOnSelectAssignment(item) }
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
}

@Composable
private fun TomorrowSummaryCard(
    tomorrowItems: List<Coursework>,
    completedCount: Int,
    hasTomorrowTasks: Boolean,
    hasTodayTasks: Boolean
) {
    val context = LocalContext.current
    val title = when {
        hasTomorrowTasks -> "Báo bài ngày mai"
        hasTodayTasks -> "Báo bài hôm nay"
        else -> "Báo bài sắp tới"
    }
    val shareText = {
        val dayLabel = when {
            hasTomorrowTasks -> "NGÀY MAI"
            hasTodayTasks -> "HÔM NAY"
            else -> "SẮP TỚI"
        }
        val date = when {
            hasTomorrowTasks -> ClassroomDateUtils.startOfTomorrow
            hasTodayTasks -> ClassroomDateUtils.startOfToday
            else -> tomorrowItems.firstOrNull { it.dueEpochMillis != null }?.dueEpochMillis
                ?: ClassroomDateUtils.startOfTomorrow
        }
        BaoBaiShareHelper.formatBaoBaiText(tomorrowItems, date, dayLabel)
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(ChunkyColor.SurfaceWhite, RoundedCornerShape(12.dp))
            .padding(horizontal = 12.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Column(modifier = Modifier.weight(1f)) {
                Text(title, style = MaterialTheme.typography.titleMedium, color = ChunkyColor.TextPrimary)
                Text(
                    "Đã xong $completedCount/${tomorrowItems.size} mục",
                    style = MaterialTheme.typography.bodyMedium,
                    color = ChunkyColor.TextMuted
                )
            }
            IconButton(onClick = {
                val copied = BaoBaiShareHelper.copyToClipboard(context, shareText())
                if (!copied || Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
                    val message = if (copied) "Đã sao chép báo bài" else "Không thể sao chép báo bài"
                    Toast.makeText(context, message, Toast.LENGTH_SHORT).show()
                }
            }) {
                Icon(Icons.Default.ContentCopy, contentDescription = "Sao chép báo bài", tint = ChunkyColor.ActionBlue)
            }
            IconButton(onClick = {
                val intent = BaoBaiShareHelper.createShareIntent(shareText(), title)
                try {
                    context.startActivity(Intent.createChooser(intent, null))
                } catch (_: ActivityNotFoundException) {
                    Toast.makeText(context, "Không thể chia sẻ báo bài", Toast.LENGTH_SHORT).show()
                }
            }) {
                Icon(Icons.Default.Share, contentDescription = "Chia sẻ báo bài", tint = ChunkyColor.ActionBlue)
            }
        }

        LinearProgressIndicator(
            progress = { completedCount.toFloat() / tomorrowItems.size },
            modifier = Modifier.fillMaxWidth(),
            color = ChunkyColor.ActionBlue
        )
    }
}
