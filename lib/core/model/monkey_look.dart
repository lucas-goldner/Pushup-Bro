import 'dart:ui' show Color;

import 'package:equatable/equatable.dart';
import 'package:pushup_bro/core/model/cosmetics.dart';

/// How a monkey looks: a cosmetic id for every [CosmeticSlot].
class MonkeyLook extends Equatable {
  const MonkeyLook({
    this.fur = 'fur.charcoal',
    this.face = 'face.lilac',
    this.hat = 'hat.none',
    this.eyewear = 'eyes.none',
    this.outfit = 'outfit.none',
    this.matColor = 'mat.blue',
    this.matPattern = 'pattern.solid',
    this.species = gorilla,
  });

  factory MonkeyLook.fromJson(Map<String, dynamic> json) {
    const fallback = MonkeyLook();
    String pick(String key, String orElse) {
      final id = json[key];
      return id is String && Cosmetic.byId(id) != null ? id : orElse;
    }

    return MonkeyLook(
      fur: pick('fur', fallback.fur),
      face: pick('face', fallback.face),
      hat: pick('hat', fallback.hat),
      eyewear: pick('eyewear', fallback.eyewear),
      outfit: pick('outfit', fallback.outfit),
      matColor: pick('matColor', fallback.matColor),
      matPattern: pick('matPattern', fallback.matPattern),
      species: json['species'] == lizard ? lizard : gorilla,
    );
  }

  static const gorilla = 'gorilla';
  static const lizard = 'lizard';

  /// King Komo's royal look, once he joins the island.
  static const kingKomo = MonkeyLook(
    fur: 'fur.jade',
    face: 'face.sand',
    hat: 'hat.lizardcrown',
    outfit: 'outfit.cape',
    matColor: 'mat.lime',
    matPattern: 'pattern.scales',
    species: lizard,
  );

  /// The cosmetics every monkey starts with.
  static final List<String> defaults = const MonkeyLook().ids;

  final String fur;
  final String face;
  final String hat;
  final String eyewear;
  final String outfit;
  final String matColor;
  final String matPattern;

  /// [gorilla] or [lizard]: whose body wears the look.
  final String species;

  List<String> get ids =>
      [fur, face, hat, eyewear, outfit, matColor, matPattern];

  String idFor(CosmeticSlot slot) => switch (slot) {
        CosmeticSlot.fur => fur,
        CosmeticSlot.face => face,
        CosmeticSlot.hat => hat,
        CosmeticSlot.eyewear => eyewear,
        CosmeticSlot.outfit => outfit,
        CosmeticSlot.matColor => matColor,
        CosmeticSlot.matPattern => matPattern,
      };

  /// This look wearing [cosmetic] in its slot.
  MonkeyLook wearing(Cosmetic cosmetic) => MonkeyLook(
        fur: cosmetic.slot == CosmeticSlot.fur ? cosmetic.id : fur,
        face: cosmetic.slot == CosmeticSlot.face ? cosmetic.id : face,
        hat: cosmetic.slot == CosmeticSlot.hat ? cosmetic.id : hat,
        eyewear: cosmetic.slot == CosmeticSlot.eyewear ? cosmetic.id : eyewear,
        outfit: cosmetic.slot == CosmeticSlot.outfit ? cosmetic.id : outfit,
        matColor:
            cosmetic.slot == CosmeticSlot.matColor ? cosmetic.id : matColor,
        matPattern:
            cosmetic.slot == CosmeticSlot.matPattern ? cosmetic.id : matPattern,
        species: species,
      );

  Color get furColor => Cosmetic.byId(fur)!.color!;
  Color get faceColor => Cosmetic.byId(face)!.color!;
  Color get matBaseColor => Cosmetic.byId(matColor)!.color!;

  Map<String, dynamic> toJson() => {
        'fur': fur,
        'face': face,
        'hat': hat,
        'eyewear': eyewear,
        'outfit': outfit,
        'matColor': matColor,
        'matPattern': matPattern,
        'species': species,
      };

  @override
  List<Object?> get props => [...ids, species];
}
