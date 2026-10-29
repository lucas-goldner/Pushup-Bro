import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/social/account/connect_account.dart';
import 'package:pushup_bro/features/social/account/sign_in_buttons.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/data/social_backend.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

/// Shows "Never lose your island" once, if a new Pro member hasn't
/// connected Apple or Google yet. Called when Home or the Island opens.
Future<void> maybePromptAccountUpgrade(BuildContext context) async {
  final account = context.read<AccountCubit>();
  if (!await account.shouldPromptUpgrade() || !context.mounted) return;
  await account.upgradePromptShown();
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const UpgradeSheet(),
  );
}

/// Calls [maybePromptAccountUpgrade] once its screen is up.
class AccountUpgradePrompt extends StatefulWidget {
  const AccountUpgradePrompt({super.key});

  @override
  State<AccountUpgradePrompt> createState() => _AccountUpgradePromptState();
}

class _AccountUpgradePromptState extends State<AccountUpgradePrompt> {
  @override
  void initState() {
    super.initState();
    // After the screen's own entrance (and the "Welcome to Pro" screen).
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 900), () {
        if (mounted) unawaited(maybePromptAccountUpgrade(context));
      }),
    );
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

/// The Pro perk: connect Apple or Google and the island is never lost.
class UpgradeSheet extends StatefulWidget {
  const UpgradeSheet({super.key});

  @override
  State<UpgradeSheet> createState() => _UpgradeSheetState();
}

class _UpgradeSheetState extends State<UpgradeSheet> {
  SignInProvider? _busy;

  Future<void> _connect(SignInProvider provider) async {
    setState(() => _busy = provider);
    final navigator = Navigator.of(context);
    final done = await connectAccount(context, provider);
    if (!mounted) return;
    setState(() => _busy = null);
    if (done) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final check = context.gameColors.jungle;

    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(PBRadius.sheet),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        PBSpace.xl,
        0,
        PBSpace.xl,
        MediaQuery.paddingOf(context).bottom + PBSpace.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(
            offset: const Offset(0, -60),
            child: Assets.images.proHeroWave.image(height: 150),
          ),
          Transform.translate(
            offset: const Offset(0, -48),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    color: context.colorScheme.primary,
                    borderRadius: BorderRadius.circular(PBRadius.pill),
                  ),
                  child: Text(
                    l.upgradeBadge,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: context.gameColors.banana,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: PBSpace.md),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: '${l.upgradeTitle} '),
                      TextSpan(
                        text: l.upgradeTitleIsland,
                        style: TextStyle(color: context.colorScheme.secondary),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: context.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: PBSpace.sm),
                Text(
                  l.upgradeText,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: PBSpace.lg),
                for (final (emoji, text) in [
                  ('🏝️', l.upgradeIsland),
                  ('📈', l.upgradePushups),
                  ('🤝', l.upgradeBros),
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: context.colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(emoji),
                        ),
                        const SizedBox(width: PBSpace.md),
                        Expanded(
                          child: Text(
                            text,
                            style: context.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(Icons.check_circle, color: check),
                      ],
                    ),
                  ),
                const SizedBox(height: PBSpace.lg),
                SignInButtons(
                  busy: _busy,
                  onPick: (provider) => unawaited(_connect(provider)),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l.upgradeLater),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
