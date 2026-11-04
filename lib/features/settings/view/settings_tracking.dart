import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/tracking_mode.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/pb_button.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/airpods_tracker_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/airpods_tracker_state.dart';
import 'package:pushup_bro/features/pushup_tracking/model/airpods_calibration.dart';
import 'package:pushup_bro/features/settings/widgets/settings_group.dart';

/// How long the test waits for AirPods movement before asking whether
/// they're in.
const _kNoMotionAfter = Duration(seconds: 4);

/// The tracking's finer settings: what the camera window shows, and how
/// sensitive the AirPods counting is, with a test to find the right level.
class TrackingSettingsPage extends StatelessWidget {
  const TrackingSettingsPage({super.key});
  static const routeName = '/tracking';

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return CupertinoPageScaffold(
      backgroundColor: context.colorScheme.surfaceContainerLow,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: PBSpace.xl),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      PBSpace.xl,
                      PBSpace.lg,
                      PBSpace.xl,
                      PBSpace.sm,
                    ),
                    child: Text(
                      l.trackingAdvanced,
                      style: context.textTheme.headlineLarge,
                    ),
                  ),
                  SettingsSectionHeader(l.trackingCameraTitle),
                  const _CameraViews(),
                  SettingsSectionHeader(l.airpodsTitle),
                  const _Sensitivity(),
                  const SizedBox(height: PBSpace.md),
                  const _CalibrationTest(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PBSpace.sm,
                PBSpace.sm,
                PBSpace.sm,
                PBSpace.lg,
              ),
              child: PBButton(
                l.goBack,
                callback: () => Navigator.of(context).pop(),
                expanded: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The two camera views, one ticked.
class _CameraViews extends StatelessWidget {
  const _CameraViews();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final view = context.select<SharedPreferencesCubit, CameraView>(
      (cubit) => cubit.state.cameraView,
    );

    Widget option(CameraView value, String title, String info, IconData icon) =>
        InkWell(
          onTap: () {
            GameAudio.instance.play(Sfx.tap);
            unawaited(
              context.read<SharedPreferencesCubit>().setCameraView(value),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PBSpace.lg,
              vertical: PBSpace.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: context.tint(context.gameColors.jungle),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: context.gameColors.jungle),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: context.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        info,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: PBSpace.sm),
                Icon(
                  view == value
                      ? CarbonIcons.checkmark_filled
                      : CarbonIcons.circle_dash,
                  size: 22,
                  color: view == value
                      ? context.colorScheme.secondary
                      : context.colorScheme.outline,
                ),
              ],
            ),
          ),
        );

    return SettingsGroup(
      children: [
        option(
          CameraView.person,
          l.cameraViewPerson,
          l.cameraViewPersonInfo,
          CarbonIcons.user_avatar,
        ),
        option(
          CameraView.skeleton,
          l.cameraViewSkeleton,
          l.cameraViewSkeletonInfo,
          CarbonIcons.pedestrian,
        ),
      ],
    );
  }
}

/// The AirPods sensitivity slider, with the reset to the standard level.
class _Sensitivity extends StatelessWidget {
  const _Sensitivity();

  @override
  Widget build(BuildContext context) =>
      BlocSelector<SharedPreferencesCubit, SharedPreferencesState, int>(
        selector: (state) => state.airpodsSensitivity,
        builder: (context, level) {
          final l = context.l10n;
          final muted = context.colorScheme.onSurfaceVariant;
          final standard = level == AirPodsSensitivity.standard;

          return SettingsGroup(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PBSpace.lg,
                  PBSpace.md,
                  PBSpace.lg,
                  PBSpace.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: PBSpace.sm,
                      children: [
                        Text(
                          l.airpodsSensitivity,
                          style: context.textTheme.titleMedium,
                        ),
                        Text(
                          [
                            l.airpodsLevel(level),
                            if (standard) l.airpodsStandard,
                          ].join(' · '),
                          style: context.textTheme.labelLarge?.copyWith(
                            color: context.colorScheme.secondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l.airpodsSensitivityInfo,
                      style:
                          context.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                    Slider(
                      value: level.toDouble(),
                      min: AirPodsSensitivity.min.toDouble(),
                      max: AirPodsSensitivity.max.toDouble(),
                      divisions:
                          AirPodsSensitivity.max - AirPodsSensitivity.min,
                      onChanged: (value) => unawaited(
                        context
                            .read<SharedPreferencesCubit>()
                            .setAirpodsSensitivity(value.round()),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l.airpodsLow,
                            style: context.textTheme.labelSmall
                                ?.copyWith(color: muted),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            l.airpodsHigh,
                            textAlign: TextAlign.end,
                            style: context.textTheme.labelSmall
                                ?.copyWith(color: muted),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SettingsRow(
                label: l.airpodsReset,
                icon: CarbonIcons.reset,
                color: context.gameColors.orange,
                trailing: const SizedBox.shrink(),
                onTap: standard
                    ? () {}
                    : () {
                        GameAudio.instance.play(Sfx.tap);
                        unawaited(
                          context
                              .read<SharedPreferencesCubit>()
                              .setAirpodsSensitivity(
                                AirPodsSensitivity.standard,
                              ),
                        );
                      },
              ),
            ],
          );
        },
      );
}

/// A test with the AirPods in: a few pushups, counted live at the chosen
/// level, and the level that suits them best.
class _CalibrationTest extends StatefulWidget {
  const _CalibrationTest();

  @override
  State<_CalibrationTest> createState() => _CalibrationTestState();
}

class _CalibrationTestState extends State<_CalibrationTest> {
  final _calibration = AirPodsCalibration();
  bool _running = false;
  bool _heard = false;
  Timer? _silence;
  bool _silent = false;

  @override
  void dispose() {
    _silence?.cancel();
    if (_running) context.read<AirPodsTrackerCubit>().stopListening();
    super.dispose();
  }

  void _start() {
    final level =
        context.read<SharedPreferencesCubit>().state.airpodsSensitivity;
    _calibration.reset(level: level);
    GameAudio.instance.play(Sfx.ready);
    context.read<AirPodsTrackerCubit>().getAirPodsMotionData();
    _silence?.cancel();
    _silence = Timer(_kNoMotionAfter, () {
      if (mounted && !_heard) setState(() => _silent = true);
    });
    setState(() {
      _running = true;
      _heard = false;
      _silent = false;
    });
  }

  void _stop() {
    _silence?.cancel();
    context.read<AirPodsTrackerCubit>().stopListening();
    setState(() => _running = false);
  }

  void _onMotion(AirPodsTrackerState state) {
    final motion = state.currentMotionData;
    if (!_running || motion == null) return;
    final before = _calibration.counted;
    _calibration.add(motion.userAcceleration.y.toDouble());
    if (_calibration.counted > before) GameAudio.instance.play(Sfx.pop);
    setState(() {
      _heard = true;
      _silent = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = context.colorScheme;
    final level = context.select<SharedPreferencesCubit, int>(
      (cubit) => cubit.state.airpodsSensitivity,
    );
    // Counting at the level on the slider, even if it moves mid-test.
    _calibration.level = level;
    final suggestion = _calibration.suggestion;
    final threshold = AirPodsSensitivity.threshold(level);

    return BlocListener<AirPodsTrackerCubit, AirPodsTrackerState>(
      listener: (context, state) => _onMotion(state),
      child: SettingsGroup(
        children: [
          Padding(
            padding: const EdgeInsets.all(PBSpace.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.airpodsTest, style: context.textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  l.airpodsTestInfo,
                  style: context.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                if (_running) ...[
                  const SizedBox(height: PBSpace.lg),
                  _MotionMeter(
                    value: _calibration.latest,
                    threshold: threshold,
                  ),
                  const SizedBox(height: PBSpace.md),
                  Text(
                    l.airpodsCounted(_calibration.counted),
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    l.airpodsFound(_calibration.reps.length),
                    style: context.textTheme.bodyMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: PBSpace.sm),
                  Text(
                    _silent
                        ? l.airpodsNoMotion
                        : suggestion == null
                            ? l.airpodsKeepGoing
                            : l.airpodsSuggestion(suggestion),
                    style: context.textTheme.labelLarge?.copyWith(
                      color: _silent
                          ? context.gameColors.orange
                          : scheme.secondary,
                    ),
                  ),
                ],
                const SizedBox(height: PBSpace.lg),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: PBSpace.sm,
                  runSpacing: PBSpace.sm,
                  children: [
                    PillButton(
                      label: _running ? l.airpodsTestStop : l.airpodsTestStart,
                      icon: _running ? CarbonIcons.stop : CarbonIcons.play,
                      onPressed: _running ? _stop : _start,
                    ),
                    if (suggestion != null && suggestion != level)
                      PillButton(
                        label: l.airpodsApply(suggestion),
                        icon: CarbonIcons.checkmark,
                        onPressed: () {
                          GameAudio.instance.play(Sfx.unlock);
                          unawaited(
                            context
                                .read<SharedPreferencesCubit>()
                                .setAirpodsSensitivity(suggestion),
                          );
                          _calibration.reset(level: suggestion);
                          setState(() {});
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The head's movement right now, as a bar from the middle (up or down),
/// with marks where a pushup starts and finishes at the chosen level.
class _MotionMeter extends StatelessWidget {
  const _MotionMeter({required this.value, required this.threshold});

  final double value;
  final double threshold;

  /// The meter's range, in g each way.
  static const _range = 0.7;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final over = value.abs() >= threshold;

    return SizedBox(
      height: 28,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final half = constraints.maxWidth / 2;
          final reach = (value / _range).clamp(-1.0, 1.0) * half;
          final mark = (threshold / _range).clamp(0.0, 1.0) * half;

          return Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(PBRadius.pill),
                  ),
                ),
              ),
              Positioned(
                left: reach < 0 ? half + reach : half,
                width: reach.abs(),
                top: 4,
                bottom: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: over ? scheme.secondary : scheme.outline,
                    borderRadius: BorderRadius.circular(PBRadius.pill),
                  ),
                ),
              ),
              for (final x in [half - mark, half + mark])
                Positioned(
                  left: x - 1,
                  width: 2,
                  top: 0,
                  bottom: 0,
                  child: ColoredBox(color: context.gameColors.orange),
                ),
              Positioned(
                left: half - 1,
                width: 2,
                top: 6,
                bottom: 6,
                child: ColoredBox(color: scheme.onSurfaceVariant),
              ),
            ],
          );
        },
      ),
    );
  }
}
