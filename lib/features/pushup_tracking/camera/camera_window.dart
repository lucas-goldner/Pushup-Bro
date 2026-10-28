import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/scene/gorilla_rig.dart';

/// A floating camera window, like the self view in a video call: drag it
/// anywhere and let go, and it glides to the nearest corner.
///
/// Fills its parent [Stack] (put it in `Positioned.fill`) but only takes
/// touches on the window itself. While it's on screen, [focus] holds the
/// window's centre as a fraction of the screen, so the 3D scenes can make
/// the gorillas look at it (see [aimGorillasAtCameraWindow]).
class CameraWindow extends StatefulWidget {
  const CameraWindow({
    required this.child,
    this.size = const Size(120, 160),
    this.corner = Alignment.bottomRight,
    this.topInset = 0,
    this.bottomInset = 0,
    super.key,
  });

  final Widget child;
  final Size size;

  /// Where it starts (one of the four corners). A change moves it there,
  /// until the user has moved it themselves.
  final Alignment corner;

  /// Room to keep free above and below it, on top of the safe area (for a
  /// close button or a bottom bar).
  final double topInset;
  final double bottomInset;

  /// The open camera window's centre, in fractions of the screen (0 to 1);
  /// null while none is on screen.
  static final ValueNotifier<Offset?> focus = ValueNotifier(null);

  @override
  State<CameraWindow> createState() => _CameraWindowState();
}

class _CameraWindowState extends State<CameraWindow>
    with SingleTickerProviderStateMixin {
  static const _margin = 16.0;

  late final AnimationController _glide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..addListener(_onGlide);

  /// The window's top left corner; null until the first layout.
  Offset? _position;
  Offset _from = Offset.zero;
  Offset _to = Offset.zero;
  Alignment _corner = Alignment.bottomRight;
  bool _moved = false;
  Size _area = Size.zero;
  EdgeInsets _safe = EdgeInsets.zero;

  @override
  void initState() {
    super.initState();
    _corner = widget.corner;
  }

  @override
  void didUpdateWidget(CameraWindow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.corner != oldWidget.corner && !_moved) {
      _corner = widget.corner;
      _glideTo(_cornerOffset(_corner));
    }
  }

  @override
  void dispose() {
    _glide.dispose();
    CameraWindow.focus.value = null;
    GorillaRig.lookTarget = null;
    super.dispose();
  }

  Offset _cornerOffset(Alignment corner) {
    final left = _margin + _safe.left;
    final right = _area.width - widget.size.width - _margin - _safe.right;
    final top = _safe.top + widget.topInset + _margin;
    final bottom = _area.height -
        widget.size.height -
        _safe.bottom -
        widget.bottomInset -
        _margin;

    return Offset(
      corner.x < 0 ? left : right,
      corner.y < 0 ? top : math.max(top, bottom),
    );
  }

  void _glideTo(Offset target) {
    _from = _position ?? target;
    _to = target;
    _glide.forward(from: 0);
  }

  void _onGlide() {
    final t = Curves.easeOutBack.transform(_glide.value);
    _place(Offset.lerp(_from, _to, t)!);
  }

  void _place(Offset position) {
    setState(() => _position = position);
    _publish();
  }

  void _publish() {
    final position = _position;
    if (position == null || _area.isEmpty) return;
    final centre = position + widget.size.center(Offset.zero);
    // Set after the frame: this may run during layout.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      CameraWindow.focus.value =
          Offset(centre.dx / _area.width, centre.dy / _area.height);
    });
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _glide.stop();
    _moved = true;
    final position = (_position ?? Offset.zero) + details.delta;
    _place(
      Offset(
        position.dx.clamp(0, _area.width - widget.size.width),
        position.dy.clamp(0, _area.height - widget.size.height),
      ),
    );
  }

  void _onDragEnd(DragEndDetails details) {
    // Throwing it counts: aim from where it's heading, not where it is.
    final heading = (_position ?? Offset.zero) +
        details.velocity.pixelsPerSecond * 0.12 +
        widget.size.center(Offset.zero);
    _corner = Alignment(
      heading.dx < _area.width / 2 ? -1 : 1,
      heading.dy < _area.height / 2 ? -1 : 1,
    );
    _glideTo(_cornerOffset(_corner));
  }

  @override
  Widget build(BuildContext context) {
    _safe = MediaQuery.paddingOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final area = constraints.biggest;
        if (area != _area) {
          _area = area;
          if (!_glide.isAnimating) {
            _position = _cornerOffset(_corner);
            _publish();
          }
        }
        final position = _position ?? _cornerOffset(_corner);

        return Stack(
          children: [
            Positioned(
              left: position.dx,
              top: position.dy,
              width: widget.size.width,
              height: widget.size.height,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanUpdate: _onDragUpdate,
                onPanEnd: _onDragEnd,
                child: widget.child,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Points every gorilla at the camera window (or lets them look away when
/// there's none): a spot just in front of [camera], in the window's
/// direction, as seen in a view of [viewSize].
void aimGorillasAtCameraWindow(Camera? camera, Size viewSize) {
  final focus = CameraWindow.focus.value;
  if (focus == null || camera is! PerspectiveCamera || viewSize.isEmpty) {
    GorillaRig.lookTarget = null;
    return;
  }
  final forward = (camera.target - camera.position).normalized();
  final right = forward.cross(camera.up).normalized();
  final up = right.cross(forward);
  final tanHalf = math.tan(camera.fovRadiansY / 2);
  final aspect = viewSize.width / viewSize.height;
  final ray = forward +
      right * ((focus.dx * 2 - 1) * tanHalf * aspect) +
      up * ((1 - focus.dy * 2) * tanHalf);
  GorillaRig.lookTarget = camera.position + ray.normalized() * 1.5;
}
