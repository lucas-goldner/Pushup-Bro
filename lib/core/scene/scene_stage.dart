import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_scene/scene.dart';

/// How many full-size frames the scene draws before [SceneStage] calls
/// `onReady`, so the first frames (which can still be paced or held by the
/// engine) are on screen.
const _kReadyFrames = 3;

/// How far a drawn frame's shape may be from the stage's and still count as
/// full size (the engine can render below the screen's resolution).
const _kAspectTolerance = 0.02;

/// Hosts a flutter_scene [Scene] over a transparent background, so the
/// Flutter UI behind it shows through as the backdrop.
///
/// [populate] runs once the engine's static resources are ready (geometry and
/// materials may not be built before that); [onTick] runs every frame.
///
/// With [warmUp] the scene's shaders compile before its first frame, so it
/// never shows half drawn; [onReady] says when the whole scene is on screen,
/// for a loading screen to step aside. It carries the size the scene was
/// drawn at: a stage laid out short of the screen draws short full frames
/// too, so only the caller knows whether that size is the one it wanted.
class SceneStage extends StatefulWidget {
  const SceneStage({
    required this.populate,
    required this.cameraBuilder,
    this.onTick,
    this.warmUp = false,
    this.onReady,
    super.key,
  });

  final void Function(Scene scene) populate;
  final Camera Function(Duration elapsed) cameraBuilder;
  final void Function(double deltaSeconds)? onTick;
  final bool warmUp;
  final void Function(Size size)? onReady;

  @override
  State<SceneStage> createState() => _SceneStageState();
}

class _SceneStageState extends State<SceneStage> {
  final Scene _scene = Scene();
  bool _ready = false;
  int _frames = 0;

  /// The size the frames were counted at; counting starts over when the
  /// stage is laid out at another size.
  Size? _countedAt;

  @override
  void initState() {
    super.initState();
    unawaited(
      Scene.initializeStaticResources().then((_) {
        if (!mounted) return;
        widget.populate(_scene);
        setState(() => _ready = true);
      }),
    );
  }

  /// The scene view only ticks once it reveals the scene. A tick isn't a
  /// drawn frame though: warming up renders a 64×64 frame, and while
  /// materials still load the engine shows its last frame again, stretched
  /// over the whole view (a squashed clearing). Only frames drawn in the
  /// stage's own shape count.
  void _tick(double deltaSeconds) {
    widget.onTick?.call(deltaSeconds);
    final size = context.size;
    if (size != _countedAt) {
      // Laid out at another size (a route can be laid out short for a
      // moment): wait for full frames at the new size, then say so again.
      _countedAt = size;
      _frames = 0;
    }
    if (_frames >= _kReadyFrames || !_drewFullFrame()) return;
    if (++_frames != _kReadyFrames) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && size != null) widget.onReady?.call(size);
    });
  }

  bool _drewFullFrame() {
    final size = context.size;
    final last = _scene.surface.lastSwapchainColorTexture();
    if (size == null || size.isEmpty || last == null) return false;
    // Bigger than the warm-up frame, and shaped like the stage.
    if (last.width <= 64 && last.height <= 64) return false;
    final drawn = last.width / last.height;
    final stage = size.width / size.height;
    return (drawn - stage).abs() / stage < _kAspectTolerance;
  }

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        opacity: _ready ? 1 : 0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        child: _ready
            ? SceneView(
                _scene,
                cameraBuilder: widget.cameraBuilder,
                warmUp: widget.warmUp,
                onTick: (_, deltaSeconds) => _tick(deltaSeconds),
              )
            : const SizedBox.expand(),
      );
}
