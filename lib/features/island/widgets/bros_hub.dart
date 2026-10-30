import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/friends/friends.dart';
import 'package:pushup_bro/features/island/widgets/island_subpage.dart';
import 'package:pushup_bro/features/leaderboard/leaderboard.dart';
import 'package:pushup_bro/features/social/widgets/social_widgets.dart';

/// Where the tabs sit below the safe area: under the header.
const _kTabsTop = 68.0;

/// Room the pages leave above themselves for the header and the tabs.
const double _kPageTop = _kTabsTop + 44 + PBSpace.lg;

/// The bros, opened from the island: today's board and the friends list
/// as two tabs of one screen.
class BrosHub extends StatefulWidget {
  const BrosHub({this.initialTab = 0, super.key});

  /// 0 for Today, 1 for Bros.
  final int initialTab;

  @override
  State<BrosHub> createState() => _BrosHubState();
}

class _BrosHubState extends State<BrosHub> {
  late int _tab = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return IslandSubpage(
      title: l.friends,
      child: Stack(
        children: [
          Positioned.fill(
            child: _tab == 0
                ? const Leaderboard(
                    key: ValueKey('today'),
                    topPadding: _kPageTop,
                    compactTabs: true,
                  )
                : const Friends(key: ValueKey('bros'), topPadding: _kPageTop),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                PBSpace.lg,
                _kTabsTop,
                PBSpace.lg,
                0,
              ),
              child: SocialTabs(
                labels: [l.leaderboard, l.friends],
                selected: _tab,
                onSelect: (tab) => setState(() => _tab = tab),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
