import Flutter
import KakaoMapsSDK
import UIKit

private final class NativeKakaoMapContainer: KMViewContainer {
  var onLayout: ((CGSize) -> Void)?

  override func layoutSubviews() {
    super.layoutSubviews()
    onLayout?(bounds.size)
  }
}

final class NativeKakaoMapView: NSObject, FlutterPlatformView, MapControllerDelegate, KakaoMapEventDelegate {
  private let container: NativeKakaoMapContainer
  private var mapController: KMController?
  private let channel: FlutterMethodChannel
  private let latitude: Double
  private let longitude: Double
  private let zoomLevel: Int
  private var spots: [[AnyHashable: Any]]
  private var isAuthenticated = false
  private var didPrepareEngine = false
  private let spotLayerID = "potatoSpotLayer"
  private var spotStyleByPoiID: [String: (markerColor: String, isRare: Bool)] = [:]
  private var eventHandlers: [DisposableEventHandler] = []

  init(
    frame: CGRect,
    viewId: Int64,
    args: Any?,
    messenger: FlutterBinaryMessenger
  ) {
    let params = args as? [String: Any] ?? [:]
    latitude = Self.doubleValue(params["latitude"]) ?? 37.3808
    longitude = Self.doubleValue(params["longitude"]) ?? 128.6609
    zoomLevel = Self.intValue(params["zoomLevel"]) ?? 9
    spots = Self.spotMaps(from: params["spots"])
    container = NativeKakaoMapContainer(frame: frame)
    channel = FlutterMethodChannel(
      name: "potato_mubwanna/kakao_map_\(viewId)",
      binaryMessenger: messenger
    )
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "updateSpots" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.spots = Self.spotMaps(from: call.arguments)
      self?.addSpotPois()
      result(nil)
    }

    let nativeAppKey = params["nativeAppKey"] as? String ?? ""
    if nativeAppKey.isEmpty {
      showFallback("KAKAO_NATIVE_APP_KEY 설정 후 모바일 카카오맵이 표시됩니다.")
      return
    }

    SDKInitializer.InitSDK(appKey: nativeAppKey)
    mapController = KMController(viewContainer: container)
    mapController?.delegate = self
    container.onLayout = { [weak self] size in
      self?.prepareEngineIfNeeded(for: size)
      self?.resizeMap(to: size)
    }
    DispatchQueue.main.async { [weak self] in
      guard let self else { return }
      self.prepareEngineIfNeeded(for: self.container.bounds.size)
    }
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
    resizeMap(to: container.bounds.size)
    let mapView = mapController?.getView("potatoMap") as? KakaoMap
    mapView?.eventDelegate = self
    if let mapView {
      bindMapEventHandlers(mapView)
    }
    addSpotPois()
  }

  func poiDidTapped(kakaoMap: KakaoMap, layerID: String, poiID: String, position: MapPoint) {
    handleSpotPoiTap(layerID: layerID, poiID: poiID)
  }

  func cameraDidStopped(kakaoMap: KakaoMap, by: MoveBy) {
    applySpotPoiScale(for: kakaoMap)
  }

  func containerDidResized(_ size: CGSize) {
    resizeMap(to: size)
  }

  func addViewFailed(_ viewName: String, viewInfoName: String) {
    showFallback("카카오맵을 표시하지 못했습니다.")
  }

  deinit {
    channel.setMethodCallHandler(nil)
    eventHandlers.forEach { $0.dispose() }
    eventHandlers.removeAll()
    mapController?.pauseEngine()
    mapController?.resetEngine()
  }

  private func prepareEngineIfNeeded(for size: CGSize) {
    guard !didPrepareEngine, size.width > 0, size.height > 0 else {
      return
    }
    didPrepareEngine = true
    mapController?.prepareEngine()
  }

  private func resizeMap(to size: CGSize) {
    guard size.width > 0, size.height > 0 else {
      return
    }
    let mapView = mapController?.getView("potatoMap") as? KakaoMap
    mapView?.viewRect = CGRect(origin: .zero, size: size)
  }

  private func bindMapEventHandlers(_ mapView: KakaoMap) {
    eventHandlers.forEach { $0.dispose() }
    eventHandlers.removeAll()

    let poiTapHandler = mapView.addPoisTappedEventHandler(target: self) { owner in
      return { param in
        owner.handleSpotPoiTap(layerID: param.layerID, poiID: param.poiID)
      }
    }
    let cameraHandler = mapView.addCameraStoppedEventHandler(target: self) { owner in
      return { param in
        guard let kakaoMap = param.view as? KakaoMap else {
          return
        }
        owner.applySpotPoiScale(for: kakaoMap)
      }
    }
    eventHandlers.append(poiTapHandler)
    eventHandlers.append(cameraHandler)
  }

  private func handleSpotPoiTap(layerID: String, poiID: String) {
    guard layerID == spotLayerID else {
      return
    }
    let spotID = poiID.replacingOccurrences(of: "potato-", with: "")
    channel.invokeMethod("spotSelected", arguments: spotID)
  }

  private func addSpotPois() {
    guard let mapView = mapController?.getView("potatoMap") as? KakaoMap else {
      return
    }

    let labelManager = mapView.getLabelManager()
    let layer = labelManager.getLabelLayer(layerID: spotLayerID) ?? labelManager.addLabelLayer(
      option: LabelLayerOptions(
        layerID: spotLayerID,
        competitionType: .none,
        competitionUnit: .symbolFirst,
        orderType: .rank,
        zOrder: 10
      )
    )
    layer?.clearAllItems()
    layer?.visible = true
    layer?.setClickable(true)
    spotStyleByPoiID.removeAll()
    if spots.isEmpty {
      mapView.refresh()
      return
    }

    for spot in spots {
      guard
        let latitude = Self.doubleValue(spot["latitude"]),
        let longitude = Self.doubleValue(spot["longitude"])
      else {
        continue
      }

      let spotID = "\(spot["id"] ?? UUID().uuidString)"
      let poiID = "potato-\(spotID)"
      let isRare = Self.boolValue(spot["rare"]) ?? false
      let markerColor = spot["markerColor"] as? String ?? (isRare ? "#F6C23E" : "#36D98F")
      addPoiStyles(
        labelManager: labelManager,
        markerColor: markerColor,
        isRare: isRare
      )
      let styleID = styleIDFor(markerColor: markerColor, isRare: isRare, sizeKey: "medium")
      let option = PoiOptions(
        styleID: styleID,
        poiID: poiID
      )
      option.clickable = true
      spotStyleByPoiID[poiID] = (markerColor: markerColor, isRare: isRare)
      layer?.addPoi(
        option: option,
        at: MapPoint(longitude: longitude, latitude: latitude)
      )?.show()
    }
    layer?.showAllPois()
    applySpotPoiScale(for: mapView)
    mapView.refresh()
  }

  private func applySpotPoiScale(for mapView: KakaoMap) {
    let sizeKey = sizeKeyForZoomLevel(mapView.zoomLevel)
    guard let layer = mapView.getLabelManager().getLabelLayer(layerID: spotLayerID) else {
      return
    }
    spotStyleByPoiID.forEach { poiID, style in
      let styleID = styleIDFor(
        markerColor: style.markerColor,
        isRare: style.isRare,
        sizeKey: sizeKey
      )
      layer.getPoi(poiID: poiID)?.changeStyle(styleID: styleID, enableTransition: false)
    }
  }

  private func sizeKeyForZoomLevel(_ zoomLevel: Int) -> String {
    if zoomLevel <= 5 {
      return "large"
    }
    if zoomLevel <= 9 {
      return "medium"
    }
    return "small"
  }

  private func addPoiStyles(labelManager: LabelManager, markerColor: String, isRare: Bool) {
    let color = colorFromHex(markerColor) ?? UIColor(red: 0.212, green: 0.851, blue: 0.561, alpha: 1)
    let text = isRare ? "🥔★" : "🥔"
    [
      ("small", CGSize(width: isRare ? 30 : 26, height: 26), CGFloat(isRare ? 10 : 13)),
      ("medium", CGSize(width: isRare ? 38 : 32, height: 32), CGFloat(isRare ? 13 : 16)),
      ("large", CGSize(width: isRare ? 44 : 38, height: 38), CGFloat(isRare ? 15 : 18)),
    ].forEach { sizeKey, size, fontSize in
      labelManager.addPoiStyle(
        makePoiStyle(
          styleID: styleIDFor(markerColor: markerColor, isRare: isRare, sizeKey: sizeKey),
          text: text,
          color: color,
          size: size,
          fontSize: fontSize
        )
      )
    }
  }

  private func styleIDFor(markerColor: String, isRare: Bool, sizeKey: String) -> String {
    let colorKey = markerColor
      .replacingOccurrences(of: "#", with: "")
      .replacingOccurrences(of: " ", with: "")
    return "potato\(colorKey)\(isRare ? "Rare" : "Normal")\(sizeKey)"
  }

  private func colorFromHex(_ hex: String) -> UIColor? {
    let normalized = hex
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .replacingOccurrences(of: "#", with: "")
    guard normalized.count == 6, let value = Int(normalized, radix: 16) else {
      return nil
    }
    return UIColor(
      red: CGFloat((value >> 16) & 0xFF) / 255.0,
      green: CGFloat((value >> 8) & 0xFF) / 255.0,
      blue: CGFloat(value & 0xFF) / 255.0,
      alpha: 1
    )
  }

  private func makePoiStyle(
    styleID: String,
    text: String,
    color: UIColor,
    size: CGSize,
    fontSize: CGFloat
  ) -> PoiStyle {
    let iconStyle = PoiIconStyle(
      symbol: makeMarkerImage(text: text, color: color, size: size, fontSize: fontSize),
      anchorPoint: CGPoint(x: 0.5, y: 1.0)
    )
    let perLevelStyle = PerLevelPoiStyle(iconStyle: iconStyle, padding: 0, level: 0)
    return PoiStyle(styleID: styleID, styles: [perLevelStyle])
  }

  private func makeMarkerImage(
    text: String,
    color: UIColor,
    size: CGSize,
    fontSize: CGFloat
  ) -> UIImage? {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { _ in
      let markerRect = CGRect(x: 3, y: 3, width: size.width - 6, height: size.height - 6)
      let markerPath = UIBezierPath(
        roundedRect: markerRect,
        cornerRadius: markerRect.height / 2
      )
      UIColor.white.setFill()
      markerPath.fill()
      color.setStroke()
      markerPath.lineWidth = 2
      markerPath.stroke()

      let paragraph = NSMutableParagraphStyle()
      paragraph.alignment = .center
      let attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: fontSize),
        .paragraphStyle: paragraph,
      ]
      let textRect = CGRect(x: 0, y: (size.height - fontSize) / 2 - 1, width: size.width, height: fontSize + 4)
      NSAttributedString(string: text, attributes: attributes).draw(in: textRect)
    }
  }

  private static func spotMaps(from value: Any?) -> [[AnyHashable: Any]] {
    if let maps = value as? [[AnyHashable: Any]] {
      return maps
    }
    if let maps = value as? [[String: Any]] {
      return maps.map { Dictionary(uniqueKeysWithValues: $0.map { (AnyHashable($0.key), $0.value) }) }
    }
    if let array = value as? [NSDictionary] {
      return array.compactMap { dictionary in
        var result: [AnyHashable: Any] = [:]
        dictionary.forEach { key, value in
          if let hashableKey = key as? AnyHashable {
            result[hashableKey] = value
          } else if let stringKey = key as? String {
            result[AnyHashable(stringKey)] = value
          }
        }
        return result
      }
    }
    return []
  }

  private static func doubleValue(_ value: Any?) -> Double? {
    if let double = value as? Double {
      return double
    }
    if let number = value as? NSNumber {
      return number.doubleValue
    }
    if let string = value as? String {
      return Double(string)
    }
    return nil
  }

  private static func intValue(_ value: Any?) -> Int? {
    if let int = value as? Int {
      return int
    }
    if let number = value as? NSNumber {
      return number.intValue
    }
    if let string = value as? String {
      return Int(string)
    }
    return nil
  }

  private static func boolValue(_ value: Any?) -> Bool? {
    if let bool = value as? Bool {
      return bool
    }
    if let number = value as? NSNumber {
      return number.boolValue
    }
    if let string = value as? String {
      return Bool(string)
    }
    return nil
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
