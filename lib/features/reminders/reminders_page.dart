import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/provider/url_launch_provider.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/pb_button.dart';
import 'package:pushup_bro/core/widgets/phone_page.dart';
import 'package:pushup_bro/features/reminders/cubit/reminders_cubit.dart';
import 'package:pushup_bro/features/reminders/cubit/reminders_state.dart';
import 'package:pushup_bro/features/reminders/model/reminder_settings.dart';
import 'package:pushup_bro/features/settings/widgets/settings_group.dart';

/// The reminder settings: the daily reminder switch, its time and what
/// Pushup Bro sends.
class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (_) => const PhonePage(child: RemindersPage()),
        ),
      );

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<RemindersCubit, RemindersState>(
        builder: (context, state) => CupertinoPageScaffold(
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
                          context.l10n.reminderPageTitle,
                          style: context.textTheme.headlineLarge,
                        ),
                      ),
                      const SizedBox(height: PBSpace.lg),
                      _ReminderControls(state: state),
                      _Footnote(context.l10n.reminderToggleFooter),
                      if (state.permissionDenied) ...[
                        const SizedBox(height: PBSpace.lg),
                        const _PermissionHint(),
                      ],
                      SettingsSectionHeader(context.l10n.reminderWhatWeSend),
                      const _WhatWeSend(),
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
                    context.l10n.goBack,
                    callback: () => Navigator.of(context).pop(),
                    expanded: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// The switch and the time.
class _ReminderControls extends StatelessWidget {
  const _ReminderControls({required this.state});

  final RemindersState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RemindersCubit>();
    final on = state.settings.enabled && !state.permissionDenied;
    void toggle({required bool enabled}) =>
        unawaited(cubit.setEnabled(enabled: enabled));

    return SettingsGroup(
      children: [
        SettingsRow(
          label: context.l10n.reminderDailyToggle,
          icon: CarbonIcons.notification,
          onTap: () => toggle(enabled: !on),
          trailing: CupertinoSwitch(
            value: on,
            activeTrackColor: context.colorScheme.primary,
            onChanged: (enabled) => toggle(enabled: enabled),
          ),
        ),
        SettingsRow(
          label: context.l10n.reminderTime,
          icon: CarbonIcons.time,
          color: context.gameColors.orange,
          onTap: () => unawaited(_pickTime(context, state.settings)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(context, state.settings),
                style: context.textTheme.titleMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: PBSpace.xs),
              Icon(
                CarbonIcons.chevron_right,
                size: 18,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ],
    );
  }

  static String _formatTime(BuildContext context, ReminderSettings settings) =>
      MaterialLocalizations.of(context).formatTimeOfDay(
        TimeOfDay(hour: settings.hour, minute: settings.minute),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );

  static Future<void> _pickTime(
    BuildContext context,
    ReminderSettings settings,
  ) async {
    final cubit = context.read<RemindersCubit>();
    final picked = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (_) => _TimeSheet(
        initial: DateTime(2000, 1, 1, settings.hour, settings.minute),
      ),
    );
    if (picked == null) return;
    await cubit.setTime(hour: picked.hour, minute: picked.minute);
  }
}

/// A sheet with a wheel time picker and a Done button.
class _TimeSheet extends StatefulWidget {
  const _TimeSheet({required this.initial});

  final DateTime initial;

  @override
  State<_TimeSheet> createState() => _TimeSheetState();
}

class _TimeSheetState extends State<_TimeSheet> {
  late DateTime _time = widget.initial;

  @override
  Widget build(BuildContext context) {
    final cupertino = CupertinoTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(PBRadius.sheet),
        ),
        boxShadow: context.cardShadow,
      ),
      padding: const EdgeInsets.fromLTRB(
        PBSpace.lg,
        PBSpace.md,
        PBSpace.lg,
        PBSpace.lg,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.reminderTime,
                    style: context.textTheme.titleLarge,
                  ),
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: PBSpace.md),
                  onPressed: () => Navigator.of(context).pop(_time),
                  child: Text(
                    context.l10n.reminderTimeDone,
                    style: context.textTheme.titleMedium?.copyWith(
                      color: context.colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              height: 216,
              child: CupertinoTheme(
                data: cupertino.copyWith(
                  textTheme: cupertino.textTheme.copyWith(
                    dateTimePickerTextStyle: cupertino
                        .textTheme.dateTimePickerTextStyle
                        .copyWith(color: context.colorScheme.onSurface),
                  ),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: widget.initial,
                  use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
                  backgroundColor: context.colorScheme.surface,
                  onDateTimeChanged: (time) => _time = time,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small muted text below a group.
class _Footnote extends StatelessWidget {
  const _Footnote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          PBSpace.xl + PBSpace.sm,
          PBSpace.sm,
          PBSpace.xl,
          0,
        ),
        child: Text(
          text,
          style: context.textTheme.bodySmall?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      );
}

/// Notifications are blocked: how to allow them again.
class _PermissionHint extends StatelessWidget {
  const _PermissionHint();

  @override
  Widget build(BuildContext context) {
    final coral = context.gameColors.coral;

    return SettingsGroup(
      children: [
        Padding(
          padding: const EdgeInsets.all(PBSpace.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconTile(icon: CarbonIcons.notification_off, color: coral),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.reminderDeniedTitle,
                      style: context.textTheme.titleMedium,
                    ),
                    const SizedBox(height: PBSpace.xs),
                    Text(
                      context.l10n.reminderDeniedHint,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SettingsRow(
          label: context.l10n.reminderOpenSettings,
          icon: CarbonIcons.launch,
          color: coral,
          onTap: () => unawaited(_openSystemSettings()),
        ),
      ],
    );
  }

  static Future<void> _openSystemSettings() async {
    try {
      await UrlLauncherProvider(const UrlLauncherService())
          .launchUri(Uri.parse('app-settings:'));
    } on Exception catch (error) {
      debugPrint('Could not open the Settings app: $error');
    }
  }
}

/// The five kinds of notifications, as muted text.
class _WhatWeSend extends StatelessWidget {
  const _WhatWeSend();

  @override
  Widget build(BuildContext context) {
    final game = context.gameColors;
    final kinds = [
      (
        CarbonIcons.notification,
        context.colorScheme.secondary,
        context.l10n.reminderKindDaily,
      ),
      (CarbonIcons.fire, game.orange, context.l10n.reminderKindStreak),
      (CarbonIcons.tree, game.jungle, context.l10n.reminderKindQuest),
      (CarbonIcons.hourglass, game.purple, context.l10n.reminderKindFreeDays),
      (CarbonIcons.undo, game.coral, context.l10n.reminderKindComeback),
    ];

    return SettingsGroup(
      children: [
        for (final (icon, color, text) in kinds)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: PBSpace.lg,
              vertical: PBSpace.md,
            ),
            child: Row(
              children: [
                _IconTile(icon: icon, color: color),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    text,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A tinted icon tile like the ones in [SettingsRow].
class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: context.tint(color),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      );
}
