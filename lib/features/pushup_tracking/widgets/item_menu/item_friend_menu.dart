import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/booster_item_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/booster_items.dart';
import 'package:pushup_bro/core/model/friend.dart';
import 'package:pushup_bro/core/widgets/minimized_profile.dart';
import 'package:pushup_bro/core/widgets/pb_button.dart';

class ItemFriendMenu extends StatefulWidget {
  const ItemFriendMenu({super.key});

  @override
  State<ItemFriendMenu> createState() => _ItemFriendMenuState();
}

class _ItemFriendMenuState extends State<ItemFriendMenu> {
  final List<Friend> friends = [];
  final List<Friend> friendsData = [
    Friend(
      id: '1',
      name: 'Friend 1',
      image: 'https://picsum.photos/200',
      streak: 12,
      sharedStreak: 1,
    ),
    Friend(
      id: '2',
      name: 'Friend 2',
      image: 'https://picsum.photos/200',
      streak: 3,
      sharedStreak: 20,
    ),
    ...List.generate(
      8,
      (index) => Friend(
        id: '${index + 3}',
        name: 'Friend $index',
      ),
    ),
  ];

  bool _isFriendInList(Friend friend) =>
      friends.map((friendData) => friendData.id).contains(friend.id);

  void _addFriendToList(Friend newFriendData, BuildContext context) {
    final boosterItemCubit = context.read<BoosterItemCubit>();
    if (boosterItemCubit.state.items[BoosterItems.friendBoost] == 0) {
      return;
    }

    if (!_isFriendInList(newFriendData)) {
      setState(() => friends.add(newFriendData));
      boosterItemCubit.consumeItem(
        item: BoosterItems.friendBoost,
      );
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Text(
              context.l10n.sendBoost,
              style: context.textTheme.titleLarge,
              textAlign: TextAlign.start,
            ),
            Flexible(
              child: ListView.builder(
                itemCount: friendsData.length,
                itemBuilder: (context, index) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: MinimizedProfile(
                        friendsData[index].toMinimizedUser(),
                        leadingItem: SizedBox(
                          width: 80,
                          child: PBButton.icon(
                            icon: _isFriendInList(friendsData[index])
                                ? CarbonIcons.checkmark_filled
                                : CarbonIcons.send,
                            '',
                            callback: () =>
                                _addFriendToList(friendsData[index], context),
                          ),
                        ),
                      ),
                    ),
                    const Divider(
                      indent: 60,
                      endIndent: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
