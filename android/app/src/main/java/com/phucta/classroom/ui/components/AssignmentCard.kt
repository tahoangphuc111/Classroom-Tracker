package com.phucta.classroom.ui.components

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
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.ui.theme.ChunkyColor

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

    // Tactile card press animation with snappy spring
    val cardInteractionSource = remember { MutableInteractionSource() }
    val isCardPressed by cardInteractionSource.collectIsPressedAsState()
    val cardScale by animateFloatAsState(
        targetValue = if (isCardPressed) 0.985f else 1.0f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessLow
        ),
        label = "cardScale"
    )

    // Checkbox press feedback & elastic bounce/scale pop (1.15f -> 1.0f)
    val checkInteractionSource = remember { MutableInteractionSource() }
    val isCheckPressed by checkInteractionSource.collectIsPressedAsState()
    val checkPressScale by animateFloatAsState(
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
            // Elastic spring bounce / scale pop: 1.15f -> 1.0f
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

    // Smooth checkmark reveal (scale + alpha)
    val iconScale by animateFloatAsState(
        targetValue = if (isCompleted) 1.0f else 0.0f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessMedium
        ),
        label = "iconScale"
    )

    val iconAlpha by animateFloatAsState(
        targetValue = if (isCompleted) 1.0f else 0.0f,
        animationSpec = tween(durationMillis = 180, easing = FastOutSlowInEasing),
        label = "iconAlpha"
    )

    val checkBgColor by animateColorAsState(
        targetValue = if (isCompleted) ChunkyColor.SuccessGreen else Color.Transparent,
        animationSpec = tween(durationMillis = 200),
        label = "checkBgColor"
    )

    val checkBorderColor by animateColorAsState(
        targetValue = if (isCompleted) ChunkyColor.SuccessGreen else ChunkyColor.TextMuted.copy(alpha = 0.5f),
        animationSpec = tween(durationMillis = 200),
        label = "checkBorderColor"
    )

    // Smooth text strikethrough transition & color fade
    val strikethroughProgress by animateFloatAsState(
        targetValue = if (isCompleted) 1.0f else 0.0f,
        animationSpec = tween(durationMillis = 260, easing = FastOutSlowInEasing),
        label = "strikethroughProgress"
    )

    val titleColor by animateColorAsState(
        targetValue = if (isCompleted) ChunkyColor.TextMuted else ChunkyColor.TextPrimary,
        animationSpec = tween(durationMillis = 220),
        label = "titleColor"
    )

    val titleAlpha by animateFloatAsState(
        targetValue = if (isCompleted) 0.60f else 1.0f,
        animationSpec = tween(durationMillis = 220),
        label = "titleAlpha"
    )

    var textLayoutResult by remember { mutableStateOf<TextLayoutResult?>(null) }

    Row(
        modifier = modifier
            .fillMaxWidth()
            .graphicsLayer {
                scaleX = cardScale
                scaleY = cardScale
            }
            .clip(RoundedCornerShape(12.dp))
            .background(ChunkyColor.SurfaceWhite)
            .border(1.dp, ChunkyColor.CardBorder, RoundedCornerShape(12.dp)),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .padding(start = 4.dp, top = 2.dp, bottom = 2.dp)
                .size(48.dp)
                .clip(CircleShape)
                .clickable(
                    interactionSource = checkInteractionSource,
                    indication = ripple(bounded = false, radius = 22.dp),
                    role = Role.Checkbox,
                    onClick = { onToggleCompletion(!isCompleted) }
                ),
            contentAlignment = Alignment.Center
        ) {
            Box(
                modifier = Modifier
                    .size(22.dp)
                    .graphicsLayer {
                        val combinedScale = checkScale.value * checkPressScale
                        scaleX = combinedScale
                        scaleY = combinedScale
                    }
                    .clip(CircleShape)
                    .background(color = checkBgColor)
                    .border(
                        width = 1.75.dp,
                        color = checkBorderColor,
                        shape = CircleShape
                    ),
                contentAlignment = Alignment.Center
            ) {
                if (iconScale > 0.01f) {
                    Icon(
                        imageVector = Icons.Default.Check,
                        contentDescription = "Completed",
                        tint = Color.White,
                        modifier = Modifier
                            .size(15.dp)
                            .graphicsLayer {
                                scaleX = iconScale
                                scaleY = iconScale
                                alpha = iconAlpha
                            }
                    )
                }
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
                .padding(start = 4.dp, end = 14.dp, top = 13.dp, bottom = 13.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            SubjectBadgePill(
                courseName = coursework.courseName,
                title = coursework.title
            )

            Spacer(modifier = Modifier.width(10.dp))

            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = coursework.title,
                    color = titleColor,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 15.5.sp,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    onTextLayout = { textLayoutResult = it },
                    modifier = Modifier
                        .graphicsLayer { alpha = titleAlpha }
                        .drawWithContent {
                            drawContent()
                            if (strikethroughProgress > 0.001f) {
                                textLayoutResult?.let { layout ->
                                    for (i in 0 until layout.lineCount) {
                                        val lineTop = layout.getLineTop(i)
                                        val lineBottom = layout.getLineBottom(i)
                                        val lineLeft = layout.getLineLeft(i)
                                        val lineRight = layout.getLineRight(i)
                                        val y = (lineTop + lineBottom) / 2f
                                        val endX = lineLeft + (lineRight - lineLeft) * strikethroughProgress
                                        drawLine(
                                            color = ChunkyColor.TextMuted.copy(alpha = 0.85f),
                                            start = Offset(lineLeft, y),
                                            end = Offset(endX, y),
                                            strokeWidth = 1.75.dp.toPx(),
                                            cap = StrokeCap.Round
                                        )
                                    }
                                }
                            }
                        }
                )
                Spacer(modifier = Modifier.height(2.5.dp))
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
                            modifier = Modifier.size(15.dp)
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
                fontSize = 12.sp
            )
        }
    }
}
