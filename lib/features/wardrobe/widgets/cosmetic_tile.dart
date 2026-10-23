import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/cosmetic_names.dart';
import 'package:pushup_bro/core/model/cosmetics.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';
import 'package:pushup_bro/core/style/pb_text_styles.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

const _tryingOnColor = Color(0xFFF5A623);

/// One cosmetic in the wardrobe: its swatch or picture, its name, and its
/// price or state.
class CosmeticTile extends StatelessWidget {
  const CosmeticTile({
    required this.cosmetic,
    required this.matColor,
    required this.owned,
    required this.worn,
    required this.tryingOn,
    required this.locked,
    required this.onTap,
    this.compact = false,
    super.key,
  });

  final Cosmetic cosmetic;

  /// For pattern swatches: the mat colour they're drawn on.
  final Color matColor;
  final bool owned;
  final bool worn;
  final bool tryingOn;
  final bool locked;
  final VoidCallback onTap;

  /// Just the picture, without the name and price.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ring = worn
        ? accentColor
        : tryingOn
            ? _tryingOnColor
            : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: ring, width: 2.5),
              ),
              child: Stack(
                children: [
                  Positioned.fill(child: _picture()),
                  if (locked)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          CarbonIcons.locked,
                          color: background2,
                          size: 20,
                        ),
                      ),
                    ),
                  if (worn)
                    const Positioned(
                      right: 4,
                      top: 4,
                      child: CircleAvatar(
                        radius: 9,
                        backgroundColor: accentColor,
                        child: Icon(
                          CarbonIcons.checkmark,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (!compact) ...[
            const SizedBox(height: 4),
            Text(
              cosmetic.label(context.l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: defaultTextStyle.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: background2,
              ),
            ),
            const SizedBox(height: 2),
            if (owned)
              Text(
                worn
                    ? context.l10n.wardrobeWearing
                    : context.l10n.wardrobeOwned,
                style: defaultTextStyle.copyWith(
                  fontSize: 11,
                  color:
                      worn ? accentColor : background2.withValues(alpha: 0.45),
                  fontWeight: FontWeight.w600,
                ),
              )
            else if (cosmetic.exclusive)
              Text(
                '🦎 ${context.l10n.trekTitle}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: defaultTextStyle.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2FA37A),
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Assets.images.island.banana.image(width: 16),
                  const SizedBox(width: 2),
                  Text(
                    '${cosmetic.price}',
                    style: defaultTextStyle.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: background2,
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _picture() {
    final color = cosmetic.color;
    final rounded = BorderRadius.circular(18);

    return switch (cosmetic.slot) {
      CosmeticSlot.fur ||
      CosmeticSlot.face ||
      CosmeticSlot.matColor =>
        DecoratedBox(
          decoration: BoxDecoration(color: background, borderRadius: rounded),
          child: Center(
            child: FractionallySizedBox(
              widthFactor: 0.62,
              heightFactor: 0.62,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: (color ?? background2).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      CosmeticSlot.matPattern => ClipRRect(
          borderRadius: rounded,
          child: CustomPaint(
            painter: MatPatternPainter(cosmetic.id, matColor),
          ),
        ),
      _ => DecoratedBox(
          decoration: BoxDecoration(color: background, borderRadius: rounded),
          child: Center(
            child: Text(cosmetic.emoji, style: const TextStyle(fontSize: 30)),
          ),
        ),
    };
  }
}

/// Paints a square of mat in [base] with [pattern], at the same scale as
/// the 3D mat (the square shows about 0.6 m of it).
class MatPatternPainter extends CustomPainter {
  MatPatternPainter(this.pattern, this.base);

  final String pattern;
  final Color base;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = base);
    const span = 0.6;
    const cells = 48;
    final cell = size.width / cells;
    final paint = Paint();
    for (var i = 0; i < cells; i++) {
      for (var j = 0; j < cells; j++) {
        final x = (i + 0.5) / cells * span - span / 2;
        final z = (j + 0.5) / cells * span * 1.4 - span * 0.7;
        final color = matPatternColor(pattern, base, x, z);
        if (color == null) continue;
        canvas.drawRect(
          Rect.fromLTWH(i * cell, j * cell, cell + 0.5, cell + 0.5),
          paint..color = color,
        );
      }
    }
  }

  @override
  bool shouldRepaint(MatPatternPainter oldDelegate) =>
      oldDelegate.pattern != pattern || oldDelegate.base != base;
}
