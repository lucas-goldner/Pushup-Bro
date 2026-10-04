import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/cubit/pushups/pushup_cubit.dart';
import 'package:pushup_bro/cubit/pushups/pushup_state.dart';
import 'package:pushup_bro/generated/assets.gen.dart';
import 'package:rive/rive.dart';

class Monkey extends StatefulWidget {
  const Monkey({super.key});

  @override
  State<Monkey> createState() => _MonkeyState();
}

class _MonkeyState extends State<Monkey> {
  BooleanInput? _bump;
  double height = 250;
  double width = 250;

  RiveWidgetController _createController(File file) {
    final controller = RiveWidgetController(
      file,
      stateMachineSelector: const StateMachineNamed('PushupState'),
    );
    // Rive 0.14 marks state machine inputs deprecated in favor of data
    // binding; migrating the artboards to view models is out of scope here.
    // ignore: deprecated_member_use
    _bump = controller.stateMachine.boolean('pushup');

    return controller;
  }

  void _triggerPushupAnim(bool anim) {
    final bump = _bump;
    if (bump != null) {
      bump.value = anim;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PushupCubit, PushupState, bool>(
      selector: (state) => state.inPushup,
      builder: (context, pushupState) {
        _triggerPushupAnim(pushupState);

        return AnimatedContainer(
          duration: const Duration(seconds: 3),
          child: SizedBox(
            height: height,
            width: width,
            child: RiveWidgetBuilder(
              fileLoader: Assets.rive.monkeyPushup.riveFileLoader(),
              controller: _createController,
              builder: (context, state) => switch (state) {
                RiveLoading() => const SizedBox.shrink(),
                RiveFailed() => const SizedBox.shrink(),
                RiveLoaded(:final controller) =>
                  RiveWidget(controller: controller),
              },
            ),
          ),
        );
      },
    );
  }
}
