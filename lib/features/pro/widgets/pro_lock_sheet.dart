import 'dart:math' as math;

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/island_sheet.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/pro/cubit/pro_cubit.dart';
import 'package:pushup_bro/features/pro/model/pro_feature.dart';
import 'package:pushup_bro/features/pro/model/pro_plan.dart';
import 'package:pushup_bro/features/pro/paywall/show_paywall.dart';
import 'package:pushup_bro/features/pro/paywall/widgets/paywall_plans.dart';
import 'package:pushup_bro/features/pro/widgets/pro_overlay_route.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

/// Shows the lock sheet for [place]; "See all plans" opens the paywall.
/// Returns whether the player has access afterwards.
Future<bool> showProLockSheet(BuildContext context, ProLockPlace place) async {
  final cubit = context.read<ProCubit>();
  final seePlans = await showProOverlay<bool>(
    context,
    (_) => BlocProvider.value(value: cubit, child: ProLockSheet(place: place)),
  );
  var access = cubit.hasAccess;
  if ((seePlans ?? false) && context.mounted) {
    access = await showPaywall(context);
  }

  return access;
}

/// A place on the island that needs Pro: what it is, the most picked plan
/// and the way to all plans. Pops with true for "See all plans".
class ProLockSheet extends StatelessWidget {
  const ProLockSheet({required this.place, super.key});

  final ProLockPlace place;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = context.colorScheme;
    final game = context.gameColors;
    final (title, body, image) = switch (place) {
      ProLockPlace.jungle => (
          l.proLockJungleTitle,
          l.proLockJungleBody,
          Assets.images.proHeroKomo,
        ),
      ProLockPlace.shop => (
          l.proLockShopTitle,
          l.proLockShopBody,
          Assets.images.island.banana,
        ),
      ProLockPlace.carlos => (
          l.proLockCarlosTitle,
          l.proLockCarlosBody,
          Assets.images.proHeroWave,
        ),
    };
    final plans = displayedPlans(context.watch<ProCubit>().state);
    final yearly = plans.firstWhere(
      (plan) => plan.kind == ProPlanKind.yearly,
      orElse: () => plans.first,
    );
    void close({bool seePlans = false}) => Navigator.of(context).pop(seePlans);

    return IslandSheet(
      title: title,
      onClose: close,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _LockedPicture(image: image),
              const SizedBox(width: PBSpace.lg),
              Expanded(
                child: Text(
                  body,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: PBSpace.lg + 4),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: PBSpace.lg,
              vertical: PBSpace.md,
            ),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.proMostPicked,
                        style: context.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          letterSpacing: 0.8,
                          color: game.jungle,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${yearly.name(context)} · ${yearly.price}',
                        style: context.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                if (yearly.pricePerWeek != null)
                  SheetTag(
                    l.proPricePerWeek(yearly.pricePerWeek!),
                    color: game.jungle,
                  ),
              ],
            ),
          ),
          const SizedBox(height: PBSpace.lg + 4),
          PillButton(
            label: l.proSeeAllPlans,
            onPressed: () => close(seePlans: true),
          ),
        ],
      ),
    );
  }
}

/// The place's picture on a tinted tile, with a lock that shakes in.
class _LockedPicture extends StatelessWidget {
  const _LockedPicture({required this.image});

  final AssetGenImage image;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return SizedBox(
      width: 102,
      height: 110,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 6,
            child: Container(
              width: 96,
              height: 104,
              alignment: Alignment.bottomCenter,
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  context.tint(scheme.secondary),
                  scheme.surface,
                ),
                borderRadius: BorderRadius.circular(PBRadius.lg),
              ),
            ),
          ),
          Positioned(
            left: 0,
            width: 96,
            bottom: 4,
            child: Center(child: image.image(height: 104)),
          ),
          Positioned(
            right: 0,
            bottom: -6,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 1000),
              builder: (context, t, child) {
                // Waits a moment, then wiggles and settles.
                final x = ((t - 0.3) / 0.7).clamp(0.0, 1.0);
                final angle = math.sin(x * math.pi * 4) * 0.21 * (1 - x);

                return Transform.rotate(angle: angle, child: child);
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                  boxShadow: context.cardShadow,
                ),
                child: Icon(
                  CarbonIcons.locked,
                  size: 16,
                  color: scheme.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
