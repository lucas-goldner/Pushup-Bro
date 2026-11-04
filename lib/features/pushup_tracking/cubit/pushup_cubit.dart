import 'dart:async';

import 'package:flutter_airpods/models/device_motion_data.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/model/pushup.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/core/model/tracking_mode.dart';
import 'package:pushup_bro/core/provider/audio_player_provider.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/pushup_state.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

class PushupCubit extends Cubit<PushupState> {
  PushupCubit(this._audioPlayer)
      : super(const PushupState(pushups: [], inPushup: false));
  final AudioPlayerProvider _audioPlayer;

  int getCurrentPushups() => state.pushups.length;

  PushupSet resetAndReturnCurrentPushupSet() {
    final pushups = state.pushups;
    emit(const PushupState(pushups: [], inPushup: false));
    return PushupSet(pushups, 0);
  }

  /// How sharp a head movement has to be (in g) to start or finish a
  /// pushup with AirPods; see [AirPodsSensitivity]. Follows the setting.
  static double threshold =
      AirPodsSensitivity.threshold(AirPodsSensitivity.standard);

  /// Feeds one AirPods motion sample: a sharp drop starts a pushup, a sharp
  /// rise finishes it.
  void listenForPushupEvents(DeviceMotionData? deviceMotionData, int volume) {
    final userAccelerationY = deviceMotionData?.userAcceleration.y ?? 0;

    if (state.inPushup) {
      if (userAccelerationY > threshold) up(volume);
    } else if (userAccelerationY < -threshold) {
      down();
    }
  }

  /// The body went down into a pushup (from either tracker).
  void down() {
    if (state.inPushup) return;
    emit(state.copyWith(pushups: state.pushups, inPushup: true));
  }

  /// The body came back up: one more pushup, with its sound at [volume]
  /// (0 to 10).
  void up(int volume) {
    if (!state.inPushup) return;
    final pushups = [...state.pushups, Pushup(completedAt: DateTime.now())];
    final pushupSoundFilePath =
        Assets.audio.pushupSound.replaceFirstMapped('assets/', (_) => '');
    if (GameAudio.instance.soundsOn) {
      unawaited(_audioPlayer.setVolumeLevel(volume / 10.toDouble()));
      unawaited(_audioPlayer.playSound(pushupSoundFilePath));
    }
    emit(state.copyWith(pushups: pushups, inPushup: false));
  }
}
