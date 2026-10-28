import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/features/settings/widgets/settings_group.dart';

/// A settings row that opens a link outside the app.
class InfoItem extends StatelessWidget {
  const InfoItem(
    this.name,
    this.icon,
    this.openInfo, {
    this.color,
    super.key,
  });
  final String name;
  final IconData icon;
  final VoidCallback openInfo;

  /// The icon tile's colour.
  final Color? color;

  @override
  Widget build(BuildContext context) => SettingsRow(
        label: name,
        icon: icon,
        color: color,
        onTap: openInfo,
        trailing: Icon(
          CarbonIcons.launch,
          size: 18,
          color: context.colorScheme.onSurfaceVariant,
        ),
      );
}
