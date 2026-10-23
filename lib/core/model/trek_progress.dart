import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// Carlos's Jungle Trek progress: his level and the stat points he spent,
/// and the stages he cleared.
class TrekProgress extends Equatable {
  const TrekProgress({
    this.level = 1,
    this.xp = 0,
    this.points = 0,
    this.power = 0,
    this.vitality = 0,
    this.grip = 0,
    this.agility = 0,
    this.stars = const {},
  });

  factory TrekProgress.fromJson(Map<String, dynamic> json) {
    int read(String key) => (json[key] as num?)?.toInt() ?? 0;

    return TrekProgress(
      level: math.max(1, read('level')),
      xp: read('xp'),
      points: read('points'),
      power: read('power'),
      vitality: read('vitality'),
      grip: read('grip'),
      agility: read('agility'),
      stars: {
        for (final MapEntry(:key, :value)
            in (json['stars'] as Map<String, dynamic>? ?? {}).entries)
          if (value is num) key: value.toInt(),
      },
    );
  }

  final int level;

  /// XP towards the next level.
  final int xp;

  /// Stat points not spent yet.
  final int points;
  final int power;
  final int vitality;
  final int grip;
  final int agility;

  /// Best stars (1 to 3) per cleared stage id.
  final Map<String, int> stars;

  /// XP needed to go from [level] to the next.
  static int xpToNext(int level) => 40 + 30 * level;

  int get nextLevelXp => xpToNext(level);

  /// Damage of an ordinary hit.
  double get attack => 10 + 3.0 * power + (level - 1);

  double get maxHp => 100 + 15.0 * vitality + 5 * (level - 1);

  /// Extra damage for held pushups.
  double get gripBonus => 0.15 * grip;

  /// How soon after the last pushup a quick one must follow, in seconds.
  double get quickWindow => 1.6 + 0.15 * agility;

  /// Extra damage for quick pushups.
  double get quickBonus => 0.1 * agility;

  bool cleared(String stageId) => stars.containsKey(stageId);

  /// With [amount] more XP, and the levels (and stat points) that brings.
  (TrekProgress, int levelsGained) gainXp(int amount) {
    var level = this.level;
    var xp = this.xp + amount;
    var gained = 0;
    while (xp >= xpToNext(level)) {
      xp -= xpToNext(level);
      level++;
      gained++;
    }

    return (
      copyWith(level: level, xp: xp, points: points + gained),
      gained,
    );
  }

  /// With one point spent on [stat] (`power`, `vitality`, `grip` or
  /// `agility`).
  TrekProgress spend(String stat) {
    if (points <= 0) return this;

    return copyWith(
      points: points - 1,
      power: power + (stat == 'power' ? 1 : 0),
      vitality: vitality + (stat == 'vitality' ? 1 : 0),
      grip: grip + (stat == 'grip' ? 1 : 0),
      agility: agility + (stat == 'agility' ? 1 : 0),
    );
  }

  /// With [stageId] cleared for [earned] stars, keeping the best.
  TrekProgress clear(String stageId, int earned) => copyWith(
        stars: {
          ...stars,
          stageId: math.max(earned, stars[stageId] ?? 0),
        },
      );

  TrekProgress copyWith({
    int? level,
    int? xp,
    int? points,
    int? power,
    int? vitality,
    int? grip,
    int? agility,
    Map<String, int>? stars,
  }) =>
      TrekProgress(
        level: level ?? this.level,
        xp: xp ?? this.xp,
        points: points ?? this.points,
        power: power ?? this.power,
        vitality: vitality ?? this.vitality,
        grip: grip ?? this.grip,
        agility: agility ?? this.agility,
        stars: stars ?? this.stars,
      );

  Map<String, dynamic> toJson() => {
        'level': level,
        'xp': xp,
        'points': points,
        'power': power,
        'vitality': vitality,
        'grip': grip,
        'agility': agility,
        'stars': stars,
      };

  @override
  List<Object?> get props =>
      [level, xp, points, power, vitality, grip, agility, stars];
}
