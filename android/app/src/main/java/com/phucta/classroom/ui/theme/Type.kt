package com.phucta.classroom.ui.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import com.phucta.classroom.R

val BeVietnamProFontFamily = FontFamily(
    Font(R.font.be_vietnam_pro_semibold, FontWeight.Normal),
    Font(R.font.be_vietnam_pro_semibold, FontWeight.Medium),
    Font(R.font.be_vietnam_pro_bold, FontWeight.SemiBold),
    Font(R.font.be_vietnam_pro_extrabold, FontWeight.Bold),
    Font(R.font.be_vietnam_pro_extrabold, FontWeight.ExtraBold)
)

val OutfitFontFamily = BeVietnamProFontFamily

val ClassroomTypography = Typography(
    displayLarge = TextStyle(
        fontFamily = BeVietnamProFontFamily,
        fontWeight = FontWeight.ExtraBold,
        fontSize = 34.sp,
        lineHeight = 42.sp,
        color = ChunkyColor.TextPrimary
    ),
    displayMedium = TextStyle(
        fontFamily = BeVietnamProFontFamily,
        fontWeight = FontWeight.ExtraBold,
        fontSize = 30.sp,
        lineHeight = 38.sp,
        color = ChunkyColor.TextPrimary
    ),
    displaySmall = TextStyle(
        fontFamily = BeVietnamProFontFamily,
        fontWeight = FontWeight.ExtraBold,
        fontSize = 26.sp,
        lineHeight = 34.sp,
        color = ChunkyColor.TextPrimary
    ),
    headlineLarge = TextStyle(
        fontFamily = BeVietnamProFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 25.sp,
        lineHeight = 33.sp,
        color = ChunkyColor.TextPrimary
    ),
    headlineMedium = TextStyle(
        fontFamily = BeVietnamProFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 22.sp,
        lineHeight = 29.sp,
        color = ChunkyColor.TextPrimary
    ),
    headlineSmall = TextStyle(
        fontFamily = BeVietnamProFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 19.sp,
        lineHeight = 25.sp,
        color = ChunkyColor.TextPrimary
    ),
    titleLarge = TextStyle(
        fontFamily = BeVietnamProFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 19.sp,
        lineHeight = 25.sp,
        color = ChunkyColor.TextPrimary
    ),
    titleMedium = TextStyle(
        fontFamily = BeVietnamProFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 16.5.sp,
        lineHeight = 22.sp,
        color = ChunkyColor.TextPrimary
    ),
    titleSmall = TextStyle(
        fontFamily = BeVietnamProFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 14.5.sp,
        lineHeight = 20.sp,
        color = ChunkyColor.TextPrimary
    ),
    bodyLarge = TextStyle(
        fontFamily = BeVietnamProFontFamily,
        fontWeight = FontWeight.SemiBold,
        fontSize = 15.5.sp,
        lineHeight = 22.sp,
        color = ChunkyColor.TextPrimary
    ),
    bodyMedium = TextStyle(
        fontFamily = BeVietnamProFontFamily,
        fontWeight = FontWeight.SemiBold,
        fontSize = 13.5.sp,
        lineHeight = 19.sp,
        color = ChunkyColor.TextMuted
    ),
    bodySmall = TextStyle(
        fontFamily = BeVietnamProFontFamily,
        fontWeight = FontWeight.SemiBold,
        fontSize = 12.sp,
        lineHeight = 17.sp,
        color = ChunkyColor.TextMuted
    ),
    labelLarge = TextStyle(
        fontFamily = BeVietnamProFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 15.sp,
        lineHeight = 20.sp,
        color = ChunkyColor.TextPrimary
    ),
    labelMedium = TextStyle(
        fontFamily = BeVietnamProFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 13.sp,
        lineHeight = 18.sp,
        color = ChunkyColor.TextPrimary
    ),
    labelSmall = TextStyle(
        fontFamily = BeVietnamProFontFamily,
        fontWeight = FontWeight.Bold,
        fontSize = 12.sp,
        lineHeight = 16.sp,
        color = ChunkyColor.TextMuted
    )
)
