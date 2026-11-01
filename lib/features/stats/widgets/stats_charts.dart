import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/stats/model/pushup_stats.dart';

/// How tall the activity chart's bars can grow.
const _kBarsHeight = 132.0;

/// How long the bars take to grow in.
const _kBarsGrow = Duration(milliseconds: 650);

/// The activity chart: one bar per day (or month for [StatsRange.year]),
/// the latest one highlighted, and the best one labelled.
class StatsBars extends StatelessWidget {
  const StatsBars({required this.bars, required this.range, super.key});

  final List<StatsBar> bars;
  final StatsRange range;

  String _label(BuildContext context, int index) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final start = bars[index].start;

    return switch (range) {
      StatsRange.week => DateFormat.E(locale).format(start).characters.first,
      StatsRange.month =>
        index % 5 == 4 || index == bars.length - 1 ? '${start.day}' : '',
      StatsRange.year => DateFormat.MMM(locale).format(start).characters.first,
    };
  }

  @override
  Widget build(BuildContext context) {
    final most = bars.map((bar) => bar.pushups).fold(0, math.max);
    final scheme = context.colorScheme;
    final gap = range == StatsRange.month ? 3.0 : 8.0;

    return Column(
      children: [
        SizedBox(
          height: _kBarsHeight,
          child: TweenAnimationBuilder<double>(
            key: ValueKey(range),
            tween: Tween(begin: 0, end: 1),
            duration: _kBarsGrow,
            curve: Curves.easeOutCubic,
            builder: (context, grow, _) => Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (i, bar) in bars.indexed) ...[
                  if (i > 0) SizedBox(width: gap),
                  Expanded(
                    child: _Bar(
                      fraction: most == 0 ? 0 : bar.pushups / most * grow,
                      latest: i == bars.length - 1,
                      value: range != StatsRange.month &&
                              bar.pushups == most &&
                              most > 0
                          ? bar.pushups
                          : null,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: PBSpace.sm),
        Row(
          children: [
            for (final (i, _) in bars.indexed) ...[
              if (i > 0) SizedBox(width: gap),
              Expanded(
                child: Text(
                  _label(context, i),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                  softWrap: false,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: i == bars.length - 1
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                    fontWeight: i == bars.length - 1
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.fraction, required this.latest, this.value});

  final double fraction;
  final bool latest;

  /// Shown above the bar: the best one's count.
  final int? value;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final value = this.value;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Room for the label above the tallest bar.
        final room = constraints.maxHeight - 20;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (value != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: FittedBox(
                  child: Text(
                    '$value',
                    style: context.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
              ),
            Container(
              // An empty day still shows a stub, so the row reads as days.
              height: math.max(4, room * fraction),
              decoration: BoxDecoration(
                color: latest
                    ? scheme.secondary
                    : fraction == 0
                        ? scheme.surfaceContainerHigh
                        : context.tint(scheme.secondary).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The consistency grid: a column per week, Monday on top, tinted by how
/// many pushups each day had.
class StatsHeatmap extends StatelessWidget {
  const StatsHeatmap({required this.weeks, super.key});

  /// From [PushupStats.heatmap].
  final List<List<int?>> weeks;

  @override
  Widget build(BuildContext context) {
    final most =
        weeks.expand((week) => week).whereType<int>().fold(0, math.max);
    final scheme = context.colorScheme;

    Color shade(int? count) {
      if (count == null) return Colors.transparent;
      if (count == 0 || most == 0) return scheme.surfaceContainerHigh;
      // Four steps, so a light day still shows up next to a huge one.
      final level = (count / most * 4).ceil().clamp(1, 4);
      return Color.lerp(
        context.tint(context.gameColors.leaf),
        context.gameColors.leaf,
        (level - 1) / 3,
      )!;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 4.0;
        final cell =
            (constraints.maxWidth - gap * (weeks.length - 1)) / weeks.length;

        return Row(
          children: [
            for (final (i, week) in weeks.indexed) ...[
              if (i > 0) const SizedBox(width: gap),
              Column(
                children: [
                  for (final (day, count) in week.indexed) ...[
                    if (day > 0) const SizedBox(height: gap),
                    Container(
                      width: cell,
                      height: cell,
                      decoration: BoxDecoration(
                        color: shade(count),
                        borderRadius: BorderRadius.circular(cell / 3.5),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }
}

/// The heatmap's "Less ▢▢▢▢ More" key.
class StatsHeatmapKey extends StatelessWidget {
  const StatsHeatmapKey({super.key});

  @override
  Widget build(BuildContext context) {
    final leaf = context.gameColors.leaf;
    final style = context.textTheme.labelSmall
        ?.copyWith(color: context.colorScheme.onSurfaceVariant);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(context.l10n.statsLess, style: style),
        const SizedBox(width: 6),
        for (final step in [-1, 0, 1, 2, 3]) ...[
          Container(
            width: 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: step < 0
                  ? context.colorScheme.surfaceContainerHigh
                  : Color.lerp(context.tint(leaf), leaf, step / 3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
        const SizedBox(width: 6),
        Text(context.l10n.statsMore, style: style),
      ],
    );
  }
}

/// A row of small bars with a label under each, for the weekday pattern.
class StatsMiniBars extends StatelessWidget {
  const StatsMiniBars({
    required this.values,
    required this.labels,
    required this.color,
    super.key,
  });

  final List<int> values;
  final List<String> labels;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final most = values.fold(0, math.max);
    final scheme = context.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final (i, value) in values.indexed) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: most == 0 ? 4 : math.max(4, 44 * value / most),
                  decoration: BoxDecoration(
                    color: value == most && most > 0
                        ? color
                        : value == 0
                            ? scheme.surfaceContainerHigh
                            : context.tint(color),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i],
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.visible,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// A thin rounded progress bar.
class StatsProgressBar extends StatelessWidget {
  const StatsProgressBar({
    required this.value,
    required this.color,
    this.height = 8,
    super.key,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value.clamp(0, 1)),
        duration: _kBarsGrow,
        curve: Curves.easeOutCubic,
        builder: (context, value, _) => ClipRRect(
          borderRadius: BorderRadius.circular(PBRadius.pill),
          child: LinearProgressIndicator(
            value: value,
            minHeight: height,
            backgroundColor: context.colorScheme.surfaceContainerHigh,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      );
}
