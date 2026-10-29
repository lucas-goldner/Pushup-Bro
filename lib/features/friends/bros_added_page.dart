import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/island/visit/island_visit_page.dart';
import 'package:pushup_bro/features/social/model/bro_profile.dart';
import 'package:pushup_bro/features/social/widgets/bro_avatar.dart';
import 'package:pushup_bro/features/social/widgets/social_widgets.dart';

const _kIntro = Duration(milliseconds: 1400);

/// "You and Mia are bros now": both avatars tilt in and shake hands, with
/// confetti, then a visit to their island or Done.
class BrosAddedPage extends StatefulWidget {
  const BrosAddedPage({required this.friend, required this.name, super.key});
  static const routeName = '/bros/added';

  final BroProfile friend;
  final String name;

  @override
  State<BrosAddedPage> createState() => _BrosAddedPageState();
}

class _BrosAddedPageState extends State<BrosAddedPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: _kIntro);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _intro.value = 1;
    } else if (!_intro.isAnimating && _intro.value == 0) {
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  double _at(double start, double length, [Curve curve = Curves.easeOutBack]) =>
      curve.transform(((_intro.value - start) / length).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final name = friendLabel(context, widget.friend, widget.name);
    final game = context.gameColors;

    return Scaffold(
      backgroundColor: Color.lerp(
        context.colorScheme.surfaceContainerLow,
        game.banana,
        0.18,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _intro,
          builder: (context, _) => Stack(
            children: [
              Positioned.fill(child: _Confetti(progress: _intro.value)),
              Padding(
                padding: const EdgeInsets.all(PBSpace.lg),
                child: Column(
                  children: [
                    const Spacer(),
                    SizedBox(
                      height: 150,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _avatar(myLook(context), -1, _at(0, 0.4)),
                          _avatar(widget.friend.look, 1, _at(0.1, 0.4)),
                          Transform.scale(
                            scale: _at(0.4, 0.3),
                            child: const Text(
                              '🤝',
                              style: TextStyle(fontSize: 34),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: PBSpace.xl),
                    Opacity(
                      opacity: _at(0.45, 0.3, Curves.easeOut),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${l.addedTitle(name)} '),
                            TextSpan(
                              text: l.addedTitleBros,
                              style: TextStyle(
                                color: context.colorScheme.secondary,
                              ),
                            ),
                            TextSpan(text: ' ${l.addedTitleNow}'),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: context.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: PBSpace.md),
                    Opacity(
                      opacity: _at(0.55, 0.3, Curves.easeOut),
                      child: Text(
                        l.addedText,
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: PBSpace.lg),
                    Transform.scale(
                      scale: _at(0.65, 0.3),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        spacing: PBSpace.sm,
                        runSpacing: PBSpace.sm,
                        children: [
                          SocialChip(
                            l.addedLevel(widget.friend.islandLevel),
                            emoji: '🏝️',
                          ),
                          SocialChip(
                            l.addedDays(widget.friend.streak),
                            emoji: '🔥',
                          ),
                        ],
                      ),
                    ),
                    const Spacer(flex: 2),
                    SizedBox(
                      width: double.infinity,
                      child: PillButton(
                        label: l.addedVisit(name),
                        onPressed: () => openIslandVisit(
                          context,
                          uid: widget.friend.uid,
                          replace: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: PBSpace.md),
                    SizedBox(
                      width: double.infinity,
                      child: PillButton(
                        label: l.addedDone,
                        color: context.colorScheme.secondary,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// An avatar sliding in from [side], tilting towards the middle.
  Widget _avatar(MonkeyLook look, int side, double t) => Transform.translate(
        offset: Offset(side * (58 + (1 - t) * 160), 0),
        child: Transform.rotate(
          angle: side * -0.12 * t,
          child: Opacity(
            opacity: t.clamp(0, 1),
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: context.cardShadow,
              ),
              child: BroAvatar(look: look, size: 112),
            ),
          ),
        ),
      );
}

/// Confetti falling once, from the top.
class _Confetti extends StatelessWidget {
  const _Confetti({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: CustomPaint(
          painter: _ConfettiPainter(progress, [
            context.colorScheme.secondary,
            context.gameColors.banana,
            context.gameColors.pink,
            context.gameColors.jungle,
            context.gameColors.orange,
          ]),
        ),
      );
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.progress, this.colors);

  final double progress;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final t = ((progress - 0.35) / 0.65).clamp(0.0, 1.0);
    if (t <= 0 || t >= 1) return;
    final random = math.Random(4);
    for (var i = 0; i < 60; i++) {
      final x = random.nextDouble() * size.width;
      final speed = 0.6 + random.nextDouble() * 0.6;
      final y = -20 + t * speed * size.height * 0.9;
      final spin = random.nextDouble() * 6 + t * 10;
      canvas
        ..save()
        ..translate(x + math.sin(t * 8 + i) * 18, y)
        ..rotate(spin)
        ..drawRect(
          const Rect.fromLTWH(-4, -2, 8, 4),
          Paint()
            ..color = colors[i % colors.length].withValues(alpha: 1 - t * t),
        )
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.progress != progress;
}
