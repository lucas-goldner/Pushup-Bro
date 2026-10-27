import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';

/// Plays [track] while this screen is the newest one showing; when it goes
/// away, the screen beneath it gets its music back.
class MusicScope extends StatefulWidget {
  const MusicScope({required this.track, required this.child, super.key});

  final MusicTrack? track;
  final Widget child;

  /// Changes the music of the screen around [context] (e.g. as a quest goes
  /// from its story to its challenge).
  static void set(BuildContext context, MusicTrack? track) =>
      context.findAncestorStateOfType<_MusicScopeState>()?._set(track);

  @override
  State<MusicScope> createState() => _MusicScopeState();
}

class _MusicScopeState extends State<MusicScope> {
  /// The screens with music, oldest first.
  static final _scopes = <_MusicScopeState>[];

  /// What the screen asked for since, over [MusicScope.track].
  MusicTrack? _override;
  bool _overridden = false;

  MusicTrack? get _track => _overridden ? _override : widget.track;

  void _set(MusicTrack? track) {
    if (_overridden && track == _override) return;
    _override = track;
    _overridden = true;
    if (_scopes.last == this) _play();
  }

  @override
  void initState() {
    super.initState();
    _scopes.add(this);
    _play();
  }

  @override
  void didUpdateWidget(MusicScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track != widget.track && _scopes.last == this) _play();
  }

  @override
  void dispose() {
    _scopes.remove(this);
    if (_scopes.isEmpty) {
      unawaited(GameAudio.instance.music(null));
    } else {
      _scopes.last._play();
    }
    super.dispose();
  }

  void _play() => unawaited(GameAudio.instance.music(_track));

  @override
  Widget build(BuildContext context) => widget.child;
}
