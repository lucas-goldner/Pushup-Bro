import 'package:pushup_bro/core/model/shared_preferences_key.dart';
import 'package:pushup_bro/core/provider/shared_preferences_interface.dart';
import 'package:pushup_bro/features/social/domain/local_day.dart';
import 'package:pushup_bro/features/social/model/gift_drop.dart';

/// Whether a gift may be dropped on a friend's island.
enum DropCheck { ok, notEnoughBananas, alreadyDropped }

/// One drop per friend and day, paid from the player's own [bananas].
DropCheck checkDrop({
  required GiftKind gift,
  required int bananas,
  required bool droppedToday,
}) {
  if (droppedToday) return DropCheck.alreadyDropped;
  if (bananas < gift.cost) return DropCheck.notEnoughBananas;

  return DropCheck.ok;
}

/// How far a drop's time may be from now; the rules allow the same, so a
/// sender can't line up drops for days ahead.
const kDropClockSlack = Duration(hours: 36);

/// Opened drops are cleared once they are this old, after their id's day
/// is over for sure.
const kOpenedDropKeep = Duration(hours: 48);

/// What `firestore.rules` checks for a new drop by [sender], so the fake
/// backend refuses the same drops as Firebase.
bool isValidDrop(
  GiftDrop drop, {
  required String sender,
  required DateTime now,
}) =>
    drop.fromUid == sender &&
    RegExp('^drop_${RegExp.escape(sender)}_[0-9]{4}-[0-9]{2}-[0-9]{2}\$')
        .hasMatch(drop.id) &&
    drop.bananas <= kMaxDropBananas &&
    drop.fromName.length <= 24 &&
    !drop.opened &&
    drop.sentAt.difference(now).abs() <= kDropClockSlack;

/// The drops still to open, oldest first.
List<GiftDrop> waitingDrops(Iterable<GiftDrop> drops) => [
      ...drops.where((drop) => !drop.opened),
    ]..sort((a, b) => a.sentAt.compareTo(b.sentAt));

/// Opened drops old enough to clear away.
List<GiftDrop> staleDrops(Iterable<GiftDrop> drops, {required DateTime now}) =>
    [
      for (final drop in drops)
        if (drop.opened && now.difference(drop.sentAt) > kOpenedDropKeep) drop,
    ];

/// The friends the player dropped a gift for today, kept on the phone as
/// `2026-10-29:mia,jonas` (the rules can't tell the sender; only the
/// friend's island can).
Future<Set<String>> droppedToday(
  SharedPreferencesInterface prefs, {
  required DateTime now,
}) async {
  final saved = await prefs.getSharedPrefString(
    SharedPreferencesKey.airportDropsSent,
  );
  final parts = (saved ?? '').split(':');
  if (parts.length != 2 || parts.first != localDayKey(now)) return {};

  return {...parts.last.split(',').where((uid) => uid.isNotEmpty)};
}

/// Remembers that the player dropped a gift for [friend] today.
Future<void> rememberDrop(
  SharedPreferencesInterface prefs, {
  required String friend,
  required DateTime now,
}) async {
  final today = await droppedToday(prefs, now: now);
  await prefs.writeStringToSharedPrefs(
    SharedPreferencesKey.airportDropsSent,
    '${localDayKey(now)}:${{...today, friend}.join(',')}',
  );
}
