import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/widgets/pb_button.dart';
import 'package:pushup_bro/features/menu/model/routes.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

class FastPushupsQuest extends StatelessWidget {
  const FastPushupsQuest({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Assets.images.island.quests.jungle.fastPushups.image(
                width: 120,
                height: 120,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '''
Carlos is getting attacked by a Jaguar. Rescue him!
Do as many pushups as you can in 30 seconds.''',
                style: context.textTheme.titleSmall,
              ),
            ),
            PBButton(
              'GO',
              callback: () => Navigator.of(context).pushReplacement(
                navigateToPushupTracking(context),
              ),
            ),
          ],
        ),
      );
}
