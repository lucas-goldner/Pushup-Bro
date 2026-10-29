import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/cubit/account_state.dart';
import 'package:pushup_bro/features/social/domain/inbox_bananas.dart';
import 'package:pushup_bro/features/social/model/inbox_item.dart';

/// Waves, bananas and nudges from friends, one at a time in a small banner
/// on the island. (Push notifications come later; they show on the next
/// open.)
class InboxBanner extends StatelessWidget {
  const InboxBanner({super.key});

  @override
  Widget build(BuildContext context) =>
      BlocSelector<AccountCubit, AccountState, String?>(
        selector: (state) =>
            state.status == AccountStatus.ready ? state.uid : null,
        builder: (context, uid) => uid == null
            ? const SizedBox.shrink()
            : StreamBuilder<List<InboxItem>>(
                stream: context.read<AccountCubit>().backend.inbox(uid),
                builder: (context, snapshot) {
                  final items = [...?snapshot.data]
                    ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => SlideTransition(
                      position: Tween(
                        begin: const Offset(0, -0.6),
                        end: Offset.zero,
                      ).animate(animation),
                      child: FadeTransition(opacity: animation, child: child),
                    ),
                    child: items.isEmpty
                        ? const SizedBox.shrink()
                        : _Item(
                            key: ValueKey(items.first.id),
                            uid: uid,
                            item: items.first,
                          ),
                  );
                },
              ),
      );
}

class _Item extends StatelessWidget {
  const _Item({required this.uid, required this.item, super.key});

  final String uid;
  final InboxItem item;

  Future<void> _handle(BuildContext context) async {
    final account = context.read<AccountCubit>();
    if (item.kind == InboxKind.banana) {
      final inventory = context.read<GameInventoryCubit>();
      if (await takeInboxBanana(
        SharedPreferencesProvider(),
        now: DateTime.now(),
      )) {
        final inv = inventory.state.inventory;
        await inventory.updateInventory(
          inv.copyWith(bananas: inv.bananas + 1),
        );
        GameAudio.instance.play(Sfx.banana);
      }
    } else {
      GameAudio.instance.play(Sfx.pop);
    }
    await account.backend.removeFromInbox(uid, item.id);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final name = item.fromName.isEmpty ? '🦍' : item.fromName;
    final text = switch (item.kind) {
      InboxKind.wave => l.inboxWave(name),
      InboxKind.banana => l.inboxBanana(name),
      InboxKind.nudge => l.inboxNudge(name),
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(
        PBSpace.lg,
        PBSpace.sm,
        PBSpace.sm,
        PBSpace.sm,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(PBRadius.pill),
        boxShadow: context.cardShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: context.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: PBSpace.sm),
          GestureDetector(
            onTap: () => unawaited(_handle(context)),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: PBSpace.lg,
                vertical: PBSpace.sm,
              ),
              decoration: BoxDecoration(
                color: item.kind == InboxKind.banana
                    ? context.gameColors.banana
                    : context.colorScheme.secondary,
                borderRadius: BorderRadius.circular(PBRadius.pill),
              ),
              child: Text(
                item.kind == InboxKind.banana ? l.inboxClaim : l.inboxOk,
                style: context.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: item.kind == InboxKind.banana
                      ? context.gameColors.onBanana
                      : context.gameColors.onGame,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
