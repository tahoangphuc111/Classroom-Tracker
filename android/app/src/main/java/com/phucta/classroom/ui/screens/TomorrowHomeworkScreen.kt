package com.phucta.classroom.ui.screens

import android.content.Intent
import android.os.Build
import android.view.HapticFeedbackConstants
import android.widget.Toast
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Share
import androidx.compose.material.icons.filled.Upcoming
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.minimumInteractiveComponentSize
import androidx.compose.material3.ripple
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.phucta.classroom.R
import com.phucta.classroom.data.model.ClassroomDateUtils
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.domain.BaoBaiShareHelper
import com.phucta.classroom.ui.components.AssignmentCard
import com.phucta.classroom.ui.components.EmberEmotion
import com.phucta.classroom.ui.components.EmberFlameCanvas
import com.phucta.classroom.ui.components.SectionHeaderPill
import com.phucta.classroom.ui.components.SubjectArtHelper
import com.phucta.classroom.ui.components.SubjectCategory
import com.phucta.classroom.ui.components.SubjectTheme
import com.phucta.classroom.ui.theme.BeVietnamProFontFamily
import com.phucta.classroom.ui.theme.ChunkyColor

private val ItemPlacementSpring = spring<IntOffset>(dampingRatio = 0.82f, stiffness = 380f)
private val ItemFadeSpring = spring<Float>(dampingRatio = 0.82f, stiffness = 380f)
private val CelebrationPopSpring = spring<Float>(
    dampingRatio = Spring.DampingRatioMediumBouncy,
    stiffness = Spring.StiffnessLow
)
private val CelebrationSettleSpring = spring<Float>(
    dampingRatio = Spring.DampingRatioNoBouncy,
    stiffness = Spring.StiffnessMedium
)
private val EmberHeroTween = tween<Float>(2400, easing = FastOutSlowInEasing)
private val EmberHeroRepeatable = infiniteRepeatable<Float>(
    animation = EmberHeroTween,
    repeatMode = RepeatMode.Reverse
)
private val ProgressDoneBrush = Brush.horizontalGradient(listOf(Color(0xFF34D399), Color(0xFF10B981)))
private val ProgressPendingBrush = Brush.horizontalGradient(listOf(Color.White, Color(0xFFBAE6FD)))
private val ProgressTrackColor = Color.White.copy(alpha = 0.25f)
private val ProgressTween = tween<Float>(durationMillis = 400, easing = FastOutSlowInEasing)

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun TomorrowHomeworkScreen(
    tomorrowItems: List<Coursework>,
    onToggleCompletion: (String, Boolean) -> Unit,
    onSelectAssignment: (Coursework) -> Unit,
    modifier: Modifier = Modifier,
    courseworkIdsWithNotes: Set<String> = emptySet(),
    currentDayEpoch: Long = com.phucta.classroom.data.model.ClassroomDateUtils.startOfToday
) {
    val context = LocalContext.current
    val view = androidx.compose.ui.platform.LocalView.current
    val currentOnToggleCompletion by rememberUpdatedState(onToggleCompletion)
    val currentOnSelectAssignment by rememberUpdatedState(onSelectAssignment)
    val incompleteCount = remember(tomorrowItems) { tomorrowItems.count { !it.isCompleted } }
    val isAllDone = remember(tomorrowItems, incompleteCount) { tomorrowItems.isNotEmpty() && incompleteCount == 0 }
    val hasTomorrowTasks = remember(tomorrowItems, currentDayEpoch) { tomorrowItems.any { it.isDueTomorrow } }
    val hasTodayTasks = remember(tomorrowItems, currentDayEpoch) { tomorrowItems.any { it.isDueToday } }

    val totalCount = tomorrowItems.size
    val completedCount = totalCount - incompleteCount
    val progressFraction = if (totalCount > 0) (completedCount.toFloat() / totalCount.toFloat()).coerceIn(0f, 1f) else 0f

    val pendingItems = remember(tomorrowItems) { tomorrowItems.filter { !it.isCompleted } }
    val completedItems = remember(tomorrowItems) { tomorrowItems.filter { it.isCompleted } }

    val lazyListState = rememberLazyListState()

    val hasUrgent = remember(tomorrowItems) { tomorrowItems.any { it.isUrgent } }
    val emotion = remember(tomorrowItems.isEmpty(), isAllDone, incompleteCount, completedCount, hasUrgent) {
        when {
            isAllDone -> EmberEmotion.CELEBRATING
            tomorrowItems.isEmpty() -> EmberEmotion.SLEEPING
            hasUrgent || incompleteCount >= 3 -> EmberEmotion.STRESSED
            completedCount > 0 -> EmberEmotion.STUDYING
            else -> EmberEmotion.NORMAL
        }
    }

    val celebrationScale = remember { Animatable(0.92f) }
    LaunchedEffect(isAllDone) {
        if (isAllDone) {
            celebrationScale.snapTo(0.92f)
            celebrationScale.animateTo(
                targetValue = 1.04f,
                animationSpec = CelebrationPopSpring
            )
            celebrationScale.animateTo(
                targetValue = 1.0f,
                animationSpec = CelebrationSettleSpring
            )
        }
    }

    LazyColumn(
        state = lazyListState,
        modifier = modifier
            .fillMaxSize()
            .background(ChunkyColor.WindowBackground),
        contentPadding = PaddingValues(start = 16.dp, top = 16.dp, end = 16.dp, bottom = 28.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        item(key = "tomorrow_summary_card", contentType = "summary_card") {
            TomorrowSummaryCard(
                tomorrowItems = tomorrowItems,
                incompleteCount = incompleteCount,
                completedCount = completedCount,
                progressFraction = progressFraction,
                isAllDone = isAllDone,
                hasTomorrowTasks = hasTomorrowTasks,
                hasTodayTasks = hasTodayTasks,
                emotion = emotion
            )
        }

        if (tomorrowItems.isEmpty()) {
            item(key = "empty_state_card", contentType = "empty_state") {
                Box(
                    modifier = Modifier
                        .animateItem(
                            fadeInSpec = ItemFadeSpring,
                            placementSpec = ItemPlacementSpring,
                            fadeOutSpec = ItemFadeSpring
                        )
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(16.dp))
                        .background(ChunkyColor.SurfaceWhite)
                        .border(1.dp, ChunkyColor.CardBorder, RoundedCornerShape(16.dp))
                        .padding(vertical = 32.dp, horizontal = 20.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Image(
                            painter = painterResource(id = R.drawable.empty_state_all_caught_up),
                            contentDescription = "Không có bài tập ngày mai",
                            modifier = Modifier
                                .size(144.dp)
                                .clip(RoundedCornerShape(12.dp)),
                            contentScale = ContentScale.Fit
                        )
                        Spacer(modifier = Modifier.height(14.dp))
                        Text(
                            text = "Ngày mai không có bài",
                            fontWeight = FontWeight.Bold,
                            fontSize = 19.sp,
                            color = ChunkyColor.TextPrimary
                        )
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(
                            text = "Không có bài tập nào cần chuẩn bị cho ngày mai.",
                            fontSize = 15.sp,
                            color = ChunkyColor.TextMuted,
                            textAlign = TextAlign.Center,
                            lineHeight = 20.sp
                        )
                    }
                }
            }
        } else {
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
                    val onClickCard = remember(item) {
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
                    val onClickCard = remember(item) {
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
private fun FloatingEmberHero(
    emotion: EmberEmotion,
    isUrgent: Boolean,
    modifier: Modifier = Modifier
) {
    val emberTransition = rememberInfiniteTransition(label = "emberFloating")
    val floatPhase = emberTransition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = EmberHeroRepeatable,
        label = "emberPhase"
    )

    EmberFlameCanvas(
        size = 76.dp,
        emotion = emotion,
        isUrgent = isUrgent,
        modifier = modifier.graphicsLayer {
            val phase = floatPhase.value
            translationY = -3f + 6f * phase
            scaleX = 0.985f + 0.030f * phase
            scaleY = 1.015f - 0.030f * phase
        }
    )
}

@Composable
private fun HomeworkProgressBar(
    progressFraction: Float,
    isAllDone: Boolean,
    modifier: Modifier = Modifier
) {
    val animatedProgress = animateFloatAsState(
        targetValue = progressFraction.coerceIn(0f, 1f),
        animationSpec = ProgressTween,
        label = "progressAnim"
    )

    val barBrush = if (isAllDone) ProgressDoneBrush else ProgressPendingBrush

    Canvas(
        modifier = modifier
            .fillMaxWidth()
            .height(9.dp)
    ) {
        val cornerRadius = CornerRadius(size.height / 2f, size.height / 2f)
        drawRoundRect(
            color = ProgressTrackColor,
            cornerRadius = cornerRadius
        )
        val progress = animatedProgress.value.coerceIn(0f, 1f)
        if (progress > 0.001f) {
            drawRoundRect(
                brush = barBrush,
                size = Size(width = size.width * progress, height = size.height),
                cornerRadius = cornerRadius
            )
        }
    }
}

@Composable
private fun TomorrowSummaryCard(
    tomorrowItems: List<Coursework>,
    incompleteCount: Int,
    completedCount: Int,
    progressFraction: Float,
    isAllDone: Boolean,
    hasTomorrowTasks: Boolean,
    hasTodayTasks: Boolean,
    emotion: EmberEmotion
) {
    val context = LocalContext.current
    val view = androidx.compose.ui.platform.LocalView.current
    val totalCount = tomorrowItems.size

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(18.dp))
            .background(ChunkyColor.SkyGradient)
            .border(1.dp, Color.White.copy(alpha = 0.25f), RoundedCornerShape(18.dp))
            .padding(18.dp)
    ) {
        Column(modifier = Modifier.fillMaxWidth()) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                FloatingEmberHero(
                    emotion = emotion,
                    isUrgent = incompleteCount >= 3
                )

                Spacer(modifier = Modifier.width(16.dp))

                Column(
                    modifier = Modifier.weight(1f)
                ) {
                    if (tomorrowItems.isEmpty()) {
                        Text(
                            text = "Ngày mai không có bài!",
                            color = Color.White,
                            fontWeight = FontWeight.ExtraBold,
                            fontSize = 22.sp
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Chưa có bài tập nào cần nộp ngày mai.",
                            color = Color.White.copy(alpha = 0.95f),
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 15.sp,
                            lineHeight = 20.sp
                        )
                    } else if (isAllDone) {
                        val doneMessage = when {
                            hasTomorrowTasks -> "Đã làm xong toàn bộ bài ngày mai."
                            hasTodayTasks -> "Đã làm xong toàn bộ bài hôm nay."
                            else -> "Đã làm xong hết bài sắp tới."
                        }
                        Text(
                            text = "Đã xong hết bài!",
                            color = Color.White,
                            fontWeight = FontWeight.ExtraBold,
                            fontSize = 22.sp
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = doneMessage,
                            color = Color.White.copy(alpha = 0.95f),
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 15.sp,
                            lineHeight = 20.sp
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
                            fontSize = 22.sp
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Còn $incompleteCount bài tập cần nộp.",
                            color = Color.White.copy(alpha = 0.95f),
                            fontWeight = FontWeight.SemiBold,
                            fontSize = 15.sp,
                            lineHeight = 20.sp
                        )
                    }
                }
            }

            if (tomorrowItems.isNotEmpty()) {
                Spacer(modifier = Modifier.height(16.dp))
                Column(modifier = Modifier.fillMaxWidth()) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = if (isAllDone) "Đã xong hết 100%" else "Đã làm: $completedCount/$totalCount bài",
                            color = Color.White.copy(alpha = 0.95f),
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.sp
                        )
                        Text(
                            text = "${(progressFraction * 100).toInt()}%",
                            color = Color.White,
                            fontFamily = BeVietnamProFontFamily,
                            fontWeight = FontWeight.Bold,
                            fontSize = 14.5.sp
                        )
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                    HomeworkProgressBar(
                        progressFraction = progressFraction,
                        isAllDone = isAllDone
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    modifier = Modifier
                        .weight(1f)
                        .minimumInteractiveComponentSize()
                        .height(42.dp)
                        .clip(RoundedCornerShape(11.dp))
                        .background(Color.White.copy(alpha = 0.20f))
                        .border(1.dp, Color.White.copy(alpha = 0.35f), RoundedCornerShape(11.dp))
                        .clickable(
                            interactionSource = remember { MutableInteractionSource() },
                            indication = ripple(color = Color.White),
                            role = Role.Button,
                            onClick = {
                                try {
                                    val targetDayLabel = when {
                                        hasTomorrowTasks -> "NGÀY MAI"
                                        hasTodayTasks -> "HÔM NAY"
                                        else -> "SẮP TỚI"
                                    }
                                    val dateEpoch = when {
                                        hasTomorrowTasks -> ClassroomDateUtils.startOfTomorrow
                                        hasTodayTasks -> ClassroomDateUtils.startOfToday
                                        else -> tomorrowItems.firstOrNull { it.dueEpochMillis != null }?.dueEpochMillis ?: ClassroomDateUtils.startOfTomorrow
                                    }
                                    val baoBaiText = BaoBaiShareHelper.formatBaoBaiText(
                                        items = tomorrowItems,
                                        dateEpochMillis = dateEpoch,
                                        targetDayLabel = targetDayLabel
                                    )
                                    val copied = BaoBaiShareHelper.copyToClipboard(context, baoBaiText)
                                    if (copied) {
                                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                                            view.performHapticFeedback(HapticFeedbackConstants.CONFIRM)
                                        } else {
                                            view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
                                        }
                                        Toast.makeText(context, "Đã sao chép báo bài", Toast.LENGTH_SHORT).show()
                                    } else {
                                        Toast.makeText(context, "Không thể sao chép báo bài", Toast.LENGTH_SHORT).show()
                                    }
                                } catch (e: Exception) {
                                    Toast.makeText(context, "Không thể sao chép báo bài", Toast.LENGTH_SHORT).show()
                                }
                            }
                        )
                        .padding(horizontal = 14.dp),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.ContentCopy,
                        contentDescription = "Sao chép báo bài",
                        tint = Color.White,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "Sao chép",
                        color = Color.White,
                        fontWeight = FontWeight.Bold,
                        fontSize = 14.sp
                    )
                }

                Row(
                    modifier = Modifier
                        .weight(1f)
                        .minimumInteractiveComponentSize()
                        .height(42.dp)
                        .clip(RoundedCornerShape(11.dp))
                        .background(Color.White.copy(alpha = 0.20f))
                        .border(1.dp, Color.White.copy(alpha = 0.35f), RoundedCornerShape(11.dp))
                        .clickable(
                            interactionSource = remember { MutableInteractionSource() },
                            indication = ripple(color = Color.White),
                            role = Role.Button,
                            onClick = {
                                try {
                                    val targetDayLabel = when {
                                        hasTomorrowTasks -> "NGÀY MAI"
                                        hasTodayTasks -> "HÔM NAY"
                                        else -> "SẮP TỚI"
                                    }
                                    val shareTitle = when {
                                        hasTomorrowTasks -> "Báo bài ngày mai"
                                        hasTodayTasks -> "Báo bài hôm nay"
                                        else -> "Báo bài sắp tới"
                                    }
                                    val dateEpoch = when {
                                        hasTomorrowTasks -> ClassroomDateUtils.startOfTomorrow
                                        hasTodayTasks -> ClassroomDateUtils.startOfToday
                                        else -> tomorrowItems.firstOrNull { it.dueEpochMillis != null }?.dueEpochMillis ?: ClassroomDateUtils.startOfTomorrow
                                    }
                                    val baoBaiText = BaoBaiShareHelper.formatBaoBaiText(
                                        items = tomorrowItems,
                                        dateEpochMillis = dateEpoch,
                                        targetDayLabel = targetDayLabel
                                    )
                                    view.performHapticFeedback(HapticFeedbackConstants.CONTEXT_CLICK)
                                    val shareIntent = BaoBaiShareHelper.createShareIntent(baoBaiText, shareTitle)
                                    val chooser = Intent.createChooser(shareIntent, "Chia sẻ báo bài qua").apply {
                                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    }
                                    context.startActivity(chooser)
                                } catch (e: Exception) {
                                    Toast.makeText(context, "Không thể chia sẻ báo bài", Toast.LENGTH_SHORT).show()
                                }
                            }
                        )
                        .padding(horizontal = 14.dp),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.Share,
                        contentDescription = "Chia sẻ báo bài",
                        tint = Color.White,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = "Chia sẻ",
                        color = Color.White,
                        fontWeight = FontWeight.Bold,
                        fontSize = 14.sp
                    )
                }
            }
        }
    }
}
