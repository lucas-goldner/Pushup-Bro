import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_item.dart';

/// One decoration the player owns: where it stands on the island (metres
/// from the island's centre on the ground) and which way it faces, or put
/// away in their bag when it isn't [placed].
class DecorPiece extends Equatable {
  const DecorPiece({
    required this.item,
    this.x = 0,
    this.z = 0,
    this.turn = 0,
    this.placed = false,
  });

  /// The piece saved in [json], or null for a decoration this version
  /// doesn't know.
  static DecorPiece? fromJson(Object? json) {
    if (json is! Map) return null;
    final item = DecorItem.byId(json['id']);
    if (item == null) return null;

    return DecorPiece(
      item: item,
      x: (json['x'] as num?)?.toDouble() ?? 0,
      z: (json['z'] as num?)?.toDouble() ?? 0,
      turn: ((json['turn'] as num?)?.toInt() ?? 0) % turns,
      placed: json['placed'] as bool? ?? false,
    );
  }

  /// The pieces in [json], skipping anything unreadable.
  static List<DecorPiece> listFromJson(Object? json) => [
        if (json is List)
          for (final each in json)
            if (fromJson(each) case final piece?) piece,
      ];

  /// How many ways a piece can face: steps of 45°.
  static const turns = 8;

  final DecorItem item;
  final double x;
  final double z;

  /// Which way it faces, in eighths of a full turn.
  final int turn;
  final bool placed;

  /// [turn] in radians, around +Y.
  double get angle => turn * math.pi * 2 / turns;

  DecorPiece copyWith({double? x, double? z, int? turn, bool? placed}) =>
      DecorPiece(
        item: item,
        x: x ?? this.x,
        z: z ?? this.z,
        turn: turn == null ? this.turn : turn % turns,
        placed: placed ?? this.placed,
      );

  // Rounded to the centimetre: plenty, and keeps the saves small.
  Map<String, dynamic> toJson() => {
        'id': item.id,
        'x': (x * 100).roundToDouble() / 100,
        'z': (z * 100).roundToDouble() / 100,
        'turn': turn,
        'placed': placed,
      };

  @override
  List<Object?> get props => [item, x, z, turn, placed];
}
