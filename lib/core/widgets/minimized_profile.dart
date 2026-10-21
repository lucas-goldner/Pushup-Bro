import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/minimized_user.dart';
import 'package:pushup_bro/core/widgets/profile_image_box.dart';

class MinimizedProfile extends StatelessWidget {
  const MinimizedProfile(
    this.user, {
    this.leadingItem,
    super.key,
  });
  final MinimizedUser user;
  final Widget? leadingItem;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.colorScheme.onSecondary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ProfileImageBox(
                user.image,
                size: const Size(48, 48),
                iconSize: 24,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              user.name,
              style: context.textTheme.headlineLarge?.copyWith(
                color: context.colorScheme.onSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            if (leadingItem != null) leadingItem ?? const SizedBox.shrink(),
          ],
        ),
      );
}
