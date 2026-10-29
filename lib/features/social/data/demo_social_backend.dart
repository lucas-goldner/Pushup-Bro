import 'dart:math' as math;

import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/features/social/data/fake_social_backend.dart';
import 'package:pushup_bro/features/social/domain/bro_name.dart';
import 'package:pushup_bro/features/social/domain/friend_code.dart';
import 'package:pushup_bro/features/social/domain/local_day.dart';
import 'package:pushup_bro/features/social/model/bro_profile.dart';
import 'package:pushup_bro/features/social/model/day_score.dart';
import 'package:pushup_bro/features/social/model/inbox_item.dart';

const _codes = {
  'mia': 'MAZ9QK',
  'jonas': 'J7N4SX',
  'yuki': 'Y8K2UP',
  'leo': 'L3E6VR',
  'sam': 'S5M8TW',
  'nina': 'N4N8BR',
};

/// A [FakeSocialBackend] with bros to look at: for previews and
/// screenshots (`--dart-define=SOCIAL_DEMO=true`), never in a release.
FakeSocialBackend demoSocialBackend({DateTime? now}) {
  final today = now ?? DateTime.now();
  final day = localDayKey(today);
  final backend = FakeSocialBackend();
  final at = today.subtract(const Duration(hours: 2));

  void bro(
    String uid,
    String name,
    BroName broName,
    MonkeyLook look, {
    required int today,
    required int streak,
    required int level,
    bool friend = true,
  }) {
    final code = _codes[uid] ??
        FriendCode.generate(
          math.Random(uid.codeUnits.fold<int>(0, (a, b) => a * 31 + b)),
        );
    backend
      ..profiles[uid] = BroProfile(
        uid: uid,
        broName: broName,
        code: code,
        look: look,
        streak: streak,
        total: today * 20,
        islandLevel: level,
        friendCount: 4,
      )
      ..codes[code] = uid
      ..friendNames[uid] = name;
    if (friend) {
      (backend.friendEdges['me'] ??= {}).add(uid);
      (backend.friendEdges[uid] ??= {}).add('me');
    }
    if (today > 0) {
      (backend.scores[day] ??= {})[uid] = DayScore(
        uid: uid,
        count: today,
        broName: broName,
        look: look,
        streak: streak,
        updatedAt: at.add(Duration(minutes: uid.length)),
      );
    }
  }

  bro(
    'mia',
    'Mia',
    const BroName(7, 2, 3114),
    const MonkeyLook(fur: 'fur.bubblegum', eyewear: 'eyes.hearts'),
    today: 142,
    streak: 21,
    level: 7,
  );
  bro(
    'jonas',
    'Jonas',
    const BroName(15, 1, 2210),
    const MonkeyLook(hat: 'hat.crown'),
    today: 120,
    streak: 9,
    level: 5,
  );
  bro(
    'yuki',
    'Yuki',
    const BroName(3, 3, 4402),
    const MonkeyLook(fur: 'fur.slate', hat: 'hat.cowboy'),
    today: 64,
    streak: 3,
    level: 4,
  );
  bro(
    'leo',
    'Leo',
    const BroName(6, 6, 3307),
    const MonkeyLook(fur: 'fur.ginger'),
    today: 40,
    streak: 1,
    level: 3,
  );
  bro(
    'sam',
    'Sam',
    const BroName(5, 5, 8061),
    const MonkeyLook(fur: 'fur.midnight', hat: 'hat.wizard'),
    today: 0,
    streak: 30,
    level: 6,
  );
  bro(
    'nina',
    'Nina',
    const BroName(9, 13, 5120),
    const MonkeyLook(fur: 'fur.mint', hat: 'hat.flowers'),
    today: 75,
    streak: 12,
    level: 5,
    friend: false,
  );
  for (final (i, (score, look)) in [
    (610, const MonkeyLook(fur: 'fur.jade')),
    (540, const MonkeyLook(hat: 'hat.crown')),
    (498, const MonkeyLook(fur: 'fur.golden')),
    (455, const MonkeyLook(fur: 'fur.snow')),
    (430, const MonkeyLook(fur: 'fur.bubblegum')),
    (418, const MonkeyLook(fur: 'fur.midnight')),
    (401, const MonkeyLook(fur: 'fur.ginger')),
  ].indexed) {
    bro(
      'top$i',
      '',
      BroName((i * 5) % 16, (i * 3 + 1) % 16, 7781 - i * 977),
      look,
      today: score,
      streak: 10 + i,
      level: 8,
      friend: false,
    );
  }
  (backend.scores[day] ??= {})['me'] = DayScore(
    uid: 'me',
    count: 85,
    broName: const BroName(0, 0, 4821),
    updatedAt: at,
  );
  backend.inboxes['me'] = {
    'wave_mia': InboxItem(
      id: 'wave_mia',
      kind: InboxKind.wave,
      fromUid: 'mia',
      fromName: 'Mia',
      sentAt: at,
    ),
  };
  return backend;
}
