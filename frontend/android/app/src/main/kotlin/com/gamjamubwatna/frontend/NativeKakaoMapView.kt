package com.gamjamubwatna.frontend

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.view.View
import android.widget.FrameLayout
import android.widget.TextView
import com.kakao.vectormap.KakaoMap
import com.kakao.vectormap.KakaoMapReadyCallback
import com.kakao.vectormap.KakaoMapSdk
import com.kakao.vectormap.LatLng
import com.kakao.vectormap.MapLifeCycleCallback
import com.kakao.vectormap.MapView
import com.kakao.vectormap.label.LabelOptions
import com.kakao.vectormap.label.LabelStyle
import com.kakao.vectormap.label.LabelStyles
import io.flutter.plugin.platform.PlatformView

class NativeKakaoMapView(
    context: Context,
    params: Map<*, *>,
) : PlatformView {
    private val container = FrameLayout(context)
    private val mapView = MapView(context)

    init {
        val appKey = params["nativeAppKey"] as? String
        val latitude = (params["latitude"] as? Number)?.toDouble() ?: 37.3808
        val longitude = (params["longitude"] as? Number)?.toDouble() ?: 128.6609
        val zoomLevel = (params["zoomLevel"] as? Number)?.toInt() ?: 9
        val spots = params["spots"] as? List<Map<*, *>> ?: emptyList()

        if (appKey.isNullOrBlank()) {
            showFallback(context, "KAKAO_NATIVE_APP_KEY 설정 후 모바일 카카오맵이 표시됩니다.")
        } else {
            initializeSdk(context, appKey)
            container.addView(
                mapView,
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT,
                ),
            )
            mapView.start(
                object : MapLifeCycleCallback() {
                    override fun onMapDestroy() = Unit

                    override fun onMapError(error: Exception) {
                        showFallback(context, "카카오맵 인증 또는 로딩에 실패했습니다.")
                    }
                },
                object : KakaoMapReadyCallback() {
                    override fun onMapReady(kakaoMap: KakaoMap) {
                        addSpotLabels(kakaoMap, spots)
                    }

                    override fun getPosition(): LatLng {
                        return LatLng.from(latitude, longitude)
                    }

                    override fun getZoomLevel(): Int {
                        return zoomLevel
                    }
                },
            )
        }
    }

    override fun getView(): View {
        return container
    }

    override fun dispose() {
        mapView.pause()
    }

    private fun showFallback(context: Context, message: String) {
        container.removeAllViews()
        container.setBackgroundColor(0xFFEAF5D5.toInt())
        val textView = TextView(context).apply {
            text = message
            textAlignment = View.TEXT_ALIGNMENT_CENTER
            setTextColor(0xFF4F6756.toInt())
            textSize = 13f
            setPadding(48, 48, 48, 48)
        }
        container.addView(
            textView,
            FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
            ),
        )
    }

    private fun addSpotLabels(kakaoMap: KakaoMap, spots: List<Map<*, *>>) {
        if (spots.isEmpty()) return

        val labelManager = kakaoMap.labelManager
        val layer = labelManager.layer
        layer.removeAll()

        val styleCache = mutableMapOf<String, LabelStyles>()
        spots.forEach { spot ->
            val latitude = (spot["latitude"] as? Number)?.toDouble() ?: return@forEach
            val longitude = (spot["longitude"] as? Number)?.toDouble() ?: return@forEach
            val spotId = spot["id"]?.toString() ?: "${latitude}_${longitude}"
            val isRare = spot["rare"] as? Boolean ?: false
            val markerColor = spot["markerColor"]?.toString() ?: if (isRare) "#F6C23E" else "#36D98F"
            val labelText = if (isRare) "🥔★" else "🥔"
            val styleKey = "${markerColor.replace("#", "")}_${if (isRare) "rare" else "normal"}"
            val styles = styleCache.getOrPut(styleKey) {
                labelManager.addLabelStyles(
                    LabelStyles.from(
                        "potato_$styleKey",
                        LabelStyle.from(markerBitmap(labelText, parseColor(markerColor)))
                            .setAnchorPoint(0.5f, 1.0f),
                    ),
                )
            }

            layer.addLabel(
                LabelOptions.from(
                    "potato-$spotId",
                    LatLng.from(latitude, longitude),
                ).setStyles(styles),
            )
        }
    }

    private fun markerBitmap(text: String, strokeColor: Int): Bitmap {
        val width = if (text.contains("★")) 58 else 48
        val height = 48
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            style = Paint.Style.FILL
        }
        val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = strokeColor
            style = Paint.Style.STROKE
            strokeWidth = 3f
        }
        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.BLACK
            textAlign = Paint.Align.CENTER
            textSize = if (text.contains("★")) 20f else 23f
        }
        val markerRect = RectF(3f, 3f, width - 3f, height - 3f)
        canvas.drawRoundRect(markerRect, markerRect.height() / 2, markerRect.height() / 2, fillPaint)
        canvas.drawRoundRect(markerRect, markerRect.height() / 2, markerRect.height() / 2, strokePaint)

        val baseline = (height / 2f) - ((textPaint.descent() + textPaint.ascent()) / 2f)
        canvas.drawText(text, width / 2f, baseline, textPaint)
        return bitmap
    }

    private fun parseColor(hex: String): Int {
        return runCatching { Color.parseColor(hex) }.getOrDefault(0xFF36D98F.toInt())
    }

    companion object {
        private var sdkInitialized = false

        private fun initializeSdk(context: Context, appKey: String) {
            if (!sdkInitialized) {
                KakaoMapSdk.init(context.applicationContext, appKey)
                sdkInitialized = true
            }
        }
    }
}
