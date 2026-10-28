import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/tracking_mode.dart';
import 'package:pushup_bro/core/model/website_links.dart';
import 'package:pushup_bro/core/provider/url_launch_provider.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/app_icon/app_icon_page.dart';
import 'package:pushup_bro/features/pro/paywall/show_paywall.dart';
import 'package:pushup_bro/features/pushup_tracking/widgets/tracking_mode_picker.dart';
import 'package:pushup_bro/features/reminders/reminders_page.dart';
import 'package:pushup_bro/features/settings/view/settings_language.dart';
import 'package:pushup_bro/features/settings/view/settings_volume.dart';
import 'package:pushup_bro/features/settings/widgets/appearance_picker.dart';
import 'package:pushup_bro/features/settings/widgets/info_item.dart';
import 'package:pushup_bro/features/settings/widgets/settings_group.dart';
import 'package:pushup_bro/features/settings/widgets/settings_item.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});
  static const routeName = '/settings';

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final _launchProvider = UrlLauncherProvider(const UrlLauncherService());

  void openBrowser(Uri uri) => _launchProvider.launchUri(uri);

  Uri createURI(String link) => Uri.parse('https://$link');

  void navigateToSettingPage(String routeName) =>
      Navigator.of(context).pushNamed(routeName);

  @override
  Widget build(BuildContext context) {
    final game = context.gameColors;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(bottom: PBSpace.xxl),
        children: [
          const SizedBox(height: 64),
          SettingsSectionHeader(context.l10n.general),
          SettingsGroup(
            children: [
              Settingsitem(
                context.l10n.switchLanguage,
                CarbonIcons.language,
                () => navigateToSettingPage(LanguageSetting.routeName),
              ),
              Settingsitem(
                context.l10n.setVolume,
                CarbonIcons.volume_up,
                () => navigateToSettingPage(VolumeSetting.routeName),
                color: game.orange,
              ),
              Settingsitem(
                context.l10n.reminderPageTitle,
                CarbonIcons.notification,
                () => RemindersPage.open(context),
                color: game.jungle,
              ),
              if (AppIconPage.isAvailable)
                Settingsitem(
                  context.l10n.appIconTitle,
                  CarbonIcons.apps,
                  () => AppIconPage.open(context),
                  color: game.purple,
                ),
              Settingsitem(
                context.l10n.proSettingsTitle,
                CarbonIcons.star_filled,
                () => showPaywall(context),
                color: game.banana,
              ),
            ],
          ),
          SettingsSectionHeader(context.l10n.appearanceTitle),
          const AppearancePicker(),
          SettingsSectionHeader(context.l10n.trackingTitle),
          const Center(child: TrackingModePicker()),
          const SizedBox(height: PBSpace.sm),
          BlocSelector<SharedPreferencesCubit, SharedPreferencesState,
              TrackingMode>(
            selector: (state) => state.trackingMode,
            builder: (context, mode) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: PBSpace.xl),
              child: Text(
                mode == TrackingMode.camera
                    ? context.l10n.trackingCameraTip
                    : context.l10n.trackingAirpodsTip,
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall,
              ),
            ),
          ),
          SettingsSectionHeader(context.l10n.info),
          SettingsGroup(
            children: [
              InfoItem(
                context.l10n.website,
                CarbonIcons.explore,
                () => openBrowser(createURI(WebsiteLinks.personalSite.link)),
                color: game.jungle,
              ),
              InfoItem(
                context.l10n.twitter,
                CarbonIcons.logo_twitter,
                () => openBrowser(createURI(WebsiteLinks.twitter.link)),
              ),
              InfoItem(
                context.l10n.privacyPolicy,
                CarbonIcons.virtual_private_cloud,
                () => openBrowser(createURI(WebsiteLinks.privacyPolicy.link)),
                color: game.purple,
              ),
              InfoItem(
                context.l10n.termsOfService,
                CarbonIcons.term,
                () => openBrowser(createURI(WebsiteLinks.termsOfService.link)),
                color: game.coral,
              ),
              InfoItem(
                context.l10n.licenses,
                CarbonIcons.credentials,
                () => showLicensePage(
                  context: context,
                  applicationName: 'Pushup Bro',
                ),
                color: context.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
