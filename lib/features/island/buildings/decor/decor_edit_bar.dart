import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/island/buildings/decor/decor_editor.dart';

/// The island's controls while decorations are moved: a hint and Done at
/// the top; turning and putting away the picked piece, and the pieces in
/// the bag, at the bottom. Lay it over the island in a [Stack].
class DecorEditBar extends StatelessWidget {
  const DecorEditBar({
    required this.editor,
    required this.onDone,
    super.key,
  });

  final DecorEditor editor;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: editor,
        builder: (context, _) => Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  PBSpace.md,
                  PBSpace.sm,
                  PBSpace.md,
                  0,
                ),
                child: Row(
                  children: [
                    Expanded(child: _Hint(context.l10n.decorEditHint)),
                    const SizedBox(width: PBSpace.sm),
                    PillButton(
                      label: context.l10n.decorDone,
                      icon: CarbonIcons.checkmark,
                      color: context.gameColors.jungle,
                      compact: true,
                      onPressed: onDone,
                    ),
                  ],
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      PBSpace.md,
                      0,
                      PBSpace.md,
                      PBSpace.lg,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (editor.selected != null) _tools(context),
                        if (editor.selected != null && editor.bag.isNotEmpty)
                          const SizedBox(height: PBSpace.sm),
                        if (editor.bag.isNotEmpty) _bag(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _tools(BuildContext context) {
    final piece = editor.pieces[editor.selected!];

    return _Panel(
      child: Row(
        children: [
          Text(piece.item.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: PBSpace.sm),
          Expanded(
            child: Text(
              piece.item.label(context.l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.titleSmall,
            ),
          ),
          _Tool(
            icon: CarbonIcons.rotate_counterclockwise,
            label: context.l10n.decorTurnLeft,
            onTap: () => editor.turn(1),
          ),
          _Tool(
            icon: CarbonIcons.rotate_clockwise,
            label: context.l10n.decorTurnRight,
            onTap: () => editor.turn(-1),
          ),
          _Tool(
            icon: CarbonIcons.archive,
            label: context.l10n.decorPutAway,
            color: context.gameColors.red,
            onTap: editor.putAway,
          ),
        ],
      ),
    );
  }

  Widget _bag(BuildContext context) => _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.decorBag,
              style: context.textTheme.labelMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: PBSpace.sm),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final index in editor.bag)
                    Padding(
                      padding: const EdgeInsets.only(right: PBSpace.sm),
                      child: _BagChip(
                        emoji: editor.pieces[index].item.emoji,
                        label: editor.pieces[index].item.label(context.l10n),
                        onTap: () {
                          final messenger = ScaffoldMessenger.maybeOf(context);
                          final full = context.l10n.decorIslandFull;
                          if (editor.place(index)) {
                            GameAudio.instance.play(Sfx.pop);
                          } else {
                            messenger?.showSnackBar(
                              SnackBar(content: Text(full)),
                            );
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(PBRadius.lg),
          boxShadow: context.cardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            PBSpace.lg,
            PBSpace.md,
            PBSpace.sm,
            PBSpace.md,
          ),
          child: child,
        ),
      );
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(
          horizontal: PBSpace.lg,
          vertical: PBSpace.sm,
        ),
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(PBRadius.pill),
          boxShadow: context.cardShadow,
        ),
        child: Row(
          children: [
            Icon(
              CarbonIcons.move,
              size: 18,
              color: context.colorScheme.secondary,
            ),
            const SizedBox(width: PBSpace.sm),
            Expanded(
              child: Text(
                text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelMedium,
              ),
            ),
          ],
        ),
      );
}

/// A round tool button, labelled for screen readers.
class _Tool extends StatelessWidget {
  const _Tool({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? context.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(left: PBSpace.xs),
      child: Tooltip(
        message: label,
        child: Material(
          color: context.tint(color),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () {
              GameAudio.instance.play(Sfx.tap);
              onTap();
            },
            child: SizedBox(
              width: 44,
              height: 44,
              child: Icon(icon, size: 20, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

class _BagChip extends StatelessWidget {
  const _BagChip({
    required this.emoji,
    required this.label,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: context.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(PBRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(PBRadius.pill),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(label, style: context.textTheme.labelMedium),
              ],
            ),
          ),
        ),
      );
}
