import 'dart:math' as math;

import 'package:pushup_bro/core/model/trek_progress.dart';
import 'package:pushup_bro/features/trek/model/boon.dart';
import 'package:pushup_bro/features/trek/model/trek.dart';

/// Pushups held at the bottom at least this long are held pushups.
const holdSeconds = 2.0;

/// How often a chameleon changes colour, in seconds.
const _shiftEvery = 8.0;

/// After it hits back, an enemy waits at least this long before it
/// attacks again on its timer.
const _afterCounter = 1.5;

/// A blocked enemy reels this long: no attacks, and it takes more damage.
const staggerSeconds = 2.5;

/// A diver stays under this long, and comes back up this often.
const _diveFor = 5.0;
const _diveEvery = 11.0;

/// A vanisher stays hidden at most this long, and vanishes this often.
const _hideFor = 7.0;
const _hideEvery = 13.0;

/// The quick combo that shows a vanisher again.
const revealCombo = 4;

/// A healer patches up the rest of its wave this often, by this much of
/// their health.
const _healEvery = 7.0;
const _healShare = 0.1;

/// An enemy in battle, made tougher or softer by the [difficulty] (and,
/// in the tower, by how high its floor is).
class Foe {
  Foe(
    this.spec,
    this.slot, {
    this.difficulty = TrekDifficulty.normal,
    double scale = 1,
  })  : maxHp = spec.hp * difficulty.health * scale,
        hp = spec.hp * difficulty.health * scale,
        attack = spec.attack * difficulty.damage * math.sqrt(scale),
        attackEvery = spec.attackEvery * difficulty.pace,
        color = spec.color ?? ScaleColor.values[slot % 3],
        attackTimer = spec.attackEvery * difficulty.pace * (0.7 + slot * 0.25),
        shield = spec.shield,
        _shiftTimer = _shiftEvery - slot * 2.5,
        _traitTimer = switch (spec.trait) {
          Trait.diver => _diveEvery * 0.5,
          Trait.vanisher => _hideEvery * 0.5,
          Trait.healer => _healEvery,
          _ => 0,
        };

  final EnemySpec spec;
  final TrekDifficulty difficulty;

  /// Its place in the wave, left to right.
  final int slot;
  final double maxHp;
  double hp;

  /// Damage of each of its attacks.
  final double attack;

  /// Seconds between its attacks on its own timer.
  final double attackEvery;
  ScaleColor color;

  /// Seconds until it attacks.
  double attackTimer;
  double _shiftTimer;

  /// Shield plates left.
  int shield;

  /// Seconds left of winding up a heavy attack; null when it isn't.
  double? charging;

  /// Seconds left reeling from a blocked heavy attack.
  double stagger = 0;

  /// Under the water (a diver) or out of sight (a vanisher).
  bool submerged = false;
  bool hidden = false;
  double _traitTimer;

  /// Pushups it has taken since it last hit back.
  int _hitsTaken = 0;

  bool get alive => hp > 0;
  bool get shifts => spec.color == null;
  Trait get trait => spec.trait;
}

/// How a hit was changed by the enemy's trait or state.
enum HitNote {
  none,

  /// It's under water and only quick pushups reach it.
  splash,

  /// It's invisible: the hit barely lands.
  unseen,

  /// Its shield took most of it.
  shielded,

  /// That held pushup broke its last plate.
  shieldBroken,

  /// The King copied the pushup: the same kind twice in a row.
  mirrored,

  /// It's reeling from a block and takes extra.
  staggered,
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
    this.note = HitNote.none,
    this.chained,
    this.chainDamage = 0,
    this.revealed = false,
    this.last = false,
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
  final HitNote note;

  /// Another enemy the Chain Lightning boon also hit, and how hard.
  final Foe? chained;
  final double chainDamage;

  /// This combo showed a vanished enemy again.
  final bool revealed;

  /// The blow that won the whole battle, for the slow-motion finish.
  final bool last;

  bool get superEffective => effectiveness > 1;
  bool get weak => effectiveness < 1;
}

/// An enemy's attack on Carlos.
class Strike {
  const Strike(
    this.foe,
    this.damage, {
    this.heavy = false,
    this.blocked = false,
  });

  final Foe foe;
  final double damage;

  /// A wound-up heavy attack.
  final bool heavy;

  /// A heavy attack Carlos blocked with a plank: no damage.
  final bool blocked;
}

/// What happened during [Battle.tick].
class TickEvents {
  final List<Strike> strikes = [];
  final List<Foe> colorShifts = [];

  /// Enemies that started winding up a heavy attack.
  final List<Foe> windUps = [];

  /// Enemies that dived, surfaced, vanished or showed up again.
  final List<Foe> dives = [];
  final List<Foe> surfaces = [];
  final List<Foe> vanishes = [];
  final List<Foe> reveals = [];

  /// Healers that just patched up their wave.
  final List<Foe> heals = [];
}

/// A Jungle Trek battle: the waves of a [stage], fought with Carlos's
/// [stats].
///
/// Each pushup becomes a [Hit] on the first enemy still standing, its
/// damage scaled by how well the kind of pushup suits the enemy's colour.
/// Enemies attack on their own timers, the one being hit strikes back
/// every few pushups ([TrekDifficulty.counterEvery]), and now and then it
/// winds up a heavy attack that only a plank (being down in a pushup when
/// it lands) blocks. Between waves Carlos picks a [Boon].
class Battle {
  Battle(
    this.stage,
    this.stats, {
    this.difficulty = TrekDifficulty.normal,
    math.Random? random,
  })  : _random = random ?? math.Random(),
        maxHp = stats.maxHp,
        hp = stats.maxHp,
        _heavyTimer = difficulty.heavyEvery * 0.6 {
    _startWave();
  }

  /// The endless Canopy Tower: floor after floor, each a little tougher.
  Battle.tower(
    this.stats, {
    this.difficulty = TrekDifficulty.normal,
    math.Random? random,
  })  : stage = TrekStage.tower,
        _random = random ?? math.Random(),
        maxHp = stats.maxHp,
        hp = stats.maxHp,
        _heavyTimer = difficulty.heavyEvery * 0.6 {
    _startWave();
  }

  final TrekStage stage;
  final TrekProgress stats;
  final TrekDifficulty difficulty;
  final math.Random _random;

  double hp;
  int wave = 0;
  List<Foe> foes = [];
  int combo = 0;
  int reps = 0;
  int superEffective = 0;
  int xp = 0;
  int bossPhase = 0;
  double _heavyTimer;

  /// The boons picked so far.
  final List<Boon> boons = [];

  // For the stage goals.
  double lowestHealth = 1;
  int bestCombo = 0;
  int blocks = 0;
  int heavyTaken = 0;
  double fightSeconds = 0;

  /// The kind of the last pushup that hit the King, for his copying.
  RepKind? _lastOnMirror;

  /// A held pushup during a wind-up counts as a block.
  bool _braced = false;

  final double maxHp;

  bool get endless => stage.endless;

  /// The tower floor being fought, from 1.
  int get floor => wave + 1;

  /// The tower's next floor, made up ahead so the rest can show it.
  List<EnemySpec>? _upcoming;

  List<EnemySpec> get _wave =>
      endless ? (_upcoming ?? towerWave(floor, _random)) : stage.waves[wave];

  /// Who comes in the next wave, for the rest between waves.
  List<EnemySpec> get upcoming => endless
      ? (_upcoming ??= towerWave(floor + 1, _random))
      : stage.waves[math.min(wave + 1, stage.waves.length - 1)];

  int get waveCount => endless ? floor : stage.waves.length;

  bool get lastWave => !endless && wave == stage.waves.length - 1;
  bool get waveCleared => foes.every((foe) => !foe.alive);
  bool get won => lastWave && waveCleared;
  bool get lost => hp <= 0;

  Foe? get target {
    for (final foe in foes) {
      if (foe.alive) return foe;
    }

    return null;
  }

  /// The enemies of tower [floor]: more and tougher the higher it goes,
  /// with elites mixed in and a big one every fifth floor.
  static List<EnemySpec> towerWave(int floor, math.Random random) {
    const pool = [
      EnemySpec.gecko(),
      EnemySpec.skink(),
      EnemySpec.iguana(),
      EnemySpec.croc(ScaleColor.green),
      EnemySpec.chameleon(),
      EnemySpec.snake(ScaleColor.blue),
      EnemySpec.snake(ScaleColor.yellow),
    ];
    const elites = [
      EnemySpec.shieldIguana(),
      EnemySpec.medic(),
      EnemySpec.croc(ScaleColor.blue, diver: true),
      EnemySpec.chameleon(vanisher: true),
    ];
    if (floor % 5 == 0) {
      return [
        elites[random.nextInt(elites.length)],
        elites[random.nextInt(elites.length)],
      ];
    }
    final count = math.min(3, 1 + floor ~/ 3);

    return [
      for (var i = 0; i < count; i++)
        if (floor > 3 && i == count - 1 && random.nextDouble() < 0.4)
          elites[random.nextInt(elites.length)]
        else
          pool[random.nextInt(math.min(pool.length, 2 + floor))],
    ];
  }

  /// How much tougher the enemies of the current floor are.
  double get _scale => endless ? 1 + 0.1 * wave : 1;

  void _startWave() {
    final scale = _scale;
    foes = [
      for (final (i, spec) in _wave.indexed)
        Foe(spec, i, difficulty: difficulty, scale: scale),
    ];
    _upcoming = null;
    combo = 0;
    _lastOnMirror = null;
  }

  void nextWave() {
    if (lastWave) return;
    wave++;
    _startWave();
  }

  /// Heals some between waves.
  void rest() => hp = math.min(maxHp, hp + maxHp * 0.35);

  /// Three different boons to pick from after a wave, none already held
  /// (Second Wind can come again).
  List<Boon> offerBoons() {
    final open = [
      for (final boon in Boon.values)
        if (boon.repeatable || !boons.contains(boon)) boon,
    ]..shuffle(_random);

    return open.take(3).toList();
  }

  void take(Boon boon) {
    boons.add(boon);
    if (boon == Boon.secondWind) hp = math.min(maxHp, hp + maxHp * 0.3);
  }

  bool has(Boon boon) => boons.contains(boon);

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
    bestCombo = math.max(bestCombo, combo);
    reps++;
    if (kind == RepKind.held && foe.charging != null) _braced = true;

    // A combo brings a vanished enemy back into sight.
    var revealed = false;
    if (foe.hidden && combo >= revealCombo) {
      foe
        ..hidden = false
        .._traitTimer = _hideEvery;
      revealed = true;
    }

    var multiplier = effectiveness(foe.color, kind);
    if (kind == RepKind.held) multiplier *= 1 + stats.gripBonus;
    if (kind == RepKind.quick) {
      multiplier *= 1 + stats.quickBonus;
      if (foe.color == ScaleColor.yellow) {
        multiplier += math.min(1, combo * 0.25);
      }
      if (has(Boon.comboKing)) multiplier *= 1 + math.min(0.6, combo * 0.06);
    }
    if (has(Boon.berserk) && hp < maxHp / 2) multiplier *= 1.25;

    var note = HitNote.none;
    if (foe.submerged && kind != RepKind.quick) {
      note = HitNote.splash;
      multiplier = 0;
    } else if (foe.hidden) {
      note = HitNote.unseen;
      multiplier *= 0.25;
    } else if (foe.shield > 0) {
      if (kind == RepKind.held) {
        foe.shield--;
        multiplier *= 0.5;
        note = foe.shield == 0 ? HitNote.shieldBroken : HitNote.shielded;
      } else {
        multiplier *= 0.15;
        note = HitNote.shielded;
      }
    } else if (foe.trait == Trait.mirror && kind == _lastOnMirror) {
      multiplier *= 0.5;
      note = HitNote.mirrored;
    } else if (foe.stagger > 0) {
      multiplier *= 1.5;
      note = HitNote.staggered;
    }
    if (foe.trait == Trait.mirror) _lastOnMirror = kind;

    final critical = multiplier > 0 &&
        _random.nextDouble() < (has(Boon.sharpEye) ? 0.25 : 0.1);
    final damage = stats.attack * multiplier * (critical ? 1.5 : 1);
    if (multiplier > 1) superEffective++;
    foe.hp = math.max(0, foe.hp - damage);
    if (has(Boon.vampire)) hp = math.min(maxHp, hp + damage * 0.05);

    // Chain Lightning: quick pushups also hit the next one standing.
    Foe? chained;
    var chainDamage = 0.0;
    if (kind == RepKind.quick && has(Boon.chain)) {
      for (final other in foes) {
        if (other != foe && other.alive && !other.submerged) {
          chained = other;
          chainDamage = damage * 0.4;
          other.hp = math.max(0, other.hp - chainDamage);
          if (!other.alive) xp += other.spec.xp;
          break;
        }
      }
    }

    // Every few pushups it takes, it hits back (on the next tick, so the
    // scene and the HUD show it like any other attack). Not while it's
    // winding up, under water or reeling.
    if (foe.alive &&
        foe.charging == null &&
        !foe.submerged &&
        foe.stagger <= 0 &&
        ++foe._hitsTaken >= difficulty.counterEvery) {
      foe
        .._hitsTaken = 0
        ..attackTimer = math.min(foe.attackTimer, 0.45);
    }

    int? phase;
    if (foe.spec.species == Species.king && foe.alive) {
      final next = foe.hp > foe.maxHp * 2 / 3
          ? 0
          : foe.hp > foe.maxHp / 3
              ? 1
              : 2;
      if (next != bossPhase) {
        bossPhase = next;
        foe.color = ScaleColor.values[next];
        phase = next;
      }
    }
    if (!foe.alive) {
      xp += foe.spec.xp;
      foe.charging = null;
    }

    return Hit(
      foe: foe,
      kind: kind,
      damage: damage,
      effectiveness: multiplier,
      critical: critical,
      defeated: !foe.alive,
      combo: combo,
      phase: phase,
      note: note,
      chained: chained,
      chainDamage: chainDamage,
      revealed: revealed,
      last: won,
    );
  }

  /// Damage Carlos takes from [amount], after his boons.
  double _hurt(double amount) {
    final taken = amount * (has(Boon.thickSkin) ? 0.85 : 1);
    hp = math.max(0, hp - taken);
    lowestHealth = math.min(lowestHealth, hp / maxHp);

    return taken;
  }

  /// Advances the enemies' timers by [deltaSeconds]: attacks, wind-ups,
  /// dives, vanishing, heals and colour changes. [bracing] is whether
  /// Carlos is down in a pushup right now, which blocks a heavy attack.
  TickEvents tick(double deltaSeconds, {bool bracing = false}) {
    final events = TickEvents();
    fightSeconds += deltaSeconds;

    // Now and then the one in front winds up a heavy attack.
    final front = target;
    if (front != null &&
        front.charging == null &&
        !front.submerged &&
        !front.hidden &&
        front.stagger <= 0) {
      _heavyTimer -= deltaSeconds;
      if (_heavyTimer <= 0) {
        _heavyTimer = difficulty.heavyEvery;
        front.charging = difficulty.windUp;
        _braced = false;
        events.windUps.add(front);
      }
    }

    for (final foe in foes) {
      if (!foe.alive) continue;
      foe.stagger = math.max(0, foe.stagger - deltaSeconds);

      final charging = foe.charging;
      if (charging != null) {
        final left = charging - deltaSeconds;
        if (left > 0) {
          foe.charging = left;
        } else {
          foe
            ..charging = null
            ..attackTimer = math.max(foe.attackTimer, _afterCounter);
          if (bracing || _braced) {
            blocks++;
            foe.stagger = staggerSeconds;
            if (has(Boon.ironPlank)) hp = math.min(maxHp, hp + maxHp * 0.08);
            events.strikes.add(Strike(foe, 0, heavy: true, blocked: true));
          } else {
            heavyTaken++;
            final taken = _hurt(foe.attack * difficulty.heavy);
            events.strikes.add(Strike(foe, taken, heavy: true));
          }
          _braced = false;
        }
        continue;
      }

      _tickTrait(foe, deltaSeconds, events);
      if (foe.stagger > 0 || foe.submerged) continue;

      foe.attackTimer -= deltaSeconds;
      if (foe.attackTimer <= 0) {
        foe
          ..attackTimer = math.max(
            _afterCounter,
            foe.attackTimer + foe.attackEvery,
          )
          .._hitsTaken = 0;
        events.strikes.add(Strike(foe, _hurt(foe.attack)));
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

  void _tickTrait(Foe foe, double deltaSeconds, TickEvents events) {
    switch (foe.trait) {
      case Trait.diver:
        foe._traitTimer -= deltaSeconds;
        if (foe._traitTimer > 0) return;
        foe.submerged = !foe.submerged;
        foe._traitTimer = foe.submerged ? _diveFor : _diveEvery;
        (foe.submerged ? events.dives : events.surfaces).add(foe);
      case Trait.vanisher:
        foe._traitTimer -= deltaSeconds;
        if (foe._traitTimer > 0) return;
        foe.hidden = !foe.hidden;
        foe._traitTimer = foe.hidden ? _hideFor : _hideEvery;
        (foe.hidden ? events.vanishes : events.reveals).add(foe);
      case Trait.healer:
        foe._traitTimer -= deltaSeconds;
        if (foe._traitTimer > 0) return;
        foe._traitTimer = _healEvery;
        var healed = false;
        for (final other in foes) {
          if (other != foe && other.alive && other.hp < other.maxHp) {
            other.hp =
                math.min(other.maxHp, other.hp + other.maxHp * _healShare);
            healed = true;
          }
        }
        if (healed) events.heals.add(foe);
      case Trait.none || Trait.shielded || Trait.mirror:
        return;
    }
  }

  /// Whether [goal] was met by the end of a won battle.
  bool met(StageGoal goal) => switch (goal.kind) {
        GoalKind.health => lowestHealth * 100 >= goal.value,
        GoalKind.combo => bestCombo >= goal.value,
        GoalKind.blocks => blocks >= goal.value,
        GoalKind.fast => fightSeconds <= goal.value,
        GoalKind.noHeavy => heavyTaken == 0,
      };

  /// Stars for a won battle: one for winning and one per goal met.
  int get stars => 1 + stage.goals.where(met).length;

  /// XP from the enemies beaten, scaled by the difficulty.
  int get earnedXp => (xp * difficulty.rewards).round();

  /// Bonus XP for clearing the stage (or, in the tower, per floor).
  int get clearXp => endless
      ? (wave * 12 * difficulty.rewards).round()
      : ((30 + 10 * stage.number) * difficulty.rewards).round();
}
