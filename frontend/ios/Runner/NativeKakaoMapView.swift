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
  private var routePolyline: [[AnyHashable: Any]]
  private var isAuthenticated = false
  private var didPrepareEngine = false
  private let spotLayerID = "potatoSpotLayer"
  private let currentLocationLayerID = "potatoCurrentLocationLayer"
  private let currentLocationStyleID = "potatoCurrentLocationStyle"
  private let currentLocationPoiID = "potatoCurrentLocation"
  private let routeLayerID = "potatoRouteLayer"
  private let routeStyleID = "potatoRoutePolylineStyle"
  private let routeShapeID = "potatoRoutePolyline"
  private var spotStyleByPoiID: [String: (markerColor: String, isFavorite: Bool, routeIndex: Int)] = [:]
  private var spotIDByPoiID: [String: String] = [:]
  private var currentLocation: [AnyHashable: Any]?
  private var eventHandlers: [DisposableEventHandler] = []
  private var didRegisterRouteStyle = false

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
    routePolyline = Self.pointMaps(from: params["routePolyline"])
    currentLocation = Self.pointMap(from: params["currentLocation"])
    container = NativeKakaoMapContainer(frame: frame)
    channel = FlutterMethodChannel(
      name: "potato_mubwanna/kakao_map_\(viewId)",
      binaryMessenger: messenger
    )
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "updateSpots" {
        self?.spots = Self.spotMaps(from: call.arguments)
        self?.addSpotPois()
        result(nil)
        return
      }
      if call.method == "updateRoutePolyline" {
        self?.routePolyline = Self.pointMaps(from: call.arguments)
        self?.renderRoutePolyline()
        result(nil)
        return
      }
      if call.method == "updateCurrentLocation" {
        self?.currentLocation = Self.pointMap(from: call.arguments)
        self?.renderCurrentLocation()
        result(nil)
        return
      }
      result(FlutterMethodNotImplemented)
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
    renderRoutePolyline()
    renderCurrentLocation()
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
    if let spotID = spotIDByPoiID[poiID] {
      notifySpotSelected(spotID)
      return
    }
    guard layerID == spotLayerID else {
      return
    }
    let spotID = poiID.replacingOccurrences(of: "potato-", with: "")
    notifySpotSelected(spotID)
  }

  private func notifySpotSelected(_ spotID: String) {
    DispatchQueue.main.async { [weak self] in
#if DEBUG
      print("[NativeKakaoMapView] spotSelected \(spotID)")
#endif
      self?.channel.invokeMethod("spotSelected", arguments: ["spotId": spotID])
    }
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
    spotIDByPoiID.removeAll()
    eventHandlers.forEach { $0.dispose() }
    eventHandlers.removeAll()
    bindMapEventHandlers(mapView)
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

      let spotID = Self.stringValue(spot["id"]) ?? UUID().uuidString
      let poiID = "potato-\(spotID)"
      let isFavorite = Self.boolValue(spot["favorite"]) ?? false
      let routeIndex = Self.intValue(spot["routeIndex"]) ?? 0
      let markerColor = spot["markerColor"] as? String ?? (isFavorite ? "#F6C23E" : "#56C787")
      addPoiStyles(
        labelManager: labelManager,
        markerColor: markerColor,
        isFavorite: isFavorite,
        routeIndex: routeIndex
      )
      let styleID = styleIDFor(
        markerColor: markerColor,
        isFavorite: isFavorite,
        routeIndex: routeIndex,
        sizeKey: "medium"
      )
      let option = PoiOptions(
        styleID: styleID,
        poiID: poiID
      )
      option.clickable = true
      spotStyleByPoiID[poiID] = (
        markerColor: markerColor,
        isFavorite: isFavorite,
        routeIndex: routeIndex
      )
      spotIDByPoiID[poiID] = spotID
      let poi = layer?.addPoi(
        option: option,
        at: MapPoint(longitude: longitude, latitude: latitude)
      )
      if let poi {
        let tapHandler = poi.addPoiTappedEventHandler(target: self) { owner in
          return { _ in
            owner.notifySpotSelected(spotID)
          }
        }
        eventHandlers.append(tapHandler)
        poi.clickable = true
        poi.show()
      }
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
        isFavorite: style.isFavorite,
        routeIndex: style.routeIndex,
        sizeKey: sizeKey
      )
      layer.getPoi(poiID: poiID)?.changeStyle(styleID: styleID, enableTransition: false)
    }
  }

  private func renderRoutePolyline() {
    guard let mapView = mapController?.getView("potatoMap") as? KakaoMap else {
      return
    }
    let shapeManager = mapView.getShapeManager()
    let layer = shapeManager.getShapeLayer(layerID: routeLayerID) ??
      shapeManager.addShapeLayer(layerID: routeLayerID, zOrder: 8, passType: .route)
    guard let layer else {
      return
    }

    layer.clearAllShapes()
    guard routePolyline.count >= 2 else {
      return
    }

    let points = routePolyline.compactMap { point -> MapPoint? in
      guard
        let latitude = Self.doubleValue(point["latitude"]),
        let longitude = Self.doubleValue(point["longitude"])
      else {
        return nil
      }
      return MapPoint(longitude: longitude, latitude: latitude)
    }
    guard points.count >= 2 else {
      return
    }

    registerRoutePolylineStyleIfNeeded(shapeManager)
    let options = MapPolylineShapeOptions(
      shapeID: routeShapeID,
      styleID: routeStyleID,
      zOrder: 8
    )
    options.polylines = [MapPolyline(line: points, styleIndex: 0)]
    layer.addMapPolylineShape(options)?.show()
  }

  private func renderCurrentLocation() {
    guard let mapView = mapController?.getView("potatoMap") as? KakaoMap else {
      return
    }

    let labelManager = mapView.getLabelManager()
    let layer = labelManager.getLabelLayer(layerID: currentLocationLayerID) ?? labelManager.addLabelLayer(
      option: LabelLayerOptions(
        layerID: currentLocationLayerID,
        competitionType: .none,
        competitionUnit: .symbolFirst,
        orderType: .rank,
        zOrder: 20
      )
    )
    layer?.clearAllItems()
    layer?.visible = true

    guard
      let currentLocation,
      let latitude = Self.doubleValue(currentLocation["latitude"]),
      let longitude = Self.doubleValue(currentLocation["longitude"])
    else {
      mapView.refresh()
      return
    }

    labelManager.addPoiStyle(makeCurrentLocationStyle())
    let option = PoiOptions(styleID: currentLocationStyleID, poiID: currentLocationPoiID)
    let poi = layer?.addPoi(
      option: option,
      at: MapPoint(longitude: longitude, latitude: latitude)
    )
    poi?.show()
    mapView.refresh()
  }

  private func registerRoutePolylineStyleIfNeeded(_ shapeManager: ShapeManager) {
    guard !didRegisterRouteStyle else {
      return
    }
    let bodyColor = UIColor(red: 0.965, green: 0.761, blue: 0.243, alpha: 0.92)
    let strokeColor = UIColor.white.withAlphaComponent(0.88)
    let levelStyle = PerLevelPolylineStyle(
      bodyColor: bodyColor,
      bodyWidth: 7,
      strokeColor: strokeColor,
      strokeWidth: 2,
      level: 0
    )
    let style = PolylineStyle(styles: [levelStyle])
    shapeManager.addPolylineStyleSet(
      PolylineStyleSet(styleSetID: routeStyleID, styles: [style], capType: .round)
    )
    didRegisterRouteStyle = true
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

  private func addPoiStyles(
    labelManager: LabelManager,
    markerColor: String,
    isFavorite: Bool,
    routeIndex: Int
  ) {
    let color = colorFromHex(markerColor) ?? UIColor(red: 0.212, green: 0.851, blue: 0.561, alpha: 1)
    [
      ("small", CGSize(width: 45, height: 51)),
      ("medium", CGSize(width: 57, height: 65)),
      ("large", CGSize(width: 69, height: 78)),
    ].forEach { sizeKey, size in
      labelManager.addPoiStyle(
        makePoiStyle(
          styleID: styleIDFor(
            markerColor: markerColor,
            isFavorite: isFavorite,
            routeIndex: routeIndex,
            sizeKey: sizeKey
          ),
          color: color,
          isFavorite: isFavorite,
          routeIndex: routeIndex,
          size: size
        )
      )
    }
  }

  private func styleIDFor(
    markerColor: String,
    isFavorite: Bool,
    routeIndex: Int = 0,
    sizeKey: String
  ) -> String {
    let colorKey = markerColor
      .replacingOccurrences(of: "#", with: "")
      .replacingOccurrences(of: " ", with: "")
    return "potato\(colorKey)\(isFavorite ? "Favorite" : "Normal")Route\(routeIndex)\(sizeKey)"
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
    color: UIColor,
    isFavorite: Bool,
    routeIndex: Int,
    size: CGSize
  ) -> PoiStyle {
    let iconStyle = PoiIconStyle(
      symbol: makeMarkerImage(
        color: color,
        isFavorite: isFavorite,
        routeIndex: routeIndex,
        size: size
      ),
      anchorPoint: CGPoint(x: 0.5, y: 1.0)
    )
    let perLevelStyle = PerLevelPoiStyle(iconStyle: iconStyle, padding: 0, level: 0)
    return PoiStyle(styleID: styleID, styles: [perLevelStyle])
  }

  private func makeMarkerImage(
    color: UIColor,
    isFavorite: Bool,
    routeIndex: Int,
    size: CGSize
  ) -> UIImage? {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { context in
      let bodyDiameter = size.width * 0.82
      let bodyRect = CGRect(
        x: (size.width - bodyDiameter) / 2,
        y: 1,
        width: bodyDiameter,
        height: bodyDiameter
      )
      let tipSize = max(7, size.width * 0.23)
      let pinTip = UIBezierPath()
      pinTip.move(to: CGPoint(x: size.width / 2 - tipSize / 2, y: bodyRect.maxY - tipSize * 0.25))
      pinTip.addLine(to: CGPoint(x: size.width / 2 + tipSize / 2, y: bodyRect.maxY - tipSize * 0.25))
      pinTip.addLine(to: CGPoint(x: size.width / 2, y: size.height - 3))
      pinTip.close()
      color.setFill()
      pinTip.fill()

      UIColor.black.withAlphaComponent(0.16).setFill()
      UIBezierPath(
        ovalIn: CGRect(
          x: size.width * 0.18,
          y: size.height - 5,
          width: size.width * 0.64,
          height: 3
        )
      ).fill()

      let bodyColor = isFavorite
        ? UIColor(red: 1.0, green: 0.969, blue: 0.800, alpha: 0.97)
        : UIColor.white.withAlphaComponent(0.94)
      bodyColor.setFill()
      UIBezierPath(ovalIn: bodyRect).fill()
      color.setStroke()
      let bodyPath = UIBezierPath(ovalIn: bodyRect)
      bodyPath.lineWidth = max(2, size.width * 0.055)
      bodyPath.stroke()

      let emoji = "🥔" as NSString
      let fontSize = size.width * 0.48
      let attributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.systemFont(ofSize: fontSize),
      ]
      let emojiSize = emoji.size(withAttributes: attributes)
      let emojiRect = CGRect(
        x: (size.width - emojiSize.width) / 2,
        y: bodyRect.midY - emojiSize.height / 2 + 1,
        width: emojiSize.width,
        height: emojiSize.height
      )
      emoji.draw(in: emojiRect, withAttributes: attributes)

      if routeIndex > 0 {
        let badgeDiameter = max(18, size.width * 0.35)
        let badgeRect = CGRect(
          x: bodyRect.maxX - badgeDiameter + 2,
          y: bodyRect.maxY - badgeDiameter + 2,
          width: badgeDiameter,
          height: badgeDiameter
        )
        UIColor.white.setFill()
        UIBezierPath(ovalIn: badgeRect).fill()
        UIColor(red: 0.314, green: 0.608, blue: 0.392, alpha: 1).setStroke()
        let badgePath = UIBezierPath(ovalIn: badgeRect)
        badgePath.lineWidth = max(1.8, size.width * 0.035)
        badgePath.stroke()

        let badgeText = "\(routeIndex)" as NSString
        let badgeFontSize = max(10, size.width * 0.19)
        let badgeAttributes: [NSAttributedString.Key: Any] = [
          .font: UIFont.systemFont(ofSize: badgeFontSize, weight: .black),
          .foregroundColor: UIColor(red: 0.125, green: 0.137, blue: 0.102, alpha: 1),
        ]
        let badgeTextSize = badgeText.size(withAttributes: badgeAttributes)
        let badgeTextRect = CGRect(
          x: badgeRect.midX - badgeTextSize.width / 2,
          y: badgeRect.midY - badgeTextSize.height / 2,
          width: badgeTextSize.width,
          height: badgeTextSize.height
        )
        badgeText.draw(in: badgeTextRect, withAttributes: badgeAttributes)
      }
    }
  }

  private func makeCurrentLocationStyle() -> PoiStyle {
    let iconStyle = PoiIconStyle(
      symbol: makeCurrentLocationImage(size: CGSize(width: 30, height: 30)),
      anchorPoint: CGPoint(x: 0.5, y: 0.5)
    )
    let perLevelStyle = PerLevelPoiStyle(iconStyle: iconStyle, padding: 0, level: 0)
    return PoiStyle(styleID: currentLocationStyleID, styles: [perLevelStyle])
  }

  private func makeCurrentLocationImage(size: CGSize) -> UIImage? {
    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { _ in
      UIColor(red: 0.184, green: 0.502, blue: 0.929, alpha: 0.18).setFill()
      UIBezierPath(ovalIn: CGRect(origin: .zero, size: size)).fill()

      UIColor.white.setFill()
      UIBezierPath(
        ovalIn: CGRect(x: 7, y: 7, width: size.width - 14, height: size.height - 14)
      ).fill()

      UIColor(red: 0.184, green: 0.502, blue: 0.929, alpha: 1).setFill()
      UIBezierPath(
        ovalIn: CGRect(x: 10, y: 10, width: size.width - 20, height: size.height - 20)
      ).fill()
    }
  }

  private static func spotMaps(from value: Any?) -> [[AnyHashable: Any]] {
    pointMaps(from: value)
  }

  private static func pointMaps(from value: Any?) -> [[AnyHashable: Any]] {
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

  private static func pointMap(from value: Any?) -> [AnyHashable: Any]? {
    if let map = value as? [AnyHashable: Any] {
      return map
    }
    if let map = value as? [String: Any] {
      return Dictionary(uniqueKeysWithValues: map.map { (AnyHashable($0.key), $0.value) })
    }
    if let dictionary = value as? NSDictionary {
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
    return nil
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

  private static func stringValue(_ value: Any?) -> String? {
    if let string = value as? String {
      return string
    }
    if let number = value as? NSNumber {
      return number.stringValue
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
