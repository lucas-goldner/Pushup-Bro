import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/features/menu/widgets/menu_circle_button.dart';

class ClosingMenuButton extends StatelessWidget {
  const ClosingMenuButton(this.toggle, {required this.open, super.key});
  final VoidCallback toggle;
  final bool open;

  @override
  Widget build(BuildContext context) =>
      MenuCircleButton(icon: CarbonIcons.close, onTap: toggle);
}
