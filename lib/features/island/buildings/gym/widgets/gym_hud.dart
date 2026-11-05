import 'dart:math' as math;

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/island/buildings/gym/model/gym_challenge.dart';
import 'package:pushup_bro/features/island/buildings/gym/model/gym_session.dart';
import 'package:pushup_bro/features/jungle/model/jungle_quest.dart';
import 'package:pushup_bro/features/pushup_tracking/widgets/tracking_mode_picker.dart';
import 'package:pushup_bro/generated/l10n.dart';

/// How long the tempo guide wants the way down to take.
const _kTempoGuideSeconds = 3.0;

/// The gym workout's heads-up display: the workout at the top, the set in
/// a ring with what this kind of workout needs under it (the pyramid's
/// steps, the minute clock, the tempo guide, the card), Gus's call at the
/// bottom and Start / Finish.
class GymHud extends StatelessWidget {
  const GymHud({
    required this.session,
    required this.now,
    required this.started,
    required this.onStart,
    required this.onFinish,
    this.countdown,
    this.downFor,
    this.coachLine,
    this.rushedFlash = false,
    super.key,
  });

  final GymSession session;

  /// Seconds since the workout started.
  final double now;
  final bool started;

  /// Seconds left of the get-ready countdown, while it runs.
  final int? countdown;

  /// How long the current pushup has been on its way down, if it is.
  final double? downFor;

  /// What Gus is shouting.
  final String? coachLine;

  /// The last rep was too quick (a tempo set).
  final bool rushedFlash;
  final VoidCallback onStart;
  final VoidCallback onFinish;

  GymChallenge get _challenge => session.challenge;

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.paddingOf(context);
    final l = context.l10n;
    final countdown = this.countdown;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, safe.top + 8, 16, safe.bottom + 20),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 56),
            child: GymGlass(
              child: Row(
                children: [
                  Text(
                    _challenge.kind.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(width: PBSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _challenge.kind.title(l),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.titleSmall,
                        ),
                        Text(
                          _challenge.goal(l),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: PBSpace.md),
          if (countdown != null)
            Expanded(child: Center(child: _Countdown(countdown)))
          else ...[
            _centre(context),
            const Spacer(),
          ],
          if (coachLine != null && started && countdown == null) ...[
            _CoachCall(coachLine!),
            const SizedBox(height: PBSpace.md),
          ],
          if (started)
            PillButton(
              label: l.questFinish,
              icon: CarbonIcons.checkmark,
              color: context.colorScheme.secondary,
              onPressed: onFinish,
            )
          else if (countdown == null) ...[
            const TrackingModePicker(),
            const SizedBox(height: PBSpace.md),
            PillButton(
              label: l.gymStart,
              icon: CarbonIcons.play_filled_alt,
              onPressed: onStart,
            ),
          ],
        ],
      ),
    );
  }

  /// The ring (or the rest clock) and the workout's own strip.
  Widget _centre(BuildContext context) {
    final l = context.l10n;
    final block = session.block;
    final set = session.currentSet;
    final kind = _challenge.kind;
    final reps = _challenge.repBlocks;
    final single = reps.length == 1;
    final remaining = session.remaining(now);

    final Widget ring;
    if (block is RestBlock) {
      ring = _RestClock(
        seconds: remaining ?? 0,
        label: l.gymRest,
        next: set == null ? null : l.gymUpNext(set.reps),
      );
    } else if (block is PlankBlock) {
      ring = _RestClock(
        seconds: remaining ?? 0,
        label: l.gymPlank,
        next: set == null ? null : l.gymUpNext(set.reps),
        color: context.gameColors.orange,
      );
    } else {
      final goal = set?.reps ?? 1;
      final score =
          session.finished && single ? session.counted : session.blockReps;
      ring = GymRing(
        score: started ? score : 0,
        goal: goal,
        done: session.blockDone,
        tag: set?.tag,
      );
    }

    return Column(
      children: [
        ring,
        const SizedBox(height: PBSpace.sm),
        if (!single)
          _Label(
            switch (kind) {
              GymChallengeKind.pyramid => l.gymStep,
              GymChallengeKind.emom => l.gymMinute,
              GymChallengeKind.deckOfCards => l.gymCard,
              GymChallengeKind.gusDrill => l.gymCall,
              _ => l.gymRound,
            }(session.setIndex + 1, reps.length),
          ),
        const SizedBox(height: PBSpace.sm),
        _strip(context, remaining),
      ],
    );
  }

  Widget _strip(BuildContext context, double? remaining) {
    final l = context.l10n;
    final block = session.block;

    switch (_challenge.kind) {
      case GymChallengeKind.pyramid:
        return _Steps(session: session);
      case GymChallengeKind.emom:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Minutes(session: session),
            if (block is RepBlock) ...[
              const SizedBox(height: PBSpace.sm),
              _Clock(
                remaining ?? 60,
                note: session.blockDone ? l.gymMinuteDone : null,
              ),
            ],
          ],
        );
      case GymChallengeKind.tempo:
        return _TempoGuide(
          downFor: started ? downFor : null,
          rushed: rushedFlash,
          rushedCount: session.rushed,
        );
      case GymChallengeKind.maxSet:
        final best = _challenge.best;
        final idle = session.idleLeft(now);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (best > 0)
              _Label(
                session.counted > best ? l.gymNewBest : l.gymYourBest(best),
                color:
                    session.counted > best ? context.gameColors.jungle : null,
              ),
            if (idle != null && idle < 5) ...[
              const SizedBox(height: PBSpace.sm),
              _Label(
                l.gymSetEnds(idle.ceil()),
                color: context.gameColors.red,
              ),
            ],
          ],
        );
      case GymChallengeKind.burner:
        return _Clock(remaining ?? 0);
      case GymChallengeKind.plankPress:
        return const SizedBox.shrink();
      case GymChallengeKind.deckOfCards:
        return _Deck(session: session);
      case GymChallengeKind.gusDrill:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (block is RepBlock) _Clock(remaining ?? 0),
            const SizedBox(height: PBSpace.sm),
            _Label(l.gymPassed(session.passed, _challenge.passMark)),
          ],
        );
    }
  }
}

/// m:ss for [seconds].
String gymClock(double seconds) {
  final whole = seconds.ceil();

  return '${whole ~/ 60}:${(whole % 60).toString().padLeft(2, '0')}';
}

/// The set's pushups in a ring.
class GymRing extends StatelessWidget {
  const GymRing({
    required this.score,
    required this.goal,
    this.done = false,
    this.tag,
    super.key,
  });

  final int score;
  final int goal;
  final bool done;

  /// A card's face, above the score.
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final full = done || score >= goal;

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
                  full ? context.gameColors.jungle : scheme.secondary,
                ),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (tag != null)
                Text(
                  tag!,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: _suitColor(context, tag!),
                  ),
                ),
              Text(
                '$score',
                style: context.textTheme.displayMedium?.copyWith(
                  fontSize: tag == null ? 44 : 36,
                  height: 1.1,
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

Color _suitColor(BuildContext context, String tag) =>
    tag.startsWith('♥') || tag.startsWith('♦')
        ? context.gameColors.red
        : context.colorScheme.onSurface;

/// A rest's (or a plank's) clock in the ring's place.
class _RestClock extends StatelessWidget {
  const _RestClock({
    required this.seconds,
    required this.label,
    this.next,
    this.color,
  });

  final double seconds;
  final String label;
  final String? next;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final color = this.color ?? context.gameColors.ice;

    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color.alphaBlend(context.tint(color), scheme.surface),
        border: Border.all(color: color, width: 4),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelMedium?.copyWith(fontSize: 13),
            ),
          ),
          Text(
            '${seconds.ceil()}',
            style: context.textTheme.displayMedium?.copyWith(
              fontSize: 44,
              height: 1.1,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (next != null)
            Text(
              next!,
              style: context.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                letterSpacing: 0,
              ),
            ),
        ],
      ),
    );
  }
}

/// The pyramid: a bar per step, as tall as its reps; done steps green.
class _Steps extends StatelessWidget {
  const _Steps({required this.session});

  final GymSession session;

  @override
  Widget build(BuildContext context) {
    final blocks = session.challenge.blocks;
    final steps = [
      for (final (i, block) in blocks.indexed)
        if (block is RepBlock) (i, block.reps),
    ];
    final peak = steps.map((step) => step.$2).reduce(math.max);
    final scheme = context.colorScheme;

    // The glass's padding, then a bar per step, narrower on a long pyramid.
    return LayoutBuilder(
      builder: (context, constraints) {
        final room = (constraints.maxWidth - 28) / steps.length;
        final width = math.min(18, room).toDouble() - 4;

        return GymGlass(
          compact: true,
          child: SizedBox(
            height: 44,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (index, reps) in steps)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: width,
                      height: 8 + 36 * reps / peak,
                      alignment: Alignment.topCenter,
                      decoration: BoxDecoration(
                        color: switch (session.results[index]) {
                          true => context.gameColors.jungle,
                          false => context.gameColors.red,
                          null when index == session.blockIndex =>
                            scheme.secondary,
                          null => scheme.surfaceContainerHigh,
                        },
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$reps',
                        style: context.textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          letterSpacing: 0,
                          color: session.results[index] != null ||
                                  index == session.blockIndex
                              ? context.gameColors.onGame
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// EMOM's minutes: done, missed, on, still to come.
class _Minutes extends StatelessWidget {
  const _Minutes({required this.session});

  final GymSession session;

  @override
  Widget build(BuildContext context) {
    final game = context.gameColors;
    final scheme = context.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, result) in session.results.indexed)
          Container(
            width: 36,
            height: 36,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: switch (result) {
                true => game.jungle,
                false => game.red,
                null when i == session.blockIndex => scheme.secondary,
                null => scheme.surface.withValues(alpha: 0.94),
              },
              boxShadow: context.cardShadow,
            ),
            child: result == null
                ? Text(
                    '${i + 1}',
                    style: context.textTheme.labelMedium?.copyWith(
                      color: i == session.blockIndex
                          ? game.onGame
                          : scheme.onSurfaceVariant,
                    ),
                  )
                : Icon(
                    result ? CarbonIcons.checkmark : CarbonIcons.close,
                    size: 18,
                    color: game.onGame,
                  ),
          ),
      ],
    );
  }
}

/// The deck: the cards still to come, face down, and the ones done.
class _Deck extends StatelessWidget {
  const _Deck({required this.session});

  final GymSession session;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final blocks = session.challenge.blocks;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, block) in blocks.indexed)
          if (block is RepBlock)
            Container(
              width: 30,
              height: 42,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: switch (session.results[i]) {
                  true => context.gameColors.jungle,
                  false => context.gameColors.red,
                  null when i == session.blockIndex => scheme.surface,
                  null => scheme.secondary,
                },
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: scheme.surface, width: 2),
                boxShadow: context.cardShadow,
              ),
              child: Text(
                session.results[i] != null || i == session.blockIndex
                    ? block.tag?.split(' ').first ?? ''
                    : '?',
                style: context.textTheme.labelMedium?.copyWith(
                  color: i == session.blockIndex
                      ? _suitColor(context, block.tag ?? '')
                      : context.gameColors.onGame,
                ),
              ),
            ),
      ],
    );
  }
}

/// Tempo: a bar that fills over three seconds while Carlos lowers himself,
/// then says push.
class _TempoGuide extends StatelessWidget {
  const _TempoGuide({
    required this.downFor,
    required this.rushed,
    required this.rushedCount,
  });

  final double? downFor;
  final bool rushed;
  final int rushedCount;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final game = context.gameColors;
    final down = downFor;
    final ready = down != null && down >= kTempoMinSeconds;
    final label = rushed
        ? l.gymTooFast
        : ready
            ? l.gymTempoUp
            : l.gymTempoDown;
    final color = rushed
        ? game.red
        : ready
            ? game.jungle
            : context.colorScheme.onSurface;

    return GymGlass(
      compact: true,
      child: SizedBox(
        width: 200,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: context.textTheme.titleSmall?.copyWith(
                color: color,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (var second = 1; second <= 3; second++) ...[
                  if (second > 1) const SizedBox(width: 4),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: LinearProgressIndicator(
                        value: down == null
                            ? 0
                            : (down - (second - 1)).clamp(0, 1).toDouble(),
                        minHeight: 10,
                        backgroundColor: context.colorScheme.surfaceContainer,
                        valueColor: AlwaysStoppedAnimation(
                          ready ? game.jungle : game.orange,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (var second = 1; second <= _kTempoGuideSeconds; second++)
                  Expanded(
                    child: Text(
                      '$second',
                      textAlign: TextAlign.center,
                      style: context.textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A clock pill; red in its last five seconds.
class _Clock extends StatelessWidget {
  const _Clock(this.seconds, {this.note});

  final double seconds;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final color = seconds < 6 && note == null
        ? context.gameColors.red
        : context.colorScheme.onSurface;

    return GymGlass(
      compact: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CarbonIcons.timer, size: 18, color: color),
              const SizedBox(width: 6),
              Text(
                gymClock(seconds),
                style: context.textTheme.titleMedium?.copyWith(
                  color: color,
                  fontSize: 18,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          if (note != null)
            Text(
              note!,
              textAlign: TextAlign.center,
              style: context.textTheme.labelSmall?.copyWith(
                color: context.gameColors.jungle,
                letterSpacing: 0,
              ),
            ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => GymGlass(
        compact: true,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: context.textTheme.titleSmall?.copyWith(
            fontSize: 14,
            color: color,
          ),
        ),
      );
}

/// 3, 2, 1, Go.
class _Countdown extends StatelessWidget {
  const _Countdown(this.seconds);

  final int seconds;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Label(context.l10n.gymGetReady),
          const SizedBox(height: PBSpace.md),
          TweenAnimationBuilder<double>(
            key: ValueKey(seconds),
            tween: Tween(begin: 1.6, end: 1),
            duration: const Duration(milliseconds: 450),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              width: 120,
              height: 120,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: context.colorScheme.secondary,
                boxShadow: context.glow(context.colorScheme.secondary),
              ),
              child: Text(
                seconds > 0 ? '$seconds' : context.l10n.gymGo,
                style: context.textTheme.displayMedium?.copyWith(
                  color: context.colorScheme.onSecondary,
                  fontSize: seconds > 0 ? 56 : 32,
                ),
              ),
            ),
          ),
        ],
      );
}

/// Grandpa Gus calling out from the side of the mat.
class _CoachCall extends StatelessWidget {
  const _CoachCall(this.line);

  final String line;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: GymGlass(
          key: ValueKey(line),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    Character.gus.color.withValues(alpha: 0.25),
                    context.colorScheme.surface,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  Character.gus.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
              const SizedBox(width: PBSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Character.gus.name(context.l10n),
                      style: context.textTheme.labelSmall?.copyWith(
                        letterSpacing: 0,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(line, style: context.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

/// A frosted card over the gym.
class GymGlass extends StatelessWidget {
  const GymGlass({required this.child, this.compact = false, super.key});

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

/// What Gus shouts while Carlos works.
List<String> gymCoachLines(S l) => [
      l.gymCoach1,
      l.gymCoach2,
      l.gymCoach3,
      l.gymCoach4,
      l.gymCoach5,
      l.gymCoach6,
    ];
