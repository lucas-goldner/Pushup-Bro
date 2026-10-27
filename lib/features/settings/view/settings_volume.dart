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
import 'package:pushup_bro/features/settings/widgets/volume_displayer.dart';

class VolumeSetting extends StatefulWidget {
  const VolumeSetting({super.key});
  static const routeName = '/volume';

  @override
  State<VolumeSetting> createState() => _VolumeSettingState();
}

class _VolumeSettingState extends State<VolumeSetting> {
  int _selectedVolume = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_getVolume());
  }

  Future<void> _getVolume() async {
    final volume =
        await BlocProvider.of<SharedPreferencesCubit>(context).getVolume();
    setState(() => _selectedVolume = volume);
  }

  Future<void> _updateVolume(int vol) async {
    final sharedPrefCubit = BlocProvider.of<SharedPreferencesCubit>(context);
    await sharedPrefCubit.setVolume(vol);
    setState(() => _selectedVolume = vol);
    GameAudio.instance.play(Sfx.tap);
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SharedPreferencesCubit, SharedPreferencesState>(
        builder: (context, state) => CupertinoPageScaffold(
          backgroundColor: context.colorScheme.surfaceContainerLow,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    PBSpace.xl,
                    PBSpace.lg,
                    PBSpace.xl,
                    PBSpace.xl,
                  ),
                  child: Text(
                    context.l10n.setVolume,
                    style: context.textTheme.headlineLarge,
                  ),
                ),
                VolumeDisplayer(_selectedVolume),
                const SizedBox(height: PBSpace.xl),
                SettingsGroup(
                  children: [
                    _VolumeRow(
                      label: context.l10n.settingsSounds,
                      value: _selectedVolume,
                      onChanged: _updateVolume,
                    ),
                    _VolumeRow(
                      label: context.l10n.settingsMusic,
                      value: state.musicVolume,
                      onChanged: (volume) => unawaited(
                        context.read<SharedPreferencesCubit>().setMusicVolume(
                              volume,
                            ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    PBSpace.sm,
                    PBSpace.sm,
                    PBSpace.sm,
                    PBSpace.lg,
                  ),
                  child: PBButton(
                    context.l10n.goBack,
                    callback: () => Navigator.of(context).pop(),
                    expanded: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// A labelled volume, 0 to 10, with round minus and plus buttons.
class _VolumeRow extends StatelessWidget {
  const _VolumeRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PBSpace.lg,
          vertical: PBSpace.md,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: context.textTheme.titleMedium),
                  Text(
                    context.l10n.volumeLevel(value),
                    style: context.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            _StepButton(
              icon: CarbonIcons.subtract,
              onTap: () => onChanged(value == 0 ? 0 : value - 1),
            ),
            const SizedBox(width: PBSpace.sm),
            _StepButton(
              icon: CarbonIcons.add,
              onTap: () => onChanged(value == 10 ? 10 : value + 1),
            ),
          ],
        ),
      );
}

/// A round soft button with an [icon].
class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: context.colorScheme.surfaceContainer,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: context.colorScheme.onSurface),
          ),
        ),
      );
}
