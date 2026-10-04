import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:pushup_bro/ui/styles/pb_colors.dart';
import 'package:pushup_bro/ui/styles/pb_text_styles.dart';
import 'package:pushup_bro/ui/widgets/onboarding/onboarding_features_item.dart';

class OnboardingFeatures extends StatelessWidget {
  const OnboardingFeatures({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      color: PBColors.onboardingFeaturesBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 16),
              child: Text(
                S.of(context).features,
                style: PBTextStyles.pageTitleTextStyle,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Flexible(
              child: ListView(
                children: <Widget>[
                  OnboardingFeaturesItem(
                    S.of(context).aidPodsFeature,
                    CarbonIcons.headphones,
                  ),
                  OnboardingFeaturesItem(
                    S.of(context).calendarFeature,
                    CarbonIcons.calendar,
                  ),
                  OnboardingFeaturesItem(
                    S.of(context).dailyGoalFeature,
                    CarbonIcons.reminder,
                  ),
                  OnboardingFeaturesItem(
                    S.of(context).friendsFeature,
                    CarbonIcons.group,
                  ),
                  OnboardingFeaturesItem(
                    S.of(context).syncFeature,
                    CarbonIcons.save,
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 16),
              child: Text(
                S.of(context).comingSoon,
                style: PBTextStyles.pageTitleTextStyle,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 16, right: 16),
              child: Text(
                S.of(context).moreIdeas,
                style: PBTextStyles.defaultTextStyle,
              ),
            ),
            const SizedBox(
              height: 40,
            ),
          ],
        ),
      ),
    );
  }
}
