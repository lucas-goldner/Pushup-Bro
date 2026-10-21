import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

class BeachOverlay extends StatefulWidget {
  const BeachOverlay({super.key});

  @override
  State<BeachOverlay> createState() => _BeachOverlayState();
}

class _BeachOverlayState extends State<BeachOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;
  late Animation<double> _animation1;
  late Animation<double> _animation2;
  late Animation<double> _animation3;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    _controller2 = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);
    _controller3 = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);
    _animation1 = Tween<double>(begin: -1.05, end: 0).animate(
      CurvedAnimation(
        parent: _controller1,
        curve: Curves.easeInOut,
      ),
    );
    _animation2 = Tween<double>(begin: -1, end: 0).animate(
      CurvedAnimation(
        parent: _controller2,
        curve: Curves.easeInOut,
      ),
    );
    _animation3 = Tween<double>(begin: -0.95, end: 0).animate(
      CurvedAnimation(
        parent: _controller3,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            bottom: 120,
            left: MediaQuery.of(context).size.width / 4,
            child: Assets.images.island.stone1.image(
              width: 100,
            ),
          ),
          Positioned(
            bottom: 180,
            right: 50,
            child: Assets.images.island.stone2.image(
              width: 80,
            ),
          ),
          Positioned(
            bottom: 320,
            left: 0,
            child: Assets.images.island.stone3.image(
              width: 80,
            ),
          ),
          _buildAnimatedWave(
            waveImage: Assets.images.island.wave3.image(
              width: context.sizeOf.width,
            ),
            animation: _animation1,
            bottomOffset: -50,
          ),
          _buildAnimatedWave(
            waveImage: Assets.images.island.wave4.image(
              width: context.sizeOf.width,
            ),
            animation: _animation2,
            bottomOffset: -25,
          ),
          _buildAnimatedWave(
            waveImage: Assets.images.island.wave5.image(
              width: context.sizeOf.width,
            ),
            animation: _animation3,
            bottomOffset: 0,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedWave({
    required Widget waveImage,
    required Animation<double> animation,
    required double bottomOffset,
  }) =>
      AnimatedBuilder(
        animation: animation,
        builder: (context, child) => Positioned(
          bottom: bottomOffset,
          left: (animation.value) * context.sizeOf.width,
          child: Row(
            children: [
              child ?? const SizedBox.shrink(),
              child ?? const SizedBox.shrink(),
              child ?? const SizedBox.shrink(),
            ],
          ),
        ),
        child: waveImage,
      );
}
