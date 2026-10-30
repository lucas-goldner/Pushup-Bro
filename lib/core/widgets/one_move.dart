import 'package:flutter/widgets.dart';

/// For screens that fade through white before they open another screen or
/// close: while one move runs, more taps do nothing. Without this, a second
/// tap on close while the white fades in would pop the screen below too,
/// down to an empty navigator: a white screen that no longer responds.
mixin OneMove<T extends StatefulWidget> on State<T> {
  bool _moving = false;

  /// Runs [move] unless another move is still running.
  Future<void> oneMove(Future<void> Function() move) async {
    if (_moving) return;
    _moving = true;
    try {
      await move();
    } finally {
      _moving = false;
    }
  }

  /// Closes this screen, but only while it is the one on top. Returns
  /// whether it closed: when something else is on top, the screen that
  /// faded to white must fade back in, or it stays white for good.
  bool popIfOnTop<R extends Object?>([R? result]) {
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) {
      return false;
    }
    Navigator.of(context).pop(result);
    return true;
  }
}
