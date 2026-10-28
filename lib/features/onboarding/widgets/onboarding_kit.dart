import 'dart:async';

import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/motion.dart';

/// The big step title, word by word out of a blur. `*Words*` are accented.
class OnbTitle extends StatelessWidget {
  const OnbTitle(
    this.text, {
    this.at = 0.1,
    this.center = false,
    this.color,
    this.accent,
    this.size,
    super.key,
  });

  final String text;
  final double at;
  final bool center;
  final Color? color;
  final Color? accent;
  final double? size;

  @override
  Widget build(BuildContext context) => BlurWords(
        text,
        at: at,
        textAlign: center ? TextAlign.center : TextAlign.start,
        accent: accent ?? context.colorScheme.secondary,
        style: context.textTheme.headlineLarge?.copyWith(
          color: color ?? context.colorScheme.onSurface,
          fontSize: size,
        ),
      );
}

/// The muted line under a title.
class OnbSub extends StatelessWidget {
  const OnbSub(this.text, {this.at = 0.5, this.center = false, super.key});

  final String text;
  final double at;
  final bool center;

  @override
  Widget build(BuildContext context) => Reveal(
        at: at,
        offset: 8,
        child: Padding(
          padding: const EdgeInsets.only(top: PBSpace.sm),
          child: Text(
            text,
            textAlign: center ? TextAlign.center : TextAlign.start,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ),
      );
}

/// A white card on the tinted background.
class OnbCard extends StatelessWidget {
  const OnbCard({
    required this.child,
    this.padding = const EdgeInsets.all(PBSpace.lg),
    this.color,
    this.borderColor,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? context.colorScheme.surface,
          borderRadius: BorderRadius.circular(PBRadius.md),
          border: Border.all(
            color: borderColor ?? Colors.transparent,
            width: 2,
          ),
          boxShadow: context.cardShadow,
        ),
        child: child,
      );
}

/// A tappable answer, with a check when [selected].
class OnbOption extends StatelessWidget {
  const OnbOption({
    required this.label,
    required this.selected,
    required this.onTap,
    this.hint,
    this.icon,
    super.key,
  });

  final String label;
  final String? hint;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.colorScheme.secondary;

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          unawaited(HapticFeedback.selectionClick());
          onTap();
        },
        child: OnbCard(
          padding: const EdgeInsets.symmetric(
            horizontal: PBSpace.lg,
            vertical: PBSpace.md,
          ),
          color: selected
              ? Color.alphaBlend(
                  context.tint(accent),
                  context.colorScheme.surface,
                )
              : null,
          borderColor: selected ? accent : null,
          child: Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(PBRadius.sm),
                  ),
                  child: Icon(icon, size: 20, color: accent),
                ),
                const SizedBox(width: PBSpace.md),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: context.textTheme.titleMedium),
                    if (hint != null)
                      Text(hint!, style: context.textTheme.bodySmall),
                  ],
                ),
              ),
              AnimatedScale(
                scale: selected ? 1 : 0,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutBack,
                child: CheckDot(color: accent),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A filled circle with a check.
class CheckDot extends StatelessWidget {
  const CheckDot({required this.color, this.size = 24, super.key});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(
          CarbonIcons.checkmark,
          size: size * 0.62,
          color: context.gameColors.onGame,
        ),
      );
}

/// Two side by side choices, like cm and ft / in.
class UnitToggle<T> extends StatelessWidget {
  const UnitToggle({
    required this.values,
    required this.labels,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final List<T> values;
  final List<String> labels;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, option) in values.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: PBSpace.xs),
              child: GestureDetector(
                onTap: () {
                  unawaited(HapticFeedback.selectionClick());
                  onChanged(option);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: PBSpace.lg,
                    vertical: PBSpace.sm,
                  ),
                  decoration: BoxDecoration(
                    color: option == value
                        ? context.colorScheme.primary
                        : context.colorScheme.surface,
                    borderRadius: BorderRadius.circular(PBRadius.pill),
                    boxShadow: context.cardShadow,
                  ),
                  child: Text(
                    labels[i],
                    style: context.textTheme.labelLarge?.copyWith(
                      color: option == value
                          ? context.colorScheme.onPrimary
                          : context.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
}

/// A big number that rolls to [value], with a small [unit] after it.
class BigNumber extends StatelessWidget {
  const BigNumber({
    required this.value,
    this.unit,
    this.color,
    this.size = 96,
    this.text,
    super.key,
  });

  final num value;

  /// Shown instead of the rolling number, like 5′11″.
  final String? text;
  final String? unit;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = context.textTheme.displayLarge?.copyWith(
      fontSize: size,
      color: color ?? context.colorScheme.secondary,
    );

    // Long units ("Liegestütze") shrink the number rather than overflow.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          if (text != null)
            Text(text!, style: style)
          else
            AnimatedFlipCounter(
              value: value,
              duration: const Duration(milliseconds: 280),
              textStyle: style,
            ),
          if (unit != null) ...[
            const SizedBox(width: PBSpace.sm),
            Text(unit!, style: context.textTheme.titleLarge),
          ],
        ],
      ),
    );
  }
}

/// A ruler that scrolls under a fixed needle and snaps to whole steps.
/// Horizontal by default; [vertical] puts the big values at the top.
class RulerPicker extends StatefulWidget {
  const RulerPicker({
    required this.min,
    required this.max,
    required this.value,
    required this.onChanged,
    this.vertical = false,
    this.labelEvery = 10,
    this.introFrom,
    this.color,
    this.label,
    super.key,
  });

  final int min;
  final int max;
  final int value;
  final ValueChanged<int> onChanged;
  final bool vertical;
  final int labelEvery;

  /// Rolls in from this value when it first appears.
  final int? introFrom;
  final Color? color;

  /// The text under a major tick; the value itself by default.
  final String Function(int value)? label;

  @override
  State<RulerPicker> createState() => _RulerPickerState();
}

class _RulerPickerState extends State<RulerPicker> {
  static const _step = 14.0;

  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(
    initialItem: _indexOf(widget.introFrom ?? widget.value),
  );
  bool _intro = false;

  int _indexOf(int value) => widget.vertical
      ? widget.max - value.clamp(widget.min, widget.max)
      : value.clamp(widget.min, widget.max) - widget.min;

  int _valueAt(int index) =>
      widget.vertical ? widget.max - index : widget.min + index;

  @override
  void initState() {
    super.initState();
    final from = widget.introFrom;
    if (from != null && from != widget.value) {
      _intro = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _controller.animateToItem(
          _indexOf(widget.value),
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeOutCubic,
        );
        _intro = false;
      });
    }
  }

  @override
  void didUpdateWidget(RulerPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final index = _indexOf(widget.value);
    if (!_intro &&
        _controller.hasClients &&
        _controller.selectedItem != index) {
      _controller.jumpToItem(index);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? context.colorScheme.secondary;
    final count = widget.max - widget.min + 1;
    final wheel = ListWheelScrollView.useDelegate(
      controller: _controller,
      itemExtent: _step,
      diameterRatio: 100,
      perspective: 0.000001,
      physics: const FixedExtentScrollPhysics(),
      onSelectedItemChanged: (index) {
        if (_intro) return;
        unawaited(HapticFeedback.selectionClick());
        widget.onChanged(_valueAt(index));
      },
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: count,
        builder: (context, index) {
          final value = _valueAt(index);
          final tick = _Tick(
            value: value,
            label: widget.label?.call(value) ?? '$value',
            labelEvery: widget.labelEvery,
            vertical: widget.vertical,
          );
          return widget.vertical
              ? tick
              : RotatedBox(quarterTurns: 1, child: tick);
        },
      ),
    );

    final needle = Container(
      width: widget.vertical ? 64 : 4,
      height: widget.vertical ? 4 : 52,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );

    return OnbCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(PBRadius.md),
        child: SizedBox(
          height: widget.vertical ? null : 96,
          width: widget.vertical ? 120 : null,
          child: Stack(
            alignment:
                widget.vertical ? Alignment.centerRight : Alignment.topCenter,
            children: [
              if (widget.vertical)
                wheel
              else
                RotatedBox(quarterTurns: 3, child: wheel),
              Padding(
                padding: EdgeInsets.only(top: widget.vertical ? 0 : 10),
                child: IgnorePointer(child: needle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tick extends StatelessWidget {
  const _Tick({
    required this.value,
    required this.label,
    required this.labelEvery,
    required this.vertical,
  });

  final int value;
  final String label;
  final int labelEvery;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final major = value % labelEvery == 0;
    final half = labelEvery ~/ 2;
    final mid = half > 0 && value % half == 0;
    final length = major ? 34.0 : (mid ? 22.0 : 14.0);
    final color = context.colorScheme.onSurface
        .withValues(alpha: major || mid ? 0.5 : 0.22);
    final line = Container(
      width: vertical ? length : 2,
      height: vertical ? 2 : length,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1),
      ),
    );
    final text = major
        ? Text(
            label,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.onSurfaceVariant,
            ),
          )
        : null;

    if (vertical) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (text != null) text,
          const SizedBox(width: PBSpace.sm),
          line,
          const SizedBox(width: PBSpace.md),
        ],
      );
    }
    return OverflowBox(
      maxWidth: 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 18),
          line,
          if (text != null) ...[const SizedBox(height: 6), text],
        ],
      ),
    );
  }
}

/// A pill button that's not the main action.
class OnbTextButton extends StatelessWidget {
  const OnbTextButton(this.label, {required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => CupertinoButton(
        onPressed: onTap,
        child: Text(
          label,
          style: context.textTheme.labelLarge?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      );
}
