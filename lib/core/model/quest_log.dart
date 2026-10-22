import 'package:equatable/equatable.dart';

/// Which jungle quests Carlos has finished, and when.
class QuestLog extends Equatable {
  const QuestLog({this.completed = const {}, this.lastCompletedDay});

  factory QuestLog.fromJson(Map<String, dynamic> json) => QuestLog(
        completed: {
          for (final MapEntry(:key, :value)
              in (json['completed'] as Map<String, dynamic>? ?? {}).entries)
            if (value is int) key: value,
        },
        lastCompletedDay: json['lastCompletedDay'] as int?,
      );

  /// Times each quest (by id) has been completed.
  final Map<String, int> completed;

  /// The day number ([dayNumber]) the last quest was completed on.
  final int? lastCompletedDay;

  int get total => completed.values.fold(0, (sum, count) => sum + count);

  bool completedOn(DateTime date) => lastCompletedDay == dayNumber(date);

  QuestLog complete(String questId, DateTime date) => QuestLog(
        completed: {...completed, questId: (completed[questId] ?? 0) + 1},
        lastCompletedDay: dayNumber(date),
      );

  Map<String, dynamic> toJson() => {
        'completed': completed,
        'lastCompletedDay': lastCompletedDay,
      };

  @override
  List<Object?> get props => [completed, lastCompletedDay];
}

/// Days since the epoch in local time, so "today" flips at midnight.
int dayNumber(DateTime date) =>
    DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;
