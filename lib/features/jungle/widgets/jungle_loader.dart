import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

const _kHopDuration = Duration(milliseconds: 900);
const _kHopHeight = 26.0;
const _kCarlosHeight = 150.0;
const _kBananaSize = 22.0;

/// Shown on white while the jungle loads: Carlos hops on the spot, waving,
/// while three bananas bounce one after another below him.
class JungleLoader extends StatefulWidget {
  const JungleLoader({super.key});

  @override
  State<JungleLoader> createState() => _JungleLoaderState();
}

class _JungleLoaderState extends State<JungleLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hop =
      AnimationController(vsync: this, duration: _kHopDuration);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _hop.stop();
    } else if (!_hop.isAnimating) {
      _hop.repeat();
    }
  }

  @override
  void dispose() {
    _hop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final game = context.gameColors;

    // Scaled down rather than overflowing when the screen is laid out
    // short for a moment.
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: AnimatedBuilder(
          animation: _hop,
          builder: (context, _) {
            final t = _hop.value;
            // Up and down once per loop; squashed a little on landing.
            final up = math.sin(t * math.pi);
            final squash = math.max(0, 1 - up * 4) * 0.08;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: _kCarlosHeight + _kHopHeight,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // His shadow shrinks as he goes up.
                      Container(
                        width: 90 * (1 - up * 0.35),
                        height: 12,
                        decoration: BoxDecoration(
                          color: game.jungleDeep.withValues(
                            alpha: 0.18 * (1 - up * 0.5),
                          ),
                          borderRadius: const BorderRadius.all(
                            Radius.elliptical(45, 6),
                          ),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(0, -6 - up * _kHopHeight),
                        child: Transform.rotate(
                          angle: math.sin(t * math.pi * 2) * 0.06,
                          child: Transform(
                            alignment: Alignment.bottomCenter,
                            transform: Matrix4.diagonal3Values(
                              1 + squash,
                              1 - squash,
                              1,
                            ),
                            child: Assets.images.proHeroWave
                                .image(height: _kCarlosHeight),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Transform.translate(
                          offset: Offset(0, -_bounce(t, i) * 10),
                          child: Transform.rotate(
                            angle: -0.4 + _bounce(t, i) * 0.6,
                            child: Assets.images.island.banana
                                .image(width: _kBananaSize),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  context.l10n.jungleLoading,
                  style: context.textTheme.titleMedium?.copyWith(
                    color: game.jungleDeep,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Banana [i] hops in the third of the loop that is its turn.
  static double _bounce(double t, int i) {
    final local = (t * 3 - i) % 3;
    return local < 1 ? math.sin(local * math.pi) : 0;
  }
}
