import 'dart:async';
import 'dart:math' as math;

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/cosmetic_names.dart';
import 'package:pushup_bro/core/model/cosmetics.dart';
import 'package:pushup_bro/core/model/trek_progress.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';
import 'package:pushup_bro/core/style/pb_text_styles.dart';
import 'package:pushup_bro/core/widgets/island_sheet.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/trek/model/trek.dart';
import 'package:pushup_bro/features/trek/trek_stage_page.dart';
import 'package:pushup_bro/features/trek/widgets/rest_panel.dart';
import 'package:pushup_bro/features/trek/widgets/stats_sheet.dart';
import 'package:pushup_bro/features/wardrobe/widgets/cosmetic_tile.dart';

const _stageGap = 150.0;

/// Whether [stage] can be played: the first, or the one after a cleared
/// stage.
bool unlocked(TrekProgress trek, TrekStage stage) {
  final index = TrekStage.all.indexOf(stage);

  return index == 0 || trek.cleared(TrekStage.all[index - 1].id);
}

/// The first stage not cleared yet (or the last, once all are).
TrekStage currentStage(TrekProgress trek) => TrekStage.all.firstWhere(
      (stage) => !trek.cleared(stage.id),
      orElse: () => TrekStage.all.last,
    );

/// The Jungle Trek's map: a trail winding up through the jungle from the
/// Fern Trail to the Throne of Scales, a node per stage.
class TrekMapPage extends StatefulWidget {
  const TrekMapPage({super.key});
  static const routeName = '/trek';

  @override
  State<TrekMapPage> createState() => _TrekMapPageState();
}

class _TrekMapPageState extends State<TrekMapPage> {
  TrekStage? _selected;
  bool _white = true;
  bool _stats = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _white = false);
    });
  }

  Future<void> _play(TrekStage stage) async {
    setState(() => _white = true);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    await Navigator.of(context).pushNamed(
      TrekStagePage.routeName,
      arguments: stage,
    );
    if (mounted) setState(() => _white = false);
  }

  Future<void> _leave() async {
    setState(() => _white = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) =>
      BlocSelector<GameInventoryCubit, GameInventoryState, TrekProgress>(
        selector: (state) => state.inventory.trek,
        builder: (context, trek) {
          final selected = _selected ?? currentStage(trek);
          final safe = MediaQuery.paddingOf(context);

          return Scaffold(
            backgroundColor: const Color(0xFF1F4A33),
            body: Stack(
              children: [
                Positioned.fill(
                  child: _Trail(
                    trek: trek,
                    selected: selected,
                    onSelect: (stage) => setState(() => _selected = stage),
                    bottomPadding: 330 + safe.bottom,
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: _TopBar(
                    trek: trek,
                    onBack: _leave,
                    onStats: () => setState(() => _stats = true),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: safe.bottom + 16,
                  child: _StagePanel(
                    key: ValueKey(selected.id),
                    stage: selected,
                    trek: trek,
                    onPlay: () => _play(selected),
                  ),
                ),
                if (_stats)
                  StatsSheet(onClose: () => setState(() => _stats = false)),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      opacity: _white ? 1 : 0,
                      duration: const Duration(milliseconds: 420),
                      child: const ColoredBox(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.trek,
    required this.onBack,
    required this.onStats,
  });

  final TrekProgress trek;
  final VoidCallback onBack;
  final VoidCallback onStats;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF123524),
            const Color(0xFF123524).withValues(alpha: 0),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Row(
            children: [
              Material(
                color: Colors.white,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onBack,
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(CarbonIcons.arrow_left, color: background2),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l.trekTitle,
                        maxLines: 1,
                        style: pageTitleTextStyle.copyWith(
                          color: Colors.white,
                          fontSize: 26,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          l.trekLevel(trek.level),
                          style: buttonTextStyle.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: trek.xp / trek.nextLevelXp,
                              minHeight: 7,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              valueColor: const AlwaysStoppedAnimation(
                                Color(0xFFF5C343),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Badge(
                isLabelVisible: trek.points > 0,
                label: Text('${trek.points}'),
                backgroundColor: const Color(0xFFE5534B),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: onStats,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      child: Text(
                        '💪 ${l.trekStats}',
                        style: buttonTextStyle.copyWith(
                          color: background2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The trail and its stage nodes, scrolled to the current stage.
class _Trail extends StatefulWidget {
  const _Trail({
    required this.trek,
    required this.selected,
    required this.onSelect,
    required this.bottomPadding,
  });

  final TrekProgress trek;
  final TrekStage selected;
  final ValueChanged<TrekStage> onSelect;
  final double bottomPadding;

  @override
  State<_Trail> createState() => _TrailState();
}

class _TrailState extends State<_Trail> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Start with the current stage in view (the trail runs bottom to top).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final index = TrekStage.all.indexOf(currentStage(widget.trek));
      _scroll.jumpTo(
        math.min(
          _scroll.position.maxScrollExtent,
          math.max(0, index - 1) * _stageGap,
        ),
      );
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Offset _node(int index, double width) => Offset(
        width / 2 + math.sin(index * 1.35) * width * 0.27,
        (TrekStage.all.length - 1 - index) * _stageGap + 150,
      );

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = (TrekStage.all.length - 1) * _stageGap + 150 + 120;
          final current = currentStage(widget.trek);

          return SingleChildScrollView(
            controller: _scroll,
            reverse: true,
            padding: EdgeInsets.only(bottom: widget.bottomPadding),
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TrailPainter(
                        points: [
                          for (var i = 0; i < TrekStage.all.length; i++)
                            _node(i, width),
                        ],
                        clearedUpTo: TrekStage.all
                            .where((s) => widget.trek.cleared(s.id))
                            .length,
                      ),
                    ),
                  ),
                  // Jungle around the trail.
                  for (var i = 0; i < 22; i++)
                    Positioned(
                      left: (i * 97 % 100) / 100 * width - 20,
                      top: i * height / 22,
                      child: Opacity(
                        opacity: 0.55,
                        child: Text(
                          ['🌴', '🌿', '🌳', '🪨', '🍄', '🌺'][i % 6],
                          style: TextStyle(fontSize: 26.0 + (i * 7 % 18)),
                        ),
                      ),
                    ),
                  for (final (i, stage) in TrekStage.all.indexed)
                    Positioned(
                      left: _node(i, width).dx - 60,
                      top: _node(i, width).dy - 44,
                      width: 120,
                      child: _StageNode(
                        stage: stage,
                        stars: widget.trek.stars[stage.id] ?? 0,
                        unlocked: unlocked(widget.trek, stage),
                        current:
                            stage == current && !widget.trek.cleared(stage.id),
                        selected: stage == widget.selected,
                        onTap: () => widget.onSelect(stage),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
}

class _TrailPainter extends CustomPainter {
  _TrailPainter({required this.points, required this.clearedUpTo});

  final List<Offset> points;
  final int clearedUpTo;

  Path _path(Iterable<Offset> along) {
    final list = along.toList();
    final path = Path()..moveTo(list.first.dx, list.first.dy);
    for (var i = 1; i < list.length; i++) {
      final a = list[i - 1];
      final b = list[i];
      path.cubicTo(
        a.dx,
        (a.dy + b.dy) / 2,
        b.dx,
        (a.dy + b.dy) / 2,
        b.dx,
        b.dy,
      );
    }

    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final all = _path(points);
    canvas
      ..drawPath(
        all,
        Paint()
          ..color = const Color(0xFF173D2A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 30
          ..strokeCap = StrokeCap.round,
      )
      ..drawPath(
        all,
        Paint()
          ..color = const Color(0xFFC79A64)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20
          ..strokeCap = StrokeCap.round,
      );
    if (clearedUpTo > 0) {
      canvas.drawPath(
        _path(points.take(math.min(points.length, clearedUpTo + 1))),
        Paint()
          ..color = const Color(0xFFF5C343)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_TrailPainter oldDelegate) =>
      oldDelegate.clearedUpTo != clearedUpTo || oldDelegate.points != points;
}

class _StageNode extends StatelessWidget {
  const _StageNode({
    required this.stage,
    required this.stars,
    required this.unlocked,
    required this.current,
    required this.selected,
    required this.onTap,
  });

  final TrekStage stage;
  final int stars;
  final bool unlocked;
  final bool current;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cleared = stars > 0;
    final color = cleared
        ? const Color(0xFF2FA37A)
        : unlocked
            ? const Color(0xFFF5A623)
            : const Color(0xFF6B7A72);

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1400),
            builder: (context, t, child) => Container(
              width: 86,
              height: 86,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? Colors.white
                      : current
                          ? const Color(0xFFF5C343).withValues(alpha: 0.6)
                          : Colors.transparent,
                  width: 4,
                ),
              ),
              child: child,
            ),
            child: Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: current ? 22 : 10,
                    spreadRadius: current ? 4 : 0,
                  ),
                ],
              ),
              child: Text(
                unlocked ? stage.emoji : '🔒',
                style: const TextStyle(fontSize: 30),
              ),
            ),
          ),
          if (cleared)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < 3; i++)
                  Icon(
                    CarbonIcons.star_filled,
                    size: 16,
                    color: i < stars
                        ? const Color(0xFFF5C343)
                        : Colors.white.withValues(alpha: 0.3),
                  ),
              ],
            ),
          Text(
            stage.title(context.l10n),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: buttonTextStyle.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              shadows: const [Shadow(color: Color(0xAA000000), blurRadius: 6)],
            ),
          ),
        ],
      ),
    );
  }
}

class _StagePanel extends StatelessWidget {
  const _StagePanel({
    required this.stage,
    required this.trek,
    required this.onPlay,
    super.key,
  });

  final TrekStage stage;
  final TrekProgress trek;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final open = unlocked(trek, stage);
    final cleared = trek.cleared(stage.id);
    final enemies = {
      for (final wave in stage.waves)
        for (final e in wave) '${e.species}${e.color}': e,
    }.values;
    final loot = Cosmetic.byId(stage.loot)!;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, (1 - t) * 40),
        child: Opacity(opacity: t.clamp(0, 1), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(18),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 30,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SheetBadge(stage.emoji, color: const Color(0xFF2FA37A)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.trekStageNumber(stage.number),
                        style: buttonTextStyle.copyWith(
                          color: const Color(0xFF2FA37A),
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        stage.title(l),
                        style: pageTitleTextStyle.copyWith(
                          color: background2,
                          fontSize: 22,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              stage.blurb(l),
              style: defaultTextStyle.copyWith(
                fontSize: 14,
                color: background2.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final e in enemies) EnemyChip(spec: e)],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 54,
                  child: CosmeticTile(
                    cosmetic: loot,
                    matColor: const Color(0xFF3FAE6A),
                    owned: true,
                    worn: false,
                    tryingOn: false,
                    locked: false,
                    onTap: () {},
                    compact: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cleared ? l.trekRewardClaimed : l.trekReward,
                        style: defaultTextStyle.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: background2.withValues(alpha: 0.55),
                        ),
                      ),
                      Text(
                        loot.label(l),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: buttonTextStyle.copyWith(
                          color: background2,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (open)
                  PillButton(
                    label: cleared ? l.trekReplay : l.trekStart,
                    icon: CarbonIcons.play_filled_alt,
                    color: cleared ? background2 : const Color(0xFF2FA37A),
                    onPressed: onPlay,
                    compact: true,
                  ),
              ],
            ),
            if (!open) ...[
              const SizedBox(height: 10),
              SheetTag(
                l.trekLocked,
                icon: CarbonIcons.locked,
                color: const Color(0xFF6B7A72),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
