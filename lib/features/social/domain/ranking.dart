import 'package:pushup_bro/features/social/model/day_score.dart';

/// Today's scores best first; on a tie, whoever got there first.
List<DayScore> rank(Iterable<DayScore> scores) => scores.toList()
  ..sort((a, b) {
    final byCount = b.count.compareTo(a.count);
    return byCount != 0 ? byCount : a.updatedAt.compareTo(b.updatedAt);
  });

/// The next small win on today's board.
sealed class NextWin {
  const NextWin();
}

/// [more] pushups pass [ahead].
class PassNext extends NextWin {
  const PassNext({required this.ahead, required this.more});

  final DayScore ahead;
  final int more;
}

/// Already first: defend the crown.
class OnTop extends NextWin {
  const OnTop();
}

/// What [uid] needs to move up a place in [ranked] (from [rank]), or null
/// when they aren't on it.
NextWin? nextWin(List<DayScore> ranked, String uid) {
  final at = ranked.indexWhere((s) => s.uid == uid);
  if (at < 0) return null;
  if (at == 0) return const OnTop();
  final ahead = ranked[at - 1];
  // A tie is lost to whoever was first, so one more passes them.
  return PassNext(ahead: ahead, more: ahead.count - ranked[at].count + 1);
}
