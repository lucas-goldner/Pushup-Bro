import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';

enum ActiveEffects {
  itemDoublePoints(2),
  itemTriplePoints(3),
  itemFriendSharedBoostReceived(2),
  eventDoublePoints(2),
  eventTriplePoints(3);

  const ActiveEffects(this.factor);

  final int factor;
}

extension ActiveEffectsExtension on ActiveEffects {
  String getLocalizedName(BuildContext context) => switch (this) {
        ActiveEffects.itemDoublePoints => context.l10n.doublePoints,
        ActiveEffects.itemTriplePoints => context.l10n.triplePoints,
        ActiveEffects.itemFriendSharedBoostReceived => context.l10n.friendBoost,
        ActiveEffects.eventDoublePoints => context.l10n.doublePoints,
        ActiveEffects.eventTriplePoints => context.l10n.eventTriplePoints
      };

  String getLocalizedWithFactor(BuildContext context) =>
      '$factor x ${getLocalizedName(context)}';
}
