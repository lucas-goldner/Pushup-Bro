import 'dart:math' as math;

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';
import 'package:pushup_bro/core/style/pb_text_styles.dart';
import 'package:pushup_bro/features/trek/model/battle.dart';
import 'package:pushup_bro/features/trek/model/trek.dart';

/// A number (or word) floating up from where a hit landed.
class Popup {
  Popup({
    required this.text,
    required this.color,
    required this.at,
    this.big = false,
  });

  final String text;
  final Color color;
  Offset at;
  final bool big;
  double age = 0;
}

/// Carlos's health and level, and which wave this is.
class PlayerBar extends StatelessWidget {
  const PlayerBar({
    required this.hp,
    required this.maxHp,
    required this.level,
    required this.wave,
    required this.waves,
    required this.shake,
    super.key,
  });

  final double hp;
  final double maxHp;
  final int level;
  final int wave;
  final int waves;

  /// 0 to 1, right after taking a hit.
  final double shake;

  @override
  Widget build(BuildContext context) {
    final fraction = (hp / maxHp).clamp(0.0, 1.0);
    final color = Color.lerp(
      const Color(0xFFE5534B),
      const Color(0xFF4FB35A),
      fraction,
    )!;

    return Transform.translate(
      offset: Offset(math.sin(shake * 40) * 6 * shake, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: background2,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                context.l10n.trekLevel(level),
                style: buttonTextStyle.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              CarbonIcons.favorite_filled,
              color: Color(0xFFE5534B),
              size: 18,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: fraction),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, value, _) => LinearProgressIndicator(
                        value: value,
                        minHeight: 12,
                        backgroundColor: background,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${hp.ceil()} / ${maxHp.round()}',
                    style: defaultTextStyle.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: background2.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              context.l10n.trekWave(wave, waves),
              style: buttonTextStyle.copyWith(
                color: background2,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small health bar over an enemy, tinted by its colour, with its name;
/// marked when it's the one being hit.
class FoeBar extends StatelessWidget {
  const FoeBar({required this.foe, required this.targeted, super.key});

  final Foe foe;
  final bool targeted;

  @override
  Widget build(BuildContext context) {
    final color = foe.color.color;

    return SizedBox(
      width: 112,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (targeted)
            const Icon(CarbonIcons.caret_down, color: Colors.white, size: 18),
          Container(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: targeted ? color : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(
                  foe.spec.species.name(context.l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: defaultTextStyle.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: background2,
                  ),
                ),
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: (foe.hp / foe.spec.hp).clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 250),
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 7,
                      backgroundColor: background,
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// What the targeted enemy is weak to, as a coloured pill.
class WeaknessHint extends StatelessWidget {
  const WeaknessHint({required this.foe, super.key});

  final Foe foe;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: foe.color.color,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: foe.color.color.withValues(alpha: 0.4),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          foe.shifts
              ? '${foe.color.weakness(context.l10n)} · '
                  '${context.l10n.weakShifting}'
              : foe.color.weakness(context.l10n),
          textAlign: TextAlign.center,
          style: buttonTextStyle.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      );
}

/// A ring filling up while a pushup is held at the bottom, and the combo
/// of quick pushups.
class RepMeter extends StatelessWidget {
  const RepMeter({
    required this.holding,
    required this.combo,
    required this.reps,
    super.key,
  });

  /// Seconds held at the bottom so far, 0 when up.
  final double holding;
  final int combo;
  final int reps;

  @override
  Widget build(BuildContext context) {
    final held = holding >= holdSeconds;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 86,
          height: 86,
          child: Stack(
            fit: StackFit.expand,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: CircularProgressIndicator(
                  value: (holding / holdSeconds).clamp(0.0, 1.0),
                  strokeWidth: 7,
                  strokeCap: StrokeCap.round,
                  backgroundColor: background,
                  valueColor: AlwaysStoppedAnimation(
                    held ? ScaleColor.blue.color : const Color(0xFF9DC4EE),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$reps',
                    style: pushupTextStyle.copyWith(
                      fontSize: 30,
                      color: background2,
                      height: 1,
                    ),
                  ),
                  Text(
                    context.l10n.holdMeter,
                    style: defaultTextStyle.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: held
                          ? ScaleColor.blue.color
                          : background2.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: combo >= 2
              ? Padding(
                  key: ValueKey(combo),
                  padding: const EdgeInsets.only(left: 10),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1.4, end: 1),
                    duration: const Duration(milliseconds: 300),
                    builder: (context, scale, child) =>
                        Transform.scale(scale: scale, child: child),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: ScaleColor.yellow.color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        context.l10n.comboCount(combo),
                        style: buttonTextStyle.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

/// Floating damage numbers and labels.
class PopupLayer extends StatelessWidget {
  const PopupLayer({required this.popups, super.key});

  final List<Popup> popups;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Stack(
          children: [
            for (final popup in popups)
              Positioned(
                left: popup.at.dx - 90,
                top: popup.at.dy - popup.age * 70,
                width: 180,
                child: Opacity(
                  opacity: (1 - popup.age).clamp(0.0, 1.0),
                  child: Text(
                    popup.text,
                    textAlign: TextAlign.center,
                    style: pushupTextStyle.copyWith(
                      fontSize: popup.big ? 30 : 20,
                      color: popup.color,
                      shadows: const [
                        Shadow(color: Color(0xAA000000), blurRadius: 6),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}
