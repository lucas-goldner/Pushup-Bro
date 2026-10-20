import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/widgets/pb_button.dart';
import 'package:pushup_bro/features/menu/model/routes.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

class LongPushupsQuest extends StatelessWidget {
  const LongPushupsQuest({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        child: Column(
          children: [
            Center(
              child: Assets.images.island.quests.jungle.longPushup.image(
                width: 120,
                height: 120,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '''
Today, Carlos if focusing on doing longer pushups.
Hold your pushups 3 seconds before going back up.''',
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
