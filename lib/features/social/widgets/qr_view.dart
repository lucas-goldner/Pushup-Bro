import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:qr/qr.dart';

/// The modules of a QR code, with error correction H so a logo can cover
/// the middle: the code still reads with up to 30% of it missing.
class QrGrid {
  /// [data] as a grid; [hole] modules square in the middle are left clear
  /// for a logo (odd, so it stays centred).
  factory QrGrid(String data, {int hole = 0}) {
    final image = QrImage(
      QrCode(
        payload: QrPayload.fromString(data),
        errorCorrectLevel: QrErrorCorrectLevel.high,
      ),
    );
    final count = image.moduleCount;
    return QrGrid._(
      count,
      [
        for (var row = 0; row < count; row++)
          for (var col = 0; col < count; col++) image.isDark(row, col),
      ],
      hole,
    );
  }
  QrGrid._(this.count, this._dark, this.hole);

  /// Modules per side.
  final int count;
  final List<bool> _dark;

  /// The logo hole, in modules per side.
  final int hole;

  /// Whether the module at [row], [col] is dark (finders and the logo hole
  /// included as they are in the code).
  bool isDark(int row, int col) => _dark[row * count + col];

  /// Whether [row], [col] is in one of the three 7×7 finder squares.
  bool isFinder(int row, int col) {
    bool near(int i) => i < 7;
    bool far(int i) => i >= count - 7;
    return (near(row) && near(col)) ||
        (near(row) && far(col)) ||
        (far(row) && near(col));
  }

  /// Whether [row], [col] is under the logo.
  bool inHole(int row, int col) {
    if (hole <= 0) return false;
    final start = (count - hole) ~/ 2;
    return row >= start &&
        row < start + hole &&
        col >= start &&
        col < start + hole;
  }

  /// The share of data modules the logo covers; error correction H
  /// recovers up to 30%.
  double get holeShare => hole * hole / (count * count);
}

/// Draws a [QrGrid]: rounded modules, rounded finder squares with
/// coloured centres, and a clear middle for a logo.
class QrPainter extends CustomPainter {
  const QrPainter(
    this.grid, {
    required this.dark,
    required this.accent,
    this.finders = 1,
  });

  final QrGrid grid;
  final Color dark;

  /// The finder squares' centres.
  final Color accent;

  /// How far each finder has popped in, 0 to 1 (all three at once).
  final double finders;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.shortestSide / grid.count;
    final paint = Paint()..color = dark;
    for (var row = 0; row < grid.count; row++) {
      for (var col = 0; col < grid.count; col++) {
        if (!grid.isDark(row, col) ||
            grid.isFinder(row, col) ||
            grid.inHole(row, col)) {
          continue;
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(col * cell, row * cell, cell, cell).deflate(
              cell * 0.06,
            ),
            Radius.circular(cell * 0.35),
          ),
          paint,
        );
      }
    }
    for (final (row, col) in [
      (0, 0),
      (0, grid.count - 7),
      (grid.count - 7, 0),
    ]) {
      _finder(canvas, Offset(col * cell, row * cell), cell);
    }
  }

  void _finder(Canvas canvas, Offset at, double cell) {
    final outer = Rect.fromLTWH(at.dx, at.dy, cell * 7, cell * 7);
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          outer.deflate(cell / 2),
          Radius.circular(cell * 2),
        ),
        Paint()
          ..color = dark
          ..style = PaintingStyle.stroke
          ..strokeWidth = cell,
      )
      ..save()
      ..translate(outer.center.dx, outer.center.dy)
      ..scale(math.max(0.001, finders))
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: cell * 3,
            height: cell * 3,
          ),
          Radius.circular(cell),
        ),
        Paint()..color = accent,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(QrPainter old) =>
      old.grid != grid ||
      old.dark != dark ||
      old.accent != accent ||
      old.finders != finders;
}

/// A QR code for [data] at [size], with an optional [logo] in the middle.
class QrView extends StatelessWidget {
  const QrView({
    required this.data,
    required this.size,
    required this.dark,
    required this.accent,
    this.logo,
    super.key,
  });

  final String data;
  final double size;
  final Color dark;
  final Color accent;
  final Widget? logo;

  @override
  Widget build(BuildContext context) {
    final grid = QrGrid(data, hole: logo == null ? 0 : 9);
    final cell = size / grid.count;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: QrPainter(grid, dark: dark, accent: accent),
            ),
          ),
          if (logo != null)
            SizedBox.square(dimension: cell * (grid.hole - 1), child: logo),
        ],
      ),
    );
  }
}
