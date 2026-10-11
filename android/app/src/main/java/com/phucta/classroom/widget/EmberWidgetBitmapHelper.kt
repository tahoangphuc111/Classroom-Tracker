package com.phucta.classroom.widget

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RadialGradient
import android.graphics.RectF
import android.graphics.Shader
import android.util.LruCache
import com.phucta.classroom.ui.components.EmberEmotion
import kotlin.math.max

object EmberWidgetBitmapHelper {

    private val bitmapCache = LruCache<String, Bitmap>(30)

    fun getEmberBitmap(
        context: Context,
        sizeDp: Int,
        emotion: EmberEmotion,
        isUrgent: Boolean = false
    ): Bitmap {
        val density = context.resources.displayMetrics.density
        val sizePx = max(32, (sizeDp * density).toInt())
        val cacheKey = "${sizePx}_${emotion.name}_$isUrgent"

        val cached = bitmapCache.get(cacheKey)
        if (cached != null && !cached.isRecycled) {
            return cached
        }

        val bitmap = renderEmber(sizePx, emotion, isUrgent)
        bitmapCache.put(cacheKey, bitmap)
        return bitmap
    }

    private fun renderEmber(sizePx: Int, emotion: EmberEmotion, isUrgent: Boolean): Bitmap {
        val bitmap = Bitmap.createBitmap(sizePx, sizePx, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val w = sizePx.toFloat()
        val h = sizePx.toFloat()
        val cx = w * 0.50f

        val isSleeping = emotion == EmberEmotion.SLEEPING
        val isStressed = emotion == EmberEmotion.STRESSED || isUrgent

        val shadowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = RadialGradient(
                cx, h * 0.94f, w * 0.37f,
                intArrayOf(Color.argb(60, 20, 51, 89), Color.TRANSPARENT),
                floatArrayOf(0.15f, 1.0f),
                Shader.TileMode.CLAMP
            )
        }
        canvas.drawOval(
            RectF(cx - w * 0.37f, h * 0.94f - h * 0.07f, cx + w * 0.37f, h * 0.94f + h * 0.07f),
            shadowPaint
        )

        val outerPath = Path().apply {
            moveTo(cx, h * 0.91f)
            cubicTo(w * 0.64f, h * 0.91f, w * 0.78f, h * 0.82f, w * 0.78f, h * 0.70f)
            cubicTo(w * 0.78f, h * 0.58f, w * 0.85f, h * 0.51f, w * 0.85f, h * 0.45f)
            cubicTo(w * 0.82f, h * 0.39f, w * 0.71f, h * 0.38f, w * 0.67f, h * 0.36f)
            val apexY = if (isStressed) h * 0.05f else if (isSleeping) h * 0.10f else h * 0.08f
            val apexX = if (isSleeping) w * 0.63f else w * 0.61f
            cubicTo(w * 0.61f, h * 0.24f, w * 0.65f, h * 0.16f, apexX, apexY)
            cubicTo(w * 0.53f, apexY, w * 0.42f, h * 0.17f, w * 0.37f, h * 0.25f)
            cubicTo(w * 0.29f, h * 0.29f, w * 0.16f, h * 0.33f, w * 0.16f, h * 0.40f)
            cubicTo(w * 0.16f, h * 0.52f, w * 0.19f, h * 0.62f, w * 0.22f, h * 0.70f)
            cubicTo(w * 0.22f, h * 0.82f, w * 0.36f, h * 0.91f, cx, h * 0.91f)
            close()
        }

        val outerPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = LinearGradient(
                w * 0.2f, h * 0.08f, w * 0.8f, h * 0.92f,
                intArrayOf(
                    Color.rgb(255, 122, 56),
                    Color.rgb(250, 82, 36),
                    Color.rgb(217, 46, 20)
                ),
                floatArrayOf(0.0f, 0.52f, 1.0f),
                Shader.TileMode.CLAMP
            )
        }
        canvas.drawPath(outerPath, outerPaint)

        val innerPath = Path().apply {
            moveTo(cx, h * 0.86f)
            cubicTo(w * 0.62f, h * 0.86f, w * 0.73f, h * 0.78f, w * 0.73f, h * 0.67f)
            cubicTo(w * 0.73f, h * 0.58f, w * 0.78f, h * 0.52f, w * 0.78f, h * 0.47f)
            cubicTo(w * 0.76f, h * 0.41f, w * 0.67f, h * 0.40f, w * 0.63f, h * 0.39f)
            cubicTo(w * 0.58f, h * 0.28f, w * 0.61f, h * 0.22f, w * 0.58f, h * 0.18f)
            cubicTo(w * 0.52f, h * 0.18f, w * 0.44f, h * 0.25f, w * 0.40f, h * 0.31f)
            cubicTo(w * 0.33f, h * 0.35f, w * 0.23f, h * 0.38f, w * 0.23f, h * 0.44f)
            cubicTo(w * 0.23f, h * 0.54f, w * 0.25f, h * 0.61f, w * 0.27f, h * 0.67f)
            cubicTo(w * 0.27f, h * 0.78f, w * 0.38f, h * 0.86f, cx, h * 0.86f)
            close()
        }

        val innerPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = LinearGradient(
                cx, h * 0.18f, cx, h * 0.86f,
                intArrayOf(
                    Color.argb(245, 255, 242, 166),
                    Color.argb(217, 255, 194, 64),
                    Color.argb(64, 250, 112, 36)
                ),
                floatArrayOf(0.0f, 0.50f, 1.0f),
                Shader.TileMode.CLAMP
            )
        }
        canvas.drawPath(innerPath, innerPaint)

        val corePath = Path().apply {
            moveTo(cx + w * 0.02f, h * 0.34f)
            cubicTo(w * 0.64f, h * 0.42f, w * 0.68f, h * 0.54f, w * 0.66f, h * 0.62f)
            cubicTo(w * 0.64f, h * 0.74f, cx + w * 0.10f, h * 0.78f, cx, h * 0.78f)
            cubicTo(cx - w * 0.10f, h * 0.78f, w * 0.36f, h * 0.74f, w * 0.34f, h * 0.62f)
            cubicTo(w * 0.32f, h * 0.54f, w * 0.38f, h * 0.42f, cx + w * 0.02f, h * 0.34f)
            close()
        }

        val corePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = LinearGradient(
                cx, h * 0.34f, cx, h * 0.78f,
                intArrayOf(
                    Color.argb(240, 255, 255, 255),
                    Color.argb(200, 255, 245, 179),
                    Color.argb(0, 255, 209, 89)
                ),
                floatArrayOf(0.0f, 0.50f, 1.0f),
                Shader.TileMode.CLAMP
            )
        }
        canvas.drawPath(corePath, corePaint)

        val glossPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeCap = Paint.Cap.ROUND
        }

        val glossPath1 = Path().apply {
            moveTo(w * 0.58f, h * 0.11f)
            cubicTo(w * 0.52f, h * 0.11f, w * 0.43f, h * 0.18f, w * 0.39f, h * 0.25f)
        }
        glossPaint.strokeWidth = max(2.0f, w * 0.024f)
        glossPaint.color = Color.argb(220, 255, 255, 255)
        canvas.drawPath(glossPath1, glossPaint)

        val glossPath2 = Path().apply {
            moveTo(w * 0.33f, h * 0.30f)
            cubicTo(w * 0.26f, h * 0.32f, w * 0.185f, h * 0.35f, w * 0.185f, h * 0.41f)
        }
        glossPaint.strokeWidth = max(2.0f, w * 0.023f)
        glossPaint.color = Color.argb(200, 255, 255, 255)
        canvas.drawPath(glossPath2, glossPaint)

        val glossPath3 = Path().apply {
            moveTo(w * 0.185f, h * 0.48f)
            cubicTo(w * 0.185f, h * 0.56f, w * 0.21f, h * 0.65f, w * 0.24f, h * 0.72f)
        }
        glossPaint.strokeWidth = max(2.2f, w * 0.025f)
        glossPaint.color = Color.argb(160, 255, 255, 255)
        canvas.drawPath(glossPath3, glossPaint)

        val blushPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.argb(110, 255, 77, 128)
        }
        val blushRadius = w * 0.055f
        canvas.drawCircle(w * 0.33f, h * 0.64f, blushRadius, blushPaint)
        canvas.drawCircle(w * 0.67f, h * 0.64f, blushRadius, blushPaint)

        val inkColor = Color.rgb(30, 20, 16)
        val inkPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = inkColor
        }
        val strokeInkPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = inkColor
            style = Paint.Style.STROKE
            strokeCap = Paint.Cap.ROUND
        }

        when (emotion) {
            EmberEmotion.NORMAL -> {
                val eyeWidth = w * 0.09f
                val eyeHeight = w * 0.14f
                val leftEyeRect = RectF(w * 0.40f - eyeWidth / 2, h * 0.58f - eyeHeight / 2, w * 0.40f + eyeWidth / 2, h * 0.58f + eyeHeight / 2)
                val rightEyeRect = RectF(w * 0.60f - eyeWidth / 2, h * 0.58f - eyeHeight / 2, w * 0.60f + eyeWidth / 2, h * 0.58f + eyeHeight / 2)
                canvas.drawOval(leftEyeRect, inkPaint)
                canvas.drawOval(rightEyeRect, inkPaint)

                val whitePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE }
                canvas.drawCircle(w * 0.385f, h * 0.565f, w * 0.018f, whitePaint)
                canvas.drawCircle(w * 0.585f, h * 0.565f, w * 0.018f, whitePaint)

                val mouthPath = Path().apply {
                    moveTo(w * 0.45f, h * 0.66f)
                    quadTo(w * 0.50f, h * 0.70f, w * 0.55f, h * 0.66f)
                }
                strokeInkPaint.strokeWidth = max(2.0f, w * 0.022f)
                canvas.drawPath(mouthPath, strokeInkPaint)
            }

            EmberEmotion.STRESSED -> {
                val eyeWidth = w * 0.10f
                val eyeHeight = w * 0.15f
                canvas.drawOval(RectF(w * 0.39f - eyeWidth / 2, h * 0.58f - eyeHeight / 2, w * 0.39f + eyeWidth / 2, h * 0.58f + eyeHeight / 2), inkPaint)
                canvas.drawOval(RectF(w * 0.61f - eyeWidth / 2, h * 0.58f - eyeHeight / 2, w * 0.61f + eyeWidth / 2, h * 0.58f + eyeHeight / 2), inkPaint)

                val whitePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE }
                canvas.drawCircle(w * 0.375f, h * 0.565f, w * 0.015f, whitePaint)
                canvas.drawCircle(w * 0.595f, h * 0.565f, w * 0.015f, whitePaint)

                val mouthPath = Path().apply {
                    moveTo(w * 0.44f, h * 0.68f)
                    quadTo(w * 0.47f, h * 0.65f, w * 0.50f, h * 0.68f)
                    quadTo(w * 0.53f, h * 0.71f, w * 0.56f, h * 0.68f)
                }
                strokeInkPaint.strokeWidth = max(2.0f, w * 0.022f)
                canvas.drawPath(mouthPath, strokeInkPaint)

                val sweatPath = Path().apply {
                    val sx = w * 0.75f
                    val sy = h * 0.46f
                    val sr = w * 0.038f
                    moveTo(sx, sy)
                    cubicTo(sx + sr, sy + sr, sx + sr, sy + 2.4f * sr, sx, sy + 2.4f * sr)
                    cubicTo(sx - sr, sy + 2.4f * sr, sx - sr, sy + sr, sx, sy)
                    close()
                }
                val sweatPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    shader = LinearGradient(
                        w * 0.73f, h * 0.46f, w * 0.77f, h * 0.56f,
                        intArrayOf(Color.rgb(115, 224, 255), Color.rgb(26, 166, 242)),
                        null,
                        Shader.TileMode.CLAMP
                    )
                }
                canvas.drawPath(sweatPath, sweatPaint)
                canvas.drawCircle(w * 0.74f, h * 0.51f, w * 0.012f, whitePaint)
            }

            EmberEmotion.SLEEPING -> {
                strokeInkPaint.strokeWidth = max(2.0f, w * 0.024f)
                val leftEyePath = Path().apply {
                    moveTo(w * 0.35f, h * 0.60f)
                    quadTo(w * 0.405f, h * 0.56f, w * 0.46f, h * 0.60f)
                }
                val rightEyePath = Path().apply {
                    moveTo(w * 0.54f, h * 0.60f)
                    quadTo(w * 0.595f, h * 0.56f, w * 0.65f, h * 0.60f)
                }
                canvas.drawPath(leftEyePath, strokeInkPaint)
                canvas.drawPath(rightEyePath, strokeInkPaint)

                val mouthPath = Path().apply {
                    moveTo(w * 0.47f, h * 0.67f)
                    quadTo(w * 0.50f, h * 0.69f, w * 0.53f, h * 0.67f)
                }
                strokeInkPaint.strokeWidth = max(1.8f, w * 0.020f)
                canvas.drawPath(mouthPath, strokeInkPaint)

                val zPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = Color.WHITE
                    style = Paint.Style.STROKE
                    strokeCap = Paint.Cap.ROUND
                }
                zPaint.strokeWidth = max(2.0f, w * 0.025f)
                val z1Path = Path().apply {
                    moveTo(w * 0.72f, h * 0.38f)
                    lineTo(w * 0.78f, h * 0.38f)
                    lineTo(w * 0.72f, h * 0.45f)
                    lineTo(w * 0.78f, h * 0.45f)
                }
                canvas.drawPath(z1Path, zPaint)

                zPaint.strokeWidth = max(2.5f, w * 0.030f)
                val z2Path = Path().apply {
                    moveTo(w * 0.80f, h * 0.25f)
                    lineTo(w * 0.88f, h * 0.25f)
                    lineTo(w * 0.80f, h * 0.34f)
                    lineTo(w * 0.88f, h * 0.34f)
                }
                canvas.drawPath(z2Path, zPaint)
            }

            EmberEmotion.CELEBRATING -> {
                strokeInkPaint.strokeWidth = max(2.2f, w * 0.026f)
                val leftEyePath = Path().apply {
                    moveTo(w * 0.35f, h * 0.60f)
                    quadTo(w * 0.405f, h * 0.53f, w * 0.46f, h * 0.60f)
                }
                val rightEyePath = Path().apply {
                    moveTo(w * 0.54f, h * 0.60f)
                    quadTo(w * 0.595f, h * 0.53f, w * 0.65f, h * 0.60f)
                }
                canvas.drawPath(leftEyePath, strokeInkPaint)
                canvas.drawPath(rightEyePath, strokeInkPaint)

                val mouthW = w * 0.13f
                val mouthH = w * 0.075f
                val mouthLeft = cx - mouthW / 2
                val mouthTop = h * 0.66f

                val mouthCavity = Path().apply {
                    moveTo(mouthLeft, mouthTop)
                    quadTo(cx, mouthTop - mouthH * 0.15f, mouthLeft + mouthW, mouthTop)
                    cubicTo(
                        mouthLeft + mouthW, mouthTop + mouthH * 0.6f,
                        mouthLeft + mouthW * 0.82f, mouthTop + mouthH,
                        cx, mouthTop + mouthH
                    )
                    cubicTo(
                        mouthLeft + mouthW * 0.18f, mouthTop + mouthH,
                        mouthLeft, mouthTop + mouthH * 0.6f,
                        mouthLeft, mouthTop
                    )
                    close()
                }

                val cavityPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    shader = LinearGradient(
                        cx, mouthTop, cx, mouthTop + mouthH,
                        Color.rgb(60, 20, 32), Color.rgb(25, 10, 15),
                        Shader.TileMode.CLAMP
                    )
                }
                canvas.drawPath(mouthCavity, cavityPaint)

                val tonguePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    shader = LinearGradient(
                        cx, mouthTop + mouthH * 0.3f, cx, mouthTop + mouthH,
                        Color.rgb(255, 90, 130), Color.rgb(230, 40, 85),
                        Shader.TileMode.CLAMP
                    )
                }
                val tongueOval = RectF(
                    cx - mouthW * 0.40f,
                    mouthTop + mouthH * 0.35f,
                    cx + mouthW * 0.40f,
                    mouthTop + mouthH * 1.15f
                )
                canvas.save()
                canvas.clipPath(mouthCavity)
                canvas.drawOval(tongueOval, tonguePaint)
                canvas.restore()

                strokeInkPaint.strokeWidth = max(1.8f, w * 0.020f)
                canvas.drawPath(mouthCavity, strokeInkPaint)

                drawSparkle(canvas, w * 0.18f, h * 0.28f, w * 0.05f)
                drawSparkle(canvas, w * 0.82f, h * 0.24f, w * 0.06f)
                drawSparkle(canvas, w * 0.85f, h * 0.58f, w * 0.04f)
            }
        }

        return bitmap
    }

    private fun drawSparkle(canvas: Canvas, x: Float, y: Float, r: Float) {
        val sparklePath = Path().apply {
            moveTo(x, y - r)
            quadTo(x, y, x + r, y)
            quadTo(x, y, x, y + r)
            quadTo(x, y, x - r, y)
            quadTo(x, y, x, y - r)
            close()
        }
        val sparklePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.rgb(255, 224, 89)
        }
        canvas.drawPath(sparklePath, sparklePaint)
    }
}
