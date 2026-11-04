import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/scene/gorilla_rig.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';

/// A floating camera window, like the self view in a video call: drag it
/// anywhere and let go, and it glides to the nearest corner. Like
/// picture in picture, flick it against the left or right edge (or tap its
/// hide button) and it tucks away there, leaving a tab; tap the tab or
/// drag it out to bring it back. It keeps counting while it's tucked away.
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

  /// How much of a tucked window still shows, as the tab to pull it back.
  static const _tab = 28.0;

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

  /// Tucked away at the left (-1) or right (1) edge; null when showing.
  int? _tucked;

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

  /// Where a window tucked at [side] sits: off screen but for the tab,
  /// at the height it was.
  Offset _tuckedOffset(int side) {
    final top = _safe.top + widget.topInset;
    final bottom =
        _area.height - widget.size.height - _safe.bottom - widget.bottomInset;
    final y = (_position ?? _cornerOffset(_corner))
        .dy
        .clamp(top, math.max(top, bottom));

    return Offset(
      side < 0 ? _tab - widget.size.width : _area.width - _tab,
      y.toDouble(),
    );
  }

  /// Tucks the window away at [side] (-1 left, 1 right).
  void _tuck(int side) {
    setState(() => _tucked = side);
    _glideTo(_tuckedOffset(side));
  }

  /// Brings a tucked window back, to the corner on its side.
  void _untuck() {
    final side = _tucked ?? 1;
    final position = _position ?? Offset.zero;
    _corner = Alignment(
      side.toDouble(),
      position.dy + widget.size.height / 2 < _area.height / 2 ? -1 : 1,
    );
    setState(() => _tucked = null);
    _glideTo(_cornerOffset(_corner));
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
    if (_tucked != null) {
      // Tucked away: the gorillas look ahead again.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) CameraWindow.focus.value = null;
      });
      return;
    }
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
    // It may go most of the way off the side, to be tucked away there.
    _place(
      Offset(
        position.dx.clamp(
          _tab - widget.size.width,
          _area.width - _tab,
        ),
        position.dy.clamp(0, _area.height - widget.size.height),
      ),
    );
  }

  void _onDragEnd(DragEndDetails details) {
    // Throwing it counts: aim from where it's heading, not where it is.
    final heading = (_position ?? Offset.zero) +
        details.velocity.pixelsPerSecond * 0.12 +
        widget.size.center(Offset.zero);
    // Past an edge (or flung at one): tucked away there. A tucked window
    // dragged back in comes back.
    final inset = widget.size.width * 0.15;
    if (heading.dx < inset) return _tuck(-1);
    if (heading.dx > _area.width - inset) return _tuck(1);
    _tucked = null;
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
            final tucked = _tucked;
            _position =
                tucked == null ? _cornerOffset(_corner) : _tuckedOffset(tucked);
            _publish();
          }
        }
        final position = _position ?? _cornerOffset(_corner);
        final tucked = _tucked;

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
                onTap: tucked == null ? null : _untuck,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Still counting while tucked away, just dimmed.
                    AnimatedOpacity(
                      opacity: tucked == null ? 1 : 0.35,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: tucked != null,
                        child: widget.child,
                      ),
                    ),
                    if (tucked == null)
                      Positioned(
                        // Centred on the frame's corner arc, so the glass
                        // keeps the same gap all along the rounded corner.
                        right: _HideButton.inset,
                        top: _HideButton.inset,
                        child: _HideButton(
                          // Towards the edge it's nearest.
                          side: _corner.x < 0 ? -1 : 1,
                          onTap: () => _tuck(_corner.x < 0 ? -1 : 1),
                        ),
                      )
                    else
                      Positioned(
                        top: 0,
                        bottom: 0,
                        width: _tab,
                        left: tucked < 0 ? widget.size.width - _tab : 0,
                        child: _Tab(side: tucked),
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The small frosted button in the window's top right corner that tucks
/// it away at [side]. Its touch area is bigger than the glass it shows.
class _HideButton extends StatelessWidget {
  const _HideButton({required this.side, required this.onTap});

  final int side;
  final VoidCallback onTap;

  static const _size = 30.0;
  static const _touch = 4.0;

  /// The camera frame's corner arc is centred this far in from the
  /// window's outer edge: its 4 pt border plus its inner radius.
  static const double _arcCentre = 4 + PBRadius.lg - 2;

  /// How far in from the window's edges the button goes so it is
  /// concentric with the rounded corner.
  static const double inset = _arcCentre - _size / 2 - _touch;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: context.l10n.cameraHide,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(_touch),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: _size,
                    height: _size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.42),
                          Colors.white.withValues(alpha: 0.22),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Icon(
                      side < 0
                          ? CarbonIcons.chevron_left
                          : CarbonIcons.chevron_right,
                      size: 18,
                      color: Colors.white,
                      shadows: const [
                        Shadow(color: Color(0x40000000), blurRadius: 3),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

/// What shows of a tucked window: a tab with an arrow pointing back in.
class _Tab extends StatelessWidget {
  const _Tab({required this.side});

  final int side;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: context.l10n.cameraShow,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colorScheme.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.horizontal(
              left: side > 0 ? const Radius.circular(14) : Radius.zero,
              right: side < 0 ? const Radius.circular(14) : Radius.zero,
            ),
            boxShadow: context.cardShadow,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CarbonIcons.video,
                  size: 16,
                  color: context.colorScheme.onSurface,
                ),
                const SizedBox(height: 6),
                Icon(
                  side < 0
                      ? CarbonIcons.chevron_right
                      : CarbonIcons.chevron_left,
                  size: 16,
                  color: context.colorScheme.onSurface,
                ),
              ],
            ),
          ),
        ),
      );
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
