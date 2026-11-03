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

/// The music, in `assets/audio/music/`: a loop per place, and short
/// jingles that play once. A place with no track of its own plays its
/// [fallback]; a track whose file isn't there stays silent.
enum MusicTrack {
  home,
  island,
  islandAlt(file: 'island_alt', fallback: island),
  islandNight(file: 'island_night', fallback: island),
  jungle,
  story,
  challenge,
  battle,
  boss(fallback: battle),
  trekMap(file: 'trek_map', fallback: story),
  trekFernTrail(file: 'trek_fern_trail', fallback: battle),
  trekCanopy(file: 'trek_canopy', fallback: battle),
  trekSwamp(file: 'trek_swamp', fallback: battle),
  trekLake(file: 'trek_lake', fallback: battle),
  trekTemple(file: 'trek_temple', fallback: battle),
  trekGorge(file: 'trek_gorge', fallback: battle),
  questVolcano(file: 'quest_volcano', fallback: story),
  questMoonBeach(file: 'quest_moon_beach', fallback: story),
  questTemple(file: 'quest_temple', fallback: story),
  questSkyIsland(file: 'quest_sky_island', fallback: story),
  introTitle(file: 'intro_title', loop: false),
  introVillage(file: 'intro_village', fallback: story),
  introStorm(file: 'intro_storm', fallback: story),
  introBeach(file: 'intro_beach', fallback: story),
  victory(loop: false),
  defeat(loop: false),
  levelUp(file: 'level_up', loop: false);

  const MusicTrack({String? file, this.fallback, this.loop = true})
      : _file = file;

  final String? _file;

  /// What plays when this track's file is missing.
  final MusicTrack? fallback;
  final bool loop;

  String get asset => 'audio/music/${_file ?? name}.m4a';
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

  /// The switches for all sound effects (the pushup count included) and
  /// all music. Off keeps the volumes for when they come back on.
  bool soundsOn = true;
  bool _musicOn = true;

  final List<AudioPlayer> _players = [];
  int _next = 0;
  AudioPlayer? _music;
  AudioPlayer? _jingle;
  MusicTrack? _track;

  /// While a jingle plays, the music underneath is turned down.
  bool _ducked = false;
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
      _jingle = AudioPlayer(playerId: 'jingle');
      await _jingle!.setReleaseMode(ReleaseMode.stop);
      await AudioCache.instance.loadAll([for (final s in Sfx.values) s.asset]);
    } on Object catch (e) {
      debugPrint('Game audio unavailable: $e');
    }
  }

  /// Plays [sfx], [gain] (0 to 1) times the effects volume. The same effect
  /// is not repeated within 30 ms, so a burst of events doesn't stack up.
  void play(Sfx sfx, {double gain = 1}) {
    if (_players.isEmpty || !soundsOn || sfxVolume == 0) return;
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

  bool get musicOn => _musicOn;

  /// Turns all music off (stopping what plays) or back on (picking up the
  /// current screen's track).
  set musicOn(bool on) {
    if (on == _musicOn) return;
    _musicOn = on;
    final track = _track;
    if (on) {
      _track = null;
      unawaited(music(track));
    } else {
      unawaited(_music?.stop().catchError((Object _) {}));
      unawaited(_jingle?.stop().catchError((Object _) {}));
    }
  }

  double get _musicLevel =>
      (_musicVolume / 10 * 0.6 * (_ducked ? 0.3 : 1)).clamp(0.0, 1.0);

  /// Switches the music to [track] (or the nearest [MusicTrack.fallback]
  /// that has a file), fading the old one out; null stops it.
  Future<void> music(MusicTrack? track) async {
    final player = _music;
    if (player == null || track == _track) return;
    _track = track;
    try {
      await _fade(player, to: 0);
      await player.stop();
      if (track == null || !_musicOn) return;
      final playable = await _playable(track);
      if (playable == null || _track != track) return;
      await player.setReleaseMode(
        playable.loop ? ReleaseMode.loop : ReleaseMode.stop,
      );
      await player.setVolume(0);
      await player.play(AssetSource(playable.asset));
      await _fade(player, to: _musicLevel);
    } on Object catch (e) {
      debugPrint('Music failed: $e');
    }
  }

  /// Plays a short [track] once over the music, which dips meanwhile and
  /// comes back afterwards (a level up during a fight).
  Future<void> jingle(MusicTrack track) async {
    final player = _jingle;
    if (player == null || !_musicOn || _musicVolume == 0) return;
    try {
      final playable = await _playable(track);
      if (playable == null) return;
      _ducked = true;
      await _music?.setVolume(_musicLevel);
      await player.play(
        AssetSource(playable.asset),
        volume: (_musicVolume / 10 * 0.8).clamp(0.0, 1.0),
      );
      await player.onPlayerComplete.first
          .timeout(const Duration(seconds: 12), onTimeout: () {});
    } on Object catch (e) {
      debugPrint('Jingle failed: $e');
    } finally {
      _ducked = false;
      unawaited(_music?.setVolume(_musicLevel).catchError((Object _) {}));
    }
  }

  /// [track], or the first of its fallbacks with a file.
  Future<MusicTrack?> _playable(MusicTrack track) async {
    for (MusicTrack? t = track; t != null; t = t.fallback) {
      if (await _has(t)) return t;
    }
    return null;
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
