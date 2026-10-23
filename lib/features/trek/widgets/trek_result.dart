import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/cosmetic_names.dart';
import 'package:pushup_bro/core/model/cosmetics.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';
import 'package:pushup_bro/core/style/pb_text_styles.dart';
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
  Widget build(BuildContext context) {
    final l = context.l10n;
    final reward = widget.reward;
    final loot = reward?.loot == null ? null : Cosmetic.byId(reward!.loot!);

    return Stack(
      children: [
        ColoredBox(
          color: background2.withValues(alpha: 0.4),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l.trekVictory,
                        style: pageTitleTextStyle.copyWith(
                          color: background2,
                          fontSize: 32,
                        ),
                      ),
                      Text(
                        widget.stage.title(l),
                        textAlign: TextAlign.center,
                        style: defaultTextStyle.copyWith(
                          color: background2.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _Stars(stars: reward?.stars ?? 1),
                      const SizedBox(height: 16),
                      if (reward != null)
                        Row(
                          children: [
                            Expanded(
                              child: _Stat(
                                value: '+${reward.xp}',
                                label: l.trekXpEarned,
                                icon: const Icon(
                                  CarbonIcons.star_filled,
                                  color: accentColor,
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
                                color: const Color(0xFFFFF4D6),
                              ),
                            ),
                          ],
                        ),
                      if (reward != null && reward.levelsGained > 0) ...[
                        const SizedBox(height: 12),
                        SheetCard(
                          color: const Color(0xFFFFE9E7),
                          onTap: () => setState(() => _stats = true),
                          child: Row(
                            children: [
                              const Text('⬆️', style: TextStyle(fontSize: 26)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l.trekLevelUp,
                                  style: headerTextStyle.copyWith(
                                    color: background2,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              SheetTag(
                                l.trekSpendPoints,
                                icon: CarbonIcons.add,
                                color: const Color(0xFFE5534B),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (loot != null) ...[
                        const SizedBox(height: 12),
                        SheetCard(
                          color: const Color(0xFFEAF7EE),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 64,
                                child: CosmeticTile(
                                  cosmetic: loot,
                                  matColor: const Color(0xFF3FAE6A),
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
                                      style: buttonTextStyle.copyWith(
                                        color: const Color(0xFF2FA37A),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      loot.label(l),
                                      style: headerTextStyle.copyWith(
                                        color: background2,
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
                        const SizedBox(height: 12),
                        SheetCard(
                          color: const Color(0xFFFFF4D6),
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
                                      style: buttonTextStyle.copyWith(
                                        color: background2,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      l.trekAdoptInfo,
                                      style: defaultTextStyle.copyWith(
                                        fontSize: 13,
                                        color:
                                            background2.withValues(alpha: 0.65),
                                      ),
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
                        ? const Color(0xFFF5C343)
                        : background2.withValues(alpha: 0.12),
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
    this.color = background,
  });

  final String value;
  final String label;
  final Widget icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            SizedBox(height: 28, child: Center(child: icon)),
            Text(
              value,
              style: pushupTextStyle.copyWith(fontSize: 26, color: background2),
            ),
            Text(
              label,
              style: defaultTextStyle.copyWith(
                fontSize: 13,
                color: background2.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
}
