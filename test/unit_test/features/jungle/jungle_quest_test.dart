import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/model/cosmetics.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/model/quest_log.dart';
import 'package:pushup_bro/features/jungle/model/jungle_quest.dart';

void main() {
  group('JungleQuest', () {
    test('picks one quest per day, the same all day, then the next', () {
      final morning = JungleQuest.forDay(DateTime(2026, 10, 22, 7));
      final night = JungleQuest.forDay(DateTime(2026, 10, 22, 23, 59));
      final tomorrow = JungleQuest.forDay(DateTime(2026, 10, 23, 7));

      expect(night, same(morning));
      expect(tomorrow, isNot(same(morning)));
    });

    test('every quest has a full story and a unique id', () {
      final ids = JungleQuest.all.map((quest) => quest.id).toSet();

      expect(ids, hasLength(JungleQuest.all.length));
      for (final quest in JungleQuest.all) {
        expect(quest.intro, isNotEmpty, reason: quest.id);
        expect(quest.win, isNotEmpty, reason: quest.id);
        expect(quest.lose, isNotEmpty, reason: quest.id);
        expect(JungleQuest.byId(quest.id), same(quest));
      }
    });

    test('pays the bonus and multiplier only for a win', () {
      final bet = JungleQuest.byId('jag-bet')!;

      expect(bet.reward(pushups: 20, won: true), 20 * 2 + bet.bonus);
      expect(bet.reward(pushups: 12, won: false), 12);
    });
  });

  group('QuestLog', () {
    test('remembers the day a quest was completed', () {
      final log = const QuestLog()
          .complete('volcano-hiccups', DateTime(2026, 10, 22, 9))
          .complete('volcano-hiccups', DateTime(2026, 10, 23, 9));

      expect(log.completed['volcano-hiccups'], 2);
      expect(log.total, 2);
      expect(log.completedOn(DateTime(2026, 10, 23, 22)), isTrue);
      expect(log.completedOn(DateTime(2026, 10, 24)), isFalse);
    });
  });

  group('Cosmetics', () {
    test('have unique ids, and every slot a free default', () {
      final ids = Cosmetic.all.map((cosmetic) => cosmetic.id).toSet();
      expect(ids, hasLength(Cosmetic.all.length));

      const look = MonkeyLook();
      for (final slot in CosmeticSlot.values) {
        final first = Cosmetic.inSlot(slot).first;
        expect(first.free, isTrue, reason: slot.name);
        expect(look.idFor(slot), first.id, reason: slot.name);
      }
    });

    test('colours have a colour, wearables a picture', () {
      for (final cosmetic in Cosmetic.all) {
        switch (cosmetic.slot) {
          case CosmeticSlot.fur || CosmeticSlot.face || CosmeticSlot.matColor:
            expect(cosmetic.color, isNotNull, reason: cosmetic.id);
          case CosmeticSlot.hat || CosmeticSlot.eyewear || CosmeticSlot.outfit:
            expect(cosmetic.emoji, isNotEmpty, reason: cosmetic.id);
          case CosmeticSlot.matPattern:
            break;
        }
      }
    });

    test('wearing a cosmetic changes only its slot', () {
      const look = MonkeyLook(fur: 'fur.mint');
      final crowned = look.wearing(Cosmetic.byId('hat.crown')!);

      expect(crowned.hat, 'hat.crown');
      expect(crowned.fur, 'fur.mint');
      expect(crowned.matPattern, look.matPattern);
    });

    test('a plain mat has no pattern, the others draw something', () {
      const base = Color(0xFF5E9EFF);
      bool drawsSomething(String pattern) => [
            for (var x = -0.4; x < 0.4; x += 0.02)
              for (var z = -0.8; z < 0.8; z += 0.02)
                matPatternColor(pattern, base, x, z),
          ].any((color) => color != null);

      expect(drawsSomething('pattern.solid'), isFalse);
      for (final pattern in Cosmetic.inSlot(CosmeticSlot.matPattern).skip(1)) {
        expect(drawsSomething(pattern.id), isTrue, reason: pattern.id);
      }
    });
  });
}
