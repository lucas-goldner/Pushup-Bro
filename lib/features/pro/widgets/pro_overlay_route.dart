import 'package:flutter/widgets.dart';

/// Shows [builder] over the current screen on the root navigator, for the
/// app's sheets that blur what's behind them themselves (like
/// `IslandSheet`). It appears at once and fades out when popped.
Future<T?> showProOverlay<T>(BuildContext context, WidgetBuilder builder) =>
    Navigator.of(context, rootNavigator: true).push<T>(
      PageRouteBuilder<T>(
        opaque: false,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, _, __) => builder(context),
        transitionsBuilder: (context, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
