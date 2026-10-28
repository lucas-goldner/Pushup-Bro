import 'dart:math' as math;

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/island_sheet.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/pro/widgets/pro_overlay_route.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

/// Day 1: Carlos waves over a sheet that says everything is open for three
/// days.
Future<void> showFreeDaysWelcome(
  BuildContext context, {
  required DateTime freeSince,
  required DateTime now,
}) =>
    showProOverlay<void>(
      context,
      (_) => FreeDaysWelcomeSheet(freeSince: freeSince, now: now),
    );

/// The last free day: what stays free and what locks. Returns whether the
/// player wants to see the plans.
Future<bool> showLastFreeDay(BuildContext context, {required Duration left}) =>
    showProOverlay<bool>(context, (_) => LastFreeDaySheet(left: left))
        .then((seePlans) => seePlans ?? false);

class FreeDaysWelcomeSheet extends StatefulWidget {
  const FreeDaysWelcomeSheet({
    required this.freeSince,
    required this.now,
    super.key,
  });

  final DateTime freeSince;
  final DateTime now;

  @override
  State<FreeDaysWelcomeSheet> createState() => _FreeDaysWelcomeSheetState();
}

class _FreeDaysWelcomeSheetState extends State<FreeDaysWelcomeSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void initState() {
    super.initState();
    GameAudio.instance.play(Sfx.pop);
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  void _close() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _close,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 300),
              builder: (context, t, _) => ColoredBox(
                color: scheme.scrim
                    .withValues(alpha: (context.isDark ? 0.5 : 0.3) * t),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: 0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) => FractionalTranslation(
              translation: Offset(0, t * 0.6),
              child: Opacity(opacity: (1 - t).clamp(0, 1), child: child),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _carlos(context),
                  _card(context),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _carlos(BuildContext context) => SizedBox(
        height: 220,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Align(
              alignment: const Alignment(0.25, 1),
              child: AnimatedBuilder(
                animation: _loop,
                builder: (context, child) => Transform.rotate(
                  alignment: Alignment.bottomCenter,
                  angle: math.sin(_loop.value * 2 * math.pi) * 0.05,
                  child: child,
                ),
                child: Transform.translate(
                  offset: const Offset(0, 24),
                  child: Assets.images.proHeroWave.image(height: 230),
                ),
              ),
            ),
            Positioned(
              left: 22,
              top: 8,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1000),
                builder: (context, t, child) {
                  final x = Curves.easeOutCubic
                      .transform(((t - 0.4) / 0.6).clamp(0, 1));

                  return Opacity(
                    opacity: x,
                    child: Transform.translate(
                      offset: Offset(0, 14 * (1 - x)),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: context.colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                      bottomLeft: Radius.circular(6),
                    ),
                    boxShadow: context.cardShadow,
                  ),
                  child: Text(
                    context.l10n.proTrialStartBubble,
                    style: context.textTheme.labelLarge?.copyWith(fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _card(BuildContext context) {
    final scheme = context.colorScheme;
    final l = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final today = math.max(
      0,
      math.min(2, widget.now.difference(widget.freeSince).inDays),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(PBRadius.sheet)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: context.isDark ? 0.5 : 0.18),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            22,
            12,
            22,
            MediaQuery.paddingOf(context).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: PBSpace.lg),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: l.proTrialStartTitle),
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: l.proTrialStartTitleAccent,
                      style: TextStyle(color: scheme.secondary),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: context.textTheme.headlineLarge,
              ),
              const SizedBox(height: 6),
              Text(
                l.proTrialStartBody,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: PBSpace.lg),
              Row(
                children: [
                  for (var day = 0; day < 3; day++) ...[
                    if (day > 0) const SizedBox(width: 10),
                    Expanded(
                      child: _DayTile(
                        label: day == today
                            ? l.proTrialStartToday
                            : DateFormat.E(locale)
                                .format(
                                  widget.freeSince.add(Duration(days: day)),
                                )
                                .toUpperCase(),
                        day: l.proTrialStartDay(day + 1),
                        today: day == today,
                        pulse: _loop,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: PBSpace.lg),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: PBSpace.md,
                ),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(PBRadius.md),
                ),
                child: Row(
                  children: [
                    _IconTile(
                      icon: CarbonIcons.notification,
                      color: context.gameColors.orange,
                    ),
                    const SizedBox(width: PBSpace.md),
                    Expanded(
                      child: Text(
                        l.proTrialStartReminder,
                        style: context.textTheme.bodyMedium
                            ?.copyWith(fontSize: 14, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: PBSpace.xl),
              PillButton(label: l.proTrialStartCta, onPressed: _close),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.label,
    required this.day,
    required this.today,
    required this.pulse,
  });

  final String label;
  final String day;
  final bool today;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final accent = scheme.secondary;
    final tile = Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: PBSpace.md),
      decoration: BoxDecoration(
        color: today
            ? Color.alphaBlend(context.tint(accent), scheme.surface)
            : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: today ? Border.all(color: accent, width: 2) : null,
      ),
      child: Column(
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              letterSpacing: 0.8,
              color: today ? accent : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              day,
              style: context.textTheme.headlineSmall
                  ?.copyWith(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    if (!today) return tile;

    return AnimatedBuilder(
      animation: pulse,
      child: tile,
      builder: (context, child) {
        // A ring that swells out and fades, twice per loop.
        final x = (pulse.value * 2) % 1;

        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.45 * (1 - x)),
                spreadRadius: 8 * x,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.color,
    this.muted = false,
  });

  final IconData icon;
  final Color color;
  final bool muted;

  @override
  Widget build(BuildContext context) => Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: muted
              ? context.colorScheme.surfaceContainerHigh
              : Color.alphaBlend(
                  context.tint(color),
                  context.colorScheme.surface,
                ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 16, color: color),
      );
}

class LastFreeDaySheet extends StatelessWidget {
  const LastFreeDaySheet({required this.left, super.key});

  final Duration left;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = context.colorScheme;
    final game = context.gameColors;
    final hours = math.max(1, (left.inMinutes / 60).ceil());
    void close({bool seePlans = false}) => Navigator.of(context).pop(seePlans);
    Widget row(String label, {required bool free}) => Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: PBSpace.md,
          ),
          child: Row(
            children: [
              _IconTile(
                icon: free ? CarbonIcons.checkmark : CarbonIcons.locked,
                color: free ? game.jungle : scheme.onSurfaceVariant,
                muted: !free,
              ),
              const SizedBox(width: PBSpace.md),
              Expanded(
                child: Text(label, style: context.textTheme.titleSmall),
              ),
              Text(
                free ? l.proFree : l.proBadge,
                style: context.textTheme.labelMedium?.copyWith(
                  fontSize: 13,
                  color: free ? game.jungle : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );

    return IslandSheet(
      title: l.proTrialEndingTitle,
      subtitle: l.proTrialEndingBody(hours),
      badge: '⏰',
      accent: game.orange,
      onClose: close,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              children: [
                row(l.proTrialEndingGym, free: true),
                const Divider(indent: 58),
                row(l.proTrialEndingTrek, free: false),
                const Divider(indent: 58),
                row(l.proTrialEndingIsland, free: false),
              ],
            ),
          ),
          const SizedBox(height: PBSpace.lg + 4),
          PillButton(
            label: l.proTrialEndingCta,
            onPressed: () => close(seePlans: true),
          ),
          const SizedBox(height: PBSpace.sm),
          TextButton(
            onPressed: close,
            child: Text(
              l.proTrialEndingDecline,
              style: context.textTheme.labelLarge?.copyWith(
                fontSize: 15,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
