import 'dart:math' as math;

import 'package:pushup_bro/core/model/trek_progress.dart';
import 'package:pushup_bro/features/trek/model/trek.dart';

/// Pushups held at the bottom at least this long are held pushups.
const holdSeconds = 2.0;

/// How often a chameleon changes colour, in seconds.
const _shiftEvery = 8.0;

/// Each pushup pushes every enemy's next attack back by this much.
const _repPushback = 0.8;

/// An enemy in battle.
class Foe {
  Foe(this.spec, this.slot)
      : hp = spec.hp,
        color = spec.color ?? ScaleColor.values[slot % 3],
        attackTimer = spec.attackEvery * (0.7 + slot * 0.25),
        _shiftTimer = _shiftEvery - slot * 2.5;

  final EnemySpec spec;

  /// Its place in the wave, left to right.
  final int slot;
  double hp;
  ScaleColor color;

  /// Seconds until it attacks.
  double attackTimer;
  double _shiftTimer;

  bool get alive => hp > 0;
  bool get shifts => spec.color == null;
}

/// One pushup landing on a [foe].
class Hit {
  const Hit({
    required this.foe,
    required this.kind,
    required this.damage,
    required this.effectiveness,
    required this.critical,
    required this.defeated,
    required this.combo,
    this.phase,
  });

  final Foe foe;
  final RepKind kind;
  final double damage;
  final double effectiveness;
  final bool critical;
  final bool defeated;

  /// Quick pushups in a row so far.
  final int combo;

  /// The boss's new phase, when this hit pushed him into one.
  final int? phase;

  bool get superEffective => effectiveness > 1;
  bool get weak => effectiveness < 1;
}

/// What happened during [Battle.tick].
class TickEvents {
  final List<Foe> strikes = [];
  final List<Foe> colorShifts = [];
}

/// A Jungle Trek battle: the waves of a [stage], fought with Carlos's
/// [stats].
///
/// Each pushup becomes a [Hit] on the first enemy still standing, its
/// damage scaled by how well the kind of pushup suits the enemy's colour.
/// Enemies attack on their own timers, which every pushup pushes back.
class Battle {
  Battle(this.stage, this.stats, {math.Random? random})
      : _random = random ?? math.Random(),
        maxHp = stats.maxHp,
        hp = stats.maxHp {
    _startWave();
  }

  final TrekStage stage;
  final TrekProgress stats;
  final math.Random _random;
  final double maxHp;

  double hp;
  int wave = 0;
  List<Foe> foes = [];
  int combo = 0;
  int reps = 0;
  int superEffective = 0;
  int xp = 0;
  int bossPhase = 0;

  List<EnemySpec> get _wave => stage.waves[wave];

  bool get lastWave => wave == stage.waves.length - 1;
  bool get waveCleared => foes.every((foe) => !foe.alive);
  bool get won => lastWave && waveCleared;
  bool get lost => hp <= 0;

  Foe? get target {
    for (final foe in foes) {
      if (foe.alive) return foe;
    }

    return null;
  }

  void _startWave() {
    foes = [for (final (i, spec) in _wave.indexed) Foe(spec, i)];
    combo = 0;
  }

  void nextWave() {
    if (lastWave) return;
    wave++;
    _startWave();
  }

  /// Heals some between waves.
  void rest() => hp = math.min(maxHp, hp + maxHp * 0.35);

  RepKind classify({required double held, double? sinceLast}) {
    if (held >= holdSeconds) return RepKind.held;
    if (sinceLast != null && sinceLast <= stats.quickWindow) {
      return RepKind.quick;
    }

    return RepKind.normal;
  }

  /// A pushup, held [held] seconds at the bottom, [sinceLast] seconds after
  /// the previous one (null for the first). Null when nobody is left to hit.
  Hit? rep({required double held, double? sinceLast}) {
    final foe = target;
    if (foe == null) return null;
    final kind = classify(held: held, sinceLast: sinceLast);
    combo = kind == RepKind.quick ? combo + 1 : 0;
    reps++;

    var multiplier = effectiveness(foe.color, kind);
    if (kind == RepKind.held) multiplier *= 1 + stats.gripBonus;
    if (kind == RepKind.quick) {
      multiplier *= 1 + stats.quickBonus;
      if (foe.color == ScaleColor.yellow) {
        multiplier += math.min(1, combo * 0.25);
      }
    }
    final critical = _random.nextDouble() < 0.1;
    final damage = stats.attack * multiplier * (critical ? 1.5 : 1);
    if (multiplier > 1) superEffective++;
    foe.hp = math.max(0, foe.hp - damage);
    for (final other in foes) {
      other.attackTimer = math.min(
        other.spec.attackEvery,
        other.attackTimer + _repPushback,
      );
    }

    int? phase;
    if (foe.spec.species == Species.king && foe.alive) {
      final next = foe.hp > foe.spec.hp * 2 / 3
          ? 0
          : foe.hp > foe.spec.hp / 3
              ? 1
              : 2;
      if (next != bossPhase) {
        bossPhase = next;
        foe.color = ScaleColor.values[next];
        phase = next;
      }
    }
    if (!foe.alive) xp += foe.spec.xp;

    return Hit(
      foe: foe,
      kind: kind,
      damage: damage,
      effectiveness: multiplier,
      critical: critical,
      defeated: !foe.alive,
      combo: combo,
      phase: phase,
    );
  }

  /// Advances the enemies' timers by [deltaSeconds]: attacks and colour
  /// changes.
  TickEvents tick(double deltaSeconds) {
    final events = TickEvents();
    for (final foe in foes) {
      if (!foe.alive) continue;
      foe.attackTimer -= deltaSeconds;
      if (foe.attackTimer <= 0) {
        foe.attackTimer += foe.spec.attackEvery;
        hp = math.max(0, hp - foe.spec.attack);
        events.strikes.add(foe);
      }
      if (foe.shifts) {
        foe._shiftTimer -= deltaSeconds;
        if (foe._shiftTimer <= 0) {
          foe._shiftTimer += _shiftEvery;
          foe.color = ScaleColor
              .values[(foe.color.index + 1) % ScaleColor.values.length];
          events.colorShifts.add(foe);
        }
      }
    }

    return events;
  }

  /// Stars for a won battle: one for winning, one for ending with at least
  /// half health, one for mostly super effective pushups.
  int get stars =>
      1 +
      (hp >= maxHp / 2 ? 1 : 0) +
      (reps > 0 && superEffective / reps >= 0.6 ? 1 : 0);

  /// Bonus XP for clearing the stage.
  int get clearXp => 30 + 10 * stage.number;
}
