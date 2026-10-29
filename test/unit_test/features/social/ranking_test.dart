import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/features/social/domain/bro_name.dart';
import 'package:pushup_bro/features/social/domain/local_day.dart';
import 'package:pushup_bro/features/social/domain/ranking.dart';
import 'package:pushup_bro/features/social/model/day_score.dart';

DayScore score(String uid, int count, {int minute = 0}) => DayScore(
      uid: uid,
      count: count,
      broName: const BroName(0, 0, 1),
      updatedAt: DateTime(2026, 10, 29, 12, minute),
    );

void main() {
  test('ranks the most pushups first', () {
    final ranked = rank([score('a', 40), score('b', 142), score('c', 85)]);
    expect(ranked.map((s) => s.uid), ['b', 'c', 'a']);
  });

  test('a tie goes to whoever got there first', () {
    final ranked = rank([
      score('late', 100, minute: 30),
      score('early', 100, minute: 5),
    ]);
    expect(ranked.map((s) => s.uid), ['early', 'late']);
  });

  test('the next win is one more than the bro ahead', () {
    final ranked = rank([score('jonas', 120), score('me', 85)]);
    final win = nextWin(ranked, 'me')! as PassNext;
    expect(win.ahead.uid, 'jonas');
    expect(win.more, 36);
  });

  test('a tie still needs one more', () {
    final ranked = rank([
      score('jonas', 85, minute: 1),
      score('me', 85, minute: 2),
    ]);
    expect((nextWin(ranked, 'me')! as PassNext).more, 1);
  });

  test('first place defends the crown', () {
    final ranked = rank([score('me', 200), score('jonas', 120)]);
    expect(nextWin(ranked, 'me'), isA<OnTop>());
  });

  test('no win for someone not on the board', () {
    expect(nextWin(rank([score('a', 1)]), 'me'), isNull);
  });

  group('local day', () {
    test('is the calendar day, padded', () {
      expect(localDayKey(DateTime(2026, 3, 7, 9)), '2026-03-07');
    });

    test('changes at midnight, not before', () {
      expect(localDayKey(DateTime(2026, 10, 29, 23, 59, 59)), '2026-10-29');
      expect(localDayKey(DateTime(2026, 10, 30)), '2026-10-30');
    });

    test('counts down to midnight', () {
      expect(
        untilMidnight(DateTime(2026, 10, 29, 17, 48)),
        const Duration(hours: 6, minutes: 12),
      );
    });
  });
}
