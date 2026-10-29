import 'dart:async';
import 'dart:math' as math;

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/friends/bros_added_page.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/data/qr_scanner.dart';
import 'package:pushup_bro/features/social/domain/add_bro.dart';
import 'package:pushup_bro/features/social/domain/friend_code.dart';
import 'package:pushup_bro/features/social/model/bro_profile.dart';
import 'package:pushup_bro/features/social/widgets/bro_avatar.dart';
import 'package:pushup_bro/features/social/widgets/social_widgets.dart';

/// Opens "Add a bro", with [code] filled in when it came from a scan or a
/// link.
Future<void> openAddBro(BuildContext context, {String? code}) =>
    Navigator.of(context).pushNamed(AddBroPage.routeName, arguments: code);

/// Six boxes for a friend's code (they auto-advance and take a paste), the
/// friend's card as soon as the code matches, and Add.
class AddBroPage extends StatelessWidget {
  const AddBroPage({this.code, super.key});
  static const routeName = '/bros/add';

  final String? code;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: context.colorScheme.surfaceContainerLow,
        body: SocialGate(builder: (context, me) => _AddBro(me: me, code: code)),
      );
}

class _AddBro extends StatefulWidget {
  const _AddBro({required this.me, this.code});

  final BroProfile me;
  final String? code;

  @override
  State<_AddBro> createState() => _AddBroState();
}

class _AddBroState extends State<_AddBro> with SingleTickerProviderStateMixin {
  late final TextEditingController _text =
      TextEditingController(text: widget.code ?? '');
  final FocusNode _focus = FocusNode();
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  CodeLookup _lookup = const CodeIncomplete();
  bool _adding = false;
  bool _failed = false;
  int _query = 0;

  @override
  void initState() {
    super.initState();
    _text.addListener(_onChanged);
    if (FriendCode.isValid(FriendCode.normalize(_text.text))) {
      unawaited(_lookUp());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    _shake.dispose();
    super.dispose();
  }

  void _onChanged() {
    setState(() => _failed = false);
    unawaited(_lookUp());
  }

  Future<void> _lookUp() async {
    final query = ++_query;
    final account = context.read<AccountCubit>();
    if (!FriendCode.isValid(FriendCode.normalize(_text.text))) {
      setState(() => _lookup = const CodeIncomplete());
      return;
    }
    final friends = await account.backend.friends(widget.me.uid).first;
    final lookup = await lookUpCode(
      account.backend,
      me: widget.me,
      friends: friends,
      input: _text.text,
    );
    if (!mounted || query != _query) return;
    setState(() => _lookup = lookup);
    if (lookup is CodeFound) {
      GameAudio.instance.play(Sfx.pop);
    } else if (lookup is! CodeIncomplete) {
      unawaited(HapticFeedback.heavyImpact());
      _shake.forward(from: 0);
    }
  }

  Future<void> _add(CodeFound found) async {
    setState(() => _adding = true);
    final account = context.read<AccountCubit>();
    final navigator = Navigator.of(context);
    try {
      await addBro(account.backend, me: widget.me, friend: found.profile);
      GameAudio.instance.play(Sfx.star);
      await navigator.pushReplacementNamed(
        BrosAddedPage.routeName,
        arguments: (found.profile, found.name),
      );
    } on Object {
      if (mounted) {
        setState(() {
          _adding = false;
          _failed = true;
        });
      }
    }
  }

  Future<void> _scan() async {
    final l = context.l10n;
    final scanned =
        await QrScanner.scan(title: l.addScanQr, cancel: l.brosCancel);
    if (scanned != null) _text.text = FriendCode.normalize(scanned);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final lookup = _lookup;
    final error = switch (lookup) {
      CodeUnknown() => l.addUnknown,
      CodeIsMine() => l.addSelf,
      CodeAlreadyBros() => l.addAlready,
      CodeTooManyBros() => l.brosLimit,
      _ when _failed => l.addFailed,
      _ => null,
    };
    final found = lookup is CodeFound ? lookup : null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: PBSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton.filledTonal(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(CarbonIcons.chevron_left),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  const SizedBox(height: PBSpace.lg),
                  Text(
                    l.addTitle,
                    textAlign: TextAlign.center,
                    style: context.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: PBSpace.sm),
                  Text(
                    l.addText,
                    textAlign: TextAlign.center,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: PBSpace.xl),
                  AnimatedBuilder(
                    animation: _shake,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(
                        math.sin(_shake.value * math.pi * 6) *
                            10 *
                            (1 - _shake.value),
                        0,
                      ),
                      child: child,
                    ),
                    child: _CodeBoxes(
                      controller: _text,
                      focus: _focus,
                      error: error != null,
                    ),
                  ),
                  const SizedBox(height: PBSpace.md),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: found != null
                        ? _Preview(
                            found: found,
                            key: ValueKey(found.profile.uid),
                          )
                        : error != null
                            ? Text(
                                error,
                                key: ValueKey(error),
                                textAlign: TextAlign.center,
                                style: context.textTheme.titleSmall?.copyWith(
                                  color: context.gameColors.red,
                                ),
                              )
                            : const SizedBox(height: 24),
                  ),
                  const SizedBox(height: PBSpace.lg),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: PBSpace.md,
                        ),
                        child: Text(
                          l.addOr,
                          style: context.textTheme.labelMedium?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: PBSpace.lg),
                  SocialCard(
                    onTap: QrScanner.available ? _scan : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(CarbonIcons.qr_code, size: 20),
                        const SizedBox(width: PBSpace.sm),
                        Flexible(
                          child: Text(
                            QrScanner.available
                                ? l.addScanQr
                                : l.scanUnavailable,
                            textAlign: TextAlign.center,
                            style: context.textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: PBSpace.lg),
              child: AnimatedOpacity(
                opacity: found == null ? 0.4 : 1,
                duration: const Duration(milliseconds: 200),
                child: PillButton(
                  label: found == null
                      ? l.addButtonEmpty
                      : l.addButton(
                          friendLabel(context, found.profile, found.name),
                        ),
                  color: context.colorScheme.secondary,
                  onPressed: () {
                    if (found != null && !_adding) unawaited(_add(found));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Six boxes over one hidden text field, so typing, deleting and pasting
/// all just work.
class _CodeBoxes extends StatelessWidget {
  const _CodeBoxes({
    required this.controller,
    required this.focus,
    required this.error,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final bool error;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: focus.requestFocus,
        child: Stack(
          children: [
            Opacity(
              opacity: 0,
              child: TextField(
                controller: controller,
                focusNode: focus,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [_CodeFormatter()],
              ),
            ),
            ListenableBuilder(
              listenable: Listenable.merge([controller, focus]),
              builder: (context, _) {
                final code = controller.text;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < FriendCode.length; i++)
                      _Box(
                        letter: i < code.length ? code[i] : '',
                        active: focus.hasFocus && i == code.length,
                        error: error,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      );
}

class _Box extends StatelessWidget {
  const _Box({required this.letter, required this.active, required this.error});

  final String letter;
  final bool active;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: 46,
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(PBRadius.sm),
        border: Border.all(
          color: error
              ? context.gameColors.red
              : active
                  ? scheme.secondary
                  : Colors.transparent,
          width: 2,
        ),
        boxShadow: context.cardShadow,
      ),
      child: Text(
        letter,
        style: context.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Upper case, only the code's letters, at most six; a pasted link or a
/// code with its dash is boiled down to the code.
class _CodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final code = FriendCode.normalize(newValue.text);
    final text = code.length > FriendCode.length
        ? code.substring(0, FriendCode.length)
        : code;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.found, super.key});

  final CodeFound found;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final profile = found.profile;

    return SocialCard(
      child: Row(
        children: [
          BroAvatar(look: profile.look, size: 52),
          const SizedBox(width: PBSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friendLabel(context, profile, found.name),
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${l.addIslandLevel(profile.islandLevel)} · '
                  '🔥 ${l.addStreakDays(profile.streak)}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SocialChip(
            l.addFound,
            color: context.tint(context.gameColors.jungle),
          ),
        ],
      ),
    );
  }
}
