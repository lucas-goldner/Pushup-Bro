import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';
import 'package:pushup_bro/core/widgets/pb_button.dart';
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
          backgroundColor: background,
          child: SafeArea(
            child: Column(
              children: [
                Text(
                  context.l10n.setVolume,
                  style: context.textTheme.titleLarge,
                ),
                const SizedBox(height: 32),
                VolumeDisplayer(_selectedVolume),
                const SizedBox(height: 20),
                _VolumeRow(
                  label: context.l10n.settingsSounds,
                  value: _selectedVolume,
                  onChanged: _updateVolume,
                ),
                const SizedBox(height: 24),
                _VolumeRow(
                  label: context.l10n.settingsMusic,
                  value: state.musicVolume,
                  onChanged: (volume) => unawaited(
                    context.read<SharedPreferencesCubit>().setMusicVolume(
                          volume,
                        ),
                  ),
                ),
                const Spacer(),
                PBButton(
                  context.l10n.goBack,
                  callback: () => Navigator.of(context).pop(),
                  expanded: true,
                ),
              ],
            ),
          ),
        ),
      );
}

/// A labelled volume, 0 to 10, with minus and plus buttons.
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
  Widget build(BuildContext context) => Column(
        children: [
          Text(label, style: context.textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 80,
                child: PBButton(
                  '-',
                  callback: () => onChanged(value == 0 ? 0 : value - 1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  context.l10n.volumeLevel(value),
                  style: context.textTheme.bodyMedium,
                ),
              ),
              SizedBox(
                width: 80,
                child: PBButton(
                  '+',
                  callback: () => onChanged(value == 10 ? 10 : value + 1),
                ),
              ),
            ],
          ),
        ],
      );
}
