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
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.phucta.classroom.data.model.Coursework
import com.phucta.classroom.ui.theme.ChunkyColor
import com.phucta.classroom.ui.theme.OutfitFontFamily

@Composable
fun AssignmentCard(
    coursework: Coursework,
    onToggleCompletion: (Boolean) -> Unit,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val isCompleted = coursework.isCompleted
    val isOverdue = coursework.isOverdue

    Box(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(ChunkyColor.SurfaceWhite)
            .border(1.dp, ChunkyColor.CardBorder, RoundedCornerShape(12.dp))
            .clickable { onClick() }
            .padding(horizontal = 14.dp, vertical = 12.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Completion Checkbox
            Box(
                modifier = Modifier
                    .size(24.dp)
                    .clip(CircleShape)
                    .background(
                        if (isCompleted) ChunkyColor.SuccessGreen else Color.Transparent
                    )
                    .border(
                        width = 1.5.dp,
                        color = if (isCompleted) ChunkyColor.SuccessGreen else ChunkyColor.TextMuted.copy(alpha = 0.5f),
                        shape = CircleShape
                    )
                    .clickable { onToggleCompletion(!isCompleted) },
                contentAlignment = Alignment.Center
            ) {
                if (isCompleted) {
                    Icon(
                        imageVector = Icons.Default.Check,
                        contentDescription = "Completed",
                        tint = Color.White,
                        modifier = Modifier.size(16.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.width(12.dp))

            // Subject Pill
            SubjectBadgePill(
                courseName = coursework.courseName,
                title = coursework.title
            )

            Spacer(modifier = Modifier.width(10.dp))

            // Title & Course
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = coursework.title,
                    color = if (isCompleted) ChunkyColor.TextMuted else ChunkyColor.TextPrimary,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 14.sp,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    textDecoration = if (isCompleted) TextDecoration.LineThrough else TextDecoration.None
                )
                Text(
                    text = coursework.courseName,
                    color = ChunkyColor.TextMuted,
                    fontSize = 12.sp,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }

            Spacer(modifier = Modifier.width(8.dp))

            // Due Time Badge / Status
            val badgeBg = when {
                isCompleted -> ChunkyColor.SuccessGreen.copy(alpha = 0.12f)
                isOverdue -> ChunkyColor.UrgentAccent.copy(alpha = 0.12f)
                coursework.isDueToday -> ChunkyColor.EmberTop.copy(alpha = 0.12f)
                coursework.isDueTomorrow -> ChunkyColor.SkyBottom.copy(alpha = 0.12f)
                else -> Color.Black.copy(alpha = 0.05f)
            }
            val badgeTextColor = when {
                isCompleted -> ChunkyColor.SuccessGreen
                isOverdue -> ChunkyColor.UrgentAccent
                coursework.isDueToday -> ChunkyColor.EmberTop
                coursework.isDueTomorrow -> ChunkyColor.SkyBottom
                else -> ChunkyColor.TextMuted
            }

            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(6.dp))
                    .background(badgeBg)
                    .padding(horizontal = 7.dp, vertical = 3.dp)
            ) {
                Text(
                    text = coursework.compactDueString,
                    color = badgeTextColor,
                    fontFamily = OutfitFontFamily,
                    fontWeight = FontWeight.SemiBold,
                    fontSize = 11.sp
                )
            }
        }
    }
}
