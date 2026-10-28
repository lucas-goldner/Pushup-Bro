import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/cubit/db_state.dart';
import 'package:pushup_bro/features/pro/cubit/pro_cubit.dart';
import 'package:pushup_bro/features/pro/model/pro_state.dart';
import 'package:pushup_bro/features/reminders/cubit/reminders_cubit.dart';
import 'package:pushup_bro/generated/l10n.dart';

/// Keeps the reminders scheduled: loads the settings once, then feeds the
/// [RemindersCubit] the workouts, Pro state and language whenever they
/// change, and plans again when the app comes back to the foreground.
///
/// Sits below the app's localizations (in the app's `builder`) and below
/// the [DBCubit], [ProCubit] and [RemindersCubit] providers.
class RemindersScope extends StatefulWidget {
  const RemindersScope({required this.child, super.key});

  final Widget child;

  @override
  State<RemindersScope> createState() => _RemindersScopeState();
}

class _RemindersScopeState extends State<RemindersScope>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(context.read<RemindersCubit>().load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Also runs when the language changes.
    _push();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    // Reloading the sets pushes them through the listener below.
    unawaited(context.read<DBCubit>().getAllPushupSets());
    unawaited(context.read<RemindersCubit>().refresh());
  }

  void _push() {
    final pro = context.read<ProCubit>();
    // Until the store answered, access isn't known yet.
    if (!pro.state.loaded) return;
    final sets = context.read<DBCubit>().state.pushupSets;
    unawaited(
      context.read<RemindersCubit>().updateInputs(
            ReminderInputs(
              workouts: [
                for (final set in sets)
                  if (set.pushups.isNotEmpty &&
                      set.pushups.last.completedAt != null)
                    set.pushups.last.completedAt!,
              ],
              hasAccess: pro.hasAccess,
              isPro: pro.state.isPro,
              freeSince: pro.state.freeSince,
              strings: S.of(context),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
        listeners: [
          BlocListener<DBCubit, DBState>(
            listenWhen: (previous, current) =>
                previous.pushupSets != current.pushupSets,
            listener: (context, _) => _push(),
          ),
          BlocListener<ProCubit, ProState>(
            listener: (context, _) => _push(),
          ),
        ],
        child: widget.child,
      );
}
