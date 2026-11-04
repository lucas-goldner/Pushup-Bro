import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/model/night.dart';
import 'package:pushup_bro/core/model/quest_log.dart';
import 'package:pushup_bro/features/jungle/model/jungle_quest.dart';

/// The story music at a daily quest's [location].
MusicTrack questMusic(ChallengeLocation location) => switch (location) {
      ChallengeLocation.volcano => MusicTrack.questVolcano,
      ChallengeLocation.moonBeach => MusicTrack.questMoonBeach,
      ChallengeLocation.temple => MusicTrack.questTemple,
      ChallengeLocation.skyIsland => MusicTrack.questSkyIsland,
      _ => MusicTrack.story,
    };

/// The fight music at a Jungle Trek stage's [location]; the King's throne
/// (and any boss) gets the boss theme.
MusicTrack trekMusic(ChallengeLocation location, {bool boss = false}) {
  if (boss) return MusicTrack.boss;

  return switch (location) {
    ChallengeLocation.fernTrail => MusicTrack.trekFernTrail,
    ChallengeLocation.canopy => MusicTrack.trekCanopy,
    ChallengeLocation.swamp => MusicTrack.trekSwamp,
    ChallengeLocation.lake => MusicTrack.trekLake,
    ChallengeLocation.temple => MusicTrack.trekTemple,
    ChallengeLocation.gorge => MusicTrack.trekGorge,
    ChallengeLocation.throne => MusicTrack.boss,
    _ => MusicTrack.battle,
  };
}

/// The island's music at [now]: the night lullaby from 8 pm to 6 am, and by
/// day one of the two island themes, swapping each day.
MusicTrack islandMusic(DateTime now) {
  if (isNight(now)) return MusicTrack.islandNight;

  return dayNumber(now).isEven ? MusicTrack.island : MusicTrack.islandAlt;
}
