import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';

/// A screen opened from the island's dock (Today, Bros): the page under a
/// title, with a round back button where the menu button usually sits.
class IslandSubpage extends StatelessWidget {
  const IslandSubpage({required this.title, required this.child, super.key});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surfaceContainerLow,
      body: Stack(
        children: [
          // Phone-wide on a wide window (iPhone Duo's inner display).
          Positioned.fill(
            child: Center(
              child: ConstrainedBox(
                // Full height: the page fills it whatever its own size.
                constraints: const BoxConstraints(
                  maxWidth: 640,
                  minHeight: double.infinity,
                ),
                child: child,
              ),
            ),
          ),
          // Positioned, so the page under it keeps the whole screen.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(title, style: context.textTheme.headlineLarge),
                    Positioned(
                      left: PBSpace.md,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: context.cardShadow,
                        ),
                        child: Material(
                          color: scheme.surface,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => Navigator.of(context).maybePop(),
                            child: SizedBox.square(
                              dimension: 48,
                              child: Icon(
                                CarbonIcons.arrow_left,
                                color: scheme.onSurface,
                                semanticLabel: MaterialLocalizations.of(context)
                                    .backButtonTooltip,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
