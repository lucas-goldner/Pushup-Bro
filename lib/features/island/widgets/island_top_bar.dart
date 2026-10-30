import 'package:flutter/material.dart';
import 'package:pushup_bro/features/island/model/quest_type.dart';
import 'package:pushup_bro/features/island/widgets/banana_counter.dart';
import 'package:pushup_bro/features/island/widgets/community_goal.dart';
import 'package:pushup_bro/features/pro/widgets/just_looking_pill.dart';

/// The island's top row: as tall as the menu button's circle, and as far
/// from the top and the side.
const kIslandHudHeight = 48.0;
const kIslandHudTop = 4.0;
const kIslandHudMargin = 12.0;

/// The menu button's circle and the gap after it.
const double _kMenuSpace = kIslandHudMargin + kIslandHudHeight + 8;

class IslandTopBar extends StatelessWidget {
  const IslandTopBar({
    required this.openQuest,
    this.locked = false,
    this.onJustLooking,
    super.key,
  });

  final void Function(QuestType questType) openQuest;

  /// Without Pro, a "Just looking" pill takes the community goal's place.
  final bool locked;
  final VoidCallback? onJustLooking;

  // One row with the menu button the page draws top left: the same
  // height and centre line, and the same margin on the right.
  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            _kMenuSpace,
            kIslandHudTop,
            kIslandHudMargin,
            0,
          ),
          child: SizedBox(
            height: kIslandHudHeight,
            child: Row(
              children: [
                if (locked) ...[
                  const Spacer(),
                  JustLookingPill(onTap: onJustLooking),
                ] else
                  Expanded(
                    child: CommunityGoal(
                      openMenu: () => openQuest(QuestType.community),
                      width: null,
                      height: kIslandHudHeight,
                    ),
                  ),
                const SizedBox(width: 8),
                const BananaCounter(height: kIslandHudHeight),
              ],
            ),
          ),
        ),
      );
}
