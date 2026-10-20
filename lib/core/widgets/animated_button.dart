import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/theme.dart';
import 'package:pushup_bro/generated/assets.gen.dart';
import 'package:rive/rive.dart' as rive;

/// Holds the button on its `idle` pose and replays `active` on every tap.
///
/// `button.riv` ships two linear animations (`idle`, `active`) and no state
/// machine, so it cannot be driven by a `RiveWidgetController` — that one
/// throws `RiveStateMachineException` when the artboard has no default state
/// machine. The artboard also draws nothing on its own: the button's resting
/// look lives in `idle`, so that animation has to stay applied.
base class _ButtonPainter extends rive.BasicArtboardPainter {
  _ButtonPainter() : super(fit: rive.Fit.cover);

  rive.Animation? _idleAnimation;
  rive.Animation? _activeAnimation;
  bool _playingActive = false;

  @override
  void artboardChanged(rive.Artboard artboard) {
    super.artboardChanged(artboard);
    _idleAnimation = artboard.animationNamed('idle');
    _activeAnimation = artboard.animationNamed('active');
    notifyListeners();
  }

  /// Replays the press animation from its first frame.
  void replayActive() {
    final animation = _activeAnimation;
    if (animation == null) return;

    animation.time = 0;
    _playingActive = true;
    notifyListeners();
  }

  @override
  bool advance(double elapsedSeconds) {
    final active = _activeAnimation;
    if (_playingActive && active != null) {
      _playingActive = active.advanceAndApply(elapsedSeconds);

      // Keep ticking one more frame so the idle pose below is reapplied.
      return true;
    }

    final idle = _idleAnimation;
    if (idle == null) return super.advance(elapsedSeconds);

    return idle.advanceAndApply(elapsedSeconds);
  }

  @override
  void dispose() {
    _idleAnimation?.dispose();
    _idleAnimation = null;
    _activeAnimation?.dispose();
    _activeAnimation = null;
    super.dispose();
  }
}

class AnimatedButton extends StatefulWidget {
  const AnimatedButton({
    required this.text,
    super.key,
    this.icon,
    this.callback,
    this.isPressed,
  });
  final String text;
  final IconData? icon;
  final VoidCallback? callback;
  final bool? isPressed;

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with TickerProviderStateMixin {
  late AnimationController _riveController;
  late AnimationController _arrowAnimController;
  late Animation<Offset> _arrowAnimation;
  final _painter = _ButtonPainter();
  late final rive.FileLoader _fileLoader;
  late final Future<rive.File> _riveFile;

  @override
  void initState() {
    super.initState();
    _riveController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _arrowAnimController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _fileLoader = Assets.rive.button.riveFileLoader();
    _riveFile = _fileLoader.file();

    _arrowAnimation = Tween<Offset>(
      begin: const Offset(-4, 0),
      end: const Offset(4, 0),
    ).animate(
      CurvedAnimation(
        parent: _arrowAnimController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _arrowAnimController.dispose();
    _riveController.dispose();
    _painter.dispose();
    _fileLoader.dispose();
    super.dispose();
  }

  void _onTap() {
    _painter.replayActive();
    const springDesc = SpringDescription(mass: 0.1, stiffness: 40, damping: 5);
    final springAnim = SpringSimulation(springDesc, 0, 1, 0);
    _riveController.animateWith(springAnim);
    widget.callback?.call();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 240,
        height: 64,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [context.shadow],
          ),
          child: GestureDetector(
            onTap: _onTap,
            child: Stack(
              children: [
                FutureBuilder<rive.File>(
                  future: _riveFile,
                  builder: (context, snapshot) {
                    final file = snapshot.data;
                    if (file == null) return const SizedBox.shrink();

                    return rive.RiveFileWidget(file: file, painter: _painter);
                  },
                ),
                Center(
                  child: AnimatedBuilder(
                    animation: _arrowAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: (widget.isPressed ?? false)
                            ? Offset.zero
                            : _arrowAnimation.value,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Visibility(
                              visible: widget.icon != null,
                              child: Icon(widget.icon),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.text,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                            ),
                            const SizedBox(width: 20),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
