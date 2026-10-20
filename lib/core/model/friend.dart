import 'package:pushup_bro/core/model/minimized_user.dart';

class Friend {
  Friend({
    this.id = '',
    this.name = '',
    this.image = '',
    this.streak = 0,
    this.longestStreak = 0,
    this.sharedStreak = 0,
    this.longestSharedStreak = 0,
  });

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        image: json['image'] as String? ?? '',
        streak: json['streak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
        sharedStreak: json['sharedStreak'] as int? ?? 0,
        longestSharedStreak: json['longestSharedStreak'] as int? ?? 0,
      );

  final String id;
  final String name;
  final String image;
  final int streak;
  final int longestStreak;
  final int sharedStreak;
  final int longestSharedStreak;
  bool get hasSharedStreakGoing => sharedStreak > 0;

  MinimizedUser toMinimizedUser() => MinimizedUser(image: image, name: name);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'image': image,
        'streak': streak,
        'longestStreak': longestStreak,
        'sharedStreak': sharedStreak,
        'longestSharedStreak': longestSharedStreak,
      };
}
