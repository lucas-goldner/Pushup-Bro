import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/cubit/account_state.dart';
import 'package:pushup_bro/features/social/data/push_service.dart';

/// The languages the Cloud Function writes notifications in.
const _kLanguages = {'en', 'de', 'es', 'ja', 'pt'};

/// Registers this iPhone for push notifications from bros once the player
/// has one (that's when iOS asks), and keeps the token and language on the
/// account up to date.
class BroPush {
  BroPush({
    required this.account,
    required this.push,
    required String Function() language,
  }) : _language = language;

  final AccountCubit account;
  final PushService push;
  final String Function() _language;
  final List<StreamSubscription<Object?>> _subscriptions = [];

  /// What's registered: for whom, which token, in which language.
  String? _uid;
  String? _token;
  String? _registeredLanguage;
  Future<void>? _running;

  /// The account being signed out of, which mustn't be registered again.
  String? _leaving;

  /// Where tapped notifications lead.
  Stream<String> get opened => push.opened;

  void start() {
    _subscriptions.addAll([
      account.stream.listen((_) => unawaited(update())),
      push.tokenRefresh.listen((token) {
        _token = token;
        _registeredLanguage = null;
        unawaited(update());
      }),
    ]);
    unawaited(update());
  }

  /// Registers or refreshes this iPhone, when there's a bro to hear from.
  Future<void> update() async {
    // One at a time; the last change is picked up by running again.
    while (_running != null) {
      await _running;
    }
    final running = _register();
    _running = running;
    try {
      await running;
    } finally {
      if (identical(_running, running)) _running = null;
    }
  }

  Future<void> _register() async {
    final state = account.state;
    final profile = state.profile;
    if (state.status != AccountStatus.ready || profile == null) return;
    if (profile.friendCount == 0 || profile.uid == _leaving) return;
    final token = _token ?? await push.enable();
    if (token == null) return;
    _token = token;
    final wanted = _language();
    final language = _kLanguages.contains(wanted) ? wanted : 'en';
    if (profile.uid == _uid && language == _registeredLanguage) return;
    try {
      await account.backend.saveDevice(
        profile.uid,
        token: token,
        language: language,
      );
      _uid = profile.uid;
      _registeredLanguage = language;
    } on Object catch (error) {
      debugPrint('Push token not saved: $error');
    }
  }

  /// Before signing out: this iPhone stops hearing about the old account.
  Future<void> forget() async {
    final uid = _uid;
    final token = _token;
    _leaving = uid;
    _uid = null;
    _registeredLanguage = null;
    if (uid == null || token == null) return;
    try {
      await account.backend.removeDevice(uid, token);
    } on Object catch (error) {
      debugPrint('Push token not removed: $error');
    }
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
  }
}
