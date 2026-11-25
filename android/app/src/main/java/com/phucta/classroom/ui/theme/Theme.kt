package com.phucta.classroom.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp

val ClassroomLightColorScheme = lightColorScheme(
    primary = Color(0xFF0265CD),
    onPrimary = Color(0xFFFFFFFF),
    primaryContainer = Color(0xFFDCEEFF),
    onPrimaryContainer = Color(0xFF003268),
    secondary = Color(0xFF0369A1),
    onSecondary = Color(0xFFFFFFFF),
    secondaryContainer = Color(0xFFE0F2FE),
    onSecondaryContainer = Color(0xFF0C4A6E),
    tertiary = Color(0xFFB45309),
    onTertiary = Color(0xFFFFFFFF),
    tertiaryContainer = Color(0xFFFEF3C7),
    onTertiaryContainer = Color(0xFF78350F),
    error = Color(0xFFB91C1C),
    onError = Color(0xFFFFFFFF),
    errorContainer = Color(0xFFFEE2E2),
    onErrorContainer = Color(0xFF7F1D1D),
    background = Color(0xFFF6F7F9),
    onBackground = Color(0xFF1A2233),
    surface = Color(0xFFF6F7F9),
    onSurface = Color(0xFF1A2233),
    surfaceVariant = Color(0xFFEAEFF5),
    onSurfaceVariant = Color(0xFF475569),
    surfaceContainerLowest = Color(0xFFFFFFFF),
    surfaceContainerLow = Color(0xFFF8FAFC),
    surfaceContainer = Color(0xFFF1F5F9),
    surfaceContainerHigh = Color(0xFFE9EFF6),
    surfaceContainerHighest = Color(0xFFE2E8F0),
    outline = Color(0xFF94A3B8),
    outlineVariant = Color(0xFFE2E8F0)
)

val ClassroomDarkColorScheme = darkColorScheme(
    primary = Color(0xFF7CC4FF),
    onPrimary = Color(0xFF00325A),
    primaryContainer = Color(0xFF004980),
    onPrimaryContainer = Color(0xFFD6E9FF),
    secondary = Color(0xFF7DD3FC),
    onSecondary = Color(0xFF003549),
    secondaryContainer = Color(0xFF074D6E),
    onSecondaryContainer = Color(0xFFCFF0FF),
    tertiary = Color(0xFFFBBF24),
    onTertiary = Color(0xFF451A03),
    tertiaryContainer = Color(0xFF78350F),
    onTertiaryContainer = Color(0xFFFEF3C7),
    error = Color(0xFFFCA5A5),
    onError = Color(0xFF690005),
    errorContainer = Color(0xFF7F1D1D),
    onErrorContainer = Color(0xFFFEE2E2),
    background = Color(0xFF111418),
    onBackground = Color(0xFFE4E8F0),
    surface = Color(0xFF111418),
    onSurface = Color(0xFFE4E8F0),
    surfaceVariant = Color(0xFF232A35),
    onSurfaceVariant = Color(0xFFA8B3C5),
    surfaceContainerLowest = Color(0xFF0C0F13),
    surfaceContainerLow = Color(0xFF171C23),
    surfaceContainer = Color(0xFF1D232C),
    surfaceContainerHigh = Color(0xFF252C37),
    surfaceContainerHighest = Color(0xFF2E3644),
    outline = Color(0xFF64748B),
    outlineVariant = Color(0xFF2E3746)
)

val ClassroomShapes = Shapes(
    extraSmall = RoundedCornerShape(6.dp),
    small = RoundedCornerShape(8.dp),
    medium = RoundedCornerShape(12.dp),
    large = RoundedCornerShape(16.dp),
    extraLarge = RoundedCornerShape(28.dp)
)

@Composable
fun ClassroomTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) ClassroomDarkColorScheme else ClassroomLightColorScheme
    MaterialTheme(
        colorScheme = colorScheme,
        typography = ClassroomTypography,
        shapes = ClassroomShapes,
        content = content
    )
}
