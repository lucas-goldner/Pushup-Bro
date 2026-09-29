import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl_standalone.dart';
import 'package:pushup_bro/cubit/airpods_tracker/airpods_tracker_cubit.dart';
import 'package:pushup_bro/cubit/db/db_cubit.dart';
import 'package:pushup_bro/cubit/pushups/pushup_cubit.dart';
import 'package:pushup_bro/cubit/shared_preferences/shared_preferences_cubit.dart';
import 'package:pushup_bro/cubit/shared_preferences/shared_preferences_state.dart';
import 'package:pushup_bro/flavor/flavor.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:pushup_bro/model/enum/environment.dart';
import 'package:pushup_bro/model/enum/shared_preferences_key.dart';
import 'package:pushup_bro/provider/airpods_motion_provider.dart';
import 'package:pushup_bro/provider/audio_player_provider.dart';
import 'package:pushup_bro/provider/db_provider.dart';
import 'package:pushup_bro/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/ui/routes.dart';
import 'package:pushup_bro/ui/styles/pb_text_styles.dart';
import 'package:pushup_bro/utils/constants.dart';
import 'package:pushup_bro/utils/extensions/string_extensions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting().then((_) => runApp(const Main()));
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

  void _initConfig(
    SharedPreferencesProvider sharedPreferencesProvider,
    SharedPreferencesCubit sharedPreferencesCubit,
    DBProvider dbProvider,
  ) {
    unawaited(
      SystemChrome.setPreferredOrientations(
        [DeviceOrientation.portraitUp],
      ),
    );
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarBrightness: Brightness.light,
      ),
    );
    unawaited(setAudioContext());
    unawaited(
      initializeSharedPreferences(
        sharedPreferencesProvider,
        sharedPreferencesCubit,
      ),
    );
    unawaited(sharedPreferencesCubit.getLanguage());
    if (!dbProvider.initialized) unawaited(dbProvider.loadDB());
  }

  @override
  Widget build(BuildContext context) {
    // Providers
    final audioPlayer = AudioPlayer(playerId: Constants.audioPlayerId);
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

    // Configuration
    _initConfig(
      sharedPreferencesProvider,
      sharedPreferencesCubit,
      dbProvider,
    );

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
      ],
      child:
          BlocSelector<SharedPreferencesCubit, SharedPreferencesState, Locale?>(
        selector: (state) => state.language,
        builder: (builder, locale) => CupertinoApp(
          debugShowCheckedModeBanner:
              Flavor.getCurrentEnvironment == Environment.dev.getFlavorName(),
          key: const Key('MainApp'),
          localizationsDelegates: const [
            S.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          locale: locale,
          supportedLocales: S.delegate.supportedLocales,
          theme: const CupertinoThemeData(
            brightness: Brightness.dark,
            textTheme: CupertinoTextThemeData(
              textStyle: PBTextStyles.defaultTextStyle,
            ),
          ),
          onGenerateRoute: (settings) =>
              RouteGenerator().onGenerateMainRoutes(settings),
        ),
      ),
    );
  }
}
