import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:pushup_bro/features/share/model/recap.dart';
import 'package:pushup_bro/features/share/recap_share_page.dart';

/// The player's weight from the onboarding, for calories; null when it
/// was never asked.
double? playerWeightKg(BuildContext context) {
  try {
    return context.read<OnboardingCubit>().state.answers.weightKg;
  } on Object {
    return null;
  }
}

/// "Share" under a result: opens the share video of [recap].
class ShareRecapButton extends StatelessWidget {
  const ShareRecapButton({required this.recap, super.key});

  /// Built when tapped, so it reads the latest sets.
  final Recap Function() recap;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: PBSpace.sm),
        onPressed: () => RecapSharePage.open(context, recap()),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CarbonIcons.share,
              size: 18,
              color: context.colorScheme.secondary,
            ),
            const SizedBox(width: PBSpace.xs + 2),
            Text(
              context.l10n.shareButton,
              style: context.textTheme.labelLarge?.copyWith(
                color: context.colorScheme.secondary,
              ),
            ),
          ],
        ),
      );
}
