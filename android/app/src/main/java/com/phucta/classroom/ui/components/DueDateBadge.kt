package com.phucta.classroom.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Immutable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.TextUnit
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.phucta.classroom.ui.theme.ChunkyColor
import com.phucta.classroom.ui.theme.OutfitFontFamily

@Immutable
data class DueDateBadgeColors(
    val background: Color,
    val border: Color,
    val text: Color
)

object DueDateBadgeDefaults {
    private val completedColors = DueDateBadgeColors(
        background = ChunkyColor.CompletedBadgeBackground,
        border = ChunkyColor.CompletedBadgeBorder,
        text = ChunkyColor.CompletedBadgeText
    )
    private val overdueColors = DueDateBadgeColors(
        background = ChunkyColor.OverdueBackground,
        border = ChunkyColor.OverdueBorder,
        text = ChunkyColor.OverdueText
    )
    private val todayColors = DueDateBadgeColors(
        background = ChunkyColor.TodayBackground,
        border = ChunkyColor.TodayBorder,
        text = ChunkyColor.TodayText
    )
    private val tomorrowColors = DueDateBadgeColors(
        background = ChunkyColor.TomorrowBackground,
        border = ChunkyColor.TomorrowBorder,
        text = ChunkyColor.TomorrowText
    )
    private val neutralColors = DueDateBadgeColors(
        background = ChunkyColor.NeutralBadgeBackground,
        border = ChunkyColor.NeutralBadgeBorder,
        text = ChunkyColor.NeutralBadgeText
    )

    fun colors(
        isCompleted: Boolean,
        isOverdue: Boolean,
        isDueToday: Boolean,
        isDueTomorrow: Boolean,
        isUrgent: Boolean = false
    ): DueDateBadgeColors {
        return when {
            isCompleted -> completedColors
            isOverdue || isUrgent -> overdueColors
            isDueToday -> todayColors
            isDueTomorrow -> tomorrowColors
            else -> neutralColors
        }
    }
}

private val BadgeShape = RoundedCornerShape(6.dp)

@Composable
fun DueDateBadge(
    text: String,
    modifier: Modifier = Modifier,
    isCompleted: Boolean = false,
    isOverdue: Boolean = false,
    isDueToday: Boolean = false,
    isDueTomorrow: Boolean = false,
    isUrgent: Boolean = false,
    fontSize: TextUnit = 12.sp
) {
    val colors = DueDateBadgeDefaults.colors(
        isCompleted = isCompleted,
        isOverdue = isOverdue,
        isDueToday = isDueToday,
        isDueTomorrow = isDueTomorrow,
        isUrgent = isUrgent
    )

    Box(
        modifier = modifier
            .background(colors.background, shape = BadgeShape)
            .border(1.dp, colors.border, BadgeShape)
            .padding(horizontal = 8.dp, vertical = 4.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text,
            color = colors.text,
            fontFamily = OutfitFontFamily,
            fontWeight = FontWeight.Bold,
            fontSize = fontSize,
            maxLines = 1,
            softWrap = false
        )
    }
}
