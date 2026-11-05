import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/audio/music_scope.dart';
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/model/tracking_mode.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/one_move.dart';
import 'package:pushup_bro/features/island/buildings/gym/model/gym_challenge.dart';
import 'package:pushup_bro/features/island/buildings/gym/model/gym_reward.dart';
import 'package:pushup_bro/features/island/buildings/gym/model/gym_session.dart';
import 'package:pushup_bro/features/island/buildings/gym/widgets/gym_coach_stage.dart';
import 'package:pushup_bro/features/island/buildings/gym/widgets/gym_hud.dart';
import 'package:pushup_bro/features/island/buildings/gym/widgets/gym_result.dart';
import 'package:pushup_bro/features/pushup_tracking/camera/camera_tracker.dart';
import 'package:pushup_bro/features/pushup_tracking/camera/camera_window.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/airpods_tracker_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/airpods_tracker_state.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/pushup_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/pushup_state.dart';

/// How often Gus shouts something new while Carlos works.
const _kCoachEvery = Duration(seconds: 7);

/// Seconds of "get ready" before the clock starts.
const _kCountdown = 3;

/// A gym workout in the home gym, with Grandpa Gus as coach: Start, a
/// countdown, the workout tracked by AirPods or the camera with its own
/// HUD, then the rewards. The pushups are saved like any other set. Pops
/// with true when the workout was won.
class GymChallengePage extends StatefulWidget {
  const GymChallengePage({
    required this.challenge,
    this.replay = false,
    super.key,
  });

  final GymChallenge challenge;

  /// Today's is already won: a banana a pushup, nothing more.
  final bool replay;

  @override
  State<GymChallengePage> createState() => _GymChallengePageState();
}

class _GymChallengePageState extends State<GymChallengePage> with OneMove {
  late final GymSession _session = GymSession(widget.challenge);

  /// Counting pushups: from Start (so AirPods can connect in the
  /// countdown) until the end.
  bool _tracking = false;
  int? _countdown;
  bool _running = false;
  DateTime? _startedAt;
  double _now = 0;
  Timer? _clock;
  StreamSubscription<PushupState>? _pushupSubscription;
  int? _volume;

  // The rep on its way down, and the last count seen.
  DateTime? _downAt;
  int _seen = 0;
  DateTime? _rushedUntil;

  String? _coach;
  int _coachCount = 0;
  DateTime _coachAt = DateTime.now();

  // The ending.
  GymReward? _reward;
  bool _won = false;
  int _pushups = 0;

  bool _white = true;
  bool _closing = false;

  GymChallenge get _challenge => widget.challenge;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _white = false);
    });
    unawaited(
      context
          .read<SharedPreferencesCubit>()
          .getVolume()
          .then((volume) => _volume = volume),
    );
  }

  @override
  void dispose() {
    _clock?.cancel();
    unawaited(_pushupSubscription?.cancel());
    super.dispose();
  }

  void _start() {
    // The camera counts on its own; only AirPods need their stream.
    if (context.read<SharedPreferencesCubit>().state.trackingMode ==
        TrackingMode.airpods) {
      context.read<AirPodsTrackerCubit>().getAirPodsMotionData();
    }
    GameAudio.instance.play(Sfx.ready);
    setState(() {
      _tracking = true;
      _countdown = _kCountdown;
    });
    _clock = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final next = (_countdown ?? 0) - 1;
      if (next < 0) {
        timer.cancel();
        _go();
      } else {
        GameAudio.instance.play(next == 0 ? Sfx.fight : Sfx.tick);
        setState(() => _countdown = next);
      }
    });
  }

  /// The countdown is over: the clock starts and pushups count.
  void _go() {
    final pushupCubit = context.read<PushupCubit>()
      ..resetAndReturnCurrentPushupSet();
    _seen = 0;
    _pushupSubscription = pushupCubit.stream.listen(_onPushupState);
    _startedAt = DateTime.now();
    _coachAt = DateTime.now();
    setState(() {
      _countdown = null;
      _running = true;
      _coach = gymCoachLines(context.l10n).first;
    });
    _clock = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
  }

  double get _elapsed {
    final started = _startedAt;

    return started == null
        ? 0
        : DateTime.now().difference(started).inMilliseconds / 1000;
  }

  void _tick() {
    if (!mounted || !_running) return;
    final now = _elapsed;
    final blockBefore = _session.blockIndex;
    final leftBefore = _session.remaining(_now)?.ceil();
    _session.tick(now);
    final leftNow = _session.remaining(now)?.ceil();
    if (_session.blockIndex != blockBefore) {
      _onBlockChange(blockBefore);
    } else if (leftNow != null &&
        leftNow != leftBefore &&
        leftNow <= 3 &&
        leftNow > 0) {
      GameAudio.instance.play(Sfx.tick);
    }
    if (DateTime.now().difference(_coachAt) >= _kCoachEvery &&
        _session.block is RepBlock) {
      final lines = gymCoachLines(context.l10n);
      _coachAt = DateTime.now();
      _coach = lines[++_coachCount % lines.length];
    }
    setState(() => _now = now);
    if (_session.finished) unawaited(_finish());
  }

  void _onBlockChange(int previous) {
    final l = context.l10n;
    final missed = previous < _session.results.length &&
        _session.results[previous] == false;
    if (missed) GameAudio.instance.play(Sfx.hurt);
    _coachAt = DateTime.now();
    switch (_session.block) {
      case RestBlock():
        if (!missed) GameAudio.instance.play(Sfx.rest);
        _coach = l.gymRest;
      case PlankBlock():
        GameAudio.instance.play(Sfx.hold);
        _coach = l.gymPlank;
      case final RepBlock set:
        GameAudio.instance.play(Sfx.next);
        _coach = l.gymUpNext(set.reps);
      case null:
        break;
    }
  }

  void _onPushupState(PushupState state) {
    if (!_running) return;
    if (state.inPushup) _downAt ??= DateTime.now();
    if (state.pushups.length > _seen) {
      _seen = state.pushups.length;
      final down = _downAt;
      final downSeconds = down == null
          ? 0.0
          : DateTime.now().difference(down).inMilliseconds / 1000;
      final block = _session.blockIndex;
      final verdict = _session.rep(_elapsed, downSeconds: downSeconds);
      if (verdict == RepVerdict.tooFast) {
        GameAudio.instance.play(Sfx.weak);
        _rushedUntil = DateTime.now().add(const Duration(milliseconds: 1500));
      } else if (verdict == RepVerdict.counted) {
        final best = _challenge.best;
        if (block < _session.results.length &&
            (_session.results[block] ?? false) &&
            _session.blockIndex != block) {
          GameAudio.instance.play(Sfx.combo);
        } else if (best > 0 && _session.counted == best + 1) {
          GameAudio.instance.play(Sfx.star);
        }
        if (_session.blockIndex != block) _onBlockChange(block);
      }
      setState(() {});
      if (_session.finished) unawaited(_finish());
    }
    if (!state.inPushup) _downAt = null;
  }

  Future<void> _finish() async {
    if (!_tracking) return;
    _tracking = false;
    _running = false;
    _clock?.cancel();
    unawaited(_pushupSubscription?.cancel());
    _session.finish();
    final airpods = context.read<AirPodsTrackerCubit>()..stopListening();
    final dbCubit = context.read<DBCubit>();
    final inventoryCubit = context.read<GameInventoryCubit>();
    final set = context.read<PushupCubit>().resetAndReturnCurrentPushupSet();
    final won = _session.won;

    // Keep the set and the rewards even if the ending is skipped.
    if (set.pushups.isNotEmpty) await dbCubit.writeNewPushupsetToDB(set);
    await inventoryCubit.fetchInventory();
    final reward = GymReward.settle(
      inventory: inventoryCubit.state.inventory,
      challenge: _challenge,
      pushups: set.pushups.length,
      won: won,
      replay: widget.replay,
      now: DateTime.now(),
    );
    await inventoryCubit.updateInventory(reward.inventory);
    airpods.stopListening();
    if (!mounted) return;
    GameAudio.instance.play(won ? Sfx.questComplete : Sfx.defeat, gain: 1.2);
    if (reward.gift != null || reward.crate > 0) {
      GameAudio.instance.play(Sfx.unlock);
    }
    setState(() {
      _won = won;
      _pushups = set.pushups.length;
      _reward = reward;
    });
  }

  Future<void> _leave() => oneMove(() async {
        if (_tracking) {
          _tracking = false;
          _running = false;
          _clock?.cancel();
          unawaited(_pushupSubscription?.cancel());
          context.read<AirPodsTrackerCubit>().stopListening();
          context.read<PushupCubit>().resetAndReturnCurrentPushupSet();
        }
        GameAudio.instance.play(Sfx.whoosh);
        // The camera shuts down first, while this screen is still up.
        setState(() {
          _white = true;
          _closing = true;
        });
        await Future<void>.delayed(const Duration(milliseconds: 450));
        if (!popIfOnTop(_won) && mounted) {
          setState(() {
            _white = false;
            _closing = false;
          });
        }
      });

  CoachMood get _mood {
    if (_reward != null) return _won ? CoachMood.cheering : CoachMood.resting;
    final block = _session.block;

    return block is RestBlock ? CoachMood.resting : CoachMood.watching;
  }

  @override
  Widget build(BuildContext context) {
    final reward = _reward;
    MusicScope.set(
      context,
      reward == null
          ? MusicTrack.challenge
          : _won
              ? MusicTrack.victory
              : MusicTrack.defeat,
    );
    final rushed = _rushedUntil?.isAfter(DateTime.now()) ?? false;
    final down = _downAt;
    final camera = context.watch<SharedPreferencesCubit>().state.trackingMode ==
        TrackingMode.camera;

    return BlocListener<AirPodsTrackerCubit, AirPodsTrackerState>(
      listener: (context, state) {
        if (state.isListening && _tracking) {
          context.read<PushupCubit>().listenForPushupEvents(
                state.currentMotionData,
                _volume ?? 10,
              );
        }
      },
      child: Scaffold(
        backgroundColor: context.colorScheme.surfaceContainerLow,
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      context.colorScheme.secondaryContainer,
                      context.colorScheme.surfaceContainerLow,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: BlocSelector<GameInventoryCubit, GameInventoryState,
                  MonkeyLook>(
                selector: (state) => state.inventory.monkeys.first.look,
                builder: (context, look) => GymCoachStage(
                  tracking: _running,
                  look: look,
                  mood: _mood,
                ),
              ),
            ),
            if (reward == null)
              Positioned.fill(
                child: GymHud(
                  session: _session,
                  now: _now,
                  started: _running,
                  countdown: _countdown,
                  downFor: down == null
                      ? null
                      : DateTime.now().difference(down).inMilliseconds / 1000,
                  coachLine: _coach,
                  rushedFlash: rushed,
                  onStart: _start,
                  onFinish: () => unawaited(_finish()),
                ),
              ),
            if (reward == null)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                left: 16,
                child: _CloseButton(onPressed: _leave),
              ),
            if (reward == null && camera && !_closing)
              Positioned.fill(
                child: CameraWindow(
                  topInset: 60,
                  bottomInset: _running ? 80 : 134,
                  child: CameraTrackerView(
                    active: _tracking,
                    onDown: context.read<PushupCubit>().down,
                    onUp: () => context.read<PushupCubit>().up(_volume ?? 10),
                  ),
                ),
              ),
            if (reward != null)
              Positioned.fill(
                child: GymResult(
                  challenge: _challenge,
                  won: _won,
                  pushups: _pushups,
                  bananas: reward.bananas,
                  streak: reward.streak,
                  gift: reward.gift,
                  crate: reward.crate,
                  replay: widget.replay,
                  onDone: _leave,
                ),
              ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _white ? 1 : 0,
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOut,
                  child: ColoredBox(color: context.gameColors.flash),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: context.cardShadow,
        ),
        child: Material(
          color: context.colorScheme.surface.withValues(alpha: 0.94),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(
                CarbonIcons.close,
                color: context.colorScheme.onSurface,
                size: 22,
              ),
            ),
          ),
        ),
      );
}
