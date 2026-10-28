import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/pb_button.dart';
import 'package:pushup_bro/features/share/data/recap_video.dart';
import 'package:pushup_bro/features/share/model/recap.dart';
import 'package:pushup_bro/features/share/widgets/recap_frame.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

const _kFps = 24;
const _kPixelRatio = 2.0;

/// Shows a share video playing, and renders and shares it on Share. Off
/// iOS, or when encoding fails, it shares a picture of the flex wall.
class RecapSharePage extends StatefulWidget {
  const RecapSharePage({required this.recap, this.video, super.key});

  final Recap recap;
  final RecapVideo? video;

  static Future<void> open(BuildContext context, Recap recap) =>
      Navigator.of(context, rootNavigator: true).push<void>(
        CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (_) => RecapSharePage(recap: recap),
        ),
      );

  @override
  State<RecapSharePage> createState() => _RecapSharePageState();
}

class _RecapSharePageState extends State<RecapSharePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _preview = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (kRecapSeconds * 1000).round()),
  );
  late final RecapVideo _video = widget.video ?? const RecapVideo();
  final GlobalKey _frameKey = GlobalKey();

  /// The frame being rendered, or null while only previewing.
  double? _renderAt;
  double _progress = 0;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _preview.repeat();
  }

  @override
  void dispose() {
    _cancelled = true;
    _preview.dispose();
    super.dispose();
  }

  Future<void> _precache() async {
    for (final image in [
      Assets.images.proHeroPushup,
      Assets.images.proHeroWave,
      Assets.images.proHeroKomo,
      Assets.images.proHeroDance,
      Assets.images.appIcons.classic,
    ]) {
      await precacheImage(image.provider(), context);
    }
  }

  /// Shows the frame at [seconds] offscreen and captures it.
  Future<ui.Image> _capture(double seconds) async {
    setState(() => _renderAt = seconds);
    await WidgetsBinding.instance.endOfFrame;
    final boundary =
        _frameKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: _kPixelRatio);
    return image;
  }

  Future<void> _share() async {
    final l = context.l10n;
    final messenger = ScaffoldMessenger.maybeOf(context);
    _cancelled = false;
    _preview.stop();
    await _precache();
    final dir = await getTemporaryDirectory();
    try {
      if (!RecapVideo.canEncode) throw UnsupportedError('No encoder here.');
      final path = '${dir.path}/pushup_bro_recap.mp4';
      await _video.start(
        path: path,
        width: (kRecapSize.width * _kPixelRatio).round(),
        height: (kRecapSize.height * _kPixelRatio).round(),
        fps: _kFps,
      );
      final frames = (kRecapSeconds * _kFps).round();
      for (var i = 0; i < frames; i++) {
        if (_cancelled || !mounted) {
          await _video.cancel();
          return;
        }
        final image = await _capture(i / _kFps);
        final bytes = await image.toByteData();
        image.dispose();
        await _video.addFrame(bytes!.buffer.asUint8List());
        setState(() => _progress = (i + 1) / frames);
      }
      final cues = [
        for (final (time, name) in recapCues(widget.recap))
          (
            time,
            await RecapVideo.assetToFile('assets/audio/sfx/$name.m4a', dir),
          ),
      ];
      final file = await _video.finish(cues: cues);
      await _video.share(file: file, text: l.shareText);
    } on Object catch (error) {
      debugPrint('Recap video failed: $error');
      if (RecapVideo.canEncode) {
        messenger?.showSnackBar(SnackBar(content: Text(l.shareFailed)));
      }
      await _sharePicture(dir, l.shareText);
    } finally {
      if (mounted) {
        setState(() {
          _renderAt = null;
          _progress = 0;
        });
        _preview.repeat();
      }
    }
  }

  /// Shares the flex wall as a picture.
  Future<void> _sharePicture(Directory dir, String text) async {
    final image = await _capture(kOutroStart - 0.6);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final file = File('${dir.path}/pushup_bro_recap.png');
    await file.writeAsBytes(png!.buffer.asUint8List(), flush: true);
    await _video.share(file: file.path, text: text);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final rendering = _renderAt != null;

    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: context.colorScheme.surfaceContainerLowest,
        body: SafeArea(
          child: Stack(
            children: [
              // The frame being captured, full size and out of sight.
              if (rendering)
                Positioned(
                  left: -kRecapSize.width * 2,
                  top: 0,
                  child: RepaintBoundary(
                    key: _frameKey,
                    child: RecapFrame(
                      recap: widget.recap,
                      seconds: _renderAt!,
                    ),
                  ),
                ),
              Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: CupertinoButton(
                      onPressed: () {
                        _cancelled = true;
                        Navigator.of(context).pop();
                      },
                      child: Icon(
                        CarbonIcons.close,
                        semanticLabel:
                            MaterialLocalizations.of(context).closeButtonLabel,
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: PBSpace.xxl,
                      ),
                      child: Center(
                        child: AspectRatio(
                          aspectRatio: kRecapSize.aspectRatio,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(PBRadius.lg),
                            child: FittedBox(
                              child: AnimatedBuilder(
                                animation: _preview,
                                builder: (context, _) => RecapFrame(
                                  recap: widget.recap,
                                  seconds: _renderAt ??
                                      _preview.value * kRecapSeconds,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(PBSpace.xl),
                    child: rendering
                        ? Column(
                            children: [
                              LinearProgressIndicator(
                                value: _progress,
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                                color: context.colorScheme.secondary,
                              ),
                              const SizedBox(height: PBSpace.sm),
                              Text(
                                l.shareRendering,
                                style: context.textTheme.bodySmall,
                              ),
                            ],
                          )
                        : PBButton.icon(
                            l.shareButton,
                            icon: CarbonIcons.share,
                            callback: () => unawaited(_share()),
                            expanded: true,
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
