package com.phucta.classroom.ui.screens

import android.content.Intent
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
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CalendarToday
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
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.painterResource
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
    currentDayEpoch: Long = com.phucta.classroom.data.model.ClassroomDateUtils.startOfToday
) {
    val context = LocalContext.current
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
    val groupedPending = remember(pendingItems) {
        pendingItems.groupBy { it.courseName.ifBlank { "Chung" } }
    }

    val lazyListState = rememberLazyListState()

    val emotion = remember(tomorrowItems.isEmpty(), isAllDone, incompleteCount) {
        when {
            isAllDone -> EmberEmotion.CELEBRATING
            tomorrowItems.isEmpty() -> EmberEmotion.SLEEPING
            incompleteCount >= 3 -> EmberEmotion.STRESSED
            else -> EmberEmotion.NORMAL
        }
    }

    val celebrationScale = remember { Animatable(0.92f) }
    LaunchedEffect(isAllDone) {
        if (isAllDone) {
            celebrationScale.snapTo(0.92f)
            celebrationScale.animateTo(
                targetValue = 1.04f,
                animationSpec = spring(
                    dampingRatio = Spring.DampingRatioMediumBouncy,
                    stiffness = Spring.StiffnessLow
                )
            )
            celebrationScale.animateTo(
                targetValue = 1.0f,
                animationSpec = spring(
                    dampingRatio = Spring.DampingRatioNoBouncy,
                    stiffness = Spring.StiffnessMedium
                )
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
        if (tomorrowItems.isNotEmpty()) {
            item(key = "tomorrow_hero_banner", contentType = "hero_banner") {
                TomorrowEditorialHeroCard(
                    scrollOffsetProvider = {
                        if (lazyListState.firstVisibleItemIndex == 0) lazyListState.firstVisibleItemScrollOffset else 400
                    },
                    modifier = Modifier.animateItem(
                        fadeInSpec = ItemFadeSpring,
                        placementSpec = ItemPlacementSpring,
                        fadeOutSpec = ItemFadeSpring
                    )
                )
            }
        }

        item(key = "tomorrow_summary_card", contentType = "summary_card") {
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
                                    text = "Ngày mai rảnh rồi!",
                                    color = Color.White,
                                    fontWeight = FontWeight.ExtraBold,
                                    fontSize = 20.sp
                                )
                                Spacer(modifier = Modifier.height(4.dp))
                                Text(
                                    text = "Không có bài tập cho ngày mai. Nghỉ ngơi nhé!",
                                    color = Color.White.copy(alpha = 0.95f),
                                    fontSize = 14.sp,
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
                                    fontSize = 14.sp,
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
                                    fontSize = 14.sp,
                                    lineHeight = 18.sp
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
                                    text = if (isAllDone) "Hoàn thành 100%!" else "Tiến độ: $completedCount/$totalCount bài tập",
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
                            Spacer(modifier = Modifier.height(8.dp))
                            HomeworkProgressBar(
                                progressFraction = progressFraction,
                                isAllDone = isAllDone
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(14.dp))
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.End,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Row(
                            modifier = Modifier
                                .minimumInteractiveComponentSize()
                                .heightIn(min = 48.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .background(Color.White.copy(alpha = 0.22f))
                                .border(1.dp, Color.White.copy(alpha = 0.40f), RoundedCornerShape(8.dp))
                                .clickable(
                                    interactionSource = remember { MutableInteractionSource() },
                                    indication = ripple(color = Color.White),
                                    onClick = {
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
                                        BaoBaiShareHelper.copyToClipboard(context, baoBaiText)
                                        Toast.makeText(context, "Đã sao chép báo bài!", Toast.LENGTH_SHORT).show()
                                    }
                                )
                                .padding(horizontal = 14.dp, vertical = 10.dp),
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
                                fontSize = 13.sp
                            )
                        }

                        Spacer(modifier = Modifier.width(8.dp))

                        Row(
                            modifier = Modifier
                                .minimumInteractiveComponentSize()
                                .heightIn(min = 48.dp)
                                .clip(RoundedCornerShape(8.dp))
                                .background(Color.White.copy(alpha = 0.22f))
                                .border(1.dp, Color.White.copy(alpha = 0.40f), RoundedCornerShape(8.dp))
                                .clickable(
                                    interactionSource = remember { MutableInteractionSource() },
                                    indication = ripple(color = Color.White),
                                    onClick = {
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
                                        val shareIntent = BaoBaiShareHelper.createShareIntent(baoBaiText, shareTitle)
                                        val chooser = Intent.createChooser(shareIntent, "Chia sẻ báo bài qua")
                                        context.startActivity(chooser)
                                    }
                                )
                                .padding(horizontal = 14.dp, vertical = 10.dp),
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
                                fontSize = 13.sp
                            )
                        }
                    }
                }
            }
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
                                .size(136.dp)
                                .clip(RoundedCornerShape(12.dp)),
                            contentScale = ContentScale.Fit
                        )
                        Spacer(modifier = Modifier.height(14.dp))
                        Text(
                            text = "Không có bài tập ngày mai",
                            fontWeight = FontWeight.Bold,
                            fontSize = 17.sp,
                            color = ChunkyColor.TextPrimary
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = "Bạn có thể thư giãn hoặc tự ôn tập theo lịch riêng nhé!",
                            fontSize = 14.sp,
                            color = ChunkyColor.TextMuted,
                            textAlign = TextAlign.Center,
                            lineHeight = 18.sp
                        )
                    }
                }
            }
        } else {
            if (isAllDone) {
                item(key = "celebration_banner", contentType = "celebration_banner") {
                    val bannerText = when {
                        hasTomorrowTasks -> "Đã hoàn thành toàn bộ bài tập ngày mai!"
                        hasTodayTasks -> "Đã hoàn thành toàn bộ bài tập hôm nay!"
                        else -> "Đã hoàn thành toàn bộ bài tập sắp tới!"
                    }
                    Box(
                        modifier = Modifier
                            .animateItem(
                                fadeInSpec = ItemFadeSpring,
                                placementSpec = ItemPlacementSpring,
                                fadeOutSpec = ItemFadeSpring
                            )
                            .graphicsLayer {
                                scaleX = celebrationScale.value
                                scaleY = celebrationScale.value
                            }
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(ChunkyColor.SuccessGreen.copy(alpha = 0.08f))
                            .border(1.dp, ChunkyColor.SuccessGreen.copy(alpha = 0.2f), RoundedCornerShape(12.dp))
                            .padding(horizontal = 16.dp, vertical = 12.dp)
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                imageVector = Icons.Default.CheckCircle,
                                contentDescription = null,
                                tint = ChunkyColor.SuccessGreen,
                                modifier = Modifier.size(20.dp)
                            )
                            Spacer(modifier = Modifier.width(12.dp))
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

                groupedPending.forEach { (courseName, itemsInCourse) ->
                    item(key = "subject_header_$courseName", contentType = "subject_header") {
                        SubjectGroupHeader(
                            courseName = courseName,
                            count = itemsInCourse.size,
                            modifier = Modifier.animateItem(
                                fadeInSpec = ItemFadeSpring,
                                placementSpec = ItemPlacementSpring,
                                fadeOutSpec = ItemFadeSpring
                            )
                        )
                    }

                    items(
                        items = itemsInCourse,
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

            if (completedItems.isNotEmpty()) {
                item(key = "completed_section_header", contentType = "completed_section_header") {
                    CompletedSectionHeader(
                        count = completedItems.size,
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
    val emberFloatOffset = emberTransition.animateFloat(
        initialValue = -3f,
        targetValue = 3f,
        animationSpec = infiniteRepeatable(
            animation = tween(2400, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "emberFloat"
    )
    val breatheScaleX = emberTransition.animateFloat(
        initialValue = 0.985f,
        targetValue = 1.015f,
        animationSpec = infiniteRepeatable(
            animation = tween(2400, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "emberBreatheX"
    )
    val breatheScaleY = emberTransition.animateFloat(
        initialValue = 1.015f,
        targetValue = 0.985f,
        animationSpec = infiniteRepeatable(
            animation = tween(2400, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "emberBreatheY"
    )

    EmberFlameCanvas(
        size = 72.dp,
        emotion = emotion,
        isUrgent = isUrgent,
        modifier = modifier.graphicsLayer {
            translationY = emberFloatOffset.value
            scaleX = breatheScaleX.value
            scaleY = breatheScaleY.value
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
        animationSpec = tween(durationMillis = 400, easing = FastOutSlowInEasing),
        label = "progressAnim"
    )

    val barColor = if (isAllDone) Color(0xFF6EE7B7) else Color.White
    val trackColor = Color.White.copy(alpha = 0.25f)

    Canvas(
        modifier = modifier
            .fillMaxWidth()
            .height(8.dp)
    ) {
        val cornerRadius = CornerRadius(size.height / 2f, size.height / 2f)
        drawRoundRect(
            color = trackColor,
            cornerRadius = cornerRadius
        )
        val progress = animatedProgress.value.coerceIn(0f, 1f)
        if (progress > 0.001f) {
            drawRoundRect(
                color = barColor,
                size = Size(width = size.width * progress, height = size.height),
                cornerRadius = cornerRadius
            )
        }
    }
}

@Composable
private fun TomorrowEditorialHeroCard(
    scrollOffsetProvider: () -> Int = { 0 },
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(132.dp)
            .graphicsLayer {
                val offset = scrollOffsetProvider()
                val fadeAlpha = (1f - (offset / 320f)).coerceIn(0f, 1f)
                alpha = fadeAlpha
                translationY = -offset * 0.15f
            }
            .clip(RoundedCornerShape(16.dp))
            .background(Color(0xFFF5EFE6))
            .border(1.dp, ChunkyColor.CardBorder, RoundedCornerShape(16.dp))
    ) {
        Image(
            painter = painterResource(id = R.drawable.hero_bao_bai_modernist),
            contentDescription = "Minh họa Báo bài Ngày mai",
            modifier = Modifier.fillMaxSize(),
            contentScale = ContentScale.Crop
        )
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    Brush.verticalGradient(
                        colors = listOf(
                            Color.Transparent,
                            ChunkyColor.WindowBackground.copy(alpha = 0.28f)
                        )
                    )
                )
        )
    }
}

@Composable
private fun SubjectGroupHeader(
    courseName: String,
    count: Int,
    modifier: Modifier = Modifier
) {
    val category = SubjectArtHelper.category(courseName)
    val color = SubjectArtHelper.themeColor(category)

    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(top = 10.dp, bottom = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(width = 4.dp, height = 15.dp)
                .clip(RoundedCornerShape(2.dp))
                .background(color)
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = courseName.uppercase(),
            style = MaterialTheme.typography.labelLarge.copy(
                fontWeight = FontWeight.ExtraBold,
                letterSpacing = 0.5.sp,
                fontSize = 12.5.sp
            ),
            color = ChunkyColor.TextPrimary
        )
        Spacer(modifier = Modifier.width(6.dp))
        Box(
            modifier = Modifier
                .clip(CircleShape)
                .background(color.copy(alpha = 0.12f))
                .padding(horizontal = 7.dp, vertical = 2.dp)
        ) {
            Text(
                text = "$count bài",
                style = MaterialTheme.typography.labelSmall.copy(
                    fontWeight = FontWeight.Bold,
                    fontSize = 11.sp
                ),
                color = color
            )
        }
    }
}

@Composable
private fun CompletedSectionHeader(
    count: Int,
    modifier: Modifier = Modifier
) {
    Row(
        modifier = modifier
            .fillMaxWidth()
            .padding(top = 16.dp, bottom = 4.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = Icons.Default.CheckCircle,
            contentDescription = null,
            tint = ChunkyColor.SuccessGreen,
            modifier = Modifier.size(16.dp)
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = "ĐÃ HOÀN THÀNH ($count)",
            style = MaterialTheme.typography.labelLarge.copy(
                fontWeight = FontWeight.Bold,
                letterSpacing = 0.5.sp,
                fontSize = 12.sp
            ),
            color = ChunkyColor.TextMuted
        )
    }
}
