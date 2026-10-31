import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// The width full-screen designs are laid out at, at most.
const kPhoneCanvasMaxWidth = 480.0;

/// The height full-screen designs need to fit without scrolling.
const kPhoneCanvasMinHeight = 760.0;

/// Lays out a full-screen design (onboarding steps, the paywall, the Pro
/// celebration) the way it was drawn: phone sized.
///
/// - On a wide window (the iPhone Duo's inner display, an iPad) it stays
///   [maxWidth] wide, centred, and the side insets it no longer touches
///   are dropped, so a strip at the edge doesn't pad it twice.
/// - On a short window (the iPhone Duo's cover display, an iPhone SE) the
///   whole design is laid out at [minHeight] and scaled down to fit, rather
///   than overflowing at the bottom.
class PhoneCanvas extends StatelessWidget {
  const PhoneCanvas({
    required this.child,
    this.maxWidth = kPhoneCanvasMaxWidth,
    this.minHeight = kPhoneCanvasMinHeight,
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final double minHeight;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final width = math.min(constraints.maxWidth, maxWidth);
          final height = constraints.maxHeight;
          final side = (constraints.maxWidth - width) / 2;
          final media = MediaQuery.of(context);

          EdgeInsets trim(EdgeInsets insets) => insets.copyWith(
                left: math.max(0, insets.left - side),
                right: math.max(0, insets.right - side),
              );

          final scale = height < minHeight ? height / minHeight : 1.0;
          Widget content = MediaQuery(
            // Designs that size themselves from the screen see the canvas.
            data: media.copyWith(
              size: Size(width / scale, height / scale),
              padding: trim(media.padding),
              viewPadding: trim(media.viewPadding),
            ),
            child: SizedBox(
              width: width / scale,
              height: height / scale,
              child: child,
            ),
          );
          if (scale < 1) {
            content = FittedBox(child: content);
          }

          return Center(
            child: SizedBox(width: width, height: height, child: content),
          );
        },
      );
}
