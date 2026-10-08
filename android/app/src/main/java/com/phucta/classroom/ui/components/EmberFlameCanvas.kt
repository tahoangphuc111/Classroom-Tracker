package com.phucta.classroom.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.phucta.classroom.ui.theme.ChunkyColor

enum class EmberEmotion {
    NORMAL,
    STRESSED,
    SLEEPING,
    CELEBRATING
}

@Composable
fun EmberFlameCanvas(
    modifier: Modifier = Modifier,
    size: Dp = 80.dp,
    emotion: EmberEmotion = EmberEmotion.NORMAL,
    isUrgent: Boolean = false
) {
    Canvas(modifier = modifier.size(size)) {
        val w = this.size.width
        val h = this.size.height

        // 1. Draw Outer Flame
        val outerPath = buildOuterFlamePath(w, h, isUrgent, emotion == EmberEmotion.SLEEPING)
        drawPath(
            path = outerPath,
            brush = Brush.verticalGradient(
                colors = listOf(ChunkyColor.EmberTop, ChunkyColor.EmberBottom)
            )
        )

        // 2. Draw Inner Flame Core
        val innerPath = buildInnerFlamePath(w, h, emotion == EmberEmotion.SLEEPING)
        drawPath(
            path = innerPath,
            brush = Brush.verticalGradient(
                colors = listOf(ChunkyColor.EmberCore, ChunkyColor.EmberTop)
            )
        )

        // 3. Draw Specular Gloss Highlight
        drawSpecularHighlight(w, h)

        // 4. Draw Cute Face & Expression
        drawEmberFace(w, h, emotion)
    }
}

private fun buildOuterFlamePath(w: Float, h: Float, isUrgent: Boolean, isSleeping: Boolean): Path {
    val cx = w * 0.50f
    val path = Path()

    path.moveTo(cx, h * 0.91f)
    path.cubicTo(
        w * 0.64f, h * 0.91f,
        w * 0.78f, h * 0.82f,
        w * 0.78f, h * 0.70f
    )
    path.cubicTo(
        w * 0.78f, h * 0.58f,
        w * 0.85f, h * 0.51f,
        w * 0.85f, h * 0.45f
    )
    path.cubicTo(
        w * 0.82f, h * 0.39f,
        w * 0.71f, h * 0.38f,
        w * 0.67f, h * 0.36f
    )

    val apexY = if (isUrgent) h * 0.05f else if (isSleeping) h * 0.10f else h * 0.08f
    val apexX = if (isSleeping) w * 0.63f else w * 0.61f

    path.cubicTo(
        w * 0.61f, h * 0.24f,
        w * 0.65f, h * 0.16f,
        apexX, apexY
    )
    path.cubicTo(
        w * 0.53f, apexY,
        w * 0.42f, h * 0.17f,
        w * 0.37f, h * 0.25f
    )
    path.cubicTo(
        w * 0.29f, h * 0.29f,
        w * 0.16f, h * 0.33f,
        w * 0.16f, h * 0.40f
    )
    path.cubicTo(
        w * 0.16f, h * 0.52f,
        w * 0.19f, h * 0.62f,
        w * 0.22f, h * 0.70f
    )
    path.cubicTo(
        w * 0.22f, h * 0.82f,
        w * 0.36f, h * 0.91f,
        cx, h * 0.91f
    )
    path.close()
    return path
}

private fun buildInnerFlamePath(w: Float, h: Float, isSleeping: Boolean): Path {
    val cx = w * 0.50f
    val path = Path()

    path.moveTo(cx, h * 0.86f)
    path.cubicTo(
        w * 0.62f, h * 0.86f,
        w * 0.73f, h * 0.78f,
        w * 0.73f, h * 0.67f
    )
    path.cubicTo(
        w * 0.73f, h * 0.58f,
        w * 0.78f, h * 0.52f,
        w * 0.78f, h * 0.47f
    )
    path.cubicTo(
        w * 0.76f, h * 0.41f,
        w * 0.67f, h * 0.40f,
        w * 0.63f, h * 0.39f
    )
    path.cubicTo(
        w * 0.58f, h * 0.28f,
        w * 0.61f, h * 0.22f,
        w * 0.58f, h * 0.18f
    )
    path.cubicTo(
        w * 0.52f, h * 0.18f,
        w * 0.44f, h * 0.25f,
        w * 0.40f, h * 0.31f
    )
    path.cubicTo(
        w * 0.33f, h * 0.35f,
        w * 0.23f, h * 0.38f,
        w * 0.23f, h * 0.44f
    )
    path.cubicTo(
        w * 0.23f, h * 0.54f,
        w * 0.25f, h * 0.61f,
        w * 0.27f, h * 0.67f
    )
    path.cubicTo(
        w * 0.27f, h * 0.78f,
        w * 0.38f, h * 0.86f,
        cx, h * 0.86f
    )
    path.close()
    return path
}

private fun DrawScope.drawSpecularHighlight(w: Float, h: Float) {
    val glossPath = Path()
    glossPath.moveTo(w * 0.58f, h * 0.11f)
    glossPath.cubicTo(
        w * 0.52f, h * 0.11f,
        w * 0.43f, h * 0.18f,
        w * 0.39f, h * 0.25f
    )
    drawPath(
        path = glossPath,
        color = Color.White.copy(alpha = 0.45f),
        style = Stroke(width = w * 0.035f, cap = StrokeCap.Round)
    )
}

private fun DrawScope.drawEmberFace(w: Float, h: Float, emotion: EmberEmotion) {
    val eyeColor = Color(0xFF1E2430)
    val blushColor = Color(0xFFFF8595).copy(alpha = 0.65f)

    when (emotion) {
        EmberEmotion.NORMAL -> {
            // Left eye
            drawCircle(color = eyeColor, radius = w * 0.045f, center = Offset(w * 0.40f, h * 0.58f))
            drawCircle(color = Color.White, radius = w * 0.018f, center = Offset(w * 0.385f, h * 0.565f))

            // Right eye
            drawCircle(color = eyeColor, radius = w * 0.045f, center = Offset(w * 0.60f, h * 0.58f))
            drawCircle(color = Color.White, radius = w * 0.018f, center = Offset(w * 0.585f, h * 0.565f))

            // Cute mouth
            val mouth = Path().apply {
                moveTo(w * 0.46f, h * 0.66f)
                quadraticBezierTo(w * 0.50f, h * 0.70f, w * 0.54f, h * 0.66f)
            }
            drawPath(mouth, color = eyeColor, style = Stroke(width = w * 0.025f, cap = StrokeCap.Round))
        }
        EmberEmotion.SLEEPING -> {
            // Sleeping eyes (^ ^)
            val leftEye = Path().apply {
                moveTo(w * 0.36f, h * 0.60f)
                quadraticBezierTo(w * 0.41f, h * 0.56f, w * 0.46f, h * 0.60f)
            }
            val rightEye = Path().apply {
                moveTo(w * 0.54f, h * 0.60f)
                quadraticBezierTo(w * 0.59f, h * 0.56f, w * 0.64f, h * 0.60f)
            }
            drawPath(leftEye, color = eyeColor, style = Stroke(width = w * 0.03f, cap = StrokeCap.Round))
            drawPath(rightEye, color = eyeColor, style = Stroke(width = w * 0.03f, cap = StrokeCap.Round))

            // Rosy cheeks
            drawCircle(color = blushColor, radius = w * 0.04f, center = Offset(w * 0.34f, h * 0.65f))
            drawCircle(color = blushColor, radius = w * 0.04f, center = Offset(w * 0.66f, h * 0.65f))

            // Gentle mouth
            val mouth = Path().apply {
                moveTo(w * 0.47f, h * 0.67f)
                quadraticBezierTo(w * 0.50f, h * 0.69f, w * 0.53f, h * 0.67f)
            }
            drawPath(mouth, color = eyeColor, style = Stroke(width = w * 0.022f, cap = StrokeCap.Round))
        }
        EmberEmotion.STRESSED -> {
            // Wide nervous eyes
            drawCircle(color = eyeColor, radius = w * 0.052f, center = Offset(w * 0.39f, h * 0.58f))
            drawCircle(color = Color.White, radius = w * 0.015f, center = Offset(w * 0.375f, h * 0.565f))

            drawCircle(color = eyeColor, radius = w * 0.052f, center = Offset(w * 0.61f, h * 0.58f))
            drawCircle(color = Color.White, radius = w * 0.015f, center = Offset(w * 0.595f, h * 0.565f))

            // Wavy mouth
            val mouth = Path().apply {
                moveTo(w * 0.44f, h * 0.68f)
                quadraticBezierTo(w * 0.47f, h * 0.65f, w * 0.50f, h * 0.68f)
                quadraticBezierTo(w * 0.53f, h * 0.71f, w * 0.56f, h * 0.68f)
            }
            drawPath(mouth, color = eyeColor, style = Stroke(width = w * 0.025f, cap = StrokeCap.Round))
        }
        EmberEmotion.CELEBRATING -> {
            // Happy star eyes or joyful arcs
            val leftEye = Path().apply {
                moveTo(w * 0.36f, h * 0.60f)
                quadraticBezierTo(w * 0.41f, h * 0.53f, w * 0.46f, h * 0.60f)
            }
            val rightEye = Path().apply {
                moveTo(w * 0.54f, h * 0.60f)
                quadraticBezierTo(w * 0.59f, h * 0.53f, w * 0.64f, h * 0.60f)
            }
            drawPath(leftEye, color = eyeColor, style = Stroke(width = w * 0.035f, cap = StrokeCap.Round))
            drawPath(rightEye, color = eyeColor, style = Stroke(width = w * 0.035f, cap = StrokeCap.Round))

            drawCircle(color = blushColor, radius = w * 0.045f, center = Offset(w * 0.33f, h * 0.64f))
            drawCircle(color = blushColor, radius = w * 0.045f, center = Offset(w * 0.67f, h * 0.64f))

            // Big open smile
            val mouth = Path().apply {
                moveTo(w * 0.44f, h * 0.66f)
                quadraticBezierTo(w * 0.50f, h * 0.75f, w * 0.56f, h * 0.66f)
            }
            drawPath(mouth, color = eyeColor, style = Stroke(width = w * 0.028f, cap = StrokeCap.Round))
        }
    }
}
