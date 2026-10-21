import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/features/island/widgets/quests/double_value_quest.dart';
import 'package:pushup_bro/features/island/widgets/quests/fast_pushups_quest.dart';
import 'package:pushup_bro/features/island/widgets/quests/long_pushups_quest.dart';

class JungleQuest extends StatelessWidget {
  JungleQuest({
    required this.onClose,
    super.key,
  });

  final VoidCallback onClose;
  final int day = DateTime.now().day;

  @override
  Widget build(BuildContext context) {
    if (day % 3 == 0) {
      return const FastPushupsQuest();
    }

    if (day.isEven) {
      return const LongPushupsQuest();
    }

    if (day % 1 == 0) {
      return const DoubleValueQuest();
    }

    return const SizedBox.shrink();
  }
}
