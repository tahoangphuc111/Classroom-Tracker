package com.phucta.classroom.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
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
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.height
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.semantics.Role
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.ui.theme.ChunkyColor
import com.phucta.classroom.ui.theme.OutfitFontFamily

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

    val checkScale by animateFloatAsState(
        targetValue = if (isCompleted) 1.0f else 0.88f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessMedium
        ),
        label = "checkScale"
    )

    val iconScale by animateFloatAsState(
        targetValue = if (isCompleted) 1.0f else 0.0f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = Spring.StiffnessMedium
        ),
        label = "iconScale"
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

    val titleAlpha by animateFloatAsState(
        targetValue = if (isCompleted) 0.60f else 1.0f,
        animationSpec = tween(durationMillis = 200),
        label = "titleAlpha"
    )

    Row(
        modifier = modifier
            .fillMaxWidth()
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
                    role = Role.Checkbox,
                    onClick = { onToggleCompletion(!isCompleted) }
                ),
            contentAlignment = Alignment.Center
        ) {
            Box(
                modifier = Modifier
                    .size(22.dp)
                    .graphicsLayer {
                        scaleX = checkScale
                        scaleY = checkScale
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
                            }
                    )
                }
            }
        }

        Row(
            modifier = Modifier
                .weight(1f)
                .clip(RoundedCornerShape(topEnd = 12.dp, bottomEnd = 12.dp))
                .clickable(onClick = onClick)
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
                        color = if (isCompleted) ChunkyColor.TextMuted else ChunkyColor.TextPrimary,
                        fontWeight = FontWeight.SemiBold,
                        fontSize = 15.5.sp,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                        textDecoration = if (isCompleted) TextDecoration.LineThrough else TextDecoration.None,
                        modifier = Modifier.graphicsLayer { alpha = titleAlpha }
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
