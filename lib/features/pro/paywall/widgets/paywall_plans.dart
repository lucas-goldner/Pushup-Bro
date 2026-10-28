import 'package:flutter/material.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/pro/data/purchases_service.dart';
import 'package:pushup_bro/features/pro/model/pro_plan.dart';
import 'package:pushup_bro/features/pro/model/pro_state.dart';

/// The plans to show: the store's, or the planned prices while the store
/// has nothing to offer (so the paywall never looks empty).
List<ProPlan> displayedPlans(ProState state) {
  final plans =
      state.plans.isEmpty ? PreviewPurchasesService.plans : state.plans;

  return [...plans]..sort((a, b) => a.kind.index.compareTo(b.kind.index));
}

/// How much cheaper a year is than 52 weeks, in percent, or null.
int? yearlySavings(List<ProPlan> plans) {
  ProPlan? find(ProPlanKind kind) {
    for (final plan in plans) {
      if (plan.kind == kind) return plan;
    }
    return null;
  }

  final weekly = find(ProPlanKind.weekly);
  final yearly = find(ProPlanKind.yearly);
  if (weekly == null || yearly == null || weekly.amount <= 0) return null;
  final percent = ((1 - yearly.amount / (weekly.amount * 52)) * 100).round();

  return percent > 0 ? percent : null;
}

extension ProPlanText on ProPlan {
  String name(BuildContext context) => switch (kind) {
        ProPlanKind.weekly => context.l10n.proPlanWeekly,
        ProPlanKind.yearly => context.l10n.proPlanYearly,
        ProPlanKind.lifetime => context.l10n.proPlanLifetime,
      };

  /// The small line under the price on the card.
  String per(BuildContext context) => switch (kind) {
        ProPlanKind.weekly => context.l10n.proPerWeek,
        ProPlanKind.yearly => pricePerWeek == null
            ? context.l10n.proBilledWeekly
            : context.l10n.proPricePerWeek(pricePerWeek!),
        ProPlanKind.lifetime => context.l10n.proPayOnce,
      };

  /// The big price line under the cards.
  String hero(BuildContext context) => switch (kind) {
        ProPlanKind.weekly => context.l10n.proPricePerWeek(price),
        ProPlanKind.yearly => context.l10n.proPricePerYear(price),
        ProPlanKind.lifetime => context.l10n.proPriceOnce(price),
      };

  String heroSub(BuildContext context) => switch (kind) {
        ProPlanKind.weekly => context.l10n.proBilledWeekly,
        ProPlanKind.yearly => pricePerWeek == null
            ? context.l10n.proCancelAnytime
            : context.l10n.proJustPerWeek(pricePerWeek!),
        ProPlanKind.lifetime => context.l10n.proEveryFeatureForever,
      };

  String assurance(BuildContext context) => kind == ProPlanKind.lifetime
      ? context.l10n.proOneTimePayment
      : context.l10n.proCancelAnytime;

  String terms(BuildContext context) => switch (kind) {
        ProPlanKind.weekly => context.l10n.proTermsWeekly(price),
        ProPlanKind.yearly => context.l10n.proTermsYearly(price),
        ProPlanKind.lifetime => context.l10n.proTermsLifetime,
      };
}

/// The three plan cards side by side; the picked one lifts with a ring.
class PaywallPlans extends StatelessWidget {
  const PaywallPlans({
    required this.plans,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<ProPlan> plans;
  final ProPlanKind selected;
  final ValueChanged<ProPlanKind> onSelected;

  @override
  Widget build(BuildContext context) {
    final savings = yearlySavings(plans);

    return Padding(
      padding: const EdgeInsets.only(top: PBSpace.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, plan) in plans.indexed) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: PlanCard(
                plan: plan,
                selected: plan.kind == selected,
                tag: switch (plan.kind) {
                  ProPlanKind.weekly => context.l10n.proTagFlexible,
                  ProPlanKind.yearly =>
                    savings == null ? null : context.l10n.proTagSave(savings),
                  ProPlanKind.lifetime => context.l10n.proTagForever,
                },
                onTap: () {
                  GameAudio.instance.play(Sfx.tap);
                  onSelected(plan.kind);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class PlanCard extends StatelessWidget {
  const PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
    this.tag,
    super.key,
  });

  final ProPlan plan;
  final bool selected;
  final String? tag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final game = context.gameColors;
    final tagColor = switch (plan.kind) {
      ProPlanKind.weekly => game.ice,
      ProPlanKind.yearly => game.jungle,
      ProPlanKind.lifetime => game.orange,
    };

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          height: 112,
          transform: Matrix4.translationValues(0, selected ? -2 : 0, 0),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              if (selected)
                BoxShadow(color: scheme.secondary, spreadRadius: 2.5),
              ...context.cardShadow,
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        plan.name(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelMedium?.copyWith(
                          fontSize: 13,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          plan.price,
                          style: context.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        plan.per(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (tag != null)
                Positioned(
                  top: -11,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      height: 22,
                      padding: const EdgeInsets.symmetric(horizontal: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tagColor,
                        borderRadius: BorderRadius.circular(PBRadius.pill),
                      ),
                      child: Text(
                        tag!,
                        maxLines: 1,
                        style: context.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          color: game.onGame,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
