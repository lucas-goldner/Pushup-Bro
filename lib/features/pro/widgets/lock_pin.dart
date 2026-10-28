import 'dart:math' as math;

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';

/// A round lock that bobs over a place the player can't use without Pro.
class LockPin extends StatefulWidget {
  const LockPin({
    required this.onTap,
    required this.label,
    this.size = 44,
    this.phase = 0,
    super.key,
  });

  final VoidCallback onTap;

  /// What's locked, for screen readers.
  final String label;
  final double size;

  /// Offsets the bob (0 to 1) so pins side by side don't move in step.
  final double phase;

  @override
  State<LockPin> createState() => _LockPinState();
}

class _LockPinState extends State<LockPin> with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Semantics(
      button: true,
      label: widget.label,
      child: AnimatedBuilder(
        animation: _bob,
        builder: (context, child) => Transform.translate(
          offset: Offset(
            0,
            -2.5 *
                (1 -
                    math.cos(
                      (_bob.value + widget.phase) * 2 * math.pi,
                    )),
          ),
          child: child,
        ),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: scheme.surface,
              shape: BoxShape.circle,
              boxShadow: context.cardShadow,
            ),
            child: Icon(
              CarbonIcons.locked,
              size: widget.size * 0.4,
              color: scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
