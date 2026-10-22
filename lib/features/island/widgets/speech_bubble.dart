import 'package:flutter/material.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';
import 'package:pushup_bro/core/style/pb_text_styles.dart';

/// A white comic speech bubble with its tail pointing down, popping in with
/// a little bounce.
class SpeechBubble extends StatelessWidget {
  const SpeechBubble(
    this.text, {
    this.color = Colors.white,
    this.textColor = background2,
    this.maxWidth = 240,
    super.key,
  });

  final String text;
  final Color color;
  final Color textColor;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
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
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: background2.withValues(alpha: 0.18),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: defaultTextStyle.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
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
