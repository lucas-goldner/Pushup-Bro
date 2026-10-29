import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/features/social/account/restore_page.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/cubit/cloud_save.dart';
import 'package:pushup_bro/features/social/data/social_backend.dart';

/// Connects [provider] to the account (or, with [restore], signs in to a
/// saved one) and handles what follows: a first save, the restore screen
/// when an island was found, or a short error. Returns whether it worked.
Future<bool> connectAccount(
  BuildContext context,
  SignInProvider provider, {
  bool restore = false,
}) async {
  final account = context.read<AccountCubit>();
  final save = context.read<CloudSave>();
  final navigator = Navigator.of(context);
  final l = context.l10n;
  final outcome = restore
      ? await account.signInToRestore(provider)
      : await account.link(provider);
  switch (outcome) {
    case Linked():
      unawaited(save.saveNow());
      return true;
    case SwitchedAccount():
      if (account.state.restore != null) {
        await navigator.pushNamed(RestorePage.routeName);
      } else {
        unawaited(save.saveNow());
      }
      return true;
    case LinkCancelled():
      return false;
    case LinkFailed():
      if (context.mounted) {
        await showCupertinoDialog<void>(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: Text(l.accountLinkFailed),
            actions: [
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l.accountOk),
              ),
            ],
          ),
        );
      }
      return false;
  }
}

/// "I already have an island": asks for Apple or Google and signs in to a
/// saved account to restore it. Returns whether it signed in.
Future<bool> pickAndRestore(BuildContext context) async {
  final l = context.l10n;
  final provider = await showCupertinoModalPopup<SignInProvider>(
    context: context,
    builder: (context) => CupertinoActionSheet(
      actions: [
        CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(SignInProvider.apple),
          child: Text(l.upgradeApple),
        ),
        CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(SignInProvider.google),
          child: Text(l.upgradeGoogle),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(l.brosCancel),
      ),
    ),
  );
  if (provider == null || !context.mounted) return false;
  final done = await connectAccount(context, provider, restore: true);
  return done;
}
