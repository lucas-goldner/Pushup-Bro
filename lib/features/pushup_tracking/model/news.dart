import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/active_effects.dart';

enum NewsType { update, friendBoost, doublePoinstEvent }

extension NewsTypeExtension on NewsType {
  Color getColor(BuildContext context) => switch (this) {
        NewsType.update => context.colorScheme.primary,
        NewsType.friendBoost => context.itemColorsTheme.friendBoost,
        NewsType.doublePoinstEvent => context.itemColorsTheme.doubleBoost,
      };

  ActiveEffects? get correspondingEffect => switch (this) {
        NewsType.friendBoost => ActiveEffects.itemFriendSharedBoostReceived,
        NewsType.doublePoinstEvent => ActiveEffects.eventDoublePoints,
        _ => null,
      };
}

class News {
  News({
    required this.title,
    required this.description,
    required this.type,
    required this.date,
  });

  final String title;
  final String description;
  final NewsType type;
  final DateTime date;
  bool get isActive => date.isAfter(DateTime.now());
  Color getColor(BuildContext context) => type.getColor(context);
}
