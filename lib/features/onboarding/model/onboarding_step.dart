/// The onboarding's screens, in order.
enum OnboardingStep {
  hook,
  goal,
  max,
  often,
  height,
  weight,
  goalWeight,
  pains,
  notYou,
  carlos,
  track,
  moves,
  chart,
  month,
  daily,
  reminder,
  building,
  firstSet,
  reward,
  plan,
  paywall;

  /// The steps this player goes through. Players who already logged
  /// pushups skip the first set and its reward; Pro members skip the
  /// paywall.
  static List<OnboardingStep> flow({
    required bool hasPushups,
    required bool isPro,
  }) =>
      [
        for (final step in values)
          if (!(hasPushups && (step == firstSet || step == reward)) &&
              !(isPro && step == paywall))
            step,
      ];

  /// Story screens without a progress bar or back button.
  bool get fullBleed => switch (this) {
        hook || notYou || carlos || building || reward => true,
        _ => false,
      };
}
