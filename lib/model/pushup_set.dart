import 'package:flutter/material.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:pushup_bro/model/pushup.dart';

class PushupSet {
  PushupSet(this.pushups, this.effort, {int? id})
      : id = id ?? DateTime.now().microsecondsSinceEpoch;

  factory PushupSet.fromJson(Map<String, dynamic> json) => PushupSet(
        (json['pushups'] as List<dynamic>)
            .map((e) => Pushup.fromJson(e as Map<String, dynamic>))
            .toList(),
        json['effort'] as int,
        id: json['id'] as int,
      );

  final int id;
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
      id: id,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pushups': pushups.map((p) => p.toJson()).toList(),
        'effort': effort,
      };
}
