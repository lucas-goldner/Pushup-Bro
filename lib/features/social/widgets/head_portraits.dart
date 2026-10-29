import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_scene/scene.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/scene/gorilla_rig.dart';
import 'package:pushup_bro/core/scene/scene_stage.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// The portraits' size on disk, in pixels.
const _kPixels = 256.0;

/// Frames to let a new look settle (meshes, materials, the idle pose)
/// before the picture is taken.
const _kSettleFrames = 8;

/// The idle animation is frozen where the head faces forward: its sway is
/// sin(0.55 t), so at a multiple of this.
const double _kFacingForward = math.pi / 0.55;

/// It blinks for 0.14 seconds every 3.4 seconds.
bool _eyesOpenAt(double time) {
  final phase = time % 3.4;
  return phase > 0.3 && phase < 3.2;
}

/// Bump to render every portrait again (after the rig or framing changes).
const _kVersion = 'v3';

/// 3D head portraits of bros: their gorilla (or lizard) head wearing their
/// fur, face, hat and glasses, rendered once per look by
/// [HeadPortraitStudio], kept in memory and on disk.
class HeadPortraits extends ChangeNotifier {
  HeadPortraits._();

  static final HeadPortraits instance = HeadPortraits._();

  final Map<String, ui.Image> _images = {};
  final List<MonkeyLook> _queue = [];
  final Set<String> _loading = {};

  static String keyOf(MonkeyLook look) =>
      [_kVersion, look.species, ...look.ids].join('_');

  /// The portrait for [look], or null while it's being made (it's asked for
  /// then, and listeners hear when it's there).
  ui.Image? of(MonkeyLook look) {
    final key = keyOf(look);
    final image = _images[key];
    if (image == null) unawaited(_request(look, key));
    return image;
  }

  /// The next look to render, if any.
  MonkeyLook? get next => _queue.firstOrNull;

  Future<void> _request(MonkeyLook look, String key) async {
    if (_loading.contains(key)) return;
    _loading.add(key);
    final saved = await _readFromDisk(key);
    if (saved != null) {
      _images[key] = saved;
      notifyListeners();
      return;
    }
    _queue.add(look);
    notifyListeners();
  }

  /// [HeadPortraitStudio] finished [look].
  void deliver(MonkeyLook look, ui.Image image) {
    final key = keyOf(look);
    _queue.removeWhere((queued) => keyOf(queued) == key);
    _images[key] = image;
    notifyListeners();
    unawaited(_writeToDisk(key, image));
  }

  /// [HeadPortraitStudio] couldn't render [look]; the drawn face stays.
  void skip(MonkeyLook look) {
    final key = keyOf(look);
    _queue.removeWhere((queued) => keyOf(queued) == key);
    notifyListeners();
  }

  static Future<File?> _file(String key) async {
    if (kIsWeb) return null;
    try {
      final dir = await getApplicationSupportDirectory();
      return File('${dir.path}/heads/$key.png');
    } on Object {
      return null;
    }
  }

  static Future<ui.Image?> _readFromDisk(String key) async {
    final file = await _file(key);
    if (file == null || !file.existsSync()) return null;
    try {
      final codec = await ui.instantiateImageCodec(await file.readAsBytes());
      return (await codec.getNextFrame()).image;
    } on Object {
      return null;
    }
  }

  static Future<void> _writeToDisk(String key, ui.Image image) async {
    final file = await _file(key);
    if (file == null) return;
    try {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) return;
      await file.parent.create(recursive: true);
      await file.writeAsBytes(png.buffer.asUint8List(), flush: true);
    } on Object catch (error) {
      debugPrint('Head portrait not saved: $error');
    }
  }
}

/// Renders the heads [HeadPortraits] asks for, one after another, in a
/// small 3D scene off screen. It only exists while there's work, so it
/// costs nothing the rest of the time. Put it once near the app's root.
class HeadPortraitStudio extends StatefulWidget {
  const HeadPortraitStudio({required this.child, super.key});

  final Widget child;

  @override
  State<HeadPortraitStudio> createState() => _HeadPortraitStudioState();
}

class _HeadPortraitStudioState extends State<HeadPortraitStudio> {
  final HeadPortraits _portraits = HeadPortraits.instance;

  @override
  void initState() {
    super.initState();
    _portraits.addListener(_changed);
  }

  @override
  void dispose() {
    _portraits.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final next = _portraits.next;

    return Stack(
      children: [
        widget.child,
        if (next != null)
          // Off screen: painted (so it can be captured) but never seen.
          Positioned(
            left: -_kPixels * 2,
            top: 0,
            width: _kPixels / 2,
            height: _kPixels / 2,
            child: IgnorePointer(child: _Studio(first: next)),
          ),
      ],
    );
  }
}

class _Studio extends StatefulWidget {
  const _Studio({required this.first});

  final MonkeyLook first;

  @override
  State<_Studio> createState() => _StudioState();
}

class _StudioState extends State<_Studio> {
  final GlobalKey _frame = GlobalKey();
  final GorillaRig _head = GorillaRig();
  MonkeyLook? _look;
  int _frames = 0;
  double _time = 0;
  bool _capturing = false;

  void _populate(Scene scene) {
    _dress(widget.first);
    scene
      ..directionalLight = DirectionalLight(
        direction: vm.Vector3(-0.35, -0.8, -0.9),
      )
      ..environmentSettings = EnvironmentSettings(exposure: 1.15)
      ..add(_head.root);
  }

  void _dress(MonkeyLook look) {
    _look = look;
    _frames = 0;
    _head
      ..look = look
      ..activity = GorillaActivity.idle
      ..settle();
    // Turned a little, like a profile picture.
    _head.root.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 1, 0), 0.28);
  }

  void _tick(double deltaSeconds) {
    // Time stands still at a moment the idle sway faces the camera and
    // the eyes are open.
    var step = 0.0;
    if (_frames == 0) {
      var at = (_time / _kFacingForward).floor() + 1;
      while (!_eyesOpenAt(at * _kFacingForward)) {
        at++;
      }
      step = at * _kFacingForward - _time;
      _time += step;
    }
    _head.update(step);
    final look = _look;
    if (look == null || _capturing || ++_frames < _kSettleFrames) return;
    _capturing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture(look));
  }

  Future<void> _capture(MonkeyLook look) async {
    final portraits = HeadPortraits.instance;
    final boundary =
        _frame.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    try {
      if (boundary == null) throw StateError('No frame');
      final image = await boundary.toImage(pixelRatio: 2);
      portraits.deliver(look, image);
    } on Object catch (error) {
      debugPrint('Head portrait failed: $error');
      portraits.skip(look);
    }
    final next = portraits.next;
    _capturing = false;
    if (next != null && mounted) _dress(next);
  }

  Camera _camera(Duration elapsed) {
    // The head and a hint of shoulders, with room for a tall hat.
    final target = vm.Vector3(0, 1, 0);
    return PerspectiveCamera(
      fovRadiansY: 30 * vm.degrees2Radians,
      position: target + vm.Vector3(0, 0.1, 2.45),
      target: target,
    );
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        key: _frame,
        child: SceneStage(
          populate: _populate,
          cameraBuilder: _camera,
          onTick: _tick,
        ),
      );
}
