import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/leaderboard/widgets/board_rows.dart';
import 'package:pushup_bro/features/leaderboard/widgets/podium.dart';
import 'package:pushup_bro/features/menu/model/menu_tab_info.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/cubit/bros_cubit.dart';
import 'package:pushup_bro/features/social/cubit/everyone_cubit.dart';
import 'package:pushup_bro/features/social/domain/local_day.dart';
import 'package:pushup_bro/features/social/domain/ranking.dart';
import 'package:pushup_bro/features/social/model/bro_profile.dart';
import 'package:pushup_bro/features/social/widgets/social_widgets.dart';

/// Today's pushups: the player's bros (a podium, then the rest) or
/// everyone (the top 50 and the player's own place). Free for everyone,
/// and it resets at each player's local midnight.
class Leaderboard extends StatelessWidget {
  const Leaderboard({super.key});
  static const routeName = '/leaderboard';

  @override
  Widget build(BuildContext context) => SocialGate(
        builder: (context, me) => MultiBlocProvider(
          key: ValueKey(me.uid),
          providers: [
            BlocProvider(
              create: (context) =>
                  BrosCubit(context.read<AccountCubit>().backend, me: me)
                    ..start(),
            ),
            BlocProvider(
              create: (context) => EveryoneCubit(
                context.read<AccountCubit>().backend,
                uid: me.uid,
              )..start(),
            ),
          ],
          child: _Board(me: me),
        ),
      );
}

class _Board extends StatefulWidget {
  const _Board({required this.me});

  final BroProfile me;

  @override
  State<_Board> createState() => _BoardState();
}

class _BoardState extends State<_Board> {
  int _tab = 0;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    // The reset countdown moves on its own.
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final left = untilMidnight(DateTime.now());

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(PBSpace.lg, 72, PBSpace.lg, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: _tab == 0
                  ? SocialChip(
                      l.boardResetsIn(left.inHours, left.inMinutes % 60),
                      emoji: '⏱',
                    )
                  : BlocSelector<EveryoneCubit, EveryoneState, int>(
                      selector: (state) => state.players,
                      builder: (context, players) => SocialChip(
                        l.boardPlayers(players),
                        emoji: '🌍',
                      ),
                    ),
            ),
            const SizedBox(height: PBSpace.md),
            SocialTabs(
              labels: [l.boardFriends, l.boardEveryone],
              selected: _tab,
              onSelect: (tab) => setState(() => _tab = tab),
            ),
            const SizedBox(height: PBSpace.lg),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _tab == 0
                    ? const _FriendsBoard(key: ValueKey('friends'))
                    : _EveryoneBoard(
                        key: const ValueKey('everyone'),
                        me: widget.me,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The player's bros: the top three on a podium, the rest below and the
/// next small win at the bottom.
class _FriendsBoard extends StatelessWidget {
  const _FriendsBoard({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<BrosCubit, BrosState>(
        builder: (context, state) {
          if (!state.loaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final bros = state.everyone;
          final ranked = rank(bros.map((bro) => bro.score));
          final byUid = {for (final bro in bros) bro.uid: bro};
          final order = [for (final score in ranked) byUid[score.uid]!];
          final me = state.me!;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: PBSpace.lg),
                  children: [
                    if (state.bros.isEmpty)
                      _NoBros(me: me)
                    else ...[
                      Podium(top: order.take(3).toList()),
                      const SizedBox(height: PBSpace.lg),
                      BoardRows(
                        rows: [
                          for (final (i, bro) in order.indexed.skip(3))
                            BoardRow.bro(context, bro, place: i + 1),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (state.bros.isNotEmpty)
                NextWinCard(
                  win: nextWin(ranked, me.uid),
                  started: me.today > 0,
                  nameOf: (uid) {
                    final bro = byUid[uid]!;
                    return friendLabel(context, bro.profile, bro.name);
                  },
                ),
              const SizedBox(height: PBSpace.xl),
            ],
          );
        },
      );
}

class _NoBros extends StatelessWidget {
  const _NoBros({required this.me});

  final Bro me;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          const SizedBox(height: PBSpace.xxl),
          Podium(top: [me]),
          const SizedBox(height: PBSpace.xl),
          Text(
            context.l10n.boardNoFriends,
            textAlign: TextAlign.center,
            style: context.textTheme.titleMedium,
          ),
          const SizedBox(height: PBSpace.md),
          TextButton(
            onPressed: () => MenuTabInfo.friends.navigate(context),
            child: Text(context.l10n.boardAddBros),
          ),
        ],
      );
}

/// Today's top 50 of everyone, with the player's own place pinned below.
class _EveryoneBoard extends StatelessWidget {
  const _EveryoneBoard({required this.me, super.key});

  final BroProfile me;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<EveryoneCubit, EveryoneState>(
        builder: (context, state) {
          if (!state.loaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final myScore =
              state.top.where((score) => score.uid == me.uid).firstOrNull;
          final today = context.select<BrosCubit, int>(
            (bros) => bros.state.me?.today ?? 0,
          );

          return Column(
            children: [
              Expanded(
                child: state.top.isEmpty
                    ? Center(
                        child: Text(
                          context.l10n.boardEmptyEveryone,
                          textAlign: TextAlign.center,
                          style: context.textTheme.bodyLarge,
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: PBSpace.lg),
                        children: [
                          BoardRows(
                            rows: [
                              for (final (i, score) in state.top.indexed)
                                BoardRow.score(
                                  context,
                                  score,
                                  place: i + 1,
                                  isMe: score.uid == me.uid,
                                ),
                            ],
                          ),
                        ],
                      ),
              ),
              MyPlaceCard(
                me: me,
                today: myScore?.count ?? today,
                rank: state.myRank,
                players: state.players,
                format: NumberFormat.decimalPattern(
                  Localizations.localeOf(context).toLanguageTag(),
                ),
              ),
              const SizedBox(height: PBSpace.xl),
            ],
          );
        },
      );
}
