import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/features/menu/widgets/menu_circle_button.dart';

/// A round button that turns the music on or off for the whole app.
class MusicToggleButton extends StatelessWidget {
  const MusicToggleButton({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<SharedPreferencesCubit, SharedPreferencesState, bool>(
        selector: (state) => state.musicOn,
        builder: (context, on) => Semantics(
          button: true,
          toggled: on,
          label: context.l10n.settingsMusic,
          child: MenuCircleButton(
            icon: on ? CarbonIcons.music : CarbonIcons.music_remove,
            onTap: () {
              GameAudio.instance.play(Sfx.tap);
              unawaited(
                context.read<SharedPreferencesCubit>().setMusicOn(on: !on),
              );
            },
          ),
        ),
      );
}
