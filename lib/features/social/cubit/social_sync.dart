import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/cubit/account_state.dart';
import 'package:pushup_bro/features/social/domain/local_day.dart';
import 'package:pushup_bro/features/social/model/day_score.dart';
import 'package:pushup_bro/features/widgets/widget_snapshot.dart';

/// Today's pushups on one iPhone, capped like the rules (1500 a day).
int pushupsOn(List<PushupSet> sets, DateTime day) {
  final key = localDayKey(day);
  var count = 0;
  for (final set in sets) {
    for (final pushup in set.pushups) {
      final at = pushup.completedAt;
      if (at != null && localDayKey(at) == key) count++;
    }
  }
  return count.clamp(0, 1500);
}

/// The island's level as friends see it: one for every building.
int islandLevelOf(GameInventory inventory) => 1 + inventory.boughtItems.length;

/// Keeps what friends see in step with the game: today's score after every
/// set, and the profile (look, streak, total, island level).
class SocialSync {
  SocialSync({
    required this.account,
    required this.db,
    required this.inventory,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AccountCubit account;
  final DBCubit db;
  final GameInventoryCubit inventory;
  final DateTime Function() _clock;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  /// The last count written, so a set that didn't change today isn't
  /// written again.
  int? _written;
  String? _writtenDay;

  void start() {
    _subscriptions.addAll([
      db.stream.listen((_) => unawaited(sync())),
      inventory.stream.listen((_) => unawaited(sync())),
      account.stream
          .where((state) => state.status == AccountStatus.ready)
          .listen((_) => unawaited(sync())),
    ]);
  }

  Future<void> sync() async {
    final state = account.state;
    final profile = state.profile;
    if (state.status != AccountStatus.ready || profile == null) return;
    final now = _clock();
    final sets = db.state.pushupSets;
    final inv = inventory.state.inventory;
    final streak = workoutStreaks(sets, now).current;
    final look = inv.monkeys.isEmpty ? profile.look : inv.monkeys.first.look;
    await account.updateProfile(
      look: look,
      streak: streak,
      total: sets.fold<int>(0, (sum, set) => sum + set.pushups.length),
      islandLevel: islandLevelOf(inv),
    );
    final day = localDayKey(now);
    final count = pushupsOn(sets, now);
    if (count == 0 || (count == _written && day == _writtenDay)) return;
    try {
      await account.backend.writeScore(
        day,
        DayScore(
          uid: profile.uid,
          count: count,
          broName: profile.broName,
          look: look,
          streak: streak,
          public: profile.showOnEveryone,
          updatedAt: now,
        ),
      );
      _written = count;
      _writtenDay = day;
    } on Object catch (error) {
      debugPrint('Score not written: $error');
    }
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
  }
}
