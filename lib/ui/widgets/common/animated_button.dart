import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:pushup_bro/generated/assets.gen.dart';
import 'package:pushup_bro/ui/styles/pb_text_styles.dart';
import 'package:rive/rive.dart';

class AnimatedButton extends StatefulWidget {
  const AnimatedButton({
    required this.text, super.key,
    this.icon,
    this.callback,
  });
  final String text;
  final IconData? icon;
  final VoidCallback? callback;

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  TriggerInput? _activeTrigger;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  RiveWidgetController _createController(File file) {
    final controller = RiveWidgetController(file);
    // Rive 0.14 marks state machine inputs deprecated in favor of data
    // binding; migrating the artboards to view models is out of scope here.
    // ignore: deprecated_member_use
    _activeTrigger = controller.stateMachine.trigger('active');

    return controller;
  }

  void _onTap() {
    _activeTrigger?.fire();
    const springDesc = SpringDescription(mass: 0.1, stiffness: 40, damping: 5);
    final springAnim = SpringSimulation(springDesc, 0, 1, 0);
    _controller?.animateWith(springAnim);
    widget.callback?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: _onTap,
        child: Stack(
          children: [
            RiveWidgetBuilder(
              fileLoader: Assets.rive.button.riveFileLoader(),
              controller: _createController,
              builder: (context, state) => switch (state) {
                RiveLoading() => const SizedBox.shrink(),
                RiveFailed() => const SizedBox.shrink(),
                RiveLoaded(:final controller) =>
                  RiveWidget(controller: controller, fit: Fit.cover),
              },
            ),
            Center(
              child: Transform.translate(
                offset: const Offset(4, 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Visibility(
                      visible: widget.icon != null,
                      child: Icon(widget.icon),
                    ),
                    const SizedBox(width: 8),
                    Text(widget.text, style: PBTextStyles.buttonTextStyle),
                    const SizedBox(width: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
