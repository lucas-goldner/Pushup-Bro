import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';
import 'package:pushup_bro/core/style/pb_text_styles.dart';
import 'package:pushup_bro/features/island/model/quest_type.dart';
import 'package:pushup_bro/features/island/widgets/quests/jungle_quest.dart';
import 'package:pushup_bro/features/jungle/widgets/jungle_scene.dart';

/// Deep inside the island's jungle: Carlos in a clearing, and today's
/// jungle quest.
class Jungle extends StatelessWidget {
  const Jungle({super.key});
  static const routeName = '/jungle';

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1F5A3C), jungleMist],
                    stops: [0, 0.6],
                  ),
                ),
              ),
            ),
            const Positioned.fill(child: JungleScene()),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        fixedSize: const Size(48, 48),
                      ),
                      icon: const Icon(
                        CarbonIcons.arrow_left,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      context.l10n.islandJungle,
                      style: pageTitleTextStyle.copyWith(
                        fontSize: 30,
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Color(0x55000000), blurRadius: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _QuestCard(onClose: () => Navigator.of(context).pop()),
                ),
              ),
            ),
          ],
        ),
      );
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.42,
          maxWidth: 520,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: background2.withValues(alpha: 0.25),
                blurRadius: 40,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  QuestType.jungleQuest.getLocalizedTitle(context),
                  style: pageTitleTextStyle.copyWith(
                    fontSize: 22,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(child: JungleQuest(onClose: onClose)),
              ],
            ),
          ),
        ),
      );
}
