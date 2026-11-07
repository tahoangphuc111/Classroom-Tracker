package com.phucta.classroom.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.phucta.classroom.ui.theme.BeVietnamProFontFamily

private val BadgeShape = RoundedCornerShape(7.dp)

@Composable
fun SubjectBadgePill(
    courseName: String,
    modifier: Modifier = Modifier,
    title: String? = null
) {
    val theme = remember(courseName, title) {
        SubjectArtHelper.theme(courseName, title)
    }

    Row(
        modifier = modifier
            .clip(BadgeShape)
            .background(theme.backgroundColor, shape = BadgeShape)
            .border(1.dp, theme.borderColor, BadgeShape)
            .padding(horizontal = 8.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(4.5.dp)
    ) {
        Icon(
            painter = painterResource(id = theme.iconRes),
            contentDescription = null,
            tint = theme.textColor,
            modifier = Modifier.size(14.dp)
        )
        Text(
            text = theme.badgeCode,
            color = theme.textColor,
            fontFamily = BeVietnamProFontFamily,
            fontWeight = FontWeight.Bold,
            fontSize = 12.sp,
            letterSpacing = 0.4.sp,
            maxLines = 1,
            softWrap = false
        )
    }
}
