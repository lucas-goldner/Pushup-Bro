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
            size: 18,
            color: context.colorScheme.secondary,
          ),
          const SizedBox(
            width: 6,
          ),
          Text(
            text,
            style: context.textTheme.titleSmall,
          ),
        ],
      );
}
