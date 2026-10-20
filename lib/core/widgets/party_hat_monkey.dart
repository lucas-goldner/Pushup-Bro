import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/features/island/model/shop_buyables.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/pushup_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/pushup_state.dart';
import 'package:pushup_bro/generated/assets.gen.dart';
import 'package:rive/rive.dart';

class PartyHatMonkey extends StatefulWidget {
  const PartyHatMonkey(
    this.equipedAccessory, {
    super.key,
  });

  final ShopBuyables equipedAccessory;

  @override
  State<PartyHatMonkey> createState() => _PartyHatMonkeyState();
}

class _PartyHatMonkeyState extends State<PartyHatMonkey> {
  BooleanInput? _bump;
  BooleanInput? _accessory;
  bool _inPushup = false;
  double height = 250;
  double width = 250;

  /// Built once so [RiveWidgetBuilder] keeps the same artboard and state
  /// machine for the lifetime of this widget; see `Monkey` for why.
  late final FileLoader _fileLoader;

  bool get _wearsPartyHat =>
      widget.equipedAccessory == ShopBuyables.accessoryPartyHat;

  @override
  void initState() {
    super.initState();
    _fileLoader = Assets.rive.partyMonkeyPushup.riveFileLoader();
  }

  @override
  void dispose() {
    _fileLoader.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PartyHatMonkey oldWidget) {
    super.didUpdateWidget(oldWidget);
    _accessory?.value = _wearsPartyHat;
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
    // Same deprecation as `pushup` above.
    // ignore: deprecated_member_use
    _accessory = controller.stateMachine.boolean('party_hat')
      ?..value = _wearsPartyHat;

    return controller;
  }

  void _triggerPushupAnim(bool anim) {
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
