import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/features/island/widgets/community_goal.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

class CommunityQuest extends StatelessWidget {
  const CommunityQuest({required this.onClose, super.key});
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            const SizedBox(
              height: 16,
            ),
            Center(
              child: Assets.images.island.quests.community.image(
                width: 140,
                height: 140,
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            CommunityGoal(openMenu: () {}),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                context.l10n.communityText,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyLarge?.copyWith(height: 1.45),
              ),
            ),
          ],
        ),
      );
}
