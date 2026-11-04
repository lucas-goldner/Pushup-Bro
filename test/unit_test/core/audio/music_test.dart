import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/audio/music_places.dart';
import 'package:pushup_bro/features/jungle/model/jungle_quest.dart';
import 'package:pushup_bro/features/trek/model/trek.dart';

void main() {
  test('every track has its file', () {
    for (final track in MusicTrack.values) {
      expect(
        File('assets/${track.asset}').existsSync(),
        isTrue,
        reason: '$track',
      );
    }
  });

  test('fallbacks end at a looping place track', () {
    for (final track in MusicTrack.values) {
      var t = track;
      final seen = <MusicTrack>{};
      while (t.fallback != null) {
        expect(seen.add(t), isTrue, reason: 'loop at $track');
        t = t.fallback!;
      }
    }
  });

  test('every quest and Trek stage has its own music', () {
    for (final quest in JungleQuest.all) {
      expect(questMusic(quest.location), isNot(MusicTrack.story));
    }
    for (final stage in TrekStage.all) {
      expect(
        trekMusic(stage.location, boss: stage.boss),
        isNot(MusicTrack.battle),
      );
    }
    expect(
      trekMusic(ChallengeLocation.fernTrail, boss: true),
      MusicTrack.boss,
    );
  });

  test('the island plays the night theme after dark', () {
    expect(islandMusic(DateTime(2026, 11, 3, 22)), MusicTrack.islandNight);
    expect(islandMusic(DateTime(2026, 11, 3, 5)), MusicTrack.islandNight);
    final days = {
      islandMusic(DateTime(2026, 11, 3, 12)),
      islandMusic(DateTime(2026, 11, 4, 12)),
    };
    expect(days, {MusicTrack.island, MusicTrack.islandAlt});
  });
}
