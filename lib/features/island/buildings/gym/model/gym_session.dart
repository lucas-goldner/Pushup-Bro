import 'dart:math' as math;

import 'package:pushup_bro/features/island/buildings/gym/model/gym_challenge.dart';

/// What happened to a pushup in a gym workout.
enum RepVerdict {
  /// It counts towards the set.
  counted,

  /// Rushed: a tempo set wants a slower way down.
  tooFast,

  /// Done in a rest or a plank, or after a minute's reps were done.
  ignored,
}

/// A gym workout as it's played: which block is on, the pushups in it and
/// which sets were passed. Time is in seconds since the workout started;
/// the page feeds it every [tick] and every pushup through [rep], so the
/// rules can be tested without a clock.
class GymSession {
  GymSession(this.challenge)
      : results = List.filled(challenge.blocks.length, null);

  final GymChallenge challenge;

  /// Per block: whether a rep block was passed, null while it's unsettled
  /// (or for rests and planks).
  final List<bool?> results;

  int _block = 0;
  double _blockStart = 0;
  int _blockReps = 0;
  int _counted = 0;
  int _rushed = 0;
  double? _lastRepAt;
  bool _finished = false;

  /// The block that's on (`blocks.length` once finished).
  int get blockIndex => _block;
  GymBlock? get block =>
      _block < challenge.blocks.length ? challenge.blocks[_block] : null;

  /// When the current block started.
  double get blockStart => _blockStart;

  /// Pushups counted in the current block.
  int get blockReps => _blockReps;

  /// Pushups counted towards the workout, all told.
  int get counted => _counted;

  /// Tempo reps that were too quick.
  int get rushed => _rushed;
  double? get lastRepAt => _lastRepAt;
  bool get finished => _finished;

  int get passed => results.where((result) => result ?? false).length;
  int get failed => results.where((result) => result == false).length;
  bool get won => passed >= challenge.passMark;

  /// Which rep block is on or next (0-based), and how many there are.
  int get setIndex {
    var index = 0;
    for (var i = 0; i < math.min(_block, challenge.blocks.length); i++) {
      if (challenge.blocks[i] is RepBlock) index++;
    }

    return math.min(index, challenge.repBlocks.length - 1);
  }

  /// The rep block that's on, or the next one during a rest or plank.
  RepBlock? get currentSet {
    for (var i = _block; i < challenge.blocks.length; i++) {
      final block = challenge.blocks[i];
      if (block is RepBlock) return block;
    }

    return null;
  }

  /// Whether the current rep block's reps are done (resting out a minute).
  bool get blockDone => results[math.min(_block, results.length - 1)] ?? false;

  /// Seconds left of the current block's clock, if it has one.
  double? remaining(double now) {
    final seconds = switch (block) {
      RestBlock(:final seconds) || PlankBlock(:final seconds) => seconds,
      RepBlock(:final window) => window,
      null => null,
    };

    return seconds == null
        ? null
        : math.max(0, seconds - (now - _blockStart)).toDouble();
  }

  /// Seconds left before an idle set ends, once it's close.
  double? idleLeft(double now) {
    final cutoff = challenge.idleCutoff;
    final last = _lastRepAt;
    if (cutoff == null || last == null || _finished) return null;

    return math.max(0, cutoff - (now - last)).toDouble();
  }

  /// Moves the clock to [now]: rests, planks and windows run out.
  void tick(double now) {
    while (!_finished) {
      final elapsed = now - _blockStart;
      switch (block) {
        case RestBlock(:final seconds) || PlankBlock(:final seconds):
          if (elapsed < seconds) return;
          _advance(_blockStart + seconds);
        case final RepBlock set:
          final window = set.window;
          final idle = idleLeft(now);
          if (window != null && elapsed >= window) {
            results[_block] ??= _blockReps >= set.reps;
            _advance(_blockStart + window);
          } else if (idle != null && idle <= 0) {
            finish();
          } else {
            return;
          }
        case null:
          _finished = true;
      }
      _giveUpIfLost();
    }
  }

  /// A pushup at [now] that took [downSeconds] on the way down.
  RepVerdict rep(double now, {double downSeconds = 0}) {
    tick(now);
    final set = block;
    if (_finished || set is! RepBlock) return RepVerdict.ignored;
    if (set.holdWindow && blockDone) return RepVerdict.ignored;
    final tempo = challenge.tempoSeconds;
    if (tempo != null && downSeconds < tempo) {
      _rushed++;

      return RepVerdict.tooFast;
    }
    _blockReps++;
    _counted++;
    _lastRepAt = now;
    if (_blockReps >= set.reps && results[_block] == null) {
      results[_block] = true;
      final last = _block == challenge.blocks.length - 1;
      if (!set.openEnded && (!set.holdWindow || last)) _advance(now);
    }

    return RepVerdict.counted;
  }

  /// Stops the workout: the set that's on is settled as it stands.
  void finish() {
    if (_finished) return;
    final set = block;
    if (set is RepBlock) results[_block] ??= _blockReps >= set.reps;
    for (var i = _block + 1; i < challenge.blocks.length; i++) {
      if (challenge.blocks[i] is RepBlock) results[i] = false;
    }
    _finished = true;
  }

  void _advance(double at) {
    _block++;
    _blockStart = at;
    _blockReps = 0;
    if (_block >= challenge.blocks.length) _finished = true;
  }

  /// Once too many sets are missed to win, there's no point going on.
  void _giveUpIfLost() {
    if (_finished) return;
    if (failed > challenge.repBlocks.length - challenge.passMark) finish();
  }
}
