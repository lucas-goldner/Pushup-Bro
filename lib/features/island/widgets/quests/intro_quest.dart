import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

/// The welcome card after the intro film and the zoom out to the island:
/// what to do, and the button to start.
class IntroQuest extends StatelessWidget {
  const IntroQuest({required this.onClose, super.key});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(PBRadius.lg),
              child: Assets.images.island.quests.intro.part3.image(
                width: 140,
                height: 140,
              ),
            ),
            const SizedBox(height: PBSpace.lg),
            Text(
              context.l10n.intro3.trim(),
              textAlign: TextAlign.center,
              style: context.textTheme.bodyLarge?.copyWith(height: 1.45),
            ),
            const SizedBox(height: PBSpace.xl),
            PillButton(
              label: context.l10n.introHelp,
              icon: CarbonIcons.favorite_filled,
              onPressed: onClose,
            ),
          ],
        ),
      );
}
