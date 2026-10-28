import Flutter
import UIKit
import UserNotifications
import Vision
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var appIconSwitcher: AppIconSwitcher?
  private var widgetBridge: WidgetBridge?
  private var poseVision: PoseVision?

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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "PoseVision") {
      poseVision = PoseVision(messenger: registrar.messenger())
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

/// Finds the player's body in camera frames for the camera pushup counter
/// (lib/features/pushup_tracking/camera/camera_tracker_device.dart), with
/// Apple's Vision framework: body pose for the joints and person
/// segmentation for the cut-out. Built into iOS, so no package is needed.
final class PoseVision {
  /// The joints the pushup tracker reads, by the names it uses.
  private static let joints: [(String, VNHumanBodyPoseObservation.JointName)] = [
    ("nose", .nose),
    ("leftShoulder", .leftShoulder),
    ("rightShoulder", .rightShoulder),
    ("leftElbow", .leftElbow),
    ("rightElbow", .rightElbow),
    ("leftWrist", .leftWrist),
    ("rightWrist", .rightWrist),
    ("leftHip", .leftHip),
    ("rightHip", .rightHip),
    ("leftKnee", .leftKnee),
    ("rightKnee", .rightKnee),
    ("leftAnkle", .leftAnkle),
    ("rightAnkle", .rightAnkle),
  ]

  private let channel: FlutterMethodChannel
  private let queue = DispatchQueue(label: "pushup_bro.pose", qos: .userInitiated)

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "pushup_bro/pose", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "process", let self,
        let args = call.arguments as? [String: Any]
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      self.queue.async {
        let reply = self.process(args)
        DispatchQueue.main.async { result(reply) }
      }
    }
  }

  /// Takes a BGRA frame and how far it's turned from upright (0, 90, 180
  /// or 270 degrees clockwise to make it upright). Returns the joints, each
  /// as [x, y, confidence] in 0...1 of the upright frame with y going down,
  /// and, when asked for, the person mask (one byte per pixel, upright).
  private func process(_ args: [String: Any]) -> [String: Any]? {
    guard let data = args["bytes"] as? FlutterStandardTypedData,
      let width = args["width"] as? Int,
      let height = args["height"] as? Int,
      let bytesPerRow = args["bytesPerRow"] as? Int,
      width > 0, height > 0, data.data.count >= bytesPerRow * height
    else { return nil }
    let degrees = args["rotation"] as? Int ?? 0
    let wantsMask = args["mask"] as? Bool ?? false

    var buffer: CVPixelBuffer?
    let attributes = [kCVPixelBufferIOSurfacePropertiesKey as String: [String: Any]()] as CFDictionary
    CVPixelBufferCreate(
      kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attributes, &buffer)
    guard let pixels = buffer else { return nil }
    CVPixelBufferLockBaseAddress(pixels, [])
    if let base = CVPixelBufferGetBaseAddress(pixels) {
      let rowLength = CVPixelBufferGetBytesPerRow(pixels)
      data.data.withUnsafeBytes { (source: UnsafeRawBufferPointer) in
        guard let from = source.baseAddress else { return }
        for row in 0..<height {
          memcpy(
            base.advanced(by: row * rowLength),
            from.advanced(by: row * bytesPerRow),
            min(rowLength, bytesPerRow))
        }
      }
    }
    CVPixelBufferUnlockBaseAddress(pixels, [])

    let orientation: CGImagePropertyOrientation
    switch degrees {
    case 90: orientation = .right
    case 180: orientation = .down
    case 270: orientation = .left
    default: orientation = .up
    }

    let pose = VNDetectHumanBodyPoseRequest()
    let segmentation = VNGeneratePersonSegmentationRequest()
    segmentation.qualityLevel = .fast
    segmentation.outputPixelFormat = kCVPixelFormatType_OneComponent8
    var requests: [VNRequest] = [pose]
    if wantsMask { requests.append(segmentation) }

    let handler = VNImageRequestHandler(cvPixelBuffer: pixels, orientation: orientation, options: [:])
    do {
      try handler.perform(requests)
    } catch {
      return nil
    }

    var joints: [String: [Double]] = [:]
    if let observation = pose.results?.first,
      let points = try? observation.recognizedPoints(.all)
    {
      for (name, key) in Self.joints {
        guard let point = points[key], point.confidence > 0 else { continue }
        // Vision's origin is bottom left; Flutter's is top left.
        joints[name] = [
          Double(point.location.x), Double(1 - point.location.y), Double(point.confidence),
        ]
      }
    }
    var reply: [String: Any] = ["joints": joints]

    if wantsMask, let mask = segmentation.results?.first?.pixelBuffer {
      // Whether the upright frame is portrait: a frame turned a quarter is
      // portrait when it came in wider than tall.
      let turnedQuarter = degrees == 90 || degrees == 270
      let portrait = turnedQuarter ? width > height : height >= width
      if let turned = Self.bytes(of: mask, turning: degrees, upright: portrait) {
        reply["mask"] = FlutterStandardTypedData(bytes: turned.data)
        reply["maskWidth"] = turned.width
        reply["maskHeight"] = turned.height
      }
    }
    return reply
  }

  /// The mask's bytes, turned upright when Vision left it the way the
  /// frame came in ([upright] says whether the upright frame is portrait).
  private static func bytes(of mask: CVPixelBuffer, turning degrees: Int, upright portrait: Bool)
    -> (data: Data, width: Int, height: Int)?
  {
    CVPixelBufferLockBaseAddress(mask, .readOnly)
    defer { CVPixelBufferUnlockBaseAddress(mask, .readOnly) }
    guard let base = CVPixelBufferGetBaseAddress(mask) else { return nil }
    let width = CVPixelBufferGetWidth(mask)
    let height = CVPixelBufferGetHeight(mask)
    let rowLength = CVPixelBufferGetBytesPerRow(mask)
    let source = base.assumingMemoryBound(to: UInt8.self)

    let alreadyUpright = (height >= width) == portrait
    let turns = alreadyUpright ? 0 : degrees
    let outWidth = turns == 90 || turns == 270 ? height : width
    let outHeight = turns == 90 || turns == 270 ? width : height
    var out = [UInt8](repeating: 0, count: outWidth * outHeight)
    for y in 0..<height {
      for x in 0..<width {
        let value = source[y * rowLength + x]
        let ux: Int
        let uy: Int
        switch turns {
        case 90:
          ux = height - 1 - y
          uy = x
        case 180:
          ux = width - 1 - x
          uy = height - 1 - y
        case 270:
          ux = y
          uy = width - 1 - x
        default:
          ux = x
          uy = y
        }
        out[uy * outWidth + ux] = value
      }
    }
    return (data: Data(out), width: outWidth, height: outHeight)
  }
}
