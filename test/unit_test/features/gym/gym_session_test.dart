import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/features/island/buildings/gym/model/gym_challenge.dart';
import 'package:pushup_bro/features/island/buildings/gym/model/gym_session.dart';

const _average = GymStrength(typical: 10, best: 15);

GymSession _session(GymChallengeKind kind, [GymStrength strength = _average]) =>
    GymSession(GymChallenge.build(kind, strength));

void main() {
  group('pyramid', () {
    test('steps up and down, resting between steps', () {
      final session = _session(GymChallengeKind.pyramid);
      expect(session.currentSet!.reps, 1);
      expect(session.rep(1), RepVerdict.counted);
      // Step 1 done: a rest before step 2.
      expect(session.block, isA<RestBlock>());
      expect(session.currentSet!.reps, 2);
      // Pushups in a rest don't count.
      expect(session.rep(2), RepVerdict.ignored);
      expect(session.counted, 1);
      session.tick(9.5);
      expect(session.block, isA<RepBlock>());
      expect(session.setIndex, 1);
      session
        ..rep(10)
        ..rep(11);
      expect(session.results[0], isTrue);
      expect(session.results[2], isTrue);
      expect(session.setIndex, 2);
    });

    test('is won once every step is climbed', () {
      final session = _session(GymChallengeKind.pyramid);
      var t = 0.0;
      while (!session.finished) {
        t += 1;
        session
          ..tick(t)
          ..rep(t);
      }
      expect(session.won, isTrue);
      expect(session.counted, 25);
    });

    test('finishing early fails the steps left', () {
      final session = _session(GymChallengeKind.pyramid)
        ..rep(1)
        ..finish();
      expect(session.finished, isTrue);
      expect(session.won, isFalse);
      expect(session.passed, 1);
    });
  });

  group('EMOM', () {
    test('rests out each minute once its reps are done', () {
      final session = _session(GymChallengeKind.emom);
      final reps = session.currentSet!.reps;
      expect(reps, 4);
      for (var i = 0; i < reps; i++) {
        session.rep(2.0 + i);
      }
      expect(session.blockDone, isTrue);
      expect(session.blockIndex, 0);
      // More in the same minute don't carry over.
      expect(session.rep(10), RepVerdict.ignored);
      expect(session.remaining(30), 30);
      session.tick(60.1);
      expect(session.blockIndex, 1);
      expect(session.blockReps, 0);
      expect(session.remaining(60.1), closeTo(59.9, 0.001));
    });

    test('a minute without its reps is missed, and the workout lost', () {
      final session = _session(GymChallengeKind.emom)
        ..rep(1)
        ..rep(2)
        ..tick(61);
      expect(session.results.first, isFalse);
      // EMOM needs every minute: there's no winning it now.
      expect(session.finished, isTrue);
      expect(session.won, isFalse);
    });

    test('five full minutes win it, ending with the last reps', () {
      final session = _session(GymChallengeKind.emom);
      for (var minute = 0; minute < 5; minute++) {
        session.tick(minute * 60.0 + 0.5);
        for (var i = 0; i < 4; i++) {
          session.rep(minute * 60.0 + 1 + i);
        }
      }
      expect(session.finished, isTrue);
      expect(session.won, isTrue);
      expect(session.counted, 20);
    });
  });

  group('tempo', () {
    test('only counts reps lowered slowly enough', () {
      final session = _session(GymChallengeKind.tempo);
      expect(session.rep(3, downSeconds: 1.2), RepVerdict.tooFast);
      expect(session.rushed, 1);
      expect(session.counted, 0);
      expect(
        session.rep(7, downSeconds: kTempoMinSeconds),
        RepVerdict.counted,
      );
      expect(session.rep(12, downSeconds: 3.4), RepVerdict.counted);
      expect(session.counted, 2);
    });

    test('is won after its slow reps', () {
      final session = _session(GymChallengeKind.tempo);
      final goal = session.currentSet!.reps;
      for (var i = 0; i < goal; i++) {
        session.rep(i * 5.0, downSeconds: 3);
      }
      expect(session.finished, isTrue);
      expect(session.won, isTrue);
    });
  });

  group('max set', () {
    test('passes at one more than the best and keeps counting', () {
      final session = _session(GymChallengeKind.maxSet);
      for (var i = 0; i < 18; i++) {
        session.rep(i * 1.5);
      }
      expect(session.won, isTrue);
      expect(session.finished, isFalse);
      expect(session.counted, 18);
    });

    test('ends after a long pause, but not before the first rep', () {
      final session = _session(GymChallengeKind.maxSet)..tick(30);
      expect(session.finished, isFalse);
      session.rep(31);
      expect(session.idleLeft(35), 4);
      session.tick(39.1);
      expect(session.finished, isTrue);
      expect(session.won, isFalse);
    });
  });

  group('timed sets', () {
    test('the burner counts until its two minutes are up', () {
      final session = _session(GymChallengeKind.burner);
      final goal = session.currentSet!.reps;
      for (var i = 0; i < goal + 5; i++) {
        session.rep(i * 2.0);
      }
      expect(session.finished, isFalse);
      session.tick(120);
      expect(session.finished, isTrue);
      expect(session.won, isTrue);
      expect(session.counted, goal + 5);
    });

    test("Gus's drill forgives one missed call, not two", () {
      final session = _session(GymChallengeKind.gusDrill);
      final window = session.currentSet!.window!;
      session.tick(window);
      expect(session.results.first, isFalse);
      expect(session.finished, isFalse);
      // The rest, then call two runs out too.
      session.tick(window + 12 + session.currentSet!.window!);
      expect(session.finished, isTrue);
      expect(session.won, isFalse);
    });
  });

  group('plank and press', () {
    test('ignores pushups during the plank', () {
      final session = _session(GymChallengeKind.plankPress);
      final plank = session.block! as PlankBlock;
      expect(session.rep(2), RepVerdict.ignored);
      expect(session.remaining(5), plank.seconds - 5);
      session.tick(plank.seconds);
      expect(session.block, isA<RepBlock>());
      expect(session.rep(plank.seconds + 1), RepVerdict.counted);
    });
  });

  group('deck of cards', () {
    test('deals card after card', () {
      final session = _session(GymChallengeKind.deckOfCards);
      final first = session.currentSet!;
      expect(first.tag, isNotNull);
      for (var i = 0; i < first.reps; i++) {
        session.rep(i + 1.0);
      }
      expect(session.results.first, isTrue);
      expect(session.block, isA<RestBlock>());
      expect(session.currentSet, isNot(same(first)));
    });
  });
}
