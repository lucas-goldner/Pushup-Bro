import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/features/settings/model/progress_reset.dart';
import 'package:pushup_bro/features/settings/widgets/settings_group.dart';

/// The two fresh starts: the island and story only, or everything.
/// Each asks first, saying what goes and what stays.
class ResetProgressGroup extends StatelessWidget {
  const ResetProgressGroup({super.key});

  ProgressReset _reset(BuildContext context) => ProgressReset(
        dbCubit: context.read<DBCubit>(),
        inventory: context.read<GameInventoryCubit>(),
        prefsCubit: context.read<SharedPreferencesCubit>(),
      );

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String info,
    required String action,
    required Future<void> Function() reset,
  }) async {
    final l = context.l10n;
    final sure = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(info),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
    await reset();
    GameAudio.instance.play(Sfx.whoosh);
    if (!context.mounted) return;
    await showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l.resetDone),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.accountOk),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final game = context.gameColors;

    return SettingsGroup(
      children: [
        SettingsRow(
          label: l.resetIsland,
          icon: CarbonIcons.reset,
          color: game.orange,
          onTap: () => unawaited(
            _confirm(
              context,
              title: l.resetIsland,
              info: l.resetIslandInfo,
              action: l.resetIslandConfirm,
              reset: _reset(context).resetIsland,
            ),
          ),
        ),
        SettingsRow(
          label: l.resetAll,
          icon: CarbonIcons.trash_can,
          color: game.red,
          onTap: () => unawaited(
            _confirm(
              context,
              title: l.resetAll,
              info: l.resetAllInfo,
              action: l.resetAllConfirm,
              reset: _reset(context).resetAll,
            ),
          ),
        ),
      ],
    );
  }
}
