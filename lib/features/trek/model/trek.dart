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

/// One enemy in a wave. A null [color] shifts between all three.
class EnemySpec {
  const EnemySpec(
    this.species,
    this.color, {
    required this.hp,
    required this.attack,
    required this.attackEvery,
    required this.xp,
  });

  const EnemySpec.gecko([ScaleColor color = ScaleColor.green])
      : this(Species.gecko, color, hp: 30, attack: 6, attackEvery: 9, xp: 12);
  const EnemySpec.skink([ScaleColor color = ScaleColor.yellow])
      : this(Species.skink, color, hp: 36, attack: 5, attackEvery: 6, xp: 15);
  const EnemySpec.iguana([ScaleColor color = ScaleColor.blue])
      : this(Species.iguana, color, hp: 60, attack: 9, attackEvery: 11, xp: 22);
  const EnemySpec.croc(ScaleColor color)
      : this(Species.croc, color, hp: 75, attack: 11, attackEvery: 11, xp: 28);
  const EnemySpec.chameleon()
      : this(
          Species.chameleon,
          null,
          hp: 70,
          attack: 8,
          attackEvery: 9,
          xp: 30,
        );
  const EnemySpec.snake(ScaleColor color)
      : this(Species.snake, color, hp: 65, attack: 10, attackEvery: 8, xp: 26);
  const EnemySpec.king()
      : this(
          Species.king,
          ScaleColor.green,
          hp: 840,
          attack: 12,
          attackEvery: 8,
          xp: 300,
        );

  final Species species;
  final ScaleColor? color;
  final double hp;
  final double attack;

  /// Seconds between its attacks.
  final double attackEvery;
  final int xp;
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

  bool get boss =>
      waves.any((wave) => wave.any((e) => e.species == Species.king));

  int get number => all.indexOf(this) + 1;

  static TrekStage? byId(String id) {
    for (final stage in all) {
      if (stage.id == id) return stage;
    }

    return null;
  }

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
        [EnemySpec.gecko(), EnemySpec.gecko()],
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
        [EnemySpec.iguana(), EnemySpec.gecko()],
        [EnemySpec.iguana(), EnemySpec.skink()],
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
        [EnemySpec.croc(ScaleColor.blue), EnemySpec.croc(ScaleColor.green)],
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
        [EnemySpec.chameleon(), EnemySpec.iguana()],
        [EnemySpec.chameleon(), EnemySpec.chameleon()],
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
          EnemySpec.snake(ScaleColor.yellow),
          EnemySpec.snake(ScaleColor.blue),
        ],
        [
          EnemySpec.chameleon(),
          EnemySpec.snake(ScaleColor.blue),
          EnemySpec.skink(),
        ],
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
