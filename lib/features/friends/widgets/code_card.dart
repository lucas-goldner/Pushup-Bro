import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/friends/add_bro_page.dart';
import 'package:pushup_bro/features/island/share/island_share_page.dart';
import 'package:pushup_bro/features/social/data/qr_scanner.dart';
import 'package:pushup_bro/features/social/domain/friend_code.dart';
import 'package:pushup_bro/features/social/model/bro_profile.dart';
import 'package:pushup_bro/features/social/widgets/bro_avatar.dart';
import 'package:pushup_bro/features/social/widgets/qr_view.dart';

/// The player's friend code on a blue card, with a mini QR, Share my
/// island and Scan a code.
class CodeCard extends StatelessWidget {
  const CodeCard({required this.me, super.key});

  final BroProfile me;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final blue = context.colorScheme.secondary;
    final ink = context.gameColors.onGame;

    return Container(
      padding: const EdgeInsets.all(PBSpace.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color.lerp(blue, Colors.white, 0.18)!, blue],
        ),
        borderRadius: BorderRadius.circular(PBRadius.lg),
        boxShadow: context.glow(blue),
      ),
      child: Column(
        children: [
          Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: ink, width: 3),
                ),
                child: BroAvatar(look: me.look, size: 54),
              ),
              const SizedBox(width: PBSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l.brosYourCode,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: ink.withValues(alpha: 0.8),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        FriendCode.format(me.code),
                        style: context.textTheme.headlineMedium?.copyWith(
                          color: ink,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: QrView(
                  data: FriendCode.link(me.code),
                  size: 48,
                  dark: const Color(0xFF17203A),
                  accent: const Color(0xFF17203A),
                ),
              ),
            ],
          ),
          const SizedBox(height: PBSpace.lg),
          Row(
            children: [
              Expanded(
                child: _CardButton(
                  label: l.brosShareIsland,
                  solid: true,
                  onTap: () => openIslandShare(context),
                ),
              ),
              const SizedBox(width: PBSpace.md),
              Expanded(
                child: _CardButton(
                  label: l.brosScanCode,
                  onTap: () => unawaited(scanFriendCode(context)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Scans a friend's QR and opens the add screen with the code filled in.
Future<void> scanFriendCode(BuildContext context) async {
  final l = context.l10n;
  if (!QrScanner.available) {
    await openAddBro(context);
    return;
  }
  final scanned =
      await QrScanner.scan(title: l.addScanQr, cancel: l.brosCancel);
  if (scanned == null || !context.mounted) return;
  await openAddBro(context, code: FriendCode.normalize(scanned));
}

class _CardButton extends StatelessWidget {
  const _CardButton({
    required this.label,
    required this.onTap,
    this.solid = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final ink = context.gameColors.onGame;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: solid ? ink : ink.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(PBRadius.pill),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: solid ? const Color(0xFF17203A) : ink,
          ),
        ),
      ),
    );
  }
}
