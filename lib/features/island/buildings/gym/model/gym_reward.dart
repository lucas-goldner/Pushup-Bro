import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/features/island/buildings/gym/model/gym_challenge.dart';

/// Gym gear, handed out one piece per week-long gym streak, in this order.
const kGymGear = [
  'hat.sweatband',
  'outfit.wristbands',
  'outfit.tank',
  'eyes.visor',
  'hat.cap',
];

/// A gift every this many days of gym streak.
const kGymGiftEvery = 7;

/// Bananas instead of gear once all of it is owned.
const kGymGiftBananas = 150;

/// What a finished gym workout earns.
class GymReward {
  const GymReward({
    required this.bananas,
    required this.inventory,
    this.gift,
    this.crate = 0,
    this.streak = 0,
  });

  /// Settles a workout of [challenge] with [pushups] done on [now].
  /// A [replay] (today's already won) earns a banana a pushup and nothing
  /// else; a win grows the streak, and every [kGymGiftEvery] days of it
  /// brings the next piece of [kGymGear].
  factory GymReward.settle({
    required GameInventory inventory,
    required GymChallenge challenge,
    required int pushups,
    required bool won,
    required bool replay,
    required DateTime now,
  }) {
    if (replay || !won) {
      return GymReward(
        bananas: pushups,
        inventory: inventory.copyWith(bananas: inventory.bananas + pushups),
        streak: inventory.gym.streakOn(now),
      );
    }

    final log = inventory.gym.complete(challenge.kind.name, now);
    var bananas = challenge.reward(pushups: pushups, won: true);
    String? gift;
    var crate = 0;
    if (log.streak % kGymGiftEvery == 0) {
      gift = kGymGear.where((id) => !inventory.owns(id)).firstOrNull;
      if (gift == null) crate = kGymGiftBananas;
    }
    bananas += crate;

    return GymReward(
      bananas: bananas,
      gift: gift,
      crate: crate,
      streak: log.streak,
      inventory: inventory.copyWith(
        bananas: inventory.bananas + bananas,
        ownedCosmetics:
            gift == null ? null : [...inventory.ownedCosmetics, gift],
        gym: log,
      ),
    );
  }

  final int bananas;

  /// The cosmetic id of the gear won, if any.
  final String? gift;

  /// Bananas in the streak crate (counted in [bananas]), given instead of
  /// gear once all of it is owned.
  final int crate;

  /// The gym streak after this workout.
  final int streak;

  /// The inventory with everything added.
  final GameInventory inventory;
}

/// Days until the next gear gift for a streak of [streak].
int daysToGymGift(int streak) => kGymGiftEvery - streak % kGymGiftEvery;
