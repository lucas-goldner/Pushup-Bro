import 'dart:math' as math;

import 'package:pushup_bro/features/island/buildings/decor/decor_item.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_piece.dart';
import 'package:pushup_bro/features/island/scene/island_world.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// How far (m) decorations stay inside the grass's edge.
const _edgeMargin = 0.3;

/// How much ground (m) a building takes up around its centre.
const _buildingRadius = 0.85;

/// Room (m) kept around the jungle's trees and its gate.
const _jungleMargin = 0.15;
const _gateRadius = 0.6;

/// Room (m) kept around Carlos's laps, so he never walks through anything.
const _carlosMargin = 0.4;

/// How far apart (m) the spots tried for a new decoration are.
const _searchStep = 0.2;

/// Most decorations standing on the island at once, so the scene stays
/// light on every phone.
const kMaxPlacedDecor = 40;

/// Where a decoration may stand on islands laid out like [plan]: on the
/// grass, clear of the buildings, the jungle and Carlos's laps, and of the
/// other decorations.
class DecorPlacement {
  const DecorPlacement(this.plan);

  final IslandPlan plan;

  /// Whether [item] fits at ([x], [z]) on the island itself, ignoring other
  /// decorations.
  bool onLand(DecorItem item, double x, double z) {
    final at = vm.Vector2(x, z);
    final r = item.radius;
    if (at.length + r > plan.grassEdge(math.atan2(z, x)) - _edgeMargin) {
      return false;
    }
    for (final spot in plan.buildingSpots) {
      if (at.distanceTo(spot) < r + _buildingRadius) return false;
    }
    if (at.distanceTo(plan.jungle) < r + plan.jungleRadius + _jungleMargin) {
      return false;
    }
    if (at.distanceTo(plan.jungleGate) < r + _gateRadius) return false;

    return at.distanceTo(plan.carlosLap) >=
        r + plan.carlosLapRadius + _carlosMargin;
  }

  /// Whether [piece] fits where it is among [pieces], leaving out the
  /// piece at [ignore] (itself, while it's moved).
  bool fits(DecorPiece piece, List<DecorPiece> pieces, {int? ignore}) {
    if (!onLand(piece.item, piece.x, piece.z)) return false;
    for (final (i, other) in pieces.indexed) {
      if (i == ignore || !other.placed) continue;
      final dx = other.x - piece.x;
      final dz = other.z - piece.z;
      final room = other.item.radius + piece.item.radius;
      if (dx * dx + dz * dz < room * room) return false;
    }

    return true;
  }

  /// The free spot for [item] among [pieces] closest to [near] (by default
  /// the island's front, in full view between Carlos and the beach), or
  /// null when the island is full.
  vm.Vector2? freeSpot(
    DecorItem item,
    List<DecorPiece> pieces, {
    vm.Vector2? near,
    int? ignore,
  }) {
    final from = near ?? vm.Vector2(0, plan.radius * 0.62);
    final reach = plan.radius;
    final steps = (reach / _searchStep).ceil();
    final candidates = <vm.Vector2>[
      for (var i = -steps; i <= steps; i++)
        for (var j = -steps; j <= steps; j++)
          vm.Vector2(i * _searchStep, j * _searchStep),
    ]..sort(
        (a, b) =>
            a.distanceToSquared(from).compareTo(b.distanceToSquared(from)),
      );
    for (final spot in candidates) {
      final piece = DecorPiece(item: item, x: spot.x, z: spot.y, placed: true);
      if (fits(piece, pieces, ignore: ignore)) return spot;
    }

    return null;
  }

  /// [pieces] as they can stand on this island: a piece that no longer fits
  /// where it was saved (a new building went up there) moves to the nearest
  /// free spot, or back into the bag when there is none.
  List<DecorPiece> settle(List<DecorPiece> pieces) {
    final settled = <DecorPiece>[];
    var standing = 0;
    for (final piece in pieces) {
      // Laid out one by one, so each only has to clear the ones before it.
      if (!piece.placed) {
        settled.add(piece);
        continue;
      }
      if (standing >= kMaxPlacedDecor) {
        settled.add(piece.copyWith(placed: false));
        continue;
      }
      if (fits(piece, settled)) {
        settled.add(piece);
        standing++;
        continue;
      }
      final spot =
          freeSpot(piece.item, settled, near: vm.Vector2(piece.x, piece.z));
      if (spot == null) {
        settled.add(piece.copyWith(placed: false));
      } else {
        settled.add(piece.copyWith(x: spot.x, z: spot.y));
        standing++;
      }
    }

    return settled;
  }
}
