import 'dart:math';

import 'package:flutter/cupertino.dart';

class CirularDottedBorder extends CustomPainter {
  CirularDottedBorder({
    required this.dots,
    this.spaceLength = 10,
  });
  final int dots;
  final int spaceLength;
  double startOfArcInDegree = 0;

  double inRads(double degree) {
    return (degree * pi) / 180;
  }

  @override
  bool shouldRepaint(CirularDottedBorder oldDelegate) {
    return true;
  }

  @override
  void paint(Canvas canvas, Size size) {
    var arcLength = (360 - (dots * spaceLength)) / dots;

    if (arcLength <= 0) {
      arcLength = 360 / spaceLength - 1;
    }

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);

    for (var i = 0; i < dots; i++) {
      canvas.drawArc(
        rect,
        inRads(startOfArcInDegree),
        inRads(arcLength),
        false,
        Paint()
          ..color = CupertinoColors.activeGreen
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke,
      );

      startOfArcInDegree += arcLength + spaceLength;
    }
  }
}
