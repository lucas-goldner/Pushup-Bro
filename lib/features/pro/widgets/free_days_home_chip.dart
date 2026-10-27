import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/features/pro/cubit/pro_cubit.dart';
import 'package:pushup_bro/features/pro/model/pro_state.dart';
import 'package:pushup_bro/features/pro/notices/free_days_notices.dart';
import 'package:pushup_bro/features/pro/paywall/show_paywall.dart';
import 'package:pushup_bro/features/pro/widgets/free_days_chip.dart';

/// On the home screen during the free days: the countdown chip (tap for
/// the paywall), and once the store has loaded, the welcome or last-day
/// sheet when one is due.
class FreeDaysHomeChip extends StatefulWidget {
  const FreeDaysHomeChip({this.visible = true, super.key});

  /// Hidden while a set is running; the sheets wait for it too.
  final bool visible;

  @override
  State<FreeDaysHomeChip> createState() => _FreeDaysHomeChipState();
}

class _FreeDaysHomeChipState extends State<FreeDaysHomeChip> {
  Timer? _ticker;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    // The countdown moves on its own.
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void didUpdateWidget(covariant FreeDaysHomeChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) _check();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _check() {
    if (!mounted || _checked || !widget.visible) return;
    if (!context.read<ProCubit>().state.loaded) return;
    _checked = true;
    unawaited(showDueFreeDaysNotice(context));
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<ProCubit, ProState>(
        listenWhen: (previous, current) => !previous.loaded && current.loaded,
        listener: (context, _) => _check(),
        builder: (context, state) {
          final now = context.read<ProCubit>().now;
          final shown = widget.visible && state.showsFreeDays(now);

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: shown
                ? FreeDaysChip(
                    left: state.freeLeft(now),
                    onTap: () => showPaywall(context),
                  )
                : const SizedBox.shrink(),
          );
        },
      );
}
