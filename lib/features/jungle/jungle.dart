import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/quest_log.dart';
import 'package:pushup_bro/core/model/trek_progress.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';
import 'package:pushup_bro/core/style/pb_text_styles.dart';
import 'package:pushup_bro/features/jungle/model/jungle_quest.dart';
import 'package:pushup_bro/features/jungle/widgets/jungle_scene.dart';
import 'package:pushup_bro/features/jungle/widgets/quest_card.dart';
import 'package:pushup_bro/features/quest/quest_page.dart';
import 'package:pushup_bro/features/trek/trek_map_page.dart';
import 'package:pushup_bro/features/trek/widgets/trek_card.dart';

/// Deep inside the island's jungle: Carlos in a clearing, and today's
/// quest popping up.
///
/// It opens out of white (the island fades to white as Carlos runs in)
/// and fades back to white on the way out.
class Jungle extends StatefulWidget {
  const Jungle({super.key});
  static const routeName = '/jungle';

  @override
  State<Jungle> createState() => _JungleState();
}

class _JungleState extends State<Jungle> {
  bool _white = true;
  bool _questShown = false;

  @override
  void initState() {
    super.initState();
    // Let the clearing appear out of white, then the quest pops up.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _white = false);
    });
    unawaited(
      Future<void>.delayed(const Duration(milliseconds: 1900), () {
        if (mounted) setState(() => _questShown = true);
      }),
    );
  }

  Future<void> _leave() async {
    setState(() => _white = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _trek() async {
    setState(() => _white = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    await Navigator.of(context).pushNamed(TrekMapPage.routeName);
    if (mounted) setState(() => _white = false);
  }

  Future<void> _play(JungleQuest quest, {required bool replay}) async {
    setState(() => _white = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    await Navigator.of(context).pushNamed(
      QuestPage.routeName,
      arguments: (quest, replay),
    );
    if (mounted) setState(() => _white = false);
  }

  @override
  Widget build(BuildContext context) {
    final quest = JungleQuest.forDay(DateTime.now());

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        backgroundColor: Colors.white,
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
                    Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _leave,
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            CarbonIcons.arrow_left,
                            color: background2,
                          ),
                        ),
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
            if (_questShown)
              SafeArea(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: BlocSelector<GameInventoryCubit, GameInventoryState,
                        (QuestLog, TrekProgress)>(
                      selector: (state) =>
                          (state.inventory.quests, state.inventory.trek),
                      builder: (context, progress) {
                        final (log, trek) = progress;
                        final done = log.completedOn(DateTime.now());
                        final trekCard = TrekCard(
                          trek: trek,
                          big: done,
                          onPlay: _trek,
                        );

                        // Today's quest first; once it's done, the Trek.
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: done
                              ? [
                                  _DonePill(
                                    onTap: () => _play(quest, replay: true),
                                  ),
                                  const SizedBox(height: 10),
                                  trekCard,
                                ]
                              : [
                                  trekCard,
                                  const SizedBox(height: 10),
                                  QuestCard(
                                    quest: quest,
                                    done: done,
                                    completedQuests: log.total,
                                    onPlay: () => _play(quest, replay: done),
                                  ),
                                ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _white ? 1 : 0,
                  duration: const Duration(milliseconds: 450),
                  curve: Curves.easeOut,
                  child: const ColoredBox(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Today's quest, done: a pill to play it again.
class _DonePill extends StatelessWidget {
  const _DonePill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              '✅ ${context.l10n.trekDailyDone}',
              style: buttonTextStyle.copyWith(
                color: background2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
}
