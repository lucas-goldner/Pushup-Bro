import 'package:equatable/equatable.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/features/social/domain/bro_name.dart';

/// A player's pushups on one day: `days/{day}/scores/{uid}`.
class DayScore extends Equatable {
  const DayScore({
    required this.uid,
    required this.count,
    required this.broName,
    required this.updatedAt,
    this.look = const MonkeyLook(),
    this.streak = 0,
    this.public = true,
  });

  factory DayScore.fromJson(String uid, Map<String, dynamic> json) => DayScore(
        uid: uid,
        count: (json['count'] as num?)?.toInt() ?? 0,
        broName: BroName.parse(json['broName'] as String?),
        look: json['look'] is Map
            ? MonkeyLook.fromJson(
                Map<String, dynamic>.from(json['look'] as Map),
              )
            : const MonkeyLook(),
        streak: (json['streak'] as num?)?.toInt() ?? 0,
        public: json['public'] as bool? ?? true,
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
          (json['updatedAt'] as num?)?.toInt() ?? 0,
        ),
      );

  final String uid;
  final int count;
  final BroName broName;
  final MonkeyLook look;
  final int streak;

  /// Shown on the Everyone board; friends always see it.
  final bool public;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'count': count,
        'broName': broName.key,
        'look': look.toJson(),
        'streak': streak,
        'public': public,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
      };

  @override
  List<Object?> get props =>
      [uid, count, broName, look, streak, public, updatedAt];
}
