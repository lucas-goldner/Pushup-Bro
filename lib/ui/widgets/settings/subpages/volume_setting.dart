import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/cubit/shared_preferences/shared_preferences_cubit.dart';
import 'package:pushup_bro/cubit/shared_preferences/shared_preferences_state.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:pushup_bro/ui/styles/pb_colors.dart';
import 'package:pushup_bro/ui/styles/pb_text_styles.dart';
import 'package:pushup_bro/ui/widgets/common/pb_button.dart';
import 'package:pushup_bro/ui/widgets/settings/volume_displayer.dart';

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
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SharedPreferencesCubit, SharedPreferencesState>(
        builder: (context, state) => CupertinoPageScaffold(
          backgroundColor: PBColors.background,
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    SingleChildScrollView(
                      child: Text(
                        S.of(context).setVolume,
                        style: PBTextStyles.pageTitleTextStyle,
                      ),
                    ),
                    const SizedBox(
                      height: 40,
                    ),
                    const VolumeDisplayer(),
                    const SizedBox(
                      height: 20,
                    ),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            child: PBButton(
                              '-',
                              callback: () => _updateVolume(
                                _selectedVolume == 0
                                    ? _selectedVolume
                                    : _selectedVolume - 1,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            child: Text(
                              S.of(context).volumeLevel(_selectedVolume),
                              style: PBTextStyles.defaultTextStyle,
                            ),
                          ),
                          SizedBox(
                            width: 80,
                            child: PBButton(
                              '+',
                              callback: () => _updateVolume(
                                _selectedVolume == 10
                                    ? _selectedVolume
                                    : _selectedVolume + 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    PBButton(
                      S.of(context).goBack,
                      callback: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
