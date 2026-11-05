import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/provider/shared_preferences_interface.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/features/island/buildings/airport/gift_opened_overlay.dart';
import 'package:pushup_bro/features/pro/widgets/pro_overlay_route.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/cubit/account_state.dart';
import 'package:pushup_bro/features/social/domain/gift_drops.dart';
import 'package:pushup_bro/features/social/model/gift_drop.dart';

/// The inventory once no other write is in flight (while one is, the
/// state holds an empty placeholder).
Future<GameInventory> _settled(GameInventoryCubit cubit) async {
  final state = cubit.state is GameInventoryFetching
      ? await cubit.stream.firstWhere((s) => s is! GameInventoryFetching)
      : cubit.state;

  return state.inventory;
}

/// How a drop on a friend's island went.
enum DropOutcome { dropped, notEnoughBananas, alreadyDropped, failed }

/// Drops [gift] on [friend]'s island, paid from the player's bananas: at
/// most one per friend and day. Returns the drop when it landed.
Future<(DropOutcome, GiftDrop?)> dropGiftOn(
  BuildContext context, {
  required String friend,
  required GiftKind gift,
  SharedPreferencesInterface? prefs,
  DateTime? now,
}) async {
  final account = context.read<AccountCubit>();
  final inventory = context.read<GameInventoryCubit>();
  final store = prefs ?? SharedPreferencesProvider();
  final at = now ?? DateTime.now();
  final me = account.state.uid;
  if (me == null) return (DropOutcome.failed, null);
  final check = checkDrop(
    gift: gift,
    bananas: (await _settled(inventory)).bananas,
    droppedToday: (await droppedToday(store, now: at)).contains(friend),
  );
  switch (check) {
    case DropCheck.alreadyDropped:
      return (DropOutcome.alreadyDropped, null);
    case DropCheck.notEnoughBananas:
      return (DropOutcome.notEnoughBananas, null);
    case DropCheck.ok:
      break;
  }
  final drop = GiftDrop.create(
    gift: gift,
    fromUid: me,
    fromName: account.state.friendName,
    now: at,
  );
  final bool landed;
  try {
    landed = await account.backend.dropGift(friend, drop);
  } on Object catch (error) {
    debugPrint('Gift drop failed: $error');
    return (DropOutcome.failed, null);
  }
  if (!landed) {
    // The rules refused it: one from this phone already landed today.
    await rememberDrop(store, friend: friend, now: at);
    return (DropOutcome.alreadyDropped, null);
  }
  // Only paid once it's down, so a failed drop costs nothing.
  final inv = await _settled(inventory);
  await inventory.updateInventory(
    inv.copyWith(bananas: inv.bananas - gift.cost),
  );
  await rememberDrop(store, friend: friend, now: at);

  return (DropOutcome.dropped, drop);
}

/// Opens a crate on the player's island: its bananas go to the player,
/// with a little celebration, and it's gone from the island.
Future<void> openGiftDrop(BuildContext context, GiftDrop drop) async {
  final account = context.read<AccountCubit>();
  final inventory = context.read<GameInventoryCubit>();
  final uid = account.state.uid;
  if (uid == null) return;
  // Marked first, so a second tap or another phone can't open it twice.
  await account.backend.openDrop(uid, drop.id);
  final inv = await _settled(inventory);
  await inventory.updateInventory(
    inv.copyWith(bananas: inv.bananas + drop.bananas),
  );
  GameAudio.instance.play(Sfx.purchase);
  if (!context.mounted) return;
  await showProOverlay<void>(
    context,
    (context) => GiftOpenedOverlay(drop: drop),
  );
}

/// Follows the gifts waiting on the player's own island while their
/// account is ready, and clears opened ones once their day is over.
class OwnGiftDrops {
  OwnGiftDrops(this._account, this._onChange);

  final AccountCubit _account;
  final void Function(List<GiftDrop> drops) _onChange;
  StreamSubscription<AccountState>? _accountSub;
  StreamSubscription<List<GiftDrop>>? _dropsSub;
  String? _uid;

  void start() {
    _follow(_account.state);
    _accountSub = _account.stream.listen(_follow);
  }

  void _follow(AccountState state) {
    final uid = state.status == AccountStatus.ready ? state.uid : null;
    if (uid == _uid) return;
    _uid = uid;
    unawaited(_dropsSub?.cancel());
    _dropsSub = null;
    if (uid == null) {
      _onChange(const []);
      return;
    }
    _dropsSub = _account.backend.drops(uid).listen(
      (drops) {
        for (final stale in staleDrops(drops, now: DateTime.now())) {
          unawaited(_account.backend.removeDrop(uid, stale.id));
        }
        _onChange(waitingDrops(drops));
      },
      onError: (Object _) => _onChange(const []),
    );
  }

  void dispose() {
    unawaited(_accountSub?.cancel());
    unawaited(_dropsSub?.cancel());
  }
}
