import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:pushup_bro/features/onboarding/onboarding_page.dart';

/// Shows the onboarding until it's done, then [child] (the home screen).
class OnboardingGate extends StatelessWidget {
  const OnboardingGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<OnboardingCubit, OnboardingState>(
        buildWhen: (a, b) => a.loaded != b.loaded || a.completed != b.completed,
        builder: (context, state) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: !state.loaded
              ? ColoredBox(
                  key: const ValueKey('loading'),
                  color: context.colorScheme.surface,
                  child: const SizedBox.expand(),
                )
              : state.completed
                  ? KeyedSubtree(key: const ValueKey('home'), child: child)
                  : const OnboardingPage(key: ValueKey('onboarding')),
        ),
      );
}
