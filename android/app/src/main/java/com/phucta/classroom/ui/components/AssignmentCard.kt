package com.phucta.classroom.ui.components

import android.view.HapticFeedbackConstants
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.EditNote
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.ripple
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.ui.theme.BeVietnamProFontFamily
import com.phucta.classroom.ui.theme.ChunkyColor
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch

private val UncheckedBorderColor = ChunkyColor.TextMuted.copy(alpha = 0.5f)
private val StrikethroughLineColor = ChunkyColor.TextMuted.copy(alpha = 0.85f)
private val CardShape = RoundedCornerShape(16.dp)
private val CardEndShape = RoundedCornerShape(topEnd = 16.dp, bottomEnd = 16.dp)

private class CachedTextLine(val left: Float, val right: Float, val y: Float)

private val CardPressSpring = spring<Float>(
    dampingRatio = Spring.DampingRatioMediumBouncy,
    stiffness = 400f
)
private val CheckPressSpring = spring<Float>(
    dampingRatio = Spring.DampingRatioMediumBouncy,
    stiffness = Spring.StiffnessMedium
)
private val CheckBounceOutTween = tween<Float>(durationMillis = 110, easing = FastOutSlowInEasing)
private val CheckBounceSpring = spring<Float>(
    dampingRatio = Spring.DampingRatioMediumBouncy,
    stiffness = Spring.StiffnessLow
)
private val IconSpring = spring<Float>(
    dampingRatio = Spring.DampingRatioMediumBouncy,
    stiffness = Spring.StiffnessMedium
)
private val CompletionProgressTween = tween<Float>(durationMillis = 260, easing = FastOutSlowInEasing)
private val CheckUncheckSpring = spring<Float>(
    dampingRatio = Spring.DampingRatioNoBouncy,
    stiffness = Spring.StiffnessMedium
)

@Composable
fun AssignmentCard(
    coursework: Coursework,
    onToggleCompletion: (Boolean) -> Unit,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    hasNote: Boolean = false
) {
    val isCompleted = coursework.isCompleted
    val isOverdue = coursework.isOverdue
    val view = LocalView.current

    val cardInteractionSource = remember { MutableInteractionSource() }
    val isCardPressed by cardInteractionSource.collectIsPressedAsState()
    val cardPressScale = animateFloatAsState(
        targetValue = if (isCardPressed) 1f else 0f,
        animationSpec = CardPressSpring,
        label = "cardPressScale"
    )

    val checkInteractionSource = remember { MutableInteractionSource() }
    val isCheckPressed by checkInteractionSource.collectIsPressedAsState()
    val checkPressScale = animateFloatAsState(
        targetValue = if (isCheckPressed) 1f else 0f,
        animationSpec = CheckPressSpring,
        label = "checkPressScale"
    )

    val checkScaleAnim = remember(coursework.id) { Animatable(if (isCompleted) 1.0f else 0.88f) }
    val iconScaleAnim = remember(coursework.id) { Animatable(if (isCompleted) 1.0f else 0.0f) }
    val completionProgress = remember(coursework.id) { Animatable(if (isCompleted) 1.0f else 0.0f) }
    var isFirstComposition by remember(coursework.id) { mutableStateOf(true) }

    LaunchedEffect(isCompleted) {
        if (isFirstComposition) {
            isFirstComposition = false
            return@LaunchedEffect
        }
        if (isCompleted) {
            coroutineScope {
                launch {
                    checkScaleAnim.animateTo(
                        targetValue = 1.15f,
                        animationSpec = CheckBounceOutTween
                    )
                    checkScaleAnim.animateTo(
                        targetValue = 1.0f,
                        animationSpec = CheckBounceSpring
                    )
                }
                launch {
                    iconScaleAnim.animateTo(
                        targetValue = 1.0f,
                        animationSpec = IconSpring
                    )
                }
                launch {
                    completionProgress.animateTo(
                        targetValue = 1.0f,
                        animationSpec = CompletionProgressTween
                    )
                }
            }
        } else {
            coroutineScope {
                launch {
                    checkScaleAnim.animateTo(
                        targetValue = 0.88f,
                        animationSpec = CheckUncheckSpring
                    )
                }
                launch {
                    iconScaleAnim.animateTo(
                        targetValue = 0.0f,
                        animationSpec = IconSpring
                    )
                }
                launch {
                    completionProgress.animateTo(
                        targetValue = 0.0f,
                        animationSpec = CompletionProgressTween
                    )
                }
            }
        }
    }

    val cachedLines = remember(coursework.id, coursework.title) { ArrayList<CachedTextLine>(2) }
    val onTextLayout: (TextLayoutResult) -> Unit = remember(cachedLines) {
        { layout ->
            cachedLines.clear()
            val count = layout.lineCount
            for (i in 0 until count) {
                cachedLines.add(
                    CachedTextLine(
                        layout.getLineLeft(i),
                        layout.getLineRight(i),
                        (layout.getLineTop(i) + layout.getLineBottom(i)) / 2f
                    )
                )
            }
        }
    }

    val onCheckboxClick = remember(isCompleted, onToggleCompletion, view) {
        {
            val newCompleted = !isCompleted
            if (newCompleted) {
                if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
                    view.performHapticFeedback(HapticFeedbackConstants.CONFIRM)
                } else {
                    view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY)
                }
            } else {
                view.performHapticFeedback(HapticFeedbackConstants.CLOCK_TICK)
            }
            onToggleCompletion(newCompleted)
        }
    }

    val subjectTheme = remember(coursework.courseName, coursework.title) {
        SubjectArtHelper.theme(coursework.courseName, coursework.title)
    }

    val colorScheme = MaterialTheme.colorScheme
    val uncheckedBorderColor = colorScheme.onSurfaceVariant.copy(alpha = 0.5f)
    val strikethroughLineColor = colorScheme.onSurfaceVariant.copy(alpha = 0.85f)

    Row(
        modifier = modifier
            .fillMaxWidth()
            .heightIn(min = 48.dp)
            .graphicsLayer {
                val scale = cardPressScale.value
                val pressFactor = 0.015f * scale
                scaleX = 1.0f - pressFactor
                scaleY = 1.0f - pressFactor
                shape = CardShape
                clip = true
            }
            .background(colorScheme.surfaceContainerLowest)
            .border(1.dp, colorScheme.outlineVariant, CardShape),
        verticalAlignment = Alignment.Top
    ) {
        Box(
            modifier = Modifier
                .padding(start = 4.dp, top = 4.dp)
                .size(48.dp)
                .semantics {
                    contentDescription = "Đánh dấu hoàn thành ${coursework.title}"
                    stateDescription = if (isCompleted) "Đã hoàn thành" else "Chưa hoàn thành"
                }
                .clickable(
                    interactionSource = checkInteractionSource,
                    indication = ripple(bounded = false, radius = 22.dp),
                    role = Role.Checkbox,
                    onClick = onCheckboxClick
                ),
            contentAlignment = Alignment.Center
        ) {
            Box(
                modifier = Modifier
                    .size(25.dp)
                    .graphicsLayer {
                        val pScale = 1.0f - 0.10f * checkPressScale.value
                        val combinedScale = checkScaleAnim.value * pScale
                        scaleX = combinedScale
                        scaleY = combinedScale
                    }
                    .drawWithCache {
                        val strokeWidthPx = 2.dp.toPx()
                        val stroke = Stroke(width = strokeWidthPx)
                        val radius = (size.minDimension - strokeWidthPx) / 2f
                        onDrawBehind {
                            val progress = completionProgress.value
                            val factor = (progress / 0.769f).coerceIn(0f, 1f)
                            val bgColor = lerp(Color.Transparent, ChunkyColor.SuccessGreen, factor)
                            val borderColor = lerp(uncheckedBorderColor, ChunkyColor.SuccessGreen, factor)
                            drawCircle(color = bgColor)
                            drawCircle(
                                color = borderColor,
                                radius = radius,
                                style = stroke
                            )
                        }
                    },
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Check,
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier
                        .size(17.dp)
                        .graphicsLayer {
                            val progress = completionProgress.value
                            scaleX = iconScaleAnim.value
                            scaleY = iconScaleAnim.value
                            rotationZ = -12f + 12f * progress
                            alpha = (progress / 0.692f).coerceIn(0f, 1f)
                        }
                )
            }
        }

        Row(
            modifier = Modifier
                .weight(1f)
                .heightIn(min = 52.dp)
                .clip(CardEndShape)
                .clickable(
                    interactionSource = cardInteractionSource,
                    indication = ripple(),
                    onClick = onClick
                )
                .padding(start = 6.dp, end = 16.dp, top = 13.dp, bottom = 13.dp),
            verticalAlignment = Alignment.Top
        ) {
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = coursework.title,
                    color = colorScheme.onSurface,
                    style = MaterialTheme.typography.titleMedium.copy(
                        fontSize = 17.sp,
                        lineHeight = 23.sp
                    ),
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    onTextLayout = onTextLayout,
                    modifier = Modifier
                        .graphicsLayer {
                            val progress = completionProgress.value
                            alpha = 1.0f - 0.35f * (progress / 0.846f).coerceIn(0f, 1f)
                        }
                        .drawWithCache {
                            val strokeWidthPx = 2.dp.toPx()
                            onDrawWithContent {
                                drawContent()
                                val progress = completionProgress.value
                                if (progress > 0.001f) {
                                    val lines = cachedLines
                                    if (lines.isNotEmpty()) {
                                        for (i in 0 until lines.size) {
                                            val line = lines[i]
                                            val endX = line.left + (line.right - line.left) * progress
                                            drawLine(
                                                color = strikethroughLineColor,
                                                start = Offset(line.left, line.y),
                                                end = Offset(endX, line.y),
                                                strokeWidth = strokeWidthPx,
                                                cap = StrokeCap.Round
                                            )
                                        }
                                    } else {
                                        val y = size.height / 2f
                                        val endX = size.width * progress
                                        drawLine(
                                            color = strikethroughLineColor,
                                            start = Offset(0f, y),
                                            end = Offset(endX, y),
                                            strokeWidth = strokeWidthPx,
                                            cap = StrokeCap.Round
                                        )
                                    }
                                }
                            }
                        }
                )
                Spacer(modifier = Modifier.height(5.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Box(
                        modifier = Modifier
                            .size(7.dp)
                            .background(subjectTheme.color, CircleShape)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = coursework.courseName,
                        color = colorScheme.onSurfaceVariant,
                        style = MaterialTheme.typography.bodyMedium,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f, fill = false)
                    )
                    if (hasNote) {
                        Spacer(modifier = Modifier.width(5.dp))
                        Icon(
                            imageVector = Icons.Default.EditNote,
                            contentDescription = "Có ghi chú",
                            tint = colorScheme.primary,
                            modifier = Modifier.size(17.dp)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.width(10.dp))

            Box(
                modifier = Modifier.widthIn(max = 150.dp),
                contentAlignment = Alignment.TopEnd
            ) {
                DueDateBadge(
                    text = coursework.compactDueString,
                    isCompleted = isCompleted,

                    isOverdue = !isCompleted && (isOverdue || coursework.isPast),
                    isDueToday = coursework.isDueToday,
                    isDueTomorrow = coursework.isDueTomorrow,
                    isUrgent = coursework.isUrgent,
                    fontSize = 13.sp,
                    modifier = Modifier.padding(top = 2.dp)
                )
            }
        }
    }
}
