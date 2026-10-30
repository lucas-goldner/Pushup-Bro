import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/widgets/one_move.dart';

/// Fades out like the jungle screens before it closes.
class _Fading extends StatefulWidget {
  const _Fading();

  @override
  State<_Fading> createState() => _FadingState();
}

class _FadingState extends State<_Fading> with OneMove {
  bool _white = false;

  Future<void> _close() => oneMove(() async {
        setState(() => _white = true);
        await Future<void>.delayed(const Duration(milliseconds: 450));
        if (!popIfOnTop() && mounted) setState(() => _white = false);
      });

  @override
  Widget build(BuildContext context) => Column(
        children: [
          TextButton(onPressed: _close, child: const Text('close')),
          if (_white) const Text('white'),
        ],
      );
}

void main() {
  Future<void> open(WidgetTester tester, {int depth = 2}) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigator, home: const Text('island')),
    );
    for (var i = 0; i < depth; i++) {
      navigator.currentState!.push(
        PageRouteBuilder<void>(pageBuilder: (_, __, ___) => const _Fading()),
      );
      await tester.pumpAndSettle();
    }
  }

  testWidgets('tapping close again while it fades closes one screen',
      (tester) async {
    await open(tester);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('close'));
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // The jungle is still there, and the island below it.
    expect(find.text('close'), findsOneWidget);
    await tester.tap(find.text('close'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('island'), findsOneWidget);
  });

  testWidgets('can close again after a move finished', (tester) async {
    await open(tester, depth: 1);
    await tester.tap(find.text('close'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('island'), findsOneWidget);
  });

  testWidgets('fades back in when something covers it instead of closing',
      (tester) async {
    await open(tester, depth: 1);
    final state = tester.state<_FadingState>(find.byType(_Fading));
    unawaited(state._close());
    await tester.pump();
    expect(find.text('white'), findsOneWidget);
    // A sheet opens over it while it fades out.
    unawaited(
      showDialog<void>(
        context: state.context,
        builder: (_) => const Text('sheet'),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));

    expect(find.text('sheet'), findsOneWidget);
    expect(find.text('white'), findsNothing);
    expect(find.text('close'), findsOneWidget);
  });
}
