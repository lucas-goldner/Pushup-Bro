import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pushup_bro/core/constants.dart';
import 'package:pushup_bro/core/cubit/active_effects_cubit.dart';
import 'package:pushup_bro/core/cubit/booster_item_cubit.dart';
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/cubit/feature_switch_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_state.dart';
import 'package:pushup_bro/core/extensions/string_ext.dart';
import 'package:pushup_bro/core/flavor.dart';
import 'package:pushup_bro/core/model/environment.dart';
import 'package:pushup_bro/core/model/shared_preferences_key.dart';
import 'package:pushup_bro/core/platform/system_locale.dart';
import 'package:pushup_bro/core/provider/audio_player_provider.dart';
import 'package:pushup_bro/core/provider/db_provider.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/core/style/theme.dart';
import 'package:pushup_bro/features/menu/model/routes.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/airpods_tracker_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/news_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/pushup_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/provider/airpods_motion_provider.dart';
import 'package:pushup_bro/generated/l10n.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Main());
}

class Main extends StatelessWidget {
  const Main({super.key});

  Future<void> setAudioContext() async {
    final audioContext = AudioContext(
      iOS: AudioContextIOS(
        options: const {
          AVAudioSessionOptions.mixWithOthers,
        },
      ),
    );
    await AudioPlayer.global.setAudioContext(audioContext);
    AudioLogger.logLevel = AudioLogLevel.error;
  }

  Future<void> initializeSharedPreferences(
    SharedPreferencesProvider sharedPreferencesProvider,
    SharedPreferencesCubit sharedPreferencesCubit,
  ) async {
    final selectedLanguage = await sharedPreferencesProvider
        .getSharedPrefString(SharedPreferencesKey.language);

    final systemLocale = await findSystemLocale();
    await sharedPreferencesCubit.setLanguage(
      selectedLanguage != null
          ? Locale(selectedLanguage)
          : Locale(systemLocale.getLanguageCode()),
    );

    await sharedPreferencesCubit.setFirstJoined();
  }

  Future<void> _initConfig(
    SharedPreferencesProvider sharedPreferencesProvider,
    SharedPreferencesCubit sharedPreferencesCubit,
    DBProvider dbProvider,
    DBCubit dbCubit,
    GameInventoryCubit gameInventoryCubit,
  ) async {
    await initializeDateFormatting();
    if (!kIsWeb) {
      await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp],
      );
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle.dark.copyWith(
          statusBarBrightness: Brightness.light,
        ),
      );
    }
    await setAudioContext();
    await initializeSharedPreferences(
      sharedPreferencesProvider,
      sharedPreferencesCubit,
    );
    await sharedPreferencesCubit.getLanguage();
    await sharedPreferencesCubit.getFirstTimeIslandVisited();
    await dbProvider.loadDB();
    await dbCubit.getUser();
    await gameInventoryCubit.fetchInventory();
  }

  @override
  Widget build(BuildContext context) {
    // Providers
    final audioPlayer = AudioPlayer(playerId: audioPlayerId);
    final audioPlayerProvider = AudioPlayerProvider(audioPlayer);
    final airpodsMotionProvider = AirPodsMotionProvider();
    final sharedPreferencesProvider = SharedPreferencesProvider();
    unawaited(sharedPreferencesProvider.loadSharedPrefs());
    final dbProvider = DBProvider();

    // Cubits
    final airpodsTrackerCubit = AirPodsTrackerCubit(airpodsMotionProvider);
    final pushupCubit = PushupCubit(audioPlayerProvider);
    final sharedPreferencesCubit =
        SharedPreferencesCubit(sharedPreferencesProvider);
    final dbCubit = DBCubit(dbProvider);
    final activeEffectsCubit = ActiveEffectsCubit();
    final boosterItemsCubit = BoosterItemCubit();
    final newsCubit = NewsCubit();
    final featureSwitchCubit = FeatureSwitchCubit();
    final gameInventoryCubit = GameInventoryCubit(dbProvider);

    return MultiBlocProvider(
      providers: [
        BlocProvider<AirPodsTrackerCubit>(
          create: (context) => airpodsTrackerCubit,
        ),
        BlocProvider<PushupCubit>(
          create: (context) => pushupCubit,
        ),
        BlocProvider<SharedPreferencesCubit>(
          create: (context) => sharedPreferencesCubit,
        ),
        BlocProvider<DBCubit>(
          create: (context) => dbCubit,
        ),
        BlocProvider<ActiveEffectsCubit>(
          create: (context) => activeEffectsCubit,
        ),
        BlocProvider<BoosterItemCubit>(
          create: (context) => boosterItemsCubit,
        ),
        BlocProvider<NewsCubit>(
          create: (context) => newsCubit,
        ),
        BlocProvider<FeatureSwitchCubit>(
          create: (context) => featureSwitchCubit,
        ),
        BlocProvider<GameInventoryCubit>(
          create: (context) => gameInventoryCubit,
        ),
      ],
      child: FutureBuilder(
        future: _initConfig(
          sharedPreferencesProvider,
          sharedPreferencesCubit,
          dbProvider,
          dbCubit,
          gameInventoryCubit,
        ),
        builder: (context, snapshot) => BlocSelector<SharedPreferencesCubit,
            SharedPreferencesState, Locale?>(
          selector: (state) => state.language,
          builder: (builder, locale) => Theme(
            data: theme,
            child: CupertinoApp(
              debugShowCheckedModeBanner: Flavor.getCurrentEnvironment ==
                  Environment.dev.getFlavorName(),
              key: const Key('MainApp'),
              localizationsDelegates: const [
                S.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              locale: locale,
              supportedLocales: S.delegate.supportedLocales,
              onGenerateRoute: generateRoutes,
            ),
          ),
        ),
      ),
    );
  }
}
