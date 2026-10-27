import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

class IntroQuest extends StatefulWidget {
  const IntroQuest({
    required this.onClose,
    super.key,
  });

  final VoidCallback onClose;

  @override
  State<IntroQuest> createState() => _IntroQuestState();
}

class _IntroQuestState extends State<IntroQuest> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 400,
        child: PageView(
          controller: _pageController,
          children: [
            _buildPage(
              text: context.l10n.intro1,
              image: Assets.images.island.quests.intro.part1.image(
                width: 160,
                height: 160,
              ),
            ),
            _buildPage(
              text: context.l10n.intro2,
              image: Assets.images.island.quests.intro.part2.image(
                width: 160,
                height: 160,
              ),
            ),
            _buildPage(
              text: context.l10n.intro3,
              image: Assets.images.island.quests.intro.part3.image(
                width: 160,
                height: 160,
              ),
              showArrow: false,
            ),
          ],
        ),
      );

  Widget _buildPage({
    required String text,
    required Widget image,
    bool showArrow = true,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(PBRadius.lg),
              child: image,
            ),
            const SizedBox(height: PBSpace.lg),
            Expanded(
              child: Text(
                text.trim(),
                textAlign: TextAlign.center,
                style: context.textTheme.bodyLarge?.copyWith(height: 1.45),
              ),
            ),
            if (showArrow)
              PillButton(
                label: context.l10n.introNext,
                icon: CarbonIcons.arrow_right,
                onPressed: () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
              )
            else
              PillButton(
                label: context.l10n.introHelp,
                icon: CarbonIcons.favorite_filled,
                onPressed: widget.onClose,
              ),
          ],
        ),
      );
}
