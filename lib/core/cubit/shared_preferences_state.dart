import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/core/model/appearance.dart';
import 'package:pushup_bro/core/model/tracking_mode.dart';

class SharedPreferencesState extends Equatable {
  const SharedPreferencesState({
    this.language,
    this.volumeLevel,
    this.firstPushupCompleted,
    this.firstTimeIslandVisited,
    this.trackingMode = TrackingMode.airpods,
    this.musicVolume = 7,
    this.appearance = Appearance.system,
    this.musicOn = true,
    this.soundsOn = true,
    this.cameraView = CameraView.person,
    this.airpodsSensitivity = AirPodsSensitivity.standard,
  });
  final Locale? language;
  final int? volumeLevel;
  final bool? firstPushupCompleted;
  final bool? firstTimeIslandVisited;

  /// How pushups are counted.
  final TrackingMode trackingMode;

  /// The game music's volume, 0 to 10 (sound effects use [volumeLevel]).
  final int musicVolume;

  /// Light or dark mode, or following the phone.
  final Appearance appearance;

  /// The switches for all music and all sound effects.
  final bool musicOn;
  final bool soundsOn;

  /// What the camera window shows (the player, or only the skeleton).
  final CameraView cameraView;

  /// How small a head movement counts as a pushup with AirPods (see
  /// [AirPodsSensitivity]).
  final int airpodsSensitivity;

  @override
  List<Object?> get props => [
        language,
        volumeLevel,
        firstPushupCompleted,
        firstTimeIslandVisited,
        trackingMode,
        musicVolume,
        appearance,
        musicOn,
        soundsOn,
        cameraView,
        airpodsSensitivity,
      ];
}

class SharedPreferencesInitial extends SharedPreferencesState {
  const SharedPreferencesInitial()
      : super(
          language: const Locale('en'),
          volumeLevel: 10,
          firstPushupCompleted: false,
          firstTimeIslandVisited: true,
        );
}

class SharedPreferencesLoaded extends SharedPreferencesState {
  const SharedPreferencesLoaded({
    super.language = const Locale('en'),
    super.volumeLevel = 10,
    super.firstPushupCompleted = false,
    super.firstTimeIslandVisited = true,
    super.trackingMode,
    super.musicVolume,
    super.appearance,
    super.musicOn,
    super.soundsOn,
    super.cameraView,
    super.airpodsSensitivity,
  });
}
