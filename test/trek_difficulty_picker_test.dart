import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/model/trek_progress.dart';
import 'package:pushup_bro/core/provider/db_provider.dart';
import 'package:pushup_bro/core/style/theme.dart';
import 'package:pushup_bro/features/trek/model/trek.dart';
import 'package:pushup_bro/features/trek/widgets/difficulty_picker.dart';
import 'package:pushup_bro/generated/l10n.dart';

Future<void> _pump(
  WidgetTester tester,
  TrekProgress trek, {
  Locale locale = const Locale('en'),
}) async {
  // The stage panel on a 320 pt phone: 16 pt margins and 20 pt padding.
  tester.view
    ..physicalSize = const Size(320, 640)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    BlocProvider(
      create: (_) => GameInventoryCubit(DBProvider()),
      child: MaterialApp(
        theme: lightTheme,
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        locale: locale,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(36),
            child: DifficultyPicker(trek: trek),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final locale in S.delegate.supportedLocales) {
    testWidgets('fits a small phone in ${locale.languageCode}', (tester) async {
      for (final difficulty in TrekDifficulty.values) {
        await _pump(
          tester,
          TrekProgress(
            difficulty: difficulty.name,
            stars: {TrekStage.all.last.id: 1},
          ),
          locale: locale,
        );
        expect(tester.takeException(), isNull);
      }
    });
  }

  testWidgets('a locked Brutal says how to open it', (tester) async {
    await _pump(tester, const TrekProgress());
    await tester.tap(find.text(S.current.trekBrutal));
    await tester.pumpAndSettle();
    expect(find.text(S.current.trekBrutalLocked), findsOneWidget);
  });
}
