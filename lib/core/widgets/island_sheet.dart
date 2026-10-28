import 'dart:ui' show ImageFilter;

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

/// The app's sheet: a rounded card that springs up from the bottom over a
/// softly blurred backdrop, headed by a coloured badge, a title and an
/// optional close button. Its top is washed in [accent] (the theme's
/// secondary colour by default).
///
/// Lay it over a screen in a [Stack]; it sizes to its content, up to
/// [maxHeightFactor] of the screen.
class IslandSheet extends StatelessWidget {
  const IslandSheet({
    required this.title,
    required this.child,
    this.badge,
    this.subtitle,
    this.trailing,
    this.onClose,
    this.accent,
    this.maxHeightFactor = 0.82,
    this.scrollable = true,
    super.key,
  });

  final String title;
  final String? subtitle;

  /// An emoji, shown in the badge next to the title.
  final String? badge;
  final Widget child;
  final Widget? trailing;
  final VoidCallback? onClose;
  final Color? accent;
  final double maxHeightFactor;

  /// Whether the content scrolls inside the sheet; turn off for content
  /// that sizes or scrolls itself (like a [PageView]).
  final bool scrollable;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          const _PopOnShow(),
          Positioned.fill(
            child: GestureDetector(
              onTap: onClose,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 300),
                builder: (context, t, _) => BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 6 * t, sigmaY: 6 * t),
                  child: ColoredBox(
                    color: context.colorScheme.scrim
                        .withValues(alpha: (context.isDark ? 0.5 : 0.3) * t),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 1, end: 0),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutBack,
              builder: (context, t, child) => FractionalTranslation(
                translation: Offset(0, t * 0.6),
                child: Opacity(opacity: (1 - t).clamp(0, 1), child: child),
              ),
              child: _card(context),
            ),
          ),
        ],
      );

  Widget _card(BuildContext context) {
    final media = MediaQuery.of(context);
    final scheme = context.colorScheme;
    final accent = this.accent ?? scheme.secondary;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: media.size.height * maxHeightFactor,
        maxWidth: 560,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(context.tint(accent), scheme.surface),
              scheme.surface,
            ],
            stops: const [0, 0.28],
          ),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(PBRadius.sheet)),
          boxShadow: [
            BoxShadow(
              color:
                  scheme.shadow.withValues(alpha: context.isDark ? 0.5 : 0.22),
              blurRadius: 40,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: EdgeInsets.only(bottom: media.padding.bottom + 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 14, 10),
                  child: _header(context, accent),
                ),
                Flexible(
                  child: scrollable
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                          child: child,
                        )
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                          child: child,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, Color accent) => Row(
        children: [
          if (badge != null) ...[
            SheetBadge(badge!, color: accent),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: context.textTheme.headlineMedium,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: context.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
          if (onClose != null) SheetCloseButton(onPressed: onClose!),
        ],
      );
}

/// A rounded tile with an emoji on a tint of [color].
class SheetBadge extends StatelessWidget {
  const SheetBadge(
    this.emoji, {
    this.color,
    this.size = 52,
    super.key,
  });

  final String emoji;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.colorScheme.secondary;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          color.withValues(alpha: 0.2),
          context.colorScheme.surface,
        ),
        borderRadius: BorderRadius.circular(size * 0.34),
      ),
      child: Text(emoji, style: TextStyle(fontSize: size * 0.5)),
    );
  }
}

/// The sheet's round close button.
class SheetCloseButton extends StatelessWidget {
  const SheetCloseButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Material(
        color: context.colorScheme.surfaceContainer,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              CarbonIcons.close,
              color: context.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
        ),
      );
}

/// A soft card inside a sheet; outlined in [accent] when [selected].
class SheetCard extends StatelessWidget {
  const SheetCard({
    required this.child,
    this.onTap,
    this.selected = false,
    this.accent,
    this.padding = const EdgeInsets.all(14),
    this.color,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final bool selected;
  final Color? accent;
  final EdgeInsets padding;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = this.accent ?? context.colorScheme.secondary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: color ??
            (selected
                ? Color.alphaBlend(
                    context.tint(accent),
                    context.colorScheme.surface,
                  )
                : context.colorScheme.surfaceContainerLow),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected ? accent : Colors.transparent,
          width: 2,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// A price in bananas, as a small pill.
class BananaPrice extends StatelessWidget {
  const BananaPrice(this.price, {this.affordable = true, super.key});

  final int price;
  final bool affordable;

  @override
  Widget build(BuildContext context) => Container(
        height: 28,
        padding: const EdgeInsets.only(left: 4, right: 10),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Assets.images.island.banana.image(width: 22),
            const SizedBox(width: 3),
            Text(
              '$price',
              style: context.textTheme.labelMedium?.copyWith(
                fontSize: 14,
                color: affordable
                    ? context.colorScheme.onSurface
                    : context.gameColors.red,
              ),
            ),
          ],
        ),
      );
}

/// A small status pill, e.g. "Owned" or "Wearing".
class SheetTag extends StatelessWidget {
  const SheetTag(this.label, {this.color, this.icon, super.key});

  final String label;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.colorScheme.secondary;

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: context.tint(color),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: context.textTheme.labelMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

/// Plays the sheet's pop as it opens.
class _PopOnShow extends StatefulWidget {
  const _PopOnShow();

  @override
  State<_PopOnShow> createState() => _PopOnShowState();
}

class _PopOnShowState extends State<_PopOnShow> {
  @override
  void initState() {
    super.initState();
    GameAudio.instance.play(Sfx.pop);
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
