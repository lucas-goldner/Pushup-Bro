import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/model/trek_progress.dart';
import 'package:pushup_bro/features/trek/model/battle.dart';
import 'package:pushup_bro/features/trek/model/boon.dart';
import 'package:pushup_bro/features/trek/model/tower_week.dart';
import 'package:pushup_bro/features/trek/model/trek.dart';
import 'package:pushup_bro/features/trek/widgets/difficulty_picker.dart';

/// Never rolls a critical hit.
class _NoCrit implements math.Random {
  @override
  double nextDouble() => 0.99;

  @override
  bool nextBool() => false;

  @override
  int nextInt(int max) => 0;
}

void main() {
  group('effectiveness', () {
    test('each colour has one pushup that suits it best', () {
      expect(effectiveness(ScaleColor.green, RepKind.normal), 2);
      expect(effectiveness(ScaleColor.blue, RepKind.held), 3);
      expect(effectiveness(ScaleColor.yellow, RepKind.quick), 2);
      expect(effectiveness(ScaleColor.blue, RepKind.quick), lessThan(1));
      expect(effectiveness(ScaleColor.yellow, RepKind.held), lessThan(1));
    });
  });

  group('Battle', () {
    Battle battle([TrekProgress stats = const TrekProgress()]) =>
        Battle(TrekStage.all.first, stats, random: _NoCrit());

    test('classifies held, quick and normal pushups', () {
      final b = battle();
      expect(b.classify(held: holdSeconds), RepKind.held);
      expect(b.classify(held: 0.5, sinceLast: 1), RepKind.quick);
      expect(b.classify(held: 0.5, sinceLast: 5), RepKind.normal);
      expect(b.classify(held: 0.5), RepKind.normal);
    });

    test('a normal pushup on a green gecko is super effective', () {
      final b = battle();
      final foe = b.target!;
      expect(foe.color, ScaleColor.green);
      final hit = b.rep(held: 0.5)!;
      expect(hit.superEffective, isTrue);
      expect(hit.damage, const TrekProgress().attack * 2);
      expect(foe.hp, foe.maxHp - hit.damage);
    });

    test('defeating every wave wins, with XP for each enemy', () {
      final b = battle();
      while (!b.won) {
        if (b.waveCleared) b.nextWave();
        b.rep(held: 0.5);
      }
      final enemyXp = [
        for (final wave in TrekStage.all.first.waves)
          for (final spec in wave) spec.xp,
      ].fold(0, (a, b) => a + b);
      expect(b.xp, enemyXp);
      // Won without a scratch, but no 3-combo: two of three stars.
      expect(b.stars, 2);
      expect(b.target, isNull);
      expect(b.rep(held: 0.5), isNull);
    });

    test('enemies attack on their timers', () {
      final b = battle();
      final foe = b.target!;
      final events = b.tick(foe.attackTimer + 0.01);
      expect(events.strikes.map((s) => s.foe), [foe]);
      expect(b.hp, b.maxHp - foe.attack);
    });

    test('the enemy being hit strikes back every few pushups', () {
      final b = battle();
      final foe = b.target!;
      for (var i = 0; i < TrekDifficulty.normal.counterEvery; i++) {
        b.rep(held: 0.5);
      }
      expect(foe.alive, isTrue);
      expect(b.tick(0.5).strikes.map((s) => s.foe), [foe]);
      expect(b.hp, b.maxHp - foe.attack);
    });

    test('a normal enemy takes about five good pushups', () {
      final b = battle();
      final foe = b.target!;
      var reps = 0;
      while (foe.alive) {
        b.rep(held: 0.5);
        reps++;
      }
      expect(reps, 5);
    });

    test('resting heals but not past full health', () {
      final b = battle()
        ..hp = 10
        ..rest();
      expect(b.hp, 10 + b.maxHp * 0.35);
      b
        ..hp = b.maxHp - 1
        ..rest();
      expect(b.hp, b.maxHp);
    });

    test('the Lizard King changes colour as he loses health', () {
      final boss = TrekStage.all.last;
      expect(boss.boss, isTrue);
      final b = Battle(
        boss,
        const TrekProgress(level: 30, power: 30),
        random: _NoCrit(),
      );
      while (b.waveCleared) {
        b.nextWave();
      }
      final king = b.foes.firstWhere((f) => f.spec.species == Species.king);
      final phases = <int>[];
      while (king.alive) {
        b.foes
            .where((f) => f != king)
            .forEach((f) => f.hp = 0); // Only the King matters here.
        final hit = b.rep(held: holdSeconds);
        if (hit?.phase != null) phases.add(hit!.phase!);
      }
      expect(phases, [1, 2]);
    });
  });

  group('Heavy attacks', () {
    Battle fresh() => Battle(TrekStage.all.first, const TrekProgress());

    Foe windUp(Battle b) {
      while (b.target!.charging == null) {
        b.tick(0.1);
      }
      final foe = b.target!;
      expect(foe.charging, isNotNull);
      return foe;
    }

    test('one taken unblocked hits hard', () {
      final b = fresh();
      final foe = windUp(b);
      final before = b.hp;
      final events = b.tick(TrekDifficulty.normal.windUp + 0.01);
      final strike = events.strikes.firstWhere((s) => s.heavy);
      expect(strike.heavy, isTrue);
      expect(strike.blocked, isFalse);
      expect(strike.damage, closeTo(foe.attack * 2.5, 0.01));
      expect(before - b.hp, greaterThanOrEqualTo(strike.damage));
      expect(b.heavyTaken, 1);
    });

    test('a plank blocks it and leaves the enemy reeling', () {
      final b = fresh();
      final foe = windUp(b);
      final before = b.hp;
      final events = b.tick(TrekDifficulty.normal.windUp + 0.01, bracing: true);
      expect(events.strikes.firstWhere((s) => s.heavy).blocked, isTrue);
      expect(b.hp, before);
      expect(b.blocks, 1);
      expect(foe.stagger, greaterThan(0));
      expect(b.rep(held: 0.5)!.note, HitNote.staggered);
    });

    test('a held pushup during the wind-up blocks it too', () {
      final b = fresh();
      windUp(b);
      b.rep(held: holdSeconds);
      final events = b.tick(TrekDifficulty.normal.windUp + 0.01);
      expect(events.strikes.firstWhere((s) => s.heavy).blocked, isTrue);
    });
  });

  group('Traits', () {
    Battle against(List<EnemySpec> wave) => Battle(
          TrekStage(
            id: 'test',
            emoji: '',
            location: TrekStage.all.first.location,
            title: (l) => '',
            blurb: (l) => '',
            loot: '',
            waves: [wave],
            intro: const [],
            outro: const [],
          ),
          const TrekProgress(),
          random: _NoCrit(),
        );

    test('a shield takes held pushups to break', () {
      final b = against(const [EnemySpec.shieldIguana()]);
      final foe = b.target!;
      expect(b.rep(held: 0.5)!.note, HitNote.shielded);
      for (var i = 0; i < 2; i++) {
        b.rep(held: holdSeconds);
      }
      expect(b.rep(held: holdSeconds)!.note, HitNote.shieldBroken);
      expect(foe.shield, 0);
    });

    test('a diver under water only feels quick pushups', () {
      final b = against(const [EnemySpec.croc(ScaleColor.green, diver: true)]);
      final foe = b.target!;
      while (!foe.submerged) {
        b.tick(0.5);
      }
      final splash = b.rep(held: 0.5)!;
      expect(splash.note, HitNote.splash);
      expect(splash.damage, 0);
      expect(b.rep(held: 0.5, sinceLast: 1)!.damage, greaterThan(0));
    });

    test('a quick combo finds a vanished enemy', () {
      final b = against(const [EnemySpec.chameleon(vanisher: true)]);
      final foe = b.target!;
      while (!foe.hidden) {
        b.tick(0.5);
      }
      expect(b.rep(held: 0.5)!.note, HitNote.unseen);
      Hit? hit;
      for (var i = 0; i < revealCombo; i++) {
        hit = b.rep(held: 0.5, sinceLast: 1);
      }
      expect(hit!.revealed, isTrue);
      expect(foe.hidden, isFalse);
    });

    test('a medic heals the rest of its wave', () {
      final b = against(const [EnemySpec.gecko(), EnemySpec.medic()]);
      final gecko = b.target!..hp = 10;
      final events = b.tick(7.1);
      expect(events.heals, isNotEmpty);
      expect(gecko.hp, greaterThan(10));
    });

    test('the King shrugs off the same pushup twice', () {
      final b = against(const [EnemySpec.king()]);
      expect(b.rep(held: 0.5)!.note, HitNote.none);
      expect(b.rep(held: 5)!.note, HitNote.none);
      expect(b.rep(held: 5)!.note, HitNote.mirrored);
    });
  });

  group('Boons and goals', () {
    test('three different boons are offered, none already taken', () {
      final b = Battle(TrekStage.all.first, const TrekProgress())
        ..take(Boon.chain);
      final offer = b.offerBoons();
      expect(offer, hasLength(3));
      expect(offer.toSet(), hasLength(3));
      expect(offer, isNot(contains(Boon.chain)));
    });

    test('Chain Lightning hits the next enemy on quick pushups', () {
      final b = Battle(
        TrekStage.all[1],
        const TrekProgress(),
        random: _NoCrit(),
      )
        ..nextWave()
        ..take(Boon.chain);
      final hit = b.rep(held: 0.5, sinceLast: 1)!;
      expect(hit.chained, isNotNull);
      expect(hit.chainDamage, closeTo(hit.damage * 0.4, 0.01));
    });

    test('goals give the second and third star', () {
      final b = Battle(
        TrekStage.all.first,
        const TrekProgress(),
        random: _NoCrit(),
      );
      var since = 5.0;
      while (!b.won) {
        if (b.waveCleared) b.nextWave();
        b.rep(held: 0.5, sinceLast: since);
        since = since == 5 ? 1 : 5;
      }
      expect(b.stars, 2);
    });
  });

  group('Tower', () {
    test('floors get tougher and never run out', () {
      final b = Battle.tower(const TrekProgress(), random: math.Random(1));
      final firstHp = b.foes.first.maxHp;
      for (var floor = 0; floor < 12; floor++) {
        for (final foe in b.foes) {
          foe.hp = 0;
        }
        expect(b.won, isFalse);
        b.nextWave();
      }
      expect(b.floor, 13);
      expect(
        b.foes.map((f) => f.maxHp).reduce(math.max),
        greaterThan(firstHp),
      );
    });

    test('the next floor shown at rest is the one that comes', () {
      final b = Battle.tower(const TrekProgress(), random: math.Random(2));
      final next = b.upcoming;
      b.nextWave();
      expect(b.foes.map((f) => f.spec), next);
    });

    test('progress keeps the best floor and this week', () {
      const progress = TrekProgress();
      final climbed = progress.climbed(7, '2026-W45').climbed(4, '2026-W45');
      expect(climbed.towerBest, 7);
      expect(climbed.towerBestIn('2026-W45'), 7);
      expect(climbed.towerBestIn('2026-W46'), 0);
      final next = climbed.climbed(3, '2026-W46');
      expect(next.towerBest, 7);
      expect(next.towerBestIn('2026-W46'), 3);
      expect(TrekProgress.fromJson(next.toJson()), next);
    });

    test('weeks start on Monday', () {
      expect(towerWeekOf(DateTime(2026, 11, 4)), '2026-W45');
      expect(towerWeekOf(DateTime(2026, 11, 8)), '2026-W45');
      expect(towerWeekOf(DateTime(2026, 11, 9)), '2026-W46');
      expect(towerWeekOf(DateTime(2027)), '2026-W53');
    });
  });

  group('TrekDifficulty', () {
    test('tougher difficulties take more pushups and hit harder', () {
      int repsFor(TrekDifficulty difficulty) {
        final b = Battle(
          TrekStage.all.first,
          const TrekProgress(),
          difficulty: difficulty,
          random: _NoCrit(),
        );
        while (!b.won) {
          if (b.waveCleared) b.nextWave();
          b.rep(held: 0.5);
        }

        return b.reps;
      }

      final reps = [for (final d in TrekDifficulty.values) repsFor(d)];
      expect(reps, orderedEquals([...reps]..sort()));
      expect(reps.first, lessThanOrEqualTo(12));
      expect(reps[1], inInclusiveRange(18, 25));
      expect(reps.last, greaterThanOrEqualTo(45));
      final attacks = [
        for (final d in TrekDifficulty.values)
          Foe(const EnemySpec.gecko(), 0, difficulty: d).attack,
      ];
      expect(attacks, orderedEquals([...attacks]..sort()));
    });

    test('harder difficulties pay more', () {
      final easy = Battle(
        TrekStage.all.first,
        const TrekProgress(),
        difficulty: TrekDifficulty.easy,
      );
      final brutal = Battle(
        TrekStage.all.first,
        const TrekProgress(),
        difficulty: TrekDifficulty.brutal,
      );
      expect(brutal.clearXp, greaterThan(easy.clearXp));
    });

    test('Brutal stays locked until the King is beaten', () {
      const fresh = TrekProgress(difficulty: 'brutal');
      expect(brutalUnlocked(fresh), isFalse);
      expect(difficultyOf(fresh), TrekDifficulty.normal);
      final done = fresh.clear(TrekStage.all.last.id, 1);
      expect(brutalUnlocked(done), isTrue);
      expect(difficultyOf(done), TrekDifficulty.brutal);
    });

    test('is saved with the progress', () {
      const progress = TrekProgress(difficulty: 'hard');
      expect(TrekProgress.fromJson(progress.toJson()).difficulty, 'hard');
      expect(TrekProgress.fromJson(const {}).difficulty, 'normal');
    });
  });

  group('TrekProgress', () {
    test('levels up, carrying over XP and granting points', () {
      const start = TrekProgress();
      final needed = TrekProgress.xpToNext(1) + TrekProgress.xpToNext(2);
      final (progress, levels) = start.gainXp(needed + 5);
      expect(levels, 2);
      expect(progress.level, 3);
      expect(progress.xp, 5);
      expect(progress.points, 2);
    });

    test('spends points on stats only when it has some', () {
      const progress = TrekProgress(points: 1);
      final spent = progress.spend('power');
      expect(spent.power, 1);
      expect(spent.points, 0);
      expect(spent.attack, greaterThan(progress.attack));
      expect(spent.spend('grip'), spent);
    });

    test('keeps the best stars per stage', () {
      final progress =
          const TrekProgress().clear('fern-trail', 3).clear('fern-trail', 1);
      expect(progress.stars['fern-trail'], 3);
      expect(progress.cleared('fern-trail'), isTrue);
      expect(progress.cleared('canopy-bridge'), isFalse);
    });

    test('round-trips through JSON', () {
      const progress = TrekProgress(
        level: 4,
        xp: 12,
        points: 1,
        power: 2,
        vitality: 1,
        grip: 3,
        agility: 1,
        stars: {'fern-trail': 2},
      );
      expect(TrekProgress.fromJson(progress.toJson()), progress);
    });
  });

  test('the stages unlock exclusive lizard loot', () {
    expect(TrekStage.byId('fern-trail'), TrekStage.all.first);
    expect(TrekStage.all.last.loot, 'hat.lizardcrown');
    expect(
      TrekStage.all.map((stage) => stage.loot).toSet(),
      hasLength(TrekStage.all.length),
    );
  });

  test('King Komo is a lizard, through JSON too', () {
    final look = MonkeyLook.fromJson(MonkeyLook.kingKomo.toJson());
    expect(look, MonkeyLook.kingKomo);
    expect(look.species, MonkeyLook.lizard);
    expect(
      MonkeyLook.fromJson(const MonkeyLook().toJson()).species,
      MonkeyLook.gorilla,
    );
  });
}
