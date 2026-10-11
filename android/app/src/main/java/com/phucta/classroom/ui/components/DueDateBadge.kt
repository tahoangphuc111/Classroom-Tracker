package com.phucta.classroom.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.phucta.classroom.ui.theme.ChunkyColor
import com.phucta.classroom.ui.theme.OutfitFontFamily

data class DueDateBadgeColors(
    val background: Color,
    val border: Color,
    val text: Color
)

object DueDateBadgeDefaults {
    fun colors(
        isCompleted: Boolean,
        isOverdue: Boolean,
        isDueToday: Boolean,
        isDueTomorrow: Boolean
    ): DueDateBadgeColors {
        return when {
            isCompleted -> DueDateBadgeColors(
                background = ChunkyColor.CompletedBadgeBackground,
                border = ChunkyColor.CompletedBadgeBorder,
                text = ChunkyColor.CompletedBadgeText
            )
            isOverdue -> DueDateBadgeColors(
                background = ChunkyColor.OverdueBackground,
                border = ChunkyColor.OverdueBorder,
                text = ChunkyColor.OverdueText
            )
            isDueToday -> DueDateBadgeColors(
                background = ChunkyColor.TodayBackground,
                border = ChunkyColor.TodayBorder,
                text = ChunkyColor.TodayText
            )
            isDueTomorrow -> DueDateBadgeColors(
                background = ChunkyColor.TomorrowBackground,
                border = ChunkyColor.TomorrowBorder,
                text = ChunkyColor.TomorrowText
            )
            else -> DueDateBadgeColors(
                background = ChunkyColor.NeutralBadgeBackground,
                border = ChunkyColor.NeutralBadgeBorder,
                text = ChunkyColor.NeutralBadgeText
            )
        }
    }
}

@Composable
fun DueDateBadge(
    text: String,
    modifier: Modifier = Modifier,
    isCompleted: Boolean = false,
    isOverdue: Boolean = false,
    isDueToday: Boolean = false,
    isDueTomorrow: Boolean = false,
    fontSize: TextUnit = 12.sp
) {
    val colors = DueDateBadgeDefaults.colors(
        isCompleted = isCompleted,
        isOverdue = isOverdue,
        isDueToday = isDueToday,
        isDueTomorrow = isDueTomorrow
    )

    Box(
        modifier = modifier
            .clip(RoundedCornerShape(6.dp))
            .background(colors.background)
            .border(1.dp, colors.border, RoundedCornerShape(6.dp))
            .padding(horizontal = 7.5.dp, vertical = 3.5.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text,
            color = colors.text,
            fontFamily = OutfitFontFamily,
            fontWeight = FontWeight.Bold,
            fontSize = fontSize,
            maxLines = 1
        )
    }
}
