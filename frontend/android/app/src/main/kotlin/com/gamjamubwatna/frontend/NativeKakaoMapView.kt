package com.gamjamubwatna.frontend

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
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
import com.kakao.vectormap.camera.CameraUpdateFactory
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
    private var currentLocation = pointMap(params["currentLocation"])
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
                        kakaoMap?.let {
                            addSpotLabels(it, nextSpots)
                            renderCurrentLocation(it)
                        }
                        result.success(null)
                    }
                    "updateRoutePolyline" -> {
                        routePolyline = pointMaps(call.arguments)
                        kakaoMap?.let { renderRoutePolyline(it) }
                        result.success(null)
                    }
                    "updateCurrentLocation" -> {
                        currentLocation = pointMap(call.arguments)
                        kakaoMap?.let { renderCurrentLocation(it) }
                        result.success(null)
                    }
                    "focusCurrentLocation" -> {
                        currentLocation = pointMap(call.arguments) ?: currentLocation
                        kakaoMap?.let {
                            renderCurrentLocation(it)
                            focusCurrentLocation(it)
                        }
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
                            renderCurrentLocation(kakaoMap)
                            kakaoMap.setOnLabelClickListener { _, _, label ->
                                val spotId = spotIdByLabelId[label.labelId] ?: return@setOnLabelClickListener false
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
        container.setBackgroundColor(0xFFE5F6EA.toInt())
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
        layer.setClickable(true)
        spotLabels.clear()
        spotIdByLabelId.clear()
        if (spots.isEmpty()) return

        val styleCache = mutableMapOf<String, LabelStyles>()
        spots.forEach { spot ->
            val latitude = (spot["latitude"] as? Number)?.toDouble() ?: return@forEach
            val longitude = (spot["longitude"] as? Number)?.toDouble() ?: return@forEach
            val spotId = spot["id"]?.toString() ?: "${latitude}_${longitude}"
            val isFavorite = spot["favorite"] as? Boolean ?: false
            val routeIndex = (spot["routeIndex"] as? Number)?.toInt() ?: 0
            val markerColor = spot["markerColor"]?.toString() ?: if (isFavorite) "#F6C23E" else "#56C787"
            val styleKey = "${markerColor.replace("#", "")}_${if (isFavorite) "favorite" else "normal"}_$routeIndex"
            val styles = styleCache.getOrPut(styleKey) {
                val labelStyles = LabelStyles.from(
                    "potato_$styleKey",
                    LabelStyle.from(markerBitmap(parseColor(markerColor), isFavorite, routeIndex))
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

    private fun renderCurrentLocation(kakaoMap: KakaoMap) {
        val location = currentLocation ?: return
        val latitude = (location["latitude"] as? Number)?.toDouble() ?: return
        val longitude = (location["longitude"] as? Number)?.toDouble() ?: return
        val labelManager = kakaoMap.labelManager ?: return
        val layer = labelManager.layer ?: return
        val styles = LabelStyles.from(
            "potatoCurrentLocationStyle",
            LabelStyle.from(currentLocationBitmap()).setAnchorPoint(0.5f, 0.5f),
        )
        val registeredStyles = labelManager.addLabelStyles(styles) ?: styles
        layer.addLabel(
            LabelOptions.from(
                "potato-current-location",
                LatLng.from(latitude, longitude),
            ).setStyles(registeredStyles),
        )?.show()
    }

    private fun focusCurrentLocation(kakaoMap: KakaoMap) {
        val location = currentLocation ?: return
        val latitude = (location["latitude"] as? Number)?.toDouble() ?: return
        val longitude = (location["longitude"] as? Number)?.toDouble() ?: return
        kakaoMap.moveCamera(
            CameraUpdateFactory.newCenterPosition(LatLng.from(latitude, longitude)),
        )
    }

    private fun markerBitmap(strokeColor: Int, isFavorite: Boolean, routeIndex: Int): Bitmap {
        val width = 69
        val height = 78
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = if (isFavorite) {
                Color.argb(247, 255, 247, 204)
            } else {
                Color.argb(240, 255, 255, 255)
            }
            style = Paint.Style.FILL
        }
        val strokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = strokeColor
            style = Paint.Style.STROKE
            strokeWidth = 2.8f
        }
        val shadowPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.argb(34, 32, 35, 26)
            style = Paint.Style.FILL
        }
        val pinPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = strokeColor
            style = Paint.Style.FILL
        }
        val emojiPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textAlign = Paint.Align.CENTER
            textSize = 34.5f
        }
        val badgeFillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            style = Paint.Style.FILL
        }
        val badgeStrokePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = parseColor("#509B64")
            style = Paint.Style.STROKE
            strokeWidth = 2.4f
        }
        val badgeTextPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.rgb(32, 35, 26)
            textAlign = Paint.Align.CENTER
            textSize = 13.5f
            isFakeBoldText = true
        }

        canvas.drawOval(
            RectF(13.5f, height - 7.5f, width - 13.5f, height - 3f),
            shadowPaint,
        )

        val pointer = Path().apply {
            moveTo(width / 2f - 7.5f, 52.5f)
            lineTo(width / 2f + 7.5f, 52.5f)
            lineTo(width / 2f, height - 4.5f)
            close()
        }
        canvas.drawPath(pointer, pinPaint)

        val bodyRect = RectF(6f, 1.5f, width - 6f, 58.5f)
        canvas.drawOval(bodyRect, fillPaint)
        canvas.drawOval(bodyRect, strokePaint)
        canvas.drawText("🥔", width / 2f, bodyRect.centerY() + 12f, emojiPaint)
        if (routeIndex > 0) {
            val badgeCenterX = bodyRect.right - 10f
            val badgeCenterY = bodyRect.bottom - 10f
            canvas.drawCircle(badgeCenterX, badgeCenterY, 12f, badgeFillPaint)
            canvas.drawCircle(badgeCenterX, badgeCenterY, 12f, badgeStrokePaint)
            val textOffset = (badgeTextPaint.descent() + badgeTextPaint.ascent()) / 2f
            canvas.drawText(routeIndex.toString(), badgeCenterX, badgeCenterY - textOffset, badgeTextPaint)
        }
        return bitmap
    }

    private fun currentLocationBitmap(): Bitmap {
        val size = 30
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val haloPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.argb(46, 47, 128, 237)
            style = Paint.Style.FILL
        }
        val whitePaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.WHITE
            style = Paint.Style.FILL
        }
        val dotPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.rgb(47, 128, 237)
            style = Paint.Style.FILL
        }
        canvas.drawCircle(size / 2f, size / 2f, 15f, haloPaint)
        canvas.drawCircle(size / 2f, size / 2f, 8f, whitePaint)
        canvas.drawCircle(size / 2f, size / 2f, 5f, dotPaint)
        return bitmap
    }

    private fun parseColor(hex: String): Int {
        return runCatching { Color.parseColor(hex) }.getOrDefault(0xFF56C787.toInt())
    }

    private fun spotMaps(value: Any?): List<Map<*, *>> {
        return pointMaps(value)
    }

    private fun pointMaps(value: Any?): List<Map<*, *>> {
        return (value as? List<*>)?.filterIsInstance<Map<*, *>>() ?: emptyList()
    }

    private fun pointMap(value: Any?): Map<*, *>? {
        return value as? Map<*, *>
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
