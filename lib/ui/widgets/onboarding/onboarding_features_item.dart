import 'package:flutter/material.dart';
import 'package:pushup_bro/ui/styles/pb_text_styles.dart';

class OnboardingFeaturesItem extends StatelessWidget {
  const OnboardingFeaturesItem(this.text, this.icon, {super.key});
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Icon(
            icon,
            size: 28,
          ),
        ),
        LimitedBox(
          maxWidth: MediaQuery.of(context).size.width / 1.5,
          child: Text(
            text,
            style: PBTextStyles.headerTextStyle,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
