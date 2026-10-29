import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/friends/add_bro_page.dart';
import 'package:pushup_bro/features/friends/widgets/code_card.dart';
import 'package:pushup_bro/features/island/visit/island_visit_page.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/cubit/bros_cubit.dart';
import 'package:pushup_bro/features/social/model/bro_profile.dart';
import 'package:pushup_bro/features/social/model/inbox_item.dart';
import 'package:pushup_bro/features/social/widgets/bro_avatar.dart';
import 'package:pushup_bro/features/social/widgets/social_widgets.dart';

/// The player's bros: their code to share, and every friend with today's
/// pushups and streak, done or ready for a nudge.
class Friends extends StatelessWidget {
  const Friends({super.key});
  static const routeName = '/friends';

  @override
  Widget build(BuildContext context) => SocialGate(
        builder: (context, me) => BlocProvider(
          key: ValueKey(me.uid),
          create: (context) =>
              BrosCubit(context.read<AccountCubit>().backend, me: me)..start(),
          child: _BrosList(me: me),
        ),
      );
}

class _BrosList extends StatelessWidget {
  const _BrosList({required this.me});

  final BroProfile me;

  @override
  Widget build(BuildContext context) => SafeArea(
        bottom: false,
        child: BlocBuilder<BrosCubit, BrosState>(
          builder: (context, state) {
            final bros = [...state.bros]
              ..sort((a, b) => b.today.compareTo(a.today));

            return ListView(
              padding: const EdgeInsets.fromLTRB(
                PBSpace.lg,
                72,
                PBSpace.lg,
                PBSpace.xxl,
              ),
              children: [
                CodeCard(me: me),
                const SizedBox(height: PBSpace.xl),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.brosCount(bros.length),
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => openAddBro(context),
                      child: Text(context.l10n.brosAddByCode),
                    ),
                  ],
                ),
                const SizedBox(height: PBSpace.sm),
                if (!state.loaded)
                  const Padding(
                    padding: EdgeInsets.all(PBSpace.xxl),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (bros.isEmpty)
                  const _Empty()
                else
                  for (final bro in bros)
                    Padding(
                      padding: const EdgeInsets.only(bottom: PBSpace.md),
                      child: _BroRow(bro: bro, me: me),
                    ),
              ],
            );
          },
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) => SocialCard(
        padding: const EdgeInsets.all(PBSpace.xl),
        child: Column(
          children: [
            const Text('🤝', style: TextStyle(fontSize: 40)),
            const SizedBox(height: PBSpace.md),
            Text(
              context.l10n.brosEmptyTitle,
              textAlign: TextAlign.center,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: PBSpace.sm),
            Text(
              context.l10n.brosEmptyText,
              textAlign: TextAlign.center,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
}

class _BroRow extends StatefulWidget {
  const _BroRow({required this.bro, required this.me});

  final Bro bro;
  final BroProfile me;

  @override
  State<_BroRow> createState() => _BroRowState();
}

class _BroRowState extends State<_BroRow> {
  bool _nudged = false;

  Bro get bro => widget.bro;

  Future<void> _nudge() async {
    if (_nudged) return;
    setState(() => _nudged = true);
    GameAudio.instance.play(Sfx.tap);
    final account = context.read<AccountCubit>();
    await account.backend.send(
      bro.uid,
      InboxItem.create(
        kind: InboxKind.nudge,
        fromUid: widget.me.uid,
        fromName: account.state.friendName,
        now: DateTime.now(),
      ),
    );
  }

  Future<void> _options() async {
    final l = context.l10n;
    final name = friendLabel(context, bro.profile, bro.name);
    final cubit = context.read<BrosCubit>();
    final choice = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(name),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop('remove'),
            child: Text(l.brosRemove),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop('block'),
            child: Text(l.brosBlock),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l.brosCancel),
        ),
      ),
    );
    if (choice == null || !mounted) return;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          choice == 'remove'
              ? l.brosRemoveConfirm(name)
              : l.brosBlockConfirm(name),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.brosCancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(choice == 'remove' ? l.brosRemove : l.brosBlock),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false)) return;
    unawaited(
      choice == 'remove' ? cubit.remove(bro.uid) : cubit.block(bro.uid),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final done = bro.today > 0;
    final game = context.gameColors;

    return SocialCard(
      padding: const EdgeInsets.all(PBSpace.md),
      onTap: () => openIslandVisit(context, uid: bro.uid),
      onLongPress: _options,
      child: Row(
        children: [
          BroAvatar(look: bro.profile.look, size: 48),
          const SizedBox(width: PBSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friendLabel(context, bro.profile, bro.name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${done ? l.brosTodayStreak(bro.today) : l.brosNotStarted}'
                  ' · 🔥 ${bro.profile.streak}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: done ? null : _nudge,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: context.tint(done ? game.jungle : game.orange),
                borderRadius: BorderRadius.circular(PBRadius.pill),
              ),
              child: Text(
                done ? l.brosDone : (_nudged ? l.brosNudged : l.brosNudge),
                style: context.textTheme.labelMedium?.copyWith(
                  color: done ? game.jungle : game.orange,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: PBSpace.xs),
          Icon(
            CarbonIcons.chevron_right,
            size: 18,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
