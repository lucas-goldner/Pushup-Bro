import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:pushup_bro/model/pushup.dart';

part 'pushup_set.g.dart';

@collection
class PushupSet {
  PushupSet(this.pushups, this.effort);
  final Id id = Isar.autoIncrement;
  final List<Pushup> pushups;
  final int effort;

  DateTime get startedDate => pushups.first.completedAt ?? DateTime(2000);
  DateTime get completedDate => pushups.last.completedAt ?? DateTime(2000);
  int get timeSpent {
    final difference = completedDate.difference(startedDate).inMinutes;
    return difference == 0 ? 1 : difference;
  }

  String translateEffort(BuildContext context) {
    switch (effort) {
      case 0:
        return S.of(context).noEffort;
      case 1:
        return S.of(context).superEasyEffort;
      case 2:
        return S.of(context).easyEffort;
      case 3:
        return S.of(context).mediumEffort;
      case 4:
        return S.of(context).hardEffort;
      case 5:
        return S.of(context).superHardEffort;
    }

    return S.of(context).noEffort;
  }

  PushupSet copyWith({
    List<Pushup>? pushups,
    int? effort,
  }) {
    return PushupSet(
      pushups ?? this.pushups,
      effort ?? this.effort,
    );
  }
}
