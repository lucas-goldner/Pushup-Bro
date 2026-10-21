import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';

class CalendarStatItem extends StatelessWidget {
  const CalendarStatItem(this.text, this.icon, {super.key});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(
            icon,
            color: context.colorScheme.inversePrimary,
          ),
          const SizedBox(
            width: 8,
          ),
          Text(
            text,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.surfaceBright,
            ),
          ),
        ],
      );
}
