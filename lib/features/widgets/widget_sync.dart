import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pushup_bro/core/cubit/db_cubit.dart';
import 'package:pushup_bro/core/cubit/db_state.dart';
import 'package:pushup_bro/core/cubit/game_inventory_cubit.dart';
import 'package:pushup_bro/core/cubit/game_inventory_state.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_cubit.dart';
import 'package:pushup_bro/core/cubit/shared_preferences_state.dart';
import 'package:pushup_bro/features/pro/cubit/pro_cubit.dart';
import 'package:pushup_bro/features/pro/model/pro_state.dart';
import 'package:pushup_bro/features/widgets/widget_snapshot.dart';
import 'package:pushup_bro/generated/l10n.dart';

/// Sends [WidgetSnapshot]s to the iOS widget extension over the
/// `pushup_bro/widgets` channel (`WidgetBridge` in AppDelegate.swift).
/// Does nothing on other platforms, and skips snapshots it already sent.
class WidgetSync {
  WidgetSync({MethodChannel? channel, bool? enabled})
      : _channel = channel ?? const MethodChannel('pushup_bro/widgets'),
        enabled =
            enabled ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS);

  final MethodChannel _channel;

  /// Whether there are widgets to update (iOS only).
  final bool enabled;
  String? _lastSent;

  /// Sends [snapshot] unless it's the one sent last. Returns whether it was
  /// sent.
  Future<bool> push(WidgetSnapshot snapshot) async {
    if (!enabled) return false;
    final json = jsonEncode(snapshot.toJson());
    if (json == _lastSent) return false;
    try {
      await _channel.invokeMethod<void>('update', json);
      _lastSent = json;
      return true;
    } on PlatformException catch (error) {
      debugPrint('Widgets not updated: ${error.message}');
    } on MissingPluginException {
      // No widget bridge on this build.
    }
    return false;
  }
}

/// Keeps the iOS widgets up to date: whenever the pushups, the streak, the
/// Jungle Trek, the bananas, Pro, the language or the appearance change,
/// and when the app comes back to the foreground (a new day).
///
/// Put it below the app's `Localizations` (e.g. in `CupertinoApp.builder`)
/// so the Jungle Trek stage title is in the app's language.
class WidgetSyncScope extends StatefulWidget {
  const WidgetSyncScope({
    required this.child,
    this.sync,
    this.clock,
    super.key,
  });

  final Widget child;

  /// Defaults to a [WidgetSync] on the real channel.
  final WidgetSync? sync;
  final DateTime Function()? clock;

  @override
  State<WidgetSyncScope> createState() => _WidgetSyncScopeState();
}

class _WidgetSyncScopeState extends State<WidgetSyncScope>
    with WidgetsBindingObserver {
  late final WidgetSync _sync = widget.sync ?? WidgetSync();
  Timer? _debounce;
  bool _loadingSets = false;
  bool _setsLoaded = false;
  S? _l10n;

  @override
  void initState() {
    super.initState();
    if (_sync.enabled) WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The language (and with it the stage title) may have changed.
    _l10n = S.maybeOf(context);
    _schedule();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _schedule();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (_sync.enabled) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _schedule() {
    if (!_sync.enabled) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _push);
  }

  /// Whether the database and the store are loaded, so a snapshot doesn't
  /// overwrite the widgets with empty data.
  bool get _ready =>
      context.read<ProCubit>().state.loaded &&
      context.read<GameInventoryCubit>().state is GameInventoryLoaded;

  Future<void> _push() async {
    if (!mounted || !_ready) return;
    if (!_setsLoaded) {
      // The app doesn't load the pushup history on start, so load it once
      // the database is open (the inventory loads after it).
      if (_loadingSets) return;
      _loadingSets = true;
      await context.read<DBCubit>().getAllPushupSets();
      _setsLoaded = true;
      _loadingSets = false;
      if (!mounted) return;
    }

    final l10n = _l10n;
    final prefs = context.read<SharedPreferencesCubit>().state;
    final db = context.read<DBCubit>().state;
    final snapshot = WidgetSnapshot.from(
      pushupSets: db.pushupSets,
      user: db.user,
      inventory: context.read<GameInventoryCubit>().state.inventory,
      pro: context.read<ProCubit>().state,
      language: prefs.language?.languageCode ?? 'en',
      appearance: prefs.appearance,
      now: (widget.clock ?? DateTime.now)(),
      stageTitle: (stage) => l10n == null ? '' : stage.title(l10n),
    );
    await _sync.push(snapshot);
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
        listeners: [
          BlocListener<DBCubit, DBState>(
            listener: (_, __) => _schedule(),
          ),
          BlocListener<GameInventoryCubit, GameInventoryState>(
            // Fetching carries an empty inventory.
            listenWhen: (_, current) => current is GameInventoryLoaded,
            listener: (_, __) => _schedule(),
          ),
          BlocListener<ProCubit, ProState>(
            listener: (_, __) => _schedule(),
          ),
          BlocListener<SharedPreferencesCubit, SharedPreferencesState>(
            listenWhen: (previous, current) =>
                previous.language != current.language ||
                previous.appearance != current.appearance,
            listener: (_, __) => _schedule(),
          ),
        ],
        child: widget.child,
      );
}
