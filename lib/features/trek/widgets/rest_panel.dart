import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';
import 'package:pushup_bro/core/style/pb_text_styles.dart';
import 'package:pushup_bro/core/widgets/island_sheet.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/trek/model/trek.dart';
import 'package:pushup_bro/features/trek/trek_stage_page.dart';

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
    final color = spec.color?.color ?? const Color(0xFF8B5FD9);

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
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
              spec.species.name(context.l10n),
              overflow: TextOverflow.ellipsis,
              style: buttonTextStyle.copyWith(
                color: background2,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
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
    super.key,
  });

  final double secondsLeft;
  final double hp;
  final double maxHp;
  final List<EnemySpec> nextWave;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final safe = MediaQuery.paddingOf(context);

    return ColoredBox(
      color: background2.withValues(alpha: 0.35),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: EdgeInsets.fromLTRB(16, 0, 16, safe.bottom + 16),
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 520),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
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
                          backgroundColor: background,
                          valueColor: const AlwaysStoppedAnimation(
                            Color(0xFF2FA37A),
                          ),
                        ),
                        Center(
                          child: Text(
                            '${secondsLeft.ceil()}',
                            style: pushupTextStyle.copyWith(
                              fontSize: 30,
                              color: background2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.trekRest,
                          style: pageTitleTextStyle.copyWith(
                            fontSize: 24,
                            color: background2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l.trekRestInfo,
                          style: defaultTextStyle.copyWith(
                            fontSize: 14,
                            color: background2.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
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
                              backgroundColor: background,
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFF4FB35A),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.trekNextWave,
                  style: buttonTextStyle.copyWith(
                    color: background2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
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
                          spec.color?.weakness(l) ?? l.weakShifting,
                          style: defaultTextStyle.copyWith(
                            fontSize: 13,
                            color: background2.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              PillButton(
                label: l.trekSkipRest,
                icon: CarbonIcons.lightning,
                color: const Color(0xFFE5534B),
                onPressed: onReady,
              ),
            ],
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

    return ColoredBox(
      color: background2.withValues(alpha: 0.45),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetBadge('😵', size: 76, color: Color(0xFFE5534B)),
              const SizedBox(height: 14),
              Text(
                l.trekKnockedOut,
                textAlign: TextAlign.center,
                style: pageTitleTextStyle.copyWith(color: background2),
              ),
              const SizedBox(height: 6),
              Text(
                l.trekKnockedOutInfo,
                textAlign: TextAlign.center,
                style: defaultTextStyle.copyWith(
                  color: background2.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 20),
              PillButton(
                label: l.trekTryAgain,
                icon: CarbonIcons.restart,
                color: const Color(0xFFE5534B),
                onPressed: onRetry,
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onLeave,
                child: Text(
                  l.trekBackToMap,
                  style: buttonTextStyle.copyWith(
                    color: background2,
                    fontWeight: FontWeight.w700,
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
