import 'package:equatable/equatable.dart';
import 'package:pushup_bro/features/social/domain/local_day.dart';

enum InboxKind { wave, banana, nudge }

/// A wave, banana or nudge from a friend: `users/{uid}/inbox/{id}`.
class InboxItem extends Equatable {
  const InboxItem({
    required this.id,
    required this.kind,
    required this.fromUid,
    required this.fromName,
    required this.sentAt,
  });

  /// A new item from [fromUid]; a nudge's id is one per friend and day, so
  /// the rules can refuse a second one.
  factory InboxItem.create({
    required InboxKind kind,
    required String fromUid,
    required String fromName,
    required DateTime now,
  }) =>
      InboxItem(
        id: kind == InboxKind.nudge
            ? 'nudge_${fromUid}_${localDayKey(now)}'
            : '${kind.name}_${fromUid}_${now.millisecondsSinceEpoch}',
        kind: kind,
        fromUid: fromUid,
        fromName: fromName,
        sentAt: now,
      );

  factory InboxItem.fromJson(String id, Map<String, dynamic> json) => InboxItem(
        id: id,
        kind: InboxKind.values.asNameMap()[json['kind']] ?? InboxKind.wave,
        fromUid: json['fromUid'] as String? ?? '',
        fromName: json['fromName'] as String? ?? '',
        sentAt: DateTime.fromMillisecondsSinceEpoch(
          (json['sentAt'] as num?)?.toInt() ?? 0,
        ),
      );

  final String id;
  final InboxKind kind;
  final String fromUid;

  /// The name the sender goes by for this friend.
  final String fromName;
  final DateTime sentAt;

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'fromUid': fromUid,
        'fromName': fromName,
        'sentAt': sentAt.millisecondsSinceEpoch,
      };

  @override
  List<Object?> get props => [id, kind, fromUid, fromName, sentAt];
}
