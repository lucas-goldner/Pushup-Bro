import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:pushup_bro/ui/styles/pb_text_styles.dart';
import 'package:pushup_bro/ui/widgets/common/pb_button.dart';
import 'package:pushup_bro/ui/widgets/common/pb_text_input.dart';

class OnboardingCreateAccount extends StatefulWidget {
  const OnboardingCreateAccount(this.navigateToPage, {super.key});
  final VoidCallback navigateToPage;

  @override
  State<OnboardingCreateAccount> createState() =>
      _OnboardingCreateAccountState();
}

class _OnboardingCreateAccountState extends State<OnboardingCreateAccount> {
  @override
  Widget build(BuildContext context) {
    final pageTitleTextStyle =
        PBTextStyles.pageTitleTextStyle.copyWith(color: CupertinoColors.white);
    final secondaryPageTextStyle =
        PBTextStyles.secondaryPageTitleTextStyle.copyWith(
      color: CupertinoColors.white,
    );
    final headerTextStyle =
        PBTextStyles.headerTextStyle.copyWith(color: CupertinoColors.white);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 16,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                S.of(context).createAccount,
                style: pageTitleTextStyle,
              ),
              const SizedBox(
                width: 20,
              ),
              GestureDetector(
                onTap: widget.navigateToPage,
                child: Text(
                  S.of(context).orLogin,
                  style: secondaryPageTextStyle,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 16,
          ),
          Text(
            S.of(context).email,
            style: headerTextStyle,
          ),
          const SizedBox(
            height: 16,
          ),
          const PBTextInput(),
          const SizedBox(
            height: 16,
          ),
          Text(
            S.of(context).username,
            style: headerTextStyle,
          ),
          const SizedBox(
            height: 16,
          ),
          const PBTextInput(),
          const SizedBox(
            height: 16,
          ),
          Text(
            S.of(context).password,
            style: headerTextStyle,
          ),
          const SizedBox(
            height: 16,
          ),
          const PBTextInput(),
          const SizedBox(
            height: 16,
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width / 1.25,
            child: PBButton(S.of(context).createAccount),
          ),
        ],
      ),
    );
  }
}