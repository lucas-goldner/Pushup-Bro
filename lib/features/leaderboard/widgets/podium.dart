import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/leaderboard/widgets/board_rows.dart';
import 'package:pushup_bro/features/social/cubit/bros_cubit.dart';
import 'package:pushup_bro/features/social/widgets/bro_avatar.dart';
import 'package:pushup_bro/features/social/widgets/social_widgets.dart';

/// The top three bros of the day: first in the middle with a crown,
/// second on the left, third on the right.
class Podium extends StatelessWidget {
  const Podium({required this.top, super.key});

  /// Best first; up to three.
  final List<Bro> top;

  @override
  Widget build(BuildContext context) {
    final game = context.gameColors;
    final steps = [
      if (top.length > 1)
        (top[1], 2, 96.0, context.colorScheme.surfaceContainerHigh),
      (top[0], 1, 132.0, game.banana),
      if (top.length > 2) (top[2], 3, 84.0, game.orange.withValues(alpha: 0.8)),
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final (bro, place, height, color) in steps)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: PBSpace.xs),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: Duration(milliseconds: 500 + place * 150),
                curve: Curves.easeOutBack,
                builder: (context, t, child) => Transform.translate(
                  offset: Offset(0, (1 - t) * 40),
                  child: Opacity(opacity: t.clamp(0, 1), child: child),
                ),
                child: Column(
                  children: [
                    if (place == 1)
                      const Text('👑', style: TextStyle(fontSize: 26)),
                    BroAvatar(
                      look: bro.profile.look,
                      size: place == 1 ? 68 : 56,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      bro.isMe
                          ? context.l10n.boardYou
                          : friendLabel(context, bro.profile, bro.name),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: height,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(PBRadius.md),
                        ),
                        border: bro.isMe
                            ? Border.all(
                                color: context.colorScheme.secondary,
                                width: 2,
                              )
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          RollingCount(
                            bro.today,
                            style: context.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: place == 1 ? game.onBanana : null,
                            ),
                          ),
                          Text(
                            '#$place',
                            style: context.textTheme.labelMedium?.copyWith(
                              color: place == 1
                                  ? game.onBanana
                                  : context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
