import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/cubit/account_state.dart';
import 'package:pushup_bro/features/social/cubit/cloud_save.dart';
import 'package:pushup_bro/features/social/cubit/social_sync.dart';
import 'package:pushup_bro/features/social/model/bro_profile.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

/// "Welcome back, bro!": a saved island was found after signing in on a
/// new iPhone. Restore it (today's pushups on this iPhone are added on
/// top) or start fresh.
class RestorePage extends StatefulWidget {
  const RestorePage({super.key});
  static const routeName = '/account/restore';

  @override
  State<RestorePage> createState() => _RestorePageState();
}

class _RestorePageState extends State<RestorePage> {
  late final Future<int> _localToday =
      context.read<CloudSave>().source.pushupsToday(DateTime.now());
  bool _busy = false;

  Future<void> _finish({required bool restore}) async {
    setState(() => _busy = true);
    final save = context.read<CloudSave>();
    final account = context.read<AccountCubit>();
    final navigator = Navigator.of(context);
    final offer = account.state.restore;
    if (restore && offer != null) {
      await save.restore(offer.backup);
    } else {
      await save.startFresh();
    }
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final offer =
        context.select<AccountCubit, RestoreOffer?>((a) => a.state.restore);
    final profile =
        context.select<AccountCubit, BroProfile?>((a) => a.state.profile);
    if (offer == null) return const SizedBox.shrink();
    final backup = offer.backup;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final inventory = backup.inventory.isEmpty
        ? null
        : GameInventory.fromJson(backup.inventory);
    final stats = [
      (
        '💪',
        NumberFormat.decimalPattern(locale).format(backup.pushups),
        l.restorePushups
      ),
      ('🔥', '${profile?.streak ?? 0}', l.restoreStreak),
      ('🤝', '${profile?.friendCount ?? 0}', l.restoreBros),
      (
        '🏝️',
        'Lv ${inventory == null ? 1 : islandLevelOf(inventory)}',
        l.restoreIsland,
      ),
    ];

    return Scaffold(
      backgroundColor: Color.lerp(
        context.colorScheme.surfaceContainerLow,
        context.colorScheme.secondary,
        0.08,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(PBSpace.lg),
          child: Column(
            children: [
              const Spacer(),
              Assets.images.proHeroWave.image(height: 220),
              const SizedBox(height: PBSpace.lg),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${l.restoreTitle} '),
                    TextSpan(
                      text: l.restoreTitleBro,
                      style: TextStyle(color: context.colorScheme.secondary),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: context.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: PBSpace.sm),
              Text(
                l.restoreFound(
                  DateFormat.MMMEd(locale).add_Hm().format(backup.savedAt),
                ),
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: PBSpace.xl),
              Row(
                children: [
                  for (final (emoji, value, label) in stats)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: context.colorScheme.surface,
                          borderRadius: BorderRadius.circular(PBRadius.md),
                          boxShadow: context.cardShadow,
                        ),
                        child: Column(
                          children: [
                            Text(emoji, style: const TextStyle(fontSize: 20)),
                            FittedBox(
                              child: Text(
                                value,
                                style: context.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.labelSmall?.copyWith(
                                color: context.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: PBSpace.md),
              FutureBuilder<int>(
                future: _localToday,
                builder: (context, snapshot) {
                  final today = snapshot.data ?? 0;
                  if (today == 0) return const SizedBox.shrink();
                  return Container(
                    padding: const EdgeInsets.all(PBSpace.md),
                    decoration: BoxDecoration(
                      color: context.colorScheme.surface,
                      borderRadius: BorderRadius.circular(PBRadius.md),
                      boxShadow: context.cardShadow,
                    ),
                    child: Row(
                      children: [
                        const Text('📱', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: PBSpace.sm),
                        Expanded(
                          child: Text(
                            l.restoreLocal(today),
                            style: context.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Spacer(flex: 2),
              PillButton(
                label: l.restoreButton,
                color: context.colorScheme.secondary,
                onPressed: () {
                  if (!_busy) unawaited(_finish(restore: true));
                },
              ),
              const SizedBox(height: PBSpace.sm),
              TextButton(
                onPressed: _busy ? null : () => _finish(restore: false),
                child: Text(l.restoreFresh),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
