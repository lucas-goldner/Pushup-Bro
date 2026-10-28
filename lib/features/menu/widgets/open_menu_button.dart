import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/features/menu/widgets/menu_circle_button.dart';

class OpenMenuButton extends StatelessWidget {
  const OpenMenuButton(this.toggle, {required this.open, super.key});
  final VoidCallback toggle;
  final bool open;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        ignoring: open,
        child: AnimatedContainer(
          transformAlignment: Alignment.center,
          transform: Matrix4.diagonal3Values(
            open ? 0.7 : 1.0,
            open ? 0.7 : 1.0,
            1,
          ),
          duration: const Duration(milliseconds: 250),
          curve: const Interval(0, 0.5, curve: Curves.easeOut),
          child: AnimatedOpacity(
            opacity: open ? 0.0 : 1.0,
            curve: const Interval(0.25, 1, curve: Curves.easeInOut),
            duration: const Duration(milliseconds: 250),
            child: MenuCircleButton(icon: CarbonIcons.menu, onTap: toggle),
          ),
        ),
      );
}
