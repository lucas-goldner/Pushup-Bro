import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_scene/scene.dart';

/// Hosts a flutter_scene [Scene] over a transparent background, so the
/// Flutter UI behind it shows through as the backdrop.
///
/// [populate] runs once the engine's static resources are ready (geometry and
/// materials may not be built before that); [onTick] runs every frame.
class SceneStage extends StatefulWidget {
  const SceneStage({
    required this.populate,
    required this.cameraBuilder,
    this.onTick,
    super.key,
  });

  final void Function(Scene scene) populate;
  final Camera Function(Duration elapsed) cameraBuilder;
  final void Function(double deltaSeconds)? onTick;

  @override
  State<SceneStage> createState() => _SceneStageState();
}

class _SceneStageState extends State<SceneStage> {
  final Scene _scene = Scene();
  bool _ready = false;

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

  @override
  Widget build(BuildContext context) => AnimatedOpacity(
        opacity: _ready ? 1 : 0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        child: _ready
            ? SceneView(
                _scene,
                cameraBuilder: widget.cameraBuilder,
                onTick: (_, deltaSeconds) => widget.onTick?.call(deltaSeconds),
              )
            : const SizedBox.expand(),
      );
}
