import 'package:flutter/material.dart';
import 'package:pushup_bro/features/settings/widgets/settings_group.dart';

/// A settings row that opens another settings page.
class Settingsitem extends StatelessWidget {
  const Settingsitem(
    this.name,
    this.icon,
    this.navigate, {
    this.color,
    super.key,
  });
  final String name;
  final IconData icon;
  final VoidCallback navigate;

  /// The icon tile's colour.
  final Color? color;

  @override
  Widget build(BuildContext context) => SettingsRow(
        label: name,
        icon: icon,
        color: color,
        onTap: navigate,
      );
}
