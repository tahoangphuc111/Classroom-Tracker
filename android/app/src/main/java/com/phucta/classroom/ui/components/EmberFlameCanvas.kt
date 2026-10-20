package com.phucta.classroom.ui.components

import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
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
    Spacer(
        modifier = modifier
            .size(size)
            .drawWithCache {
                val w = this.size.width
                val h = this.size.height

                val isSleeping = emotion == EmberEmotion.SLEEPING
                val outerPath = buildOuterFlamePath(w, h, isUrgent, isSleeping)
                val outerBrush = Brush.verticalGradient(
                    colors = listOf(ChunkyColor.EmberTop, ChunkyColor.EmberBottom)
                )

                val innerPath = buildInnerFlamePath(w, h, isSleeping)
                val innerBrush = Brush.verticalGradient(
                    colors = listOf(ChunkyColor.EmberCore, ChunkyColor.EmberTop)
                )

                val glossPath = Path().apply {
                    moveTo(w * 0.58f, h * 0.11f)
                    cubicTo(
                        w * 0.52f, h * 0.11f,
                        w * 0.43f, h * 0.18f,
                        w * 0.39f, h * 0.25f
                    )
                }
                val glossColor = Color.White.copy(alpha = 0.45f)
                val glossStroke = Stroke(width = w * 0.035f, cap = StrokeCap.Round)

                val eyeColor = Color(0xFF1E2430)
                val blushColor = Color(0xFFFF8595).copy(alpha = 0.65f)

                val mouthPath: Path
                val mouthStroke: Stroke
                var leftEyePath: Path? = null
                var rightEyePath: Path? = null
                var eyeStroke: Stroke? = null
                var z1Path: Path? = null
                var z2Path: Path? = null
                var zStroke: Stroke? = null
                var sweatPath: Path? = null

                when (emotion) {
                    EmberEmotion.NORMAL -> {
                        mouthPath = Path().apply {
                            moveTo(w * 0.46f, h * 0.66f)
                            quadraticTo(w * 0.50f, h * 0.70f, w * 0.54f, h * 0.66f)
                        }
                        mouthStroke = Stroke(width = w * 0.025f, cap = StrokeCap.Round)
                    }
                    EmberEmotion.SLEEPING -> {
                        leftEyePath = Path().apply {
                            moveTo(w * 0.36f, h * 0.60f)
                            quadraticTo(w * 0.41f, h * 0.56f, w * 0.46f, h * 0.60f)
                        }
                        rightEyePath = Path().apply {
                            moveTo(w * 0.54f, h * 0.60f)
                            quadraticTo(w * 0.59f, h * 0.56f, w * 0.64f, h * 0.60f)
                        }
                        eyeStroke = Stroke(width = w * 0.03f, cap = StrokeCap.Round)

                        mouthPath = Path().apply {
                            moveTo(w * 0.47f, h * 0.67f)
                            quadraticTo(w * 0.50f, h * 0.69f, w * 0.53f, h * 0.67f)
                        }
                        mouthStroke = Stroke(width = w * 0.022f, cap = StrokeCap.Round)

                        z1Path = Path().apply {
                            moveTo(w * 0.72f, h * 0.40f)
                            lineTo(w * 0.77f, h * 0.40f)
                            lineTo(w * 0.72f, h * 0.46f)
                            lineTo(w * 0.77f, h * 0.46f)
                        }
                        z2Path = Path().apply {
                            moveTo(w * 0.80f, h * 0.28f)
                            lineTo(w * 0.86f, h * 0.28f)
                            lineTo(w * 0.80f, h * 0.35f)
                            lineTo(w * 0.86f, h * 0.35f)
                        }
                        zStroke = Stroke(width = w * 0.025f, cap = StrokeCap.Round)
                    }
                    EmberEmotion.STRESSED -> {
                        mouthPath = Path().apply {
                            moveTo(w * 0.44f, h * 0.68f)
                            quadraticTo(w * 0.47f, h * 0.65f, w * 0.50f, h * 0.68f)
                            quadraticTo(w * 0.53f, h * 0.71f, w * 0.56f, h * 0.68f)
                        }
                        mouthStroke = Stroke(width = w * 0.025f, cap = StrokeCap.Round)

                        sweatPath = Path().apply {
                            val sx = w * 0.75f
                            val sy = h * 0.48f
                            val sr = w * 0.038f
                            moveTo(sx, sy)
                            cubicTo(sx + sr, sy + sr, sx + sr, sy + 2.4f * sr, sx, sy + 2.4f * sr)
                            cubicTo(sx - sr, sy + 2.4f * sr, sx - sr, sy + sr, sx, sy)
                            close()
                        }
                    }
                    EmberEmotion.CELEBRATING -> {
                        leftEyePath = Path().apply {
                            moveTo(w * 0.36f, h * 0.60f)
                            quadraticTo(w * 0.41f, h * 0.53f, w * 0.46f, h * 0.60f)
                        }
                        rightEyePath = Path().apply {
                            moveTo(w * 0.54f, h * 0.60f)
                            quadraticTo(w * 0.59f, h * 0.53f, w * 0.64f, h * 0.60f)
                        }
                        eyeStroke = Stroke(width = w * 0.035f, cap = StrokeCap.Round)

                        mouthPath = Path().apply {
                            moveTo(w * 0.44f, h * 0.66f)
                            quadraticTo(w * 0.50f, h * 0.75f, w * 0.56f, h * 0.66f)
                        }
                        mouthStroke = Stroke(width = w * 0.028f, cap = StrokeCap.Round)
                    }
                }

                val leftEyeCenter = Offset(w * 0.40f, h * 0.58f)
                val leftPupilCenter = Offset(w * 0.385f, h * 0.565f)
                val rightEyeCenter = Offset(w * 0.60f, h * 0.58f)
                val rightPupilCenter = Offset(w * 0.585f, h * 0.565f)

                val stressedLeftEyeCenter = Offset(w * 0.39f, h * 0.58f)
                val stressedLeftPupilCenter = Offset(w * 0.375f, h * 0.565f)
                val stressedRightEyeCenter = Offset(w * 0.61f, h * 0.58f)
                val stressedRightPupilCenter = Offset(w * 0.595f, h * 0.565f)

                val leftBlushCenterSleeping = Offset(w * 0.34f, h * 0.65f)
                val rightBlushCenterSleeping = Offset(w * 0.66f, h * 0.65f)
                val leftBlushCenterCelebrating = Offset(w * 0.33f, h * 0.64f)
                val rightBlushCenterCelebrating = Offset(w * 0.67f, h * 0.64f)

                onDrawBehind {
                    drawPath(path = outerPath, brush = outerBrush)
                    drawPath(path = innerPath, brush = innerBrush)
                    drawPath(path = glossPath, color = glossColor, style = glossStroke)

                    when (emotion) {
                        EmberEmotion.NORMAL -> {
                            drawCircle(color = eyeColor, radius = w * 0.045f, center = leftEyeCenter)
                            drawCircle(color = Color.White, radius = w * 0.018f, center = leftPupilCenter)
                            drawCircle(color = eyeColor, radius = w * 0.045f, center = rightEyeCenter)
                            drawCircle(color = Color.White, radius = w * 0.018f, center = rightPupilCenter)
                            drawPath(path = mouthPath, color = eyeColor, style = mouthStroke)
                        }
                        EmberEmotion.SLEEPING -> {
                            val activeEyeStroke = eyeStroke ?: Stroke(width = w * 0.035f, cap = StrokeCap.Round)
                            val activeZStroke = zStroke ?: Stroke(width = w * 0.025f, cap = StrokeCap.Round)
                            leftEyePath?.let { drawPath(path = it, color = eyeColor, style = activeEyeStroke) }
                            rightEyePath?.let { drawPath(path = it, color = eyeColor, style = activeEyeStroke) }
                            drawCircle(color = blushColor, radius = w * 0.04f, center = leftBlushCenterSleeping)
                            drawCircle(color = blushColor, radius = w * 0.04f, center = rightBlushCenterSleeping)
                            drawPath(path = mouthPath, color = eyeColor, style = mouthStroke)
                            z1Path?.let { drawPath(path = it, color = Color.White.copy(alpha = 0.85f), style = activeZStroke) }
                            z2Path?.let { drawPath(path = it, color = Color.White.copy(alpha = 0.95f), style = activeZStroke) }
                        }
                        EmberEmotion.STRESSED -> {
                            drawCircle(color = eyeColor, radius = w * 0.052f, center = stressedLeftEyeCenter)
                            drawCircle(color = Color.White, radius = w * 0.015f, center = stressedLeftPupilCenter)
                            drawCircle(color = eyeColor, radius = w * 0.052f, center = stressedRightEyeCenter)
                            drawCircle(color = Color.White, radius = w * 0.015f, center = stressedRightPupilCenter)
                            drawPath(path = mouthPath, color = eyeColor, style = mouthStroke)
                            sweatPath?.let {
                                drawPath(path = it, color = Color(0xFF61C7FF).copy(alpha = 0.9f))
                                drawCircle(color = Color.White.copy(alpha = 0.8f), radius = w * 0.012f, center = Offset(w * 0.74f, h * 0.52f))
                            }
                        }
                        EmberEmotion.CELEBRATING -> {
                            val activeEyeStroke = eyeStroke ?: Stroke(width = w * 0.035f, cap = StrokeCap.Round)
                            leftEyePath?.let { drawPath(path = it, color = eyeColor, style = activeEyeStroke) }
                            rightEyePath?.let { drawPath(path = it, color = eyeColor, style = activeEyeStroke) }
                            drawCircle(color = blushColor, radius = w * 0.045f, center = leftBlushCenterCelebrating)
                            drawCircle(color = blushColor, radius = w * 0.045f, center = rightBlushCenterCelebrating)
                            drawPath(path = mouthPath, color = eyeColor, style = mouthStroke)
                        }
                    }
                }
            }
    )
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
