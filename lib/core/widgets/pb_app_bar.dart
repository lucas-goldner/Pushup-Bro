import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/menu/model/menu_tab_info.dart';
import 'package:pushup_bro/features/menu/widgets/closing_menu_button.dart';
import 'package:pushup_bro/features/menu/widgets/menu_tabs.dart';
import 'package:pushup_bro/features/menu/widgets/open_menu_button.dart';

const _initialDelayTime = Duration(milliseconds: 50);
const _itemSlideTime = Duration(milliseconds: 250);
const _staggerTime = Duration(milliseconds: 50);
const _buttonDelayTime = Duration(milliseconds: 150);
const _buttonTime = Duration(milliseconds: 500);

class PBAppBar extends StatefulWidget {
  const PBAppBar(
    this.title,
    this.toggelOpacity, {
    this.overScene = false,
    super.key,
  });
  final String? title;
  final VoidCallback toggelOpacity;

  /// Over a bright 3D scene the title sits on a floating card, so it reads
  /// in dark mode too.
  final bool overScene;

  @override
  State<PBAppBar> createState() => _PBAppBarState();
}

class _PBAppBarState extends State<PBAppBar> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late AnimationController _drawerController;
  final Duration _animationDuration = _initialDelayTime +
      (_staggerTime * MenuTabInfo.values.length) +
      _buttonDelayTime +
      _buttonTime;
  final List<Interval> _itemSlideIntervals = [];
  bool _open = false;

  @override
  void initState() {
    super.initState();
    _open = false;
    _controller = AnimationController(
      value: _open ? 1.0 : 0.0,
      duration: _itemSlideTime,
      vsync: this,
    );
    _drawerController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );
    _createAnimationIntervals();
  }

  @override
  void dispose() {
    _controller.dispose();
    _drawerController.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _open = !_open;
      if (_open) {
        _controller.forward();
        _drawerController.forward();
      } else {
        _controller.reverse();
        _drawerController.reverse();
      }
    });
    widget.toggelOpacity();
  }

  void _createAnimationIntervals() {
    for (var i = 0; i < MenuTabInfo.values.length; ++i) {
      final startTime = _initialDelayTime + (_staggerTime * i);
      final endTime = startTime + _itemSlideTime;
      _itemSlideIntervals.add(
        Interval(
          startTime.inMilliseconds / _animationDuration.inMilliseconds,
          endTime.inMilliseconds / _animationDuration.inMilliseconds,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClosingMenuButton(
                  _toggle,
                  open: _open,
                ),
                MenuTabs(
                  _drawerController,
                  _itemSlideIntervals,
                  open: _open,
                ),
                OpenMenuButton(
                  _toggle,
                  open: _open,
                ),
              ],
            ),
          ),
          Visibility(
            visible: widget.title != null,
            child: SizedBox(
              height: 56,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.overScene)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: context.colorScheme.surface,
                        borderRadius: BorderRadius.circular(PBRadius.pill),
                        boxShadow: context.cardShadow,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        child: Text(
                          widget.title ?? '',
                          style: context.textTheme.headlineSmall,
                        ),
                      ),
                    )
                  else
                    Text(
                      widget.title ?? '',
                      style: context.textTheme.headlineLarge,
                    ),
                ],
              ),
            ),
          ),
        ],
      );
}
