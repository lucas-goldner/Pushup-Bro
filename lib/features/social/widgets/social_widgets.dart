import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/cubit/account_state.dart';
import 'package:pushup_bro/features/social/domain/bro_name.dart';
import 'package:pushup_bro/features/social/model/bro_profile.dart';

/// A bro's generated name in the reader's language.
String broNameOf(BuildContext context, BroName name) =>
    name.display(Localizations.localeOf(context).languageCode);

/// What friends call [profile]: their name for friends, or the bro name.
String friendLabel(BuildContext context, BroProfile profile, String name) =>
    name.isNotEmpty ? name : broNameOf(context, profile.broName);

/// The player's look, from the account (or the default gorilla).
MonkeyLook myLook(BuildContext context) =>
    context.read<AccountCubit>().state.profile?.look ?? const MonkeyLook();

/// A white rounded card on a soft shadow, like the app's other cards.
class SocialCard extends StatelessWidget {
  const SocialCard({
    required this.child,
    this.padding = const EdgeInsets.all(PBSpace.lg),
    this.onTap,
    this.onLongPress,
    this.outline,
    this.color,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// A coloured outline, like the player's own row.
  final Color? outline;
  final Color? color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: color ?? context.colorScheme.surface,
          borderRadius: BorderRadius.circular(PBRadius.lg),
          border:
              outline == null ? null : Border.all(color: outline!, width: 2),
          boxShadow: context.cardShadow,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: BorderRadius.circular(PBRadius.lg),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            child: Padding(padding: padding, child: child),
          ),
        ),
      );
}

/// Two tabs side by side in a soft track.
class SocialTabs extends StatelessWidget {
  const SocialTabs({
    required this.labels,
    required this.selected,
    required this.onSelect,
    super.key,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) => Container(
        height: 44,
        padding: const EdgeInsets.all(PBSpace.xs),
        decoration: BoxDecoration(
          color: context.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(PBRadius.sm),
        ),
        child: Row(
          children: [
            for (final (i, label) in labels.indexed)
              Expanded(
                child: GestureDetector(
                  onTap: () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == selected
                          ? context.colorScheme.surface
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(PBRadius.sm - 3),
                      boxShadow: i == selected ? context.cardShadow : null,
                    ),
                    child: Text(
                      label,
                      style: context.textTheme.labelLarge?.copyWith(
                        fontWeight:
                            i == selected ? FontWeight.w800 : FontWeight.w600,
                        color: i == selected
                            ? context.colorScheme.onSurface
                            : context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
}

/// A small rounded chip: an emoji and a label.
class SocialChip extends StatelessWidget {
  const SocialChip(this.label, {this.emoji, this.color, super.key});

  final String label;
  final String? emoji;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color ?? context.colorScheme.surface,
          borderRadius: BorderRadius.circular(PBRadius.pill),
          boxShadow: color == null ? context.cardShadow : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(emoji!, style: const TextStyle(fontSize: 13)),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
}

/// Shows [builder] once the account is ready; a spinner while it signs
/// in, and a retry when it can't reach the server.
class SocialGate extends StatelessWidget {
  const SocialGate({required this.builder, super.key});

  final Widget Function(BuildContext context, BroProfile me) builder;

  @override
  Widget build(BuildContext context) => BlocBuilder<AccountCubit, AccountState>(
        buildWhen: (previous, current) =>
            previous.status != current.status || previous.uid != current.uid,
        builder: (context, state) => switch ((state.status, state.profile)) {
          (AccountStatus.ready, final BroProfile me) => builder(context, me),
          (AccountStatus.offline, _) => const _Offline(),
          _ => const Center(child: CircularProgressIndicator()),
        },
      );
}

class _Offline extends StatelessWidget {
  const _Offline();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(PBSpace.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CarbonIcons.wifi_off,
                size: 48,
                color: context.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: PBSpace.lg),
              Text(
                context.l10n.socialOffline,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyLarge,
              ),
              const SizedBox(height: PBSpace.lg),
              TextButton(
                onPressed: () => context.read<AccountCubit>().start(
                      look: myLook(context),
                    ),
                child: Text(context.l10n.socialRetry),
              ),
            ],
          ),
        ),
      );
}
