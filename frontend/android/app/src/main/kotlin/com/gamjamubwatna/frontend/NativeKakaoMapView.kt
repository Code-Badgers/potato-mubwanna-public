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
import com.kakao.vectormap.camera.CameraPosition
import com.kakao.vectormap.label.Label
import com.kakao.vectormap.label.LabelOptions
import com.kakao.vectormap.label.LabelStyle
import com.kakao.vectormap.label.LabelStyles
import com.kakao.vectormap.shape.MapPoints
import com.kakao.vectormap.shape.PolylineOptions
import com.kakao.vectormap.shape.ShapeLayerOptions
import com.kakao.vectormap.shape.ShapeLayerPass
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView

class NativeKakaoMapView(
    context: Context,
    viewId: Int,
    params: Map<*, *>,
    messenger: BinaryMessenger,
) : PlatformView {
    private val container = FrameLayout(context)
    private var mapView: MapView? = null
    private val channel = MethodChannel(messenger, "potato_mubwanna/kakao_map_$viewId")
    private val spotLabels = mutableListOf<Label>()
    private val spotIdByLabelId = mutableMapOf<String, String>()
    private var kakaoMap: KakaoMap? = null
    private var routePolyline = pointMaps(params["routePolyline"])
    private val routeLayerId = "potatoRouteLayer"

    init {
        val appKey = params["nativeAppKey"] as? String
        val latitude = (params["latitude"] as? Number)?.toDouble() ?: 37.3808
        val longitude = (params["longitude"] as? Number)?.toDouble() ?: 128.6609
        val zoomLevel = (params["zoomLevel"] as? Number)?.toInt() ?: 9
        val spots = spotMaps(params["spots"])

        if (appKey.isNullOrBlank()) {
            showFallback(context, "KAKAO_NATIVE_APP_KEY 설정 후 모바일 카카오맵이 표시됩니다.")
        } else {
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateSpots" -> {
                        val nextSpots = spotMaps(call.arguments)
                        kakaoMap?.let { addSpotLabels(it, nextSpots) }
                        result.success(null)
                    }
                    "updateRoutePolyline" -> {
                        routePolyline = pointMaps(call.arguments)
                        kakaoMap?.let { renderRoutePolyline(it) }
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
            try {
                initializeSdk(context, appKey)
                val createdMapView = MapView(context)
                mapView = createdMapView
                container.addView(
                    createdMapView,
                    FrameLayout.LayoutParams(
                        FrameLayout.LayoutParams.MATCH_PARENT,
                        FrameLayout.LayoutParams.MATCH_PARENT,
                    ),
                )
                createdMapView.start(
                    object : MapLifeCycleCallback() {
                        override fun onMapDestroy() = Unit

                        override fun onMapError(error: Exception) {
                            showFallback(context, "카카오맵 인증 또는 로딩에 실패했습니다.")
                        }

                    },
                    object : KakaoMapReadyCallback() {
                        override fun onMapReady(kakaoMap: KakaoMap) {
                            this@NativeKakaoMapView.kakaoMap = kakaoMap
                            addSpotLabels(kakaoMap, spots)
                            renderRoutePolyline(kakaoMap)
                            kakaoMap.setOnLabelClickListener { _, _, label ->
                                val spotId = spotIdByLabelId[label.labelId]
                                    ?: label.labelId.removePrefix("potato-")
                                channel.invokeMethod("spotSelected", mapOf("spotId" to spotId))
                                true
                            }
                            kakaoMap.setOnCameraMoveEndListener { map, cameraPosition, _ ->
                                scaleSpotLabels(map, cameraPosition)
                            }
                        }

                        override fun getPosition(): LatLng {
                            return LatLng.from(latitude, longitude)
                        }

                        override fun getZoomLevel(): Int {
                            return zoomLevel
                        }
                    },
                )
            } catch (_: UnsatisfiedLinkError) {
                mapView = null
                showFallback(
                    context,
                    "이 에뮬레이터 CPU에서는 카카오맵을 실행할 수 없습니다. ARM64 기기에서 확인해주세요.",
                )
            }
        }
    }

    override fun getView(): View {
        return container
    }

    override fun dispose() {
        channel.setMethodCallHandler(null)
        mapView?.pause()
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
        val labelManager = kakaoMap.labelManager ?: return
        val layer = labelManager.layer ?: return
        layer.removeAll()
        spotLabels.clear()
        spotIdByLabelId.clear()
        if (spots.isEmpty()) return

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
                val labelStyles = LabelStyles.from(
                    "potato_$styleKey",
                    LabelStyle.from(markerBitmap(labelText, parseColor(markerColor)))
                        .setAnchorPoint(0.5f, 1.0f),
                )
                labelManager.addLabelStyles(labelStyles) ?: labelStyles
            }

            val label = layer.addLabel(
                LabelOptions.from(
                    "potato-$spotId",
                    LatLng.from(latitude, longitude),
                )
                    .setStyles(styles)
                    .setClickable(true),
            )
            label.show()
            spotLabels.add(label)
            spotIdByLabelId[label.labelId] = spotId
        }
        scaleSpotLabels(kakaoMap, kakaoMap.cameraPosition)
    }

    private fun scaleSpotLabels(kakaoMap: KakaoMap, cameraPosition: CameraPosition?) {
        val level = cameraPosition?.zoomLevel ?: kakaoMap.zoomLevel
        val scale = when {
            level <= 5 -> 1.0f
            level <= 8 -> 0.82f
            level <= 11 -> 0.66f
            else -> 0.52f
        }
        spotLabels.forEach { label ->
            label.scaleTo(scale, scale)
        }
    }

    private fun renderRoutePolyline(kakaoMap: KakaoMap) {
        val shapeManager = kakaoMap.shapeManager ?: return
        val routeLayer = shapeManager.getLayer(routeLayerId)
            ?: shapeManager.addLayer(
                ShapeLayerOptions.from(routeLayerId, 8, ShapeLayerPass.Route),
            )
            ?: return

        routeLayer.removeAll()
        if (routePolyline.size < 2) {
            return
        }

        val points = routePolyline.mapNotNull { point ->
            val latitude = (point["latitude"] as? Number)?.toDouble() ?: return@mapNotNull null
            val longitude = (point["longitude"] as? Number)?.toDouble() ?: return@mapNotNull null
            LatLng.from(latitude, longitude)
        }
        if (points.size < 2) {
            return
        }

        val options = PolylineOptions.from(
            MapPoints.fromLatLng(points),
            12f,
            Color.parseColor("#F6C23E"),
        ).setZOrder(8)
        routeLayer.addPolyline(options)?.show()
        routeLayer.showAllPolyline()
    }

    private fun markerBitmap(text: String, strokeColor: Int): Bitmap {
        val width = if (text.contains("★")) 42 else 36
        val height = 36
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            style = Paint.Style.FILL
        }
        val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = strokeColor
            style = Paint.Style.STROKE
            strokeWidth = 2f
        }
        val textPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.BLACK
            textAlign = Paint.Align.CENTER
            textSize = if (text.contains("★")) 15f else 18f
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

    private fun spotMaps(value: Any?): List<Map<*, *>> {
        return pointMaps(value)
    }

    private fun pointMaps(value: Any?): List<Map<*, *>> {
        return (value as? List<*>)?.filterIsInstance<Map<*, *>>() ?: emptyList()
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
