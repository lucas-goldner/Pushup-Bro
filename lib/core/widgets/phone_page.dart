import 'package:flutter/widgets.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/widgets/book_fold_half.dart';

/// The widest a page of text and lists gets.
const kPhonePageMaxWidth = 640.0;

/// A page of text and lists (settings, the bros, reminders): at most
/// [kPhonePageMaxWidth] wide and centred on a wide window (the iPhone Duo's
/// inner display, an iPad), and in the right half of a foldable open like
/// a book, off the fold. On a phone it is just [child].
class PhonePage extends StatelessWidget {
  const PhonePage({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => ColoredBox(
        // Beside the column, the pages' own background.
        color: context.colorScheme.surfaceContainerLow,
        child: BookFoldHalf(
          child: Center(
            child: ConstrainedBox(
              // Full height: the page fills it whatever its own size.
              constraints: const BoxConstraints(
                maxWidth: kPhonePageMaxWidth,
                minHeight: double.infinity,
              ),
              child: child,
            ),
          ),
        ),
      );
}
