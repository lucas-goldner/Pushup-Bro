import 'package:pushup_bro/core/model/user.dart';

class MinimizedUser {
  MinimizedUser({
    required this.name,
    required this.image,
  });

  final String name;
  final String image;

  MinimizedUser fromUser(
    User user,
  ) =>
      MinimizedUser(
        name: user.name,
        image: user.image,
      );
}
