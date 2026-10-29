import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/social/data/social_backend.dart';

/// "Continue with Apple" (black, as Apple asks) and "Continue with
/// Google" (outlined), one above the other.
class SignInButtons extends StatelessWidget {
  const SignInButtons({required this.onPick, this.busy, super.key});

  final ValueChanged<SignInProvider> onPick;

  /// The provider whose sheet is open, while it is.
  final SignInProvider? busy;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _Button(
            label: context.l10n.upgradeApple,
            icon: Icons.apple,
            fill: Colors.black,
            ink: Colors.white,
            busy: busy == SignInProvider.apple,
            onTap: busy == null ? () => onPick(SignInProvider.apple) : null,
          ),
          const SizedBox(height: PBSpace.md),
          _Button(
            label: context.l10n.upgradeGoogle,
            icon: CarbonIcons.logo_google,
            fill: context.colorScheme.surface,
            ink: context.colorScheme.onSurface,
            outline: context.colorScheme.outlineVariant,
            busy: busy == SignInProvider.google,
            onTap: busy == null ? () => onPick(SignInProvider.google) : null,
          ),
        ],
      );
}

class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.icon,
    required this.fill,
    required this.ink,
    required this.busy,
    required this.onTap,
    this.outline,
  });

  final String label;
  final IconData icon;
  final Color fill;
  final Color ink;
  final Color? outline;
  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(PBRadius.pill),
            border: outline == null ? null : Border.all(color: outline!),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (busy)
                SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: ink),
                )
              else
                Icon(icon, color: ink, size: 22),
              const SizedBox(width: PBSpace.sm),
              Text(
                label,
                style: context.textTheme.titleSmall?.copyWith(
                  color: ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
}
