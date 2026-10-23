import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';
import 'package:pushup_bro/core/style/pb_text_styles.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/jungle/model/jungle_quest.dart';

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
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quest.title(context.l10n),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: buttonTextStyle.copyWith(
                            color: background2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          rule.summary(context.l10n),
                          style: defaultTextStyle.copyWith(
                            fontSize: 13,
                            color: background2.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ScoreRing(score: score, goal: rule.goal),
          const SizedBox(height: 10),
          if (rule is TimedRule)
            _Glass(
              compact: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CarbonIcons.timer,
                    size: 18,
                    color:
                        remaining < 6 ? const Color(0xFFE5534B) : background2,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '0:${remaining.ceil().toString().padLeft(2, '0')}',
                    style: buttonTextStyle.copyWith(
                      color:
                          remaining < 6 ? const Color(0xFFE5534B) : background2,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
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
              color: accentColor,
              onPressed: onFinish,
            )
          else
            PillButton(
              label: context.l10n.questStartChallenge,
              icon: CarbonIcons.play_filled_alt,
              onPressed: onStart,
            ),
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
  Widget build(BuildContext context) => SizedBox(
        width: 132,
        height: 132,
        child: Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.9),
                boxShadow: [
                  BoxShadow(
                    color: background2.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
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
                  backgroundColor: background,
                  valueColor: AlwaysStoppedAnimation(
                    score >= goal ? const Color(0xFF2FA37A) : accentColor,
                  ),
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$score',
                  style: pushupTextStyle.copyWith(
                    fontSize: 44,
                    color: background2,
                    height: 1,
                  ),
                ),
                Text(
                  context.l10n.questOfGoal(goal),
                  style: defaultTextStyle.copyWith(
                    fontSize: 14,
                    color: background2.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}

class _HoldMeter extends StatelessWidget {
  const _HoldMeter({required this.holding, required this.seconds});

  final double holding;
  final double seconds;

  @override
  Widget build(BuildContext context) {
    final full = holding >= seconds;

    return _Glass(
      compact: true,
      child: SizedBox(
        width: 180,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              full ? context.l10n.questHeld : context.l10n.questHoldBottom,
              style: buttonTextStyle.copyWith(
                color: full ? const Color(0xFF2FA37A) : background2,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: (holding / seconds).clamp(0, 1),
                minHeight: 10,
                backgroundColor: background,
                valueColor: AlwaysStoppedAnimation(
                  full ? const Color(0xFF2FA37A) : const Color(0xFFF5A623),
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
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: child,
      );
}
