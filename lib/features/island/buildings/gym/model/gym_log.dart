import 'package:equatable/equatable.dart';
import 'package:pushup_bro/core/model/quest_log.dart';

/// The gym's daily workouts Carlos has won, and his streak of days in a row.
class GymLog extends Equatable {
  const GymLog({
    this.completed = const {},
    this.lastCompletedDay,
    this.streak = 0,
    this.bestStreak = 0,
  });

  factory GymLog.fromJson(Map<String, dynamic> json) => GymLog(
        completed: {
          for (final MapEntry(:key, :value)
              in (json['completed'] as Map<String, dynamic>? ?? {}).entries)
            if (value is int) key: value,
        },
        lastCompletedDay: json['lastCompletedDay'] as int?,
        streak: json['streak'] as int? ?? 0,
        bestStreak: json['bestStreak'] as int? ?? 0,
      );

  /// Times each kind of workout (by name) has been won.
  final Map<String, int> completed;

  /// The day number ([dayNumber]) the last workout was won on.
  final int? lastCompletedDay;

  /// Days in a row with a workout won, up to [lastCompletedDay].
  final int streak;
  final int bestStreak;

  int get total => completed.values.fold(0, (sum, count) => sum + count);

  bool completedOn(DateTime date) => lastCompletedDay == dayNumber(date);

  /// The streak as it stands on [date]: gone once a whole day was missed.
  int streakOn(DateTime date) {
    final last = lastCompletedDay;
    if (last == null) return 0;

    return dayNumber(date) - last <= 1 ? streak : 0;
  }

  /// Won [kind] on [date]; the streak grows when yesterday was won too.
  GymLog complete(String kind, DateTime date) {
    final day = dayNumber(date);
    final last = lastCompletedDay;
    final next = last == day
        ? streak
        : last == day - 1
            ? streak + 1
            : 1;

    return GymLog(
      completed: {...completed, kind: (completed[kind] ?? 0) + 1},
      lastCompletedDay: day,
      streak: next,
      bestStreak: next > bestStreak ? next : bestStreak,
    );
  }

  Map<String, dynamic> toJson() => {
        'completed': completed,
        'lastCompletedDay': lastCompletedDay,
        'streak': streak,
        'bestStreak': bestStreak,
      };

  @override
  List<Object?> get props => [completed, lastCompletedDay, streak, bestStreak];
}
