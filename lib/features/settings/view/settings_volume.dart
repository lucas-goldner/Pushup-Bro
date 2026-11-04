import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/pb_button.dart';
import 'package:pushup_bro/features/settings/widgets/settings_group.dart';

/// Music and sound effects: a switch and a volume slider for each.
class VolumeSetting extends StatelessWidget {
  const VolumeSetting({super.key});
  static const routeName = '/volume';

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SharedPreferencesCubit, SharedPreferencesState>(
        builder: (context, state) {
          final prefs = context.read<SharedPreferencesCubit>();
          final l = context.l10n;
          final game = context.gameColors;

          return CupertinoPageScaffold(
            backgroundColor: context.colorScheme.surfaceContainerLow,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ListView(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            PBSpace.xl,
                            PBSpace.lg,
                            PBSpace.xl,
                            PBSpace.sm,
                          ),
                          child: Text(
                            l.setVolume,
                            style: context.textTheme.headlineLarge,
                          ),
                        ),
                        SettingsSectionHeader(l.settingsMusic),
                        SettingsGroup(
                          children: [
                            SoundSwitchRow(
                              label: l.settingsMusic,
                              icon: CarbonIcons.music,
                              color: game.purple,
                              on: state.musicOn,
                              onChanged: (on) =>
                                  unawaited(prefs.setMusicOn(on: on)),
                            ),
                            _VolumeSlider(
                              value: state.musicVolume,
                              enabled: state.musicOn,
                              color: game.purple,
                              onChanged: (volume) =>
                                  unawaited(prefs.setMusicVolume(volume)),
                            ),
                          ],
                        ),
                        SettingsSectionHeader(l.settingsSoundEffects),
                        SettingsGroup(
                          children: [
                            SoundSwitchRow(
                              label: l.settingsSoundEffects,
                              icon: CarbonIcons.volume_up,
                              color: game.orange,
                              on: state.soundsOn,
                              onChanged: (on) =>
                                  unawaited(prefs.setSoundsOn(on: on)),
                            ),
                            _VolumeSlider(
                              value: state.volumeLevel ?? 10,
                              enabled: state.soundsOn,
                              color: game.orange,
                              onChanged: (volume) =>
                                  unawaited(prefs.setVolume(volume)),
                              // Let them hear the new level.
                              onChangeEnd: (_) =>
                                  GameAudio.instance.play(Sfx.tap),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      PBSpace.sm,
                      PBSpace.sm,
                      PBSpace.sm,
                      PBSpace.lg,
                    ),
                    child: PBButton(
                      l.goBack,
                      callback: () => Navigator.of(context).pop(),
                      expanded: true,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

/// A settings row with an icon tile and a switch.
class SoundSwitchRow extends StatelessWidget {
  const SoundSwitchRow({
    required this.label,
    required this.icon,
    required this.on,
    required this.onChanged,
    this.color,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color? color;
  final bool on;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => SettingsRow(
        label: label,
        icon: icon,
        color: color,
        onTap: () => onChanged(!on),
        trailing: Switch.adaptive(value: on, onChanged: onChanged),
      );
}

/// A volume from 0 to 10, with a speaker at each end.
class _VolumeSlider extends StatelessWidget {
  const _VolumeSlider({
    required this.value,
    required this.enabled,
    required this.color,
    required this.onChanged,
    this.onChangeEnd,
  });

  final int value;
  final bool enabled;
  final Color color;
  final ValueChanged<int> onChanged;
  final ValueChanged<int>? onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final muted = context.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PBSpace.lg,
        PBSpace.xs,
        PBSpace.lg,
        PBSpace.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.settingsVolume,
                  style: context.textTheme.labelLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                enabled ? '${value * 10} %' : context.l10n.settingsOff,
                style: context.textTheme.labelLarge?.copyWith(
                  color: enabled ? color : muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(CarbonIcons.volume_mute, size: 18, color: muted),
              Expanded(
                child: Slider(
                  value: value.toDouble(),
                  max: 10,
                  divisions: 10,
                  activeColor: color,
                  onChanged: enabled ? (v) => onChanged(v.round()) : null,
                  onChangeEnd: enabled && onChangeEnd != null
                      ? (v) => onChangeEnd!(v.round())
                      : null,
                ),
              ),
              Icon(CarbonIcons.volume_up, size: 18, color: muted),
            ],
          ),
        ],
      ),
    );
  }
}
