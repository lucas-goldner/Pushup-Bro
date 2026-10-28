import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/trek_progress.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/trek/model/trek.dart';
import 'package:pushup_bro/features/trek/trek_map_page.dart';

/// The way into the Jungle Trek's story from the jungle: how far Carlos
/// has got and the stage that comes next.
class TrekCard extends StatelessWidget {
  const TrekCard({
    required this.trek,
    required this.onPlay,
    super.key,
  });

  final TrekProgress trek;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final stage = currentStage(trek);
    final progress = l.trekStageNumber(stage.number);
    final started = trek.stars.isNotEmpty;
    final finished = TrekStage.all.every((s) => trek.cleared(s.id));
    final game = context.gameColors;
    final text = context.textTheme;
    final lime = Color.lerp(game.leaf, game.onGame, 0.25)!;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.elasticOut,
      builder: (context, t, child) => Transform.scale(
        scale: 0.6 + 0.4 * t,
        alignment: Alignment.bottomCenter,
        child: Opacity(opacity: t.clamp(0, 1), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(game.jungle, game.jungleDeep, 0.55)!,
              game.jungleDeep,
            ],
          ),
          borderRadius: BorderRadius.circular(32),
          boxShadow: context.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🦎', style: TextStyle(fontSize: 40)),
                const SizedBox(width: PBSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.trekTitle,
                        style: text.headlineMedium?.copyWith(
                          color: game.onGame,
                        ),
                      ),
                      Text(
                        '${l.trekLevel(trek.level)} · $progress',
                        style: text.labelMedium?.copyWith(
                          color: lime,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              finished
                  ? l.trekAllCleared
                  : started
                      ? l.trekNextUp(stage.title(l))
                      : l.trekTagline,
              style: text.bodyMedium?.copyWith(
                color: game.onGame.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: PBSpace.lg),
            Center(
              child: PillButton(
                label: started ? l.trekContinue : l.trekPlay,
                icon: CarbonIcons.play_filled_alt,
                color: game.red,
                onPressed: onPlay,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
