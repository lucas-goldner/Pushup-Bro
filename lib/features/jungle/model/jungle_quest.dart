import 'dart:ui' show Color;

import 'package:pushup_bro/core/model/quest_log.dart';
import 'package:pushup_bro/generated/l10n.dart';

/// Who talks in the jungle's stories.
enum Character {
  carlos('🦍', Color(0xFF3B3A45)),
  coco('🦜', Color(0xFFE5534B)),
  shelldon('🐢', Color(0xFF2FA37A)),
  jag('🐆', Color(0xFFE8A33D)),
  stranger('🕶️', Color(0xFF5B3FB5)),
  zip('🦎', Color(0xFF4FB35A)),
  skitter('🦎', Color(0xFFE0A21F)),
  frostbite('🦎', Color(0xFF4F9BE0)),
  snap('🐊', Color(0xFF2F8443)),
  shifty('🦎', Color(0xFF8B5FD9)),
  hiss('🐍', Color(0xFFC2457A)),
  komo('👑', Color(0xFF2FA37A)),

  /// Grandpa Gus, chief of Carlos's tribe, in the island intro.
  gus('🦍', Color(0xFF6E7487));

  const Character(this.emoji, this.color);

  final String emoji;
  final Color color;

  String name(S l) => switch (this) {
        carlos => l.charCarlos,
        coco => l.charCoco,
        shelldon => l.charShelldon,
        jag => l.charJag,
        stranger => l.charStranger,
        zip => l.charZip,
        skitter => l.charSkitter,
        frostbite => l.charFrostbite,
        snap => l.charSnap,
        shifty => l.charShifty,
        hiss => l.charHiss,
        komo => l.charKomo,
        gus => l.charGus,
      };
}

/// Where a quest's challenge or a Trek stage happens.
enum ChallengeLocation {
  volcano('🌋'),
  moonBeach('🌕'),
  temple('🛕'),
  skyIsland('☁️'),
  fernTrail('🌿'),
  canopy('🌉'),
  swamp('🌫️'),
  lake('⛵'),
  gorge('🐍'),
  throne('👑');

  const ChallengeLocation(this.emoji);

  final String emoji;

  String name(S l) => switch (this) {
        volcano => l.locVolcano,
        moonBeach => l.locMoonBeach,
        temple => l.locTemple,
        skyIsland => l.locSkyIsland,
        fernTrail => l.locFernTrail,
        canopy => l.locCanopy,
        swamp => l.locSwamp,
        lake => l.locLake,
        gorge => l.locGorge,
        throne => l.locThrone,
      };
}

/// How a challenge is won.
sealed class ChallengeRule {
  const ChallengeRule(this.goal);

  /// Pushups (or held pushups) needed to win.
  final int goal;

  String summary(S l);
}

/// As many pushups as possible before the clock runs out.
class TimedRule extends ChallengeRule {
  const TimedRule({required int goal, required this.seconds}) : super(goal);

  final int seconds;

  @override
  String summary(S l) => l.ruleTimed(goal, seconds);
}

/// Pushups only count when held at the bottom for [seconds].
class HoldRule extends ChallengeRule {
  const HoldRule({required int goal, required this.seconds}) : super(goal);

  final double seconds;

  @override
  String summary(S l) => l.ruleHold(goal, seconds.round());
}

/// Reach [goal] pushups; the set ends there.
class TargetRule extends ChallengeRule {
  const TargetRule({required int goal}) : super(goal);

  @override
  String summary(S l) => l.ruleTarget(goal);
}

/// A line of a story: who says what.
typedef Line = (Character speaker, String Function(S l) text);

/// A daily jungle quest: a little story played as a cutscene, then a
/// pushup challenge at [location], then an ending depending on the result.
class JungleQuest {
  JungleQuest({
    required this.id,
    required this.title,
    required this.teaser,
    required this.location,
    required this.guest,
    required this.rule,
    required this.intro,
    required this.win,
    required this.lose,
    this.bonus = 30,
    this.bananaMultiplier = 1,
  });

  final String id;
  final String Function(S l) title;

  /// A sentence or two for the quest card.
  final String Function(S l) teaser;
  final ChallengeLocation location;

  /// Who Carlos meets.
  final Character guest;
  final ChallengeRule rule;
  final List<Line> intro;
  final List<Line> win;
  final List<Line> lose;

  /// Extra bananas for winning.
  final int bonus;

  /// Bananas per pushup, when won.
  final int bananaMultiplier;

  /// Bananas earned for [pushups] pushups.
  int reward({required int pushups, required bool won}) =>
      won ? pushups * bananaMultiplier + bonus : pushups;

  /// Today's quest; a new one every day, round and round.
  static JungleQuest forDay(DateTime date) => all[dayNumber(date) % all.length];

  static JungleQuest? byId(String id) {
    for (final quest in all) {
      if (quest.id == id) return quest;
    }

    return null;
  }

  static final all = <JungleQuest>[
    JungleQuest(
      id: 'volcano-hiccups',
      title: (l) => l.q1Title,
      teaser: (l) => l.q1Teaser,
      location: ChallengeLocation.volcano,
      guest: Character.coco,
      rule: const TimedRule(goal: 10, seconds: 30),
      bonus: 40,
      intro: [
        (Character.coco, (l) => l.q1i1),
        (Character.carlos, (l) => l.q1i2),
        (Character.coco, (l) => l.q1i3),
        (Character.coco, (l) => l.q1i4),
        (Character.carlos, (l) => l.q1i5),
        (Character.coco, (l) => l.q1i6),
      ],
      win: [
        (Character.coco, (l) => l.q1w1),
        (Character.carlos, (l) => l.q1w2),
      ],
      lose: [
        (Character.coco, (l) => l.q1l1),
        (Character.carlos, (l) => l.q1l2),
      ],
    ),
    JungleQuest(
      id: 'wishing-moon',
      title: (l) => l.q2Title,
      teaser: (l) => l.q2Teaser,
      location: ChallengeLocation.moonBeach,
      guest: Character.shelldon,
      rule: const HoldRule(goal: 5, seconds: 3),
      bonus: 50,
      intro: [
        (Character.shelldon, (l) => l.q2i1),
        (Character.carlos, (l) => l.q2i2),
        (Character.shelldon, (l) => l.q2i3),
        (Character.shelldon, (l) => l.q2i4),
        (Character.carlos, (l) => l.q2i5),
        (Character.shelldon, (l) => l.q2i6),
      ],
      win: [
        (Character.shelldon, (l) => l.q2w1),
        (Character.carlos, (l) => l.q2w2),
      ],
      lose: [(Character.shelldon, (l) => l.q2l1)],
    ),
    JungleQuest(
      id: 'jag-bet',
      title: (l) => l.q3Title,
      teaser: (l) => l.q3Teaser,
      location: ChallengeLocation.temple,
      guest: Character.jag,
      rule: const TargetRule(goal: 20),
      bonus: 20,
      bananaMultiplier: 2,
      intro: [
        (Character.jag, (l) => l.q3i1),
        (Character.carlos, (l) => l.q3i2),
        (Character.jag, (l) => l.q3i3),
        (Character.jag, (l) => l.q3i4),
        (Character.carlos, (l) => l.q3i5),
      ],
      win: [
        (Character.jag, (l) => l.q3w1),
        (Character.jag, (l) => l.q3w2),
        (Character.carlos, (l) => l.q3w3),
      ],
      lose: [(Character.jag, (l) => l.q3l1)],
    ),
    JungleQuest(
      id: 'rainbow-bridge',
      title: (l) => l.q4Title,
      teaser: (l) => l.q4Teaser,
      location: ChallengeLocation.skyIsland,
      guest: Character.coco,
      rule: const TargetRule(goal: 15),
      bonus: 40,
      intro: [
        (Character.coco, (l) => l.q4i1),
        (Character.carlos, (l) => l.q4i2),
        (Character.coco, (l) => l.q4i3),
        (Character.carlos, (l) => l.q4i4),
      ],
      win: [
        (Character.coco, (l) => l.q4w1),
        (Character.carlos, (l) => l.q4w2),
      ],
      lose: [(Character.coco, (l) => l.q4l1)],
    ),
    JungleQuest(
      id: 'masked-monkey',
      title: (l) => l.q5Title,
      teaser: (l) => l.q5Teaser,
      location: ChallengeLocation.moonBeach,
      guest: Character.stranger,
      rule: const TimedRule(goal: 12, seconds: 45),
      bananaMultiplier: 2,
      intro: [
        (Character.stranger, (l) => l.q5i1),
        (Character.carlos, (l) => l.q5i2),
        (Character.stranger, (l) => l.q5i3),
        (Character.stranger, (l) => l.q5i4),
        (Character.stranger, (l) => l.q5i5),
      ],
      win: [
        (Character.stranger, (l) => l.q5w1),
        (Character.carlos, (l) => l.q5w2),
      ],
      lose: [(Character.stranger, (l) => l.q5l1)],
    ),
  ];
}
