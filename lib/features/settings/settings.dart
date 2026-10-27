import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/tracking_mode.dart';
import 'package:pushup_bro/core/model/website_links.dart';
import 'package:pushup_bro/core/provider/url_launch_provider.dart';
import 'package:pushup_bro/features/pushup_tracking/widgets/tracking_mode_picker.dart';
import 'package:pushup_bro/features/settings/view/settings_language.dart';
import 'package:pushup_bro/features/settings/view/settings_volume.dart';
import 'package:pushup_bro/features/settings/widgets/info_item.dart';
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

  Uri createURI(String path) => Uri(scheme: 'https', path: path);

  void navigateToSettingPage(String routeName) =>
      Navigator.of(context).pushNamed(routeName);

  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(
              height: 80,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                context.l10n.general,
                style: context.textTheme.titleSmall,
                textAlign: TextAlign.start,
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            Settingsitem(
              context.l10n.switchLanguage,
              CarbonIcons.language,
              () => navigateToSettingPage(LanguageSetting.routeName),
            ),
            const SizedBox(
              height: 8,
            ),
            Settingsitem(
              context.l10n.setVolume,
              CarbonIcons.volume_up,
              () => navigateToSettingPage(VolumeSetting.routeName),
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                context.l10n.trackingTitle,
                style: context.textTheme.titleSmall,
                textAlign: TextAlign.start,
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            const Center(child: TrackingModePicker()),
            const SizedBox(
              height: 8,
            ),
            BlocSelector<SharedPreferencesCubit, SharedPreferencesState,
                TrackingMode>(
              selector: (state) => state.trackingMode,
              builder: (context, mode) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  mode == TrackingMode.camera
                      ? context.l10n.trackingCameraTip
                      : context.l10n.trackingAirpodsTip,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall,
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                context.l10n.info,
                style: context.textTheme.titleSmall,
                textAlign: TextAlign.start,
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            InfoItem(
              context.l10n.website,
              CarbonIcons.explore,
              () => openBrowser(createURI(WebsiteLinks.personalSite.link)),
            ),
            const SizedBox(
              height: 8,
            ),
            InfoItem(
              context.l10n.twitter,
              CarbonIcons.logo_twitter,
              () => openBrowser(createURI(WebsiteLinks.twitter.link)),
            ),
            const SizedBox(
              height: 8,
            ),
            InfoItem(
              context.l10n.privacyPolicy,
              CarbonIcons.virtual_private_cloud,
              () => openBrowser(createURI(WebsiteLinks.privacyPolicy.link)),
            ),
            const SizedBox(
              height: 8,
            ),
            InfoItem(
              context.l10n.termsOfService,
              CarbonIcons.term,
              () => openBrowser(createURI(WebsiteLinks.termsOfService.link)),
            ),
            const SizedBox(
              height: 8,
            ),
            InfoItem(
              context.l10n.licenses,
              CarbonIcons.credentials,
              () => showLicensePage(
                context: context,
                applicationName: 'Pushup Bro',
              ),
            ),
          ],
        ),
      );
}
