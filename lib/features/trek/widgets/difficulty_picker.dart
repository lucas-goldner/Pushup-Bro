import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/trek_progress.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/features/trek/model/trek.dart';

/// The difficulty picked for [trek]'s battles; Brutal falls back to Normal
/// while it's still locked.
TrekDifficulty difficultyOf(TrekProgress trek) {
  final picked = TrekDifficulty.byName(trek.difficulty);

  return picked == TrekDifficulty.brutal && !brutalUnlocked(trek)
      ? TrekDifficulty.normal
      : picked;
}

/// Brutal opens once the whole Trek, King Komo included, is cleared.
bool brutalUnlocked(TrekProgress trek) => trek.cleared(TrekStage.all.last.id);

/// Four chips to pick how tough the Trek is, and a line saying who the
/// picked one is for (by pushups in a row) and what it pays.
class DifficultyPicker extends StatefulWidget {
  const DifficultyPicker({required this.trek, super.key});

  final TrekProgress trek;

  @override
  State<DifficultyPicker> createState() => _DifficultyPickerState();
}

class _DifficultyPickerState extends State<DifficultyPicker> {
  /// Set while showing why Brutal is still locked.
  bool _lockedHint = false;

  Future<void> _pick(TrekDifficulty difficulty) async {
    if (difficulty == TrekDifficulty.brutal && !brutalUnlocked(widget.trek)) {
      GameAudio.instance.play(Sfx.blip);
      setState(() => _lockedHint = true);
      return;
    }
    GameAudio.instance.play(Sfx.tap);
    setState(() => _lockedHint = false);
    final cubit = context.read<GameInventoryCubit>();
    final inventory = cubit.state.inventory;
    await cubit.updateInventory(
      inventory.copyWith(
        trek: inventory.trek.copyWith(difficulty: difficulty.name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final scheme = context.colorScheme;
    final text = context.textTheme;
    final current = difficultyOf(widget.trek);
    final unlocked = brutalUnlocked(widget.trek);
    final rewards = NumberFormat(
      '0.##',
      Localizations.localeOf(context).toLanguageTag(),
    ).format(current.rewards);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.trekDifficulty,
          style: text.labelMedium?.copyWith(
            fontSize: 12,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final (i, difficulty) in TrekDifficulty.values.indexed) ...[
              if (i > 0) const SizedBox(width: 6),
              Expanded(
                child: _Chip(
                  difficulty: difficulty,
                  selected: difficulty == current,
                  locked: difficulty == TrekDifficulty.brutal && !unlocked,
                  onTap: () => unawaited(_pick(difficulty)),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(
            _lockedHint
                ? l.trekBrutalLocked
                : current == TrekDifficulty.normal
                    ? current.forWho(l)
                    : '${current.forWho(l)} ${l.trekRewards(rewards)}',
            key: ValueKey('${current.name}$_lockedHint'),
            style: text.bodySmall?.copyWith(
              fontSize: 12.5,
              height: 1.3,
              color: _lockedHint ? _colorOf(TrekDifficulty.brutal) : null,
            ),
          ),
        ),
      ],
    );
  }
}

Color _colorOf(TrekDifficulty difficulty) => switch (difficulty) {
      TrekDifficulty.easy => const Color(0xFF3FAE5A),
      TrekDifficulty.normal => const Color(0xFF3F86D9),
      TrekDifficulty.hard => const Color(0xFFE2752F),
      TrekDifficulty.brutal => const Color(0xFFD63A4A),
    };

class _Chip extends StatelessWidget {
  const _Chip({
    required this.difficulty,
    required this.selected,
    required this.locked,
    required this.onTap,
  });

  final TrekDifficulty difficulty;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final color = _colorOf(difficulty);

    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 52,
          decoration: BoxDecoration(
            color: selected
                ? color
                : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(PBRadius.sm + 4),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.35),
              width: 1.5,
            ),
          ),
          child: Opacity(
            opacity: locked ? 0.5 : 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (locked)
                  Icon(
                    CarbonIcons.locked,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  )
                else
                  Text(difficulty.emoji, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      difficulty.label(context.l10n),
                      maxLines: 1,
                      style: context.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: selected ? Colors.white : scheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
