import 'package:equatable/equatable.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/features/social/domain/bro_name.dart';

/// A player as others see them: `users/{uid}`.
class BroProfile extends Equatable {
  const BroProfile({
    required this.uid,
    required this.broName,
    required this.code,
    this.look = const MonkeyLook(),
    this.streak = 0,
    this.total = 0,
    this.islandLevel = 1,
    this.friendCount = 0,
    this.showOnEveryone = true,
    this.island,
  });

  factory BroProfile.fromJson(String uid, Map<String, dynamic> json) =>
      BroProfile(
        uid: uid,
        broName: BroName.parse(json['broName'] as String?),
        code: json['code'] as String? ?? '',
        look: json['look'] is Map
            ? MonkeyLook.fromJson(
                Map<String, dynamic>.from(json['look'] as Map),
              )
            : const MonkeyLook(),
        streak: (json['streak'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        islandLevel: (json['islandLevel'] as num?)?.toInt() ?? 1,
        friendCount: (json['friendCount'] as num?)?.toInt() ?? 0,
        showOnEveryone: json['showOnEveryone'] as bool? ?? true,
        island: json['island'] is Map
            ? Map<String, dynamic>.from(json['island'] as Map)
            : null,
      );

  final String uid;
  final BroName broName;

  /// The friend code, without the dash.
  final String code;
  final MonkeyLook look;
  final int streak;

  /// Pushups ever.
  final int total;
  final int islandLevel;
  final int friendCount;

  /// Whether strangers see this player on today's Everyone board.
  final bool showOnEveryone;

  /// What their island looks like, for visits (see `IslandSnapshot`).
  final Map<String, dynamic>? island;

  Map<String, dynamic> toJson() => {
        'broName': broName.key,
        'code': code,
        'look': look.toJson(),
        'streak': streak,
        'total': total,
        'islandLevel': islandLevel,
        'friendCount': friendCount,
        'showOnEveryone': showOnEveryone,
        if (island != null) 'island': island,
      };

  BroProfile copyWith({
    MonkeyLook? look,
    int? streak,
    int? total,
    int? islandLevel,
    int? friendCount,
    bool? showOnEveryone,
    Map<String, dynamic>? island,
  }) =>
      BroProfile(
        uid: uid,
        broName: broName,
        code: code,
        look: look ?? this.look,
        streak: streak ?? this.streak,
        total: total ?? this.total,
        islandLevel: islandLevel ?? this.islandLevel,
        friendCount: friendCount ?? this.friendCount,
        showOnEveryone: showOnEveryone ?? this.showOnEveryone,
        island: island ?? this.island,
      );

  @override
  List<Object?> get props => [
        uid,
        broName,
        code,
        look,
        streak,
        total,
        islandLevel,
        friendCount,
        showOnEveryone,
        island,
      ];
}
