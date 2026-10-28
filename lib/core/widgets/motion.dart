import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// A clock in seconds that every [Reveal], [Pop] and [BlurWords] below it
/// reads, so a whole screen animates in on one timeline. With Reduce
/// Motion on it starts at the end.
class MotionClock extends StatefulWidget {
  const MotionClock({
    required this.child,
    this.duration = const Duration(seconds: 6),
    super.key,
  });

  final Widget child;
  final Duration duration;

  /// The seconds since the screen appeared.
  static Animation<double> of(BuildContext context) =>
      context.dependOnInheritedWidgetOrNull<_MotionScope>()?.seconds ??
      const AlwaysStoppedAnimation(1000000);

  @override
  State<MotionClock> createState() => _MotionClockState();
}

class _MotionClockState extends State<MotionClock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _seconds = _controller.drive(
    Tween(begin: 0, end: widget.duration.inMilliseconds / 1000),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_controller.isAnimating && _controller.value == 0) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _MotionScope(seconds: _seconds, child: widget.child);
}

class _MotionScope extends InheritedWidget {
  const _MotionScope({required this.seconds, required super.child});

  final Animation<double> seconds;

  @override
  bool updateShouldNotify(_MotionScope oldWidget) =>
      seconds != oldWidget.seconds;
}

extension on BuildContext {
  T? dependOnInheritedWidgetOrNull<T extends InheritedWidget>() =>
      dependOnInheritedWidgetOfExactType<T>();
}

/// How far into an animation that starts at [at] and lasts [duration]
/// seconds the clock is, from 0 to 1.
double _progress(double seconds, double at, double duration) =>
    ((seconds - at) / duration).clamp(0.0, 1.0);

/// Fades [child] in while it rises [offset] pixels, starting [at] seconds.
class Reveal extends StatelessWidget {
  const Reveal({
    required this.child,
    this.at = 0,
    this.duration = 0.5,
    this.offset = 24,
    super.key,
  });

  final Widget child;
  final double at;
  final double duration;
  final double offset;

  @override
  Widget build(BuildContext context) {
    final clock = MotionClock.of(context);

    return AnimatedBuilder(
      animation: clock,
      child: child,
      builder: (context, child) {
        final t =
            Curves.easeOutCubic.transform(_progress(clock.value, at, duration));

        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * offset),
            child: child,
          ),
        );
      },
    );
  }
}

/// Scales [child] in with a little overshoot, starting [at] seconds.
class Pop extends StatelessWidget {
  const Pop({
    required this.child,
    this.at = 0,
    this.duration = 0.45,
    super.key,
  });

  final Widget child;
  final double at;
  final double duration;

  @override
  Widget build(BuildContext context) {
    final clock = MotionClock.of(context);

    return AnimatedBuilder(
      animation: clock,
      child: child,
      builder: (context, child) {
        final t = _progress(clock.value, at, duration);
        if (t == 0) return Opacity(opacity: 0, child: child);

        return Transform.scale(
          scale: Curves.easeOutBack.transform(t).clamp(0.0, 1.2),
          child: Opacity(opacity: math.min(1, t * 2), child: child),
        );
      },
    );
  }
}

/// [text] appearing word by word out of a blur, starting [at] seconds.
/// Words between asterisks (`*like this*`) get [accent].
class BlurWords extends StatelessWidget {
  const BlurWords(
    this.text, {
    required this.style,
    this.accent,
    this.at = 0,
    this.stagger = 0.08,
    this.textAlign = TextAlign.start,
    super.key,
  });

  final String text;
  final TextStyle? style;
  final Color? accent;
  final double at;
  final double stagger;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final clock = MotionClock.of(context);
    final words = _words(text);

    return AnimatedBuilder(
      animation: clock,
      builder: (context, _) => Wrap(
        alignment: switch (textAlign) {
          TextAlign.center => WrapAlignment.center,
          TextAlign.end || TextAlign.right => WrapAlignment.end,
          _ => WrapAlignment.start,
        },
        children: [
          for (final (i, (word, accented)) in words.indexed)
            _word(
              word,
              accented,
              _progress(clock.value, at + i * stagger, 0.5),
            ),
        ],
      ),
    );
  }

  Widget _word(String word, bool accented, double t) {
    final eased = Curves.easeOut.transform(t);
    final blur = (1 - eased) * 10;
    final text = Text(
      word,
      style: accented ? style?.copyWith(color: accent) : style,
    );

    return Opacity(
      opacity: eased,
      child: Transform.translate(
        offset: Offset(0, (1 - eased) * 12),
        child: blur < 0.1
            ? text
            : ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: text,
              ),
      ),
    );
  }

  /// Splits [text] into pieces to animate one by one: each word with the
  /// space after it, and an accented run (between asterisks) apart from
  /// the text it touches, so `*腕立て*を` works without spaces too.
  static List<(String, bool)> _words(String text) {
    final result = <(String, bool)>[];
    var accented = false;
    final buffer = StringBuffer();
    void flush() {
      if (buffer.isNotEmpty) result.add((buffer.toString(), accented));
      buffer.clear();
    }

    for (final char in text.characters) {
      if (char == '*') {
        flush();
        accented = !accented;
      } else {
        buffer.write(char);
        if (char == ' ') flush();
      }
    }
    flush();
    return result;
  }
}
