import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Encodes share videos and opens the share sheet through the
/// `pushup_bro/recap_video` channel (`RecapVideo` in
/// ios/Runner/AppDelegate.swift, AVFoundation and UIActivityViewController).
class RecapVideo {
  const RecapVideo({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('pushup_bro/recap_video');

  final MethodChannel _channel;

  /// Videos are made on iOS only; elsewhere a picture is shared.
  static bool get canEncode =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Starts a video of [width] × [height] at [fps] into [path].
  Future<void> start({
    required String path,
    required int width,
    required int height,
    required int fps,
  }) =>
      _channel.invokeMethod<void>('start', {
        'path': path,
        'width': width,
        'height': height,
        'fps': fps,
      });

  /// Adds the next frame as raw RGBA bytes.
  Future<void> addFrame(Uint8List rgba) =>
      _channel.invokeMethod<void>('frame', rgba);

  /// Finishes the video and mixes in [cues] (seconds and a sound file
  /// each). Returns the finished file's path.
  Future<String> finish({List<(double, String)> cues = const []}) async {
    final path = await _channel.invokeMethod<String>('finish', {
      'cues': [
        for (final (time, file) in cues) {'time': time, 'path': file},
      ],
    });
    if (path == null) throw StateError('The video has no file.');
    return path;
  }

  /// Stops a video halfway and deletes what was written.
  Future<void> cancel() => _channel.invokeMethod<void>('cancel');

  /// Opens the share sheet with [file] and [text].
  Future<void> share({required String file, required String text}) async {
    if (!canEncode) return;
    await _channel.invokeMethod<void>('share', {'path': file, 'text': text});
  }

  /// Writes an asset (like a sound) to a temporary file the native side
  /// can read, once.
  static Future<String> assetToFile(String asset, Directory dir) async {
    final file = File('${dir.path}/${asset.split('/').last}');
    if (!file.existsSync()) {
      final data = await rootBundle.load(asset);
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
    }
    return file.path;
  }
}
