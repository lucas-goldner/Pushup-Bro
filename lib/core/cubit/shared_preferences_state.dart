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

  @override
  List<Object?> get props => [
        language,
        volumeLevel,
        firstPushupCompleted,
        firstTimeIslandVisited,
        trackingMode,
        musicVolume,
        appearance,
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
  });
}
