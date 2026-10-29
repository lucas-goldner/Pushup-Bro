import AVFoundation
import Accelerate
import Flutter
import StoreKit
import UIKit
import UserNotifications
import Vision
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var appIconSwitcher: AppIconSwitcher?
  private var widgetBridge: WidgetBridge?
  private var poseVision: PoseVision?
  private var storeReview: StoreReview?
  private var recapVideo: RecapVideo?
  private var qrScanner: QrScanner?
  private var screenBrightness: ScreenBrightness?

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
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "StoreReview") {
      storeReview = StoreReview(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "RecapVideo") {
      recapVideo = RecapVideo(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "QrScanner") {
      qrScanner = QrScanner(messenger: registrar.messenger())
    }
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "ScreenBrightness") {
      screenBrightness = ScreenBrightness(messenger: registrar.messenger())
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
        WidgetCenter.shared.reloadAllTimelines()
      }
      result(nil)
    }
  }
}

/// Shows the App Store rating prompt (lib/core/platform/store_review.dart).
/// iOS decides whether it really appears.
final class StoreReview {
  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "pushup_bro/review", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "request" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let scene = UIApplication.shared.connectedScenes
        .first { $0.activationState == .foregroundActive } as? UIWindowScene
      if let scene = scene {
        AppStore.requestReview(in: scene)
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

/// Makes the share videos (lib/features/share/): Flutter sends each frame as
/// RGBA bytes, AVAssetWriter encodes them as H.264, and the sound cues are
/// mixed in with AVMutableComposition. Also opens the share sheet.
final class RecapVideo {
  private let channel: FlutterMethodChannel
  private var writer: AVAssetWriter?
  private var input: AVAssetWriterInput?
  private var adaptor: AVAssetWriterInputPixelBufferAdaptor?
  private var url: URL?
  private var size = CGSize.zero
  private var fps: Int32 = 24
  private var frame: Int64 = 0

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "pushup_bro/recap_video", binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { return }
      switch call.method {
      case "start":
        self.start(call.arguments as? [String: Any], result: result)
      case "frame":
        self.append(call.arguments as? FlutterStandardTypedData, result: result)
      case "finish":
        self.finish(call.arguments as? [String: Any], result: result)
      case "cancel":
        self.reset(delete: true)
        result(nil)
      case "share":
        self.share(call.arguments as? [String: Any], result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private func start(_ args: [String: Any]?, result: FlutterResult) {
    guard let args = args, let path = args["path"] as? String,
      let width = args["width"] as? Int, let height = args["height"] as? Int,
      let fps = args["fps"] as? Int
    else {
      result(FlutterError(code: "recap", message: "Missing arguments", details: nil))
      return
    }
    reset(delete: false)
    let url = URL(fileURLWithPath: path)
    try? FileManager.default.removeItem(at: url)
    do {
      let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
      let input = AVAssetWriterInput(
        mediaType: .video,
        outputSettings: [
          AVVideoCodecKey: AVVideoCodecType.h264,
          AVVideoWidthKey: width,
          AVVideoHeightKey: height,
          AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 6_000_000],
        ])
      input.expectsMediaDataInRealTime = false
      let adaptor = AVAssetWriterInputPixelBufferAdaptor(
        assetWriterInput: input,
        sourcePixelBufferAttributes: [
          kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
          kCVPixelBufferWidthKey as String: width,
          kCVPixelBufferHeightKey as String: height,
        ])
      writer.add(input)
      guard writer.startWriting() else {
        throw writer.error ?? NSError(domain: "recap", code: 1)
      }
      writer.startSession(atSourceTime: .zero)
      self.writer = writer
      self.input = input
      self.adaptor = adaptor
      self.url = url
      self.size = CGSize(width: width, height: height)
      self.fps = Int32(fps)
      self.frame = 0
      result(nil)
    } catch {
      result(FlutterError(code: "recap", message: error.localizedDescription, details: nil))
    }
  }

  private func append(_ data: FlutterStandardTypedData?, result: FlutterResult) {
    guard let data = data, let input = input, let adaptor = adaptor,
      let pool = adaptor.pixelBufferPool
    else {
      result(FlutterError(code: "recap", message: "Not started", details: nil))
      return
    }
    while !input.isReadyForMoreMediaData {
      Thread.sleep(forTimeInterval: 0.005)
    }
    var buffer: CVPixelBuffer?
    CVPixelBufferPoolCreatePixelBuffer(nil, pool, &buffer)
    guard let pixels = buffer else {
      result(FlutterError(code: "recap", message: "No pixel buffer", details: nil))
      return
    }
    let width = Int(size.width)
    let height = Int(size.height)
    CVPixelBufferLockBaseAddress(pixels, [])
    data.data.withUnsafeBytes { raw in
      guard let source = raw.baseAddress else { return }
      var from = vImage_Buffer(
        data: UnsafeMutableRawPointer(mutating: source), height: vImagePixelCount(height),
        width: vImagePixelCount(width), rowBytes: width * 4)
      var to = vImage_Buffer(
        data: CVPixelBufferGetBaseAddress(pixels), height: vImagePixelCount(height),
        width: vImagePixelCount(width), rowBytes: CVPixelBufferGetBytesPerRow(pixels))
      // RGBA from Flutter to the BGRA the encoder takes.
      let map: [UInt8] = [2, 1, 0, 3]
      _ = vImagePermuteChannels_ARGB8888(&from, &to, map, vImage_Flags(kvImageNoFlags))
    }
    CVPixelBufferUnlockBaseAddress(pixels, [])
    let time = CMTime(value: frame, timescale: fps)
    if adaptor.append(pixels, withPresentationTime: time) {
      frame += 1
      result(nil)
    } else {
      result(
        FlutterError(
          code: "recap", message: writer?.error?.localizedDescription ?? "Append failed",
          details: nil))
    }
  }

  private func finish(_ args: [String: Any]?, result: @escaping FlutterResult) {
    guard let writer = writer, let input = input, let url = url else {
      result(FlutterError(code: "recap", message: "Not started", details: nil))
      return
    }
    let cues = (args?["cues"] as? [[String: Any]]) ?? []
    let duration = CMTime(value: frame, timescale: fps)
    input.markAsFinished()
    writer.endSession(atSourceTime: duration)
    writer.finishWriting { [weak self] in
      guard let self = self else { return }
      self.writer = nil
      self.input = nil
      self.adaptor = nil
      guard writer.status == .completed else {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "recap", message: writer.error?.localizedDescription ?? "Writing failed",
              details: nil))
        }
        return
      }
      self.mix(video: url, cues: cues, duration: duration) { output in
        DispatchQueue.main.async { result(output.path) }
      }
    }
  }

  /// Puts each sound at its time over the video. Falls back to the silent
  /// video when anything goes wrong.
  private func mix(
    video: URL, cues: [[String: Any]], duration: CMTime, done: @escaping (URL) -> Void
  ) {
    let asset = AVURLAsset(url: video)
    guard !cues.isEmpty, let videoTrack = asset.tracks(withMediaType: .video).first else {
      done(video)
      return
    }
    let composition = AVMutableComposition()
    let range = CMTimeRange(start: .zero, duration: duration)
    guard
      let track = composition.addMutableTrack(
        withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid),
      (try? track.insertTimeRange(range, of: videoTrack, at: .zero)) != nil
    else {
      done(video)
      return
    }
    for cue in cues {
      guard let path = cue["path"] as? String, let time = cue["time"] as? Double else {
        continue
      }
      let sound = AVURLAsset(url: URL(fileURLWithPath: path))
      guard let soundTrack = sound.tracks(withMediaType: .audio).first,
        let audio = composition.addMutableTrack(
          withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
      else { continue }
      let at = CMTime(seconds: time, preferredTimescale: 600)
      let length = CMTimeMinimum(sound.duration, CMTimeSubtract(duration, at))
      guard CMTimeCompare(length, .zero) > 0 else { continue }
      try? audio.insertTimeRange(
        CMTimeRange(start: .zero, duration: length), of: soundTrack, at: at)
    }
    let output = video.deletingPathExtension().appendingPathExtension("final.mp4")
    try? FileManager.default.removeItem(at: output)
    guard
      let export = AVAssetExportSession(
        asset: composition, presetName: AVAssetExportPresetHighestQuality)
    else {
      done(video)
      return
    }
    export.outputURL = output
    export.outputFileType = .mp4
    export.exportAsynchronously {
      done(export.status == .completed ? output : video)
    }
  }

  private func reset(delete: Bool) {
    input?.markAsFinished()
    writer?.cancelWriting()
    if delete, let url = url { try? FileManager.default.removeItem(at: url) }
    writer = nil
    input = nil
    adaptor = nil
    frame = 0
  }

  private func share(_ args: [String: Any]?, result: @escaping FlutterResult) {
    guard let path = args?["path"] as? String else {
      result(FlutterError(code: "recap", message: "No file", details: nil))
      return
    }
    var items: [Any] = [URL(fileURLWithPath: path)]
    if let text = args?["text"] as? String { items.append(text) }
    let scene = UIApplication.shared.connectedScenes
      .first { $0.activationState == .foregroundActive } as? UIWindowScene
    guard var top = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
      result(FlutterError(code: "recap", message: "No window", details: nil))
      return
    }
    while let presented = top.presentedViewController { top = presented }
    let sheet = UIActivityViewController(activityItems: items, applicationActivities: nil)
    if let popover = sheet.popoverPresentationController {
      popover.sourceView = top.view
      popover.sourceRect = CGRect(
        x: top.view.bounds.midX, y: top.view.bounds.midY, width: 0, height: 0)
      popover.permittedArrowDirections = []
    }
    sheet.completionWithItemsHandler = { _, _, _, _ in result(nil) }
    top.present(sheet, animated: true)
  }
}

/// The topmost view controller, to present native screens over Flutter.
private func topViewController() -> UIViewController? {
  let scene = UIApplication.shared.connectedScenes
    .first { $0.activationState == .foregroundActive } as? UIWindowScene
  var top = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
  while let presented = top?.presentedViewController { top = presented }
  return top
}

/// Scans a friend's QR code for lib/features/social/data/qr_scanner.dart:
/// AVFoundation's metadata output reads QR codes natively (no ML Kit).
/// Returns the code's text, or nil when cancelled or there's no camera.
final class QrScanner {
  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "pushup_bro/qr_scanner", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "scan" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let args = call.arguments as? [String: Any]
      QrScanner.present(
        title: args?["title"] as? String ?? "",
        cancel: args?["cancel"] as? String ?? "Cancel",
        result: result
      )
    }
  }

  private static func present(title: String, cancel: String, result: @escaping FlutterResult) {
    let start = {
      guard let top = topViewController() else {
        result(nil)
        return
      }
      let scanner = QrScannerViewController(title: title, cancel: cancel) { code in
        result(code)
      }
      scanner.modalPresentationStyle = .fullScreen
      top.present(scanner, animated: true)
    }
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      start()
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { granted in
        DispatchQueue.main.async { granted ? start() : result(nil) }
      }
    default:
      result(nil)
    }
  }
}

final class QrScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
  private let session = AVCaptureSession()
  private let sessionQueue = DispatchQueue(label: "pushup_bro.qr")
  private let titleText: String
  private let cancelText: String
  private var finish: ((String?) -> Void)?

  init(title: String, cancel: String, finish: @escaping (String?) -> Void) {
    titleText = title
    cancelText = cancel
    self.finish = finish
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) { fatalError("init(coder:) is not used") }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .black
    guard
      let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
      let input = try? AVCaptureDeviceInput(device: camera),
      session.canAddInput(input)
    else {
      close(with: nil)
      return
    }
    session.addInput(input)
    let output = AVCaptureMetadataOutput()
    guard session.canAddOutput(output) else {
      close(with: nil)
      return
    }
    session.addOutput(output)
    output.setMetadataObjectsDelegate(self, queue: .main)
    output.metadataObjectTypes = [.qr]

    let preview = AVCaptureVideoPreviewLayer(session: session)
    preview.videoGravity = .resizeAspectFill
    preview.frame = view.bounds
    view.layer.addSublayer(preview)

    // A rounded frame to aim with, the title above and Cancel below.
    let frame = UIView()
    frame.layer.borderColor = UIColor.white.cgColor
    frame.layer.borderWidth = 4
    frame.layer.cornerRadius = 28
    frame.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(frame)

    let label = UILabel()
    label.text = titleText
    label.textColor = .white
    label.font = .systemFont(ofSize: 20, weight: .bold)
    label.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(label)

    var config = UIButton.Configuration.filled()
    config.title = cancelText
    config.baseBackgroundColor = .white
    config.baseForegroundColor = .black
    config.cornerStyle = .capsule
    config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 32, bottom: 14, trailing: 32)
    let button = UIButton(configuration: config)
    button.addAction(UIAction { [weak self] _ in self?.close(with: nil) }, for: .touchUpInside)
    button.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(button)

    NSLayoutConstraint.activate([
      frame.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      frame.centerYAnchor.constraint(equalTo: view.centerYAnchor),
      frame.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.7),
      frame.heightAnchor.constraint(equalTo: frame.widthAnchor),
      label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      label.bottomAnchor.constraint(equalTo: frame.topAnchor, constant: -28),
      button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
      button.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
    ])
    sessionQueue.async { [session] in session.startRunning() }
  }

  func metadataOutput(
    _ output: AVCaptureMetadataOutput,
    didOutput metadataObjects: [AVMetadataObject],
    from connection: AVCaptureConnection
  ) {
    guard
      let code = metadataObjects.compactMap({ $0 as? AVMetadataMachineReadableCodeObject }).first,
      let text = code.stringValue
    else { return }
    UINotificationFeedbackGenerator().notificationOccurred(.success)
    close(with: text)
  }

  private func close(with code: String?) {
    guard let finish = finish else { return }
    self.finish = nil
    sessionQueue.async { [session] in session.stopRunning() }
    if presentingViewController != nil {
      dismiss(animated: true) { finish(code) }
    } else {
      finish(code)
    }
  }
}

/// Full brightness while a QR code is shown, for
/// lib/features/social/data/screen_brightness.dart.
final class ScreenBrightness {
  private let channel: FlutterMethodChannel

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "pushup_bro/brightness", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "raise":
        let previous = UIScreen.main.brightness
        UIScreen.main.brightness = 1
        result(Double(previous))
      case "restore":
        if let level = call.arguments as? Double {
          UIScreen.main.brightness = CGFloat(level)
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}

