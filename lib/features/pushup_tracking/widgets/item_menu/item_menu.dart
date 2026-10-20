import 'dart:math' as math;

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:pushup_bro/core/cubit/active_effects_cubit.dart';
import 'package:pushup_bro/core/cubit/booster_item_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/active_effects.dart';
import 'package:pushup_bro/core/model/booster_items.dart';
import 'package:pushup_bro/features/pushup_tracking/widgets/item_menu/item_friend_menu.dart';
import 'package:pushup_bro/features/pushup_tracking/widgets/item_menu/item_menu_item.dart';

class ItemMenu extends StatelessWidget {
  const ItemMenu({super.key});

  Future<void> _triggerItem(BuildContext context, BoosterItems item) async {
    final activeEffectsCubit = context.read<ActiveEffectsCubit>();
    final boosterItemCubit = context.read<BoosterItemCubit>();

    if (boosterItemCubit.state.items[item] == 0) {
      return;
    }

    switch (item) {
      case BoosterItems.doublePoints:
        activeEffectsCubit.addEffect(
          ActiveEffects.itemDoublePoints,
        );
        boosterItemCubit.consumeItem(
          item: BoosterItems.doublePoints,
        );
        return;
      case BoosterItems.friendBoost:
        await showCupertinoModalBottomSheet<bool>(
          backgroundColor: context.colorScheme.surface,
          context: context,
          useRootNavigator: true,
          builder: (context) => const ItemFriendMenu(),
        );
        return;
    }
  }

  @override
  Widget build(BuildContext context) => _ExpandableItemMenuButton(
        distance: 80,
        children: BoosterItems.values
            .map(
              (item) => ItemMenuItem(
                onPressed: () => _triggerItem(context, item),
                item: item,
              ),
            )
            .toList(),
      );
}

@immutable
class _ExpandableItemMenuButton extends StatefulWidget {
  const _ExpandableItemMenuButton({
    required this.distance,
    required this.children,
  });

  final double distance;
  final List<Widget> children;

  @override
  State<_ExpandableItemMenuButton> createState() =>
      _ExpandableItemMenuButtonState();
}

class _ExpandableItemMenuButtonState extends State<_ExpandableItemMenuButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _expandAnimation;
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeOutQuad,
      parent: _controller,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  Widget _buildTapToCloseFab() => GestureDetector(
        onTap: _toggle,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [context.shadow],
          ),
          child: SizedBox(
            width: 56,
            height: 56,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.close,
                  color: context.colorScheme.primary,
                ),
              ),
            ),
          ),
        ),
      );

  List<Widget> _buildExpandingActionButtons() {
    final children = <Widget>[];
    final count = widget.children.length;
    final step = 90.0 / (count - 1);
    for (var i = 0, angleInDegrees = 0.0;
        i < count;
        i++, angleInDegrees += step) {
      children.add(
        _ItemMenuItemContainer(
          directionInDegrees: angleInDegrees,
          maxDistance: widget.distance,
          progress: _expandAnimation,
          index: i,
          child: widget.children[i],
        ),
      );
    }
    return children;
  }

  Widget _buildTapToOpenFab() => IgnorePointer(
        ignoring: _open,
        child: AnimatedContainer(
          transformAlignment: Alignment.center,
          transform: Matrix4.diagonal3Values(
            _open ? 0.7 : 1.0,
            _open ? 0.7 : 1.0,
            1,
          ),
          duration: const Duration(milliseconds: 250),
          curve: const Interval(0, 0.5, curve: Curves.easeOut),
          child: AnimatedOpacity(
            opacity: _open ? 0.0 : 1.0,
            curve: const Interval(0.25, 1, curve: Curves.easeInOut),
            duration: const Duration(milliseconds: 250),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
              ),
              child: IconButton.filled(
                padding: const EdgeInsets.all(12),
                iconSize: 32,
                onPressed: _toggle,
                icon: Icon(
                  CarbonIcons.upgrade,
                  color: context.colorScheme.surface,
                ),
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 200,
        width: 200,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            _buildTapToCloseFab(),
            ..._buildExpandingActionButtons(),
            _buildTapToOpenFab(),
          ],
        ),
      );
}

@immutable
class _ItemMenuItemContainer extends StatelessWidget {
  const _ItemMenuItemContainer({
    required this.directionInDegrees,
    required this.maxDistance,
    required this.progress,
    required this.child,
    required this.index,
  });

  final double directionInDegrees;
  final double maxDistance;
  final Animation<double> progress;
  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: progress,
        builder: (context, child) {
          final offset = Offset.fromDirection(
            directionInDegrees * (math.pi / 180.0),
            progress.value * maxDistance,
          );
          final x = offset.dx +
              (maxDistance + 50) *
                  math.cos(directionInDegrees * (math.pi / 180.0)) *
                  index;
          return Positioned(
            right: x,
            bottom: 80,
            child: Transform.rotate(
              angle: (1.0 - progress.value) * math.pi / 2,
              child: child,
            ),
          );
        },
        child: FadeTransition(
          opacity: progress,
          child: child,
        ),
      );
}
