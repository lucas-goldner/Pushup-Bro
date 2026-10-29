import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/provider/shared_preferences_provider.dart';
import 'package:pushup_bro/features/social/data/fake_social_backend.dart';
import 'package:pushup_bro/features/social/domain/inbox_bananas.dart';
import 'package:pushup_bro/features/social/model/inbox_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('bananas from friends stop at 5 a day', () async {
    final prefs = SharedPreferencesProvider();
    final today = DateTime(2026, 10, 29, 9);
    final claimed = [
      for (var i = 0; i < 7; i++) await takeInboxBanana(prefs, now: today),
    ];
    expect(claimed.where((ok) => ok).length, kInboxBananasPerDay);
  });

  test('the count starts over the next day', () async {
    final prefs = SharedPreferencesProvider();
    for (var i = 0; i < 5; i++) {
      await takeInboxBanana(prefs, now: DateTime(2026, 10, 29, 9));
    }
    expect(
      await takeInboxBanana(prefs, now: DateTime(2026, 10, 30, 0, 5)),
      isTrue,
    );
  });

  test('one nudge per friend and day', () async {
    final backend = FakeSocialBackend();
    InboxItem nudge(DateTime at) => InboxItem.create(
          kind: InboxKind.nudge,
          fromUid: 'mia',
          fromName: 'Mia',
          now: at,
        );
    expect(await backend.send('me', nudge(DateTime(2026, 10, 29, 9))), isTrue);
    expect(
      await backend.send('me', nudge(DateTime(2026, 10, 29, 20))),
      isFalse,
    );
    expect(await backend.send('me', nudge(DateTime(2026, 10, 30, 9))), isTrue);
  });

  test('waves and bananas can come more than once', () async {
    final backend = FakeSocialBackend();
    for (final minute in [1, 2]) {
      expect(
        await backend.send(
          'me',
          InboxItem.create(
            kind: InboxKind.wave,
            fromUid: 'mia',
            fromName: 'Mia',
            now: DateTime(2026, 10, 29, 9, minute),
          ),
        ),
        isTrue,
      );
    }
  });
}
