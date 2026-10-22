import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/model/quest_log.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';
import 'package:pushup_bro/core/style/pb_text_styles.dart';
import 'package:pushup_bro/features/jungle/model/jungle_quest.dart';
import 'package:pushup_bro/features/jungle/widgets/jungle_scene.dart';
import 'package:pushup_bro/features/jungle/widgets/quest_card.dart';
import 'package:pushup_bro/features/quest/quest_page.dart';

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
                      'Jungle',
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
                        QuestLog>(
                      selector: (state) => state.inventory.quests,
                      builder: (context, log) {
                        final done = log.completedOn(DateTime.now());

                        return QuestCard(
                          quest: quest,
                          done: done,
                          completedQuests: log.total,
                          onPlay: () => _play(quest, replay: done),
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
