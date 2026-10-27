import Flutter
import UIKit
import UserNotifications
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var appIconSwitcher: AppIconSwitcher?
  private var widgetBridge: WidgetBridge?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Lets reminder notifications show as banners while the app is open.
    UNUserNotificationCenter.current().delegate = self
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "AppIconSwitcher") {
      appIconSwitcher = AppIconSwitcher(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "WidgetBridge") {
      widgetBridge = WidgetBridge(messenger: registrar.messenger())
    }
  }
}

/// Hands the widgets' data (lib/features/widgets/widget_sync.dart) to the
/// PushupBroWidgets extension through the App Group.
final class WidgetBridge {
  private static let appGroup = "group.com.lucas-goldner.pushup-bro"
  private static let snapshotKey = "widget_snapshot"
  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "pushup_bro/widgets", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "update" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let json = call.arguments as? String,
        let defaults = UserDefaults(suiteName: WidgetBridge.appGroup)
      else {
        result(FlutterError(code: "widgets", message: "App Group unavailable", details: nil))
        return
      }
      if defaults.string(forKey: WidgetBridge.snapshotKey) != json {
        defaults.set(json, forKey: WidgetBridge.snapshotKey)
        if #available(iOS 14.0, *) {
          WidgetCenter.shared.reloadAllTimelines()
        }
      }
      result(nil)
    }
  }
}

/// Switches the home screen icon between the alternate icons listed in
/// ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES (lib/features/app_icon/).
final class AppIconSwitcher {
  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "pushup_bro/app_icon", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      let app = UIApplication.shared
      switch call.method {
      case "isSupported":
        result(app.supportsAlternateIcons)
      case "current":
        result(app.alternateIconName)
      case "set":
        let name = call.arguments as? String
        guard app.supportsAlternateIcons else {
          result(
            FlutterError(code: "app_icon", message: "Alternate icons are not supported", details: nil))
          return
        }
        if app.alternateIconName == name {
          result(nil)
          return
        }
        app.setAlternateIconName(name) { error in
          DispatchQueue.main.async {
            if let error = error {
              result(FlutterError(code: "app_icon", message: error.localizedDescription, details: nil))
            } else {
              result(nil)
            }
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
