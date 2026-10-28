import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter_scene/scene.dart';
import 'package:pushup_bro/core/model/monkey_look.dart';
import 'package:pushup_bro/core/scene/gorilla_rig.dart';
import 'package:pushup_bro/core/scene/reptiles.dart';
import 'package:pushup_bro/core/scene/scene_kit.dart';
import 'package:pushup_bro/features/jungle/model/jungle_quest.dart';
import 'package:pushup_bro/features/quest/scene/location_world.dart';
import 'package:pushup_bro/features/trek/model/battle.dart';
import 'package:pushup_bro/features/trek/model/trek.dart';
import 'package:vector_math/vector_math.dart' as vm;

/// A shot flying from Carlos to an enemy, and the burst when it lands.
class _Shot {
  _Shot(this.node, this.from, this.foe);

  final Node node;
  final vm.Vector3 from;
  final Foe foe;
  double t = 0;
  void Function()? onLand;
}

class _Spark {
  _Spark(this.node, this.velocity);

  final Node node;
  final vm.Vector3 velocity;
  double life = 1;
}

/// The 3D side of a Jungle Trek stage: the place, Carlos on his mat facing
/// the reptiles (towards -Z), Coco cheering beside him, and the effects of
/// every pushup landing.
class TrekWorld {
  TrekWorld(this.stage, {required MonkeyLook look})
      : location = LocationWorld(
          stage.location,
          look: look,
          guest: Character.coco,
        ) {
    location.stageBattle();
    root
      ..add(location.root)
      ..add(_fx);
  }

  final TrekStage stage;
  final LocationWorld location;
  final Node root = Node(name: 'trek');
  final Node _fx = Node(name: 'fx');
  final Map<Foe, Reptile> _actors = {};
  final Map<Reptile, double> _entering = {};
  final List<_Shot> _shots = [];
  final List<_Spark> _sparks = [];
  final _random = math.Random(1);
  double _time = 0;
  bool _tracking = false;

  /// Where an enemy in [slot] of a wave of [count] stands.
  vm.Vector3 _slot(int slot, int count) {
    final spread = count == 1
        ? 0.0
        : count == 2
            ? 0.75
            : 1.1;
    final x = count == 1 ? 0.0 : -spread + slot * (2 * spread / (count - 1));

    return vm.Vector3(x, location.enemyFloor, -2.3 - (slot.isOdd ? 0.35 : 0));
  }

  /// Brings on the [foes] of a new wave, marching in from the back.
  void spawn(List<Foe> foes) {
    for (final actor in _actors.values) {
      location.root.remove(actor.root);
    }
    _actors.clear();
    for (final foe in foes) {
      final actor = switch (foe.spec.species) {
        Species.gecko => Gecko(foe.color.color),
        Species.skink => Gecko(foe.color.color, skinny: true),
        Species.iguana => Iguana(foe.color.color),
        Species.croc => Croc(foe.color.color),
        Species.chameleon => Chameleon(foe.color.color),
        Species.snake => Snake(foe.color.color),
        Species.king => KingKomo(),
      };
      // Bigger than life, so they read as a threat next to Carlos.
      actor.root.scale = vm.Vector3.all(_sizeOf(foe.spec.species));
      _actors[foe] = actor;
      _entering[actor] = 0;
      actor.root.position = _slot(foe.slot, foes.length) + vm.Vector3(0, 0, -6);
      location.root.add(actor.root);
    }
    // The King gets a mat for the duel.
    if (foes.any((foe) => foe.spec.species == Species.king)) {
      location.root.add(
        meshNode(
          CylinderGeometry(radialSegments: 48),
          matte(const Color(0xFF2F8443), roughness: 0.7),
        )
          ..scale = vm.Vector3(1, 0.022, 1.8)
          ..position = vm.Vector3(0, 0.011, -2.4),
      );
    }
  }

  /// The actor playing [foe].
  Reptile? actorFor(Foe foe) => _actors[foe];

  static double _sizeOf(Species species) => switch (species) {
        Species.gecko || Species.skink => 1.9,
        Species.iguana => 1.6,
        Species.croc => 1.5,
        Species.chameleon => 1.3,
        Species.snake => 1.2,
        Species.king => 1,
      };

  double _heightOf(Reptile actor) => actor.height * actor.root.scale.y;

  /// Where to hang [foe]'s health bar, in world space.
  vm.Vector3 barAnchor(Foe foe) {
    final actor = _actors[foe];
    if (actor == null) return vm.Vector3.zero();

    return actor.root.position + vm.Vector3(0, _heightOf(actor) * 0.7, 0);
  }

  /// Carlos does pushups while the battle is on; Coco cheers, and the King
  /// does them right back at him.
  set tracking(bool value) {
    _tracking = value;
    location.tracking = value;
    for (final actor in _actors.values) {
      if (actor is KingKomo) {
        actor.rig.activity =
            value ? GorillaActivity.pushups : GorillaActivity.idle;
      }
    }
  }

  bool get tracking => _tracking;

  set inPushup(bool value) {
    location.inPushup = value;
    for (final actor in _actors.values) {
      if (actor is KingKomo) actor.rig.inPushup = value;
    }
  }

  bool get inPushup => location.inPushup;

  /// A colour change after a chameleon shifts or the King's phase turns.
  void recolor(Foe foe) => _actors[foe]?.color = foe.color.color;

  /// Fires a shot coloured by [hit]'s kind at its enemy; [onLand] runs as
  /// it lands.
  void fire(Hit hit, {void Function()? onLand}) {
    final actor = _actors[hit.foe];
    if (actor == null) return;
    final color = hit.kind.color;
    final shot = Node(name: 'shot')
      ..add(
        meshNode(
          IcosphereGeometry(radius: 0.12),
          UnlitMaterial()..baseColorFactor = linearColor(color),
        ),
      )
      ..add(
        meshNode(
          IcosphereGeometry(radius: 0.2),
          UnlitMaterial()
            ..baseColorFactor = linearColor(
              Color.lerp(color, const Color(0xFFFFFFFF), 0.6)!,
            ),
        )..scale = vm.Vector3.all(0.6),
      );
    _fx.add(shot);
    _shots.add(
      _Shot(
        shot,
        location.carlos.root.position + vm.Vector3(0, 0.45, -0.5),
        hit.foe,
      )..onLand = () {
          actor.hit();
          if (hit.defeated) actor.defeat();
          _burst(
            actor.root.position + vm.Vector3(0, _heightOf(actor) * 0.5, 0),
            color,
            hit.superEffective ? 14 : 8,
          );
          onLand?.call();
        },
    );
  }

  /// An enemy attacks Carlos.
  void strike(Foe foe) {
    _actors[foe]?.lunge();
    _burst(
      location.carlos.root.position + vm.Vector3(0, 0.5, 0),
      const Color(0xFFE5534B),
      6,
    );
  }

  void _burst(vm.Vector3 at, Color color, int count) {
    final material = UnlitMaterial()..baseColorFactor = linearColor(color);
    for (var i = 0; i < count; i++) {
      final node = meshNode(
        IcosphereGeometry(radius: 0.05, subdivisions: 0),
        material,
        position: at.clone(),
      );
      _fx.add(node);
      final a = _random.nextDouble() * math.pi * 2;
      _sparks.add(
        _Spark(
          node,
          vm.Vector3(
            math.cos(a) * (1 + _random.nextDouble()),
            1 + _random.nextDouble() * 2,
            math.sin(a) * (1 + _random.nextDouble()),
          ),
        ),
      );
    }
  }

  void update(double deltaSeconds) {
    _time += deltaSeconds;
    location.update(deltaSeconds);
    for (final MapEntry(key: foe, value: actor) in _actors.entries) {
      // March in, then idle in place.
      final entering = _entering[actor];
      final home = _slot(foe.slot, _actors.length);
      if (entering != null && entering < 1) {
        final t = math.min(1, entering + deltaSeconds / 1.2).toDouble();
        _entering[actor] = t;
        final eased = 1 - (1 - t) * (1 - t);
        actor.root.position = home + vm.Vector3(0, 0, -6 * (1 - eased));
      } else {
        actor.root.position = vm.Vector3(home.x, home.y, home.z);
      }
      // Face Carlos.
      final toCarlos = location.carlos.root.position - actor.root.position
        ..y = 0;
      if (toCarlos.length2 > 1e-4) {
        actor.root.rotation = vm.Quaternion.fromTwoVectors(
          vm.Vector3(0, 0, 1),
          toCarlos..normalize(),
        );
      }
      actor.update(deltaSeconds);
    }
    for (final shot in [..._shots]) {
      shot.t = math.min(1, shot.t + deltaSeconds / 0.32);
      final actor = _actors[shot.foe];
      final to = actor == null
          ? shot.from
          : actor.root.position + vm.Vector3(0, _heightOf(actor) * 0.5, 0);
      final arc = math.sin(shot.t * math.pi) * 0.5;
      shot.node
        ..position =
            shot.from + (to - shot.from) * shot.t + vm.Vector3(0, arc, 0)
        ..scale = vm.Vector3.all(1 + math.sin(_time * 30) * 0.15);
      if (shot.t >= 1) {
        _shots.remove(shot);
        _fx.remove(shot.node);
        shot.onLand?.call();
      }
    }
    for (final spark in [..._sparks]) {
      spark.life -= deltaSeconds * 1.6;
      spark.velocity.y -= 6 * deltaSeconds;
      spark.node
        ..position = spark.node.position + spark.velocity * deltaSeconds
        ..scale = vm.Vector3.all(math.max(0.01, spark.life));
      if (spark.life <= 0) {
        _sparks.remove(spark);
        _fx.remove(spark.node);
      }
    }
  }
}
