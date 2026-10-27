import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/tracking_mode.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';

/// Picks how pushups are counted, AirPods or camera; shown in the settings
/// and before every workout. The choice is remembered.
class TrackingModePicker extends StatelessWidget {
  const TrackingModePicker({this.onDark = false, super.key});

  /// For dark backgrounds (the jungle, the Trek): a glassier look.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return BlocSelector<SharedPreferencesCubit, SharedPreferencesState,
        TrackingMode>(
      selector: (state) => state.trackingMode,
      builder: (context, mode) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: onDark
              ? context.gameColors.onGame.withValues(alpha: 0.18)
              : context.colorScheme.surface,
          borderRadius: BorderRadius.circular(PBRadius.pill),
          boxShadow: onDark ? null : context.cardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (option, icon, label) in [
              (TrackingMode.airpods, CarbonIcons.headphones, l.trackingAirpods),
              (TrackingMode.camera, CarbonIcons.camera, l.trackingCamera),
            ])
              GestureDetector(
                onTap: () => unawaited(
                  context
                      .read<SharedPreferencesCubit>()
                      .setTrackingMode(option),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: option == mode
                        ? (onDark
                            ? context.colorScheme.surface
                            : context.colorScheme.primary)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(PBRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: _foreground(context, selected: option == mode),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: context.textTheme.labelMedium?.copyWith(
                          color: _foreground(context, selected: option == mode),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _foreground(BuildContext context, {required bool selected}) => onDark
      ? (selected ? context.colorScheme.onSurface : context.gameColors.onGame)
      : (selected
          ? context.colorScheme.onPrimary
          : context.colorScheme.onSurfaceVariant);
}
