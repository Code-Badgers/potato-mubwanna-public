import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let controller = window?.rootViewController as! FlutterViewController
    registrar(forPlugin: "NativeKakaoMapView")?
      .register(
        NativeKakaoMapViewFactory(messenger: controller.binaryMessenger),
        withId: "potato_mubwanna/kakao_map"
      )
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
