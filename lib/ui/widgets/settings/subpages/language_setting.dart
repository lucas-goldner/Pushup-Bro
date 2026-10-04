import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/cubit/shared_preferences/shared_preferences_cubit.dart';
import 'package:pushup_bro/cubit/shared_preferences/shared_preferences_state.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:pushup_bro/ui/styles/pb_colors.dart';
import 'package:pushup_bro/ui/styles/pb_text_styles.dart';
import 'package:pushup_bro/ui/widgets/common/pb_button.dart';
import 'package:pushup_bro/utils/get_localized_language_name.dart';

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
    setState(() {
      _selectedLocale = lang.languageCode;
    });
  }

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<SharedPreferencesCubit, SharedPreferencesState>(
        builder: (context, state) => CupertinoPageScaffold(
          backgroundColor: PBColors.background,
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    SingleChildScrollView(
                      child: Text(
                        S.of(context).switchLanguage,
                        style: PBTextStyles.pageTitleTextStyle,
                      ),
                    ),
                    Column(
                      children: [
                        for (var i = 0;
                            i <= supportedLanguages.length - 1;
                            i++) ...{
                          GestureDetector(
                            onTap: () => _updateLanguage(supportedLanguages[i]),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(
                                    16,
                                  ),
                                  child: Text(
                                    LanguageLocal()
                                        .getDisplayLanguage(
                                          supportedLanguages[i].languageCode,
                                        )
                                        .toString(),
                                  ),
                                ),
                                const Spacer(),
                                if (_selectedLocale ==
                                    supportedLanguages[i].languageCode)
                                  const Icon(CarbonIcons.checkmark),
                                const SizedBox(
                                  width: 16,
                                ),
                              ],
                            ),
                          ),
                          const Divider(
                            height: 2,
                          ),
                        },
                      ],
                    ),
                    const Spacer(),
                    PBButton(
                      S.of(context).goBack,
                      callback: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
}
