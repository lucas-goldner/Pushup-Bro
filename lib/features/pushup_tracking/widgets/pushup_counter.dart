import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';

class PushupCounter extends StatelessWidget {
  const PushupCounter(this.pushups, {super.key});
  final int pushups;

  @override
  Widget build(BuildContext context) => AnimatedFlipCounter(
        value: pushups,
        prefix: context.l10n.pushupsCounter,
        textStyle: context.theme.textTheme.bodyLarge,
      );
}
