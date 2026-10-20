import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_text_styles.dart';

class Settingsitem extends StatelessWidget {
  const Settingsitem(this.name, this.icon, this.navigate, {super.key});
  final String name;
  final IconData icon;
  final VoidCallback navigate;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: navigate,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colorScheme.onSecondary,
              borderRadius: const BorderRadius.all(
                Radius.circular(8),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                  ),
                  Icon(icon),
                  const SizedBox(
                    width: 12,
                  ),
                  Text(
                    name,
                    style: buttonTextStyle.copyWith(
                      color: context.colorScheme.surfaceBright,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    CarbonIcons.arrow_right,
                    color: context.colorScheme.surfaceBright,
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
