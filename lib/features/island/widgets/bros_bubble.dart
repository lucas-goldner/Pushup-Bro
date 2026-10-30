import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/cubit/account_state.dart';
import 'package:pushup_bro/features/social/cubit/bros_cubit.dart';
import 'package:pushup_bro/features/social/domain/ranking.dart';
import 'package:pushup_bro/features/social/model/bro_profile.dart';
import 'package:pushup_bro/features/social/model/inbox_item.dart';
import 'package:pushup_bro/features/social/widgets/bro_avatar.dart';
import 'package:pushup_bro/features/social/widgets/social_widgets.dart';

/// How many heads the bubble shows.
const _kHeads = 3;

/// The size of a head in the bubble.
const _kHeadSize = 40.0;

/// How far the heads overlap.
const _kHeadOverlap = 14.0;

/// The bros, floating above the island's dock: the top heads of today's
/// board, the player's place and the next small win, and how many waves,
/// bananas and nudges wait. Tapping it opens the bros.
class BrosBubble extends StatelessWidget {
  const BrosBubble({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) =>
      BlocSelector<AccountCubit, AccountState, BroProfile?>(
        selector: (state) =>
            state.status == AccountStatus.ready ? state.profile : null,
        builder: (context, me) => me == null
            // Offline or still signing in: just the way to the bros.
            ? _Bubble(onTap: onTap, title: context.l10n.friends)
            : BlocProvider(
                key: ValueKey(me.uid),
                create: (context) =>
                    BrosCubit(context.read<AccountCubit>().backend, me: me)
                      ..start(),
                child: _LiveBubble(me: me, onTap: onTap),
              ),
      );
}

class _LiveBubble extends StatelessWidget {
  const _LiveBubble({required this.me, required this.onTap});

  final BroProfile me;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return StreamBuilder<List<InboxItem>>(
      stream: context.read<AccountCubit>().backend.inbox(me.uid),
      builder: (context, inbox) => BlocBuilder<BrosCubit, BrosState>(
        builder: (context, state) {
          final waiting = inbox.data?.length ?? 0;
          if (!state.loaded || state.bros.isEmpty) {
            return _Bubble(
              onTap: onTap,
              heads: [me],
              title: l.friends,
              subtitle: state.loaded ? l.islandBrosAdd : null,
              waiting: waiting,
            );
          }
          final everyone = state.everyone;
          final ranked = rank(everyone.map((bro) => bro.score));
          final byUid = {for (final bro in everyone) bro.uid: bro};
          final place = ranked.indexWhere((s) => s.uid == me.uid) + 1;
          final subtitle = switch (nextWin(ranked, me.uid)) {
            PassNext(:final ahead, :final more) => l.islandBrosPass(
                more,
                friendLabel(
                  context,
                  byUid[ahead.uid]!.profile,
                  byUid[ahead.uid]!.name,
                ),
              ),
            OnTop() => l.islandBrosTop,
            null => null,
          };

          return _Bubble(
            onTap: onTap,
            heads: [
              for (final score in ranked.take(_kHeads))
                byUid[score.uid]!.profile,
            ],
            title: l.islandBrosPlace(place),
            subtitle: subtitle,
            waiting: waiting,
          );
        },
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.onTap,
    required this.title,
    this.heads = const [],
    this.subtitle,
    this.waiting = 0,
  });

  final VoidCallback onTap;
  final List<BroProfile> heads;
  final String title;
  final String? subtitle;

  /// Waves, bananas and nudges not seen yet.
  final int waiting;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final subtitle = this.subtitle;

    return Semantics(
      button: true,
      label: [
        title,
        if (subtitle != null) subtitle,
        if (waiting > 0) context.l10n.islandBrosWaiting(waiting),
      ].join(', '),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: const StadiumBorder(),
          shadows: context.cardShadow,
        ),
        child: Material(
          color: scheme.surface,
          shape: const StadiumBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Container(
              height: 56,
              padding: EdgeInsets.fromLTRB(
                heads.isEmpty ? PBSpace.lg : PBSpace.sm,
                0,
                PBSpace.lg,
                0,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (heads.isEmpty)
                    Icon(CarbonIcons.group, size: 22, color: scheme.onSurface)
                  else
                    SizedBox(
                      width: _kHeadSize +
                          (heads.length - 1) * (_kHeadSize - _kHeadOverlap),
                      height: _kHeadSize,
                      child: Stack(
                        children: [
                          for (final (i, head) in heads.indexed)
                            Positioned(
                              left: i * (_kHeadSize - _kHeadOverlap),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: scheme.surface,
                                    width: 2,
                                  ),
                                ),
                                child: BroAvatar(
                                  look: head.look,
                                  size: _kHeadSize - 4,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                          height: 1.15,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: context.textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.15,
                          ),
                        ),
                    ],
                  ),
                  if (waiting > 0) ...[
                    const SizedBox(width: 10),
                    Container(
                      constraints: const BoxConstraints(minWidth: 20),
                      height: 20,
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.gameColors.orange,
                        borderRadius: BorderRadius.circular(PBRadius.pill),
                      ),
                      child: Text(
                        '$waiting',
                        style: context.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: context.gameColors.onBanana,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
