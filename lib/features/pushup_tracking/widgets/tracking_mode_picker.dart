import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/tracking_mode.dart';
import 'package:pushup_bro/core/style/pb_colors.dart';
import 'package:pushup_bro/core/style/pb_text_styles.dart';

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
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(20),
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
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: option == mode
                        ? (onDark ? Colors.white : background2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: _foreground(selected: option == mode),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: buttonTextStyle.copyWith(
                          color: _foreground(selected: option == mode),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
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

  Color _foreground({required bool selected}) => onDark
      ? (selected ? background2 : Colors.white)
      : (selected ? Colors.white : background2);
}
