import 'package:flutter/cupertino.dart';
import 'package:pushup_bro/model/enum/menu_tab.dart';
import 'package:pushup_bro/ui/styles/pb_text_styles.dart';
import 'package:pushup_bro/ui/widgets/common/menu/closing_menu_button.dart';
import 'package:pushup_bro/ui/widgets/common/menu/menu_tabs.dart';
import 'package:pushup_bro/ui/widgets/common/menu/open_menu_button.dart';

class PBAppBar extends StatefulWidget {
  const PBAppBar(this.title, this.toggelOpacity, {super.key});
  final String? title;
  final VoidCallback toggelOpacity;

  @override
  State<PBAppBar> createState() => _PBAppBarState();
}

class _PBAppBarState extends State<PBAppBar> with TickerProviderStateMixin {
  static const List<MenuTabInfo> _menuTabInfo = [
    MenuTabInfo.home,
    MenuTabInfo.calendar,
    MenuTabInfo.settings,
  ];

  late final AnimationController _controller;
  late AnimationController _drawerController;
  static const _initialDelayTime = Duration(milliseconds: 50);
  static const _itemSlideTime = Duration(milliseconds: 250);
  static const _staggerTime = Duration(milliseconds: 50);
  static const _buttonDelayTime = Duration(milliseconds: 150);
  static const _buttonTime = Duration(milliseconds: 500);
  final Duration _animationDuration = _initialDelayTime +
      (_staggerTime * _menuTabInfo.length) +
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
      duration: const Duration(milliseconds: 250),
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
    for (var i = 0; i < 5; ++i) {
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
  Widget build(BuildContext context) {
    return Stack(
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
                _menuTabInfo,
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.title ?? '',
                style: PBTextStyles.pageTitleTextStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
