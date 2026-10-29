import 'dart:async';

import 'package:pushup_bro/features/social/data/social_backend.dart';
import 'package:pushup_bro/features/social/domain/ranking.dart';
import 'package:pushup_bro/features/social/model/bro_profile.dart';
import 'package:pushup_bro/features/social/model/cloud_backup.dart';
import 'package:pushup_bro/features/social/model/day_score.dart';
import 'package:pushup_bro/features/social/model/inbox_item.dart';

/// A [SocialBackend] in memory: for tests, and for previews on platforms
/// without Firebase. It follows the same rules as `firestore.rules`.
class FakeSocialBackend implements SocialBackend {
  FakeSocialBackend({this.startUid = 'me'});

  final String startUid;
  String? _uid;
  int _anonymous = 0;
  final Map<String, Set<SignInProvider>> _providers = {};

  /// Which uid an Apple or Google account belongs to, to test the
  /// "already has an island" path.
  final Map<SignInProvider, String> accountsByProvider = {};

  /// What the next sign-in sheet does.
  LinkOutcome? nextSheet;

  final Map<String, BroProfile> profiles = {};
  final Map<String, String> codes = {};
  final Map<String, String> friendNames = {};
  final Map<String, Set<String>> friendEdges = {};
  final Map<String, Set<String>> blocks = {};
  final Map<String, Map<String, DayScore>> scores = {};
  final Map<String, Map<String, InboxItem>> inboxes = {};
  final Map<String, CloudBackup> backups = {};

  /// Push tokens by uid, with their language.
  final Map<String, Map<String, String>> devices = {};

  final _changes = StreamController<void>.broadcast();

  void _changed() => _changes.add(null);

  Stream<T> _watch<T>(T Function() read) async* {
    yield read();
    yield* _changes.stream.map((_) => read());
  }

  @override
  String? get uid => _uid;

  @override
  Set<SignInProvider> get linkedProviders => {...?_providers[_uid]};

  @override
  Future<String> ensureSignedIn() async =>
      _uid ??= _anonymous++ == 0 ? startUid : '$startUid-$_anonymous';

  @override
  Future<LinkOutcome> link(SignInProvider provider) async {
    final sheet = nextSheet;
    nextSheet = null;
    if (sheet is LinkCancelled || sheet is LinkFailed) return sheet!;
    final owner = accountsByProvider[provider];
    final me = _uid!;
    if (owner != null && owner != me) {
      final switched = await _switchTo(owner);
      return switched;
    }
    accountsByProvider[provider] = me;
    (_providers[me] ??= {}).add(provider);
    _changed();
    return const Linked();
  }

  @override
  Future<LinkOutcome> signInWith(SignInProvider provider) async {
    final owner = accountsByProvider[provider];
    if (owner == null) {
      final linked = await link(provider);
      return linked;
    }
    final switched = await _switchTo(owner);
    return switched;
  }

  /// Like Firebase: the anonymous account is cleaned up, then [owner] is
  /// signed in.
  Future<SwitchedAccount> _switchTo(String owner) async {
    final leftover = _uid!;
    final friends = [...?friendEdges[leftover]];
    await deleteAccount();
    _uid = owner;
    return SwitchedAccount(
      uid: owner,
      leftover: leftover,
      leftoverFriends: friends,
    );
  }

  @override
  Future<String> signOut() async {
    _uid = null;
    final fresh = await ensureSignedIn();
    return fresh;
  }

  @override
  Future<void> deleteAccount() async {
    final me = _uid!;
    profiles.remove(me);
    codes.removeWhere((_, owner) => owner == me);
    friendNames.remove(me);
    friendEdges.remove(me);
    for (final edges in friendEdges.values) {
      edges.remove(me);
    }
    blocks.remove(me);
    for (final day in scores.values) {
      day.remove(me);
    }
    inboxes.remove(me);
    backups.remove(me);
    accountsByProvider.removeWhere((_, owner) => owner == me);
    _providers.remove(me);
    _uid = null;
    _changed();
  }

  @override
  Future<BroProfile?> profile(String uid) async => profiles[uid];

  @override
  Future<void> saveProfile(BroProfile profile) async {
    profiles[profile.uid] = profile;
    _changed();
  }

  @override
  Future<bool> claimCode(String code, String uid) async {
    if (codes.containsKey(code)) return false;
    codes[code] = uid;
    return true;
  }

  @override
  Future<String?> uidForCode(String code) async => codes[code];

  @override
  Future<String?> friendName(String uid) async => friendNames[uid];

  @override
  Future<void> setFriendName(String uid, String name) async {
    friendNames[uid] = name;
    _changed();
  }

  @override
  Stream<List<String>> friends(String uid) =>
      _watch(() => [...?friendEdges[uid]]);

  @override
  Future<void> addFriend({
    required String me,
    required String friend,
    required String code,
  }) async {
    if (codes[code] != friend) throw StateError('permission-denied');
    (friendEdges[me] ??= {}).add(friend);
    (friendEdges[friend] ??= {}).add(me);
    _changed();
  }

  @override
  Future<void> removeFriend({
    required String me,
    required String friend,
  }) async {
    friendEdges[me]?.remove(friend);
    friendEdges[friend]?.remove(me);
    _changed();
  }

  @override
  Future<void> block({required String me, required String other}) async {
    (blocks[me] ??= {}).add(other);
    await removeFriend(me: me, friend: other);
  }

  @override
  Future<void> unblock({required String me, required String other}) async {
    blocks[me]?.remove(other);
    _changed();
  }

  @override
  Stream<List<String>> blocked(String uid) => _watch(() => [...?blocks[uid]]);

  @override
  Future<void> writeScore(String day, DayScore score) async {
    // The rules: only up, and at most 1500 a day.
    final before = scores[day]?[score.uid]?.count ?? 0;
    if (score.count < before || score.count > 1500) {
      throw StateError('permission-denied');
    }
    (scores[day] ??= {})[score.uid] = score;
    _changed();
  }

  @override
  Stream<List<DayScore>> scoresOf(String day, List<String> uids) => _watch(
        () => [
          for (final uid in uids)
            if (scores[day]?[uid] case final score?) score,
        ],
      );

  @override
  Stream<List<DayScore>> topScores(String day, {int limit = 50}) => _watch(
        () => rank(
          (scores[day]?.values ?? const <DayScore>[]).where((s) => s.public),
        ).take(limit).toList(),
      );

  @override
  Future<int> countAbove(String day, int count) async =>
      (scores[day]?.values ?? const <DayScore>[])
          .where((s) => s.public && s.count > count)
          .length;

  @override
  Future<int> playerCount(String day) async => scores[day]?.length ?? 0;

  @override
  Future<bool> send(String to, InboxItem item) async {
    final box = inboxes[to] ??= {};
    if (box.containsKey(item.id)) return false;
    box[item.id] = item;
    _changed();
    return true;
  }

  @override
  Stream<List<InboxItem>> inbox(String uid) =>
      _watch(() => [...?inboxes[uid]?.values]);

  @override
  Future<void> removeFromInbox(String uid, String id) async {
    inboxes[uid]?.remove(id);
    _changed();
  }

  @override
  Future<void> saveDevice(
    String uid, {
    required String token,
    required String language,
  }) async =>
      (devices[uid] ??= {})[token] = language;

  @override
  Future<void> removeDevice(String uid, String token) async =>
      devices[uid]?.remove(token);

  @override
  Future<CloudBackup?> readBackup(String uid) async => backups[uid];

  @override
  Future<void> writeBackup(String uid, CloudBackup backup) async {
    if (linkedProviders.isEmpty) throw StateError('permission-denied');
    backups[uid] = backup;
  }
}
