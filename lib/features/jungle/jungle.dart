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
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/one_move.dart';
import 'package:pushup_bro/features/jungle/model/jungle_quest.dart';
import 'package:pushup_bro/features/jungle/widgets/jungle_loader.dart';
import 'package:pushup_bro/features/jungle/widgets/jungle_scene.dart';
import 'package:pushup_bro/features/jungle/widgets/quest_card.dart';
import 'package:pushup_bro/features/pro/pro_access.dart';
import 'package:pushup_bro/features/quest/quest_page.dart';
import 'package:pushup_bro/features/trek/trek_map_page.dart';
import 'package:pushup_bro/features/trek/widgets/trek_card.dart';

/// Deep inside the island's jungle: Carlos in a clearing, and today's
/// quest popping up.
///
/// It opens out of white (the island fades to white as Carlos runs in)
/// and fades back to white on the way out. Carlos hops on the white
/// until the clearing is fully drawn.
class Jungle extends StatefulWidget {
  const Jungle({super.key});
  static const routeName = '/jungle';

  @override
  State<Jungle> createState() => _JungleState();
}

/// Opens the jungle anyway if the scene never reports ready.
const _kLoadTimeout = Duration(seconds: 8);

/// The quest pops up this long after the clearing appears.
const _kQuestDelay = Duration(milliseconds: 1300);

class _JungleState extends State<Jungle> with OneMove {
  bool _white = true;
  bool _loaded = false;
  bool _questShown = false;
  Timer? _loadTimeout;

  /// Whether the story is picked over today's challenge; until the player
  /// picks, the story once today's challenge is done.
  bool? _story;

  @override
  void initState() {
    super.initState();
    _loadTimeout = Timer(_kLoadTimeout, _onLoaded);
  }

  /// The clearing is fully drawn: it appears out of white, then the quest
  /// pops up.
  void _onLoaded() {
    _loadTimeout?.cancel();
    if (_loaded || !mounted) return;
    setState(() {
      _loaded = true;
      _white = false;
    });
    unawaited(
      Future<void>.delayed(_kQuestDelay, () {
        if (mounted) setState(() => _questShown = true);
      }),
    );
  }

  @override
  void dispose() {
    _loadTimeout?.cancel();
    super.dispose();
  }

  Future<void> _leave() => oneMove(() async {
        GameAudio.instance.play(Sfx.whoosh);
        setState(() => _white = true);
        await Future<void>.delayed(const Duration(milliseconds: 450));
        if (!popIfOnTop() && mounted) setState(() => _white = false);
      });

  Future<void> _trek() => oneMove(_openTrek);

  Future<void> _openTrek() async {
    if (!await ensureProAccess(context) || !mounted) return;
    GameAudio.instance.play(Sfx.whoosh);
    setState(() => _white = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    await Navigator.of(context).pushNamed(TrekMapPage.routeName);
    if (mounted) setState(() => _white = false);
  }

  Future<void> _play(JungleQuest quest, {required bool replay}) =>
      oneMove(() => _openQuest(quest, replay: replay));

  Future<void> _openQuest(JungleQuest quest, {required bool replay}) async {
    if (!await ensureProAccess(context) || !mounted) return;
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
    final scheme = context.colorScheme;
    final game = context.gameColors;
    // The island fades to white as Carlos runs in, in both modes.
    final whiteout = game.flash;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        backgroundColor: whiteout,
        body: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [game.jungleDeep, jungleMistOf(context)],
                    stops: const [0, 0.6],
                  ),
                ),
              ),
            ),
            Positioned.fill(child: JungleScene(onReady: _onLoaded)),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Row(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: context.cardShadow,
                      ),
                      child: Material(
                        color: scheme.surface,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: _leave,
                          child: SizedBox(
                            width: 48,
                            height: 48,
                            child: Icon(
                              CarbonIcons.arrow_left,
                              color: scheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: PBSpace.md),
                    Text(
                      context.l10n.islandJungle,
                      style: context.textTheme.headlineLarge?.copyWith(
                        color: game.onGame,
                        shadows: [
                          Shadow(
                            color: scheme.shadow.withValues(alpha: 0.35),
                            blurRadius: 12,
                          ),
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
                  child: ColoredBox(color: whiteout),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child:
                      _loaded ? const SizedBox.shrink() : const JungleLoader(),
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
    final game = context.gameColors;

    return Container(
      constraints: const BoxConstraints(maxWidth: 520),
      padding: const EdgeInsets.all(PBSpace.xs),
      decoration: BoxDecoration(
        color: context.colorScheme.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(PBRadius.pill),
        boxShadow: context.cardShadow,
      ),
      child: Row(
        children: [
          _ModeTab(
            emoji: dailyDone ? '✅' : '☀️',
            label: l.jungleTabDaily,
            selected: !story,
            color: game.jungle,
            onTap: () => onPick(false),
          ),
          _ModeTab(
            emoji: '🦎',
            label: l.jungleTabStory,
            badge: '$stage',
            selected: story,
            color: game.jungleDeep,
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
    final foreground =
        selected ? context.gameColors.onGame : context.colorScheme.onSurface;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(PBRadius.pill),
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
                  style: context.textTheme.labelMedium?.copyWith(
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
                        ? context.gameColors.onGame.withValues(alpha: 0.25)
                        : context.tint(color),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge!,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: foreground,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0,
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
