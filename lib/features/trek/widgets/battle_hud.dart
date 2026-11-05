import 'dart:math' as math;

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/trek/model/battle.dart';
import 'package:pushup_bro/features/trek/model/trek.dart';
import 'package:pushup_bro/generated/l10n.dart';

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
    final scheme = context.colorScheme;
    final game = context.gameColors;
    final text = context.textTheme;
    final color = Color.lerp(game.red, game.leaf, fraction)!;

    return Transform.translate(
      offset: Offset(math.sin(shake * 40) * 6 * shake, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 14, 8),
        decoration: BoxDecoration(
          color: scheme.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(PBRadius.pill),
          boxShadow: context.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(PBRadius.pill),
              ),
              child: Text(
                context.l10n.trekLevel(level),
                style: text.labelMedium?.copyWith(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              CarbonIcons.favorite_filled,
              color: game.red,
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
                        backgroundColor: scheme.surfaceContainerHigh,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${hp.ceil()} / ${maxHp.round()}',
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              waves == 0
                  ? context.l10n.towerFloor(wave)
                  : context.l10n.trekWave(wave, waves),
              style: text.labelMedium,
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
    final scheme = context.colorScheme;

    return SizedBox(
      width: 112,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (targeted)
            Icon(
              CarbonIcons.caret_down,
              color: context.gameColors.onGame,
              size: 18,
              shadows: [
                Shadow(
                  color: scheme.shadow.withValues(alpha: 0.4),
                  blurRadius: 6,
                ),
              ],
            ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
            decoration: BoxDecoration(
              color: targeted
                  ? Color.alphaBlend(context.tint(color), scheme.surface)
                  : scheme.surface.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(PBRadius.sm),
              boxShadow: targeted ? context.glow(color) : context.cardShadow,
            ),
            child: Column(
              children: [
                Text(
                  foe.trait == Trait.none
                      ? foe.spec.species.name(context.l10n)
                      : '${foe.trait.emoji} ${foe.trait.label(context.l10n)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
                if (foe.shield > 0) ...[
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < foe.shield; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 1.5),
                          child: Icon(
                            CarbonIcons.security,
                            size: 12,
                            color: ScaleColor.blue.color,
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 3),
                if (foe.charging case final left?) ...[
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (1 - left / foe.difficulty.windUp).clamp(0, 1),
                      minHeight: 5,
                      backgroundColor: scheme.surfaceContainerHigh,
                      valueColor: AlwaysStoppedAnimation(
                        context.gameColors.red,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: (foe.hp / foe.maxHp).clamp(0.0, 1.0)),
                    duration: const Duration(milliseconds: 250),
                    builder: (context, value, _) => LinearProgressIndicator(
                      value: value,
                      minHeight: 7,
                      backgroundColor: scheme.surfaceContainerHigh,
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
          borderRadius: BorderRadius.circular(PBRadius.pill),
          boxShadow: context.glow(foe.color.color),
        ),
        child: Text(
          foe.submerged
              ? context.l10n.noteSplash
              : foe.hidden
                  ? context.l10n.noteUnseen
                  : foe.shield > 0
                      ? context.l10n.noteShield
                      : foe.shifts
                          ? '${foe.color.weakness(context.l10n)} · '
                              '${context.l10n.weakShifting}'
                          : foe.color.weakness(context.l10n),
          textAlign: TextAlign.center,
          style: context.textTheme.labelMedium?.copyWith(
            color: context.gameColors.onGame,
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
    final scheme = context.colorScheme;
    final blue = ScaleColor.blue.color;

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
                  color: scheme.surface.withValues(alpha: 0.94),
                  boxShadow: context.cardShadow,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: CircularProgressIndicator(
                  value: (holding / holdSeconds).clamp(0.0, 1.0),
                  strokeWidth: 7,
                  strokeCap: StrokeCap.round,
                  backgroundColor: scheme.surfaceContainerHigh,
                  valueColor: AlwaysStoppedAnimation(
                    held ? blue : Color.lerp(blue, scheme.surface, 0.45),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$reps',
                    style: context.textTheme.displaySmall?.copyWith(
                      fontSize: 30,
                      height: 1,
                    ),
                  ),
                  Text(
                    context.l10n.holdMeter,
                    style: context.textTheme.labelSmall?.copyWith(
                      letterSpacing: 0,
                      color: held ? blue : scheme.onSurfaceVariant,
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
                        borderRadius: BorderRadius.circular(PBRadius.pill),
                        boxShadow: context.glow(ScaleColor.yellow.color),
                      ),
                      child: Text(
                        context.l10n.comboCount(combo),
                        style: context.textTheme.labelLarge?.copyWith(
                          color: context.gameColors.onBanana,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
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
                    style: context.textTheme.displaySmall?.copyWith(
                      fontSize: popup.big ? 34 : 22,
                      color: popup.color,
                      shadows: [
                        Shadow(
                          color: context.colorScheme.shadow
                              .withValues(alpha: context.isDark ? 0.6 : 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

/// A trait's name and mark, for enemy bars and chips.
extension TraitLabel on Trait {
  String get emoji => switch (this) {
        Trait.none => '',
        Trait.diver => '🌊',
        Trait.vanisher => '👻',
        Trait.shielded => '🛡️',
        Trait.healer => '➕',
        Trait.mirror => '🪞',
      };

  String label(S l) => switch (this) {
        Trait.none => '',
        Trait.diver => l.traitDiver,
        Trait.vanisher => l.traitVanisher,
        Trait.shielded => l.traitShielded,
        Trait.healer => l.traitHealer,
        Trait.mirror => l.traitMirror,
      };
}

/// The warning while the enemy in front winds up a heavy attack: get down
/// into a plank before the bar runs out.
class HeavyAlert extends StatelessWidget {
  const HeavyAlert({
    required this.left,
    required this.total,
    required this.bracing,
    super.key,
  });

  /// Seconds left of the wind-up, out of [total].
  final double left;
  final double total;

  /// Whether Carlos is already down, which blocks it.
  final bool bracing;

  @override
  Widget build(BuildContext context) {
    final game = context.gameColors;
    final color = bracing ? ScaleColor.blue.color : game.red;
    final pulse = 1 + 0.04 * math.sin(left * 18);

    return Transform.scale(
      scale: pulse,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(PBRadius.lg),
          boxShadow: context.glow(color),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              bracing
                  ? '🛡️ ${context.l10n.heavyBracing}'
                  : '⚠️ ${context.l10n.heavyIncoming}',
              textAlign: TextAlign.center,
              style: context.textTheme.titleSmall?.copyWith(
                color: game.onGame,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (left / total).clamp(0, 1),
                minHeight: 6,
                backgroundColor: game.onGame.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation(game.onGame),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
