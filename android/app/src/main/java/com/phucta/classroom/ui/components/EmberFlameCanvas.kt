package com.phucta.classroom.ui.components

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.size
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithCache
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.StrokeJoin
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.clipPath
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.phucta.classroom.R
import com.phucta.classroom.ui.theme.ChunkyColor

enum class EmberEmotion {
    NORMAL,
    STRESSED,
    SLEEPING,
    CELEBRATING
}

private val GlossColor = Color.White.copy(alpha = 0.45f)
private val EyeColor = Color(0xFF1E2430)
private val BlushColor = Color(0xFFFF8595).copy(alpha = 0.65f)
private val Z1Color = Color.White.copy(alpha = 0.85f)
private val Z2Color = Color.White.copy(alpha = 0.95f)
private val SweatDropColor = Color(0xFF61C7FF).copy(alpha = 0.9f)
private val SweatGlintColor = Color.White.copy(alpha = 0.8f)

private val CavityTopColor = Color(0xFF3D1520)
private val CavityBottomColor = Color(0xFF1A0A10)
private val TongueTopColor = Color(0xFFFF7FA2)
private val TongueMidColor = Color(0xFFFF527C)
private val TongueBottomColor = Color(0xFFE62957)
private val TongueCreaseColor = Color(0xFFC9204A)
private val TongueGlossColor = Color.White.copy(alpha = 0.42f)
private val SparkleGoldColor = Color(0xFFFFDF4A)

private val OuterBrushColors = listOf(ChunkyColor.EmberTop, ChunkyColor.EmberBottom)
private val InnerBrushColors = listOf(ChunkyColor.EmberCore, ChunkyColor.EmberTop)
private val CavityBrushColors = listOf(CavityTopColor, CavityBottomColor)
private val TongueBrushColors = listOf(TongueTopColor, TongueMidColor, TongueBottomColor)

private fun buildSparklePath(x: Float, y: Float, r: Float): Path = Path().apply {
    moveTo(x, y - r)
    quadraticTo(x, y, x + r, y)
    quadraticTo(x, y, x, y + r)
    quadraticTo(x, y, x - r, y)
    quadraticTo(x, y, x, y - r)
    close()
}

private class FlamePathCache {
    var cachedW: Float = -1f
    var cachedH: Float = -1f
    var cachedIsUrgent: Boolean = false
    var cachedIsSleeping: Boolean = false
    val outerPath: Path = Path()
    val innerPath: Path = Path()
    val glossPath: Path = Path()

    fun update(w: Float, h: Float, isUrgent: Boolean, isSleeping: Boolean) {
        if (cachedW == w && cachedH == h && cachedIsUrgent == isUrgent && cachedIsSleeping == isSleeping) {
            return
        }
        val sizeChanged = cachedW != w || cachedH != h
        cachedW = w
        cachedH = h
        cachedIsUrgent = isUrgent
        cachedIsSleeping = isSleeping

        outerPath.reset()
        buildOuterFlamePathTo(outerPath, w, h, isUrgent, isSleeping)

        innerPath.reset()
        buildInnerFlamePathTo(innerPath, w, h, isSleeping)

        if (sizeChanged) {
            glossPath.reset()
            glossPath.moveTo(w * 0.58f, h * 0.11f)
            glossPath.cubicTo(
                w * 0.52f, h * 0.11f,
                w * 0.43f, h * 0.18f,
                w * 0.39f, h * 0.25f
            )
        }
    }
}

@Composable
fun EmberFlameCanvas(
    modifier: Modifier = Modifier,
    size: Dp = 80.dp,
    emotion: EmberEmotion = EmberEmotion.NORMAL,
    isUrgent: Boolean = false
) {
    val resId = when (emotion) {
        EmberEmotion.NORMAL -> R.drawable.ember_normal
        EmberEmotion.STRESSED -> R.drawable.ember_stressed
        EmberEmotion.SLEEPING -> R.drawable.ember_sleeping
        EmberEmotion.CELEBRATING -> R.drawable.ember_celebrating
    }

    Image(
        painter = painterResource(id = resId),
        contentDescription = "Ember mascot",
        modifier = modifier.size(size)
    )
}

@Composable
fun ProceduralEmberFlameCanvas(
    modifier: Modifier = Modifier,
    size: Dp = 80.dp,
    emotion: EmberEmotion = EmberEmotion.NORMAL,
    isUrgent: Boolean = false
) {
    val pathCache = remember { FlamePathCache() }

    Spacer(
        modifier = modifier
            .size(size)
            .drawWithCache {
                val w = this.size.width
                val h = this.size.height
                val cx = w * 0.50f

                val isSleeping = emotion == EmberEmotion.SLEEPING
                pathCache.update(w, h, isUrgent, isSleeping)
                val outerPath = pathCache.outerPath
                val outerBrush = Brush.verticalGradient(colors = OuterBrushColors)

                val innerPath = pathCache.innerPath
                val innerBrush = Brush.verticalGradient(colors = InnerBrushColors)

                val glossPath = pathCache.glossPath
                val glossStroke = Stroke(width = w * 0.035f, cap = StrokeCap.Round)

                var mouthPath: Path? = null
                var mouthCavityPath: Path? = null
                var tonguePath: Path? = null
                var cavityBrush: Brush? = null
                var tongueBrush: Brush? = null
                val mouthStroke: Stroke
                var leftEyePath: Path? = null
                var rightEyePath: Path? = null
                val eyeStroke: Stroke
                var z1Path: Path? = null
                var z2Path: Path? = null
                val zStroke = Stroke(width = w * 0.025f, cap = StrokeCap.Round)
                var sweatPath: Path? = null
                val sweatGlintCenter = Offset(w * 0.74f, h * 0.52f)
                var sparkle1Path: Path? = null
                var sparkle2Path: Path? = null
                var sparkle3Path: Path? = null

                when (emotion) {
                    EmberEmotion.NORMAL -> {
                        eyeStroke = Stroke(width = w * 0.035f, cap = StrokeCap.Round)
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
                    }
                    EmberEmotion.STRESSED -> {
                        eyeStroke = Stroke(width = w * 0.035f, cap = StrokeCap.Round)
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

                        val mouthW = w * 0.13f
                        val mouthH = w * 0.072f
                        val mouthCy = h * 0.638f
                        val left = cx - mouthW * 0.5f
                        val right = cx + mouthW * 0.5f
                        val top = mouthCy
                        val bottom = mouthCy + mouthH

                        cavityBrush = Brush.verticalGradient(
                            colors = CavityBrushColors,
                            startY = mouthCy,
                            endY = mouthCy + mouthH
                        )
                        tongueBrush = Brush.verticalGradient(
                            colors = TongueBrushColors,
                            startY = mouthCy + mouthH * 0.28f,
                            endY = mouthCy + mouthH
                        )

                        mouthCavityPath = Path().apply {
                            moveTo(left, top)
                            quadraticTo(cx, top - mouthH * 0.14f, right, top)
                            cubicTo(right, top + mouthH * 0.56f, cx + mouthW * 0.32f, bottom, cx, bottom)
                            cubicTo(cx - mouthW * 0.32f, bottom, left, top + mouthH * 0.56f, left, top)
                            close()
                        }

                        tonguePath = Path().apply {
                            moveTo(cx - mouthW * 0.46f, top + mouthH * 1.10f)
                            cubicTo(
                                cx - mouthW * 0.42f, top + mouthH * 0.42f,
                                cx - mouthW * 0.18f, top + mouthH * 0.28f,
                                cx, top + mouthH * 0.32f
                            )
                            cubicTo(
                                cx + mouthW * 0.18f, top + mouthH * 0.28f,
                                cx + mouthW * 0.42f, top + mouthH * 0.42f,
                                cx + mouthW * 0.46f, top + mouthH * 1.10f
                            )
                            close()
                        }

                        mouthStroke = Stroke(
                            width = maxOf(1.8f, w * 0.018f),
                            cap = StrokeCap.Round,
                            join = StrokeJoin.Round
                        )

                        sparkle1Path = buildSparklePath(w * 0.20f, h * 0.32f, w * 0.045f)
                        sparkle2Path = buildSparklePath(w * 0.83f, h * 0.27f, w * 0.055f)
                        sparkle3Path = buildSparklePath(w * 0.85f, h * 0.57f, w * 0.038f)
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

                val eyeRadius = w * 0.045f
                val pupilRadius = w * 0.018f
                val stressedEyeRadius = w * 0.052f
                val stressedPupilRadius = w * 0.015f
                val blushRadiusSleeping = w * 0.04f
                val blushRadiusCelebrating = w * 0.045f
                val sweatGlintRadius = w * 0.012f

                onDrawBehind {
                    drawPath(path = outerPath, brush = outerBrush)
                    drawPath(path = innerPath, brush = innerBrush)
                    drawPath(path = glossPath, color = GlossColor, style = glossStroke)

                    when (emotion) {
                        EmberEmotion.NORMAL -> {
                            drawCircle(color = EyeColor, radius = eyeRadius, center = leftEyeCenter)
                            drawCircle(color = Color.White, radius = pupilRadius, center = leftPupilCenter)
                            drawCircle(color = EyeColor, radius = eyeRadius, center = rightEyeCenter)
                            drawCircle(color = Color.White, radius = pupilRadius, center = rightPupilCenter)
                            mouthPath?.let { drawPath(path = it, color = EyeColor, style = mouthStroke) }
                        }
                        EmberEmotion.SLEEPING -> {
                            leftEyePath?.let { drawPath(path = it, color = EyeColor, style = eyeStroke) }
                            rightEyePath?.let { drawPath(path = it, color = EyeColor, style = eyeStroke) }
                            drawCircle(color = BlushColor, radius = blushRadiusSleeping, center = leftBlushCenterSleeping)
                            drawCircle(color = BlushColor, radius = blushRadiusSleeping, center = rightBlushCenterSleeping)
                            mouthPath?.let { drawPath(path = it, color = EyeColor, style = mouthStroke) }
                            z1Path?.let { drawPath(path = it, color = Z1Color, style = zStroke) }
                            z2Path?.let { drawPath(path = it, color = Z2Color, style = zStroke) }
                        }
                        EmberEmotion.STRESSED -> {
                            drawCircle(color = EyeColor, radius = stressedEyeRadius, center = stressedLeftEyeCenter)
                            drawCircle(color = Color.White, radius = stressedPupilRadius, center = stressedLeftPupilCenter)
                            drawCircle(color = EyeColor, radius = stressedEyeRadius, center = stressedRightEyeCenter)
                            drawCircle(color = Color.White, radius = stressedPupilRadius, center = stressedRightPupilCenter)
                            mouthPath?.let { drawPath(path = it, color = EyeColor, style = mouthStroke) }
                            sweatPath?.let {
                                drawPath(path = it, color = SweatDropColor)
                                drawCircle(color = SweatGlintColor, radius = sweatGlintRadius, center = sweatGlintCenter)
                            }
                        }
                        EmberEmotion.CELEBRATING -> {
                            leftEyePath?.let { drawPath(path = it, color = EyeColor, style = eyeStroke) }
                            rightEyePath?.let { drawPath(path = it, color = EyeColor, style = eyeStroke) }
                            drawCircle(color = BlushColor, radius = blushRadiusCelebrating, center = leftBlushCenterCelebrating)
                            drawCircle(color = BlushColor, radius = blushRadiusCelebrating, center = rightBlushCenterCelebrating)

                            mouthCavityPath?.let { cavity ->
                                clipPath(cavity) {
                                    val mouthW = w * 0.13f
                                    val mouthH = w * 0.072f
                                    val mouthCy = h * 0.638f
                                    cavityBrush?.let { brush ->
                                        drawRect(
                                            brush = brush,
                                            topLeft = Offset(cx - mouthW, mouthCy - mouthH * 0.2f),
                                            size = Size(mouthW * 2f, mouthH * 2f)
                                        )
                                    }

                                    tonguePath?.let { tongue ->
                                        tongueBrush?.let { brush ->
                                            drawPath(
                                                path = tongue,
                                                brush = brush
                                            )
                                        }
                                    }

                                    drawLine(
                                        color = TongueCreaseColor,
                                        start = Offset(cx, mouthCy + mouthH * 0.37f),
                                        end = Offset(cx, mouthCy + mouthH * 0.67f),
                                        strokeWidth = maxOf(1.0f, w * 0.009f),
                                        cap = StrokeCap.Round
                                    )

                                    drawOval(
                                        color = TongueGlossColor,
                                        topLeft = Offset(cx - mouthW * 0.18f, mouthCy + mouthH * 0.35f),
                                        size = Size(mouthW * 0.36f, mouthH * 0.20f)
                                    )
                                }
                                drawPath(path = cavity, color = EyeColor, style = mouthStroke)
                            }

                            sparkle1Path?.let { drawPath(path = it, color = SparkleGoldColor) }
                            sparkle2Path?.let { drawPath(path = it, color = SparkleGoldColor) }
                            sparkle3Path?.let { drawPath(path = it, color = SparkleGoldColor) }
                        }
                    }
                }
            }
    )
}

private fun buildOuterFlamePath(w: Float, h: Float, isUrgent: Boolean, isSleeping: Boolean): Path {
    val path = Path()
    buildOuterFlamePathTo(path, w, h, isUrgent, isSleeping)
    return path
}

private fun buildOuterFlamePathTo(path: Path, w: Float, h: Float, isUrgent: Boolean, isSleeping: Boolean) {
    val cx = w * 0.50f

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
}

private fun buildInnerFlamePath(w: Float, h: Float, isSleeping: Boolean): Path {
    val path = Path()
    buildInnerFlamePathTo(path, w, h, isSleeping)
    return path
}

private fun buildInnerFlamePathTo(path: Path, w: Float, h: Float, isSleeping: Boolean) {
    val cx = w * 0.50f

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
}
