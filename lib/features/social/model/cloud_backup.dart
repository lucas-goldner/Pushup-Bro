import 'package:equatable/equatable.dart';

/// The year a set (as JSON) was done in, from its first pushup.
int setYear(Map<String, dynamic> set) {
  final pushups = set['pushups'] as List? ?? const [];
  final first = pushups.isEmpty ? null : pushups.first as Map?;
  return DateTime.tryParse(first?['completedAt'] as String? ?? '')?.year ?? 0;
}

/// [backup]'s sets plus the [local] ones it doesn't have (by id), so
/// pushups done on this iPhone before restoring aren't lost.
List<Map<String, dynamic>> mergeSets(
  List<Map<String, dynamic>> backup,
  List<Map<String, dynamic>> local,
) {
  final ids = {for (final set in backup) set['id']};
  return [
    ...backup,
    for (final set in local)
      if (!ids.contains(set['id'])) set,
  ];
}

/// Everything a Pro member gets back on a new iPhone: game prefs, the
/// inventory and look, and every pushup set.
///
/// It lives in `users/{uid}/backup/state` plus one document of sets per
/// year (`backup/h{yyyy}`), each well under Firestore's 1 MB limit.
class CloudBackup extends Equatable {
  const CloudBackup({
    required this.savedAt,
    required this.device,
    required this.prefs,
    required this.inventory,
    required this.sets,
    this.version = 1,
  });

  factory CloudBackup.fromJson(
    Map<String, dynamic> state,
    List<Map<String, dynamic>> sets,
  ) =>
      CloudBackup(
        version: (state['v'] as num?)?.toInt() ?? 1,
        savedAt: DateTime.fromMillisecondsSinceEpoch(
          (state['savedAt'] as num?)?.toInt() ?? 0,
        ),
        device: state['device'] as String? ?? '',
        prefs: Map<String, Object?>.from(state['prefs'] as Map? ?? const {}),
        inventory: Map<String, dynamic>.from(
          state['inventory'] as Map? ?? const {},
        ),
        sets: sets,
      );

  final int version;
  final DateTime savedAt;

  /// A short name for the iPhone that saved it.
  final String device;

  /// The game's SharedPreferences, by key; device settings are left out.
  final Map<String, Object?> prefs;

  /// The inventory as JSON: bananas, monkeys and their looks, quests, trek.
  final Map<String, dynamic> inventory;

  /// Every pushup set as JSON, each with its `id`.
  final List<Map<String, dynamic>> sets;

  int get pushups => sets.fold(
        0,
        (sum, set) => sum + ((set['pushups'] as List?)?.length ?? 0),
      );

  Map<String, dynamic> stateJson() => {
        'v': version,
        'savedAt': savedAt.millisecondsSinceEpoch,
        'device': device,
        'prefs': prefs,
        'inventory': inventory,
      };

  /// The sets by year, for the `backup/h{yyyy}` documents.
  Map<int, List<Map<String, dynamic>>> setsByYear(
    int Function(Map<String, dynamic> set) yearOf,
  ) {
    final years = <int, List<Map<String, dynamic>>>{};
    for (final set in sets) {
      (years[yearOf(set)] ??= []).add(set);
    }
    return years;
  }

  @override
  List<Object?> get props => [version, savedAt, device, prefs, inventory, sets];
}
