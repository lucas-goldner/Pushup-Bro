import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pushup_bro/features/social/data/social_backend.dart';
import 'package:pushup_bro/features/social/model/bro_profile.dart';
import 'package:pushup_bro/features/social/model/cloud_backup.dart';
import 'package:pushup_bro/features/social/model/day_score.dart';
import 'package:pushup_bro/features/social/model/inbox_item.dart';

/// The [SocialBackend] on Firebase: anonymous auth that Pro members link to
/// Apple or Google, and Firestore (`nam5`). The data model and its rules
/// are in `firestore.rules`.
class FirestoreSocialBackend implements SocialBackend {
  FirestoreSocialBackend({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  /// `whereIn` takes at most 30 values.
  static const _chunk = 30;

  CollectionReference<Map<String, dynamic>> get _users =>
      _db.collection('users');
  DocumentReference<Map<String, dynamic>> _user(String uid) => _users.doc(uid);
  CollectionReference<Map<String, dynamic>> _scores(String day) =>
      _db.collection('days').doc(day).collection('scores');

  @override
  String? get uid => _auth.currentUser?.uid;

  @override
  Set<SignInProvider> get linkedProviders => {
        for (final info in _auth.currentUser?.providerData ?? <UserInfo>[])
          if (info.providerId == 'apple.com')
            SignInProvider.apple
          else if (info.providerId == 'google.com')
            SignInProvider.google,
      };

  @override
  Future<String> ensureSignedIn() async {
    final current = _auth.currentUser;
    if (current != null) return current.uid;
    final credential = await _auth.signInAnonymously();
    return credential.user!.uid;
  }

  AuthProvider _provider(SignInProvider provider) => switch (provider) {
        SignInProvider.apple => AppleAuthProvider()
          ..addScope('email')
          ..addScope('name'),
        SignInProvider.google => GoogleAuthProvider(),
      };

  @override
  Future<LinkOutcome> link(SignInProvider provider) async {
    final user = _auth.currentUser;
    if (user == null) return const LinkFailed('no-user');
    try {
      await user.linkWithProvider(_provider(provider));
      return const Linked();
    } on FirebaseAuthException catch (e) {
      final outcome = await _afterFailedLink(e, leftover: user.uid);
      return outcome;
    }
  }

  @override
  Future<LinkOutcome> signInWith(SignInProvider provider) => link(provider);

  /// The Apple or Google account already belongs to another uid: sign in
  /// to that one instead, so its island can be restored.
  Future<LinkOutcome> _afterFailedLink(
    FirebaseAuthException e, {
    required String leftover,
  }) async {
    switch (e.code) {
      case 'credential-already-in-use' || 'email-already-in-use':
        final credential = e.credential;
        if (credential == null) return LinkFailed(e.code);
        // Clean up the anonymous account while still signed in to it (the
        // rules only let owners delete), remembering its friends.
        final friends = (await _user(leftover).collection('friends').get())
            .docs
            .map((doc) => doc.id)
            .toList();
        await _deleteData(leftover);
        await _auth.currentUser?.delete();
        final result = await _auth.signInWithCredential(credential);
        return SwitchedAccount(
          uid: result.user!.uid,
          leftover: leftover,
          leftoverFriends: friends,
        );
      case 'canceled' || 'web-context-canceled' || 'popup-closed-by-user':
        return const LinkCancelled();
      default:
        // Apple's sheet reports a cancel as an unknown error.
        return e.message?.contains('1001') ?? false
            ? const LinkCancelled()
            : LinkFailed(e.code);
    }
  }

  @override
  Future<String> signOut() async {
    await _auth.signOut();
    final fresh = await ensureSignedIn();
    return fresh;
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final me = user.uid;
    // Apple wants its token revoked (App Review 5.1.1(v)); that needs a
    // fresh authorization code, which re-authenticating gives.
    if (linkedProviders.contains(SignInProvider.apple)) {
      final again = await user.reauthenticateWithProvider(AppleAuthProvider());
      final code = again.additionalUserInfo?.authorizationCode;
      if (code != null) await _auth.revokeTokenWithAuthorizationCode(code);
    } else if (linkedProviders.contains(SignInProvider.google)) {
      await user.reauthenticateWithProvider(GoogleAuthProvider());
    }
    await _deleteData(me);
    await user.delete();
  }

  /// Everything stored for [me]: the profile and its subcollections, the
  /// code, the edges on friends' profiles and the last days' scores.
  Future<void> _deleteData(String me) async {
    final profile = await _user(me).get();
    final code = profile.data()?['code'] as String?;
    final friends = await _user(me).collection('friends').get();
    final batch = _db.batch();
    for (final friend in friends.docs) {
      batch.delete(_user(friend.id).collection('friends').doc(me));
    }
    final subs = [
      'friends',
      'blocked',
      'inbox',
      'private',
      'devices',
      // Only a linked account may touch its backup (and only it has one).
      if (linkedProviders.isNotEmpty) 'backup',
    ];
    for (final sub in subs) {
      for (final doc in (await _user(me).collection(sub).get()).docs) {
        batch.delete(doc.reference);
      }
    }
    if (code != null && code.isNotEmpty) {
      batch.delete(_db.collection('codes').doc(code));
    }
    final now = DateTime.now();
    for (var back = 0; back < 31; back++) {
      final day = now.subtract(Duration(days: back));
      batch.delete(_scores(_dayKey(day)).doc(me));
    }
    batch.delete(_user(me));
    await batch.commit();
  }

  static String _dayKey(DateTime time) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)}';
  }

  @override
  Future<BroProfile?> profile(String uid) async {
    final doc = await _user(uid).get();
    final data = doc.data();
    return data == null ? null : BroProfile.fromJson(uid, data);
  }

  @override
  Future<void> saveProfile(BroProfile profile) => _user(profile.uid).set(
        {
          ...profile.toJson(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

  @override
  Future<bool> claimCode(String code, String uid) =>
      _db.runTransaction((transaction) async {
        final ref = _db.collection('codes').doc(code);
        if ((await transaction.get(ref)).exists) return false;
        transaction.set(ref, {'uid': uid});
        return true;
      });

  @override
  Future<String?> uidForCode(String code) async {
    final doc = await _db.collection('codes').doc(code).get();
    return doc.data()?['uid'] as String?;
  }

  @override
  Future<String?> friendName(String uid) async {
    try {
      final doc = await _user(uid).collection('private').doc('profile').get();
      return doc.data()?['friendName'] as String?;
    } on FirebaseException {
      // Not friends (yet): the rules hide it.
      return null;
    }
  }

  @override
  Future<void> setFriendName(String uid, String name) => _user(uid)
      .collection('private')
      .doc('profile')
      .set({'friendName': name}, SetOptions(merge: true));

  @override
  Stream<List<String>> friends(String uid) => _user(uid)
      .collection('friends')
      .snapshots()
      .map((snap) => [for (final doc in snap.docs) doc.id]);

  @override
  Future<void> addFriend({
    required String me,
    required String friend,
    required String code,
  }) async {
    // Both edges carry the friend's code: the rules only let someone who
    // knows it (codes/{code}.uid == friend) make the two of them bros.
    final now = FieldValue.serverTimestamp();
    final batch = _db.batch()
      ..set(_user(me).collection('friends').doc(friend), {
        'code': code,
        'since': now,
      })
      ..set(_user(friend).collection('friends').doc(me), {
        'code': code,
        'since': now,
      });
    await batch.commit();
  }

  @override
  Future<void> removeFriend({
    required String me,
    required String friend,
  }) async {
    final batch = _db.batch()
      ..delete(_user(me).collection('friends').doc(friend))
      ..delete(_user(friend).collection('friends').doc(me));
    await batch.commit();
  }

  @override
  Future<void> block({required String me, required String other}) async {
    final batch = _db.batch()
      ..set(_user(me).collection('blocked').doc(other), {
        'since': FieldValue.serverTimestamp(),
      })
      ..delete(_user(me).collection('friends').doc(other))
      ..delete(_user(other).collection('friends').doc(me));
    await batch.commit();
  }

  @override
  Future<void> unblock({required String me, required String other}) =>
      _user(me).collection('blocked').doc(other).delete();

  @override
  Stream<List<String>> blocked(String uid) => _user(uid)
      .collection('blocked')
      .snapshots()
      .map((snap) => [for (final doc in snap.docs) doc.id]);

  @override
  Future<void> writeScore(String day, DayScore score) =>
      // A merge with the new total, not an increment, so a retry is safe.
      _scores(day).doc(score.uid).set(score.toJson(), SetOptions(merge: true));

  @override
  Stream<List<DayScore>> scoresOf(String day, List<String> uids) {
    if (uids.isEmpty) return Stream.value(const []);
    final chunks = [
      for (var i = 0; i < uids.length; i += _chunk)
        uids.sublist(i, (i + _chunk).clamp(0, uids.length)),
    ];
    final latest = List<List<DayScore>?>.filled(chunks.length, null);
    late final StreamController<List<DayScore>> controller;
    final subscriptions = <StreamSubscription<void>>[];
    controller = StreamController<List<DayScore>>(
      onListen: () {
        for (final (i, chunk) in chunks.indexed) {
          subscriptions.add(
            _scores(day)
                .where(FieldPath.documentId, whereIn: chunk)
                .snapshots()
                .listen(
              (snap) {
                latest[i] = [
                  for (final doc in snap.docs)
                    DayScore.fromJson(doc.id, doc.data()),
                ];
                if (latest.every((part) => part != null)) {
                  controller.add([for (final part in latest) ...part!]);
                }
              },
              onError: controller.addError,
            ),
          );
        }
      },
      onCancel: () async {
        for (final subscription in subscriptions) {
          await subscription.cancel();
        }
      },
    );
    return controller.stream;
  }

  @override
  Stream<List<DayScore>> topScores(String day, {int limit = 50}) => _scores(day)
      .where('public', isEqualTo: true)
      .orderBy('count', descending: true)
      .limit(limit)
      .snapshots()
      .map(
        (snap) => [
          for (final doc in snap.docs) DayScore.fromJson(doc.id, doc.data()),
        ],
      );

  @override
  Future<int> countAbove(String day, int count) async {
    final result = await _scores(day)
        .where('public', isEqualTo: true)
        .where('count', isGreaterThan: count)
        .count()
        .get();
    return result.count ?? 0;
  }

  @override
  Future<int> playerCount(String day) async {
    final result = await _scores(day).count().get();
    return result.count ?? 0;
  }

  @override
  Future<bool> send(String to, InboxItem item) async {
    try {
      await _user(to).collection('inbox').doc(item.id).set(item.toJson());
      return true;
    } on FirebaseException catch (e) {
      // A second nudge the same day: the rules refuse to overwrite it.
      if (e.code == 'permission-denied') return false;
      rethrow;
    }
  }

  @override
  Stream<List<InboxItem>> inbox(String uid) =>
      _user(uid).collection('inbox').snapshots().map(
            (snap) => [
              for (final doc in snap.docs)
                InboxItem.fromJson(doc.id, doc.data()),
            ],
          );

  @override
  Future<void> removeFromInbox(String uid, String id) =>
      _user(uid).collection('inbox').doc(id).delete();

  @override
  Future<void> saveDevice(
    String uid, {
    required String token,
    required String language,
  }) =>
      _user(uid).collection('devices').doc(token).set({
        'token': token,
        'language': language,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

  @override
  Future<void> removeDevice(String uid, String token) =>
      _user(uid).collection('devices').doc(token).delete();

  @override
  Future<CloudBackup?> readBackup(String uid) async {
    final docs = (await _user(uid).collection('backup').get()).docs;
    final state = docs.where((doc) => doc.id == 'state').firstOrNull;
    if (state == null) return null;
    final sets = [
      for (final doc in docs)
        if (doc.id.startsWith('h'))
          for (final set in (doc.data()['sets'] as List? ?? const []))
            Map<String, dynamic>.from(set as Map),
    ];
    return CloudBackup.fromJson(state.data(), sets);
  }

  @override
  Future<void> writeBackup(String uid, CloudBackup backup) async {
    final backupDocs = _user(uid).collection('backup');
    final batch = _db.batch()..set(backupDocs.doc('state'), backup.stateJson());
    final years = backup.setsByYear(setYear);
    for (final MapEntry(key: year, value: sets) in years.entries) {
      batch.set(backupDocs.doc('h$year'), {'sets': sets});
    }
    await batch.commit();
  }
}
