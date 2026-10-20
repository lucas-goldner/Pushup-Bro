import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/feature_switch_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/feature_variants.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/news_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/news_state.dart';

class PushupTrackingTopRow extends StatelessWidget {
  const PushupTrackingTopRow({
    required this.toggleNewsVisibility,
    super.key,
  });

  final VoidCallback toggleNewsVisibility;

  @override
  Widget build(BuildContext context) {
    final featureVariant =
        context.read<FeatureSwitchCubit>().state.featureVariant;

    return GestureDetector(
      onTap: toggleNewsVisibility,
      child: Row(
        children: [
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(
              right: 16,
              top: 4,
            ),
            child: switch (featureVariant) {
              FeatureVariants.hookmodel => Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      style: IconButton.styleFrom(
                        splashFactory: NoSplash.splashFactory,
                        backgroundColor: context.colorScheme.surface,
                        tapTargetSize: MaterialTapTargetSize.padded,
                      ),
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onPressed: toggleNewsVisibility,
                      icon: Icon(
                        size: 32,
                        CarbonIcons.event_schedule,
                        color: context.colorScheme.onSecondaryContainer,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 2,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 20,
                          minHeight: 20,
                        ),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: context.colorScheme.onSecondary,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Center(
                            child: BlocBuilder<NewsCubit, NewsState>(
                              builder: (context, state) => Text(
                                state.news.length.toString(),
                                style: context.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              FeatureVariants.gamification => const SizedBox(
                  width: 32,
                  height: 32,
                ),
            },
          ),
        ],
      ),
    );
  }
}
