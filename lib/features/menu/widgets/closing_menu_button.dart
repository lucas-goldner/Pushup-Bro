import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';

class ClosingMenuButton extends StatelessWidget {
  const ClosingMenuButton(this.toggle, {required this.open, super.key});
  final VoidCallback toggle;
  final bool open;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 56,
        height: 56,
        child: Center(
          child: Material(
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            elevation: 4,
            child: InkWell(
              splashFactory: NoSplash.splashFactory,
              onTap: toggle,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  CarbonIcons.close_outline,
                  color: context.colorScheme.inversePrimary,
                ),
              ),
            ),
          ),
        ),
      );
}
