package com.phucta.classroom.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.phucta.classroom.R

val BeVietnamProFontFamily = FontFamily(
    Font(R.font.be_vietnam_pro_medium, FontWeight.Medium),
    Font(R.font.be_vietnam_pro_semibold, FontWeight.SemiBold),
    Font(R.font.be_vietnam_pro_bold, FontWeight.Bold),
    Font(R.font.be_vietnam_pro_extrabold, FontWeight.ExtraBold)
)

val OutfitFontFamily = FontFamily(
    Font(R.font.outfit, FontWeight.Normal),
    Font(R.font.outfit, FontWeight.Bold)
)

val ClassroomTypography = Typography(
    headlineLarge = TextStyle(
        fontFamily = BeVietnamProFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 24.sp
    ),
    headlineMedium = TextStyle(
        fontFamily = BeVietnamProFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 20.sp
    ),
    titleLarge = TextStyle(
        fontFamily = BeVietnamProFontFamily,
        fontWeight = FontWeight.SemiBold,
        fontSize = 18.sp
    ),
    titleMedium = TextStyle(
        fontFamily = BeVietnamProFontFamily,
        fontWeight = FontWeight.SemiBold,
        fontSize = 15.sp
    ),
    bodyLarge = TextStyle(
        fontFamily = BeVietnamProFontFamily,
        fontWeight = FontWeight.Medium,
        fontSize = 14.sp
    ),
    bodyMedium = TextStyle(
        fontFamily = BeVietnamProFontFamily,
        fontWeight = FontWeight.Medium,
        fontSize = 12.sp,
        color = ChunkyColor.TextMuted
    ),
    labelSmall = TextStyle(
        fontFamily = BeVietnamProFontFamily,
        fontWeight = FontWeight.SemiBold,
        fontSize = 11.sp,
        color = ChunkyColor.TextMuted
    )
)
