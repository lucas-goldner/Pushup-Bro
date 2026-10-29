import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/features/social/data/social_backend.dart';
import 'package:pushup_bro/features/social/domain/local_day.dart';
import 'package:pushup_bro/features/social/domain/ranking.dart';
import 'package:pushup_bro/features/social/model/day_score.dart';

/// The Everyone board refreshes this often while open.
const _kRefresh = Duration(seconds: 60);

/// The player count is asked for at most this often.
const _kCountFor = Duration(minutes: 10);

class EveryoneState extends Equatable {
  const EveryoneState({
    this.loaded = false,
    this.top = const [],
    this.myRank,
    this.players = 0,
  });

  final bool loaded;

  /// Today's top 50, without anyone the player blocked.
  final List<DayScore> top;

  /// The player's place, when they did pushups today.
  final int? myRank;
  final int players;

  @override
  List<Object?> get props => [loaded, top, myRank, players];
}

/// Today's top 50 of everyone, the player's own rank and how many play.
class EveryoneCubit extends Cubit<EveryoneState> {
  EveryoneCubit(
    this._backend, {
    required this.uid,
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        super(const EveryoneState());

  final SocialBackend _backend;
  final String uid;
  final DateTime Function() _clock;
  Timer? _timer;

  static ({String day, int count, DateTime at})? _players;

  void start() {
    unawaited(refresh());
    _timer = Timer.periodic(_kRefresh, (_) => unawaited(refresh()));
  }

  Future<void> refresh() async {
    final now = _clock();
    final day = localDayKey(now);
    try {
      final blocked = (await _backend.blocked(uid).first).toSet();
      final top = rank(
        (await _backend.topScores(day).first)
            .where((score) => !blocked.contains(score.uid)),
      );
      final mine = (await _backend.scoresOf(day, [uid]).first).firstOrNull;
      final above = mine == null || mine.count == 0
          ? null
          : await _backend.countAbove(day, mine.count);
      final cached = _players;
      final players = cached != null &&
              cached.day == day &&
              now.difference(cached.at) < _kCountFor
          ? cached.count
          : await _backend.playerCount(day);
      _players = (day: day, count: players, at: now);
      if (isClosed) return;
      emit(
        EveryoneState(
          loaded: true,
          top: top,
          myRank: above == null ? null : above + 1,
          players: players,
        ),
      );
    } on Object {
      if (!isClosed) emit(const EveryoneState(loaded: true));
    }
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    await super.close();
  }
}
