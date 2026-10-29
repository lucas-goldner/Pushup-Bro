import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/pro/cubit/pro_cubit.dart';
import 'package:pushup_bro/features/pro/model/pro_state.dart';
import 'package:pushup_bro/features/pro/paywall/show_paywall.dart';
import 'package:pushup_bro/features/settings/widgets/settings_group.dart';
import 'package:pushup_bro/features/social/account/connect_account.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/cubit/account_state.dart';
import 'package:pushup_bro/features/social/cubit/cloud_save.dart';
import 'package:pushup_bro/features/social/data/social_backend.dart';
import 'package:pushup_bro/features/social/domain/friend_code.dart';
import 'package:pushup_bro/features/social/model/bro_profile.dart';
import 'package:pushup_bro/features/social/widgets/bro_avatar.dart';
import 'package:pushup_bro/features/social/widgets/social_widgets.dart';

/// Settings, Account: the bro name and code everyone gets, and for Pro
/// members Apple and Google to keep the island, friend settings, sign out
/// and Delete account (which App Review requires).
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});
  static const routeName = '/settings/account';

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: context.colorScheme.surfaceContainerLow,
        appBar: AppBar(
          title: Text(context.l10n.accountTitle),
          backgroundColor: Colors.transparent,
        ),
        body: SocialGate(
          builder: (context, me) => BlocBuilder<AccountCubit, AccountState>(
            builder: (context, account) => BlocBuilder<ProCubit, ProState>(
              builder: (context, pro) => _Account(
                me: account.profile ?? me,
                account: account,
                pro: pro,
              ),
            ),
          ),
        ),
      );
}

class _Account extends StatelessWidget {
  const _Account({required this.me, required this.account, required this.pro});

  final BroProfile me;
  final AccountState account;
  final ProState pro;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final linked = account.isLinked;
    final save = context.read<CloudSave>();

    return ListView(
      padding: const EdgeInsets.only(bottom: PBSpace.xxl),
      children: [
        Padding(
          padding: const EdgeInsets.all(PBSpace.lg),
          child: SocialCard(
            child: Row(
              children: [
                BroAvatar(look: me.look, size: 56),
                const SizedBox(width: PBSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        broNameOf(context, me.broName),
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${FriendCode.format(me.code)} · ${pro.isPro ? '👑 '
                            '${l.accountPro}' : l.accountLocalOnly}',
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (linked)
                  SocialChip(
                    '☁️ ${l.accountSaved}',
                    color: context.tint(context.gameColors.jungle),
                  ),
              ],
            ),
          ),
        ),
        if (pro.isPro || linked) ...[
          SettingsGroup(
            children: [
              _ProviderRow(provider: SignInProvider.apple, account: account),
              _ProviderRow(provider: SignInProvider.google, account: account),
              SettingsRow(
                label: l.accountLastSaved,
                icon: CarbonIcons.renew,
                color: context.colorScheme.secondary,
                onTap: () => unawaited(save.saveNow()),
                trailing: Text(
                  _ago(context, account.savedAt),
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          if (linked && !pro.isPro)
            _Note(l.accountPaused, color: context.gameColors.orange),
        ] else ...[
          const _BackupCard(),
          _Note(l.accountFreeNote),
          Center(
            child: TextButton(
              onPressed: () => _restore(context),
              child: Text(l.accountRestore),
            ),
          ),
        ],
        SettingsSectionHeader(l.accountFriends),
        SettingsGroup(
          children: [
            SettingsRow(
              label: l.accountFriendName,
              icon: CarbonIcons.tag,
              color: context.gameColors.orange,
              onTap: () => _editFriendName(context),
              trailing: Text(
                account.friendName,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            SettingsRow(
              label: l.accountShowEveryone,
              icon: CarbonIcons.earth,
              color: context.gameColors.jungle,
              onTap: () => context
                  .read<AccountCubit>()
                  .setShowOnEveryone(show: !me.showOnEveryone),
              trailing: CupertinoSwitch(
                value: me.showOnEveryone,
                onChanged: (show) =>
                    context.read<AccountCubit>().setShowOnEveryone(show: show),
              ),
            ),
            _BlockedRow(me: me),
          ],
        ),
        const SizedBox(height: PBSpace.xl),
        SettingsGroup(
          children: [
            if (linked)
              SettingsRow(
                label: l.accountSignOut,
                icon: CarbonIcons.logout,
                onTap: () => _signOut(context),
              ),
            SettingsRow(
              label: l.accountDelete,
              icon: CarbonIcons.trash_can,
              color: context.gameColors.red,
              onTap: () => _delete(context),
            ),
          ],
        ),
        _Note(l.accountDeleteNote),
      ],
    );
  }

  static String _ago(BuildContext context, DateTime? at) {
    final l = context.l10n;
    if (at == null) return l.accountNever;
    final since = DateTime.now().difference(at);
    if (since.inMinutes < 1) return l.accountJustNow;
    if (since.inHours < 1) return l.accountMinutesAgo(since.inMinutes);
    if (since.inDays < 1) return l.accountHoursAgo(since.inHours);
    return DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag())
        .format(at);
  }

  Future<void> _restore(BuildContext context) => pickAndRestore(context);

  Future<void> _editFriendName(BuildContext context) async {
    final l = context.l10n;
    final controller = TextEditingController(text: account.friendName);
    final name = await showCupertinoDialog<String>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(l.accountFriendName),
        content: Padding(
          padding: const EdgeInsets.only(top: PBSpace.md),
          child: CupertinoTextField(
            controller: controller,
            placeholder: l.accountFriendNameHint,
            maxLength: 24,
            autofocus: true,
          ),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l.brosCancel),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(l.accountOk),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && context.mounted) {
      await context.read<AccountCubit>().setFriendName(name);
    }
  }

  Future<bool> _confirm(
    BuildContext context,
    String text,
    String action,
  ) async =>
      await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(text),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(context.l10n.brosCancel),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  Future<void> _signOut(BuildContext context) async {
    final l = context.l10n;
    if (!await _confirm(context, l.accountSignOutConfirm, l.accountSignOut)) {
      return;
    }
    if (!context.mounted) return;
    await context.read<AccountCubit>().signOut(look: me.look);
  }

  Future<void> _delete(BuildContext context) async {
    final l = context.l10n;
    if (!await _confirm(context, l.accountDeleteConfirm, l.accountDelete)) {
      return;
    }
    if (!context.mounted) return;
    await context.read<AccountCubit>().deleteAccount(look: me.look);
  }
}

class _ProviderRow extends StatelessWidget {
  const _ProviderRow({required this.provider, required this.account});

  final SignInProvider provider;
  final AccountState account;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final connected = account.linked.contains(provider);
    final apple = provider == SignInProvider.apple;

    return SettingsRow(
      label: apple ? l.accountApple : l.accountGoogle,
      icon: apple ? Icons.apple : CarbonIcons.logo_google,
      color: context.colorScheme.onSurface,
      onTap: connected ? () {} : () => connectAccount(context, provider),
      trailing: Text(
        connected ? l.accountConnected : l.accountConnect,
        style: context.textTheme.bodyMedium?.copyWith(
          color: connected
              ? context.colorScheme.onSurfaceVariant
              : context.colorScheme.secondary,
          fontWeight: connected ? null : FontWeight.w700,
        ),
      ),
    );
  }
}

class _BlockedRow extends StatelessWidget {
  const _BlockedRow({required this.me});

  final BroProfile me;

  @override
  Widget build(BuildContext context) {
    final backend = context.read<AccountCubit>().backend;

    return StreamBuilder<List<String>>(
      stream: backend.blocked(me.uid),
      builder: (context, snapshot) {
        final blocked = snapshot.data ?? const [];
        return SettingsRow(
          label: context.l10n.accountBlocked,
          icon: CarbonIcons.misuse,
          color: context.gameColors.red,
          onTap: () => _show(context, blocked),
          trailing: Text(
            '${blocked.length}',
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }

  Future<void> _show(BuildContext context, List<String> blocked) async {
    if (blocked.isEmpty) return;
    final backend = context.read<AccountCubit>().backend;
    final profiles = [
      for (final uid in blocked)
        if (await backend.profile(uid) case final profile?) profile,
    ];
    if (!context.mounted) return;
    final unblock = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(context.l10n.accountUnblock),
        actions: [
          for (final profile in profiles)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop(profile.uid),
              child: Text(broNameOf(context, profile.broName)),
            ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.brosCancel),
        ),
      ),
    );
    if (unblock != null) await backend.unblock(me: me.uid, other: unblock);
  }
}

/// "Back up your island", the Pro perk, for free players.
class _BackupCard extends StatelessWidget {
  const _BackupCard();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final blue = context.colorScheme.secondary;
    final ink = context.gameColors.onGame;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: PBSpace.lg),
      padding: const EdgeInsets.all(PBSpace.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(blue, Colors.white, 0.2)!, blue],
        ),
        borderRadius: BorderRadius.circular(PBRadius.lg),
        boxShadow: context.glow(blue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: context.colorScheme.primary,
              borderRadius: BorderRadius.circular(PBRadius.pill),
            ),
            child: Text(
              '👑 PRO',
              style: context.textTheme.labelMedium?.copyWith(
                color: context.gameColors.banana,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: PBSpace.md),
          Text(
            l.accountBackupTitle,
            style: context.textTheme.titleLarge?.copyWith(
              color: ink,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: PBSpace.xs),
          Text(
            l.accountBackupText,
            style: context.textTheme.bodyMedium?.copyWith(
              color: ink.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: PBSpace.lg),
          GestureDetector(
            onTap: () => showPaywall(context),
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: ink,
                borderRadius: BorderRadius.circular(PBRadius.pill),
              ),
              child: Text(
                l.accountSeePro,
                style: context.textTheme.titleSmall?.copyWith(
                  color: const Color(0xFF17203A),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text, {this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(
          PBSpace.xl,
          PBSpace.md,
          PBSpace.xl,
          0,
        ),
        child: Text(
          text,
          style: context.textTheme.bodySmall?.copyWith(
            color: color ?? context.colorScheme.onSurfaceVariant,
          ),
        ),
      );
}
