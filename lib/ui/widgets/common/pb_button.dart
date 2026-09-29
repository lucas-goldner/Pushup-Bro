import 'package:flutter/material.dart';
import 'package:pushup_bro/ui/styles/pb_colors.dart';
import 'package:pushup_bro/ui/styles/pb_text_styles.dart';

class PBButton extends StatelessWidget {
  const PBButton(this.text, {this.callback, super.key});
  final String text;
  final VoidCallback? callback;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () => callback?.call(),
              style: ElevatedButton.styleFrom(
                splashFactory: NoSplash.splashFactory,
                backgroundColor: PBColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                text,
                style: PBTextStyles.buttonTextStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
