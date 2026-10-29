import 'package:equatable/equatable.dart';
import 'package:pushup_bro/features/social/data/social_backend.dart';
import 'package:pushup_bro/features/social/model/bro_profile.dart';
import 'package:pushup_bro/features/social/model/cloud_backup.dart';

enum AccountStatus {
  /// Signing in and loading the profile.
  starting,
  ready,

  /// No connection on the first launch: social features wait for it.
  offline,
}

/// A saved island found after signing in on a new iPhone.
class RestoreOffer extends Equatable {
  const RestoreOffer(this.backup);

  final CloudBackup backup;

  @override
  List<Object?> get props => [backup];
}

class AccountState extends Equatable {
  const AccountState({
    this.status = AccountStatus.starting,
    this.profile,
    this.linked = const {},
    this.friendName = '',
    this.savedAt,
    this.restore,
  });

  final AccountStatus status;
  final BroProfile? profile;

  /// Apple and Google, when connected.
  final Set<SignInProvider> linked;

  /// The name friends see; empty until set.
  final String friendName;

  /// When the island was last saved to the cloud.
  final DateTime? savedAt;
  final RestoreOffer? restore;

  String? get uid => profile?.uid;
  bool get isLinked => linked.isNotEmpty;

  AccountState copyWith({
    AccountStatus? status,
    BroProfile? profile,
    Set<SignInProvider>? linked,
    String? friendName,
    DateTime? savedAt,
    RestoreOffer? restore,
    bool clearRestore = false,
  }) =>
      AccountState(
        status: status ?? this.status,
        profile: profile ?? this.profile,
        linked: linked ?? this.linked,
        friendName: friendName ?? this.friendName,
        savedAt: savedAt ?? this.savedAt,
        restore: clearRestore ? null : restore ?? this.restore,
      );

  @override
  List<Object?> get props =>
      [status, profile, linked, friendName, savedAt, restore];
}
