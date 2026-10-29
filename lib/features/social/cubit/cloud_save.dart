import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/core/model/shared_preferences_key.dart';
import 'package:pushup_bro/core/provider/db_provider.dart';
import 'package:pushup_bro/features/pro/cubit/pro_cubit.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/model/cloud_backup.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saves 2 minutes after the last change.
const _kSaveAfter = Duration(minutes: 2);

/// The game's preferences that travel with the island. Device settings
/// (volumes, language, tracking mode, appearance, reminders) stay put.
const List<SharedPreferencesKey> backedUpPrefs = [
  SharedPreferencesKey.firstPushupDone,
  SharedPreferencesKey.joined,
  SharedPreferencesKey.firstTimeIslandVisited,
  SharedPreferencesKey.onboardingCompleted,
  SharedPreferencesKey.onboardingAnswers,
  SharedPreferencesKey.trekBestCombo,
];

/// Where a backup comes from and goes back to.
abstract class BackupSource {
  /// Fires when something worth saving changed.
  Stream<void> get changes;

  Future<CloudBackup> collect({required DateTime now});

  /// Replaces the game state with [backup], keeping this iPhone's sets
  /// that aren't in it.
  Future<void> apply(CloudBackup backup);

  /// Pushups done today on this iPhone.
  Future<int> pushupsToday(DateTime now);
}

/// The game's own state: SharedPreferences, the inventory and the sets.
class GameBackupSource implements BackupSource {
  GameBackupSource({
    required this.db,
    required this.dbCubit,
    required this.inventory,
  });

  final DBProvider db;
  final DBCubit dbCubit;
  final GameInventoryCubit inventory;

  @override
  Stream<void> get changes {
    late final StreamController<void> controller;
    final subscriptions = <StreamSubscription<Object?>>[];
    controller = StreamController<void>(
      onListen: () => subscriptions.addAll([
        dbCubit.stream.listen((_) => controller.add(null)),
        inventory.stream.listen((_) => controller.add(null)),
      ]),
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );
    return controller.stream;
  }

  @override
  Future<CloudBackup> collect({required DateTime now}) async {
    final prefs = await SharedPreferences.getInstance();
    final sets = await db.getAllPushupSets();
    return CloudBackup(
      savedAt: now,
      device: 'iPhone',
      prefs: {
        for (final key in backedUpPrefs)
          if (prefs.get(key.name) case final value?) key.name: value,
      },
      inventory: Map<String, dynamic>.from(
        jsonDecode(jsonEncode(await db.getInventory())) as Map,
      ),
      sets: [
        for (final set in sets)
          Map<String, dynamic>.from(jsonDecode(jsonEncode(set)) as Map),
      ],
    );
  }

  @override
  Future<void> apply(CloudBackup backup) async {
    final prefs = await SharedPreferences.getInstance();
    for (final MapEntry(:key, :value) in backup.prefs.entries) {
      switch (value) {
        case final bool v:
          await prefs.setBool(key, v);
        case final int v:
          await prefs.setInt(key, v);
        case final double v:
          await prefs.setDouble(key, v);
        case final String v:
          await prefs.setString(key, v);
      }
    }
    final local = [
      for (final set in await db.getAllPushupSets())
        Map<String, dynamic>.from(jsonDecode(jsonEncode(set)) as Map),
    ];
    final merged = mergeSets(backup.sets, local);
    final current = {for (final set in local) set['id']};
    for (final set in merged) {
      if (!current.contains(set['id'])) {
        await db.addNewPushupSet(PushupSet.fromJson(set));
      }
    }
    if (backup.inventory.isNotEmpty) {
      await inventory.updateInventory(GameInventory.fromJson(backup.inventory));
    }
    await dbCubit.getAllPushupSets();
    await inventory.fetchInventory();
  }

  @override
  Future<int> pushupsToday(DateTime now) async {
    final sets = await db.getAllPushupSets();
    return sets
        .expand((set) => set.pushups)
        .map((p) => p.completedAt?.toLocal())
        .where(
          (at) =>
              at != null &&
              at.year == now.year &&
              at.month == now.month &&
              at.day == now.day,
        )
        .length;
  }
}

/// Saves the island to the cloud for Pro members who connected Apple or
/// Google: 2 minutes after the last change, when the app goes to the
/// background, and on "Sync now".
class CloudSave {
  CloudSave({
    required this.account,
    required this.pro,
    required this.source,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final AccountCubit account;
  final ProCubit pro;
  final BackupSource source;
  final DateTime Function() _clock;

  StreamSubscription<void>? _changes;
  AppLifecycleListener? _lifecycle;
  Timer? _timer;
  bool _saving = false;

  /// Linked, but Pro lapsed: saved data stays, new saves wait.
  bool get paused => account.state.isLinked && !pro.state.isPro;
  bool get canSave =>
      account.state.isLinked && pro.state.isPro && account.state.uid != null;

  void start() {
    _changes = source.changes.listen((_) => _schedule());
    _lifecycle = AppLifecycleListener(
      onHide: () => unawaited(saveNow()),
    );
  }

  void _schedule() {
    if (!canSave) return;
    _timer?.cancel();
    _timer = Timer(_kSaveAfter, () => unawaited(saveNow()));
  }

  /// Saves now if allowed; returns whether it saved.
  Future<bool> saveNow() async {
    if (!canSave || _saving) return false;
    _saving = true;
    _timer?.cancel();
    try {
      final now = _clock();
      final backup = await source.collect(now: now);
      await account.backend.writeBackup(account.state.uid!, backup);
      account.savedAt(now);
      return true;
    } on Object catch (error) {
      debugPrint('Cloud save failed: $error');
      return false;
    } finally {
      _saving = false;
    }
  }

  /// Restores the offered backup, keeping today's local pushups.
  Future<void> restore(CloudBackup backup) async {
    await source.apply(backup);
    account
      ..savedAt(backup.savedAt)
      ..restoreHandled();
  }

  /// "Start fresh": keeps this iPhone's state; the next save overwrites
  /// the backup.
  Future<void> startFresh() async {
    account.restoreHandled();
    await saveNow();
  }

  Future<void> dispose() async {
    _timer?.cancel();
    _lifecycle?.dispose();
    await _changes?.cancel();
  }
}
