import 'dart:ui' show Color;

import 'package:pushup_bro/core/model/quest_log.dart';

/// Who talks in the jungle's stories.
enum Character {
  carlos('Carlos', '🦍', Color(0xFF3B3A45)),
  coco('Coco', '🦜', Color(0xFFE5534B)),
  shelldon('Sir Shelldon', '🐢', Color(0xFF2FA37A)),
  jag('Jag', '🐆', Color(0xFFE8A33D)),
  stranger('???', '🕶️', Color(0xFF5B3FB5));

  const Character(this.displayName, this.emoji, this.color);

  final String displayName;
  final String emoji;
  final Color color;
}

/// Where a quest's challenge happens.
enum ChallengeLocation {
  volcano('Mount Burpee', '🌋'),
  moonBeach('Moonlit Beach', '🌕'),
  temple('Temple of the Golden Banana', '🛕'),
  skyIsland('Cloud Island', '☁️');

  const ChallengeLocation(this.displayName, this.emoji);

  final String displayName;
  final String emoji;
}

/// How a challenge is won.
sealed class ChallengeRule {
  const ChallengeRule(this.goal);

  /// Pushups (or held pushups) needed to win.
  final int goal;

  String get summary;
}

/// As many pushups as possible before the clock runs out.
class TimedRule extends ChallengeRule {
  const TimedRule({required int goal, required this.seconds}) : super(goal);

  final int seconds;

  @override
  String get summary => '$goal pushups in $seconds seconds';
}

/// Pushups only count when held at the bottom for [seconds].
class HoldRule extends ChallengeRule {
  const HoldRule({required int goal, required this.seconds}) : super(goal);

  final double seconds;

  @override
  String get summary =>
      '$goal pushups, holding each for ${seconds.toStringAsFixed(0)} seconds';
}

/// Reach [goal] pushups; the set ends there.
class TargetRule extends ChallengeRule {
  const TargetRule({required int goal}) : super(goal);

  @override
  String get summary => 'Reach $goal pushups';
}

/// A line of a story: who says what.
typedef Line = (Character speaker, String text);

/// A daily jungle quest: a little story played as a cutscene, then a
/// pushup challenge at [location], then an ending depending on the result.
class JungleQuest {
  const JungleQuest({
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
  final String title;

  /// A sentence or two for the quest card.
  final String teaser;
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

  static const all = <JungleQuest>[
    JungleQuest(
      id: 'volcano-hiccups',
      title: "Mount Burpee's Hiccups",
      teaser: 'The volcano has the hiccups and is sneezing lava on '
          "Coco's nest. Only super fast pushups can scare them away.",
      location: ChallengeLocation.volcano,
      guest: Character.coco,
      rule: TimedRule(goal: 10, seconds: 30),
      bonus: 40,
      intro: [
        (Character.coco, 'CARLOS! Code red! Mount Burpee has the hiccups!'),
        (Character.carlos, 'Volcanoes get hiccups?!'),
        (
          Character.coco,
          'Every time it hics, it sneezes lava on my nest. Rude.',
        ),
        (
          Character.coco,
          'Legend says only a gorilla doing super fast pushups can scare '
              'hiccups away.',
        ),
        (Character.carlos, 'Fast pushups? I was BORN for this.'),
        (
          Character.coco,
          'Ten pushups in thirty seconds. Go fast. Go furious. Go… banana.',
        ),
      ],
      win: [
        (
          Character.coco,
          'It worked! The volcano burped out… a message in a bottle?!',
        ),
        (
          Character.carlos,
          '"We\'re out there. Keep growing the island. — The Banana '
              'Brigade." My friends are alive!',
        ),
      ],
      lose: [
        (Character.coco, '…hic. Still hiccuping. My poor nest.'),
        (Character.carlos, "I'll be back tomorrow, faster than ever!"),
      ],
    ),
    JungleQuest(
      id: 'wishing-moon',
      title: 'The Wishing Moon',
      teaser: 'Sir Shelldon says the full moon grants a wish to whoever '
          'holds their pushups slow and strong.',
      location: ChallengeLocation.moonBeach,
      guest: Character.shelldon,
      rule: HoldRule(goal: 5, seconds: 3),
      bonus: 50,
      intro: [
        (
          Character.shelldon,
          'Ahh… young Carlos… tonight… is the night… of the Wishing Moon…',
        ),
        (Character.carlos, 'Sir Shelldon! Are you… awake?'),
        (Character.shelldon, 'I have been awake… since 1824.'),
        (
          Character.shelldon,
          'The moon grants one wish… to whoever holds their pushups… slow… '
              'and strong… like a tortoise.',
        ),
        (Character.carlos, 'Then I wish to find my monkey friends!'),
        (
          Character.shelldon,
          'Hold each pushup at the bottom… three seconds. Five times. The '
              'moon… is watching.',
        ),
      ],
      win: [
        (
          Character.shelldon,
          'The moon smiles… Look… its reflection draws a map… east… beyond '
              'the reef.',
        ),
        (
          Character.carlos,
          "A map to my friends! I'll need a bigger island to get there…",
        ),
      ],
      lose: [
        (
          Character.shelldon,
          'Patience… even the moon… took four billion years… Return '
              'tomorrow.',
        ),
      ],
    ),
    JungleQuest(
      id: 'jag-bet',
      title: "Jag's Banana Bet",
      teaser: 'A show-off jaguar guards the Golden Banana and bets you '
          "can't do 20 pushups on his temple steps. Double bananas if you do.",
      location: ChallengeLocation.temple,
      guest: Character.jag,
      rule: TargetRule(goal: 20),
      bonus: 20,
      bananaMultiplier: 2,
      intro: [
        (
          Character.jag,
          'Well, well. The famous Carlos. I hear you do… pushups.',
        ),
        (Character.carlos, 'And who are you supposed to be?'),
        (
          Character.jag,
          'Jag. Fastest cat, biggest biceps, guardian of the Golden Banana.',
        ),
        (
          Character.jag,
          "I bet you can't do 20 pushups on my temple steps. Win, and I "
              'double your bananas.',
        ),
        (Character.carlos, 'Deal. Prepare to be out-pushed, kitty.'),
      ],
      win: [
        (
          Character.jag,
          '…Twenty. Fine. FINE. Take your double bananas.',
        ),
        (
          Character.jag,
          'Also… a monkey in a cape came through last week. Said she was '
              'looking for a gorilla.',
        ),
        (Character.carlos, 'A monkey in a cape?! That has to be Lulu!'),
      ],
      lose: [
        (
          Character.jag,
          'Ha! The Golden Banana stays with me. Come back when you have '
              'muscles.',
        ),
      ],
    ),
    JungleQuest(
      id: 'rainbow-bridge',
      title: 'The Rainbow Bridge',
      teaser: 'An island is floating in the sky! The rainbow bridge up '
          'runs on muscle power: every pushup paints a stripe.',
      location: ChallengeLocation.skyIsland,
      guest: Character.coco,
      rule: TargetRule(goal: 15),
      bonus: 40,
      intro: [
        (Character.coco, 'Carlos, look up! An island… IN THE SKY!'),
        (Character.carlos, "How do we get up there? I can't fly!"),
        (
          Character.coco,
          'The rainbow bridge runs on muscle power. Every pushup paints a '
              'stripe.',
        ),
        (
          Character.carlos,
          "Fifteen pushups, fifteen stripes. Let's paint the sky!",
        ),
      ],
      win: [
        (
          Character.coco,
          "We made it! Whoa, there's a tiny footprint up here… with a banana "
              'sticker on it.',
        ),
        (Character.carlos, "That's Lulu's sticker! She was HERE!"),
      ],
      lose: [
        (
          Character.coco,
          'The bridge faded… We need more stripes. Same time tomorrow?',
        ),
      ],
    ),
    JungleQuest(
      id: 'masked-monkey',
      title: 'The Masked Monkey',
      teaser: 'Someone in sunglasses is waiting on the beach at night. '
          'They say they know where your friends are.',
      location: ChallengeLocation.moonBeach,
      guest: Character.stranger,
      rule: TimedRule(goal: 12, seconds: 45),
      bananaMultiplier: 2,
      intro: [
        (Character.stranger, 'Psst. Gorilla. Over here.'),
        (
          Character.carlos,
          "Who's there? And why are you wearing sunglasses at night?",
        ),
        (
          Character.stranger,
          "Because I'm cool. And undercover. The Banana Brigade sent me.",
        ),
        (
          Character.stranger,
          "They can't come back until the island is ready for everyone. "
              'Keep building. Keep pushing.',
        ),
        (
          Character.stranger,
          "Twelve pushups before the tide comes in, and I'll double today's "
              'bananas.',
        ),
      ],
      win: [
        (
          Character.stranger,
          "Not bad, big guy. I'll tell them you're getting swole.",
        ),
        (Character.carlos, "Wait! Lulu, is that you?! …She's gone."),
      ],
      lose: [
        (Character.stranger, 'Too slow, big guy. The tide waits for no one.'),
      ],
    ),
  ];
}
