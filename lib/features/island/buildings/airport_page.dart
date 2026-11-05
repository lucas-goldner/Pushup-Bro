import 'dart:async';

import 'package:carbon_icons/carbon_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/extensions/build_context_ext.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/core/style/pb_tokens.dart';
import 'package:pushup_bro/core/widgets/pill_button.dart';
import 'package:pushup_bro/features/friends/add_bro_page.dart';
import 'package:pushup_bro/features/island/buildings/airport/departures_board.dart';
import 'package:pushup_bro/features/island/buildings/airport/take_off_page.dart';
import 'package:pushup_bro/features/social/cubit/account_cubit.dart';
import 'package:pushup_bro/features/social/cubit/bros_cubit.dart';
import 'package:pushup_bro/features/social/domain/gift_drops.dart';
import 'package:pushup_bro/features/social/model/bro_profile.dart';
import 'package:pushup_bro/features/social/widgets/social_widgets.dart';

/// The airport: a departures board with a flight to every bro's island.
/// Tapping one takes off and lands on their island, where a gift can be
/// dropped. Like the rest of the social side it needs the account, and
/// shows offline or loading until it's there.
class AirportPage extends StatelessWidget {
  const AirportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;

    return Scaffold(
      backgroundColor: context.colorScheme.surfaceContainerLowest,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                PBSpace.sm,
                PBSpace.sm,
                PBSpace.lg,
                0,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(CarbonIcons.chevron_left),
                  ),
                  const SizedBox(width: PBSpace.xs),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.buildingAirport,
                          style: context.textTheme.headlineMedium,
                        ),
                        Text(
                          l.airportSubtitle,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SocialGate(
                builder: (context, me) => BlocProvider(
                  key: ValueKey(me.uid),
                  create: (context) => BrosCubit(
                    context.read<AccountCubit>().backend,
                    me: me,
                  )..start(),
                  child: _Departures(me: me),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Departures extends StatefulWidget {
  const _Departures({required this.me});

  final BroProfile me;

  @override
  State<_Departures> createState() => _DeparturesState();
}

class _DeparturesState extends State<_Departures> {
  Set<String> _dropped = const {};

  @override
  void initState() {
    super.initState();
    unawaited(_loadDropped());
  }

  /// Which bros already got today's gift, to show on the board.
  Future<void> _loadDropped() async {
    final dropped = await droppedToday(
      SharedPreferencesProvider(),
      now: DateTime.now(),
    );
    if (mounted) setState(() => _dropped = dropped);
  }

  Future<void> _fly(Bro bro) async {
    await flyToIsland(
      context,
      uid: bro.uid,
      name: friendLabel(context, bro.profile, bro.name),
    );
    // Back from the visit: a gift may have been dropped.
    await _loadDropped();
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<BrosCubit, BrosState>(
        builder: (context, state) {
          // Highest islands first, like the big flights.
          final bros = [...state.bros]..sort(
              (a, b) => b.profile.islandLevel.compareTo(a.profile.islandLevel),
            );

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              PBSpace.lg,
              PBSpace.lg,
              PBSpace.lg,
              PBSpace.xxl,
            ),
            children: [
              _Board(
                child: !state.loaded
                    ? const Padding(
                        padding: EdgeInsets.all(PBSpace.xxl),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : bros.isEmpty
                        ? const _NoFlights()
                        : Column(
                            children: [
                              for (final (i, bro) in bros.indexed)
                                FlightRow(
                                  bro: bro,
                                  index: i,
                                  giftDropped: _dropped.contains(bro.uid),
                                  onTap: () => unawaited(_fly(bro)),
                                ),
                            ],
                          ),
              ),
              if (bros.isNotEmpty) ...[
                const SizedBox(height: PBSpace.lg),
                Text(
                  context.l10n.airportHint,
                  textAlign: TextAlign.center,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          );
        },
      );
}

/// The departures board itself: its heading, the columns and [child].
class _Board extends StatelessWidget {
  const _Board({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = boardColors(context);
    final label = context.textTheme.labelSmall?.copyWith(
      color: colors.ink.withValues(alpha: 0.55),
      fontWeight: FontWeight.w800,
      letterSpacing: 1,
    );

    return Container(
      padding: const EdgeInsets.all(PBSpace.md),
      decoration: BoxDecoration(
        color: colors.board,
        borderRadius: BorderRadius.circular(PBRadius.lg),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              PBSpace.sm,
              PBSpace.xs,
              PBSpace.sm,
              PBSpace.md,
            ),
            child: Row(
              children: [
                Icon(CarbonIcons.plane, color: colors.amber, size: 20),
                const SizedBox(width: PBSpace.sm),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: FlapText(
                      l.airportDepartures.toUpperCase(),
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: PBSpace.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${l.airportFlight} · ${l.airportDestination}'
                        .toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: label,
                  ),
                ),
                Text(l.airportGate.toUpperCase(), style: label),
              ],
            ),
          ),
          Divider(color: colors.ink.withValues(alpha: 0.12), height: 12),
          child,
        ],
      ),
    );
  }
}

class _NoFlights extends StatelessWidget {
  const _NoFlights();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final colors = boardColors(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PBSpace.md,
        PBSpace.lg,
        PBSpace.md,
        PBSpace.md,
      ),
      child: Column(
        children: [
          Text(
            l.airportEmptyTitle,
            textAlign: TextAlign.center,
            style: context.textTheme.titleMedium?.copyWith(
              color: colors.amber,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: PBSpace.sm),
          Text(
            l.airportEmptyText,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: colors.ink.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: PBSpace.lg),
          PillButton(
            label: l.airportAddBro,
            icon: CarbonIcons.user_follow,
            compact: true,
            color: context.gameColors.jungle,
            onPressed: () => unawaited(openAddBro(context)),
          ),
        ],
      ),
    );
  }
}
