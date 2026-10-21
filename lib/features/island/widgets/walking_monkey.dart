import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/widgets/party_hat_monkey.dart';
import 'package:pushup_bro/features/island/model/adoptable_monkey.dart';
import 'package:pushup_bro/features/island/model/game_menu_type.dart';
import 'package:pushup_bro/features/island/model/turning_direction.dart';

class WalkingMonkey extends StatefulWidget {
  const WalkingMonkey({required this.onMenuOpen, super.key});

  final void Function(GameMenuType gameMenuType) onMenuOpen;

  @override
  State<WalkingMonkey> createState() => _WalkingMonkeyState();
}

class _WalkingMonkeyState extends State<WalkingMonkey>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final animationPath = Tween<double>(begin: 20, end: 200);
  TurningDirection turningDirection = TurningDirection.right;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    _animation =
        Tween<double>(begin: animationPath.begin, end: animationPath.end)
            .animate(_controller)
          ..addListener(
            () {
              if (_animation.value >= (animationPath.end! - 0.2)) {
                setState(() => turningDirection = TurningDirection.left);
              }

              if (_animation.value <= (animationPath.begin! + 0.2)) {
                setState(() => turningDirection = TurningDirection.right);
              }
            },
          );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocSelector<GameInventoryCubit, GameInventoryState, AdoptableMonkey>(
        selector: (state) => state.inventory.monkeys.first,
        builder: (context, monkey) => AnimatedPositioned(
          duration: const Duration(
            seconds: 10,
          ),
          curve: Curves.easeInOut,
          left: _animation.value,
          top: context.sizeOf.height / 3,
          child: GestureDetector(
            onTap: () => widget.onMenuOpen(GameMenuType.monkey),
            child: Transform.scale(
              scale: 0.5,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(
                  turningDirection == TurningDirection.right ? 0.0 : 3.1416,
                ),
                child: PartyHatMonkey(monkey.accessory),
              ),
            ),
          ),
        ),
      );
}
