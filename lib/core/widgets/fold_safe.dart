import 'package:flutter/widgets.dart';

/// Keeps controls off the fold of a half-open foldable (the iPhone Duo held
/// like a book or a laptop): they move into the half of the window that
/// [anchor] points at, and are at most [maxWidth] wide, centred there.
///
/// On a phone without a fold, or a foldable lying flat, only [maxWidth]
/// applies. The fold comes from `MediaQuery.displayFeatures`, which the
/// app's `FoldableProvider` fills on iPhone Duo.
class FoldSafe extends StatelessWidget {
  const FoldSafe({
    required this.child,
    this.anchor = const Offset(double.maxFinite, double.maxFinite),
    this.maxWidth = double.infinity,
    this.alignment = Alignment.bottomCenter,
    super.key,
  });

  /// Where the controls sit in their half.
  final AlignmentGeometry alignment;

  /// Bottom right by default: where the thumb is.
  final Offset anchor;
  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) => DisplayFeatureSubScreen(
        anchorPoint: anchor,
        child: Align(
          alignment: alignment,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        ),
      );
}
