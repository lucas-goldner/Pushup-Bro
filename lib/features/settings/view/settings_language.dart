import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_state.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/utils/get_localized_language_name.dart';
import 'package:pushup_bro/core/widgets/pb_button.dart';
import 'package:pushup_bro/features/settings/widgets/settings_group.dart';
import 'package:pushup_bro/generated/l10n.dart';

class LanguageSetting extends StatefulWidget {
  const LanguageSetting({super.key});
  static const routeName = '/language';

  @override
  State<LanguageSetting> createState() => _LanguageSettingState();
}

class _LanguageSettingState extends State<LanguageSetting> {
  List<Locale> supportedLanguages = S.delegate.supportedLocales;
  String _selectedLocale = '';

  @override
  void initState() {
    super.initState();
    unawaited(_getLanguage());
  }

  Future<void> _getLanguage() async {
    final lang =
        await BlocProvider.of<SharedPreferencesCubit>(context).getLanguage();
    setState(() => _selectedLocale = lang);
  }

  Future<void> _updateLanguage(Locale lang) async {
    final sharedPrefCubit = BlocProvider.of<SharedPreferencesCubit>(context);
    await sharedPrefCubit.setLanguage(lang);
    setState(() => _selectedLocale = lang.languageCode);
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SharedPreferencesCubit, SharedPreferencesState>(
        builder: (context, state) => CupertinoPageScaffold(
          backgroundColor: context.colorScheme.surfaceContainerLow,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    PBSpace.xl,
                    PBSpace.lg,
                    PBSpace.xl,
                    PBSpace.sm,
                  ),
                  child: Text(
                    context.l10n.switchLanguage,
                    style: context.textTheme.headlineLarge,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: PBSpace.lg),
                    child: SettingsGroup(
                      children: [
                        for (final language in supportedLanguages)
                          SettingsRow(
                            label: LanguageLocal()
                                .getDisplayLanguage(language.languageCode)
                                .toString(),
                            onTap: () => _updateLanguage(language),
                            trailing: _selectedLocale == language.languageCode
                                ? Icon(
                                    CarbonIcons.checkmark,
                                    size: 20,
                                    color: context.colorScheme.secondary,
                                  )
                                : const SizedBox(width: 20),
                          ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    PBSpace.sm,
                    PBSpace.sm,
                    PBSpace.sm,
                    PBSpace.lg,
                  ),
                  child: PBButton(
                    context.l10n.goBack,
                    callback: () => Navigator.of(context).pop(),
                    expanded: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
