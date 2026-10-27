import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The game's sound effects, in `assets/audio/sfx/`.
enum Sfx {
  tap,
  pop,
  whoosh,
  banana,
  purchase,
  equip,
  levelUp('level_up'),
  star,
  victory,
  defeat,
  hitNormal('hit_normal'),
  hitHeld('hit_held'),
  hitQuick('hit_quick'),
  superEffective('super'),
  crit,
  weak,
  enemyAttack('enemy_attack'),
  hurt,
  defeatEnemy('defeat_enemy'),
  waveClear('wave_clear'),
  fight,
  rest,
  ready,
  tick,
  blip,
  next,
  roar,
  splash,
  hold,
  combo,
  unlock,
  questComplete('quest_complete');

  const Sfx([this._file]);

  final String? _file;

  String get asset => 'audio/sfx/${_file ?? name}.m4a';
}

/// The music, one loop per place (and a jingle), in `assets/audio/music/`.
/// A track whose file isn't there yet simply stays silent.
enum MusicTrack {
  home,
  island,
  jungle,
  story,
  challenge,
  battle,
  boss,
  victory(loop: false);

  const MusicTrack({this.loop = true});

  final bool loop;

  String get asset => 'audio/music/$name.mp3';
}

/// Plays the game's sound effects and music, at the volumes from the
/// settings (0 to 10 each).
///
/// Effects play on a small round robin of players so they can overlap;
/// music plays on its own player and crossfades from track to track.
class GameAudio {
  GameAudio._();

  static final instance = GameAudio._();

  static const _voices = 6;

  /// Effects volume and music volume, 0 to 10.
  int sfxVolume = 10;
  int _musicVolume = 7;

  final List<AudioPlayer> _players = [];
  int _next = 0;
  AudioPlayer? _music;
  MusicTrack? _track;
  final Map<MusicTrack, bool> _available = {};
  final Map<Sfx, DateTime> _lastPlayed = {};

  /// Sets up the players and preloads the effects. Safe to skip (tests):
  /// nothing plays until it's done.
  Future<void> init() async {
    try {
      for (var i = 0; i < _voices; i++) {
        final player = AudioPlayer(playerId: 'sfx$i');
        await player.setReleaseMode(ReleaseMode.stop);
        _players.add(player);
      }
      _music = AudioPlayer(playerId: 'music');
      await AudioCache.instance.loadAll([for (final s in Sfx.values) s.asset]);
    } on Object catch (e) {
      debugPrint('Game audio unavailable: $e');
    }
  }

  /// Plays [sfx], [gain] (0 to 1) times the effects volume. The same effect
  /// is not repeated within 30 ms, so a burst of events doesn't stack up.
  void play(Sfx sfx, {double gain = 1}) {
    if (_players.isEmpty || sfxVolume == 0) return;
    final now = DateTime.now();
    final last = _lastPlayed[sfx];
    if (last != null && now.difference(last).inMilliseconds < 30) return;
    _lastPlayed[sfx] = now;
    final player = _players[_next];
    _next = (_next + 1) % _players.length;
    unawaited(
      player
          .play(
            AssetSource(sfx.asset),
            volume: (gain * sfxVolume / 10).clamp(0.0, 1.0),
            mode: PlayerMode.lowLatency,
          )
          .catchError((Object _) {}),
    );
  }

  /// Plays [sfx] [times] times, [gap] apart (e.g. one per star).
  void playRepeated(
    Sfx sfx,
    int times, {
    Duration gap = const Duration(
      milliseconds: 280,
    ),
  }) {
    for (var i = 0; i < times; i++) {
      Future<void>.delayed(gap * i, () => play(sfx));
    }
  }

  int get musicVolume => _musicVolume;
  set musicVolume(int value) {
    _musicVolume = value;
    unawaited(_music?.setVolume(_musicLevel).catchError((Object _) {}));
  }

  double get _musicLevel => (_musicVolume / 10 * 0.6).clamp(0.0, 1.0);

  /// Switches the music to [track], fading the old one out; null stops it.
  Future<void> music(MusicTrack? track) async {
    final player = _music;
    if (player == null || track == _track) return;
    _track = track;
    try {
      await _fade(player, to: 0);
      await player.stop();
      if (track == null || !await _has(track) || _track != track) return;
      await player.setReleaseMode(
        track.loop ? ReleaseMode.loop : ReleaseMode.stop,
      );
      await player.setVolume(0);
      await player.play(AssetSource(track.asset));
      await _fade(player, to: _musicLevel);
    } on Object catch (e) {
      debugPrint('Music failed: $e');
    }
  }

  Future<void> _fade(AudioPlayer player, {required double to}) async {
    final from = player.volume;
    const steps = 8;
    for (var i = 1; i <= steps; i++) {
      await player.setVolume(from + (to - from) * i / steps);
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
  }

  Future<bool> _has(MusicTrack track) async =>
      _available[track] ??= await rootBundle
          .load('assets/${track.asset}')
          .then((_) => true, onError: (Object _) => false);
}
