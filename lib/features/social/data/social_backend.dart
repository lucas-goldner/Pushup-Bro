import 'package:pushup_bro/features/social/model/bro_profile.dart';
import 'package:pushup_bro/features/social/model/cloud_backup.dart';
import 'package:pushup_bro/features/social/model/day_score.dart';
import 'package:pushup_bro/features/social/model/inbox_item.dart';

/// The sign-in providers a Pro member can connect.
enum SignInProvider { apple, google }

/// How connecting a provider went.
sealed class LinkOutcome {
  const LinkOutcome();
}

/// Connected to this account; the uid stays.
class Linked extends LinkOutcome {
  const Linked();
}

/// That Apple or Google account already has an island from another
/// iPhone. The backend has signed in to it: [uid] is now the current user.
/// The anonymous account it left ([leftover]) is deleted; its friends are
/// in [leftoverFriends], to be added again on [uid].
class SwitchedAccount extends LinkOutcome {
  const SwitchedAccount({
    required this.uid,
    required this.leftover,
    this.leftoverFriends = const [],
  });

  final String uid;
  final String leftover;
  final List<String> leftoverFriends;
}

/// The player closed the sign-in sheet.
class LinkCancelled extends LinkOutcome {
  const LinkCancelled();
}

class LinkFailed extends LinkOutcome {
  const LinkFailed(this.reason);

  final String reason;
}

/// Everything social goes through this: Firebase in the app
/// (`FirestoreSocialBackend`), memory in tests and previews
/// (`FakeSocialBackend`).
abstract class SocialBackend {
  // Account.

  /// The signed-in user, signing in anonymously first if nobody is.
  Future<String> ensureSignedIn();
  String? get uid;
  Set<SignInProvider> get linkedProviders;

  /// Connects [provider] to the current account (see [LinkOutcome]).
  Future<LinkOutcome> link(SignInProvider provider);

  /// Signs in with [provider] on a new iPhone, to restore a saved island.
  Future<LinkOutcome> signInWith(SignInProvider provider);

  /// Signs out and starts over on a fresh anonymous account.
  Future<String> signOut();

  /// Deletes the account and everything stored for it on the server.
  Future<void> deleteAccount();

  // Profiles and codes.

  Future<BroProfile?> profile(String uid);
  Future<void> saveProfile(BroProfile profile);

  /// Claims [code] for [uid]; false when someone already has it.
  Future<bool> claimCode(String code, String uid);
  Future<String?> uidForCode(String code);

  /// The name a player goes by for their friends only.
  Future<String?> friendName(String uid);
  Future<void> setFriendName(String uid, String name);

  // Friends.

  Stream<List<String>> friends(String uid);

  /// Makes [me] and [friend] bros; [code] is the friend's code, which the
  /// rules check.
  Future<void> addFriend({
    required String me,
    required String friend,
    required String code,
  });
  Future<void> removeFriend({required String me, required String friend});
  Future<void> block({required String me, required String other});
  Future<void> unblock({required String me, required String other});
  Stream<List<String>> blocked(String uid);

  // Today's scores.

  Future<void> writeScore(String day, DayScore score);
  Stream<List<DayScore>> scoresOf(String day, List<String> uids);
  Stream<List<DayScore>> topScores(String day, {int limit = 50});

  /// How many players beat [count] on [day].
  Future<int> countAbove(String day, int count);
  Future<int> playerCount(String day);

  // Inbox.

  /// Sends [item] to [to]; false when the rules refused it (a second nudge
  /// the same day).
  Future<bool> send(String to, InboxItem item);
  Stream<List<InboxItem>> inbox(String uid);
  Future<void> removeFromInbox(String uid, String id);

  // Cloud save, for linked Pro members.

  Future<CloudBackup?> readBackup(String uid);
  Future<void> writeBackup(String uid, CloudBackup backup);
}
