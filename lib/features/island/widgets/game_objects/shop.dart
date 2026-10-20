import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/features/island/model/game_menu_type.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

class Shop extends StatelessWidget {
  const Shop({required this.onMenuOpen, super.key});

  final void Function(GameMenuType) onMenuOpen;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Positioned(
            bottom: 200,
            right: 0,
            child: GestureDetector(
              onTap: () => onMenuOpen(GameMenuType.shop),
              child: Assets.images.island.shop.image(
                height: 200,
              ),
            ),
          ),
          Positioned(
            bottom: 232,
            right: 56,
            child: GestureDetector(
              onTap: () => onMenuOpen(GameMenuType.shop),
              child: Container(
                decoration: BoxDecoration(
                  color: context.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.colorScheme.surfaceDim,
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Text(
                    'Shop'.toUpperCase(),
                    style: context.textTheme.bodyMedium,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}
