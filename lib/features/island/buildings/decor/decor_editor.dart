import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_piece.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_placement.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// Asks the island to open its edit mode, with the piece at the index
/// selected (or none for null): sent by the accessory shop, which sits on
/// top of the island and can't reach it otherwise.
final StreamController<int?> decorEditRequests =
    StreamController<int?>.broadcast();

/// Moving decorations around the island: a working copy of the pieces that
/// the island shows while editing, saved by whoever started it once done.
class DecorEditor extends ChangeNotifier {
  List<DecorPiece> _pieces = const [];
  DecorPlacement? _placement;
  int? _selected;
  bool _blocked = false;

  /// Where the piece being dragged last stood clear of everything.
  vm.Vector2? _lastFree;

  bool get active => _placement != null;
  List<DecorPiece> get pieces => _pieces;
  int? get selected => _selected;

  /// Whether the selected piece is being dragged over something it can't
  /// stand on; let go there and it jumps back.
  bool get blocked => _blocked;

  /// The pieces in the bag, by their index in [pieces].
  List<int> get bag => [
        for (final (i, piece) in _pieces.indexed)
          if (!piece.placed) i,
      ];

  /// Starts editing [pieces] (already settled on the island) laid out by
  /// [placement], with the piece at [select] picked.
  void start(
    List<DecorPiece> pieces,
    DecorPlacement placement, {
    int? select,
  }) {
    _pieces = [...pieces];
    _placement = placement;
    _selected =
        select != null && select < pieces.length && pieces[select].placed
            ? select
            : null;
    _blocked = false;
    notifyListeners();
  }

  /// Ends editing; the caller saves [pieces] first.
  void stop() {
    _placement = null;
    _selected = null;
    _blocked = false;
    notifyListeners();
  }

  void select(int? index) {
    if (index == _selected) return;
    _selected = index;
    _blocked = false;
    notifyListeners();
  }

  /// Drags the selected piece to ([x], [z]) on the ground. It follows the
  /// finger anywhere on the island, marked [blocked] over things it can't
  /// stand on.
  void dragTo(double x, double z) {
    final index = _selected;
    final placement = _placement;
    if (index == null || placement == null) return;
    final current = _pieces[index];
    _lastFree ??= vm.Vector2(current.x, current.z);
    // Never past the beach, so it can't be lost in the sea.
    final at = vm.Vector2(x, z);
    final edge = placement.plan.radius * 1.05;
    if (at.length > edge) at.scale(edge / at.length);
    final moved = current.copyWith(x: at.x, z: at.y);
    _pieces = [..._pieces]..[index] = moved;
    _blocked = !placement.fits(moved, _pieces, ignore: index);
    if (!_blocked) _lastFree = at;
    notifyListeners();
  }

  /// Lets go of the dragged piece: where it is when that's free, else back
  /// where it last stood clear.
  void endDrag() {
    final index = _selected;
    final lastFree = _lastFree;
    _lastFree = null;
    if (index == null) return;
    if (_blocked && lastFree != null) {
      _pieces = [..._pieces]..[index] =
          _pieces[index].copyWith(x: lastFree.x, z: lastFree.y);
    }
    _blocked = false;
    notifyListeners();
  }

  /// Turns the selected piece by [steps] eighths of a turn.
  void turn(int steps) {
    final index = _selected;
    if (index == null) return;
    _pieces = [..._pieces]..[index] =
        _pieces[index].copyWith(turn: _pieces[index].turn + steps);
    notifyListeners();
  }

  /// Puts the selected piece back in the bag.
  void putAway() {
    final index = _selected;
    if (index == null) return;
    _pieces = [..._pieces]..[index] = _pieces[index].copyWith(placed: false);
    _selected = null;
    _blocked = false;
    notifyListeners();
  }

  /// Takes the piece at [index] out of the bag to a free spot and picks
  /// it. Returns false when the island is full.
  bool place(int index) {
    final placement = _placement;
    if (placement == null) return false;
    final standing = _pieces.where((piece) => piece.placed).length;
    if (standing >= kMaxPlacedDecor) return false;
    final spot =
        placement.freeSpot(_pieces[index].item, _pieces, ignore: index);
    if (spot == null) return false;
    _pieces = [..._pieces]..[index] =
        _pieces[index].copyWith(x: spot.x, z: spot.y, placed: true);
    _selected = index;
    _blocked = false;
    notifyListeners();
    return true;
  }
}
