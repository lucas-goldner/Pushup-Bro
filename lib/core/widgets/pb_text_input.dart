import 'package:flutter/cupertino.dart';

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
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(10)),
            color: CupertinoColors.white,
          ),
        ),
      );
}
