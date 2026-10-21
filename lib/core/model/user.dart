import 'package:pushup_bro/core/model/friend.dart';
import 'package:pushup_bro/core/model/minimized_user.dart';

// TODO(items): Move items also into user object
class User {
  User({
    required this.level,
    required this.xp,
    required this.friends,
    required this.name,
    required this.image,
    required this.streak,
    required this.longestStreak,
  });

  factory User.empty() => User(
        level: 1,
        xp: 0,
        name: '',
        image: '',
        streak: 0,
        friends: [],
        longestStreak: 0,
      );

  factory User.fromJson(Map<String, dynamic> json) => User(
        level: json['level'] as int? ?? 1,
        xp: json['xp'] as int? ?? 0,
        name: json['name'] as String? ?? '',
        image: json['image'] as String? ?? '',
        streak: json['streak'] as int? ?? 0,
        friends: (json['friends'] as List<dynamic>? ?? [])
            .map((e) => Friend.fromJson(e as Map<String, dynamic>))
            .toList(),
        longestStreak: json['longestStreak'] as int? ?? 0,
      );

  final int level;
  final int xp;
  final String name;
  final String image;
  final int streak;
  final List<Friend> friends;
  final int longestStreak;

  User copyWith({
    int? level,
    int? xp,
    String? name,
    String? image,
    int? streak,
    List<Friend>? friends,
    int? longestStreak,
  }) =>
      User(
        level: level ?? this.level,
        xp: xp ?? this.xp,
        name: name ?? this.name,
        image: image ?? this.image,
        streak: streak ?? this.streak,
        friends: friends ?? this.friends,
        longestStreak: longestStreak ?? this.longestStreak,
      );

  MinimizedUser toMinimizedUser() => MinimizedUser(
        name: name,
        image: image,
      );

  Map<String, dynamic> toJson() => {
        'level': level,
        'xp': xp,
        'name': name,
        'image': image,
        'streak': streak,
        'friends': friends.map((f) => f.toJson()).toList(),
        'longestStreak': longestStreak,
      };

  @override
  String toString() => 'User(level: $level, xp: $xp, name: $name)';
}
