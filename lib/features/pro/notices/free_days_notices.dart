import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/model/shared_preferences_key.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/features/pro/cubit/pro_cubit.dart';
import 'package:pushup_bro/features/pro/notices/free_days_sheets.dart';
import 'package:pushup_bro/features/pro/paywall/show_paywall.dart';
import 'package:pushup_bro/features/pro/widgets/free_days_chip.dart';

/// Which free-days sheet is due, if any.
enum FreeDaysNotice { welcome, lastDay }

/// Picks the sheet to show: the welcome once at the start, the last-day
/// one once when less than a day is left. A player who first opens the app
/// on the last day only sees the last-day sheet.
FreeDaysNotice? dueFreeDaysNotice({
  required Duration left,
  required bool welcomeSeen,
  required bool lastDaySeen,
}) {
  if (left <= Duration.zero) return null;
  if (left < const Duration(hours: 24)) {
    return lastDaySeen ? null : FreeDaysNotice.lastDay;
  }

  return welcomeSeen ? null : FreeDaysNotice.welcome;
}

/// Shows the free-days sheet that's due on the home screen, at most once
/// each.
Future<void> showDueFreeDaysNotice(
  BuildContext context, {
  SharedPreferencesProvider? prefs,
}) async {
  final cubit = context.read<ProCubit>();
  final state = cubit.state;
  final now = cubit.now;
  final freeSince = state.freeSince;
  if (!state.loaded || freeSince == null || !state.showsFreeDays(now)) return;

  final store = prefs ?? SharedPreferencesProvider();
  final welcomeSeen = await store
          .getSharedPrefBool(SharedPreferencesKey.proFreeDaysWelcomeSeen) ??
      false;
  final lastDaySeen =
      await store.getSharedPrefBool(SharedPreferencesKey.proLastFreeDaySeen) ??
          false;
  final left = state.freeLeft(now);
  final notice = dueFreeDaysNotice(
    left: left,
    welcomeSeen: welcomeSeen,
    lastDaySeen: lastDaySeen,
  );
  if (notice == null || !context.mounted) return;

  switch (notice) {
    case FreeDaysNotice.welcome:
      await store.writeBoolToSharedPrefs(
        SharedPreferencesKey.proFreeDaysWelcomeSeen,
        value: true,
      );
      if (!context.mounted) return;
      await showFreeDaysWelcome(context, freeSince: freeSince, now: now);
    case FreeDaysNotice.lastDay:
      await store.writeBoolToSharedPrefs(
        SharedPreferencesKey.proFreeDaysWelcomeSeen,
        value: true,
      );
      await store.writeBoolToSharedPrefs(
        SharedPreferencesKey.proLastFreeDaySeen,
        value: true,
      );
      if (!context.mounted) return;
      final seePlans = await showLastFreeDay(context, left: left);
      if (seePlans && context.mounted) await showPaywall(context);
  }
}
