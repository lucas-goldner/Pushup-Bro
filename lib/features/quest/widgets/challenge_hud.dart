import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/jungle/model/jungle_quest.dart';
import 'package:pushup_bro/features/pushup_tracking/widgets/tracking_mode_picker.dart';

/// The challenge's heads-up display: the goal at the top, the score in a
/// ring with the clock or hold meter under it, and Start / Finish.
class ChallengeHud extends StatelessWidget {
  const ChallengeHud({
    required this.quest,
    required this.started,
    required this.pushups,
    required this.held,
    required this.holding,
    required this.remaining,
    required this.onStart,
    required this.onFinish,
    super.key,
  });

  final JungleQuest quest;
  final bool started;
  final int pushups;
  final int held;

  /// How long the current pushup has been held at the bottom, in seconds.
  final double holding;

  /// Seconds left, for a [TimedRule].
  final double remaining;
  final VoidCallback onStart;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final rule = quest.rule;
    final score = rule is HoldRule ? held : pushups;
    final safe = MediaQuery.paddingOf(context);
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final clock = remaining < 6 ? context.gameColors.red : scheme.onSurface;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, safe.top + 8, 16, safe.bottom + 24),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: _Glass(
              child: Row(
                children: [
                  Text(
                    quest.location.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: PBSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quest.title(context.l10n),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall,
                        ),
                        Text(
                          rule.summary(context.l10n),
                          style: text.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: PBSpace.lg),
          _ScoreRing(score: score, goal: rule.goal),
          const SizedBox(height: PBSpace.md),
          if (rule is TimedRule)
            _Glass(
              compact: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CarbonIcons.timer,
                    size: 18,
                    color: clock,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '0:${remaining.ceil().toString().padLeft(2, '0')}',
                    style: text.titleMedium?.copyWith(
                      color: clock,
                      fontSize: 18,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          if (rule is HoldRule)
            _HoldMeter(holding: holding, seconds: rule.seconds),
          const Spacer(),
          if (started)
            PillButton(
              label: context.l10n.questFinish,
              icon: CarbonIcons.checkmark,
              color: scheme.secondary,
              onPressed: onFinish,
            )
          else ...[
            const TrackingModePicker(onDark: true),
            const SizedBox(height: PBSpace.md),
            PillButton(
              label: context.l10n.questStartChallenge,
              icon: CarbonIcons.play_filled_alt,
              onPressed: onStart,
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score, required this.goal});

  final int score;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return SizedBox(
      width: 132,
      height: 132,
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
            padding: const EdgeInsets.all(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: (score / goal).clamp(0, 1).toDouble()),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 9,
                strokeCap: StrokeCap.round,
                backgroundColor: scheme.surfaceContainer,
                valueColor: AlwaysStoppedAnimation(
                  score >= goal ? context.gameColors.jungle : scheme.secondary,
                ),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$score',
                style: context.textTheme.displayMedium?.copyWith(
                  fontSize: 44,
                ),
              ),
              Text(
                context.l10n.questOfGoal(goal),
                style: context.textTheme.labelMedium?.copyWith(
                  fontSize: 14,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HoldMeter extends StatelessWidget {
  const _HoldMeter({required this.holding, required this.seconds});

  final double holding;
  final double seconds;

  @override
  Widget build(BuildContext context) {
    final full = holding >= seconds;
    final game = context.gameColors;

    return _Glass(
      compact: true,
      child: SizedBox(
        width: 180,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              full ? context.l10n.questHeld : context.l10n.questHoldBottom,
              style: context.textTheme.titleSmall?.copyWith(
                color: full ? game.jungle : context.colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: (holding / seconds).clamp(0, 1),
                minHeight: 10,
                backgroundColor: context.colorScheme.surfaceContainer,
                valueColor: AlwaysStoppedAnimation(
                  full ? game.jungle : game.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Glass extends StatelessWidget {
  const _Glass({required this.child, this.compact = false});

  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 14 : 16,
          vertical: compact ? 8 : 10,
        ),
        decoration: BoxDecoration(
          color: context.colorScheme.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(PBRadius.md),
          boxShadow: context.cardShadow,
        ),
        child: child,
      );
}
