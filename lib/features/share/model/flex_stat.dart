import 'package:flutter/foundation.dart';

/// One achievement on a share video's flex wall.
enum FlexKind {
  moreThanLast,
  kcal,
  inARow,
  streak,
  total,
  bananas,
  pushups,
  stars,
  damage,
  combo,
}

@immutable
class FlexStat {
  const FlexStat(this.kind, this.value, {this.best = false});

  final FlexKind kind;
  final int value;

  /// A new personal best.
  final bool best;

  @override
  bool operator ==(Object other) =>
      other is FlexStat &&
      other.kind == kind &&
      other.value == value &&
      other.best == best;

  @override
  int get hashCode => Object.hash(kind, value, best);

  @override
  String toString() => 'FlexStat($kind, $value${best ? ', best' : ''})';
}

/// The stats to flex, at most [count]: always good news. [gains] come
/// first in their order (more than last time, new bests, calories), then
/// [fillers] (totals that only ever grow) until the wall is full. Anything
/// not above zero is dropped, so a drop is never shown.
List<FlexStat> pickFlexStats({
  required List<FlexStat?> gains,
  required List<FlexStat?> fillers,
  int count = 4,
}) {
  final picked = <FlexStat>[];
  final kinds = <FlexKind>{};
  for (final stat in [...gains, ...fillers]) {
    if (picked.length == count) break;
    if (stat == null || stat.value <= 0 || kinds.contains(stat.kind)) continue;
    picked.add(stat);
    kinds.add(stat.kind);
  }
  return picked;
}
