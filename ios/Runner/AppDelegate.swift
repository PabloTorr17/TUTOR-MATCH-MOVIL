import Flutter
import UIKit
import Stripe

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    STPAPIClient.shared.publishableKey = "pk_test_51Td1fo1Atb0bhefly5xtkWDDBcb8vDBkxdtBxDmeq9bUDDkBmQukQBbC92GzDSNhWymgvz9M5S9JWaxSfb0sPia200JlJwGVxk"
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
