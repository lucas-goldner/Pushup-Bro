import 'dart:ui';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/cubit/db_state.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/extensions/int_ext.dart';
import 'package:pushup_bro/core/model/level_scalings.dart';
import 'package:pushup_bro/core/model/pushup_set.dart';
import 'package:pushup_bro/core/model/user.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/island_sheet.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/pushup_tracking/widgets/finished_pushup_sheet/finished_set_stats_item.dart';
import 'package:pushup_bro/features/share/model/recap.dart';
import 'package:pushup_bro/features/share/widgets/share_recap_button.dart';
import 'package:pushup_bro/generated/assets.gen.dart';

class FinishedSetBottomSheet extends StatefulWidget {
  const FinishedSetBottomSheet(this.pushupSet, {super.key});
  final PushupSet pushupSet;

  @override
  State<FinishedSetBottomSheet> createState() => _FinishedSetBottomSheetState();
}

class _FinishedSetBottomSheetState extends State<FinishedSetBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double difficultySliderValue = 0;
  bool levelUpVisible = false;
  int level = 1;
  int amountOfXP = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    amountOfXP = widget.pushupSet.pushups.length * 2;
    final user = BlocProvider.of<DBCubit>(context).state.user;
    level = user.level;
    final initialScaling = LevelScaler().getCurrentExperienceRelativeToLevel(
      user.level,
      level,
      user.xp,
    );
    _animation =
        Tween<double>(begin: initialScaling, end: 1).animate(_controller);
    Future.delayed(
      const Duration(seconds: 1),
      () => calculateLevelUps(initialScaling, user),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void calculateLevelUps(double initialScaling, User user) {
    final levelScaling = LevelScaler().getCurrentExperienceRelativeToLevel(
      user.level,
      level,
      user.xp + amountOfXP,
    );

    final levelUps =
        splitDouble(levelScaling).where((element) => element == 1).toList();
    final xpLeftOver =
        splitDouble(levelScaling).where((element) => element != 1).first;

    if (levelUps.isEmpty) {
      _animation = Tween<double>(begin: initialScaling, end: 1)
          .animate(_controller)
        ..addListener(() async => setState(() {}));
      _controller.animateTo(levelScaling, duration: const Duration(seconds: 1));
    } else {
      _animation = Tween<double>(begin: initialScaling, end: 1)
          .animate(_controller)
        ..addListener(() async {
          setState(() {});

          if (_animation.value == 1) {
            level += 1;
            levelUps.remove(levelUps.first);
            showLevelUp();
            _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
            _controller.reset();

            if (levelUps.isEmpty) {
              await _controller.animateTo(
                xpLeftOver,
                duration: const Duration(milliseconds: 500),
              );
            } else if (levelUps.length == 1) {
              await _controller.animateTo(
                1,
                duration: const Duration(seconds: 1),
              );
            } else {
              if (levelUps.isNotEmpty) {
                await _controller.animateTo(
                  1,
                  duration: const Duration(seconds: 1),
                );
              }
            }
          }
        });

      _controller.animateTo(1, duration: const Duration(seconds: 1));
    }
  }

  List<double> splitDouble(double number) {
    final integerPart = number.floor();
    final fractionalPart = number - integerPart;

    final onesList = List<double>.filled(integerPart, 1, growable: true);

    if (fractionalPart > 0) {
      onesList.add(fractionalPart);
    }

    return onesList;
  }

  void showLevelUp() => setState(() => levelUpVisible = true);

  Future<void> savePushupSet() async {
    await BlocProvider.of<DBCubit>(context).writeNewPushupsetToDB(
      widget.pushupSet.copyWith(effort: difficultySliderValue.toInt()),
    );
  }

  Future<void> closeModalAndSave() async {
    final navigator = Navigator.of(context);
    final sharedPrefsCubit = BlocProvider.of<SharedPreferencesCubit>(context);
    final dbCubit = BlocProvider.of<DBCubit>(context);
    final gameInventoryCubit = BlocProvider.of<GameInventoryCubit>(context);
    final finished = await sharedPrefsCubit.getFirstPushupCompleted();
    final leftOverXP = (LevelScaler().getLevelScaling(level) * _animation.value)
        .toInt()
        .toNextEvenNumber();

    if (!finished) {
      await dbCubit.createUser(level: level, xp: leftOverXP);
      await sharedPrefsCubit.finishFirstPushupCompleted();
    } else {
      await dbCubit.updateUser(level: level, xp: leftOverXP);
    }

    await gameInventoryCubit.fetchInventory();
    final currentInventory = gameInventoryCubit.state.inventory;
    GameAudio.instance.play(Sfx.banana);
    await gameInventoryCubit.updateInventory(
      currentInventory.copyWith(
        bananas: currentInventory.bananas + widget.pushupSet.pushups.length,
      ),
    );
    await savePushupSet();
    navigator.pop(finished);
  }

  void closeModal() => showCupertinoDialog<Widget>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(context.l10n.closeWithoutSaving),
          content: Text(context.l10n.closeExplanation),
          actions: <Widget>[
            CupertinoDialogAction(
              child: Text(
                context.l10n.cancel,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            CupertinoDialogAction(
              child: Text(
                context.l10n.dontSave,
                style: TextStyle(
                  color: context.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => {
                Navigator.of(context)
                  ..pop()
                  ..pop(),
              },
            ),
          ],
        ),
      );

  static const _efforts = ['😌', '🙂', '😅', '😤', '🥵', '💀'];

  @override
  Widget build(BuildContext context) {
    final localized = context.l10n;
    final pushups = widget.pushupSet.pushups.length;

    return BlocSelector<DBCubit, DBState, User>(
      selector: (state) => state.user,
      builder: (context, user) => Material(
        // Pin the surface rather than relying on the ambient canvas colour,
        // which turns near-black whenever `Theme.of` resolves a theme
        // derived from the dark `CupertinoApp` instead of the app theme.
        color: context.colorScheme.surface,
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(
                      children: [
                        SheetBadge('🏆', color: context.gameColors.orange),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            localized.congrats,
                            style: context.textTheme.headlineMedium,
                          ),
                        ),
                        SheetCloseButton(onPressed: closeModal),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _hero(pushups),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: FinishedSetStatsItem(
                            icon: CarbonIcons.time,
                            text: context.l10n.completedInXMinutes(
                              widget.pushupSet.timeSpent.toString(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FinishedSetStatsItem(
                            icon: CarbonIcons.chart_average,
                            text: context.l10n.onAverage(
                              '$pushups/${widget.pushupSet.timeSpent}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      localized.difficulty,
                      style: context.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (final (i, emoji) in _efforts.indexed)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: _EffortChip(
                                emoji: emoji,
                                selected: difficultySliderValue.round() == i,
                                onTap: () => setState(
                                  () => difficultySliderValue = i.toDouble(),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (final label in [
                          context.l10n.easyDifficulty,
                          context.l10n.middleDifficulty,
                          context.l10n.hardDifficulty,
                        ])
                          Text(
                            label,
                            style: context.textTheme.bodySmall,
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    _bananas(pushups),
                    const SizedBox(height: 22),
                    Center(
                      child: PillButton(
                        label: localized.saveSet,
                        icon: CarbonIcons.checkmark,
                        onPressed: closeModalAndSave,
                      ),
                    ),
                    Center(
                      child: ShareRecapButton(
                        recap: () => Recap.workout(
                          set: widget.pushupSet,
                          history: context.read<DBCubit>().state.pushupSets,
                          now: DateTime.now(),
                          weightKg: playerWeightKg(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (levelUpVisible) _levelUp(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(int pushups) => Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [context.colorScheme.secondary, context.gameColors.purple],
          ),
          borderRadius: BorderRadius.circular(PBRadius.lg),
          boxShadow: context.glow(context.colorScheme.secondary),
        ),
        child: Column(
          children: [
            Text(
              '$pushups',
              style: context.textTheme.displayLarge?.copyWith(
                fontSize: 64,
                color: context.gameColors.onGame,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.madeXPushups(pushups.toString()),
              style: context.textTheme.labelLarge?.copyWith(
                color: context.gameColors.onGame.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      );

  Widget _bananas(int pushups) => SheetCard(
        color: context.gameColors.cream,
        child: Row(
          children: [
            Assets.images.island.banana.image(height: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.l10n.bananasEarned(pushups),
                style: context.textTheme.titleMedium,
              ),
            ),
            Text(
              '+$pushups',
              style: context.textTheme.displaySmall?.copyWith(
                fontSize: 26,
                color: context.gameColors.orange,
              ),
            ),
          ],
        ),
      );

  Widget _levelUp() => Positioned.fill(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(32),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                borderRadius: BorderRadius.circular(PBRadius.sheet),
                boxShadow: context.cardShadow,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SheetBadge('🎉', size: 72, color: context.gameColors.orange),
                  const SizedBox(height: 16),
                  Text(
                    context.l10n.levelReached(level),
                    textAlign: TextAlign.center,
                    style: context.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 20),
                  PillButton(
                    label: context.l10n.monkeyConfirm,
                    onPressed: () => setState(() => levelUpVisible = false),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

class _EffortChip extends StatelessWidget {
  const _EffortChip({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        decoration: BoxDecoration(
          color: selected
              ? context.colorScheme.primary
              : context.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(PBRadius.md),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(PBRadius.md),
            onTap: onTap,
            child: Center(
              child: AnimatedScale(
                scale: selected ? 1.2 : 1,
                duration: const Duration(milliseconds: 180),
                child: Text(emoji, style: const TextStyle(fontSize: 24)),
              ),
            ),
          ),
        ),
      );
}
