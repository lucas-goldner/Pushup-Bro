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
  bool _inPushup = false;
  double height = 250;
  double width = 250;

  /// Built once so [RiveWidgetBuilder] keeps the same artboard and state
  /// machine for the lifetime of this widget.
  ///
  /// [FileLoader] has no value equality, so handing out a fresh instance on
  /// every build makes `didUpdateWidget` reload the file and rebuild the
  /// controller — which resets the `pushup` input back to `false` and drops
  /// the animation we just asked for.
  late final FileLoader _fileLoader;

  @override
  void initState() {
    super.initState();
    _fileLoader = Assets.rive.monkeyPushup.riveFileLoader();
  }

  @override
  void dispose() {
    _fileLoader.dispose();
    super.dispose();
  }

  RiveWidgetController _createController(File file) {
    final controller = RiveWidgetController(
      file,
      stateMachineSelector: const StateMachineNamed('PushupState'),
    );
    // Rive 0.14 marks state machine inputs deprecated in favor of data
    // binding; migrating the artboards to view models is out of scope here.
    // ignore: deprecated_member_use
    _bump = controller.stateMachine.boolean('pushup')?..value = _inPushup;

    return controller;
  }

  void _triggerPushupAnim(bool anim) {
    // Remembered so a controller created after the first pushup event still
    // starts on the pose the cubit is currently in.
    _inPushup = anim;
    _bump?.value = anim;
  }

  @override
  Widget build(BuildContext context) => BlocListener<PushupCubit, PushupState>(
        listenWhen: (previous, current) =>
            previous.inPushup != current.inPushup,
        listener: (context, state) => _triggerPushupAnim(state.inPushup),
        child: SizedBox(
          height: height,
          width: width,
          child: RiveWidgetBuilder(
            fileLoader: _fileLoader,
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
}
