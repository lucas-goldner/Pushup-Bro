import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/phone_page.dart';
import 'package:pushup_bro/features/app_icon/app_icon_choice.dart';
import 'package:pushup_bro/features/app_icon/app_icon_service.dart';
import 'package:pushup_bro/features/pro/cubit/pro_cubit.dart';
import 'package:pushup_bro/features/pro/model/pro_state.dart';
import 'package:pushup_bro/features/pro/paywall/show_paywall.dart';

const _kPopDuration = Duration(milliseconds: 400);
const _kRingDuration = Duration(milliseconds: 200);
const _kCurrentIconSize = 80.0;
const _kGridIconSize = 72.0;

/// Picks the home screen icon: the one in use on top, then all nine in a
/// grid. Classic is free, the others need Pro (a locked one opens the
/// paywall). iOS only.
class AppIconPage extends StatefulWidget {
  const AppIconPage({this.service, super.key});

  /// Defaults to an [AppIconService] on the real channel.
  final AppIconService? service;

  /// Whether the app icon can be changed on this platform; hide the
  /// settings row otherwise.
  static bool get isAvailable => AppIconService.isPlatformSupported;

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
        CupertinoPageRoute<void>(
          builder: (_) => const PhonePage(child: AppIconPage()),
        ),
      );

  @override
  State<AppIconPage> createState() => _AppIconPageState();
}

class _AppIconPageState extends State<AppIconPage> {
  late final AppIconService _service = widget.service ?? AppIconService();
  AppIconChoice _current = AppIconChoice.classic;
  bool _supported = true;
  bool _busy = false;
  bool _switched = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final supported = await _service.isSupported();
    final current = await _service.current();
    if (!mounted) return;
    setState(() {
      _supported = supported;
      _current = current;
    });
  }

  Future<void> _pick(AppIconChoice choice) async {
    if (_busy || !_supported || choice == _current) return;
    final pro = context.read<ProCubit>();
    if (choice.needsPro && !pro.hasAccess) {
      final unlocked = await showPaywall(context);
      if (!mounted || !(unlocked || pro.hasAccess)) return;
    }
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await _service.set(choice);
      if (!mounted) return;
      setState(() {
        _current = choice;
        _switched = true;
      });
    } on PlatformException {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
        backgroundColor: context.colorScheme.surfaceContainerLow,
        child: SafeArea(
          bottom: false,
          child: BlocBuilder<ProCubit, ProState>(
            builder: (context, _) {
              final hasAccess = context.read<ProCubit>().hasAccess;

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  PBSpace.sm,
                  20,
                  PBSpace.xl,
                ),
                children: [
                  const _Header(),
                  const SizedBox(height: 18),
                  _CurrentIcon(
                    choice: _current,
                    note: _note(context),
                  ),
                  const SizedBox(height: 18),
                  _Caption(context.l10n.appIconChoose),
                  const SizedBox(height: PBSpace.sm),
                  _IconGrid(
                    current: _current,
                    hasAccess: hasAccess,
                    onPick: (choice) => unawaited(_pick(choice)),
                  ),
                  const SizedBox(height: PBSpace.md),
                  Text(
                    !_supported
                        ? context.l10n.appIconUnsupported
                        : _failed
                            ? context.l10n.appIconError
                            : context.l10n.appIconSubtitle,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: _failed ? context.colorScheme.error : null,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );

  String _note(BuildContext context) {
    if (_switched) return context.l10n.appIconSwitched;
    return _current.needsPro
        ? context.l10n.appIconProNote
        : context.l10n.appIconFreeNote;
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Semantics(
            button: true,
            label: context.l10n.appIconBack,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: context.colorScheme.surface,
                  shape: BoxShape.circle,
                  boxShadow: context.cardShadow,
                ),
                child: Icon(
                  CarbonIcons.chevron_left,
                  size: 20,
                  color: context.colorScheme.onSurface,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              context.l10n.appIconTitle,
              textAlign: TextAlign.center,
              style: context.textTheme.headlineSmall?.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      );
}

class _Caption extends StatelessWidget {
  const _Caption(this.text, {this.indent = 6});

  final String text;
  final double indent;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(left: indent),
        child: Text(
          text.toUpperCase(),
          style: context.textTheme.labelSmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      );
}

class _IconImage extends StatelessWidget {
  const _IconImage({required this.choice, required this.size, super.key});

  final AppIconChoice choice;
  final double size;

  @override
  Widget build(BuildContext context) => ClipRRect(
        // The iOS icon corner, about 23% of the side.
        borderRadius: BorderRadius.circular(size * 0.235),
        child: choice.preview.image(
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
}

/// The icon on the home screen now.
class _CurrentIcon extends StatelessWidget {
  const _CurrentIcon({required this.choice, required this.note});

  final AppIconChoice choice;
  final String note;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(PBSpace.lg),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(PBRadius.lg),
          boxShadow: context.cardShadow,
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: _kPopDuration,
              switchInCurve: Curves.easeOutBack,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: Tween<double>(begin: 0.88, end: 1).animate(animation),
                child: child,
              ),
              child: _IconImage(
                key: ValueKey(choice),
                choice: choice,
                size: _kCurrentIconSize,
              ),
            ),
            const SizedBox(width: PBSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Caption(context.l10n.appIconCurrentLabel, indent: 0),
                  const SizedBox(height: 2),
                  Text(
                    choice.label(context.l10n),
                    style: context.textTheme.headlineSmall?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(note, style: context.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      );
}

class _IconGrid extends StatelessWidget {
  const _IconGrid({
    required this.current,
    required this.hasAccess,
    required this.onPick,
  });

  final AppIconChoice current;
  final bool hasAccess;
  final ValueChanged<AppIconChoice> onPick;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: PBSpace.md,
          vertical: PBSpace.lg,
        ),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(PBRadius.lg),
          boxShadow: context.cardShadow,
        ),
        child: GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 14,
          crossAxisSpacing: 10,
          childAspectRatio: 0.92,
          children: [
            for (final choice in AppIconChoice.values)
              _IconTile(
                choice: choice,
                selected: choice == current,
                locked: choice.needsPro && !hasAccess && choice != current,
                onTap: () => onPick(choice),
              ),
          ],
        ),
      );
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.choice,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final AppIconChoice choice;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final label = choice.label(context.l10n);

    return Semantics(
      button: true,
      selected: selected,
      label: locked ? '$label, ${context.l10n.appIconLocked}' : label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          children: [
            SizedBox(
              width: _kGridIconSize + 24,
              height: _kGridIconSize + 4,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.bottomCenter,
                children: [
                  AnimatedContainer(
                    duration: _kRingDuration,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: scheme.secondary,
                                spreadRadius: 5.5,
                              ),
                              BoxShadow(
                                color: scheme.surface,
                                spreadRadius: 3,
                              ),
                            ]
                          : const [],
                    ),
                    child: Opacity(
                      opacity: locked ? 0.85 : 1,
                      child: _IconImage(choice: choice, size: _kGridIconSize),
                    ),
                  ),
                  if (selected || locked)
                    Positioned(
                      top: 0,
                      right: 2,
                      child: _Badge(selected: selected),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A check on the icon in use, a lock on the ones that need Pro.
class _Badge extends StatelessWidget {
  const _Badge({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? scheme.secondary : scheme.primary,
        boxShadow: selected ? null : context.cardShadow,
      ),
      child: Icon(
        selected ? CarbonIcons.checkmark : CarbonIcons.locked,
        size: selected ? 14 : 12,
        color: selected ? scheme.onSecondary : scheme.onPrimary,
      ),
    );
  }
}
