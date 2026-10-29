import 'package:flutter/widgets.dart';

/// The X logo, drawn in the [IconTheme]'s colour and size: a bold stroke
/// from top left to bottom right, crossed by a thin one.
class XLogo extends StatelessWidget {
  const XLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final size = theme.size ?? 24;

    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _XPainter(theme.color ?? const Color(0xFF000000)),
      ),
    );
  }
}

class _XPainter extends CustomPainter {
  const _XPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..color = color;
    // The bold stroke: an outlined band with a slot cut through it.
    canvas
      ..drawPath(
        Path()
          ..moveTo(w * 0.06, h * 0.1)
          ..lineTo(w * 0.36, h * 0.1)
          ..lineTo(w * 0.94, h * 0.9)
          ..lineTo(w * 0.64, h * 0.9)
          ..close(),
        paint,
      )
      ..drawPath(
        Path()
          ..moveTo(w * 0.2, h * 0.17)
          ..lineTo(w * 0.32, h * 0.17)
          ..lineTo(w * 0.8, h * 0.83)
          ..lineTo(w * 0.68, h * 0.83)
          ..close(),
        Paint()
          ..color = color
          ..blendMode = BlendMode.clear,
      )
      // The thin stroke, bottom left to top right.
      ..drawLine(
        Offset(w * 0.12, h * 0.9),
        Offset(w * 0.86, h * 0.1),
        paint
          ..strokeWidth = w * 0.09
          ..strokeCap = StrokeCap.butt,
      );
  }

  @override
  bool shouldRepaint(_XPainter oldDelegate) => color != oldDelegate.color;
}
