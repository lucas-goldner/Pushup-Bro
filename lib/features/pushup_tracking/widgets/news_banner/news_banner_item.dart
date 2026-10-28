import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/pushup_tracking/model/news.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

/// One piece of news: a floating card with a tinted icon tile, the title
/// and its description. It grows as it pages into the middle.
class NewsBannerItem extends StatelessWidget {
  const NewsBannerItem({
    required this.factor,
    required this.index,
    required this.news,
    super.key,
  });

  final double factor;
  final int index;
  final News news;

  Color _accent(BuildContext context) => switch (news.type) {
        NewsType.update => context.colorScheme.secondary,
        NewsType.friendBoost => context.gameColors.banana,
        NewsType.doublePoinstEvent => context.gameColors.purple,
      };

  Widget _icon(BuildContext context) => switch (news.type) {
        NewsType.update => Icon(
            CarbonIcons.upgrade,
            size: 22,
            color: _accent(context),
          ),
        NewsType.friendBoost =>
          Assets.images.itemConnect.image(width: 32, height: 32),
        NewsType.doublePoinstEvent =>
          Assets.images.itemDouble.image(width: 32, height: 32),
      };

  @override
  Widget build(BuildContext context) {
    final t = factor.clamp(0.0, 1.0);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: PBSpace.xl),
        child: Opacity(
          opacity: 0.6 + 0.4 * t,
          child: Container(
            height: 64 + t * 12,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: PBSpace.md),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PBRadius.lg),
              color: context.colorScheme.surface,
              boxShadow: context.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.tint(_accent(context)),
                    borderRadius: BorderRadius.circular(PBRadius.sm),
                  ),
                  child: _icon(context),
                ),
                const SizedBox(width: PBSpace.md),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        news.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.titleSmall,
                      ),
                      if (news.description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          news.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
