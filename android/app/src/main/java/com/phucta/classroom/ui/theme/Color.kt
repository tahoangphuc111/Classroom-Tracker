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

    val CardBorder = Color(0xFFE2E8F0)
    val CardHoverBorder = Color(0xFFCBD5E1)
    val Hairline = Color(0xFFE2E8F0)

    val OverdueText = Color(0xFFB91C1C)
    val OverdueBackground = Color(0xFFFEE2E2)
    val OverdueBorder = Color(0xFFFECACA)

    val TodayText = Color(0xFFC2410C)
    val TodayBackground = Color(0xFFFFEDD5)
    val TodayBorder = Color(0xFFFED7AA)

    val TomorrowText = Color(0xFF0369A1)
    val TomorrowBackground = Color(0xFFE0F2FE)
    val TomorrowBorder = Color(0xFFBAE6FD)

    val NeutralBadgeText = Color(0xFF475569)
    val NeutralBadgeBackground = Color(0xFFF1F5F9)
    val NeutralBadgeBorder = Color(0xFFE2E8F0)

    val CompletedBadgeText = Color(0xFF15803D)
    val CompletedBadgeBackground = Color(0xFFDCFCE7)
    val CompletedBadgeBorder = Color(0xFFBBF7D0)

    val HeaderOverdue = Color(0xFFDC2626)
    val HeaderToday = Color(0xFFEA580C)
    val HeaderTomorrow = Color(0xFF0284C7)
    val HeaderUpcoming = Color(0xFF475569)
    val HeaderCompleted = Color(0xFF16A34A)

    val SkyGradient = Brush.linearGradient(
        colors = listOf(SkyTop, SkyBottom)
    )

    val EmberGradient = Brush.verticalGradient(
        colors = listOf(EmberTop, EmberBottom)
    )
}
