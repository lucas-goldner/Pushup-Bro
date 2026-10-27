import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/minimized_user.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/profile_image_box.dart';

/// A person in a row: rounded avatar, name, an optional muted [subtitle]
/// and a trailing [leadingItem]. Wrap it in a [ProfileCard] to float it.
class MinimizedProfile extends StatelessWidget {
  const MinimizedProfile(
    this.user, {
    this.leadingItem,
    this.subtitle,
    super.key,
  });
  final MinimizedUser user;

  /// Shown at the end of the row.
  final Widget? leadingItem;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(PBSpace.sm),
        child: Row(
          children: [
            ProfileImageBox(
              user.image,
              size: const Size(48, 48),
              iconSize: 24,
            ),
            const SizedBox(width: PBSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user.name,
                    style: context.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: context.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (leadingItem != null) ...[
              const SizedBox(width: PBSpace.sm),
              leadingItem!,
            ],
          ],
        ),
      );
}

/// A white rounded card floating on a soft shadow, for profile rows.
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    required this.child,
    this.highlight,
    super.key,
  });

  final Widget child;

  /// Tints the card, e.g. for the learner's own row.
  final Color? highlight;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(PBSpace.sm),
        decoration: BoxDecoration(
          color: highlight == null
              ? context.colorScheme.surface
              : Color.alphaBlend(
                  context.tint(highlight!),
                  context.colorScheme.surface,
                ),
          borderRadius: BorderRadius.circular(PBRadius.lg),
          boxShadow: context.cardShadow,
        ),
        child: child,
      );
}
