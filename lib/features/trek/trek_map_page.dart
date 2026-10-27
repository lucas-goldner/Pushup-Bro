import 'dart:async';
import 'dart:math' as math;

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/cosmetic_names.dart';
import 'package:pushup_bro/core/model/cosmetics.dart';
import 'package:pushup_bro/core/model/trek_progress.dart';
import 'package:pushup_bro/core/style/extensions/game_colors_theme_extension.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/island_sheet.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/pro/pro_access.dart';
import 'package:pushup_bro/features/trek/model/trek.dart';
import 'package:pushup_bro/features/trek/trek_stage_page.dart';
import 'package:pushup_bro/features/trek/widgets/rest_panel.dart';
import 'package:pushup_bro/features/trek/widgets/stats_sheet.dart';
import 'package:pushup_bro/features/wardrobe/widgets/cosmetic_tile.dart';

const _stageGap = 170.0;

/// [color] with its lightness cut by [amount] (0 to 1).
Color _darken(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);

  return hsl.withLightness(hsl.lightness * (1 - amount)).toColor();
}

/// The map's painted illustration, mixed from the game colours.
@immutable
class _MapArt {
  _MapArt(GameColorsThemeExtension game)
      : zones = [
          Color.lerp(game.jungleDeep, game.leaf, 0.3)!,
          game.jungleDeep,
          Color.lerp(game.jungleDeep, game.grass, 0.2)!,
          _darken(Color.lerp(game.jungleDeep, game.ice, 0.5)!, 0.2),
          _darken(game.map, 0.35),
          _darken(Color.lerp(game.map, game.coral, 0.4)!, 0.4),
          _darken(Color.lerp(game.purple, game.jungleDeep, 0.3)!, 0.5),
          _darken(Color.lerp(game.ice, game.sand, 0.6)!, 0.45),
        ],
        trailEdge = _darken(game.jungleDeep, 0.3),
        trail = Color.lerp(game.map, game.orange, 0.25)!,
        cleared = game.banana,
        light = game.onGame,
        locked = HSLColor.fromColor(game.jungleDeep)
            .withSaturation(0.07)
            .withLightness(0.45)
            .toColor();

  /// The ground colour of each stretch of the trail, from the Fern Trail
  /// up to the misty peak still to come.
  final List<Color> zones;
  final Color trailEdge;
  final Color trail;

  /// The trail walked so far.
  final Color cleared;

  /// Highlights painted on the ground.
  final Color light;

  /// A stage node not unlocked yet.
  final Color locked;

  /// The node for the stretch still to come, in the mist.
  Color get soon => Color.lerp(zones.last, light, 0.15)!;
}

/// Stops on the map: every stage, then the stretch still to come.
int get _stops => TrekStage.all.length + 1;

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
  bool _soon = false;
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
    if (!await ensureProAccess(context) || !mounted) return;
    GameAudio.instance.play(Sfx.whoosh);
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
    GameAudio.instance.play(Sfx.whoosh);
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
          final art = _MapArt(context.gameColors);

          return Scaffold(
            backgroundColor: art.zones.first,
            body: Stack(
              children: [
                Positioned.fill(
                  child: _Trail(
                    art: art,
                    trek: trek,
                    selected: selected,
                    soonSelected: _soon,
                    onSelect: (stage) => setState(() {
                      _selected = stage;
                      _soon = false;
                    }),
                    onSoon: () => setState(() => _soon = true),
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
                  child: _soon
                      ? const _ComingSoonPanel(key: ValueKey('soon'))
                      : _StagePanel(
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
                      // The same white the jungle fades through.
                      child: ColoredBox(color: context.gameColors.flash),
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
    final scheme = context.colorScheme;
    final game = context.gameColors;
    final text = context.textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.scrim.withValues(alpha: 0.45),
            scheme.scrim.withValues(alpha: 0),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
                    onTap: onBack,
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
                        style: text.headlineMedium?.copyWith(
                          color: game.onGame,
                        ),
                      ),
                    ),
                    const SizedBox(height: PBSpace.xs),
                    Row(
                      children: [
                        Text(
                          l.trekLevel(trek.level),
                          style: text.labelMedium?.copyWith(
                            color: game.onGame,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: PBSpace.sm),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: trek.xp / trek.nextLevelXp,
                              minHeight: 7,
                              backgroundColor:
                                  game.onGame.withValues(alpha: 0.2),
                              valueColor: AlwaysStoppedAnimation(game.banana),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PBSpace.md),
              Badge(
                isLabelVisible: trek.points > 0,
                label: Text('${trek.points}'),
                backgroundColor: game.red,
                textColor: game.onGame,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(PBRadius.pill),
                    boxShadow: context.cardShadow,
                  ),
                  child: Material(
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(PBRadius.pill),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(PBRadius.pill),
                      onTap: onStats,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: PBSpace.lg,
                          vertical: PBSpace.md,
                        ),
                        child: Text(
                          '💪 ${l.trekStats}',
                          style: text.titleSmall,
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
    required this.art,
    required this.trek,
    required this.selected,
    required this.soonSelected,
    required this.onSelect,
    required this.onSoon,
    required this.bottomPadding,
  });

  final _MapArt art;
  final TrekProgress trek;
  final TrekStage selected;
  final bool soonSelected;
  final ValueChanged<TrekStage> onSelect;
  final VoidCallback onSoon;
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
      final done = TrekStage.all.every((s) => widget.trek.cleared(s.id));
      final index = TrekStage.all.indexOf(currentStage(widget.trek));
      // Once every stage is cleared, show what's still to come.
      _scroll.jumpTo(
        done
            ? _scroll.position.maxScrollExtent
            : math.min(
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
        (_stops - 1 - index) * _stageGap + 250,
      );

  /// Where stop [index]'s landmark sits: across the trail from its node.
  Offset _landmark(int index, double width) {
    final swing = math.sin(index * 1.35);
    final side = swing.abs() < 0.2 ? (index.isEven ? 1 : -1) : -swing.sign;
    final away = swing.abs() < 0.2 ? 0.3 : 0.2;

    return Offset(width * (0.5 + side * away), _node(index, width).dy - 10);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = (_stops - 1) * _stageGap + 250 + 150;
          final current = currentStage(widget.trek);
          final stages = TrekStage.all.length;

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
                      painter: _GroundPainter(
                        art: widget.art,
                        stops: [
                          for (var i = 0; i < _stops; i++) _node(i, width).dy,
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _TrailPainter(
                        art: widget.art,
                        points: [
                          for (var i = 0; i < _stops; i++) _node(i, width),
                        ],
                        clearedUpTo: TrekStage.all
                            .where((s) => widget.trek.cleared(s.id))
                            .length,
                      ),
                    ),
                  ),
                  for (var i = 0; i < _stops; i++)
                    Positioned(
                      left: _landmark(i, width).dx - 72,
                      top: _landmark(i, width).dy - 72,
                      width: 144,
                      height: 144,
                      child: _Landmark(
                        asset: TrekStage.landmarkFor(
                          i < stages ? TrekStage.all[i].id : 'soon',
                        ),
                        faded: i < stages &&
                            !unlocked(widget.trek, TrekStage.all[i]),
                        onTap: i < stages
                            ? () => widget.onSelect(TrekStage.all[i])
                            : widget.onSoon,
                      ),
                    ),
                  for (final (i, stage) in TrekStage.all.indexed)
                    Positioned(
                      left: _node(i, width).dx - 60,
                      top: _node(i, width).dy - 44,
                      width: 120,
                      child: _StageNode(
                        art: widget.art,
                        stage: stage,
                        stars: widget.trek.stars[stage.id] ?? 0,
                        unlocked: unlocked(widget.trek, stage),
                        current:
                            stage == current && !widget.trek.cleared(stage.id),
                        selected:
                            !widget.soonSelected && stage == widget.selected,
                        onTap: () => widget.onSelect(stage),
                      ),
                    ),
                  Positioned(
                    left: _node(stages, width).dx - 60,
                    top: _node(stages, width).dy - 44,
                    width: 120,
                    child: _SoonNode(
                      art: widget.art,
                      selected: widget.soonSelected,
                      onTap: widget.onSoon,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

/// A landmark diorama on the map, bobbing gently, with a soft shadow.
class _Landmark extends StatelessWidget {
  const _Landmark({
    required this.asset,
    required this.faded,
    required this.onTap,
  });

  final String asset;
  final bool faded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              bottom: 10,
              child: Container(
                width: 104,
                height: 22,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(60),
                  boxShadow: [
                    BoxShadow(
                      color: context.colorScheme.shadow
                          .withValues(alpha: context.isDark ? 0.5 : 0.35),
                      blurRadius: 14,
                    ),
                  ],
                ),
              ),
            ),
            Opacity(
              opacity: faded ? 0.6 : 1,
              child: ColorFiltered(
                colorFilter: faded
                    ? const ColorFilter.matrix([
                        0.4, 0.4, 0.2, 0, 0, //
                        0.4, 0.4, 0.2, 0, 0, //
                        0.4, 0.4, 0.2, 0, 0, //
                        0, 0, 0, 1, 0,
                      ])
                    : const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.dst,
                      ),
                child: Image.asset(asset, width: 144, height: 144),
              ),
            ),
          ],
        ),
      );
}

/// The ground under the trail: a band of colour per stretch, blended into
/// each other, dotted with soft clumps of foliage, water and stone.
class _GroundPainter extends CustomPainter {
  _GroundPainter({required this.art, required this.stops});

  final _MapArt art;

  /// The y of each stop, from the first stage (bottom) to the last.
  final List<double> stops;

  @override
  void paint(Canvas canvas, Size size) {
    // Bottom to top in the scroll view is high y to low y.
    final colors = [for (var i = stops.length - 1; i >= 0; i--) art.zones[i]];
    final positions = [
      for (var i = stops.length - 1; i >= 0; i--) stops[i] / size.height,
    ];
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: positions,
        ).createShader(Offset.zero & size),
    );

    final random = math.Random(7);
    for (var i = 0; i < stops.length; i++) {
      final zone = art.zones[i];
      for (var k = 0; k < 14; k++) {
        final center = Offset(
          random.nextDouble() * size.width,
          stops[i] + (random.nextDouble() - 0.5) * _stageGap,
        );
        final radius = 18 + random.nextDouble() * 46;
        final light = random.nextBool();
        canvas.drawOval(
          Rect.fromCenter(
            center: center,
            width: radius * 2,
            height: radius * 1.3,
          ),
          Paint()
            ..color =
                light ? Color.lerp(zone, art.light, 0.1)! : _darken(zone, 0.16)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GroundPainter oldDelegate) =>
      !listEquals(oldDelegate.stops, stops) ||
      !listEquals(oldDelegate.art.zones, art.zones);
}

class _TrailPainter extends CustomPainter {
  _TrailPainter({
    required this.art,
    required this.points,
    required this.clearedUpTo,
  });

  final _MapArt art;
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
    final stagePoints = points.take(points.length - 1);
    final all = _path(stagePoints);
    // The stretch still to come: a dotted line into the mist.
    final toCome = _path(points.skip(points.length - 2));
    for (final metric in toCome.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 22) {
        final at = metric.getTangentForOffset(d)?.position;
        if (at == null) continue;
        canvas.drawCircle(
          at,
          6,
          Paint()..color = art.light.withValues(alpha: 0.5),
        );
      }
    }
    canvas
      ..drawPath(
        all,
        Paint()
          ..color = art.trailEdge
          ..style = PaintingStyle.stroke
          ..strokeWidth = 30
          ..strokeCap = StrokeCap.round,
      )
      ..drawPath(
        all,
        Paint()
          ..color = art.trail
          ..style = PaintingStyle.stroke
          ..strokeWidth = 20
          ..strokeCap = StrokeCap.round,
      );
    if (clearedUpTo > 0) {
      canvas.drawPath(
        _path(stagePoints.take(math.min(points.length - 1, clearedUpTo + 1))),
        Paint()
          ..color = art.cleared
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_TrailPainter oldDelegate) =>
      oldDelegate.clearedUpTo != clearedUpTo ||
      oldDelegate.points != points ||
      oldDelegate.art.trail != art.trail;
}

class _StageNode extends StatelessWidget {
  const _StageNode({
    required this.art,
    required this.stage,
    required this.stars,
    required this.unlocked,
    required this.current,
    required this.selected,
    required this.onTap,
  });

  final _MapArt art;
  final TrekStage stage;
  final int stars;
  final bool unlocked;
  final bool current;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cleared = stars > 0;
    final game = context.gameColors;
    final color = cleared
        ? game.jungle
        : unlocked
            ? game.orange
            : art.locked;

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
                      ? game.onGame
                      : current
                          ? game.banana.withValues(alpha: 0.6)
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
                border: Border.all(color: game.onGame, width: 3),
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
                        ? game.banana
                        : game.onGame.withValues(alpha: 0.3),
                  ),
              ],
            ),
          Text(
            stage.title(context.l10n),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.labelMedium?.copyWith(
              color: game.onGame,
              fontWeight: FontWeight.w800,
              shadows: [
                Shadow(
                  color: context.colorScheme.shadow.withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
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
    final scheme = context.colorScheme;
    final game = context.gameColors;
    final text = context.textTheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, (1 - t) * 40),
        child: Opacity(opacity: t.clamp(0, 1), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: context.cardShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                SheetBadge(stage.emoji, color: game.jungle),
                const SizedBox(width: PBSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.trekStageNumber(stage.number),
                        style: text.labelMedium?.copyWith(
                          color: game.jungle,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        stage.title(l),
                        style: text.headlineSmall?.copyWith(height: 1.1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: PBSpace.sm),
            Text(
              stage.blurb(l),
              style: text.bodyMedium?.copyWith(
                fontSize: 14,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: PBSpace.md),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final e in enemies) EnemyChip(spec: e)],
            ),
            const SizedBox(height: PBSpace.md),
            Row(
              children: [
                SizedBox(
                  width: 54,
                  child: CosmeticTile(
                    cosmetic: loot,
                    matColor: game.jungle,
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
                        style: text.labelMedium?.copyWith(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        loot.label(l),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.titleSmall?.copyWith(
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
                    color: cleared ? null : game.jungle,
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
                color: scheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The last stop on the map: the trail runs on into the mist.
class _SoonNode extends StatelessWidget {
  const _SoonNode({
    required this.art,
    required this.selected,
    required this.onTap,
  });

  final _MapArt art;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final game = context.gameColors;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 86,
            height: 86,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? game.onGame : Colors.transparent,
                width: 4,
              ),
            ),
            child: Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: art.soon,
                shape: BoxShape.circle,
                border: Border.all(
                  color: game.onGame.withValues(alpha: 0.8),
                  width: 3,
                ),
              ),
              child: Text(
                '?',
                style: context.textTheme.displaySmall?.copyWith(
                  color: game.onGame,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: game.banana,
              borderRadius: BorderRadius.circular(PBRadius.pill),
              boxShadow: context.glow(game.banana),
            ),
            child: Text(
              context.l10n.trekComingSoon,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: context.textTheme.labelMedium?.copyWith(
                // Dark ink: white doesn't read on banana yellow.
                color: game.onBanana,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// What the panel says about the stretch still to come.
class _ComingSoonPanel extends StatelessWidget {
  const _ComingSoonPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = context.textTheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, (1 - t) * 40),
        child: Opacity(opacity: t.clamp(0, 1), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: context.cardShadow,
        ),
        child: Row(
          children: [
            Image.asset(TrekStage.landmarkFor('soon'), width: 84, height: 84),
            const SizedBox(width: PBSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.trekComingSoon,
                    style: text.labelMedium?.copyWith(
                      color: context.gameColors.orange,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    l.trekComingSoonTitle,
                    style: text.headlineSmall?.copyWith(height: 1.1),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l.trekComingSoonInfo,
                    style: text.bodyMedium?.copyWith(
                      fontSize: 14,
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
