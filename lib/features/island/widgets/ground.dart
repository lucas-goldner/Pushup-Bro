import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';

class Ground extends StatelessWidget {
  const Ground({super.key});

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Column(
            children: [
              Flexible(
                flex: 4,
                child: ColoredBox(
                  color: context.gameColorsTheme.grass,
                  child: const SizedBox.expand(),
                ),
              ),
              Flexible(
                flex: 5,
                child: ColoredBox(
                  color: context.gameColorsTheme.sand,
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
          Positioned(
            top: context.sizeOf.height / 2.5,
            left: -20,
            child: Row(
              children: [
                Container(
                  width: 100,
                  height: 50,
                  decoration: BoxDecoration(
                    color: context.gameColorsTheme.sand,
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                const SizedBox(
                  width: 100,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 32),
                  child: Container(
                    width: 100,
                    height: 30,
                    decoration: BoxDecoration(
                      color: context.gameColorsTheme.sand,
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}
