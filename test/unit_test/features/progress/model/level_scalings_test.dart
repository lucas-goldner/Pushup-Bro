import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/features/progress/model/level_scalings.dart';

void main() {
  final levelScaler = LevelScaler();

  group('LevelScaler', () {
    test('getLevelScaling returns correct values', () {
      expect(levelScaler.getLevelScaling(1), 40);
      expect(levelScaler.getLevelScaling(2), 60);
      expect(levelScaler.getLevelScaling(3), 80);
      expect(levelScaler.getLevelScaling(4), 120);
      expect(levelScaler.getLevelScaling(5), 160);
      expect(levelScaler.getLevelScaling(30), 1800);
      expect(levelScaler.getLevelScaling(50), 11800);
    });

    test('getLevelScaling returns 0 for undefined levels', () {
      expect(levelScaler.getLevelScaling(0), 0);
      expect(levelScaler.getLevelScaling(61), 0);
      expect(levelScaler.getLevelScaling(-1), 0);
    });

    test('getCurrentExperienceRelativeToLevel => correct ratio for single lvl',
        () {
      expect(
        levelScaler.getCurrentExperienceRelativeToLevel(1, 1, 20),
        closeTo(0.5, 0.0001),
      ); // 20/40 = 0.5
      expect(
        levelScaler.getCurrentExperienceRelativeToLevel(2, 2, 30),
        closeTo(0.5, 0.0001),
      ); // 30/60 = 0.5
      expect(
        levelScaler.getCurrentExperienceRelativeToLevel(3, 3, 40),
        closeTo(0.5, 0.0001),
      ); // 40/80 = 0.5
      expect(
        levelScaler.getCurrentExperienceRelativeToLevel(4, 4, 60),
        closeTo(0.5, 0.0001),
      ); // 60/120 = 0.5
      expect(
        levelScaler.getCurrentExperienceRelativeToLevel(5, 5, 80),
        closeTo(0.5, 0.0001),
      ); // 80/160 = 0.5
    });

    test(
        'getCurrentExperienceRelativeToLevel => correct ratio for multiple lvl',
        () {
      expect(
        levelScaler.getCurrentExperienceRelativeToLevel(1, 3, 180),
        closeTo(
          180 / (40 + 60 + 80),
          0.0001,
        ),
      ); // 180 / (40+60+80) = 180 / 180 = 1.0
      expect(
        levelScaler.getCurrentExperienceRelativeToLevel(2, 4, 240),
        closeTo(
          240 / (60 + 80 + 120),
          0.0001,
        ),
      ); // 240 / (60+80+120) = 240 / 260 = 0.9231
      expect(
        levelScaler.getCurrentExperienceRelativeToLevel(3, 5, 260),
        closeTo(
          260 / (80 + 120 + 160),
          0.0001,
        ),
      ); // 260 / (80+120+160) = 260 / 360 = 0.7222
    });

    test('getCurrentExperienceRelativeToLevel => progress for multiple lvl',
        () {
      expect(
        levelScaler.getCurrentExperienceRelativeToLevel(1, 3, 100),
        closeTo(
          100 / (40 + 60 + 80),
          0.0001,
        ),
      ); // 100 / (40+60+80) = 100 / 180 = 0.5556
      expect(
        levelScaler.getCurrentExperienceRelativeToLevel(2, 4, 150),
        closeTo(
          150 / (60 + 80 + 120),
          0.0001,
        ),
      ); // 150 / (60+80+120) = 150 / 260 = 0.5769
      expect(
        levelScaler.getCurrentExperienceRelativeToLevel(3, 5, 200),
        closeTo(
          200 / (80 + 120 + 160),
          0.0001,
        ),
      ); // 200 / (80+120+160) = 200 / 360 = 0.5556
    });

    test('getCurrentExperienceRelativeToLevel => correct ratio for edge cases',
        () {
      expect(levelScaler.getCurrentExperienceRelativeToLevel(1, 1, 0), 0.0);
      expect(levelScaler.getCurrentExperienceRelativeToLevel(1, 1, 40), 1.0);
      expect(levelScaler.getCurrentExperienceRelativeToLevel(2, 2, 60), 1.0);
      expect(levelScaler.getCurrentExperienceRelativeToLevel(3, 3, 80), 1.0);
      expect(levelScaler.getCurrentExperienceRelativeToLevel(4, 4, 120), 1.0);
      expect(levelScaler.getCurrentExperienceRelativeToLevel(5, 5, 160), 1.0);
    });
  });
}
