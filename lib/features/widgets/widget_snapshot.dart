import 'package:equatable/equatable.dart';
import 'package:pushup_bro/core/model/appearance.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/core/model/trek_progress.dart';
import 'package:pushup_bro/core/model/user.dart';
import 'package:pushup_bro/features/pro/model/pro_state.dart';
import 'package:pushup_bro/features/trek/model/trek.dart';

/// The daily goal the widgets count towards; the app has no setting yet.
const kDefaultDailyGoal = 50;

/// A local calendar day as the widgets read it: `yyyy-MM-dd`.
String widgetDayKey(DateTime day) {
  String two(int value) => value.toString().padLeft(2, '0');

  return '${day.year.toString().padLeft(4, '0')}-${two(day.month)}-'
      '${two(day.day)}';
}

DateTime _dayOf(DateTime time) => DateTime(time.year, time.month, time.day);

/// Pushups done on one day.
class WidgetDay extends Equatable {
  const WidgetDay({required this.day, required this.pushups});

  /// Midnight of the day, local time.
  final DateTime day;
  final int pushups;

  Map<String, dynamic> toJson() => {
        'date': widgetDayKey(day),
        'pushups': pushups,
      };

  @override
  List<Object?> get props => [day, pushups];
}

/// Pushups per local day for the seven days ending on [now]'s day, oldest
/// first. Days without pushups count 0.
List<WidgetDay> lastSevenDays(Iterable<PushupSet> sets, DateTime now) {
  final today = _dayOf(now);
  final days = [
    for (var back = 6; back >= 0; back--)
      DateTime(today.year, today.month, today.day - back),
  ];
  final counts = {for (final day in days) day: 0};
  for (final set in sets) {
    for (final pushup in set.pushups) {
      final done = pushup.completedAt;
      if (done == null) continue;
      final day = _dayOf(done.toLocal());
      if (counts.containsKey(day)) counts[day] = counts[day]! + 1;
    }
  }

  return [
    for (final day in days) WidgetDay(day: day, pushups: counts[day]!),
  ];
}

/// The days in a row with pushups up to today (or up to yesterday, while
/// today can still keep the streak), the longest such run, and the last
/// day with pushups.
({int current, int longest, DateTime? lastWorkout}) workoutStreaks(
  Iterable<PushupSet> sets,
  DateTime now,
) {
  final active = <DateTime>{
    for (final set in sets)
      for (final pushup in set.pushups)
        if (pushup.completedAt != null) _dayOf(pushup.completedAt!.toLocal()),
  }.toList()
    ..sort();
  if (active.isEmpty) return (current: 0, longest: 0, lastWorkout: null);

  var longest = 1;
  var run = 1;
  for (var i = 1; i < active.length; i++) {
    final previous = active[i - 1];
    final next = DateTime(previous.year, previous.month, previous.day + 1);
    run = active[i] == next ? run + 1 : 1;
    if (run > longest) longest = run;
  }

  final today = _dayOf(now);
  final yesterday = DateTime(today.year, today.month, today.day - 1);
  final last = active.last;
  var current = 0;
  if (last == today || last == yesterday) {
    current = 1;
    for (var i = active.length - 1; i > 0; i--) {
      final day = active[i];
      if (active[i - 1] != DateTime(day.year, day.month, day.day - 1)) break;
      current++;
    }
  }

  return (current: current, longest: longest, lastWorkout: last);
}

/// The Jungle Trek stage the widget points at: the first one not cleared.
class WidgetTrek extends Equatable {
  const WidgetTrek({
    required this.stageNumber,
    required this.stageCount,
    required this.title,
    required this.waves,
    required this.boss,
    required this.allCleared,
  });

  factory WidgetTrek.fromProgress(
    TrekProgress trek, {
    required String Function(TrekStage stage) title,
  }) {
    final stages = TrekStage.all;
    final stage = stages.firstWhere(
      (stage) => !trek.cleared(stage.id),
      orElse: () => stages.last,
    );

    return WidgetTrek(
      stageNumber: stage.number,
      stageCount: stages.length,
      title: title(stage),
      waves: stage.waves.length,
      boss: stage.boss,
      allCleared: stages.every((stage) => trek.cleared(stage.id)),
    );
  }

  final int stageNumber;
  final int stageCount;
  final String title;
  final int waves;
  final bool boss;
  final bool allCleared;

  Map<String, dynamic> toJson() => {
        'stageNumber': stageNumber,
        'stageCount': stageCount,
        'title': title,
        'waves': waves,
        'boss': boss,
        'allCleared': allCleared,
      };

  @override
  List<Object?> get props =>
      [stageNumber, stageCount, title, waves, boss, allCleared];
}

/// Everything the iOS widgets show, sent as JSON to the widget extension.
/// Keep the fields in sync with `WidgetSnapshot` in
/// ios/PushupBroWidgets/PushupBroWidgets.swift.
class WidgetSnapshot extends Equatable {
  const WidgetSnapshot({
    required this.hasAccess,
    required this.isPro,
    required this.streak,
    required this.longestStreak,
    required this.days,
    required this.bananas,
    required this.language,
    required this.appearance,
    this.accessUntil,
    this.dailyGoal = kDefaultDailyGoal,
    this.lastWorkoutDate,
    this.trek,
  });

  /// The snapshot for the player's state at [now].
  factory WidgetSnapshot.from({
    required List<PushupSet> pushupSets,
    required User user,
    required GameInventory inventory,
    required ProState pro,
    required String language,
    required Appearance appearance,
    required DateTime now,
    required String Function(TrekStage stage) stageTitle,
    int dailyGoal = kDefaultDailyGoal,
  }) {
    final streaks = workoutStreaks(pushupSets, now);
    final hasAccess = pro.hasAccess(now);
    // While only the free days keep everything open, the widgets lock
    // themselves when they end.
    final onlyFreeDays = hasAccess &&
        !pro.isPro &&
        pro.storeAvailable &&
        pro.plans.isNotEmpty &&
        pro.inFreeDays(now);

    return WidgetSnapshot(
      hasAccess: hasAccess,
      isPro: pro.isPro,
      accessUntil: onlyFreeDays ? pro.freeUntil : null,
      streak: streaks.current,
      longestStreak: user.longestStreak > streaks.longest
          ? user.longestStreak
          : streaks.longest,
      dailyGoal: dailyGoal,
      lastWorkoutDate: streaks.lastWorkout,
      days: lastSevenDays(pushupSets, now),
      trek: WidgetTrek.fromProgress(inventory.trek, title: stageTitle),
      bananas: inventory.bananas,
      language: language,
      appearance: appearance,
    );
  }

  /// Whether the widgets show their content: Pro, the free days, or a
  /// store that can't sell anything.
  final bool hasAccess;
  final bool isPro;

  /// When the free days end, while they are all that keeps the widgets
  /// open.
  final DateTime? accessUntil;

  /// Days in a row with pushups, as of the snapshot's day.
  final int streak;
  final int longestStreak;
  final int dailyGoal;
  final DateTime? lastWorkoutDate;

  /// The seven days ending on the snapshot's day, oldest first.
  final List<WidgetDay> days;
  final WidgetTrek? trek;
  final int bananas;

  /// The app's language code, which the widgets use for their strings.
  final String language;
  final Appearance appearance;

  /// Pushups on the snapshot's day.
  int get todayPushups => days.isEmpty ? 0 : days.last.pushups;

  Map<String, dynamic> toJson() => {
        'version': 1,
        'hasAccess': hasAccess,
        'isPro': isPro,
        'accessUntilMs': accessUntil?.millisecondsSinceEpoch,
        'streak': streak,
        'longestStreak': longestStreak,
        'todayPushups': todayPushups,
        'dailyGoal': dailyGoal,
        'lastWorkoutDate':
            lastWorkoutDate == null ? null : widgetDayKey(lastWorkoutDate!),
        'days': [for (final day in days) day.toJson()],
        'trek': trek?.toJson(),
        'bananas': bananas,
        'language': language,
        'appearance': appearance.name,
      };

  @override
  List<Object?> get props => [
        hasAccess,
        isPro,
        accessUntil,
        streak,
        longestStreak,
        dailyGoal,
        lastWorkoutDate,
        days,
        trek,
        bananas,
        language,
        appearance,
      ];
}
