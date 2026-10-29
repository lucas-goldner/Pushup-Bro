import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/menu/model/menu_tab_info.dart';
import 'package:pushup_bro/features/social/cubit/bros_cubit.dart';
import 'package:pushup_bro/features/social/domain/ranking.dart';
import 'package:pushup_bro/features/social/model/bro_profile.dart';
import 'package:pushup_bro/features/social/model/day_score.dart';
import 'package:pushup_bro/features/social/widgets/bro_avatar.dart';
import 'package:pushup_bro/features/social/widgets/social_widgets.dart';

const _kRowHeight = 68.0;
const _kRowGap = 10.0;
const _kMove = Duration(milliseconds: 450);

/// One line on the board.
class BoardRow {
  const BoardRow({
    required this.uid,
    required this.place,
    required this.look,
    required this.name,
    required this.subtitle,
    required this.count,
    this.isMe = false,
    this.showToday = false,
  });

  /// A bro on the Friends board: their streak below the name.
  factory BoardRow.bro(BuildContext context, Bro bro, {required int place}) =>
      BoardRow(
        uid: bro.uid,
        place: place,
        look: bro.profile.look,
        name: bro.isMe
            ? context.l10n.boardYou
            : friendLabel(context, bro.profile, bro.name),
        subtitle: bro.today == 0
            ? context.l10n.boardNotStarted
            : '🔥 ${context.l10n.boardStreak(bro.profile.streak)}',
        count: bro.today,
        isMe: bro.isMe,
        showToday: true,
      );

  /// A stranger on the Everyone board: only their bro name.
  factory BoardRow.score(
    BuildContext context,
    DayScore score, {
    required int place,
    required bool isMe,
  }) =>
      BoardRow(
        uid: score.uid,
        place: place,
        look: score.look,
        name: isMe
            ? context.l10n.boardYouName(broNameOf(context, score.broName))
            : broNameOf(context, score.broName),
        subtitle: context.l10n.boardToday,
        count: score.count,
        isMe: isMe,
      );

  final String uid;
  final int place;
  final MonkeyLook look;
  final String name;
  final String subtitle;
  final int count;
  final bool isMe;

  /// "today" after the number, on the Friends board.
  final bool showToday;
}

/// The rows of the board; when a bro moves up, their row slides to its
/// new place and the number rolls.
class BoardRows extends StatelessWidget {
  const BoardRows({required this.rows, super.key});

  final List<BoardRow> rows;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: rows.isEmpty
            ? 0
            : rows.length * (_kRowHeight + _kRowGap) - _kRowGap,
        child: Stack(
          children: [
            for (final (i, row) in rows.indexed)
              AnimatedPositioned(
                key: ValueKey(row.uid),
                duration: _kMove,
                curve: Curves.easeOutCubic,
                top: i * (_kRowHeight + _kRowGap),
                left: 0,
                right: 0,
                height: _kRowHeight,
                child: _Row(row),
              ),
          ],
        ),
      );
}

class _Row extends StatelessWidget {
  const _Row(this.row);

  final BoardRow row;

  @override
  Widget build(BuildContext context) {
    final medal = switch (row.place) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => null,
    };

    return SocialCard(
      outline: row.isMe ? context.colorScheme.secondary : null,
      padding: const EdgeInsets.symmetric(horizontal: PBSpace.md),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              medal ?? '${row.place}',
              textAlign: TextAlign.center,
              style: context.textTheme.labelLarge?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: PBSpace.sm),
          BroAvatar(look: row.look, size: 42),
          const SizedBox(width: PBSpace.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  row.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          RollingCount(
            row.count,
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (row.showToday) ...[
            const SizedBox(width: 3),
            Text(
              context.l10n.boardToday,
              style: context.textTheme.labelSmall?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A number that rolls up (or down) to [value] when it changes.
class RollingCount extends StatelessWidget {
  const RollingCount(this.value, {this.style, super.key});

  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(end: value.toDouble()),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 700),
        curve: Curves.easeOutCubic,
        builder: (context, shown, _) => Text(
          '${shown.round()}',
          style: style?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      );
}

/// The next small win, always encouraging: how many to pass the next bro,
/// or that the player is on top.
class NextWinCard extends StatelessWidget {
  const NextWinCard({
    required this.win,
    required this.started,
    required this.nameOf,
    super.key,
  });

  final NextWin? win;
  final bool started;
  final String Function(String uid) nameOf;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final (title, subtitle, emoji) = switch (win) {
      _ when !started => (l.boardStart, l.boardStartSub, '💪'),
      PassNext(:final ahead, :final more) => (
          l.boardPass(more, nameOf(ahead.uid)),
          l.boardPassSub,
          '🚀',
        ),
      OnTop() => (l.boardOnTop, l.boardOnTopSub, '👑'),
      null => (l.boardStart, l.boardStartSub, '💪'),
    };
    final scheme = context.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        PBSpace.lg,
        PBSpace.md,
        PBSpace.md,
        PBSpace.md,
      ),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(PBRadius.lg),
        boxShadow: context.cardShadow,
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: PBSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: context.textTheme.titleSmall?.copyWith(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: scheme.onPrimary.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          if (win is! OnTop || !started)
            GestureDetector(
              onTap: () => MenuTabInfo.pushupTracking.navigate(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: PBSpace.lg,
                  vertical: PBSpace.sm,
                ),
                decoration: BoxDecoration(
                  color: context.gameColors.banana,
                  borderRadius: BorderRadius.circular(PBRadius.pill),
                ),
                child: Text(
                  l.boardGo,
                  style: context.textTheme.labelLarge?.copyWith(
                    color: context.gameColors.onBanana,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// The player's own place on the Everyone board, pinned at the bottom.
class MyPlaceCard extends StatelessWidget {
  const MyPlaceCard({
    required this.me,
    required this.today,
    required this.rank,
    required this.players,
    required this.format,
    super.key,
  });

  final BroProfile me;
  final int today;
  final int? rank;
  final int players;
  final NumberFormat format;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final place = rank;
    final percent = place == null || players == 0
        ? null
        : (place * 100 / players).ceil().clamp(1, 100);

    return SocialCard(
      outline: context.colorScheme.secondary,
      padding: const EdgeInsets.all(PBSpace.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: context.tint(context.colorScheme.secondary),
              borderRadius: BorderRadius.circular(PBRadius.pill),
            ),
            child: Text(
              place == null ? '–' : '#${format.format(place)}',
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colorScheme.secondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: PBSpace.sm),
          BroAvatar(look: me.look, size: 42),
          const SizedBox(width: PBSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.boardYouName(broNameOf(context, me.broName)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  percent == null
                      ? l.boardNotOnYet
                      : l.boardTopPercent(percent),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          RollingCount(
            today,
            style: context.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
