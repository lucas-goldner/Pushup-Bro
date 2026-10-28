import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pushup_bro/core/scene/gorilla_rig.dart';
import 'package:pushup_bro/features/pushup_tracking/camera/camera_window.dart';
import 'package:vector_math/vector_math.dart' as vm;

void main() {
  const window = Key('window');

  Future<void> pump(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(400, 800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: Stack(
          children: [
            Positioned.fill(
              child: CameraWindow(
                child: SizedBox.expand(key: window),
              ),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('starts in its corner and reports where it is', (tester) async {
    await pump(tester);

    expect(tester.getTopLeft(find.byKey(window)), const Offset(264, 624));
    expect(CameraWindow.focus.value, const Offset(324 / 400, 704 / 800));
  });

  testWidgets('snaps to the nearest corner after a drag', (tester) async {
    await pump(tester);

    await tester.drag(find.byKey(window), const Offset(-200, -500));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.byKey(window)), const Offset(16, 16));
    expect(CameraWindow.focus.value, const Offset(76 / 400, 96 / 800));
  });

  testWidgets('forgets the spot once closed', (tester) async {
    await pump(tester);
    await tester.pumpWidget(const SizedBox());

    expect(CameraWindow.focus.value, isNull);
    expect(GorillaRig.lookTarget, isNull);
  });

  test('aims the gorillas towards the window', () {
    final camera = PerspectiveCamera(
      position: vm.Vector3(0, 0, 5),
      target: vm.Vector3.zero(),
    );

    CameraWindow.focus.value = const Offset(0.5, 0.5);
    aimGorillasAtCameraWindow(camera, const Size(400, 800));
    final ahead = GorillaRig.lookTarget!;
    expect(ahead.x, closeTo(0, 1e-6));
    expect(ahead.z, closeTo(3.5, 1e-6));

    CameraWindow.focus.value = const Offset(1, 0);
    aimGorillasAtCameraWindow(camera, const Size(400, 800));
    final corner = GorillaRig.lookTarget!;
    expect(corner.x, greaterThan(0));
    expect(corner.y, greaterThan(0));

    CameraWindow.focus.value = null;
    aimGorillasAtCameraWindow(camera, const Size(400, 800));
    expect(GorillaRig.lookTarget, isNull);
  });
}
