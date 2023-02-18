import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/ui/styles/pb_colors.dart';
import 'package:pushup_bro/ui/widgets/common/pb_app_bar.dart';

class PageContainer extends StatefulWidget {
  const PageContainer(this.pageContent, {this.title, super.key});
  final Widget pageContent;
  final String? title;

  @override
  State<PageContainer> createState() => _PageContainerState();
}

class _PageContainerState extends State<PageContainer> {
  double opacityLevel = 0;

  void _changeOpacity() {
    setState(() => opacityLevel = opacityLevel == 0 ? 0.75 : 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: PBColors.background,
      child: Stack(
        children: [
          Stack(
            children: [
              Center(
                child: widget.pageContent,
              ),
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: opacityLevel,
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    color: CupertinoColors.black,
                  ),
                ),
              ),
              SafeArea(
                child: PBAppBar(widget.title, _changeOpacity),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
