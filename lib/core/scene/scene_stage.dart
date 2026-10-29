import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_scene/scene.dart';

/// How many frames the scene draws after warming up before [SceneStage]
/// calls `onReady`, so the first frames (which can still be paced or held
/// by the engine) are on screen at full size.
const _kReadyFrames = 3;

/// Hosts a flutter_scene [Scene] over a transparent background, so the
/// Flutter UI behind it shows through as the backdrop.
///
/// [populate] runs once the engine's static resources are ready (geometry and
/// materials may not be built before that); [onTick] runs every frame.
///
/// With [warmUp] the scene's shaders compile before its first frame, so it
/// never shows half drawn; [onReady] says when the whole scene is on screen,
/// for a loading screen to step aside.
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
  final VoidCallback? onReady;

  @override
  State<SceneStage> createState() => _SceneStageState();
}

class _SceneStageState extends State<SceneStage> {
  final Scene _scene = Scene();
  bool _ready = false;
  int _frames = 0;

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

  /// The scene view only ticks once it reveals the scene, so counting ticks
  /// counts drawn frames.
  void _tick(double deltaSeconds) {
    widget.onTick?.call(deltaSeconds);
    if (++_frames != _kReadyFrames) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onReady?.call();
    });
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
