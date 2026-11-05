import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/island_sheet.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/island/buildings/adoption/adoption.dart';
import 'package:pushup_bro/features/island/model/adoptable_monkey.dart';
import 'package:pushup_bro/features/social/widgets/bro_avatar.dart';
import 'package:pushup_bro/generated/assets.gen.dart';
import 'package:pushup_bro/generated/l10n.dart';
import 'package:rive/rive.dart';

/// The little line that says who [monkey] is.
String? monkeyLine(S l, AdoptableMonkey monkey) {
  if (monkey.look.species == MonkeyLook.lizard) return l.adoptionKomoLine;

  return switch (monkey.personality) {
    0 => l.adoptionPersona0,
    1 => l.adoptionPersona1,
    2 => l.adoptionPersona2,
    3 => l.adoptionPersona3,
    4 => l.adoptionPersona4,
    5 => l.adoptionPersona5,
    6 => l.adoptionPersona6,
    7 => l.adoptionPersona7,
    _ =>
      !monkey.adopted && monkey.name == 'Carlos' ? l.adoptionCarlosLine : null,
  };
}

/// Asks for a new name for [current]; null when cancelled or left empty.
Future<String?> askMonkeyName(BuildContext context, String current) =>
    showDialog<String>(
      context: context,
      builder: (context) => _NameDialog(current: current),
    );

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.current});

  final String current;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.current);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() =>
      Navigator.of(context).pop(Adoption.cleanName(_controller.text));

  @override
  Widget build(BuildContext context) => AlertDialog(
        backgroundColor: context.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PBRadius.lg),
        ),
        title: Text(context.l10n.adoptionRename),
        content: TextField(
          controller: _controller,
          autofocus: true,
          maxLength: Adoption.maxNameLength,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(hintText: context.l10n.adoptionNameHint),
          onSubmitted: (_) => _save(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.cancel),
          ),
          TextButton(onPressed: _save, child: Text(context.l10n.adoptionSave)),
        ],
      );
}

/// A candidate to pick at the top of the centre: their face and name.
class CandidateChip extends StatelessWidget {
  const CandidateChip({
    required this.monkey,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final AdoptableMonkey monkey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => SheetCard(
        selected: selected,
        accent: context.gameColors.banana,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        onTap: onTap,
        child: Column(
          children: [
            BroAvatar(look: monkey.look, size: 48),
            const SizedBox(height: 6),
            Text(
              monkey.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
}

/// A small rounded button with an icon and a label, for cards.
class CardAction extends StatelessWidget {
  const CardAction({
    required this.icon,
    required this.label,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: context.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(PBRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(PBRadius.pill),
          onTap: () {
            GameAudio.instance.play(Sfx.tap);
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: context.colorScheme.onSurface),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.labelMedium?.copyWith(
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

/// One of the player's monkeys in a spot: face, name and line, whether it
/// trains in the home gym, and buttons to dress it up or rename it.
class MonkeyCard extends StatelessWidget {
  const MonkeyCard({
    required this.monkey,
    required this.trainer,
    required this.onGym,
    required this.onDressUp,
    required this.onRename,
    super.key,
  });

  final AdoptableMonkey monkey;

  /// Who they train with: the monkey the player plays as.
  final String trainer;
  final ValueChanged<bool> onGym;
  final VoidCallback onDressUp;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    final line = monkeyLine(context.l10n, monkey);

    return SheetCard(
      color: context.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              BroAvatar(look: monkey.look, size: 52),
              const SizedBox(width: PBSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(PBRadius.sm),
                      onTap: onRename,
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              monkey.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            CarbonIcons.edit,
                            size: 16,
                            semanticLabel: context.l10n.adoptionRename,
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                    if (line != null)
                      Text(
                        line,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: PBSpace.sm),
          // The button moves under the switch when they don't fit side by
          // side, as in German or Japanese on a small phone.
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: PBSpace.sm,
            runSpacing: PBSpace.xs,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Switch.adaptive(
                    value: monkey.trainsInGym,
                    activeTrackColor: context.gameColors.jungle,
                    onChanged: onGym,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      context.l10n.adoptionTrainWith(trainer),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: context.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              CardAction(
                icon: CarbonIcons.color_palette,
                label: context.l10n.adoptionDressUp,
                onTap: onDressUp,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A spot on the island still free, with what it costs to fill.
class FreeSpotCard extends StatelessWidget {
  const FreeSpotCard({required this.price, required this.next, super.key});

  final int price;

  /// The next one to fill; the others wait their turn.
  final bool next;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: next ? 1 : 0.6,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: context.colorScheme.outlineVariant,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.colorScheme.surfaceContainer,
                ),
                child: Icon(
                  next ? CarbonIcons.add : CarbonIcons.locked,
                  size: 18,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: PBSpace.md),
              Expanded(
                child: Text(
                  context.l10n.adoptionFreeSpot,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.labelLarge?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              BananaPrice(price),
            ],
          ),
        ),
      );
}

/// The celebration after an adoption: confetti, the new monkey's face and
/// a warm welcome.
Future<void> showWelcome(
  BuildContext context, {
  required AdoptableMonkey monkey,
  required String trainer,
  bool confetti = true,
}) =>
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: context.l10n.adoptionYay,
      barrierColor: context.colorScheme.scrim.withValues(alpha: 0.45),
      transitionDuration: const Duration(milliseconds: 420),
      transitionBuilder: (context, animation, _, child) => ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: animation, child: child),
      ),
      pageBuilder: (context, _, __) =>
          _Welcome(monkey: monkey, trainer: trainer, confetti: confetti),
    );

class _Welcome extends StatelessWidget {
  const _Welcome({
    required this.monkey,
    required this.trainer,
    required this.confetti,
  });

  final AdoptableMonkey monkey;
  final String trainer;
  final bool confetti;

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(PBSpace.xl),
              child: Material(
                color: context.colorScheme.surface,
                borderRadius: BorderRadius.circular(PBRadius.lg),
                child: Padding(
                  padding: const EdgeInsets.all(PBSpace.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          BroAvatar(look: monkey.look, size: 96),
                          const Positioned(
                            right: -18,
                            top: -10,
                            child: Text('🎉', style: TextStyle(fontSize: 32)),
                          ),
                        ],
                      ),
                      const SizedBox(height: PBSpace.lg),
                      Text(
                        context.l10n.adoptionWelcome(monkey.name),
                        textAlign: TextAlign.center,
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: PBSpace.sm),
                      Text(
                        context.l10n.adoptionWelcomeBody(monkey.name, trainer),
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: PBSpace.xl),
                      PillButton(
                        label: context.l10n.adoptionYay,
                        compact: true,
                        color: context.gameColors.jungle,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (confetti)
            IgnorePointer(
              child: RiveWidgetBuilder(
                fileLoader: Assets.rive.confetti.riveFileLoader(),
                builder: (context, state) => switch (state) {
                  RiveLoading() => const SizedBox.shrink(),
                  RiveFailed() => const SizedBox.shrink(),
                  RiveLoaded(:final controller) =>
                    RiveWidget(controller: controller),
                },
              ),
            ),
        ],
      );
}
