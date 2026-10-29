import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
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
import 'package:pushup_bro/core/model/appearance.dart';
import 'package:pushup_bro/core/model/environment.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/model/shared_preferences_key.dart';
import 'package:pushup_bro/core/platform/system_locale.dart';
import 'package:pushup_bro/core/provider/audio_player_provider.dart';
import 'package:pushup_bro/core/provider/db_provider.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/core/style/theme.dart';
import 'package:pushup_bro/features/app_icon/app_icon_guard.dart';
import 'package:pushup_bro/features/menu/model/routes.dart';
import 'package:pushup_bro/features/onboarding/cubit/onboarding_cubit.dart';
import 'package:pushup_bro/features/pro/cubit/pro_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/airpods_tracker_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/news_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/cubit/pushup_cubit.dart';
import 'package:pushup_bro/features/pushup_tracking/provider/airpods_motion_provider.dart';
import 'package:pushup_bro/features/reminders/cubit/reminders_cubit.dart';
import 'package:pushup_bro/features/reminders/data/reminder_service.dart';
import 'package:pushup_bro/features/reminders/reminders_scope.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/cubit/cloud_save.dart';
import 'package:pushup_bro/features/social/cubit/social_sync.dart';
import 'package:pushup_bro/features/social/data/social_backend.dart';
import 'package:pushup_bro/features/social/social_setup.dart';
import 'package:pushup_bro/features/social/widgets/head_portraits.dart';
import 'package:pushup_bro/features/widgets/widget_sync.dart';
import 'package:pushup_bro/generated/l10n.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(Main(social: UnavailableSocialBackend()));
}

class Main extends StatelessWidget {
  const Main({required this.social, super.key});

  /// Firebase, or a stand-in where it isn't set up (see
  /// `createSocialBackend`).
  final SocialBackend social;

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
    ProCubit proCubit,
    OnboardingCubit onboardingCubit,
    AccountCubit accountCubit,
    CloudSave cloudSave,
    SocialSync socialSync,
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
    await sharedPreferencesCubit.loadWorkoutSettings();
    // Sounds follow the volumes in the settings.
    final audio = GameAudio.instance
      ..sfxVolume = sharedPreferencesCubit.state.volumeLevel ?? 10
      ..musicVolume = sharedPreferencesCubit.state.musicVolume;
    sharedPreferencesCubit.stream.listen((state) {
      audio
        ..sfxVolume = state.volumeLevel ?? 10
        ..musicVolume = state.musicVolume;
    });
    await audio.init();
    await dbProvider.loadDB();
    await dbCubit.getUser();
    // Reminders and widgets plan from the saved sets.
    await dbCubit.getAllPushupSets();
    await gameInventoryCubit.fetchInventory();
    // After the sets: the onboarding skips the first set for players who
    // already have some.
    await onboardingCubit.load();
    // The free days start on the first launch; the store loads alongside.
    unawaited(proCubit.load());
    // The anonymous account, then scores and saves follow the game.
    socialSync.start();
    cloudSave.start();
    final monkeys = gameInventoryCubit.state.inventory.monkeys;
    unawaited(
      accountCubit.start(
        look: monkeys.isEmpty ? const MonkeyLook() : monkeys.first.look,
      ),
    );
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
    final proCubit = ProCubit(sharedPreferencesProvider);
    final remindersCubit =
        RemindersCubit(sharedPreferencesProvider, LocalReminderService());
    final onboardingCubit = OnboardingCubit(sharedPreferencesProvider);
    final accountCubit = AccountCubit(social, sharedPreferencesProvider)
      ..onSignedIn = (uid) => unawaited(proCubit.logIn(uid));
    proCubit.onBecamePro = () => unawaited(accountCubit.markUpgradePrompt());
    final cloudSave = CloudSave(
      account: accountCubit,
      pro: proCubit,
      source: GameBackupSource(
        db: dbProvider,
        dbCubit: dbCubit,
        inventory: gameInventoryCubit,
      ),
    );
    final socialSync = SocialSync(
      account: accountCubit,
      db: dbCubit,
      inventory: gameInventoryCubit,
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
        BlocProvider<ProCubit>(
          create: (context) => proCubit,
        ),
        BlocProvider<RemindersCubit>(
          create: (context) => remindersCubit,
        ),
        BlocProvider<OnboardingCubit>(
          create: (context) => onboardingCubit,
        ),
        BlocProvider<AccountCubit>(
          create: (context) => accountCubit,
        ),
        RepositoryProvider<CloudSave>.value(value: cloudSave),
      ],
      child: FutureBuilder(
        future: _initConfig(
          sharedPreferencesProvider,
          sharedPreferencesCubit,
          dbProvider,
          dbCubit,
          gameInventoryCubit,
          proCubit,
          onboardingCubit,
          accountCubit,
          cloudSave,
          socialSync,
        ),
        builder: (context, snapshot) =>
            BlocBuilder<SharedPreferencesCubit, SharedPreferencesState>(
          buildWhen: (previous, current) =>
              previous.language != current.language ||
              previous.appearance != current.appearance,
          builder: (context, prefs) => _ThemedApp(
            appearance: prefs.appearance,
            locale: prefs.language,
          ),
        ),
      ),
    );
  }
}

/// The app in light or dark mode, by the appearance setting and the phone.
class _ThemedApp extends StatelessWidget {
  const _ThemedApp({required this.appearance, required this.locale});

  final Appearance appearance;
  final Locale? locale;

  @override
  Widget build(BuildContext context) {
    final brightness =
        appearance.resolve(MediaQuery.platformBrightnessOf(context));
    final themeData = brightness == Brightness.dark ? darkTheme : lightTheme;

    return Theme(
      data: themeData,
      child: CupertinoApp(
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
        theme: MaterialBasedCupertinoThemeData(materialTheme: themeData),
        onGenerateRoute: generateRoutes,
        // Below Localizations: these read translated strings.
        builder: (context, child) => WidgetSyncScope(
          child: AppIconProGuard(
            child: RemindersScope(
              child: Theme(
                data: themeData,
                child: HeadPortraitStudio(child: child!),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
