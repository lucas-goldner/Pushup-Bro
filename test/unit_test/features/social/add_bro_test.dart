import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/features/social/cubit/bros_cubit.dart';
import 'package:pushup_bro/features/social/data/fake_social_backend.dart';
import 'package:pushup_bro/features/social/domain/add_bro.dart';
import 'package:pushup_bro/features/social/domain/bro_name.dart';
import 'package:pushup_bro/features/social/model/bro_profile.dart';

void main() {
  late FakeSocialBackend backend;
  const me = BroProfile(uid: 'me', broName: BroName(0, 0, 1), code: 'AAAAAA');
  const mia = BroProfile(uid: 'mia', broName: BroName(1, 1, 1), code: 'MAZ9QK');

  setUp(() {
    backend = FakeSocialBackend()
      ..profiles['me'] = me
      ..profiles['mia'] = mia
      ..codes['AAAAAA'] = 'me'
      ..codes['MAZ9QK'] = 'mia'
      ..friendNames['mia'] = 'Mia';
  });

  Future<CodeLookup> look(String input, {List<String> friends = const []}) =>
      lookUpCode(backend, me: me, friends: friends, input: input);

  test('waits for all six letters', () async {
    expect(await look('MAZ9'), isA<CodeIncomplete>());
  });

  test('finds a bro by code, in any case, with or without the dash', () async {
    final found = await look('maz-9qk') as CodeFound;
    expect(found.profile.uid, 'mia');
    expect(found.name, 'Mia');
  });

  test("says when the code is the player's own", () async {
    expect(await look('AAAAAA'), isA<CodeIsMine>());
  });

  test('says when nobody has the code', () async {
    expect(await look('ZZZZZZ'), isA<CodeUnknown>());
  });

  test('says when they are bros already', () async {
    expect(await look('MAZ9QK', friends: ['mia']), isA<CodeAlreadyBros>());
  });

  test('stops at 100 bros', () async {
    final friends = [for (var i = 0; i < kMaxBros; i++) 'bro$i'];
    expect(await look('MAZ9QK', friends: friends), isA<CodeTooManyBros>());
  });

  test('adding makes both of them bros', () async {
    await addBro(backend, me: me, friend: mia);
    expect(backend.friendEdges['me'], {'mia'});
    expect(backend.friendEdges['mia'], {'me'});
  });
}
