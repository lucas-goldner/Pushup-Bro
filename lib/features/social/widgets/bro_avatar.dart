import 'package:flutter/material.dart';
import 'package:pushup_bro/core/model/cosmetics.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';

/// A bro's face in a round tile: their gorilla drawn from their [look]
/// (fur, face and mat colours) with their hat on top.
class BroAvatar extends StatelessWidget {
  const BroAvatar({required this.look, this.size = 44, super.key});

  final MonkeyLook look;
  final double size;

  @override
  Widget build(BuildContext context) {
    final hat = Cosmetic.byId(look.hat);
    final emoji = hat == null || look.hat == 'hat.none' ? '' : hat.emoji;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _FacePainter(
                fur: _color(look.fur, const Color(0xFF2B2B33)),
                face: _color(look.face, const Color(0xFFB9B4D6)),
                tile: _color(look.matColor, const Color(0xFF5E9EFF)),
                shades: look.eyewear == 'eyes.shades',
              ),
            ),
          ),
          if (emoji.isNotEmpty)
            Positioned(
              top: -size * 0.2,
              left: 0,
              right: 0,
              child: Text(
                emoji,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: size * 0.34, height: 1),
              ),
            ),
        ],
      ),
    );
  }

  static Color _color(String id, Color fallback) =>
      Cosmetic.byId(id)?.color ?? fallback;
}

class _FacePainter extends CustomPainter {
  const _FacePainter({
    required this.fur,
    required this.face,
    required this.tile,
    required this.shades,
  });

  final Color fur;
  final Color face;
  final Color tile;
  final bool shades;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    Offset at(double x, double y) => Offset(x * s, y * s);
    Paint fill(Color color) => Paint()..color = color;

    // The round tile, a soft tint of their mat.
    canvas
      ..drawCircle(
        at(0.5, 0.5),
        s / 2,
        fill(Color.lerp(tile, Colors.white, 0.45)!),
      )
      ..save()
      ..clipPath(Path()..addOval(Offset.zero & size));

    // Ears, head and the tuft on top.
    for (final x in [0.2, 0.8]) {
      canvas
        ..drawCircle(at(x, 0.56), s * 0.1, fill(fur))
        ..drawCircle(at(x, 0.56), s * 0.05, fill(face));
    }
    canvas
      ..drawOval(
        Rect.fromCenter(
          center: at(0.5, 0.6),
          width: s * 0.62,
          height: s * 0.6,
        ),
        fill(fur),
      )
      ..drawCircle(at(0.47, 0.28), s * 0.07, fill(fur))
      ..drawCircle(at(0.55, 0.27), s * 0.06, fill(fur))
      // The face: a mask round the eyes and a muzzle below.
      ..drawOval(
        Rect.fromCenter(
          center: at(0.4, 0.55),
          width: s * 0.26,
          height: s * 0.24,
        ),
        fill(face),
      )
      ..drawOval(
        Rect.fromCenter(
          center: at(0.6, 0.55),
          width: s * 0.26,
          height: s * 0.24,
        ),
        fill(face),
      )
      ..drawOval(
        Rect.fromCenter(
          center: at(0.5, 0.7),
          width: s * 0.36,
          height: s * 0.24,
        ),
        fill(face),
      );

    if (shades) {
      final glass = fill(const Color(0xFF15161C));
      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: at(0.4, 0.54),
              width: s * 0.17,
              height: s * 0.11,
            ),
            Radius.circular(s * 0.04),
          ),
          glass,
        )
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: at(0.6, 0.54),
              width: s * 0.17,
              height: s * 0.11,
            ),
            Radius.circular(s * 0.04),
          ),
          glass,
        )
        ..drawLine(
          at(0.48, 0.53),
          at(0.52, 0.53),
          glass..strokeWidth = s * 0.02,
        );
    } else {
      for (final x in [0.4, 0.6]) {
        canvas
          ..drawCircle(at(x, 0.54), s * 0.07, fill(Colors.white))
          ..drawCircle(
            at(x + 0.01, 0.55),
            s * 0.045,
            fill(const Color(0xFF15161C)),
          )
          ..drawCircle(at(x + 0.025, 0.53), s * 0.014, fill(Colors.white));
      }
    }
    final blush = fill(const Color(0xFFF2A0B0));
    canvas
      ..drawOval(
        Rect.fromCenter(
          center: at(0.31, 0.66),
          width: s * 0.1,
          height: s * 0.06,
        ),
        blush,
      )
      ..drawOval(
        Rect.fromCenter(
          center: at(0.69, 0.66),
          width: s * 0.1,
          height: s * 0.06,
        ),
        blush,
      )
      // Nose and smile.
      ..drawOval(
        Rect.fromCenter(
          center: at(0.5, 0.66),
          width: s * 0.1,
          height: s * 0.06,
        ),
        fill(const Color(0xFF15161C)),
      )
      ..drawArc(
        Rect.fromCenter(
          center: at(0.5, 0.72),
          width: s * 0.12,
          height: s * 0.07,
        ),
        0.3,
        2.5,
        false,
        Paint()
          ..color = const Color(0xFF15161C)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = s * 0.02,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(_FacePainter old) =>
      fur != old.fur ||
      face != old.face ||
      tile != old.tile ||
      shades != old.shades;
}
