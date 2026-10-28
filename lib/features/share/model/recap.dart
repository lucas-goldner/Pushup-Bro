import 'package:pushup_bro/core/model/calorie_estimator.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/features/share/model/flex_stat.dart';
import 'package:pushup_bro/features/widgets/widget_snapshot.dart';

enum RecapKind { workout, quest, trek }

/// Everything a share video shows: the headline number and the flex wall.
class Recap {
  const Recap({
    required this.kind,
    required this.pushups,
    required this.flex,
    this.title,
    this.vsLast = 0,
    this.minutes = 0,
    this.kcal = 0,
    this.stars = 0,
  });

  /// After a workout: compares with the sets before it. [history] must not
  /// contain [set] yet.
  factory Recap.workout({
    required PushupSet set,
    required List<PushupSet> history,
    required DateTime now,
    double? weightKg,
  }) {
    final pushups = set.pushups.length;
    final last = history.isEmpty ? null : history.last.pushups.length;
    final bestBefore = history.fold<int>(
      0,
      (best, s) => s.pushups.length > best ? s.pushups.length : best,
    );
    final total =
        history.fold<int>(0, (sum, s) => sum + s.pushups.length) + pushups;
    final streak = workoutStreaks([...history, set], now).current;
    final kcal = CalorieEstimator.roundedKcal(pushups, weightKg: weightKg);
    final vsLast = last == null ? 0 : pushups - last;

    return Recap(
      kind: RecapKind.workout,
      pushups: pushups,
      vsLast: vsLast,
      minutes: set.timeSpent,
      kcal: kcal,
      flex: pickFlexStats(
        gains: [
          FlexStat(FlexKind.moreThanLast, vsLast),
          FlexStat(FlexKind.kcal, kcal),
          if (history.isNotEmpty && pushups > bestBefore)
            FlexStat(FlexKind.inARow, pushups, best: true),
          if (streak >= 2) FlexStat(FlexKind.streak, streak),
        ],
        fillers: [
          FlexStat(FlexKind.total, total),
          FlexStat(FlexKind.bananas, pushups),
          FlexStat(FlexKind.streak, streak),
          FlexStat(FlexKind.inARow, pushups),
        ],
      ),
    );
  }

  /// After a daily quest.
  factory Recap.quest({
    required String title,
    required int pushups,
    required int bananas,
    required List<PushupSet> history,
    required DateTime now,
    double? weightKg,
  }) {
    final kcal = CalorieEstimator.roundedKcal(pushups, weightKg: weightKg);
    final streak = workoutStreaks(history, now).current;
    final total = history.fold<int>(0, (sum, s) => sum + s.pushups.length);

    return Recap(
      kind: RecapKind.quest,
      title: title,
      pushups: pushups,
      kcal: kcal,
      flex: pickFlexStats(
        gains: [
          FlexStat(FlexKind.pushups, pushups),
          FlexStat(FlexKind.kcal, kcal),
          if (streak >= 2) FlexStat(FlexKind.streak, streak),
        ],
        fillers: [
          FlexStat(FlexKind.bananas, bananas),
          FlexStat(FlexKind.total, total),
          FlexStat(FlexKind.streak, streak),
        ],
      ),
    );
  }

  /// After a Jungle Trek stage. [bestComboBefore] is the best combo of
  /// every stage before this one.
  factory Recap.trek({
    required String title,
    required int pushups,
    required int damage,
    required int bestCombo,
    required int bestComboBefore,
    required int stars,
    required int bananas,
    double? weightKg,
  }) {
    final kcal = CalorieEstimator.roundedKcal(pushups, weightKg: weightKg);

    return Recap(
      kind: RecapKind.trek,
      title: title,
      pushups: pushups,
      kcal: kcal,
      stars: stars,
      flex: pickFlexStats(
        gains: [
          FlexStat(FlexKind.damage, damage),
          FlexStat(
            FlexKind.combo,
            bestCombo,
            best: bestComboBefore > 0 && bestCombo > bestComboBefore,
          ),
          FlexStat(FlexKind.pushups, pushups),
          FlexStat(FlexKind.kcal, kcal),
        ],
        fillers: [
          FlexStat(FlexKind.stars, stars),
          FlexStat(FlexKind.bananas, bananas),
        ],
      ),
    );
  }

  final RecapKind kind;

  /// The quest's or stage's name.
  final String? title;
  final int pushups;

  /// Pushups more than last time; only shown when above zero.
  final int vsLast;
  final int minutes;
  final int kcal;
  final int stars;
  final List<FlexStat> flex;
}
