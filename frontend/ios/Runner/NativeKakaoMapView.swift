import Flutter
import KakaoMapsSDK
import UIKit

final class NativeKakaoMapView: NSObject, FlutterPlatformView, MapControllerDelegate {
  private let container: KMViewContainer
  private var mapController: KMController?
  private let latitude: Double
  private let longitude: Double
  private let zoomLevel: Int
  private var isAuthenticated = false

  init(
    frame: CGRect,
    viewId: Int64,
    args: Any?,
    messenger: FlutterBinaryMessenger
  ) {
    let params = args as? [String: Any] ?? [:]
    latitude = params["latitude"] as? Double ?? 37.3808
    longitude = params["longitude"] as? Double ?? 128.6609
    zoomLevel = params["zoomLevel"] as? Int ?? 9
    container = KMViewContainer(frame: frame)
    super.init()

    let nativeAppKey = params["nativeAppKey"] as? String ?? ""
    if nativeAppKey.isEmpty {
      showFallback("KAKAO_NATIVE_APP_KEY 설정 후 모바일 카카오맵이 표시됩니다.")
      return
    }

    SDKInitializer.InitSDK(appKey: nativeAppKey)
    mapController = KMController(viewContainer: container)
    mapController?.delegate = self
    mapController?.prepareEngine()
  }

  func view() -> UIView {
    container
  }

  func authenticationSucceeded() {
    isAuthenticated = true
    mapController?.activateEngine()
  }

  func authenticationFailed(_ errorCode: Int, desc: String) {
    showFallback("카카오맵 인증에 실패했습니다.")
  }

  func addViews() {
    let defaultPosition = MapPoint(longitude: longitude, latitude: latitude)
    let mapviewInfo = MapviewInfo(
      viewName: "potatoMap",
      viewInfoName: "map",
      defaultPosition: defaultPosition,
      defaultLevel: zoomLevel
    )
    mapController?.addView(mapviewInfo)
  }

  func addViewSucceeded(_ viewName: String, viewInfoName: String) {
    container.setNeedsLayout()
    container.layoutIfNeeded()
  }

  func addViewFailed(_ viewName: String, viewInfoName: String) {
    showFallback("카카오맵을 표시하지 못했습니다.")
  }

  deinit {
    mapController?.pauseEngine()
    mapController?.resetEngine()
  }

  private func showFallback(_ message: String) {
    container.subviews.forEach { $0.removeFromSuperview() }
    container.backgroundColor = UIColor(red: 0.918, green: 0.961, blue: 0.835, alpha: 1)

    let label = UILabel(frame: container.bounds)
    label.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    label.text = message
    label.textAlignment = .center
    label.numberOfLines = 0
    label.textColor = UIColor(red: 0.31, green: 0.40, blue: 0.34, alpha: 1)
    label.font = .systemFont(ofSize: 13, weight: .semibold)
    container.addSubview(label)
  }
}
