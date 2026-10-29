import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/model/shared_preferences_key.dart';
import 'package:pushup_bro/core/provider/shared_preferences_interface.dart';
import 'package:pushup_bro/features/social/cubit/account_state.dart';
import 'package:pushup_bro/features/social/data/social_backend.dart';
import 'package:pushup_bro/features/social/domain/bro_name.dart';
import 'package:pushup_bro/features/social/domain/friend_code.dart';
import 'package:pushup_bro/features/social/model/bro_profile.dart';

/// How often a new code is tried when the random one is taken.
const _kCodeAttempts = 8;

/// The player's account: an anonymous one from the first launch, with a
/// generated bro name and a friend code. Pro members can connect Apple or
/// Google to keep it (and their saved island) on a new iPhone.
class AccountCubit extends Cubit<AccountState> {
  AccountCubit(
    this._backend,
    this._prefs, {
    math.Random? random,
    Duration timeout = const Duration(seconds: 12),
  })  : _random = random ?? math.Random.secure(),
        _timeout = timeout,
        super(const AccountState());

  final SocialBackend _backend;
  final SharedPreferencesInterface _prefs;
  final math.Random _random;
  final Duration _timeout;

  /// Called with the uid after Apple or Google is connected or a saved
  /// account is signed in to; ties Pro to it.
  void Function(String uid)? onSignedIn;

  /// Called before signing out, while the old account can still be
  /// written to.
  Future<void> Function()? beforeSignOut;

  SocialBackend get backend => _backend;

  /// Signs in (anonymously the first time) and loads or creates the
  /// profile with [look]. Without a connection it stays offline and can
  /// be retried.
  Future<void> start({MonkeyLook look = const MonkeyLook()}) async {
    emit(state.copyWith(status: AccountStatus.starting));
    try {
      final uid = await _backend.ensureSignedIn().timeout(_timeout);
      final profile = await _profileFor(uid, look).timeout(_timeout);
      final friendName = await _backend.friendName(uid) ?? '';
      final saved = await _prefs.getSharedPrefString(
        SharedPreferencesKey.cloudSavedAt,
      );
      emit(
        state.copyWith(
          status: AccountStatus.ready,
          profile: profile,
          linked: _backend.linkedProviders,
          friendName: friendName,
          savedAt: DateTime.tryParse(saved ?? ''),
        ),
      );
    } on Object catch (error) {
      debugPrint('Account offline: $error');
      emit(state.copyWith(status: AccountStatus.offline));
    }
  }

  /// The stored profile, or a new one with a fresh name and code.
  Future<BroProfile> _profileFor(String uid, MonkeyLook look) async {
    final stored = await _backend.profile(uid);
    if (stored != null && stored.code.isNotEmpty) return stored;
    final code = await _claimCode(uid);
    final profile = BroProfile(
      uid: uid,
      broName: BroName.random(_random),
      code: code,
      look: look,
    );
    await _backend.saveProfile(profile);
    return profile;
  }

  Future<String> _claimCode(String uid) async {
    for (var attempt = 0; attempt < _kCodeAttempts; attempt++) {
      final code = FriendCode.generate(_random);
      if (await _backend.claimCode(code, uid)) return code;
    }
    throw StateError('No free friend code');
  }

  /// Keeps what friends see in step with the game, at most every few
  /// seconds of changes.
  Future<void> updateProfile({
    MonkeyLook? look,
    int? streak,
    int? total,
    int? islandLevel,
    int? friendCount,
    Map<String, dynamic>? island,
  }) async {
    final profile = state.profile;
    if (profile == null) return;
    final updated = profile.copyWith(
      look: look,
      streak: streak,
      total: total,
      islandLevel: islandLevel,
      friendCount: friendCount,
      island: island,
    );
    if (updated == profile) return;
    emit(state.copyWith(profile: updated));
    try {
      await _backend.saveProfile(updated);
    } on Object catch (error) {
      // Firestore queues it offline; anything else waits for the next one.
      debugPrint('Profile not saved: $error');
    }
  }

  Future<void> setShowOnEveryone({required bool show}) =>
      updateProfileVisibility(show: show);

  Future<void> updateProfileVisibility({required bool show}) async {
    final profile = state.profile;
    if (profile == null) return;
    final updated = profile.copyWith(showOnEveryone: show);
    emit(state.copyWith(profile: updated));
    await _backend.saveProfile(updated);
  }

  Future<void> setFriendName(String name) async {
    final uid = state.uid;
    if (uid == null) return;
    final trimmed = name.trim();
    emit(state.copyWith(friendName: trimmed));
    await _backend.setFriendName(uid, trimmed);
  }

  // Connecting Apple or Google.

  /// Connects [provider]. If that account already has an island from
  /// another iPhone, signs in to it and offers to restore it.
  Future<LinkOutcome> link(SignInProvider provider) async {
    final outcome = await _backend.link(provider);
    await _after(outcome);
    return outcome;
  }

  /// On a new iPhone: signs in with [provider] to find a saved island.
  Future<LinkOutcome> signInToRestore(SignInProvider provider) async {
    final outcome = await _backend.signInWith(provider);
    await _after(outcome);
    return outcome;
  }

  Future<void> _after(LinkOutcome outcome) async {
    switch (outcome) {
      case Linked():
        emit(state.copyWith(linked: _backend.linkedProviders));
        await _prefs.writeStringToSharedPrefs(
          SharedPreferencesKey.accountUpgradePromptPending,
          'false',
        );
        onSignedIn?.call(state.uid!);
      case SwitchedAccount(:final uid, :final leftoverFriends):
        final profile = await _backend.profile(uid) ??
            BroProfile(
              uid: uid,
              broName: BroName.random(_random),
              code: await _claimCode(uid),
              look: state.profile?.look ?? const MonkeyLook(),
            );
        await _readd(uid, leftoverFriends);
        final backup = await _backend.readBackup(uid);
        emit(
          state.copyWith(
            profile: profile,
            linked: _backend.linkedProviders,
            friendName: await _backend.friendName(uid) ?? '',
            restore: backup == null ? null : RestoreOffer(backup),
          ),
        );
        onSignedIn?.call(uid);
      case LinkCancelled() || LinkFailed():
        break;
    }
  }

  /// Friends made on the leftover anonymous account, added again.
  Future<void> _readd(String uid, List<String> friends) async {
    for (final friend in friends) {
      final their = await _backend.profile(friend);
      if (their == null) continue;
      try {
        await _backend.addFriend(me: uid, friend: friend, code: their.code);
      } on Object catch (error) {
        debugPrint('Friend not moved: $error');
      }
    }
  }

  /// The restore screen is done (restored or started fresh).
  void restoreHandled() => emit(state.copyWith(clearRestore: true));

  void savedAt(DateTime time) {
    emit(state.copyWith(savedAt: time));
    unawaited(
      _prefs.writeStringToSharedPrefs(
        SharedPreferencesKey.cloudSavedAt,
        time.toIso8601String(),
      ),
    );
  }

  /// Back to a fresh anonymous account; progress on this iPhone stays.
  Future<void> signOut({MonkeyLook look = const MonkeyLook()}) async {
    await beforeSignOut?.call();
    await _backend.signOut();
    emit(const AccountState());
    await start(look: look);
  }

  /// Deletes the account and everything saved for it on the server, then
  /// starts over anonymously. Progress on this iPhone stays.
  Future<void> deleteAccount({MonkeyLook look = const MonkeyLook()}) async {
    await _backend.deleteAccount();
    await _prefs.writeStringToSharedPrefs(
      SharedPreferencesKey.cloudSavedAt,
      '',
    );
    emit(const AccountState());
    await start(look: look);
  }

  // The "Never lose your island" prompt.

  /// Pro just started from a purchase or restore: offer to save the
  /// account the next time the player opens Home or the Island.
  Future<void> markUpgradePrompt() => _prefs.writeStringToSharedPrefs(
        SharedPreferencesKey.accountUpgradePromptPending,
        'true',
      );

  /// Whether to show the prompt now; at most once, never once connected.
  Future<bool> shouldPromptUpgrade() async {
    if (state.isLinked || state.status != AccountStatus.ready) return false;
    final pending = await _prefs.getSharedPrefString(
      SharedPreferencesKey.accountUpgradePromptPending,
    );
    final shown = await _prefs.getSharedPrefString(
      SharedPreferencesKey.accountUpgradePromptShown,
    );
    return pending == 'true' && shown != 'true';
  }

  /// The prompt was shown; it stays in Settings, Account.
  Future<void> upgradePromptShown() async {
    await _prefs.writeStringToSharedPrefs(
      SharedPreferencesKey.accountUpgradePromptShown,
      'true',
    );
    await _prefs.writeStringToSharedPrefs(
      SharedPreferencesKey.accountUpgradePromptPending,
      'false',
    );
  }
}
