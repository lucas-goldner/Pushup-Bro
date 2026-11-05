import 'package:equatable/equatable.dart';
import 'package:pushup_bro/features/social/domain/local_day.dart';

/// What a bro can drop on a friend's island from the airport. The sender
/// pays [cost] bananas from their own and the friend gets [bananas] when
/// they open it; the bouquet is the cheap, cute one.
enum GiftKind {
  small(bananas: 10, emoji: '📦'),
  big(bananas: 25, emoji: '🎁'),
  golden(bananas: 50, emoji: '👑'),
  flowers(bananas: 5, emoji: '💐');

  const GiftKind({required this.bananas, required this.emoji});

  final int bananas;
  final String emoji;

  /// Gifts pass on every banana they cost.
  int get cost => bananas;
}

/// The most bananas a single drop may carry (the rules check it too).
const kMaxDropBananas = 50;

/// A gift a friend dropped on the player's island:
/// `users/{uid}/drops/{id}`. Its id is one per sender and day, so the
/// rules refuse a second drop from the same friend that day. Opening it
/// marks it [opened] rather than deleting it, so the id stays taken until
/// the day is over.
class GiftDrop extends Equatable {
  const GiftDrop({
    required this.id,
    required this.gift,
    required this.fromUid,
    required this.fromName,
    required this.sentAt,
    this.opened = false,
  });

  /// A new drop from [fromUid], under today's id for them.
  factory GiftDrop.create({
    required GiftKind gift,
    required String fromUid,
    required String fromName,
    required DateTime now,
  }) =>
      GiftDrop(
        id: idFor(fromUid, now),
        gift: gift,
        fromUid: fromUid,
        fromName: fromName,
        sentAt: now,
      );

  /// Old or tampered drops fall back to the smallest gift, and never
  /// carry more than [kMaxDropBananas].
  factory GiftDrop.fromJson(String id, Map<String, dynamic> json) => GiftDrop(
        id: id,
        gift: GiftKind.values.asNameMap()[json['gift']] ?? GiftKind.flowers,
        fromUid: json['fromUid'] as String? ?? '',
        fromName: json['fromName'] as String? ?? '',
        sentAt: DateTime.fromMillisecondsSinceEpoch(
          (json['sentAt'] as num?)?.toInt() ?? 0,
        ),
        opened: json['opened'] as bool? ?? false,
      );

  /// The id of [fromUid]'s drop on [now]'s day.
  static String idFor(String fromUid, DateTime now) =>
      'drop_${fromUid}_${localDayKey(now)}';

  final String id;
  final GiftKind gift;
  final String fromUid;

  /// The name the sender goes by for this friend.
  final String fromName;
  final DateTime sentAt;
  final bool opened;

  int get bananas => gift.bananas;

  /// The sender's day the drop was made on, from its id.
  String get day => id.length >= 10 ? id.substring(id.length - 10) : '';

  GiftDrop open() => GiftDrop(
        id: id,
        gift: gift,
        fromUid: fromUid,
        fromName: fromName,
        sentAt: sentAt,
        opened: true,
      );

  Map<String, dynamic> toJson() => {
        'gift': gift.name,
        'bananas': bananas,
        'fromUid': fromUid,
        'fromName': fromName,
        'sentAt': sentAt.millisecondsSinceEpoch,
        'opened': opened,
      };

  @override
  List<Object?> get props => [id, gift, fromUid, fromName, sentAt, opened];
}
