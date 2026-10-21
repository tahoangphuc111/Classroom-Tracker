package com.phucta.classroom.ui.components

import android.view.HapticFeedbackConstants
import androidx.compose.animation.animateColorAsState
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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.EditNote
import androidx.compose.material3.Icon
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
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.ui.theme.ChunkyColor

private val UncheckedBorderColor = ChunkyColor.TextMuted.copy(alpha = 0.5f)
private val StrikethroughLineColor = ChunkyColor.TextMuted.copy(alpha = 0.85f)

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
    val cardScaleX = animateFloatAsState(
        targetValue = if (isCardPressed) 1.01f else 1.0f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = 400f
        ),
        label = "cardScaleX"
    )
    val cardScaleY = animateFloatAsState(
        targetValue = if (isCardPressed) 0.97f else 1.0f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = 400f
        ),
        label = "cardScaleY"
    )

    val checkInteractionSource = remember { MutableInteractionSource() }
    val isCheckPressed by checkInteractionSource.collectIsPressedAsState()
    val checkPressScale = animateFloatAsState(
        targetValue = if (isCheckPressed) 0.90f else 1.0f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessMedium
        ),
        label = "checkPressScale"
    )

    val checkScale = remember { Animatable(if (isCompleted) 1.0f else 0.88f) }
    var isFirstComposition by remember { mutableStateOf(true) }
    LaunchedEffect(isCompleted) {
        if (isFirstComposition) {
            isFirstComposition = false
            return@LaunchedEffect
        }
        if (isCompleted) {
            checkScale.animateTo(
                targetValue = 1.15f,
                animationSpec = tween(durationMillis = 110, easing = FastOutSlowInEasing)
            )
            checkScale.animateTo(
                targetValue = 1.0f,
                animationSpec = spring(
                    dampingRatio = Spring.DampingRatioMediumBouncy,
                    stiffness = Spring.StiffnessLow
                )
            )
        } else {
            checkScale.animateTo(
                targetValue = 0.88f,
                animationSpec = spring(
                    dampingRatio = Spring.DampingRatioNoBouncy,
                    stiffness = Spring.StiffnessMedium
                )
            )
        }
    }

    val iconScale = animateFloatAsState(
        targetValue = if (isCompleted) 1.0f else 0.0f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessMedium
        ),
        label = "iconScale"
    )

    val iconRotation = animateFloatAsState(
        targetValue = if (isCompleted) 0f else -12f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessMedium
        ),
        label = "iconRotation"
    )

    val iconAlpha = animateFloatAsState(
        targetValue = if (isCompleted) 1.0f else 0.0f,
        animationSpec = tween(durationMillis = 180, easing = FastOutSlowInEasing),
        label = "iconAlpha"
    )

    val checkBgColor = animateColorAsState(
        targetValue = if (isCompleted) ChunkyColor.SuccessGreen else Color.Transparent,
        animationSpec = tween(durationMillis = 200),
        label = "checkBgColor"
    )

    val checkBorderColor = animateColorAsState(
        targetValue = if (isCompleted) ChunkyColor.SuccessGreen else UncheckedBorderColor,
        animationSpec = tween(durationMillis = 200),
        label = "checkBorderColor"
    )

    val strikethroughProgress = animateFloatAsState(
        targetValue = if (isCompleted) 1.0f else 0.0f,
        animationSpec = tween(durationMillis = 260, easing = FastOutSlowInEasing),
        label = "strikethroughProgress"
    )

    val titleAlpha = animateFloatAsState(
        targetValue = if (isCompleted) 0.60f else 1.0f,
        animationSpec = tween(durationMillis = 220),
        label = "titleAlpha"
    )

    val textLayoutResultHolder = remember(coursework.id, coursework.title) { arrayOfNulls<TextLayoutResult>(1) }
    val onTextLayout: (TextLayoutResult) -> Unit = remember(textLayoutResultHolder) {
        { textLayoutResultHolder[0] = it }
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

    Row(
        modifier = modifier
            .fillMaxWidth()
            .graphicsLayer {
                scaleX = cardScaleX.value
                scaleY = cardScaleY.value
            }
            .clip(RoundedCornerShape(12.dp))
            .background(ChunkyColor.SurfaceWhite)
            .border(1.dp, ChunkyColor.CardBorder, RoundedCornerShape(12.dp)),
        verticalAlignment = Alignment.Top
    ) {
        Box(
            modifier = Modifier
                .padding(start = 4.dp, top = 2.dp)
                .size(48.dp)
                .clip(CircleShape)
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
                    .size(24.dp)
                    .graphicsLayer {
                        val combinedScale = checkScale.value * checkPressScale.value
                        scaleX = combinedScale
                        scaleY = combinedScale
                    }
                    .drawWithCache {
                        val strokeWidthPx = 2.dp.toPx()
                        val stroke = Stroke(width = strokeWidthPx)
                        val radius = (size.minDimension - strokeWidthPx) / 2f
                        onDrawBehind {
                            drawCircle(color = checkBgColor.value)
                            drawCircle(
                                color = checkBorderColor.value,
                                radius = radius,
                                style = stroke
                            )
                        }
                    },
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Check,
                    contentDescription = "Completed",
                    tint = Color.White,
                    modifier = Modifier
                        .size(16.dp)
                        .graphicsLayer {
                            scaleX = iconScale.value
                            scaleY = iconScale.value
                            rotationZ = iconRotation.value
                            alpha = iconAlpha.value
                        }
                )
            }
        }

        Row(
            modifier = Modifier
                .weight(1f)
                .clip(RoundedCornerShape(topEnd = 12.dp, bottomEnd = 12.dp))
                .clickable(
                    interactionSource = cardInteractionSource,
                    indication = ripple(),
                    onClick = onClick
                )
                .padding(start = 4.dp, end = 16.dp, top = 12.dp, bottom = 12.dp),
            verticalAlignment = Alignment.Top
        ) {
            SubjectBadgePill(
                courseName = coursework.courseName,
                title = coursework.title,
                modifier = Modifier.padding(top = 1.dp)
            )

            Spacer(modifier = Modifier.width(12.dp))

            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = coursework.title,
                    color = ChunkyColor.TextPrimary,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 16.sp,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    onTextLayout = onTextLayout,
                    modifier = Modifier
                        .graphicsLayer { alpha = titleAlpha.value }
                        .drawWithCache {
                            val strokeWidthPx = 2.dp.toPx()
                            onDrawWithContent {
                                drawContent()
                                val progress = strikethroughProgress.value
                                if (progress > 0.001f) {
                                    val layout = textLayoutResultHolder[0]
                                    if (layout != null) {
                                        for (i in 0 until layout.lineCount) {
                                            val lineTop = layout.getLineTop(i)
                                            val lineBottom = layout.getLineBottom(i)
                                            val lineLeft = layout.getLineLeft(i)
                                            val lineRight = layout.getLineRight(i)
                                            val y = (lineTop + lineBottom) / 2f
                                            val endX = lineLeft + (lineRight - lineLeft) * progress
                                            drawLine(
                                                color = StrikethroughLineColor,
                                                start = Offset(lineLeft, y),
                                                end = Offset(endX, y),
                                                strokeWidth = strokeWidthPx,
                                                cap = StrokeCap.Round
                                            )
                                        }
                                    } else {
                                        val y = size.height / 2f
                                        val endX = size.width * progress
                                        drawLine(
                                            color = StrikethroughLineColor,
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
                Spacer(modifier = Modifier.height(2.dp))
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = coursework.courseName,
                        color = ChunkyColor.TextMuted,
                        fontSize = 13.sp,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f, fill = false)
                    )
                    if (hasNote) {
                        Spacer(modifier = Modifier.width(4.dp))
                        Icon(
                            imageVector = Icons.Default.EditNote,
                            contentDescription = "Có ghi chú",
                            tint = ChunkyColor.SkyBottom,
                            modifier = Modifier.size(16.dp)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.width(8.dp))

            DueDateBadge(
                text = coursework.compactDueString,
                isCompleted = isCompleted,
                isOverdue = isOverdue || coursework.isPast,
                isDueToday = coursework.isDueToday,
                isDueTomorrow = coursework.isDueTomorrow,
                fontSize = 12.sp,
                modifier = Modifier.padding(top = 1.dp)
            )
        }
    }
}
