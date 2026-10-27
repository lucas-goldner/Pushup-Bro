import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
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

  /// Whether the story is picked over today's challenge; until the player
  /// picks, the story once today's challenge is done.
  bool? _story;

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
    GameAudio.instance.play(Sfx.whoosh);
    setState(() => _white = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _trek() async {
    GameAudio.instance.play(Sfx.whoosh);
    setState(() => _white = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    await Navigator.of(context).pushNamed(TrekMapPage.routeName);
    if (mounted) setState(() => _white = false);
  }

  Future<void> _play(JungleQuest quest, {required bool replay}) async {
    GameAudio.instance.play(Sfx.whoosh);
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
                        final story = _story ?? done;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ModePicker(
                              story: story,
                              dailyDone: done,
                              stage: currentStage(trek).number,
                              onPick: (value) => setState(() => _story = value),
                            ),
                            const SizedBox(height: 10),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: story
                                  ? TrekCard(
                                      key: const ValueKey('story'),
                                      trek: trek,
                                      onPlay: _trek,
                                    )
                                  : QuestCard(
                                      key: const ValueKey('daily'),
                                      quest: quest,
                                      done: done,
                                      completedQuests: log.total,
                                      onPlay: () => _play(quest, replay: done),
                                    ),
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

/// Picks what to play in the jungle: today's challenge or the story.
class _ModePicker extends StatelessWidget {
  const _ModePicker({
    required this.story,
    required this.dailyDone,
    required this.stage,
    required this.onPick,
  });

  final bool story;
  final bool dailyDone;

  /// The story's next stage, shown on its tab.
  final int stage;
  final ValueChanged<bool> onPick;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          _ModeTab(
            emoji: dailyDone ? '✅' : '☀️',
            label: l.jungleTabDaily,
            selected: !story,
            color: const Color(0xFF2FA37A),
            onTap: () => onPick(false),
          ),
          _ModeTab(
            emoji: '🦎',
            label: l.jungleTabStory,
            badge: '$stage',
            selected: story,
            color: const Color(0xFF1F5A3C),
            onTap: () => onPick(true),
          ),
        ],
      ),
    );
  }
}

class _ModeTab extends StatelessWidget {
  const _ModeTab({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.badge,
  });

  final String emoji;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? Colors.white : background2;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: buttonTextStyle.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.25)
                        : color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge!,
                    style: buttonTextStyle.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
