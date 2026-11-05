import 'dart:ui' show Color;

import 'package:pushup_bro/features/jungle/model/jungle_quest.dart';
import 'package:pushup_bro/generated/l10n.dart';

/// The colour of a reptile, which decides which pushups hurt it most.
enum ScaleColor {
  /// Weak to steady, ordinary pushups.
  green(Color(0xFF4FB35A)),

  /// Weak to pushups held at the bottom.
  blue(Color(0xFF4F9BE0)),

  /// Weak to quick pushups in a row.
  yellow(Color(0xFFF2B630));

  const ScaleColor(this.color);

  final Color color;

  String weakness(S l) => switch (this) {
        green => l.weakGreen,
        blue => l.weakBlue,
        yellow => l.weakYellow,
      };
}

/// How a pushup was done, judged from how long it was held at the bottom
/// and how soon it followed the last one.
enum RepKind {
  normal,
  held,
  quick;

  String label(S l) => switch (this) {
        normal => l.repNormal,
        held => l.repHeld,
        quick => l.repQuick,
      };

  Color get color => switch (this) {
        normal => ScaleColor.green.color,
        held => ScaleColor.blue.color,
        quick => ScaleColor.yellow.color,
      };
}

/// How hard a [kind] of pushup hits a reptile of [color].
double effectiveness(ScaleColor color, RepKind kind) => switch ((color, kind)) {
      (ScaleColor.green, RepKind.normal) => 2,
      (ScaleColor.green, _) => 1,
      (ScaleColor.blue, RepKind.held) => 3,
      (ScaleColor.blue, RepKind.normal) => 0.5,
      (ScaleColor.blue, RepKind.quick) => 0.25,
      (ScaleColor.yellow, RepKind.quick) => 2,
      (ScaleColor.yellow, RepKind.normal) => 0.5,
      (ScaleColor.yellow, RepKind.held) => 0.25,
    };

/// How tough the Trek is, picked by how many pushups in a row the player
/// can do. Tougher reptiles take more pushups to beat and hit back harder
/// and sooner, and pay out more XP and bananas. [brutal] opens once the
/// whole Trek is cleared.
enum TrekDifficulty {
  /// Fewer than 10 pushups in a row: about 10 to 15 a stage.
  easy(
    health: 0.42,
    damage: 0.6,
    pace: 1.25,
    counterEvery: 4,
    rewards: 0.75,
    heavyEvery: 22,
    windUp: 4,
    heavy: 2,
  ),

  /// About 10 to 20 in a row: about 20 to 35 a stage, with rests.
  normal(
    health: 1,
    damage: 1,
    pace: 1,
    counterEvery: 3,
    rewards: 1,
    heavyEvery: 16,
    windUp: 3.2,
    heavy: 2.5,
  ),

  /// 30 or more: about 30 to 45 a stage.
  hard(
    health: 1.7,
    damage: 1.15,
    pace: 0.9,
    counterEvery: 3,
    rewards: 1.5,
    heavyEvery: 13,
    windUp: 2.8,
    heavy: 2.8,
  ),

  /// 50 or more: 40 to 60 a stage, and every second pushup gets hit back.
  brutal(
    health: 2.6,
    damage: 1.25,
    pace: 0.8,
    counterEvery: 2,
    rewards: 2.2,
    heavyEvery: 10,
    windUp: 2.4,
    heavy: 3,
  );

  const TrekDifficulty({
    required this.health,
    required this.damage,
    required this.pace,
    required this.counterEvery,
    required this.rewards,
    required this.heavyEvery,
    required this.windUp,
    required this.heavy,
  });

  /// Seconds between heavy attacks.
  final double heavyEvery;

  /// Seconds a heavy attack winds up: the time to get down into a plank.
  final double windUp;

  /// A heavy attack's damage, times a normal one.
  final double heavy;

  /// Enemy health, times the normal.
  final double health;

  /// Enemy damage, times the normal.
  final double damage;

  /// Seconds between enemy attacks, times the normal.
  final double pace;

  /// The enemy being hit strikes back after this many pushups.
  final int counterEvery;

  /// XP and bananas, times the normal.
  final double rewards;

  static TrekDifficulty byName(String? name) {
    for (final difficulty in values) {
      if (difficulty.name == name) return difficulty;
    }

    return normal;
  }

  String label(S l) => switch (this) {
        easy => l.trekEasy,
        normal => l.trekNormal,
        hard => l.trekHard,
        brutal => l.trekBrutal,
      };

  /// Who it's for, by pushups in a row.
  String forWho(S l) => switch (this) {
        easy => l.trekEasyInfo,
        normal => l.trekNormalInfo,
        hard => l.trekHardInfo,
        brutal => l.trekBrutalInfo,
      };

  String get emoji => switch (this) {
        easy => '🌱',
        normal => '💪',
        hard => '🔥',
        brutal => '💀',
      };
}

/// The kinds of reptile in the jungle.
enum Species {
  gecko,
  skink,
  iguana,
  croc,
  chameleon,
  snake,
  king;

  String name(S l) => switch (this) {
        gecko => l.enemyGecko,
        skink => l.enemySkink,
        iguana => l.enemyIguana,
        croc => l.enemyCroc,
        chameleon => l.enemyChameleon,
        snake => l.enemySnake,
        king => l.enemyKing,
      };
}

/// A special rule an enemy fights by.
enum Trait {
  none,

  /// Dives under the water now and then: only quick pushups reach it.
  diver,

  /// Turns invisible now and then: hits barely land until a quick combo
  /// shows it again.
  vanisher,

  /// Starts behind a shield that only held pushups break.
  shielded,

  /// Heals the others in its wave while it stands.
  healer,

  /// Copies Carlos: the same kind of pushup twice in a row barely hurts.
  mirror,
}

/// One enemy in a wave. A null [color] shifts between all three.
class EnemySpec {
  const EnemySpec(
    this.species,
    this.color, {
    required this.hp,
    required this.attack,
    required this.attackEvery,
    required this.xp,
    this.trait = Trait.none,
    this.shield = 0,
  });

  /// An iguana behind a shield of three plates.
  const EnemySpec.shieldIguana([ScaleColor color = ScaleColor.green])
      : this(
          Species.iguana,
          color,
          hp: 150,
          attack: 11,
          attackEvery: 12,
          xp: 34,
          trait: Trait.shielded,
          shield: 3,
        );

  /// A skink medic that patches up the rest of its wave.
  const EnemySpec.medic([ScaleColor color = ScaleColor.green])
      : this(
          Species.skink,
          color,
          hp: 90,
          attack: 5,
          attackEvery: 9,
          xp: 24,
          trait: Trait.healer,
        );

  const EnemySpec.gecko([ScaleColor color = ScaleColor.green])
      : this(Species.gecko, color, hp: 100, attack: 8, attackEvery: 10, xp: 15);
  const EnemySpec.skink([ScaleColor color = ScaleColor.yellow])
      : this(Species.skink, color, hp: 110, attack: 7, attackEvery: 8, xp: 18);
  const EnemySpec.iguana([ScaleColor color = ScaleColor.blue])
      : this(
          Species.iguana,
          color,
          hp: 150,
          attack: 11,
          attackEvery: 12,
          xp: 26,
        );
  const EnemySpec.croc(ScaleColor color, {bool diver = false})
      : this(
          Species.croc,
          color,
          hp: 170,
          attack: 12,
          attackEvery: 12,
          xp: 32,
          trait: diver ? Trait.diver : Trait.none,
        );
  const EnemySpec.chameleon({bool vanisher = false})
      : this(
          Species.chameleon,
          null,
          hp: 160,
          attack: 10,
          attackEvery: 10,
          xp: 34,
          trait: vanisher ? Trait.vanisher : Trait.none,
        );
  const EnemySpec.snake(ScaleColor color)
      : this(
          Species.snake,
          color,
          hp: 150,
          attack: 11,
          attackEvery: 10,
          xp: 30,
        );
  const EnemySpec.king()
      : this(
          Species.king,
          ScaleColor.green,
          hp: 1300,
          attack: 10,
          attackEvery: 8,
          trait: Trait.mirror,
          xp: 300,
        );

  final Species species;
  final ScaleColor? color;
  final double hp;
  final double attack;

  /// Seconds between its attacks.
  final double attackEvery;
  final int xp;
  final Trait trait;

  /// Shield plates; each held pushup breaks one.
  final int shield;
}

/// What a stage's stars ask for, beyond winning.
enum GoalKind {
  /// Never drop below [StageGoal.value] percent health.
  health,

  /// Reach a quick combo of [StageGoal.value].
  combo,

  /// Block [StageGoal.value] heavy attacks.
  blocks,

  /// Win within [StageGoal.value] seconds of fighting.
  fast,

  /// Take no heavy attack unblocked.
  noHeavy,
}

/// One of a stage's two star goals.
class StageGoal {
  const StageGoal(this.kind, [this.value = 0]);

  final GoalKind kind;
  final int value;

  String label(S l) => switch (kind) {
        GoalKind.health => l.goalHealth(value),
        GoalKind.combo => l.goalCombo(value),
        GoalKind.blocks => l.goalBlocks(value),
        GoalKind.fast => l.goalFast((value / 60).ceil()),
        GoalKind.noHeavy => l.goalNoHeavy,
      };
}

/// A line of a Trek story: who says what.
typedef TrekLine = (Character speaker, String Function(S l) text);

/// A stage of the Jungle Trek: a place, a story, and waves of reptiles.
class TrekStage {
  const TrekStage({
    required this.id,
    required this.emoji,
    required this.location,
    required this.title,
    required this.blurb,
    required this.waves,
    required this.intro,
    required this.outro,
    required this.loot,
    this.phaseLines = const [],
    this.goals = const [],
  });

  final String id;
  final String emoji;
  final ChallengeLocation location;
  final String Function(S l) title;
  final String Function(S l) blurb;
  final List<List<EnemySpec>> waves;
  final List<TrekLine> intro;
  final List<TrekLine> outro;

  /// The boss's lines as the fight turns (one per phase after the first).
  final List<TrekLine> phaseLines;

  /// The cosmetic won the first time the stage is cleared.
  final String loot;

  /// The two goals that earn the second and third star.
  final List<StageGoal> goals;

  bool get boss =>
      waves.any((wave) => wave.any((e) => e.species == Species.king));

  int get number => all.indexOf(this) + 1;

  /// A little 3D diorama of the stage's place, shown beside it on the map.
  String get landmark => landmarkFor(id);

  /// The map's diorama for [id] (`soon` for the trail still to come).
  static String landmarkFor(String id) =>
      'assets/images/trek/landmark_$id.webp';

  static TrekStage? byId(String id) {
    for (final stage in all) {
      if (stage.id == id) return stage;
    }

    return null;
  }

  /// The endless Canopy Tower, open once King Komo is beaten: floor after
  /// floor of reptiles until Carlos goes down. Its waves are made up as
  /// it goes (see `Battle.tower`).
  static final tower = TrekStage(
    id: 'tower',
    emoji: '🗼',
    location: ChallengeLocation.canopy,
    title: (l) => l.towerTitle,
    blurb: (l) => l.towerBlurb,
    loot: '',
    waves: const [],
    intro: const [],
    outro: const [],
  );

  bool get endless => id == 'tower';

  static final all = <TrekStage>[
    TrekStage(
      id: 'fern-trail',
      emoji: '🌿',
      location: ChallengeLocation.fernTrail,
      title: (l) => l.stage1Title,
      blurb: (l) => l.stage1Blurb,
      loot: 'pattern.scales',
      waves: const [
        [EnemySpec.gecko()],
        [EnemySpec.gecko()],
        [EnemySpec.gecko(), EnemySpec.gecko()],
      ],
      goals: const [
        StageGoal(GoalKind.health, 50),
        StageGoal(GoalKind.combo, 3),
      ],
      intro: [
        (Character.coco, (l) => l.s1i1),
        (Character.zip, (l) => l.s1i2),
        (Character.carlos, (l) => l.s1i3),
        (Character.zip, (l) => l.s1i4),
        (Character.coco, (l) => l.s1i5),
      ],
      outro: [
        (Character.zip, (l) => l.s1o1),
        (Character.zip, (l) => l.s1o2),
      ],
    ),
    TrekStage(
      id: 'canopy-bridge',
      emoji: '🌉',
      location: ChallengeLocation.canopy,
      title: (l) => l.stage2Title,
      blurb: (l) => l.stage2Blurb,
      loot: 'hat.gecko',
      waves: const [
        [EnemySpec.skink()],
        [EnemySpec.skink(), EnemySpec.gecko()],
        [EnemySpec.skink(), EnemySpec.skink()],
      ],
      goals: const [
        StageGoal(GoalKind.blocks, 1),
        StageGoal(GoalKind.combo, 4),
      ],
      intro: [
        (Character.coco, (l) => l.s2i1),
        (Character.skitter, (l) => l.s2i2),
        (Character.coco, (l) => l.s2i3),
        (Character.carlos, (l) => l.s2i4),
      ],
      outro: [(Character.skitter, (l) => l.s2o1)],
    ),
    TrekStage(
      id: 'misty-swamp',
      emoji: '🌫️',
      location: ChallengeLocation.swamp,
      title: (l) => l.stage3Title,
      blurb: (l) => l.stage3Blurb,
      loot: 'fur.jade',
      waves: const [
        [EnemySpec.iguana()],
        [EnemySpec.shieldIguana()],
        [EnemySpec.iguana(), EnemySpec.medic(), EnemySpec.skink()],
      ],
      goals: const [
        StageGoal(GoalKind.health, 40),
        StageGoal(GoalKind.blocks, 2),
      ],
      intro: [
        (Character.coco, (l) => l.s3i1),
        (Character.frostbite, (l) => l.s3i2),
        (Character.coco, (l) => l.s3i3),
      ],
      outro: [(Character.frostbite, (l) => l.s3o1)],
    ),
    TrekStage(
      id: 'lake-snapjaw',
      emoji: '⛵',
      location: ChallengeLocation.lake,
      title: (l) => l.stage4Title,
      blurb: (l) => l.stage4Blurb,
      loot: 'outfit.tooth',
      waves: const [
        [EnemySpec.croc(ScaleColor.blue)],
        [EnemySpec.croc(ScaleColor.green), EnemySpec.croc(ScaleColor.yellow)],
        [
          EnemySpec.croc(ScaleColor.blue, diver: true),
          EnemySpec.croc(ScaleColor.green),
        ],
      ],
      goals: const [
        StageGoal(GoalKind.noHeavy),
        StageGoal(GoalKind.combo, 5),
      ],
      intro: [
        (Character.coco, (l) => l.s4i1),
        (Character.carlos, (l) => l.s4i2),
        (Character.snap, (l) => l.s4i3),
        (Character.coco, (l) => l.s4i4),
      ],
      outro: [(Character.snap, (l) => l.s4o1)],
    ),
    TrekStage(
      id: 'temple-of-scales',
      emoji: '🛕',
      location: ChallengeLocation.temple,
      title: (l) => l.stage5Title,
      blurb: (l) => l.stage5Blurb,
      loot: 'eyes.chameleon',
      waves: const [
        [EnemySpec.chameleon()],
        [EnemySpec.chameleon(), EnemySpec.shieldIguana(ScaleColor.yellow)],
        [EnemySpec.chameleon(vanisher: true), EnemySpec.chameleon()],
      ],
      goals: const [
        StageGoal(GoalKind.fast, 300),
        StageGoal(GoalKind.blocks, 2),
      ],
      intro: [
        (Character.coco, (l) => l.s5i1),
        (Character.shifty, (l) => l.s5i2),
        (Character.coco, (l) => l.s5i3),
        (Character.carlos, (l) => l.s5i4),
      ],
      outro: [(Character.shifty, (l) => l.s5o1)],
    ),
    TrekStage(
      id: 'serpent-gorge',
      emoji: '🐍',
      location: ChallengeLocation.gorge,
      title: (l) => l.stage6Title,
      blurb: (l) => l.stage6Blurb,
      loot: 'outfit.tail',
      waves: const [
        [EnemySpec.snake(ScaleColor.yellow), EnemySpec.snake(ScaleColor.blue)],
        [
          EnemySpec.snake(ScaleColor.green),
          EnemySpec.medic(ScaleColor.yellow),
          EnemySpec.snake(ScaleColor.blue),
        ],
        [
          EnemySpec.chameleon(vanisher: true),
          EnemySpec.snake(ScaleColor.blue),
          EnemySpec.skink(),
        ],
      ],
      goals: const [
        StageGoal(GoalKind.health, 30),
        StageGoal(GoalKind.combo, 6),
      ],
      intro: [
        (Character.hiss, (l) => l.s6i1),
        (Character.coco, (l) => l.s6i2),
        (Character.carlos, (l) => l.s6i3),
      ],
      outro: [(Character.hiss, (l) => l.s6o1)],
    ),
    TrekStage(
      id: 'throne-of-scales',
      emoji: '👑',
      location: ChallengeLocation.throne,
      title: (l) => l.stage7Title,
      blurb: (l) => l.stage7Blurb,
      loot: 'hat.lizardcrown',
      waves: const [
        [EnemySpec.king()],
      ],
      goals: const [
        StageGoal(GoalKind.blocks, 3),
        StageGoal(GoalKind.health, 25),
      ],
      intro: [
        (Character.komo, (l) => l.s7i1),
        (Character.komo, (l) => l.s7i2),
        (Character.carlos, (l) => l.s7i3),
        (Character.komo, (l) => l.s7i4),
        (Character.komo, (l) => l.s7i5),
      ],
      phaseLines: [
        (Character.komo, (l) => l.s7p2),
        (Character.komo, (l) => l.s7p3),
      ],
      outro: [
        (Character.komo, (l) => l.s7o1),
        (Character.komo, (l) => l.s7o2),
        (Character.carlos, (l) => l.s7o3),
        (Character.coco, (l) => l.s7o4),
      ],
    ),
  ];
}
