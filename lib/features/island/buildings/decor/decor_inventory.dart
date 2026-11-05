import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_item.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_piece.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_placement.dart';
import 'package:pushup_bro/features/island/scene/island_world.dart';

/// Buying decorations and moving them around the island.
extension DecorInventory on GameInventory {
  /// How the island is laid out with the buildings bought so far.
  DecorPlacement get decorPlacement =>
      DecorPlacement(IslandPlan.of(boughtItems));

  /// How many of [item] the player has, standing or in the bag.
  int ownedDecor(DecorItem item) => decor.where((p) => p.item == item).length;

  /// Whether another decoration can stand on the island.
  bool get roomForDecor =>
      decor.where((piece) => piece.placed).length < kMaxPlacedDecor;

  /// Pays for [item] and stands it in a free spot near the island's front,
  /// or puts it in the bag when the island is full. Returns null when the
  /// bananas don't stretch that far.
  GameInventory? buyDecor(DecorItem item) {
    if (bananas < item.price) return null;
    final pieces = decorPlacement.settle(decor);
    final spot = roomForDecor ? decorPlacement.freeSpot(item, pieces) : null;
    final piece = spot == null
        ? DecorPiece(item: item)
        : DecorPiece(item: item, x: spot.x, z: spot.y, placed: true);

    return copyWith(bananas: bananas - item.price, decor: [...pieces, piece]);
  }

  /// Takes the piece at [index] out of the bag onto a free spot; unchanged
  /// when the island is full.
  GameInventory placeDecor(int index) {
    final pieces = decorPlacement.settle(decor);
    final piece = pieces[index];
    if (piece.placed || !roomForDecor) return this;
    final spot = decorPlacement.freeSpot(piece.item, pieces, ignore: index);
    if (spot == null) return this;

    return copyWith(
      decor: [...pieces]..[index] =
          piece.copyWith(x: spot.x, z: spot.y, placed: true),
    );
  }

  /// Moves the piece at [index] to ([x], [z]) when it fits there.
  GameInventory moveDecor(int index, double x, double z) {
    final moved = decor[index].copyWith(x: x, z: z, placed: true);
    if (!decorPlacement.fits(moved, decor, ignore: index)) return this;

    return _replace(index, moved);
  }

  /// Turns the piece at [index] by [steps] eighths of a turn.
  GameInventory turnDecor(int index, int steps) =>
      _replace(index, decor[index].copyWith(turn: decor[index].turn + steps));

  /// Puts the piece at [index] back in the bag.
  GameInventory putAwayDecor(int index) =>
      _replace(index, decor[index].copyWith(placed: false));

  GameInventory _replace(int index, DecorPiece piece) =>
      copyWith(decor: [...decor]..[index] = piece);
}
