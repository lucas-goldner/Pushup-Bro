import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/widgets/animated_button.dart';

class StartPushupsButton extends StatefulWidget {
  const StartPushupsButton(this.onButtontrigger, {super.key});
  final VoidCallback onButtontrigger;

  @override
  State<StartPushupsButton> createState() => _StartPushupsButtonState();
}

class _StartPushupsButtonState extends State<StartPushupsButton> {
  bool buttonPressed = false;

  void switchButtonState(BuildContext context) {
    widget.onButtontrigger.call();
    setState(() => buttonPressed = !buttonPressed);
  }

  @override
  Widget build(BuildContext context) => AnimatedButton(
        text: buttonPressed ? context.l10n.finishSet : context.l10n.startPush,
        icon: CarbonIcons.arrow_right,
        callback: () => switchButtonState(context),
        isPressed: buttonPressed,
      );
}
