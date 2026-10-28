import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';

/// A comic speech bubble on the surface colour (white, or raised navy in
/// dark mode) with its tail pointing down, popping in with a little bounce.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble(
    this.text, {
    this.color,
    this.textColor,
    this.maxWidth = 240,
    super.key,
  });

  final String text;

  /// The bubble's fill; the surface colour by default.
  final Color? color;

  /// The text's colour; onSurface by default.
  final Color? textColor;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.colorScheme.surface;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 420),
      curve: Curves.elasticOut,
      builder: (context, t, child) => Transform.scale(
        scale: 0.4 + 0.6 * t,
        alignment: Alignment.bottomCenter,
        child: Opacity(opacity: t.clamp(0, 1), child: child),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(PBRadius.lg),
                boxShadow: context.cardShadow,
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: textColor ?? context.colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),
              ),
            ),
            CustomPaint(
              size: const Size(22, 12),
              painter: _TailPainter(color),
            ),
          ],
        ),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  _TailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TailPainter oldDelegate) => oldDelegate.color != color;
}
