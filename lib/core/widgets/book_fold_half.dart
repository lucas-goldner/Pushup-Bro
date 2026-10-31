import 'dart:ui' show DisplayFeatureState, DisplayFeatureType;

import 'package:flutter/widgets.dart';

/// Moves a screen into the right half of a foldable held open like a book
/// (the iPhone Duo with a vertical fold), so nothing sits across the fold.
/// Each half is about as wide as a phone.
///
/// A fold across the screen like a laptop's is left alone: those screens
/// keep their buttons at the bottom, below it. Without a fold this is just
/// [child].
class BookFoldHalf extends StatelessWidget {
  const BookFoldHalf({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final bookFold = MediaQuery.displayFeaturesOf(context).any(
      (feature) =>
          (feature.type == DisplayFeatureType.fold ||
              feature.type == DisplayFeatureType.hinge) &&
          feature.state != DisplayFeatureState.postureFlat &&
          feature.bounds.height >= size.height - 1 &&
          feature.bounds.left > 0,
    );
    if (!bookFold) return child;

    return DisplayFeatureSubScreen(
      anchorPoint: const Offset(double.maxFinite, 0),
      child: child,
    );
  }
}
