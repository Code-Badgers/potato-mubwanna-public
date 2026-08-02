import UIKit
import Flutter
import HealthKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let healthBackgroundStepSync = HealthBackgroundStepSyncCoordinator()
  private var healthBackgroundSyncChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      registrar(forPlugin: "NativeKakaoMapView")?
        .register(
          NativeKakaoMapViewFactory(messenger: controller.binaryMessenger),
          withId: "potato_mubwanna/kakao_map"
        )
      let healthBackgroundSyncChannel = FlutterMethodChannel(
        name: HealthBackgroundStepSyncCoordinator.channelName,
        binaryMessenger: controller.binaryMessenger
      )
      healthBackgroundSyncChannel.setMethodCallHandler { [weak self] call, result in
        guard call.method == HealthBackgroundStepSyncCoordinator.enableMethod else {
          result(FlutterMethodNotImplemented)
          return
        }

        self?.healthBackgroundStepSync.enableBackgroundDelivery()
        result(nil)
      }
      self.healthBackgroundSyncChannel = healthBackgroundSyncChannel
    }
    healthBackgroundStepSync.registerObserver()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

private final class HealthBackgroundStepSyncCoordinator {
  static let channelName = "potato_mubwanna/health_background_sync"
  static let enableMethod = "enable"

  private static let startMethod = "start"
  private static let completedMethod = "completed"
  private static let entrypoint = "iosHealthBackgroundSyncEntrypoint"
  private static let timeout: TimeInterval = 25

  private let healthStore = HKHealthStore()
  private var observerQuery: HKObserverQuery?
  private var backgroundEngine: FlutterEngine?
  private var backgroundChannel: FlutterMethodChannel?
  private var timeoutWorkItem: DispatchWorkItem?
  private var observerCompletions: [HKObserverQueryCompletionHandler] = []

  func registerObserver() {
    guard observerQuery == nil,
          HKHealthStore.isHealthDataAvailable(),
          let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)
    else {
      return
    }

    let query = HKObserverQuery(sampleType: stepType, predicate: nil) {
      [weak self] _, completionHandler, error in
      guard let self else {
        completionHandler()
        return
      }

      if let error {
        NSLog("HealthKit step observer failed: %@", error.localizedDescription)
        completionHandler()
        return
      }

      DispatchQueue.main.async { [weak self] in
        guard let self else {
          completionHandler()
          return
        }
        self.enqueueBackgroundSync(completionHandler)
      }
    }

    observerQuery = query
    healthStore.execute(query)
    enableBackgroundDelivery(for: stepType)
  }

  func enableBackgroundDelivery() {
    guard HKHealthStore.isHealthDataAvailable(),
          let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)
    else {
      return
    }

    enableBackgroundDelivery(for: stepType)
  }

  private func enableBackgroundDelivery(for stepType: HKQuantityType) {
    healthStore.enableBackgroundDelivery(for: stepType, frequency: .hourly) {
      success, error in
      if !success {
        NSLog(
          "HealthKit background delivery could not be enabled: %@",
          error?.localizedDescription ?? "unknown error"
        )
      }
    }
  }

  private func enqueueBackgroundSync(
    _ completionHandler: @escaping HKObserverQueryCompletionHandler
  ) {
    observerCompletions.append(completionHandler)
    guard backgroundEngine == nil else {
      return
    }

    let engine = FlutterEngine(
      name: "health-background-step-sync",
      project: nil,
      allowHeadlessExecution: true
    )
    backgroundEngine = engine

    guard engine.run(withEntrypoint: Self.entrypoint) else {
      finishBackgroundSync()
      return
    }

    GeneratedPluginRegistrant.register(with: engine)
    let channel = FlutterMethodChannel(
      name: Self.channelName,
      binaryMessenger: engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == Self.completedMethod else {
        result(FlutterMethodNotImplemented)
        return
      }

      result(nil)
      DispatchQueue.main.async { [weak self] in
        self?.finishBackgroundSync()
      }
    }
    backgroundChannel = channel

    let timeoutWorkItem = DispatchWorkItem { [weak self] in
      self?.finishBackgroundSync()
    }
    self.timeoutWorkItem = timeoutWorkItem
    DispatchQueue.main.asyncAfter(
      deadline: .now() + Self.timeout,
      execute: timeoutWorkItem
    )

    channel.invokeMethod(Self.startMethod, arguments: nil)
  }

  private func finishBackgroundSync() {
    guard !observerCompletions.isEmpty else {
      return
    }

    timeoutWorkItem?.cancel()
    timeoutWorkItem = nil
    backgroundChannel?.setMethodCallHandler(nil)
    backgroundChannel = nil
    backgroundEngine?.destroyContext()
    backgroundEngine = nil

    let completions = observerCompletions
    observerCompletions.removeAll()
    completions.forEach { $0() }
  }
}
