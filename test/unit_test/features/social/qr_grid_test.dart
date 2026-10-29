import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/features/social/domain/friend_code.dart';
import 'package:pushup_bro/features/social/widgets/qr_view.dart';

void main() {
  final grid = QrGrid(FriendCode.link('4K2B7Q'), hole: 9);

  test('a friend link fits a 37 × 37 code', () {
    expect(grid.count, 37);
  });

  test('the logo hole stays well inside error correction H (30%)', () {
    expect(grid.holeShare, lessThan(0.3));
    expect(grid.holeShare, closeTo(81 / 1369, 1e-9));
  });

  test('the hole sits in the middle and keeps clear of the finders', () {
    expect(grid.inHole(18, 18), isTrue);
    expect(grid.inHole(14, 14), isTrue);
    expect(grid.inHole(13, 18), isFalse);
    for (var row = 0; row < grid.count; row++) {
      for (var col = 0; col < grid.count; col++) {
        expect(grid.inHole(row, col) && grid.isFinder(row, col), isFalse);
      }
    }
  });

  test('finds the three finder squares', () {
    expect(grid.isFinder(0, 0), isTrue);
    expect(grid.isFinder(6, 36), isTrue);
    expect(grid.isFinder(36, 0), isTrue);
    expect(grid.isFinder(36, 36), isFalse);
    // A finder's ring is dark, the gap inside it light.
    expect(grid.isDark(0, 0), isTrue);
    expect(grid.isDark(1, 1), isFalse);
    expect(grid.isDark(3, 3), isTrue);
  });
}
