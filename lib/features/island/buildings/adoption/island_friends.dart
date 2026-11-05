import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/scene/gorilla_rig.dart';
import 'package:pushup_bro/core/scene/nature_kit.dart' show yaw;
import 'package:pushup_bro/core/scene/scene_kit.dart' show springTo;
import 'package:pushup_bro/features/island/buildings/adoption/adoption.dart';
import 'package:pushup_bro/features/island/scene/island_world.dart'
    show grassTop;
import 'package:vector_math/vector_math.dart' as vm;

/// Where each friend hangs out, as fractions of the grass radius (x, z):
/// on the lawn either side of Carlos's laps and in front of them, clear
/// of the building slots.
const _spots = [(-0.3, 0.1), (0.3, 0.12), (-0.13, 0.56), (0.15, 0.6)];

/// How far (fraction of the grass radius) a friend strolls from its spot.
const _stroll = 0.07;

/// One round of a friend's day: a stroll, then a rest.
const _roundSeconds = 13.0;
const _walkSeconds = 6.0;

/// The adopted monkeys on the island: each strolls around its own spot on
/// the lawn, rests facing the camera and now and then dances.
///
/// They are the most expensive things on the island to draw, so there are
/// never more than [Adoption.maxExtras] and rigs are reused when the looks
/// change. Build it once the engine is ready, add [root] to the island's
/// root and call [update] every frame.
class IslandFriends {
  final Node root = Node(name: 'island-friends');
  final List<_Friend> _friends = [];
  double _time = 0;

  /// Who lives on the island besides Carlos.
  List<MonkeyLook> get looks => [
        for (final friend in _friends)
          if (friend.rig.root.visible) friend.rig.look,
      ];
  set looks(List<MonkeyLook> value) {
    final shown = value.take(Adoption.maxExtras).toList();
    for (final (i, look) in shown.indexed) {
      if (i == _friends.length) {
        final friend = _Friend(
          GorillaRig(look: look, timeOffset: i * 1.3 + 0.4),
          index: i,
        );
        _friends.add(friend);
        root.add(friend.rig.root..scale = vm.Vector3.all(0.82));
      }
      _friends[i].rig
        ..look = look
        ..root.visible = true;
    }
    // Kept for later instead of rebuilt: a rig is costly to make.
    for (final friend in _friends.skip(shown.length)) {
      friend.rig.root.visible = false;
    }
  }

  /// Moves everyone on; [radius] is the island's grass radius.
  void update(double deltaSeconds, {required double radius}) {
    _time += deltaSeconds;
    for (final friend in _friends) {
      if (friend.rig.root.visible) friend.update(_time, deltaSeconds, radius);
    }
  }
}

class _Friend {
  _Friend(this.rig, {required this.index})
      : _lap = index * 1.9,
        _direction = index.isEven ? 1 : -1 {
    rig
      ..activity = GorillaActivity.idle
      ..settle();
  }

  final GorillaRig rig;
  final int index;
  double _lap;
  final int _direction;
  double _heading = 0;

  void update(double time, double deltaSeconds, double radius) {
    // Everyone keeps their own rhythm, out of step with the others.
    final clock = time + index * 3.3;
    final round = (clock / _roundSeconds).floor();
    final walking = clock % _roundSeconds < _walkSeconds;
    final double target;
    if (walking) {
      _lap += deltaSeconds * 0.55 * _direction;
      rig
        ..activity = GorillaActivity.walking
        ..walkSpeed = 1;
      // Along the circle: its tangent.
      target = math.atan2(
        -math.sin(_lap) * _direction,
        math.cos(_lap) * _direction,
      );
    } else {
      // Every third rest is a little dance.
      rig.activity = (round + index) % 3 == 0
          ? GorillaActivity.dance
          : GorillaActivity.idle;
      target = 0;
    }
    _heading = _turnTowards(target, deltaSeconds);
    final (x, z) = _spots[index % _spots.length];
    final reach = radius * _stroll;
    rig.root
      ..position = vm.Vector3(
        x * radius + math.cos(_lap) * reach,
        grassTop,
        z * radius + math.sin(_lap) * reach,
      )
      ..rotation = yaw(_heading);
    rig.update(deltaSeconds);
  }

  double _turnTowards(double target, double deltaSeconds) {
    var delta = (target - _heading) % (math.pi * 2);
    if (delta > math.pi) delta -= math.pi * 2;

    return springTo(_heading, _heading + delta, deltaSeconds, 6);
  }
}
