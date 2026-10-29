import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/features/social/data/social_backend.dart';
import 'package:pushup_bro/features/social/domain/local_day.dart';
import 'package:pushup_bro/features/social/model/bro_profile.dart';
import 'package:pushup_bro/features/social/model/day_score.dart';

/// Most friends a player can have.
const kMaxBros = 100;

/// A friend (or the player) with today's pushups.
class Bro extends Equatable {
  const Bro({
    required this.profile,
    required this.name,
    required this.today,
    required this.updatedAt,
    this.isMe = false,
  });

  final BroProfile profile;

  /// The name they go by for their friends; empty when they set none, and
  /// the bro name shows instead.
  final String name;
  final int today;
  final DateTime updatedAt;
  final bool isMe;

  String get uid => profile.uid;

  /// As a score, for ranking.
  DayScore get score => DayScore(
        uid: uid,
        count: today,
        broName: profile.broName,
        look: profile.look,
        streak: profile.streak,
        updatedAt: updatedAt,
      );

  @override
  List<Object?> get props => [profile, name, today, updatedAt, isMe];
}

class BrosState extends Equatable {
  const BrosState({this.loaded = false, this.bros = const [], this.me});

  final bool loaded;

  /// Friends, without the player.
  final List<Bro> bros;
  final Bro? me;

  /// Friends and the player.
  List<Bro> get everyone => [...bros, if (me case final me?) me];

  @override
  List<Object?> get props => [loaded, bros, me];
}

/// The player's bros and how many pushups each has done today, live while
/// a screen shows them.
class BrosCubit extends Cubit<BrosState> {
  BrosCubit(
    this._backend, {
    required this.me,
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        super(const BrosState());

  final SocialBackend _backend;
  final BroProfile me;
  final DateTime Function() _clock;

  final Map<String, BroProfile> _profiles = {};
  final Map<String, String> _names = {};
  StreamSubscription<List<String>>? _friends;
  StreamSubscription<List<DayScore>>? _scores;
  List<String> _uids = const [];

  SocialBackend get backend => _backend;

  void start() {
    _friends = _backend.friends(me.uid).listen(
          (uids) => unawaited(_onFriends(uids)),
          onError: (_) => emit(const BrosState(loaded: true)),
        );
  }

  Future<void> _onFriends(List<String> uids) async {
    _uids = uids;
    for (final uid in uids) {
      if (_profiles.containsKey(uid)) continue;
      final profile = await _backend.profile(uid);
      if (profile != null) _profiles[uid] = profile;
      _names[uid] = await _backend.friendName(uid) ?? '';
    }
    await _scores?.cancel();
    _scores =
        _backend.scoresOf(localDayKey(_clock()), [...uids, me.uid]).listen(
      _onScores,
      onError: (_) => _onScores(const []),
    );
  }

  void _onScores(List<DayScore> scores) {
    final byUid = {for (final score in scores) score.uid: score};
    Bro bro(BroProfile profile, {bool isMe = false}) {
      final score = byUid[profile.uid];
      return Bro(
        profile: profile,
        name: isMe ? '' : _names[profile.uid] ?? '',
        today: score?.count ?? 0,
        updatedAt: score?.updatedAt ?? DateTime(2100),
        isMe: isMe,
      );
    }

    emit(
      BrosState(
        loaded: true,
        bros: [
          for (final uid in _uids)
            if (_profiles[uid] case final profile?) bro(profile),
        ],
        me: bro(me, isMe: true),
      ),
    );
  }

  /// A friend's profile, loaded or cached.
  Future<BroProfile?> profileOf(String uid) async {
    final cached = _profiles[uid];
    if (cached != null) return cached;
    final profile = await _backend.profile(uid);
    if (profile != null) _profiles[uid] = profile;
    return profile;
  }

  Future<void> remove(String uid) =>
      _backend.removeFriend(me: me.uid, friend: uid);

  Future<void> block(String uid) => _backend.block(me: me.uid, other: uid);

  @override
  Future<void> close() async {
    await _friends?.cancel();
    await _scores?.cancel();
    await super.close();
  }
}
