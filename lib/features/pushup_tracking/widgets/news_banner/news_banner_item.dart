import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/features/pushup_tracking/model/news.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

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

  Widget _buildBasicCard(
    BuildContext context,
    Widget content,
  ) =>
      Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: SizedBox(
            height: 25 + (factor * 30),
            width: double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: news.getColor(context),
                boxShadow: [
                  context.shadow,
                ],
              ),
              child: Center(child: content),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => switch (news.type) {
        NewsType.update => _buildBasicCard(
            context,
            _UpdateCard(news),
          ),
        NewsType.friendBoost => _buildBasicCard(
            context,
            _FriendBoostCard(news),
          ),
        NewsType.doublePoinstEvent => _buildBasicCard(
            context,
            _EventDayCard(news),
          ),
      };
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard(this.news);
  final News news;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CarbonIcons.upgrade,
            color: context.colorScheme.onPrimary,
          ),
          const SizedBox(
            width: 12,
          ),
          Text(
            news.title,
            style: context.textTheme.labelLarge?.copyWith(
              color: context.colorScheme.onPrimary,
            ),
          ),
        ],
      );
}

class _FriendBoostCard extends StatelessWidget {
  const _FriendBoostCard(this.news);
  final News news;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Assets.images.itemConnect.image(width: 52, height: 52),
          const SizedBox(
            width: 12,
          ),
          Text(
            news.title,
            style: context.textTheme.labelLarge?.copyWith(
              color: context.colorScheme.primary,
            ),
          ),
        ],
      );
}

class _EventDayCard extends StatelessWidget {
  const _EventDayCard(this.news);
  final News news;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Assets.images.itemDouble.image(width: 52, height: 52),
          const SizedBox(
            width: 12,
          ),
          Text(
            news.title,
            style: context.textTheme.labelLarge?.copyWith(
              color: context.colorScheme.primary,
            ),
          ),
        ],
      );
}
