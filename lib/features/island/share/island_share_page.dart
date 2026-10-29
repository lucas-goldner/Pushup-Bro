import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/friends/widgets/code_card.dart';
import 'package:pushup_bro/features/island/widgets/island_scene.dart';
import 'package:pushup_bro/features/share/data/recap_video.dart';
import 'package:pushup_bro/features/social/data/screen_brightness.dart';
import 'package:pushup_bro/features/social/domain/friend_code.dart';
import 'package:pushup_bro/features/social/model/bro_profile.dart';
import 'package:pushup_bro/features/social/widgets/bro_avatar.dart';
import 'package:pushup_bro/features/social/widgets/qr_view.dart';
import 'package:pushup_bro/features/social/widgets/social_widgets.dart';

/// The timeline, in seconds from the tap (see the design's island-to-QR
/// video).
const _kRise = (0.15, 1.95);
const _kMosaic = 2.0;
const _kPop = 0.5;
const _kSnap = (2.5, 3.5);
const _kQr = 3.5;
const _kSheet = 3.6;
const _kEnd = 5.2;

/// How much bigger the mosaic starts than the finished code.
const _kMosaicScale = 2.3;

/// Navy modules on white, like a printed code.
const _kNavy = Color(0xFF17203A);

Future<void> openIslandShare(BuildContext context) =>
    Navigator.of(context).pushNamed(IslandSharePage.routeName);

/// "Share my island": the camera rises over the island until it looks
/// straight down, the view breaks into tiles in the island's colours, the
/// tiles snap into the player's QR friend code, and the code sheet springs
/// up with Share my island and Scan a friend's code.
class IslandSharePage extends StatelessWidget {
  const IslandSharePage({super.key});
  static const routeName = '/island/share';

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.white,
        body: SocialGate(builder: (context, me) => _Share(me: me)),
      );
}

class _Share extends StatefulWidget {
  const _Share({required this.me});

  final BroProfile me;

  @override
  State<_Share> createState() => _ShareState();
}

class _ShareState extends State<_Share> with SingleTickerProviderStateMixin {
  late final AnimationController _clock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _kEnd * 1000 ~/ 1),
  );
  final ValueNotifier<double> _rise = ValueNotifier(0);
  final GlobalKey _scene = GlobalKey();
  final GlobalKey _card = GlobalKey();
  late final QrGrid _grid = QrGrid(FriendCode.link(widget.me.code), hole: 9);
  List<Color>? _tiles;
  double? _brightness;
  bool _captured = false;
  final Set<String> _played = {};

  double get _seconds => _clock.value * _kEnd;

  @override
  void initState() {
    super.initState();
    _clock.addListener(_onTick);
    unawaited(
      ScreenBrightness.raise().then((level) => _brightness = level),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_clock.isAnimating || _clock.value > 0) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      // Straight to the card, with a cross-fade.
      _captured = true;
      _clock.value = 1;
    } else {
      GameAudio.instance.play(Sfx.whoosh);
      _clock.forward();
    }
  }

  @override
  void dispose() {
    unawaited(ScreenBrightness.restore(_brightness));
    _clock.dispose();
    _rise.dispose();
    super.dispose();
  }

  void _cue(String name, double at, Sfx sfx) {
    if (_seconds >= at && _played.add(name)) GameAudio.instance.play(sfx);
  }

  void _onTick() {
    final s = _seconds;
    _rise.value = _smooth((s - _kRise.$1) / (_kRise.$2 - _kRise.$1));
    if (s >= _kMosaic && !_captured) {
      _captured = true;
      unawaited(_capture());
    }
    _cue('mosaic', _kMosaic, Sfx.blip);
    _cue('snap', _kSnap.$1, Sfx.next);
    _cue('qr', _kQr, Sfx.levelUp);
    _cue('sheet', _kSheet, Sfx.pop);
    _cue('star', _kSheet + 0.6, Sfx.star);
  }

  /// The top-down island, sampled under each tile of the mosaic.
  Future<void> _capture() async {
    final boundary =
        _scene.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    final size = context.size;
    if (boundary == null || size == null) return;
    try {
      final image = await boundary.toImage();
      final data = await image.toByteData();
      if (data == null || !mounted) return;
      final start = _mosaicRect(size, 0);
      final cell = start.width / _grid.count;
      Color pixel(Offset at) {
        final x = (at.dx * image.width / size.width)
            .round()
            .clamp(0, image.width - 1);
        final y = (at.dy * image.height / size.height)
            .round()
            .clamp(0, image.height - 1);
        final i = (y * image.width + x) * 4;
        return Color.fromARGB(
          255,
          data.getUint8(i),
          data.getUint8(i + 1),
          data.getUint8(i + 2),
        );
      }

      setState(() {
        _tiles = [
          for (var row = 0; row < _grid.count; row++)
            for (var col = 0; col < _grid.count; col++)
              pixel(
                start.topLeft + Offset((col + 0.5) * cell, (row + 0.5) * cell),
              ),
        ];
      });
      image.dispose();
    } on Object {
      // Without a picture the tiles start in the sky's colour.
    }
  }

  /// Where the code ends up.
  Rect _qrRect(Size size) {
    final top = MediaQuery.paddingOf(context).top + 64;
    final side = math.min(size.width - 48, size.height * 0.4);
    return Rect.fromLTWH((size.width - side) / 2, top, side, side);
  }

  /// The mosaic at [snap] (0 big over the island, 1 on the code).
  Rect _mosaicRect(Size size, double snap) {
    final end = _qrRect(size);
    final center = size.center(Offset.zero);
    final start = Rect.fromCenter(
      center: center,
      width: end.width * _kMosaicScale,
      height: end.height * _kMosaicScale,
    );
    return Rect.lerp(start, end, snap)!;
  }

  Future<void> _shareImage() async {
    final l = context.l10n;
    final link = FriendCode.link(widget.me.code);
    final boundary =
        _card.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null || !RecapVideo.canEncode) return;
    final image = await boundary.toImage(pixelRatio: 3);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (png == null) return;
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/pushup_bro_${widget.me.code}.png');
    await file.writeAsBytes(png.buffer.asUint8List(), flush: true);
    await const RecapVideo().share(
      file: file.path,
      text: l.shareMessage(link),
    );
  }

  static double _smooth(double t) {
    final x = t.clamp(0.0, 1.0);
    return x * x * (3 - 2 * x);
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) => AnimatedBuilder(
          animation: _clock,
          builder: (context, _) => _build(context, constraints.biggest),
        ),
      );

  Widget _build(BuildContext context, Size size) {
    final s = _seconds;
    final snap = _smooth((s - _kSnap.$1) / (_kSnap.$2 - _kSnap.$1));
    final qr = _smooth((s - _kQr) / 0.25);
    final sheet = Curves.easeOutBack.transform(
      ((s - _kSheet) / 0.6).clamp(0.0, 1.0),
    );
    final sky = islandSky(context);
    final qrRect = _qrRect(size);

    return Stack(
      children: [
        // The island, until the white wash covers it.
        if (snap < 1)
          Positioned.fill(
            child: RepaintBoundary(
              key: _scene,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [sky.top, sky.horizon],
                    stops: const [0, 0.55],
                  ),
                ),
                child: IgnorePointer(child: IslandScene(rise: _rise)),
              ),
            ),
          ),
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(color: Colors.white.withValues(alpha: snap)),
          ),
        ),
        if (s >= _kMosaic && qr < 1)
          Positioned.fill(
            child: Opacity(
              opacity: 1 - qr,
              child: CustomPaint(
                painter: _MosaicPainter(
                  grid: _grid,
                  tiles: _tiles,
                  fallback: sky.top,
                  rect: _mosaicRect(size, snap),
                  pop: ((s - _kMosaic) / _kPop).clamp(0.0, 1.0),
                  snap: snap,
                ),
              ),
            ),
          ),
        if (qr > 0)
          Positioned.fromRect(
            rect: qrRect,
            child: Opacity(
              opacity: qr,
              child: _FinalCode(
                me: widget.me,
                grid: _grid,
                finders: ((s - _kQr) / 0.45).clamp(0.0, 1.0),
                logo: Curves.elasticOut.transform(
                  ((s - _kQr - 0.2) / 0.7).clamp(0.0, 1.0),
                ),
              ),
            ),
          ),
        // The top bar: close, "My island" and share.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Opacity(
              opacity: qr,
              child: Padding(
                padding: const EdgeInsets.all(PBSpace.md),
                child: Row(
                  children: [
                    _RoundButton(
                      icon: CarbonIcons.close,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Text(
                        context.l10n.shareTitle,
                        textAlign: TextAlign.center,
                        style: context.textTheme.titleMedium?.copyWith(
                          color: _kNavy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    _RoundButton(
                      icon: CarbonIcons.share,
                      onTap: () => unawaited(_shareImage()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (sheet > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: FractionalTranslation(
              translation: Offset(0, 1 - sheet),
              child: _CodeSheet(
                me: widget.me,
                seconds: s - _kSheet,
                cardKey: _card,
                grid: _grid,
                onShare: () => unawaited(_shareImage()),
              ),
            ),
          ),
      ],
    );
  }
}

/// The island broken into tiles: they pop in from the middle out in the
/// island's colours, then snap to navy or white and shrink onto the code.
class _MosaicPainter extends CustomPainter {
  _MosaicPainter({
    required this.grid,
    required this.tiles,
    required this.fallback,
    required this.rect,
    required this.pop,
    required this.snap,
  });

  final QrGrid grid;
  final List<Color>? tiles;
  final Color fallback;
  final Rect rect;
  final double pop;
  final double snap;

  @override
  void paint(Canvas canvas, Size size) {
    final n = grid.count;
    final cell = rect.width / n;
    final middle = (n - 1) / 2;
    final farthest = math.sqrt(2) * middle;
    final paint = Paint();
    for (var row = 0; row < n; row++) {
      for (var col = 0; col < n; col++) {
        final distance =
            math.sqrt(math.pow(row - middle, 2) + math.pow(col - middle, 2));
        // From the middle out.
        final start = distance / farthest * 0.6;
        final t = ((pop - start) / 0.4).clamp(0.0, 1.0);
        if (t <= 0) continue;
        final scale = Curves.easeOutBack.transform(t);
        final dark = grid.isDark(row, col) && !grid.inHole(row, col);
        final from = tiles?[row * n + col] ?? fallback;
        paint.color = Color.lerp(from, dark ? _kNavy : Colors.white, snap)!;
        final center =
            rect.topLeft + Offset((col + 0.5) * cell, (row + 0.5) * cell);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: center,
              width: cell * 0.92 * scale,
              height: cell * 0.92 * scale,
            ),
            Radius.circular(cell * (0.15 + 0.2 * snap)),
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_MosaicPainter old) => true;
}

/// The finished code: rounded modules, blue finder centres popping in and
/// Carlos in the middle.
class _FinalCode extends StatelessWidget {
  const _FinalCode({
    required this.me,
    required this.grid,
    required this.finders,
    required this.logo,
  });

  final BroProfile me;
  final QrGrid grid;
  final double finders;
  final double logo;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.biggest.shortestSide;
          final cell = side / grid.count;
          return Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: QrPainter(
                    grid,
                    dark: _kNavy,
                    accent: context.colorScheme.secondary,
                    finders: finders,
                  ),
                ),
              ),
              Transform.scale(
                scale: logo,
                child: Container(
                  width: cell * (grid.hole - 1),
                  height: cell * (grid.hole - 1),
                  decoration: BoxDecoration(
                    color: context.gameColors.orange,
                    borderRadius: BorderRadius.circular(cell * 2),
                  ),
                  alignment: Alignment.center,
                  child:
                      BroAvatar(look: me.look, size: cell * (grid.hole - 2.5)),
                ),
              ),
            ],
          );
        },
      );
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: context.cardShadow,
          ),
          child: Icon(icon, size: 20, color: _kNavy),
        ),
      );
}

/// The sheet under the code: the code's letters bounce in one by one, then
/// the island level, the text and the buttons.
class _CodeSheet extends StatelessWidget {
  const _CodeSheet({
    required this.me,
    required this.seconds,
    required this.cardKey,
    required this.grid,
    required this.onShare,
  });

  final BroProfile me;

  /// Seconds since the sheet started coming up.
  final double seconds;
  final GlobalKey cardKey;
  final QrGrid grid;
  final VoidCallback onShare;

  double _at(double start) =>
      Curves.easeOutBack.transform(((seconds - start) / 0.35).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final code = FriendCode.format(me.code);
    final game = context.gameColors;

    return Container(
      padding: EdgeInsets.fromLTRB(
        PBSpace.xl,
        PBSpace.md,
        PBSpace.xl,
        MediaQuery.paddingOf(context).bottom + PBSpace.lg,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(PBRadius.sheet),
        ),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD9DCE4),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: PBSpace.lg),
          RepaintBoundary(
            key: cardKey,
            child: ColoredBox(
              color: Colors.white,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            for (final (i, letter) in code.split('').indexed)
                              Transform.translate(
                                offset:
                                    Offset(0, (1 - _at(0.1 + i * 0.06)) * 18),
                                child: Opacity(
                                  opacity: _at(0.1 + i * 0.06).clamp(0, 1),
                                  child: Text(
                                    letter,
                                    style: context.textTheme.displaySmall
                                        ?.copyWith(
                                      color: _kNavy,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          l.shareCodeLabel,
                          style: context.textTheme.labelMedium?.copyWith(
                            color: const Color(0xFF5D6680),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.scale(
                    scale: _at(0.6),
                    child: SocialChip(
                      l.shareLevel(me.islandLevel),
                      color: game.jungle.withValues(alpha: 0.14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: PBSpace.lg),
          Opacity(
            opacity: _at(0.75).clamp(0, 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.shareHeadline,
                  style: context.textTheme.titleLarge?.copyWith(
                    color: _kNavy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: PBSpace.xs),
                Text(
                  l.islandShareText(me.friendCount, me.streak),
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF5D6680),
                  ),
                ),
                const SizedBox(height: PBSpace.xs),
                Text(
                  '☀️ ${l.shareBrightness}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF5D6680),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: PBSpace.lg),
          Transform.scale(
            scale: _at(0.9),
            child: SizedBox(
              width: double.infinity,
              child: PillButton(
                label: l.islandShareButton,
                color: _kNavy,
                onPressed: onShare,
              ),
            ),
          ),
          const SizedBox(height: PBSpace.sm),
          Center(
            child: Opacity(
              opacity: _at(1).clamp(0, 1),
              child: TextButton(
                onPressed: () => unawaited(scanFriendCode(context)),
                child: Text(l.shareScan),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
