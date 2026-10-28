import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/features/pro/cubit/pro_cubit.dart';
import 'package:pushup_bro/features/pro/model/pro_feature.dart';
import 'package:pushup_bro/features/pro/paywall/show_paywall.dart';
import 'package:pushup_bro/features/pro/widgets/pro_lock_sheet.dart';

/// Whether the player may use a Pro feature right now. With access it
/// returns true at once; without, it opens the paywall (or first the lock
/// sheet for [place], on the island) and returns whether they unlocked it.
Future<bool> ensureProAccess(
  BuildContext context, {
  ProLockPlace? place,
}) async {
  if (context.read<ProCubit>().hasAccess) return true;

  return place == null
      ? await showPaywall(context)
      : await showProLockSheet(context, place);
}
