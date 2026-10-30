import 'package:flutter/widgets.dart';

/// The X logo, drawn in the [IconTheme]'s colour and size: an outlined
/// stroke from top left to bottom right, crossed by a thin one.
class XLogo extends StatelessWidget {
  const XLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final size = theme.size ?? 24;

    // Centred like an Icon, so a tile that stretches it keeps it small.
    return Center(
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _XPainter(theme.color ?? const Color(0xFF000000)),
        ),
      ),
    );
  }
}

class _XPainter extends CustomPainter {
  const _XPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn inside a 12% margin, like the icon font's glyphs.
    Offset at(double x, double y) => Offset(
          size.width * (0.12 + x * 0.76),
          size.height * (0.12 + y * 0.76),
        );
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.miter
      ..strokeWidth = size.width * 0.075;
    canvas
      // The bold stroke, drawn as an outline.
      ..drawPath(
        Path()
          ..moveTo(at(0, 0).dx, at(0, 0).dy)
          ..lineTo(at(0.3, 0).dx, at(0.3, 0).dy)
          ..lineTo(at(1, 1).dx, at(1, 1).dy)
          ..lineTo(at(0.7, 1).dx, at(0.7, 1).dy)
          ..close(),
        line,
      )
      // The thin stroke, bottom left to top right.
      ..drawLine(at(0.04, 1), at(0.94, 0), line);
  }

  @override
  bool shouldRepaint(_XPainter oldDelegate) => color != oldDelegate.color;
}
