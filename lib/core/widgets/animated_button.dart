import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';

/// A start-style pill button: primary fill, a gently swaying label and a
/// springy squeeze on every tap. Looks like `PillButton`.
class AnimatedButton extends StatefulWidget {
  const AnimatedButton({
    required this.text,
    super.key,
    this.icon,
    this.callback,
    this.isPressed,
  });
  final String text;
  final IconData? icon;
  final VoidCallback? callback;

  /// Stops the label from swaying.
  final bool? isPressed;

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with TickerProviderStateMixin {
  late final AnimationController _pressController;
  late final AnimationController _arrowAnimController;
  late final Animation<Offset> _arrowAnimation;

  @override
  void initState() {
    super.initState();
    // 1 is at rest; a tap squeezes it and springs back.
    _pressController = AnimationController.unbounded(value: 1, vsync: this);
    _arrowAnimController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _arrowAnimation = Tween<Offset>(
      begin: const Offset(-4, 0),
      end: const Offset(4, 0),
    ).animate(
      CurvedAnimation(
        parent: _arrowAnimController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _arrowAnimController.dispose();
    _pressController.dispose();
    super.dispose();
  }

  void _onTap() {
    const springDesc = SpringDescription(mass: 0.1, stiffness: 40, damping: 5);
    _pressController
      ..value = 0.92
      ..animateWith(SpringSimulation(springDesc, 0.92, 1, 0));
    widget.callback?.call();
  }

  @override
  Widget build(BuildContext context) {
    final ink = context.colorScheme.onPrimary;

    return GestureDetector(
      onTap: _onTap,
      child: ScaleTransition(
        scale: _pressController,
        child: Container(
          width: 240,
          height: 60,
          decoration: BoxDecoration(
            color: context.colorScheme.primary,
            borderRadius: BorderRadius.circular(PBRadius.pill),
            boxShadow: context.glow(context.colorScheme.shadow),
          ),
          child: AnimatedBuilder(
            animation: _arrowAnimation,
            builder: (context, child) => Transform.translate(
              offset: (widget.isPressed ?? false)
                  ? Offset.zero
                  : _arrowAnimation.value,
              child: child,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: ink, size: 22),
                  const SizedBox(width: 10),
                ],
                Text(
                  widget.text,
                  style: context.textTheme.labelLarge?.copyWith(
                    color: ink,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
