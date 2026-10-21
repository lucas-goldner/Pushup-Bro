import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/core/extensions/color_ext.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';

class VolumeDisplayer extends StatelessWidget {
  const VolumeDisplayer(this.volume, {super.key});
  final int volume;

  @override
  Widget build(BuildContext context) {
    double getRandomPadding(int i) => math.Random().nextInt(20).toDouble() + i;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 100,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: background2,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i <= 9; i++) ...{
                  Padding(
                    padding: EdgeInsets.only(
                      top: getRandomPadding(i),
                      bottom: getRandomPadding(i),
                    ),
                    child: Container(
                      color: Color.fromRGBO(
                        i == 0 ? 255 : 255 ~/ i,
                        i * 25,
                        0,
                        1,
                      ).darken(i >= volume ? 200 : 0),
                      height: 28,
                      width: 14,
                    ),
                  ),
                  const SizedBox(
                    width: 8,
                  ),
                },
              ],
            ),
          ),
        ),
      ),
    );
  }
}
