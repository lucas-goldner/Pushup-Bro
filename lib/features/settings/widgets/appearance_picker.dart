import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/appearance.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';

/// Picks light or dark mode, or following the phone: a segmented control
/// shaped like the tracking mode picker. The choice is remembered.
class AppearancePicker extends StatelessWidget {
  const AppearancePicker({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final current = context.watch<SharedPreferencesCubit>().state.appearance;
    final scheme = context.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: PBSpace.lg),
      padding: const EdgeInsets.all(PBSpace.xs),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: context.cardShadow,
      ),
      child: Row(
        children: [
          for (final (option, icon, label) in [
            (Appearance.system, CarbonIcons.mobile, l.appearanceSystem),
            (Appearance.light, CarbonIcons.sun, l.appearanceLight),
            (Appearance.dark, CarbonIcons.moon, l.appearanceDark),
          ])
            Expanded(
              child: GestureDetector(
                onTap: () => unawaited(
                  context.read<SharedPreferencesCubit>().setAppearance(option),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: PBSpace.md,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        option == current ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: option == current
                            ? scheme.onPrimary
                            : scheme.onSurface,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.textTheme.labelMedium?.copyWith(
                            color: option == current
                                ? scheme.onPrimary
                                : scheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
