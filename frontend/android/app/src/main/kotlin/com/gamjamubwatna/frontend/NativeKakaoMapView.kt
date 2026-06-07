package com.gamjamubwatna.frontend

import android.content.Context
import android.view.View
import android.widget.FrameLayout
import android.widget.TextView
import com.kakao.vectormap.KakaoMap
import com.kakao.vectormap.KakaoMapReadyCallback
import com.kakao.vectormap.KakaoMapSdk
import com.kakao.vectormap.LatLng
import com.kakao.vectormap.MapLifeCycleCallback
import com.kakao.vectormap.MapView
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
                    override fun onMapReady(kakaoMap: KakaoMap) = Unit

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
