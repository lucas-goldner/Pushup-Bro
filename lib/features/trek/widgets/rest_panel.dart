import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/island_sheet.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/trek/model/boon.dart';
import 'package:pushup_bro/features/trek/model/trek.dart';
import 'package:pushup_bro/features/trek/trek_stage_page.dart';
import 'package:pushup_bro/features/trek/widgets/battle_hud.dart';

/// The emoji for a [Species].
String speciesEmoji(Species species) => switch (species) {
      Species.gecko || Species.skink || Species.iguana => '🦎',
      Species.croc => '🐊',
      Species.chameleon => '🦎',
      Species.snake => '🐍',
      Species.king => '👑',
    };

/// An enemy as a chip: its emoji on its colour, and its name.
class EnemyChip extends StatelessWidget {
  const EnemyChip({required this.spec, super.key});

  final EnemySpec spec;

  @override
  Widget build(BuildContext context) {
    final color = spec.color?.color ?? context.gameColors.purple;

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      decoration: BoxDecoration(
        color: context.tint(color),
        borderRadius: BorderRadius.circular(PBRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: spec.color == null
                  ? SweepGradient(
                      colors: [
                        for (final c in ScaleColor.values) c.color,
                        ScaleColor.green.color,
                      ],
                    )
                  : null,
              color: spec.color == null ? null : color,
              shape: BoxShape.circle,
            ),
            child: Text(
              speciesEmoji(spec.species),
              style: const TextStyle(fontSize: 15),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              spec.trait == Trait.none
                  ? spec.species.name(context.l10n)
                  : '${spec.species.name(context.l10n)} · '
                      '${spec.trait.emoji} ${spec.trait.label(context.l10n)}',
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// A breather between waves: a countdown ring, health coming back, who's
/// next and what they're weak to.
class RestPanel extends StatelessWidget {
  const RestPanel({
    required this.secondsLeft,
    required this.hp,
    required this.maxHp,
    required this.nextWave,
    required this.onReady,
    this.offer = const [],
    this.picked,
    this.onPick,
    this.onStop,
    super.key,
  });

  final double secondsLeft;
  final double hp;
  final double maxHp;
  final List<EnemySpec> nextWave;
  final VoidCallback onReady;

  /// The power-ups to pick one from, and the one picked.
  final List<Boon> offer;
  final Boon? picked;
  final ValueChanged<Boon>? onPick;

  /// In the tower: stop climbing and take what's been earned.
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final safe = MediaQuery.paddingOf(context);
    final scheme = context.colorScheme;
    final game = context.gameColors;
    final text = context.textTheme;

    return ColoredBox(
      color: scheme.scrim.withValues(alpha: context.isDark ? 0.5 : 0.35),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: EdgeInsets.fromLTRB(16, 0, 16, safe.bottom + 16),
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 520),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: context.cardShadow,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 84,
                      height: 84,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: secondsLeft / restSeconds,
                            strokeWidth: 8,
                            strokeCap: StrokeCap.round,
                            backgroundColor: scheme.surfaceContainerHigh,
                            valueColor: AlwaysStoppedAnimation(game.jungle),
                          ),
                          Center(
                            child: Text(
                              '${secondsLeft.ceil()}',
                              style: text.displaySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: PBSpace.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.trekRest, style: text.headlineMedium),
                          const SizedBox(height: PBSpace.xs),
                          Text(
                            l.trekRestInfo,
                            style: text.bodyMedium?.copyWith(
                              fontSize: 14,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: PBSpace.sm),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: hp / maxHp),
                              duration: const Duration(milliseconds: 900),
                              curve: Curves.easeOutCubic,
                              builder: (context, value, _) =>
                                  LinearProgressIndicator(
                                value: value,
                                minHeight: 10,
                                backgroundColor: scheme.surfaceContainerHigh,
                                valueColor: AlwaysStoppedAnimation(game.leaf),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (offer.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(l.boonPick, style: text.titleSmall),
                  ),
                  const SizedBox(height: PBSpace.sm),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, boon) in offer.indexed) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(
                            child: BoonCard(
                              boon: boon,
                              picked: boon == picked,
                              dimmed: picked != null && boon != picked,
                              onTap:
                                  onPick == null ? null : () => onPick!(boon),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l.trekNextWave,
                    style: text.titleSmall,
                  ),
                ),
                const SizedBox(height: PBSpace.sm),
                for (final spec in {
                  for (final e in nextWave) '${e.species}${e.color}': e,
                }.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Flexible(child: EnemyChip(spec: spec)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            switch (spec.trait) {
                              Trait.shielded => l.noteShield,
                              Trait.diver => l.noteDived,
                              Trait.vanisher => l.noteVanished,
                              _ => spec.color?.weakness(l) ?? l.weakShifting,
                            },
                            style: text.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: PBSpace.md),
                PillButton(
                  label: onStop == null ? l.trekSkipRest : l.towerNext,
                  icon: CarbonIcons.lightning,
                  color: game.red,
                  onPressed: onReady,
                ),
                if (onStop case final stop?)
                  TextButton(onPressed: stop, child: Text(l.towerStop)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Carlos lost the fight: try again or leave.
class KnockedOutPanel extends StatelessWidget {
  const KnockedOutPanel({
    required this.onRetry,
    required this.onLeave,
    super.key,
  });

  final VoidCallback onRetry;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = context.colorScheme;
    final red = context.gameColors.red;

    return ColoredBox(
      color: scheme.scrim.withValues(alpha: context.isDark ? 0.6 : 0.45),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(PBSpace.xl),
          padding: const EdgeInsets.all(PBSpace.xl),
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(32),
            boxShadow: context.cardShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SheetBadge('😵', size: 76, color: red),
              const SizedBox(height: 14),
              Text(
                l.trekKnockedOut,
                textAlign: TextAlign.center,
                style: context.textTheme.headlineLarge,
              ),
              const SizedBox(height: 6),
              Text(
                l.trekKnockedOutInfo,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              PillButton(
                label: l.trekTryAgain,
                icon: CarbonIcons.restart,
                color: red,
                onPressed: onRetry,
              ),
              const SizedBox(height: PBSpace.sm),
              TextButton(
                onPressed: onLeave,
                child: Text(
                  l.trekBackToMap,
                  style: context.textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A power-up to pick between waves: its mark, name and what it does.
class BoonCard extends StatelessWidget {
  const BoonCard({
    required this.boon,
    required this.picked,
    required this.dimmed,
    this.onTap,
    super.key,
  });

  final Boon boon;
  final bool picked;
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = context.colorScheme;
    final game = context.gameColors;
    final text = context.textTheme;

    return Semantics(
      button: true,
      selected: picked,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: dimmed ? 0.45 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
            decoration: BoxDecoration(
              color: picked
                  ? Color.alphaBlend(context.tint(game.banana), scheme.surface)
                  : scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(PBRadius.md),
              border: Border.all(
                color: picked ? game.banana : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Text(boon.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(height: 4),
                Text(
                  boon.title(l),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: text.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  boon.info(l),
                  textAlign: TextAlign.center,
                  style: text.bodySmall?.copyWith(
                    fontSize: 11,
                    height: 1.25,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
