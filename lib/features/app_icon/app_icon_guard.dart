import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/features/app_icon/app_icon_choice.dart';
import 'package:pushup_bro/features/app_icon/app_icon_service.dart';
import 'package:pushup_bro/features/pro/cubit/pro_cubit.dart';
import 'package:pushup_bro/features/pro/model/pro_state.dart';

/// Puts the Classic icon back once Pro (or the free days) ends: checked
/// when the store has loaded, whenever Pro changes, and when the app comes
/// back to the foreground.
class AppIconProGuard extends StatefulWidget {
  const AppIconProGuard({required this.child, this.service, super.key});

  final Widget child;

  /// Defaults to an [AppIconService] on the real channel.
  final AppIconService? service;

  @override
  State<AppIconProGuard> createState() => _AppIconProGuardState();
}

class _AppIconProGuardState extends State<AppIconProGuard>
    with WidgetsBindingObserver {
  late final AppIconService _service = widget.service ?? AppIconService();
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    if (!_service.enabled) return;
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_check()));
  }

  @override
  void dispose() {
    if (_service.enabled) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_check());
  }

  Future<void> _check() async {
    if (!mounted || !_service.enabled || _checking) return;
    final pro = context.read<ProCubit>();
    // Before the store answers, everything looks open (or locked).
    if (!pro.state.loaded || pro.hasAccess) return;
    _checking = true;
    try {
      if (await _service.current() != AppIconChoice.classic) {
        await _service.set(AppIconChoice.classic);
      }
    } on PlatformException catch (error) {
      debugPrint('Could not reset the app icon: ${error.message}');
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) => BlocListener<ProCubit, ProState>(
        listener: (_, __) => unawaited(_check()),
        child: widget.child,
      );
}
