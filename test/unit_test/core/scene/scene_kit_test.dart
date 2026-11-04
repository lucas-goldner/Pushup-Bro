import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_scene/scene.dart';
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

  group('fitShadowCascades', () {
    final camera = PerspectiveCamera(
      fovRadiansY: 0.6,
      position: vm.Vector3(1, 3, 9),
      target: vm.Vector3(0, 0.5, 0),
    );
    final direction = vm.Vector3(-0.4, -1, -0.3);
    DirectionalLight light() =>
        DirectionalLight(direction: direction, castsShadow: true);

    void expectSameCascades(double visibleDepth, int kept) {
      final before = light().computeCascades(camera, 0.46);
      final fitted = fitShadowCascades(light(), visibleDepth: visibleDepth);
      final after = fitted.computeCascades(camera, 0.46);

      expect(after, hasLength(kept));
      for (var i = 0; i < kept; i++) {
        expect(after[i].splitDistance, closeTo(before[i].splitDistance, 1e-6));
        expect(after[i].radius, closeTo(before[i].radius, 1e-6));
        expect((after[i].center! - before[i].center!).length, lessThan(1e-6));
        final a = after[i].lightSpaceMatrix.storage;
        final b = before[i].lightSpaceMatrix.storage;
        for (var j = 0; j < 16; j++) {
          expect(a[j], closeTo(b[j], 1e-6));
        }
      }
      // Shadows only fade out where nothing shows.
      final end = after.last.splitDistance;
      final fade = math.max(fitted.shadowFadeRange, end * 0.1);
      expect(end - fade, greaterThanOrEqualTo(visibleDepth));
    }

    test('keeps the near cascades exactly where they were', () {
      expectSameCascades(8, 1);
      expectSameCascades(20, 2);
      expectSameCascades(29, 2);
      expectSameCascades(30, 3);
      expectSameCascades(53, 3);
    });

    test('keeps all four when the view reaches far', () {
      final fitted = fitShadowCascades(light(), visibleDepth: 70);

      expect(fitted.shadowCascadeCount, 4);
      expect(fitted.shadowMaxDistance, 150);
      expect(fitted.firstCascadeFarBound, isNull);
    });
  });
}
