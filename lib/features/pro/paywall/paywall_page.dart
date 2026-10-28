import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/audio/game_audio.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/model/website_links.dart';
import 'package:pushup_bro/core/provider/url_launch_provider.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/pro/cubit/pro_cubit.dart';
import 'package:pushup_bro/features/pro/model/pro_feature.dart';
import 'package:pushup_bro/features/pro/model/pro_plan.dart';
import 'package:pushup_bro/features/pro/model/pro_state.dart';
import 'package:pushup_bro/features/pro/paywall/widgets/paywall_features.dart';
import 'package:pushup_bro/features/pro/paywall/widgets/paywall_plans.dart';
import 'package:pushup_bro/features/pro/paywall/widgets/paywall_stage.dart';
import 'package:pushup_bro/features/pro/widgets/free_days_chip.dart';

const _kIntroDuration = Duration(milliseconds: 1300);
const _kBreatheDuration = Duration(milliseconds: 2400);
const _kLoopDuration = Duration(milliseconds: 1400);

/// The Pushup Bro Pro paywall: a little stage that plays what Pro opens,
/// the three plans and the button to buy one. Pops with true once the
/// player bought or restored Pro.
class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage>
    with TickerProviderStateMixin {
  late final AnimationController _scene = AnimationController(
    vsync: this,
    duration: kPaywallSceneDuration,
  )..addStatusListener(_onSceneDone);
  late final AnimationController _intro =
      AnimationController(vsync: this, duration: _kIntroDuration);
  late final AnimationController _loop =
      AnimationController(vsync: this, duration: _kLoopDuration);
  late final AnimationController _breathe =
      AnimationController(vsync: this, duration: _kBreatheDuration);
  final _launcher = UrlLauncherProvider(const UrlLauncherService());

  ProFeature _feature = ProFeature.values.first;
  ProPlanKind? _selected;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scene.forward();
    _intro.forward();
    _loop.repeat();
    _breathe.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scene.dispose();
    _intro.dispose();
    _loop.dispose();
    _breathe.dispose();
    super.dispose();
  }

  void _onSceneDone(AnimationStatus status) {
    if (status == AnimationStatus.completed) _show(_next);
  }

  ProFeature get _next =>
      ProFeature.values[(_feature.index + 1) % ProFeature.values.length];

  void _show(ProFeature feature) {
    if (!mounted) return;
    setState(() => _feature = feature);
    _scene.forward(from: 0);
  }

  void _replay() {
    GameAudio.instance.play(Sfx.whoosh);
    _show(ProFeature.values.first);
    _intro.forward(from: 0);
  }

  ProPlan _plan(List<ProPlan> plans) {
    final kind = _selected ??
        (plans.any((plan) => plan.kind == ProPlanKind.yearly)
            ? ProPlanKind.yearly
            : plans.first.kind);

    return plans.firstWhere(
      (plan) => plan.kind == kind,
      orElse: () => plans.first,
    );
  }

  Future<void> _buy(ProPlan plan) async {
    final cubit = context.read<ProCubit>();
    final l = context.l10n;
    final navigator = Navigator.of(context);
    if (!cubit.state.storeAvailable || plan.handle == null) {
      setState(() => _error = l.proStoreUnavailable);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    String? error;
    try {
      final pro = await cubit.purchase(plan);
      if (pro ?? false) {
        GameAudio.instance.play(Sfx.purchase);
        navigator.pop(true);
        return;
      }
      // Null means the player cancelled: nothing to say.
      if (pro != null) error = l.proPurchaseFailed;
    } on Object catch (e) {
      debugPrint('Purchase failed: $e');
      error = l.proPurchaseFailed;
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  Future<void> _restore() async {
    final cubit = context.read<ProCubit>();
    final l = context.l10n;
    final navigator = Navigator.of(context);
    if (!cubit.state.storeAvailable) {
      setState(() => _error = l.proStoreUnavailable);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    String? error;
    try {
      if (await cubit.restore()) {
        GameAudio.instance.play(Sfx.unlock);
        navigator.pop(true);
        return;
      }
      error = l.proRestoreNothing;
    } on Object catch (e) {
      debugPrint('Restore failed: $e');
      error = l.proPurchaseFailed;
    }
    if (mounted) {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  Future<void> _open(WebsiteLinks link) async {
    try {
      await _launcher.launchUri(Uri(scheme: 'https', path: link.link));
    } on Object catch (e) {
      debugPrint('Could not open ${link.link}: $e');
    }
  }

  /// Fades and slides a section in, [delay] seconds after the page opens.
  Widget _in(double delay, Widget child) => AnimatedBuilder(
        animation: _intro,
        child: child,
        builder: (context, child) {
          final start = delay / 1.3;
          final x = Curves.easeOutCubic.transform(
            ((_intro.value - start) / (0.6 / 1.3)).clamp(0.0, 1.0),
          );

          return Opacity(
            opacity: x,
            child: Transform.translate(
              offset: Offset(0, 14 * (1 - x)),
              child: child,
            ),
          );
        },
      );

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final cubit = context.watch<ProCubit>();
    final state = cubit.state;
    final now = cubit.now;
    final trial = state.inFreeDays(now) && !state.simulateLocked;
    final plans = displayedPlans(state);
    final plan = _plan(plans);

    return Material(
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            PBSpace.sm,
            20,
            MediaQuery.paddingOf(context).bottom + 28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _in(0, _topBar(context, state, now)),
              const SizedBox(height: PBSpace.lg),
              _in(
                0.1,
                PaywallStage(
                  scene: _feature,
                  progress: _scene,
                  loop: _loop,
                  onTap: () {
                    GameAudio.instance.play(Sfx.tap);
                    _show(_next);
                  },
                ),
              ),
              const SizedBox(height: PBSpace.lg),
              _in(0.25, _headline(context, trial: trial)),
              const SizedBox(height: PBSpace.lg),
              _in(
                0.4,
                PaywallFeatures(
                  current: _feature,
                  onSelected: (feature) {
                    GameAudio.instance.play(Sfx.tap);
                    _show(feature);
                  },
                ),
              ),
              const SizedBox(height: PBSpace.lg),
              _in(
                0.55,
                PaywallPlans(
                  plans: plans,
                  selected: plan.kind,
                  onSelected: (kind) => setState(() {
                    _selected = kind;
                    _error = null;
                  }),
                ),
              ),
              const SizedBox(height: PBSpace.lg),
              _in(0.65, _price(context, plan)),
              const SizedBox(height: PBSpace.lg),
              _cta(context, plan, trial: trial),
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _error == null
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: PBSpace.md),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: context.gameColors.red,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: PBSpace.lg),
              _assurance(context, plan),
              const SizedBox(height: PBSpace.md),
              _links(context),
              const SizedBox(height: PBSpace.md),
              Text(
                plan.terms(context),
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall
                    ?.copyWith(fontSize: 11, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context, ProState state, DateTime now) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _RoundButton(
            icon: CarbonIcons.close,
            label: context.l10n.proClose,
            onTap: () => Navigator.of(context).pop(false),
          ),
          if (!state.isPro)
            Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: PBSpace.sm),
                child: FreeDaysChip(
                  left: state.simulateLocked
                      ? Duration.zero
                      : state.freeLeft(now),
                ),
              ),
            ),
          _RoundButton(
            icon: CarbonIcons.restart,
            label: context.l10n.proReplay,
            onTap: _replay,
          ),
        ],
      );

  Widget _headline(BuildContext context, {required bool trial}) {
    final l = context.l10n;
    final title = context.textTheme.displaySmall?.copyWith(fontSize: 32);

    return Column(
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: trial
                    ? l.proPaywallHeadlineTrial
                    : l.proPaywallHeadlineEnded,
              ),
              const TextSpan(text: ' '),
              TextSpan(
                text: trial
                    ? l.proPaywallHeadlineTrialAccent
                    : l.proPaywallHeadlineEndedAccent,
                style: TextStyle(color: context.colorScheme.secondary),
              ),
            ],
          ),
          textAlign: TextAlign.center,
          style: title,
        ),
        const SizedBox(height: 6),
        Text(
          trial ? l.proPaywallSubTrial : l.proPaywallSubEnded,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _price(BuildContext context, ProPlan plan) => AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Column(
          key: ValueKey(plan.kind),
          children: [
            Text(
              plan.hero(context),
              textAlign: TextAlign.center,
              style: context.textTheme.displaySmall?.copyWith(fontSize: 30),
            ),
            const SizedBox(height: 2),
            Text(
              plan.heroSub(context),
              textAlign: TextAlign.center,
              style: context.textTheme.bodySmall?.copyWith(fontSize: 14),
            ),
          ],
        ),
      );

  Widget _cta(BuildContext context, ProPlan plan, {required bool trial}) {
    final scheme = context.colorScheme;
    final label = trial ? context.l10n.proCtaTrial : context.l10n.proCtaEnded;

    return AnimatedBuilder(
      animation: _breathe,
      builder: (context, child) => Transform.scale(
        scale:
            _busy ? 1 : 1 + 0.02 * Curves.easeInOut.transform(_breathe.value),
        child: child,
      ),
      child: SizedBox(
        width: double.infinity,
        child: _busy
            ? Container(
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(PBRadius.pill),
                  boxShadow: context.glow(scheme.shadow),
                ),
                child: CupertinoActivityIndicator(color: scheme.onPrimary),
              )
            : PillButton(label: label, onPressed: () => _buy(plan)),
      ),
    );
  }

  Widget _assurance(BuildContext context, ProPlan plan) {
    final style = context.textTheme.labelMedium?.copyWith(
      fontSize: 13,
      color: context.colorScheme.onSurfaceVariant,
    );
    Widget item(String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CarbonIcons.checkmark,
              size: 15,
              color: context.gameColors.jungle,
            ),
            const SizedBox(width: 5),
            Flexible(child: Text(text, style: style)),
          ],
        );

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: PBSpace.lg,
      runSpacing: PBSpace.xs,
      children: [
        item(plan.assurance(context)),
        item(context.l10n.proGymStaysFree),
      ],
    );
  }

  Widget _links(BuildContext context) {
    final style = context.textTheme.labelMedium?.copyWith(
      fontSize: 13,
      color: context.colorScheme.onSurfaceVariant,
    );
    Widget link(String text, VoidCallback onTap) => GestureDetector(
          onTap: _busy ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: PBSpace.xs),
            child: Text(text, style: style),
          ),
        );
    Widget dot() => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ExcludeSemantics(child: Text('·', style: style)),
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        link(context.l10n.proRestore, _restore),
        dot(),
        link(
          context.l10n.proTerms,
          () => _open(WebsiteLinks.termsOfService),
        ),
        dot(),
        link(
          context.l10n.proPrivacy,
          () => _open(WebsiteLinks.privacyPolicy),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: label,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: context.cardShadow,
          ),
          child: Material(
            color: context.colorScheme.surface,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox.square(
                dimension: 40,
                child: Icon(
                  icon,
                  size: 18,
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      );
}
