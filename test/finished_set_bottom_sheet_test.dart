import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/cubit/active_effects_cubit.dart';
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/cubit/feature_switch_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/model/game_inventory.dart';
import 'package:pushup_bro/core/model/pushup.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/core/model/user.dart';
import 'package:pushup_bro/core/provider/db_provider.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/core/style/theme.dart';
import 'package:pushup_bro/features/pushup_tracking/widgets/finished_pushup_sheet/finished_set_bottom_sheet.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory stand-in for the MMKV-backed provider, which needs the native
/// MMKV library and so cannot run under `flutter test`.
class _InMemoryDBProvider extends DBProvider {
  final pushupSets = <PushupSet>[];
  User user = User.empty();
  GameInventory inventory = GameInventory.empty();

  @override
  bool get initialized => true;

  @override
  Future<void> loadDB() async {}

  @override
  Future<User> getUser() async => user;

  @override
  Future<User> createUser({int xp = 0, int level = 1}) async {
    return user = User.empty().copyWith(xp: xp, level: level);
  }

  @override
  Future<void> updateUser(User user) async => this.user = user;

  @override
  Future<GameInventory> getInventory() async => inventory;

  @override
  Future<GameInventory> createInventory() async =>
      inventory = GameInventory.empty();

  @override
  Future<void> updateInventory(GameInventory inventory) async =>
      this.inventory = inventory;

  @override
  Future<void> addNewPushupSet(PushupSet pushupSet) async =>
      pushupSets.add(pushupSet);

  @override
  Future<void> deletePushupSet(int id) async =>
      pushupSets.removeWhere((set) => set.id == id);

  @override
  Future<List<PushupSet>> getAllPushupSets() async => [...pushupSets];
}

/// WCAG relative contrast ratio between two opaque colors.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final lighter = la > lb ? la : lb;
  final darker = la > lb ? lb : la;

  return (lighter + 0.05) / (darker + 0.05);
}

PushupSet buildPushupSet(int pushups) => PushupSet(
      List.generate(
        pushups,
        (i) => Pushup(completedAt: DateTime(2026, 10, 4, 12, 0, i)),
      ),
      0,
    );

void main() {
  late _InMemoryDBProvider dbProvider;
  late ActiveEffectsCubit activeEffectsCubit;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    dbProvider = _InMemoryDBProvider();
    activeEffectsCubit = ActiveEffectsCubit();
  });

  /// Mirrors the real app shell in lib/main.dart: a dark `CupertinoApp`
  /// under the app's Material [lightTheme].
  Widget wrapInApp(Widget child) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => activeEffectsCubit),
          BlocProvider(create: (_) => DBCubit(dbProvider)),
          BlocProvider(create: (_) => FeatureSwitchCubit()),
          BlocProvider(create: (_) => GameInventoryCubit(dbProvider)),
          BlocProvider(
            create: (_) => SharedPreferencesCubit(SharedPreferencesProvider()),
          ),
        ],
        child: Theme(
          data: lightTheme,
          child: CupertinoApp(
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: S.delegate.supportedLocales,
            locale: const Locale('en'),
            theme: const CupertinoThemeData(brightness: Brightness.dark),
            home: CupertinoPageScaffold(child: child),
          ),
        ),
      );

  Material sheetMaterial(WidgetTester tester) => tester.widget<Material>(
        find
            .descendant(
              of: find.byType(FinishedSetBottomSheet),
              matching: find.byType(Material),
            )
            .first,
      );

  group('FinishedSetBottomSheet', () {
    testWidgets('paints the app surface instead of a derived dark canvas',
        (tester) async {
      await tester.pumpWidget(
        wrapInApp(FinishedSetBottomSheet(buildPushupSet(2))),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(sheetMaterial(tester).color, lightTheme.colorScheme.surface);
    });

    testWidgets('text contrasts with the surface', (tester) async {
      await tester.pumpWidget(
        wrapInApp(FinishedSetBottomSheet(buildPushupSet(2))),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // The resolved style, after DefaultTextStyle and theme merging.
      final textColor = tester
          .renderObject<RenderParagraph>(find.text('Congrats!'))
          .text
          .style!
          .color!;
      expect(
        contrastRatio(textColor, sheetMaterial(tester).color!),
        greaterThan(4.5),
      );
    });

    testWidgets('opens after a previous set cleared the active effects',
        (tester) async {
      // Saving a set calls `clearEffects`, which leaves the cubit activated
      // with an empty list; the next sheet used to throw on `reduce`.
      activeEffectsCubit.clearEffects();

      await tester.pumpWidget(
        wrapInApp(FinishedSetBottomSheet(buildPushupSet(3))),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      expect(tester.takeException(), isNull);
      expect(find.text('Congrats!'), findsOneWidget);
    });

    testWidgets('saving a set earns one banana per pushup', (tester) async {
      dbProvider.inventory = GameInventory.empty().copyWith(bananas: 5);

      await tester.pumpWidget(
        wrapInApp(FinishedSetBottomSheet(buildPushupSet(7))),
      );
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await tester.ensureVisible(find.text('Save set'));
      await tester.tap(find.text('Save set'));
      await tester.pumpAndSettle();

      expect(dbProvider.inventory.bananas, 12);
      expect(dbProvider.pushupSets, hasLength(1));
      expect(dbProvider.pushupSets.single.pushups, hasLength(7));
    });
  });
}
