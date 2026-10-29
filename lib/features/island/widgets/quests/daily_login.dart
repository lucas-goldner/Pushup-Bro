import 'dart:async';
import 'dart:math' as math;

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/island/model/daily_bananas.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

const _kRevealDuration = Duration(milliseconds: 2200);
const _kCollectDuration = Duration(milliseconds: 650);

/// When the big banana pops in, and when the small ones start bursting out
/// of it, one every [_kBurstEvery] of the reveal.
const _kBigBananaEnd = 0.25;
const _kBurstStart = 0.2;
const _kBurstEvery = 0.055;
const _kBurstLength = 0.22;

/// Today's ten free bananas: they burst out of a big banana one by one
/// while the count rolls up to +10, then fly off when claimed.
class DailyLogin extends StatefulWidget {
  const DailyLogin({
    required this.onClose,
    super.key,
  });
  final VoidCallback onClose;

  @override
  State<DailyLogin> createState() => _DailyLoginState();
}

class _DailyLoginState extends State<DailyLogin> with TickerProviderStateMixin {
  late final AnimationController _reveal =
      AnimationController(vsync: this, duration: _kRevealDuration);
  late final AnimationController _collect =
      AnimationController(vsync: this, duration: _kCollectDuration);
  bool _started = false;
  bool _claiming = false;
  int _landed = 0;

  @override
  void initState() {
    super.initState();
    _reveal.addListener(_onReveal);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _reveal.value = 1;
    } else {
      _reveal.forward();
    }
  }

  /// A tick and a haptic for each banana that lands.
  void _onReveal() {
    final landed = List.generate(DailyBananas.amount, _landAt)
        .where((at) => _reveal.value >= at)
        .length;
    if (landed == _landed) return;
    _landed = landed;
    unawaited(HapticFeedback.selectionClick());
    GameAudio.instance.play(
      landed == DailyBananas.amount ? Sfx.banana : Sfx.tick,
      gain: 0.6,
    );
  }

  static double _startAt(int i) => _kBurstStart + i * _kBurstEvery;
  static double _landAt(int i) => _startAt(i) + _kBurstLength;

  Future<void> _claim() async {
    if (_claiming) return;
    setState(() => _claiming = true);
    final gameInvCubit = context.read<GameInventoryCubit>();
    _reveal.value = 1;
    GameAudio.instance.play(Sfx.whoosh);
    final flight = MediaQuery.disableAnimationsOf(context)
        ? Future<void>.value()
        : _collect.forward().orCancel.catchError((_) {});
    // Once a day: a second tap or another visit today gives nothing.
    if (await DailyBananas().claim()) {
      await gameInvCubit.fetchInventory();
      final inv = gameInvCubit.state.inventory;
      await gameInvCubit.updateInventory(
        inv.copyWith(bananas: inv.bananas + DailyBananas.amount),
      );
      GameAudio.instance.play(Sfx.banana);
    }
    await flight;
    widget.onClose();
  }

  @override
  void dispose() {
    _reveal.dispose();
    _collect.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.dailyInfo,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(
            height: 200,
            child: AnimatedBuilder(
              animation: Listenable.merge([_reveal, _collect]),
              builder: (context, _) => _Burst(
                reveal: _reveal.value,
                collect: Curves.easeInCubic.transform(_collect.value),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _reveal,
            builder: (context, _) => Text(
              '+$_landed',
              textAlign: TextAlign.center,
              style: context.textTheme.displayMedium?.copyWith(
                color: context.gameColors.orange,
              ),
            ),
          ),
          Text(
            context.l10n.dailyToday,
            textAlign: TextAlign.center,
            style: context.textTheme.labelLarge?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: AnimatedBuilder(
              animation: _reveal,
              builder: (context, child) => AnimatedScale(
                scale: _reveal.value >= 1 ? 1 : 0.92,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                child: child,
              ),
              child: PillButton(
                label: context.l10n.dailyClaim,
                icon: CarbonIcons.gift,
                color: context.gameColors.orange,
                // _claim ignores taps while the bananas fly off.
                onPressed: () => unawaited(_claim()),
              ),
            ),
          ),
        ],
      );
}

/// The big banana in a soft glow with the ten small ones around it.
class _Burst extends StatelessWidget {
  const _Burst({required this.reveal, required this.collect});

  /// 0 to 1 through the reveal.
  final double reveal;

  /// 0 to 1 while the bananas fly off after claiming.
  final double collect;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final center = Offset(constraints.maxWidth / 2, 100);
          final big = Curves.easeOutBack
              .transform((reveal / _kBigBananaEnd).clamp(0.0, 1.0));
          // A gentle breathing once everything has landed.
          final breathe = reveal >= 1 ? 0.0 : math.sin(reveal * math.pi * 6);
          final glow = context.gameColors.banana;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: center.dx - 90,
                top: center.dy - 90,
                child: Opacity(
                  opacity: (big * (1 - collect)).clamp(0.0, 1.0),
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          glow.withValues(alpha: 0.55),
                          glow.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              for (var i = 0; i < DailyBananas.amount; i++)
                _small(i, center, constraints.maxWidth),
              Positioned(
                left: center.dx - 50,
                top: center.dy - 50,
                child: Opacity(
                  opacity: (1 - collect).clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, -collect * 120),
                    child: Transform.scale(
                      scale: big * (1 + breathe * 0.03),
                      child: Assets.images.island.banana.image(width: 100),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );

  /// Banana [i]: shoots out of the middle to its spot on a ring, then
  /// flies up and away when claimed.
  Widget _small(int i, Offset center, double width) {
    final start = _kBurstStart + i * _kBurstEvery;
    final t = ((reveal - start) / _kBurstLength).clamp(0.0, 1.0);
    if (t == 0) return const SizedBox.shrink();
    final out = Curves.easeOutBack.transform(t);
    final angle = -math.pi / 2 + (i - (DailyBananas.amount - 1) / 2) * 0.5;
    final radius = math.min(width / 2 - 26, 118) * (i.isEven ? 1 : 0.78);
    final spot = center +
        Offset(math.cos(angle) * radius, math.sin(angle) * radius * 0.62 + 18);
    final position = Offset.lerp(center, spot, out)! +
        Offset(
          (spot.dx - center.dx) * 0.2 * collect,
          -collect * (160 + i * 8),
        );

    return Positioned(
      left: position.dx - 18,
      top: position.dy - 18,
      child: Opacity(
        opacity: (math.min(1, t * 3) * (1 - collect)).clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: (1 - out) * 2.4 + angle * 0.3 + collect * 1.5,
          child: Assets.images.island.banana.image(width: 36),
        ),
      ),
    );
  }
}
