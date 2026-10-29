import 'package:pushup_bro/features/social/cubit/bros_cubit.dart';
import 'package:pushup_bro/features/social/data/social_backend.dart';
import 'package:pushup_bro/features/social/domain/friend_code.dart';
import 'package:pushup_bro/features/social/model/bro_profile.dart';

/// What a typed or scanned code turned out to be.
sealed class CodeLookup {
  const CodeLookup();
}

/// Not six letters and digits yet.
class CodeIncomplete extends CodeLookup {
  const CodeIncomplete();
}

class CodeFound extends CodeLookup {
  const CodeFound(this.profile, this.name);

  final BroProfile profile;

  /// Their name for friends, if they set one.
  final String name;
}

class CodeIsMine extends CodeLookup {
  const CodeIsMine();
}

class CodeUnknown extends CodeLookup {
  const CodeUnknown();
}

class CodeAlreadyBros extends CodeLookup {
  const CodeAlreadyBros(this.profile);

  final BroProfile profile;
}

/// The player has [kMaxBros] already.
class CodeTooManyBros extends CodeLookup {
  const CodeTooManyBros();
}

/// Looks up [input] (a code, with or without the dash, or a scanned link)
/// for [me], who has [friends].
Future<CodeLookup> lookUpCode(
  SocialBackend backend, {
  required BroProfile me,
  required List<String> friends,
  required String input,
}) async {
  final code = FriendCode.normalize(input);
  if (!FriendCode.isValid(code)) return const CodeIncomplete();
  if (code == me.code) return const CodeIsMine();
  final uid = await backend.uidForCode(code);
  if (uid == null) return const CodeUnknown();
  if (uid == me.uid) return const CodeIsMine();
  final profile = await backend.profile(uid);
  if (profile == null) return const CodeUnknown();
  if (friends.contains(uid)) return CodeAlreadyBros(profile);
  if (friends.length >= kMaxBros) return const CodeTooManyBros();
  return CodeFound(profile, await backend.friendName(uid) ?? '');
}

/// Makes [me] and [friend] bros.
Future<void> addBro(
  SocialBackend backend, {
  required BroProfile me,
  required BroProfile friend,
}) =>
    backend.addFriend(me: me.uid, friend: friend.uid, code: friend.code);
