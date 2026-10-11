package com.phucta.classroom.ui.components

import androidx.compose.foundation.background
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
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.phucta.classroom.ui.theme.OutfitFontFamily

@Composable
fun SubjectBadgePill(
    courseName: String,
    modifier: Modifier = Modifier,
    title: String? = null
) {
    val theme = SubjectArtHelper.theme(courseName, title)

    Box(
        modifier = modifier
            .clip(RoundedCornerShape(6.dp))
            .background(theme.color)
            .padding(horizontal = 8.dp, vertical = 3.5.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = theme.badgeCode,
            color = Color.White,
            fontFamily = OutfitFontFamily,
            fontWeight = FontWeight.Bold,
            fontSize = 11.sp,
            letterSpacing = 0.5.sp,
            maxLines = 1,
            softWrap = false
        )
    }
}
