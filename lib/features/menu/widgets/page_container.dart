import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/widgets/pb_app_bar.dart';
import 'package:pushup_bro/features/menu/model/menu_tab_info.dart';

class PageContainer extends StatefulWidget {
  const PageContainer(
    this.pageContent, {
    this.menuTab,
    bool? showTitle,
    super.key,
  }) : _showTitle = showTitle ?? true;

  final Widget pageContent;
  final MenuTabInfo? menuTab;
  final bool _showTitle;

  @override
  State<PageContainer> createState() => _PageContainerState();
}

class _PageContainerState extends State<PageContainer> {
  double opacityLevel = 0;

  void _changeOpacity() =>
      setState(() => opacityLevel = opacityLevel == 0 ? 0.75 : 0.0);

  bool get menuIsVisible => opacityLevel == 0;
  bool get titleVisible => widget._showTitle && opacityLevel == 0;

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
        backgroundColor: context.colorScheme.surface,
        child: Stack(
          children: [
            Stack(
              children: [
                IgnorePointer(
                  ignoring: !menuIsVisible,
                  child: Stack(
                    children: [
                      widget.pageContent,
                      Visibility(
                        visible: !menuIsVisible,
                        child: ClipRect(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                              sigmaX: 10,
                              sigmaY: 10,
                            ),
                            child: SizedBox(
                              width: MediaQuery.sizeOf(context).width,
                              height: MediaQuery.sizeOf(context).height,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: opacityLevel,
                    duration: const Duration(milliseconds: 500),
                    child: Container(
                      width: MediaQuery.sizeOf(context).width,
                      height: MediaQuery.sizeOf(context).height,
                      color: context.colorScheme.surfaceDim,
                    ),
                  ),
                ),
                SafeArea(
                  child: PBAppBar(
                    titleVisible ? widget.menuTab?.getMenuTitle(context) : '',
                    _changeOpacity,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}
