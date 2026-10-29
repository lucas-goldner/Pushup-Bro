import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/island/model/island_snapshot.dart';
import 'package:pushup_bro/features/island/widgets/island_scene.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/domain/local_day.dart';
import 'package:pushup_bro/features/social/domain/ranking.dart';
import 'package:pushup_bro/features/social/model/bro_profile.dart';
import 'package:pushup_bro/features/social/model/inbox_item.dart';
import 'package:pushup_bro/features/social/widgets/bro_avatar.dart';
import 'package:pushup_bro/features/social/widgets/social_widgets.dart';

/// Opens a friend's island; [replace] swaps it in for the current screen.
Future<void> openIslandVisit(
  BuildContext context, {
  required String uid,
  bool replace = false,
}) {
  final navigator = Navigator.of(context);
  return replace
      ? navigator.pushReplacementNamed(
          IslandVisitPage.routeName,
          arguments: uid,
        )
      : navigator.pushNamed(IslandVisitPage.routeName, arguments: uid);
}

/// What the visit shows about the friend.
typedef _Visit = ({
  BroProfile profile,
  String name,
  int today,
  int? rank,
});

/// A friend's real 3D island, read-only: their card on top, today's
/// pushups, their place among the player's bros, and Wave or Send a
/// banana.
class IslandVisitPage extends StatefulWidget {
  const IslandVisitPage({required this.uid, super.key});
  static const routeName = '/island/visit';

  final String uid;

  @override
  State<IslandVisitPage> createState() => _IslandVisitPageState();
}

class _IslandVisitPageState extends State<IslandVisitPage> {
  late final Future<_Visit?> _visit = _load();
  bool _waved = false;
  bool _bananaSent = false;

  Future<_Visit?> _load() async {
    final account = context.read<AccountCubit>();
    final backend = account.backend;
    final me = account.state.uid;
    final profile = await backend.profile(widget.uid);
    if (profile == null || me == null) return null;
    final day = localDayKey(DateTime.now());
    final friends = await backend.friends(me).first;
    final scores = rank(await backend.scoresOf(day, [...friends, me]).first);
    final at = scores.indexWhere((score) => score.uid == widget.uid);
    return (
      profile: profile,
      name: await backend.friendName(widget.uid) ?? '',
      today: at < 0 ? 0 : scores[at].count,
      rank: at < 0 ? null : at + 1,
    );
  }

  Future<void> _send(InboxKind kind) async {
    final account = context.read<AccountCubit>();
    final sent = await account.backend.send(
      widget.uid,
      InboxItem.create(
        kind: kind,
        fromUid: account.state.uid!,
        fromName: account.state.friendName,
        now: DateTime.now(),
      ),
    );
    if (!sent || !mounted) return;
    GameAudio.instance.play(kind == InboxKind.banana ? Sfx.banana : Sfx.pop);
    setState(() {
      if (kind == InboxKind.wave) _waved = true;
      if (kind == InboxKind.banana) _bananaSent = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sky = islandSky(context);
    final l = context.l10n;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [sky.top, sky.horizon],
            stops: const [0, 0.55],
          ),
        ),
        child: FutureBuilder<_Visit?>(
          future: _visit,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            final visit = snapshot.data;
            if (visit == null) {
              return SafeArea(
                child: Column(
                  children: [
                    _BackRow(onBack: () => Navigator.of(context).pop()),
                    Expanded(
                      child: Center(
                        child: Text(
                          l.visitGone,
                          style: context.textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            final name = friendLabel(context, visit.profile, visit.name);

            return Stack(
              children: [
                Positioned.fill(
                  child: IslandScene(
                    snapshot: IslandSnapshot.fromJson(visit.profile.island),
                    greetings: [
                      l.visitGreet1,
                      l.visitGreet2,
                      l.visitGreet3,
                      l.visitGreet4,
                      l.visitGreet5,
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(PBSpace.lg),
                    child: Column(
                      children: [
                        _FriendCard(
                          profile: visit.profile,
                          name: name,
                          onBack: () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: PBSpace.sm,
                          runSpacing: PBSpace.sm,
                          children: [
                            SocialChip(l.visitToday(visit.today), emoji: '💪'),
                            if (visit.rank case final rank?)
                              SocialChip(l.visitRank(rank), emoji: '🏆'),
                            SocialChip(
                              l.visitFriends(visit.profile.friendCount),
                              emoji: '🐒',
                            ),
                          ],
                        ),
                        const SizedBox(height: PBSpace.lg),
                        Row(
                          children: [
                            Expanded(
                              child: _ActionButton(
                                label:
                                    _waved ? l.visitWaved : '👋 ${l.visitWave}',
                                onTap: _waved
                                    ? null
                                    : () => unawaited(_send(InboxKind.wave)),
                              ),
                            ),
                            const SizedBox(width: PBSpace.md),
                            Expanded(
                              child: _ActionButton(
                                label: _bananaSent
                                    ? l.visitBananaSent
                                    : '🍌 ${l.visitBanana}',
                                color: context.gameColors.banana,
                                ink: context.gameColors.onBanana,
                                onTap: _bananaSent
                                    ? null
                                    : () => unawaited(_send(InboxKind.banana)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BackRow extends StatelessWidget {
  const _BackRow({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.all(PBSpace.lg),
          child: IconButton.filledTonal(
            onPressed: onBack,
            icon: const Icon(CarbonIcons.chevron_left),
          ),
        ),
      );
}

/// The friend's card on top: back, their avatar, "Mia's island", level and
/// friends, and their streak.
class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.profile,
    required this.name,
    required this.onBack,
  });

  final BroProfile profile;
  final String name;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Container(
      padding: const EdgeInsets.all(PBSpace.sm),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(PBRadius.pill),
        boxShadow: context.cardShadow,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(CarbonIcons.chevron_left),
          ),
          BroAvatar(look: profile.look),
          const SizedBox(width: PBSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.visitTitle(name),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  l.visitSubtitle(profile.islandLevel, profile.friendCount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SocialChip(
            '${profile.streak}',
            emoji: '🔥',
            color: context.tint(context.gameColors.orange),
          ),
          const SizedBox(width: PBSpace.sm),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.color,
    this.ink,
  });

  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final Color? ink;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: onTap == null ? 0.7 : 1,
          child: Container(
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color ?? context.colorScheme.surface,
              borderRadius: BorderRadius.circular(PBRadius.pill),
              boxShadow: context.cardShadow,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
          ),
        ),
      );
}
