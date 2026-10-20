import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:vector_math/vector_math.dart' as vm;

void main() {
  group('solveTwoBone', () {
    test('keeps both bones at their lengths and reaches the target', () {
      final root = vm.Vector3(0, 1, 0);
      final target = vm.Vector3(0, 0, 0.3);

      final (middle, end) =
          solveTwoBone(root, target, 0.6, 0.5, vm.Vector3(0, 0, -1));

      expect((middle - root).length, closeTo(0.6, 1e-6));
      expect((end - middle).length, closeTo(0.5, 1e-6));
      expect((end - target).length, closeTo(0, 1e-6));
    });

    test('bends towards the pole', () {
      final (middle, _) = solveTwoBone(
        vm.Vector3.zero(),
        vm.Vector3(0, -0.8, 0),
        0.5,
        0.5,
        vm.Vector3(0, 0, 1),
      );

      expect(middle.z, greaterThan(0));
    });

    test('pulls an out-of-reach target in along the same direction', () {
      final (_, end) = solveTwoBone(
        vm.Vector3.zero(),
        vm.Vector3(0, -5, 0),
        0.5,
        0.5,
        vm.Vector3(0, 0, 1),
      );

      expect(end.y, closeTo(-1, 1e-2));
      expect(end.x, closeTo(0, 1e-6));
    });
  });

  test('springTo settles on the target and never overshoots', () {
    var value = 0.0;
    for (var i = 0; i < 120; i++) {
      value = springTo(value, 1, 1 / 60, 8);
      expect(value, lessThanOrEqualTo(1));
    }
    expect(value, closeTo(1, 1e-3));
  });

  test('linearColor converts sRGB to linear', () {
    final color = linearColor(const Color(0xFF808080));

    expect(color.x, closeTo(0.2159, 1e-3));
    expect(color.w, 1);
  });
}
