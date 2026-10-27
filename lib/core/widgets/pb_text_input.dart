import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';

/// A soft filled text field without a border.
class PBTextInput extends StatefulWidget {
  const PBTextInput(this.textEditingController, {super.key});
  final TextEditingController textEditingController;

  @override
  State<PBTextInput> createState() => _PBTextInputState();
}

class _PBTextInputState extends State<PBTextInput> {
  @override
  Widget build(BuildContext context) => SizedBox(
        width: MediaQuery.sizeOf(context).width / 1.25,
        child: CupertinoTextField(
          controller: widget.textEditingController,
          padding: const EdgeInsets.symmetric(
            horizontal: PBSpace.lg,
            vertical: 18,
          ),
          style: context.textTheme.bodyLarge,
          placeholderStyle: context.textTheme.bodyLarge?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
          cursorColor: context.colorScheme.secondary,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PBRadius.md),
            color: context.colorScheme.surfaceContainer,
          ),
        ),
      );
}
