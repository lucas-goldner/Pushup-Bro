import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/features/pro/cubit/pro_cubit.dart';
import 'package:pushup_bro/features/pro/paywall/paywall_page.dart';
import 'package:pushup_bro/features/pro/success/pro_success_page.dart';

/// Opens the Pushup Bro Pro paywall. Returns whether the player has Pro (or
/// full access) when it closes. A purchase or restore is celebrated first
/// with the welcome screen.
Future<bool> showPaywall(BuildContext context) async {
  final cubit = context.read<ProCubit>();
  final wasPro = cubit.state.isPro;
  final bought = await Navigator.of(context, rootNavigator: true).push<bool>(
    CupertinoPageRoute(
      fullscreenDialog: true,
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const PaywallPage(),
      ),
    ),
  );

  if ((bought ?? false) && !wasPro && cubit.state.isPro && context.mounted) {
    await ProSuccessPage.show(context, plan: cubit.lastPurchase);
  }

  return (bought ?? false) || cubit.hasAccess;
}
