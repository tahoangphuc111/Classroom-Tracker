package com.phucta.classroom.ui.theme

import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color

object ChunkyColor {
    val SkyTop = Color(0xFF61C7FF)
    val SkyBottom = Color(0xFF249EFA)

    val EmberTop = Color(0xFFFF7A38)
    val EmberBottom = Color(0xFFF05226)
    val EmberCore = Color(0xFFFFDC61)

    val TextPrimary = Color(0xFF1F293D)
    val TextMuted = Color(0xFF7587A3)
    val TextTertiary = Color(0xFF9EABB8)

    val UrgentAccent = Color(0xFFF04047)
    val ButterYellow = Color(0xFFFFDC61)
    val PillBlue = Color(0xFF3385D1)
    val SuccessGreen = Color(0xFF2E7D32)

    val WindowBackground = Color(0xFFF6F7F9)
    val SurfaceWhite = Color(0xFFFFFFFF)
    val SidebarBackground = Color(0xFFF2F3F5)

    val CardBorder = Color(0x0F000000)
    val CardHoverBorder = Color(0x1F000000)
    val Hairline = Color(0x0D000000)

    val SkyGradient = Brush.linearGradient(
        colors = listOf(SkyTop, SkyBottom)
    )

    val EmberGradient = Brush.verticalGradient(
        colors = listOf(EmberTop, EmberBottom)
    )
}
