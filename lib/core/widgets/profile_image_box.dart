import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';

/// A rounded avatar: the profile photo, or a person on a soft fill.
class ProfileImageBox extends StatelessWidget {
  const ProfileImageBox(
    this.profileImage, {
    Size? size,
    double? iconSize,
    super.key,
  })  : _size = size ?? const Size(100, 100),
        _iconSize = iconSize ?? 48;

  final String profileImage;
  final Size _size;
  final double _iconSize;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(_size.shortestSide * 0.32),
        child: Container(
          height: _size.height,
          width: _size.width,
          alignment: Alignment.center,
          color: context.colorScheme.surfaceContainerHigh,
          child: profileImage.isNotEmpty
              ? Image.network(
                  profileImage,
                  height: _size.height,
                  width: _size.width,
                  fit: BoxFit.cover,
                )
              : Icon(
                  CarbonIcons.user,
                  size: _iconSize,
                  color: context.colorScheme.onSurfaceVariant,
                ),
        ),
      );
}
