import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/cubit/db_state.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/settings/widgets/settings_group.dart';
import 'package:pushup_bro/features/share/widgets/share_recap_button.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/cubit/account_state.dart';
import 'package:pushup_bro/features/social/widgets/social_widgets.dart';
import 'package:pushup_bro/features/stats/model/game_stats.dart';
import 'package:pushup_bro/features/stats/model/pushup_stats.dart';
import 'package:pushup_bro/features/stats/widgets/stats_charts.dart';

/// The effort emojis, as the finished-set sheet offers them.
const _kEfforts = ['😌', '🙂', '😅', '😤', '🥵', '💀'];

/// Everything the game tracks about the player, on one page: pushups,
/// streaks, records and rhythm, then the island, the jungle and the Trek.
class StatsPage extends StatelessWidget {
  const StatsPage({this.now, super.key});

  static const routeName = '/stats';

  /// Fixed in tests; the clock otherwise.
  final DateTime? now;

  @override
  Widget build(BuildContext context) => BlocBuilder<DBCubit, DBState>(
        builder: (context, db) =>
            BlocBuilder<GameInventoryCubit, GameInventoryState>(
          builder: (context, inventory) {
            final stats = PushupStats.from(
              db.pushupSets,
              now ?? DateTime.now(),
              weightKg: playerWeightKg(context),
            );
            final game = GameStats.from(
              inventory.inventory,
              level: db.user.level,
              xp: db.user.xp,
            );

            return SafeArea(
              bottom: false,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  PBSpace.lg,
                  64,
                  PBSpace.lg,
                  PBSpace.xxl * 2,
                ),
                children: [
                  _Hero(stats: stats),
                  const SizedBox(height: PBSpace.md),
                  _Streaks(stats: stats),
                  const SizedBox(height: PBSpace.md),
                  _Activity(stats: stats),
                  const SizedBox(height: PBSpace.md),
                  _Consistency(stats: stats),
                  _Header(context.l10n.statsRecords),
                  _Records(stats: stats),
                  _Header(context.l10n.statsRhythm),
                  _Rhythm(stats: stats),
                  _Header(context.l10n.statsGame),
                  _Game(game: game),
                  const SizedBox(height: PBSpace.md),
                  _Trek(game: game),
                ],
              ),
            );
          },
        ),
      );
}

String _number(BuildContext context, num value) =>
    NumberFormat.decimalPattern(Localizations.localeOf(context).toLanguageTag())
        .format(value);

String _duration(BuildContext context, int minutes) => minutes < 60
    ? context.l10n.statsMinutes(minutes)
    : context.l10n.statsHours(minutes ~/ 60, minutes % 60);

/// A white rounded card.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding ?? const EdgeInsets.all(PBSpace.lg + 4),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(PBRadius.lg),
          boxShadow: context.cardShadow,
        ),
        child: child,
      );
}

/// A section heading, aligned with the cards' content.
class _Header extends StatelessWidget {
  const _Header(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: PBSpace.sm),
        // The settings' heading, minus the card margin it adds.
        child: Transform.translate(
          offset: const Offset(-PBSpace.lg, 0),
          child: SettingsSectionHeader(title),
        ),
      );
}

/// A card's title row, with an optional trailing widget.
class _CardTitle extends StatelessWidget {
  const _CardTitle(this.title, {this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    final trailing = this.trailing;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.textTheme.titleMedium),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}

/// An icon on a tinted disc.
class _IconDisc extends StatelessWidget {
  const _IconDisc(this.icon, this.color, {this.size = 36});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: context.tint(color),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: size * 0.5, color: color),
      );
}

/// The total, big, on the brand gradient, with the totals under it.
class _Hero extends StatelessWidget {
  const _Hero({required this.stats});

  final PushupStats stats;

  @override
  Widget build(BuildContext context) {
    final on = context.gameColors.onGame;
    final first = stats.firstDay;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final l = context.l10n;

    Widget total(String value, String label) => Expanded(
          child: Column(
            children: [
              FittedBox(
                child: Text(
                  value,
                  style: context.textTheme.titleLarge?.copyWith(
                    color: on,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelSmall?.copyWith(
                  color: on.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(
        PBSpace.lg,
        PBSpace.xl,
        PBSpace.lg,
        PBSpace.lg + 4,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [context.colorScheme.secondary, context.gameColors.purple],
        ),
        borderRadius: BorderRadius.circular(PBRadius.lg),
        boxShadow: context.glow(context.colorScheme.secondary),
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: stats.total.toDouble()),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => FittedBox(
              child: Text(
                _number(context, value.round()),
                style: context.textTheme.displayLarge?.copyWith(
                  fontSize: 64,
                  height: 1,
                  color: on,
                ),
              ),
            ),
          ),
          const SizedBox(height: PBSpace.sm),
          Text(
            first == null
                ? l.statsEmpty
                : '${l.statsPushupsSoFar} · '
                    '${l.statsSince(DateFormat.yMMMd(locale).format(first))}',
            textAlign: TextAlign.center,
            style: context.textTheme.labelLarge?.copyWith(
              color: on.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: PBSpace.lg + 4),
          Container(
            padding: const EdgeInsets.symmetric(vertical: PBSpace.md),
            decoration: BoxDecoration(
              color: on.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(PBRadius.md),
            ),
            child: Row(
              children: [
                total(_number(context, stats.sets), l.statsSets),
                total(_number(context, stats.activeDays), l.statsActiveDays),
                total(_duration(context, stats.minutes), l.statsTime),
                total(_number(context, stats.kcal), l.statsKcal),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The current and the best streak, side by side.
class _Streaks extends StatelessWidget {
  const _Streaks({required this.stats});

  final PushupStats stats;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    Widget tile(IconData icon, Color color, String label, int days) => Expanded(
          child: _Card(
            padding: const EdgeInsets.all(PBSpace.lg),
            child: Row(
              children: [
                _IconDisc(icon, color, size: 44),
                const SizedBox(width: PBSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FittedBox(
                        alignment: Alignment.centerLeft,
                        fit: BoxFit.scaleDown,
                        child: Text(
                          l.statsDays(days),
                          style: context.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelMedium?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    return Row(
      children: [
        tile(
          CarbonIcons.fire,
          context.gameColors.orange,
          l.statsStreak,
          stats.currentStreak,
        ),
        const SizedBox(width: PBSpace.md),
        tile(
          CarbonIcons.trophy,
          context.gameColors.banana,
          l.statsBestStreak,
          stats.longestStreak,
        ),
      ],
    );
  }
}

/// The activity chart, for the last week, month or year.
class _Activity extends StatefulWidget {
  const _Activity({required this.stats});

  final PushupStats stats;

  @override
  State<_Activity> createState() => _ActivityState();
}

class _ActivityState extends State<_Activity> {
  StatsRange _range = StatsRange.week;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final bars = widget.stats.bars(_range);
    final sum = bars.fold(0, (sum, bar) => sum + bar.pushups);

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardTitle(
            l.statsActivity,
            subtitle: switch (_range) {
              StatsRange.week => l.statsLast7Days,
              StatsRange.month => l.statsLast30Days,
              StatsRange.year => l.statsLast12Months,
            },
            trailing: Text(
              // The plural picks the words; the number gets its separators.
              l.statsPushups(sum).replaceFirst('$sum', _number(context, sum)),
              style: context.textTheme.titleSmall?.copyWith(
                color: context.colorScheme.secondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: PBSpace.lg),
          SocialTabs(
            compact: true,
            labels: [l.statsWeek, l.statsMonth, l.statsYear],
            selected: _range.index,
            onSelect: (i) => setState(() => _range = StatsRange.values[i]),
          ),
          const SizedBox(height: PBSpace.xl),
          if (sum == 0)
            SizedBox(
              height: 154,
              child: Center(
                child: Text(
                  l.statsNoPushupsYet,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            StatsBars(bars: bars, range: _range),
        ],
      ),
    );
  }
}

/// The heatmap of the last weeks.
class _Consistency extends StatelessWidget {
  const _Consistency({required this.stats});

  final PushupStats stats;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardTitle(
            l.statsConsistency,
            subtitle: l.statsWeeks(kStatsHeatmapWeeks),
            trailing: const StatsHeatmapKey(),
          ),
          const SizedBox(height: PBSpace.lg),
          StatsHeatmap(weeks: stats.heatmap()),
        ],
      ),
    );
  }
}

/// One number in a grid of records.
class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    this.detail,
    this.wide = false,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  /// A small line under the label, like the date of a record.
  final String? detail;

  /// The whole row to itself: the icon beside the number.
  final bool wide;

  _Tile get widened => _Tile(
        icon: icon,
        color: color,
        value: value,
        label: label,
        detail: detail,
        wide: true,
      );

  @override
  Widget build(BuildContext context) {
    final detail = this.detail;
    if (wide) {
      return _Card(
        padding: const EdgeInsets.all(PBSpace.lg),
        child: Row(
          children: [
            _IconDisc(icon, color, size: 44),
            const SizedBox(width: PBSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    detail == null ? label : '$label · $detail',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return _Card(
      padding: const EdgeInsets.all(PBSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconDisc(icon, color),
          const SizedBox(height: PBSpace.md),
          FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: context.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            detail ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelSmall?.copyWith(
              color:
                  context.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// Tiles two to a row; an odd one out at the end takes the whole row.
class _TileGrid extends StatelessWidget {
  const _TileGrid(this.tiles);

  final List<_Tile> tiles;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          for (var i = 0; i < tiles.length; i += 2) ...[
            if (i > 0) const SizedBox(height: PBSpace.md),
            if (i + 1 == tiles.length)
              tiles[i].widened
            else
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: tiles[i]),
                    const SizedBox(width: PBSpace.md),
                    Expanded(child: tiles[i + 1]),
                  ],
                ),
              ),
          ],
        ],
      );
}

class _Records extends StatelessWidget {
  const _Records({required this.stats});

  final PushupStats stats;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final game = context.gameColors;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final bestDay = stats.bestDayDate;
    final pace = stats.bestPace;

    return _TileGrid([
      _Tile(
        icon: CarbonIcons.trophy,
        color: game.banana,
        value: _number(context, stats.bestSet),
        label: l.statsBestSet,
      ),
      _Tile(
        icon: CarbonIcons.calendar,
        color: context.colorScheme.secondary,
        value: _number(context, stats.bestDay),
        label: l.statsBestDay,
        detail:
            bestDay == null ? null : DateFormat.yMMMd(locale).format(bestDay),
      ),
      _Tile(
        icon: CarbonIcons.lightning,
        color: game.orange,
        value: pace == null
            ? '–'
            : l.statsPerMinute(NumberFormat('0.#', locale).format(pace)),
        label: l.statsFastest,
      ),
      _Tile(
        icon: CarbonIcons.chart_average,
        color: game.leaf,
        value: _number(context, stats.averageSet),
        label: l.statsAverageSet,
      ),
    ]);
  }
}

/// When the player trains: the weekday pattern, the time of day and how
/// sets usually feel.
class _Rhythm extends StatelessWidget {
  const _Rhythm({required this.stats});

  final PushupStats stats;

  String _dayTime(BuildContext context, DayTime time) => switch (time) {
        DayTime.morning => context.l10n.statsMorning,
        DayTime.afternoon => context.l10n.statsAfternoon,
        DayTime.evening => context.l10n.statsEvening,
        DayTime.night => context.l10n.statsNight,
      };

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final locale = Localizations.localeOf(context).toLanguageTag();
    // 2024-01-01 was a Monday.
    String weekday(int day, {bool short = true}) =>
        (short ? DateFormat.E(locale) : DateFormat.EEEE(locale))
            .format(DateTime(2024, 1, day));
    final favouriteDay = stats.favouriteWeekday;
    final favouriteTime = stats.favouriteDayTime;
    final effort = stats.usualEffort;
    final scheme = context.colorScheme;

    Widget fact(String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              fact(
                l.statsFavouriteDay,
                favouriteDay == null
                    ? '–'
                    : weekday(favouriteDay, short: false),
              ),
              fact(
                l.statsFavouriteTime,
                favouriteTime == null ? '–' : _dayTime(context, favouriteTime),
              ),
            ],
          ),
          const SizedBox(height: PBSpace.lg),
          StatsMiniBars(
            values: stats.weekdays,
            labels: [for (var day = 1; day <= 7; day++) weekday(day)],
            color: scheme.secondary,
          ),
          const SizedBox(height: PBSpace.lg),
          _DayTimeSplit(stats: stats, name: (time) => _dayTime(context, time)),
          if (effort != null) ...[
            const SizedBox(height: PBSpace.lg),
            Row(
              children: [
                Text(_kEfforts[effort], style: const TextStyle(fontSize: 26)),
                const SizedBox(width: PBSpace.md),
                fact(l.statsUsualEffort, _effortName(context, effort)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _effortName(BuildContext context, int effort) => switch (effort) {
        1 => context.l10n.superEasyEffort,
        2 => context.l10n.easyEffort,
        3 => context.l10n.mediumEffort,
        4 => context.l10n.hardEffort,
        _ => context.l10n.superHardEffort,
      };
}

/// One bar split by the time of day, with a legend.
class _DayTimeSplit extends StatelessWidget {
  const _DayTimeSplit({required this.stats, required this.name});

  final PushupStats stats;
  final String Function(DayTime time) name;

  @override
  Widget build(BuildContext context) {
    final game = context.gameColors;
    final colors = [
      game.banana,
      game.orange,
      context.colorScheme.secondary,
      game.purple,
    ];
    final total = stats.dayTimes.fold(0, (sum, count) => sum + count);
    int share(DayTime time) =>
        (stats.dayTimes[time.index] * 100 / total).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(PBRadius.pill),
          child: SizedBox(
            height: 10,
            child: total == 0
                ? ColoredBox(color: context.colorScheme.surfaceContainerHigh)
                : Row(
                    children: [
                      for (final time in DayTime.values)
                        if (stats.dayTimes[time.index] > 0)
                          Expanded(
                            flex: stats.dayTimes[time.index],
                            child: ColoredBox(color: colors[time.index]),
                          ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: PBSpace.sm),
        Wrap(
          spacing: PBSpace.md,
          runSpacing: PBSpace.xs,
          children: [
            for (final time in DayTime.values)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors[time.index],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    total == 0 ? name(time) : '${name(time)} ${share(time)}%',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

/// The bro level and the island, wardrobe, monkeys, quests and bros.
class _Game extends StatelessWidget {
  const _Game({required this.game});

  final GameStats game;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.gameColors;
    final scheme = context.colorScheme;
    String outOf(Collected value) => '${value.have} / ${value.of}';

    return Column(
      children: [
        _Card(
          child: Row(
            children: [
              _IconDisc(CarbonIcons.star, scheme.secondary, size: 44),
              const SizedBox(width: PBSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l.level(game.level),
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: PBSpace.sm),
                    StatsProgressBar(
                      value: game.levelProgress,
                      color: scheme.secondary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: PBSpace.md),
        BlocSelector<AccountCubit, AccountState, int?>(
          selector: (state) => state.status == AccountStatus.ready
              ? state.profile?.friendCount
              : null,
          builder: (context, bros) => _TileGrid([
            _Tile(
              icon: CarbonIcons.fruit_bowl,
              color: colors.banana,
              value: _number(context, game.bananas),
              label: l.statsBananas,
            ),
            _Tile(
              icon: CarbonIcons.building,
              color: colors.leaf,
              value: outOf(game.buildings),
              label: l.statsBuildings,
            ),
            _Tile(
              icon: CarbonIcons.clean,
              color: colors.purple,
              value: outOf(game.cosmetics),
              label: l.wardrobeTitle,
            ),
            _Tile(
              icon: CarbonIcons.map,
              color: colors.jungle,
              value: _number(context, game.questsTotal),
              label: l.statsQuests,
              detail: l.statsQuestsFound(game.quests.have, game.quests.of),
            ),
            _Tile(
              icon: CarbonIcons.pedestrian_family,
              color: colors.orange,
              value: _number(context, game.monkeys),
              label: l.statsMonkeys,
            ),
            if (bros != null)
              _Tile(
                icon: CarbonIcons.group,
                color: scheme.secondary,
                value: _number(context, bros),
                label: l.friends,
              ),
          ]),
        ),
      ],
    );
  }
}

/// The Jungle Trek: level, stages, stars and stat points.
class _Trek extends StatelessWidget {
  const _Trek({required this.game});

  final GameStats game;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = context.gameColors;

    Widget row(String label, Collected value, Color color) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label, style: context.textTheme.labelLarge),
                ),
                Text(
                  '${value.have} / ${value.of}',
                  style: context.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            StatsProgressBar(
              value: value.of == 0 ? 0 : value.have / value.of,
              color: color,
            ),
          ],
        );

    Widget stat(String label, int value) => Expanded(
          child: Column(
            children: [
              Text(
                '$value',
                style: context.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: context.textTheme.labelSmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardTitle(
            l.trekTitle,
            trailing: SocialChip(
              l.trekLevel(game.trekLevel),
              color: colors.jungle,
            ),
          ),
          const SizedBox(height: PBSpace.lg),
          row(l.statsTrekStages, game.trekStages, colors.jungle),
          const SizedBox(height: PBSpace.md),
          row(l.trekStars, game.trekStars, colors.banana),
          const SizedBox(height: PBSpace.lg),
          Row(
            children: [
              stat(l.statPower, game.power),
              stat(l.statVitality, game.vitality),
              stat(l.statGrip, game.grip),
              stat(l.statAgility, game.agility),
            ],
          ),
        ],
      ),
    );
  }
}
