import 'package:flutter/widgets.dart';
import 'package:pushup_bro/features/pushup_tracking/widgets/start_pushups_button.dart';

class PushupTrackingBottomRow extends StatelessWidget {
  const PushupTrackingBottomRow({
    required this.toggleListeningUpdates,
    super.key,
  });

  final VoidCallback toggleListeningUpdates;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Spacer(),
          Expanded(
            flex: 8,
            child: Center(child: StartPushupsButton(toggleListeningUpdates)),
          ),
          const Spacer(),
        ],
      );
}
