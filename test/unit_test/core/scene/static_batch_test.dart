import 'package:flutter_scene/scene.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/scene/static_batch.dart';
import 'package:vector_math/vector_math.dart' as vm;

void main() {
  group('findMoving', () {
    test('finds what an animation moves, hides or swaps, and nothing else', () {
      final still = Node(name: 'still');
      final swaying = Node(name: 'swaying');
      final leaf = Node(name: 'leaf');
      final blinking = Node(name: 'blinking');
      final root = Node()
        ..add(still)
        ..add(swaying..add(leaf))
        ..add(blinking);

      final moving = findMoving(root, (step) {
        swaying.rotation =
            vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), step * 0.1);
        blinking.visible = step.isEven;
      });

      expect(moving, {swaying, blinking});
    });

    test('catches a move on any step, and nothing when nothing moves', () {
      final bobbing = Node(name: 'bobbing');
      final root = Node()..add(bobbing);

      final moving = findMoving(root, (step) {
        bobbing.position = vm.Vector3(0, step.isEven ? 0 : 0.2, 0);
      });

      // It moved on the odd steps.
      expect(moving, {bobbing});
      expect(findMoving(root, (_) {}), isEmpty);
    });
  });
}
