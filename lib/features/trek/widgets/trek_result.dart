import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/cosmetic_names.dart';
import 'package:pushup_bro/core/model/cosmetics.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/island_sheet.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/trek/model/trek.dart';
import 'package:pushup_bro/features/trek/trek_stage_page.dart';
import 'package:pushup_bro/features/trek/widgets/stats_sheet.dart';
import 'package:pushup_bro/features/wardrobe/widgets/cosmetic_tile.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

/// A won stage: stars, XP and bananas, a level up, the item won and, at the
/// very end, King Komo joining the island.
class TrekResult extends StatefulWidget {
  const TrekResult({
    required this.stage,
    required this.reward,
    required this.onDone,
    super.key,
  });

  final TrekStage stage;
  final TrekReward? reward;
  final VoidCallback onDone;

  @override
  State<TrekResult> createState() => _TrekResultState();
}

class _TrekResultState extends State<TrekResult> {
  bool _stats = false;

  @override
  void initState() {
    super.initState();
    // The rewards' sounds, in the order they appear.
    final reward = widget.reward;
    final audio = GameAudio.instance
      ..playRepeated(Sfx.star, reward?.stars ?? 1);
    if (reward == null) return;
    Future<void>.delayed(
      const Duration(milliseconds: 1100),
      () => audio.play(Sfx.banana),
    );
    if (reward.levelsGained > 0) {
      Future<void>.delayed(
        const Duration(milliseconds: 1600),
        () => audio.play(Sfx.levelUp),
      );
    }
    if (reward.loot != null) {
      Future<void>.delayed(
        const Duration(milliseconds: 2300),
        () => audio.play(Sfx.unlock),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final reward = widget.reward;
    final loot = reward?.loot == null ? null : Cosmetic.byId(reward!.loot!);
    final scheme = context.colorScheme;
    final game = context.gameColors;
    final text = context.textTheme;
    Color tinted(Color color) =>
        Color.alphaBlend(context.tint(color), scheme.surface);

    return Stack(
      children: [
        ColoredBox(
          color: scheme.scrim.withValues(alpha: context.isDark ? 0.55 : 0.4),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeOutBack,
                builder: (context, t, child) => Transform.scale(
                  scale: 0.85 + 0.15 * t,
                  child: Opacity(opacity: t.clamp(0, 1), child: child),
                ),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  constraints: const BoxConstraints(maxWidth: 440),
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: context.cardShadow,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l.trekVictory,
                        style: text.headlineLarge?.copyWith(fontSize: 32),
                      ),
                      Text(
                        widget.stage.title(l),
                        textAlign: TextAlign.center,
                        style: text.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: PBSpace.md),
                      _Stars(stars: reward?.stars ?? 1),
                      const SizedBox(height: PBSpace.lg),
                      if (reward != null)
                        Row(
                          children: [
                            Expanded(
                              child: _Stat(
                                value: '+${reward.xp}',
                                label: l.trekXpEarned,
                                icon: Icon(
                                  CarbonIcons.star_filled,
                                  color: scheme.secondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _Stat(
                                value: '+${reward.bananas}',
                                label: l.questBananas,
                                icon: Assets.images.island.banana
                                    .image(width: 28),
                                color: game.cream,
                              ),
                            ),
                          ],
                        ),
                      if (reward != null && reward.levelsGained > 0) ...[
                        const SizedBox(height: PBSpace.md),
                        SheetCard(
                          color: tinted(game.red),
                          onTap: () => setState(() => _stats = true),
                          child: Row(
                            children: [
                              const Text('⬆️', style: TextStyle(fontSize: 26)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l.trekLevelUp,
                                  style: text.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              SheetTag(
                                l.trekSpendPoints,
                                icon: CarbonIcons.add,
                                color: game.red,
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (loot != null) ...[
                        const SizedBox(height: PBSpace.md),
                        SheetCard(
                          color: tinted(game.jungle),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 64,
                                child: CosmeticTile(
                                  cosmetic: loot,
                                  matColor: game.jungle,
                                  owned: true,
                                  worn: false,
                                  tryingOn: false,
                                  locked: false,
                                  onTap: () {},
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '🎁 ${l.trekNewItem}',
                                      style: text.titleSmall?.copyWith(
                                        color: game.jungle,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      loot.label(l),
                                      style: text.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (reward?.adopted ?? false) ...[
                        const SizedBox(height: PBSpace.md),
                        SheetCard(
                          color: game.cream,
                          child: Row(
                            children: [
                              const Text('👑', style: TextStyle(fontSize: 34)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l.trekAdoptTitle,
                                      style: text.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      l.trekAdoptInfo,
                                      style: text.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      PillButton(
                        label: l.trekBackToMap,
                        icon: CarbonIcons.map,
                        onPressed: widget.onDone,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_stats) StatsSheet(onClose: () => setState(() => _stats = false)),
      ],
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.stars});

  final int stars;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: Duration(milliseconds: 500 + i * 250),
              curve: Curves.elasticOut,
              builder: (context, t, _) => Transform.scale(
                scale: i < stars ? t : 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    CarbonIcons.star_filled,
                    size: i == 1 ? 52 : 42,
                    color: i < stars
                        ? context.gameColors.banana
                        : context.colorScheme.surfaceContainerHigh,
                  ),
                ),
              ),
            ),
        ],
      );
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    required this.icon,
    this.color,
  });

  final String value;
  final String label;
  final Widget icon;

  /// The tile's fill; the page background colour when null.
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(PBSpace.md),
        decoration: BoxDecoration(
          color: color ?? context.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(PBRadius.md),
        ),
        child: Column(
          children: [
            SizedBox(height: 28, child: Center(child: icon)),
            Text(
              value,
              style: context.textTheme.displaySmall?.copyWith(fontSize: 28),
            ),
            Text(label, style: context.textTheme.bodySmall),
          ],
        ),
      );
}
