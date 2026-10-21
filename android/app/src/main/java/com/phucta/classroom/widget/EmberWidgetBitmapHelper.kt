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
import android.graphics.Typeface
import android.util.LruCache
import com.phucta.classroom.ui.components.EmberEmotion
import kotlin.math.max

object EmberWidgetBitmapHelper {
    private val maxMemoryKb = (Runtime.getRuntime().maxMemory() / 1024).toInt()
    private val cacheSizeKb = (maxMemoryKb / 16).coerceIn(1024, 8192)

    private val bitmapCache = object : LruCache<String, Bitmap>(cacheSizeKb) {
        override fun sizeOf(key: String, bitmap: Bitmap): Int {
            return (bitmap.byteCount / 1024).coerceAtLeast(1)
        }
    }

    private val inkColor = Color.rgb(31, 20, 15)
    private val inkPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = inkColor }
    private val primaryCatchlightPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE }
    private val secondaryCatchlightPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(235, 255, 255, 255) }
    private val shineDotPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(242, 255, 255, 255) }
    private val dropBorderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.WHITE
        style = Paint.Style.STROKE
    }
    private val sparklePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.rgb(255, 223, 74)
    }
    private val creasePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        color = Color.argb(217, 201, 32, 74)
        style = Paint.Style.STROKE
        strokeCap = Paint.Cap.ROUND
    }
    private val upperLipGlossPaint = Paint(Paint.ANTI_ALIAS_FLAG)

    fun clearCache() {
        synchronized(bitmapCache) {
            bitmapCache.evictAll()
        }
    }

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

        synchronized(bitmapCache) {
            val secondCheck = bitmapCache.get(cacheKey)
            if (secondCheck != null && !secondCheck.isRecycled) {
                return secondCheck
            }
            val bitmap = renderEmber(sizePx, emotion, isUrgent)
            bitmapCache.put(cacheKey, bitmap)
            return bitmap
        }
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
                cx, h * 0.933f, w * 0.367f,
                intArrayOf(Color.argb(64, 20, 36, 59), Color.TRANSPARENT),
                floatArrayOf(0.10f, 1.0f),
                Shader.TileMode.CLAMP
            )
        }
        canvas.drawOval(
            RectF(cx - w * 0.367f, h * 0.933f - h * 0.065f, cx + w * 0.367f, h * 0.933f + h * 0.065f),
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

        val flameDropShadowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.argb(72, 219, 51, 26)
            style = Paint.Style.FILL
            setShadowLayer(w * 0.04f, 0f, h * 0.02f, Color.argb(72, 219, 51, 26))
        }
        canvas.save()
        canvas.translate(0f, h * 0.02f)
        canvas.drawPath(outerPath, flameDropShadowPaint)
        canvas.restore()

        val outerPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = LinearGradient(
                w * 0.15f, 0f, w * 0.85f, h,
                intArrayOf(
                    Color.rgb(255, 122, 56),
                    Color.rgb(247, 79, 36),
                    Color.rgb(214, 43, 20)
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
                    Color.argb(245, 255, 244, 166),
                    Color.argb(217, 255, 194, 64),
                    Color.argb(64, 250, 110, 36)
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
                    Color.argb(242, 255, 255, 255),
                    Color.argb(204, 255, 245, 179),
                    Color.argb(0, 255, 209, 89)
                ),
                floatArrayOf(0.0f, 0.50f, 1.0f),
                Shader.TileMode.CLAMP
            )
        }
        canvas.drawPath(corePath, corePaint)

        val crestPath = Path().apply {
            moveTo(w * 0.58f, h * 0.11f)
            cubicTo(w * 0.52f, h * 0.11f, w * 0.43f, h * 0.18f, w * 0.39f, h * 0.25f)
        }
        val crestPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeCap = Paint.Cap.ROUND
            strokeWidth = max(2.0f, w * 0.024f)
            shader = LinearGradient(
                w * 0.58f, h * 0.11f, w * 0.39f, h * 0.25f,
                intArrayOf(
                    Color.argb(0, 255, 255, 255),
                    Color.argb(230, 255, 255, 255),
                    Color.argb(242, 255, 255, 255),
                    Color.argb(0, 255, 255, 255)
                ),
                floatArrayOf(0.0f, 0.25f, 0.65f, 1.0f),
                Shader.TileMode.CLAMP
            )
        }
        canvas.drawPath(crestPath, crestPaint)

        val leftTonguePath = Path().apply {
            moveTo(w * 0.33f, h * 0.30f)
            cubicTo(w * 0.26f, h * 0.32f, w * 0.185f, h * 0.35f, w * 0.185f, h * 0.41f)
        }
        val leftTonguePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeCap = Paint.Cap.ROUND
            strokeWidth = max(2.0f, w * 0.023f)
            shader = LinearGradient(
                w * 0.33f, h * 0.30f, w * 0.185f, h * 0.41f,
                intArrayOf(
                    Color.argb(0, 255, 255, 255),
                    Color.argb(217, 255, 255, 255),
                    Color.argb(242, 255, 255, 255),
                    Color.argb(0, 255, 255, 255)
                ),
                floatArrayOf(0.0f, 0.35f, 0.70f, 1.0f),
                Shader.TileMode.CLAMP
            )
        }
        canvas.drawPath(leftTonguePath, leftTonguePaint)

        val leftCheekPath = Path().apply {
            moveTo(w * 0.185f, h * 0.48f)
            cubicTo(w * 0.185f, h * 0.56f, w * 0.21f, h * 0.65f, w * 0.24f, h * 0.72f)
        }
        val leftCheekPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeCap = Paint.Cap.ROUND
            strokeWidth = max(2.2f, w * 0.025f)
            shader = LinearGradient(
                w * 0.185f, h * 0.48f, w * 0.24f, h * 0.72f,
                intArrayOf(
                    Color.argb(0, 255, 255, 255),
                    Color.argb(217, 255, 255, 255),
                    Color.argb(166, 255, 255, 255),
                    Color.argb(0, 255, 255, 255)
                ),
                floatArrayOf(0.0f, 0.35f, 0.75f, 1.0f),
                Shader.TileMode.CLAMP
            )
        }
        canvas.drawPath(leftCheekPath, leftCheekPaint)

        val rightTipPath = Path().apply {
            moveTo(w * 0.60f, h * 0.10f)
            cubicTo(w * 0.62f, h * 0.14f, w * 0.63f, h * 0.18f, w * 0.63f, h * 0.22f)
        }
        val rightTipPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeCap = Paint.Cap.ROUND
            strokeWidth = max(1.6f, w * 0.016f)
            shader = LinearGradient(
                w * 0.60f, h * 0.10f, w * 0.63f, h * 0.22f,
                intArrayOf(
                    Color.argb(0, 255, 255, 255),
                    Color.argb(166, 255, 255, 255),
                    Color.argb(0, 255, 255, 255)
                ),
                floatArrayOf(0.0f, 0.40f, 1.0f),
                Shader.TileMode.CLAMP
            )
        }
        canvas.drawPath(rightTipPath, rightTipPaint)

        val rightTonguePath = Path().apply {
            moveTo(w * 0.70f, h * 0.38f)
            cubicTo(w * 0.75f, h * 0.40f, w * 0.80f, h * 0.43f, w * 0.82f, h * 0.46f)
        }
        val rightTonguePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeCap = Paint.Cap.ROUND
            strokeWidth = max(1.6f, w * 0.016f)
            shader = LinearGradient(
                w * 0.70f, h * 0.38f, w * 0.82f, h * 0.46f,
                intArrayOf(
                    Color.argb(0, 255, 255, 255),
                    Color.argb(153, 255, 255, 255),
                    Color.argb(0, 255, 255, 255)
                ),
                floatArrayOf(0.0f, 0.40f, 1.0f),
                Shader.TileMode.CLAMP
            )
        }
        canvas.drawPath(rightTonguePath, rightTonguePaint)

        val blushRadius = w * 0.07f
        val leftBlushPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = RadialGradient(
                w * 0.33f, h * 0.605f, blushRadius,
                intArrayOf(Color.argb(140, 255, 77, 121), Color.argb(0, 255, 77, 121)),
                floatArrayOf(0.0f, 1.0f),
                Shader.TileMode.CLAMP
            )
        }
        canvas.drawCircle(w * 0.33f, h * 0.605f, blushRadius, leftBlushPaint)

        val rightBlushPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            shader = RadialGradient(
                w * 0.69f, h * 0.605f, blushRadius,
                intArrayOf(Color.argb(140, 255, 77, 121), Color.argb(0, 255, 77, 121)),
                floatArrayOf(0.0f, 1.0f),
                Shader.TileMode.CLAMP
            )
        }
        canvas.drawCircle(w * 0.69f, h * 0.605f, blushRadius, rightBlushPaint)

        val inkColor = Color.rgb(31, 20, 15)
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
                val eyeWidth = w * 0.10f
                val eyeHeight = w * 0.155f
                val eyeCorner = eyeWidth / 2f
                val eyeY = h * 0.545f

                val leftEyeCx = w * 0.425f
                val rightEyeCx = w * 0.585f

                canvas.drawRoundRect(
                    RectF(leftEyeCx - eyeWidth / 2, eyeY - eyeHeight / 2, leftEyeCx + eyeWidth / 2, eyeY + eyeHeight / 2),
                    eyeCorner, eyeCorner, inkPaint
                )
                canvas.drawRoundRect(
                    RectF(rightEyeCx - eyeWidth / 2, eyeY - eyeHeight / 2, rightEyeCx + eyeWidth / 2, eyeY + eyeHeight / 2),
                    eyeCorner, eyeCorner, inkPaint
                )

                val primaryCatchlightPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE }
                val primaryR = w * 0.020f
                canvas.drawCircle(leftEyeCx - eyeWidth * 0.19f, eyeY - eyeHeight * 0.25f, primaryR, primaryCatchlightPaint)
                canvas.drawCircle(rightEyeCx - eyeWidth * 0.19f, eyeY - eyeHeight * 0.25f, primaryR, primaryCatchlightPaint)

                val secondaryCatchlightPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(235, 255, 255, 255) }
                val secondaryR = w * 0.011f
                canvas.drawCircle(leftEyeCx + eyeWidth * 0.19f, eyeY + eyeHeight * 0.22f, secondaryR, secondaryCatchlightPaint)
                canvas.drawCircle(rightEyeCx + eyeWidth * 0.19f, eyeY + eyeHeight * 0.22f, secondaryR, secondaryCatchlightPaint)

                val mouthPath = Path().apply {
                    moveTo(w * 0.454f, h * 0.638f)
                    quadTo(w * 0.504f, h * 0.688f, w * 0.554f, h * 0.638f)
                }
                strokeInkPaint.strokeWidth = max(2.2f, w * 0.020f)
                canvas.drawPath(mouthPath, strokeInkPaint)
            }

            EmberEmotion.STRESSED -> {
                val eyeWidth = w * 0.10f
                val eyeHeight = w * 0.155f
                val eyeCorner = eyeWidth / 2f
                val eyeY = h * 0.545f

                val leftEyeCx = w * 0.425f
                val rightEyeCx = w * 0.585f

                canvas.drawRoundRect(
                    RectF(leftEyeCx - eyeWidth / 2, eyeY - eyeHeight / 2, leftEyeCx + eyeWidth / 2, eyeY + eyeHeight / 2),
                    eyeCorner, eyeCorner, inkPaint
                )
                canvas.drawRoundRect(
                    RectF(rightEyeCx - eyeWidth / 2, eyeY - eyeHeight / 2, rightEyeCx + eyeWidth / 2, eyeY + eyeHeight / 2),
                    eyeCorner, eyeCorner, inkPaint
                )

                val primaryCatchlightPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE }
                val primaryR = w * 0.020f
                canvas.drawCircle(leftEyeCx - eyeWidth * 0.19f, eyeY - eyeHeight * 0.25f, primaryR, primaryCatchlightPaint)
                canvas.drawCircle(rightEyeCx - eyeWidth * 0.19f, eyeY - eyeHeight * 0.25f, primaryR, primaryCatchlightPaint)

                val secondaryCatchlightPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.argb(235, 255, 255, 255) }
                val secondaryR = w * 0.011f
                canvas.drawCircle(leftEyeCx + eyeWidth * 0.19f, eyeY + eyeHeight * 0.22f, secondaryR, secondaryCatchlightPaint)
                canvas.drawCircle(rightEyeCx + eyeWidth * 0.19f, eyeY + eyeHeight * 0.22f, secondaryR, secondaryCatchlightPaint)

                val mouthPath = Path().apply {
                    moveTo(w * 0.454f, h * 0.646f)
                    cubicTo(w * 0.483f, h * 0.629f, w * 0.513f, h * 0.671f, w * 0.554f, h * 0.646f)
                }
                strokeInkPaint.strokeWidth = max(2.2f, w * 0.018f)
                canvas.drawPath(mouthPath, strokeInkPaint)

                val sweatCx = w * 0.78f
                val sweatCy = h * 0.42f
                val dropW = w * 0.075f
                val dropH = h * 0.12f
                val dropRx = dropW / 2f

                canvas.save()
                canvas.translate(sweatCx, sweatCy)
                canvas.rotate(18f)

                val dropRect = RectF(-dropW / 2, -dropH / 2, dropW / 2, dropH / 2)
                val dropPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    shader = LinearGradient(
                        -dropW / 2, -dropH / 2, dropW / 2, dropH / 2,
                        intArrayOf(Color.rgb(112, 224, 255), Color.rgb(24, 165, 242)),
                        null,
                        Shader.TileMode.CLAMP
                    )
                }
                canvas.drawRoundRect(dropRect, dropRx, dropRx, dropPaint)

                val dropBorderPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = Color.WHITE
                    style = Paint.Style.STROKE
                    strokeWidth = max(0.7f, w * 0.007f)
                }
                canvas.drawRoundRect(dropRect, dropRx, dropRx, dropBorderPaint)

                val shineDotPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = Color.argb(242, 255, 255, 255)
                }
                canvas.drawCircle(-dropW * 0.20f, -dropH * 0.25f, w * 0.011f, shineDotPaint)

                canvas.restore()
            }

            EmberEmotion.SLEEPING -> {
                strokeInkPaint.strokeWidth = max(2.2f, w * 0.022f)
                val leftEyePath = Path().apply {
                    moveTo(w * 0.371f, h * 0.570f)
                    quadTo(w * 0.421f, h * 0.545f, w * 0.471f, h * 0.570f)
                }
                val rightEyePath = Path().apply {
                    moveTo(w * 0.529f, h * 0.570f)
                    quadTo(w * 0.579f, h * 0.545f, w * 0.629f, h * 0.570f)
                }
                canvas.drawPath(leftEyePath, strokeInkPaint)
                canvas.drawPath(rightEyePath, strokeInkPaint)

                val mouthPath = Path().apply {
                    moveTo(w * 0.463f, h * 0.638f)
                    quadTo(w * 0.50f, h * 0.667f, w * 0.538f, h * 0.638f)
                }
                strokeInkPaint.strokeWidth = max(1.8f, w * 0.018f)
                canvas.drawPath(mouthPath, strokeInkPaint)

                val zPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = Color.WHITE
                    textSize = w * 0.125f
                    typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
                    setShadowLayer(max(2f, w * 0.02f), 0f, max(1f, w * 0.01f), Color.argb(46, 0, 0, 0))
                }
                canvas.drawText("Z", w * 0.73f, h * 0.27f, zPaint)

                zPaint.textSize = w * 0.085f
                zPaint.color = Color.argb(230, 255, 255, 255)
                canvas.drawText("z", w * 0.80f, h * 0.37f, zPaint)
            }

            EmberEmotion.CELEBRATING -> {
                strokeInkPaint.strokeWidth = max(2.4f, w * 0.024f)
                val leftEyePath = Path().apply {
                    moveTo(w * 0.371f, h * 0.560f)
                    quadTo(w * 0.421f, h * 0.530f, w * 0.471f, h * 0.560f)
                }
                val rightEyePath = Path().apply {
                    moveTo(w * 0.529f, h * 0.560f)
                    quadTo(w * 0.579f, h * 0.530f, w * 0.629f, h * 0.560f)
                }
                canvas.drawPath(leftEyePath, strokeInkPaint)
                canvas.drawPath(rightEyePath, strokeInkPaint)

                val mouthW = w * 0.13f
                val mouthH = w * 0.072f
                val mouthCy = h * 0.638f

                val mouthCavity = Path().apply {
                    moveTo(-mouthW * 0.5f, 0f)
                    quadTo(0f, -mouthH * 0.14f, mouthW * 0.5f, 0f)
                    cubicTo(mouthW * 0.5f, mouthH * 0.56f, mouthW * 0.32f, mouthH, 0f, mouthH)
                    cubicTo(-mouthW * 0.32f, mouthH, -mouthW * 0.5f, mouthH * 0.56f, -mouthW * 0.5f, 0f)
                    close()
                }

                canvas.save()
                canvas.translate(cx, mouthCy)

                canvas.save()
                canvas.clipPath(mouthCavity)

                val cavityPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    shader = LinearGradient(
                        0f, 0f, 0f, mouthH,
                        Color.rgb(61, 21, 32), Color.rgb(26, 10, 16),
                        Shader.TileMode.CLAMP
                    )
                }
                canvas.drawRect(RectF(-mouthW, -mouthH, mouthW, mouthH * 2), cavityPaint)

                val tonguePath = Path().apply {
                    moveTo(-mouthW * 0.46f, mouthH * 1.10f)
                    cubicTo(-mouthW * 0.42f, mouthH * 0.42f, -mouthW * 0.18f, mouthH * 0.28f, 0f, mouthH * 0.32f)
                    cubicTo(mouthW * 0.18f, mouthH * 0.28f, mouthW * 0.42f, mouthH * 0.42f, mouthW * 0.46f, mouthH * 1.10f)
                    close()
                }
                val tonguePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    shader = LinearGradient(
                        0f, mouthH * 0.28f, 0f, mouthH,
                        intArrayOf(Color.rgb(255, 127, 162), Color.rgb(255, 82, 124), Color.rgb(230, 41, 87)),
                        floatArrayOf(0.0f, 0.60f, 1.0f),
                        Shader.TileMode.CLAMP
                    )
                }
                canvas.drawPath(tonguePath, tonguePaint)

                val creasePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = Color.argb(217, 201, 32, 74)
                    style = Paint.Style.STROKE
                    strokeCap = Paint.Cap.ROUND
                    strokeWidth = max(1.0f, w * 0.009f)
                }
                canvas.drawLine(0f, mouthH * 0.37f, 0f, mouthH * 0.67f, creasePaint)

                val glossPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                    color = Color.argb(107, 255, 255, 255)
                }
                canvas.drawOval(
                    RectF(-mouthW * 0.18f, mouthH * 0.35f, mouthW * 0.18f, mouthH * 0.55f),
                    glossPaint
                )
                glossPaint.color = Color.argb(153, 255, 255, 255)
                canvas.drawOval(
                    RectF(-mouthW * 0.12f, mouthH * 0.38f, -mouthW * 0.02f, mouthH * 0.48f),
                    glossPaint
                )

                canvas.restore()

                strokeInkPaint.strokeWidth = max(1.8f, w * 0.018f)
                canvas.drawPath(mouthCavity, strokeInkPaint)

                canvas.restore()

                drawSparkle(canvas, w * 0.20f, h * 0.32f, w * 0.045f)
                drawSparkle(canvas, w * 0.83f, h * 0.27f, w * 0.055f)
                drawSparkle(canvas, w * 0.85f, h * 0.57f, w * 0.038f)
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
            color = Color.rgb(255, 223, 74)
        }
        canvas.drawPath(sparklePath, sparklePaint)
    }
}
