part of 'location_world.dart';

/// A bird or bat in flight: its body and the two wings that flap.
typedef _Flyer = ({Node node, Node left, Node right});

/// The world around each location: scenery all the way round, so every
/// camera angle in a cutscene has something behind the actors, and things
/// that live there (birds, fish, crabs, smoke) going about their day.
extension _LocationLife on LocationWorld {
  void _enliven(Node scene) => switch (location) {
        ChallengeLocation.volcano => _volcanoLife(scene),
        ChallengeLocation.moonBeach => _moonBeachLife(scene),
        ChallengeLocation.temple => _templeLife(scene),
        ChallengeLocation.skyIsland => _skyIslandLife(scene),
        ChallengeLocation.fernTrail => _fernTrailLife(scene),
        ChallengeLocation.canopy => _canopyLife(scene),
        ChallengeLocation.swamp => _swampLife(scene),
        ChallengeLocation.lake => _lakeLife(scene),
        ChallengeLocation.gorge => _gorgeLife(scene),
        ChallengeLocation.throne => _throneLife(scene),
      };

  /// [count] things from [build] spread all the way round, between [near]
  /// and [far] from the middle, each turned to face it.
  void _around(
    Node parent,
    math.Random random, {
    required int count,
    required double near,
    required double far,
    required Node Function(int i) build,
    double offset = 0,
    double y = 0,
  }) {
    for (var i = 0; i < count; i++) {
      final a = offset + (i + random.nextDouble() * 0.6) / count * math.pi * 2;
      final r = near + random.nextDouble() * (far - near);
      parent.add(
        build(i)
          ..position = vm.Vector3(math.cos(a) * r, y, math.sin(a) * r)
          ..rotation = yaw(-a - math.pi / 2),
      );
    }
  }

  /// A bird (or a bat) with its beak along +Z, about [size] across.
  _Flyer _flyer(Color body, Color wings, {double size = 1}) {
    final wingMaterial = matte(wings, roughness: 0.7)..doubleSided = true;
    Node wing(double side) => Node()
      ..add(
        meshNode(
          reshaped(
            CuboidGeometry(vm.Vector3.all(1)),
            vm.Vector3(0.32 * size, 0.015 * size, 0.14 * size),
          ),
          wingMaterial,
          position: vm.Vector3(side * 0.16 * size, 0, 0),
        ),
      );
    final left = wing(-1);
    final right = wing(1);
    final node = Node(name: 'flyer')
      ..add(
        meshNode(
          reshaped(
            SphereGeometry(radius: 0.06 * size, segments: 10, rings: 8),
            vm.Vector3(0.9, 0.8, 1.9),
          ),
          matte(body, roughness: 0.7),
        ),
      )
      ..add(left)
      ..add(right);

    return (node: node, left: left, right: right);
  }

  /// [count] flyers circling [center] at [radius], bobbing and flapping.
  void _flock(
    Node parent, {
    required int count,
    required vm.Vector3 center,
    required double radius,
    required Color body,
    required Color wings,
    double size = 1,
    double speed = 0.35,
    double flap = 11,
  }) {
    for (var i = 0; i < count; i++) {
      final bird = _flyer(body, wings, size: size);
      final phase = i / count * math.pi * 2 + _random.nextDouble() * 0.5;
      final orbit = radius * (0.75 + _random.nextDouble() * 0.5);
      final lift = _random.nextDouble() * 1.2;
      final direction = i.isEven ? 1.0 : -1.0;
      parent.add(bird.node);
      _animations.add((time, _) {
        final a = time * speed * direction * (6 / orbit) + phase;
        bird.node
          ..position = center +
              vm.Vector3(
                math.cos(a) * orbit,
                lift + math.sin(time * 0.9 + phase) * 0.35,
                math.sin(a) * orbit,
              )
          ..rotation = vm.Quaternion.fromTwoVectors(
            vm.Vector3(0, 0, 1),
            vm.Vector3(-math.sin(a), 0, math.cos(a)) * direction,
          );
        // Flap, then glide a little.
        final beat = math.sin(time * flap + phase * 3);
        final angle =
            0.15 + (math.sin(time * 0.7 + phase) > -0.3 ? beat : 0.2) * 0.6;
        bird.left.rotation =
            vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), -angle);
        bird.right.rotation =
            vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), angle);
      });
    }
  }

  /// Butterflies fluttering around [homes].
  void _butterflies(Node parent, List<vm.Vector3> homes) {
    for (final (i, home) in homes.indexed) {
      final material = matte(
        flowerColors[(i * 3 + 1) % flowerColors.length],
        roughness: 0.5,
      )..doubleSided = true;
      Node wing(double side) => Node()
        ..add(
          meshNode(
            reshaped(
              DiscGeometry(radius: 0.06, segments: 12),
              vm.Vector3(1, 1, 0.7),
            ),
            material,
            position: vm.Vector3(side * 0.055, 0, 0),
          ),
        );
      final left = wing(-1);
      final right = wing(1);
      final node = Node(name: 'butterfly')
        ..add(left)
        ..add(right);
      parent.add(node);
      _animations.add((time, _) {
        final t = time * 0.8 + i * 2.4;
        node.position = home +
            vm.Vector3(
              math.sin(t) * 0.6,
              math.sin(t * 1.7) * 0.2,
              math.cos(t * 0.7) * 0.5,
            );
        final flap = 0.25 + math.sin(time * 18 + i) * 0.9;
        left.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), flap);
        right.rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), -flap);
      });
    }
  }

  /// Leaves drifting down from [height] over a [spread] wide area.
  void _fallingLeaves(
    Node parent, {
    required int count,
    required double height,
    required double spread,
    List<Color> colors = leafGreens,
  }) {
    for (var i = 0; i < count; i++) {
      final leaf = meshNode(
        reshaped(
          DiscGeometry(radius: 0.06, segments: 8),
          vm.Vector3(1, 1, 0.55),
        ),
        matte(colors[i % colors.length], roughness: 0.8)..doubleSided = true,
      );
      final start = vm.Vector3(
        (_random.nextDouble() - 0.5) * spread,
        height,
        (_random.nextDouble() - 0.5) * spread - 1,
      );
      final phase = _random.nextDouble();
      final speed = 0.25 + _random.nextDouble() * 0.2;
      parent.add(leaf);
      _animations.add((time, _) {
        final t = (time * speed / height + phase) % 1;
        leaf
          ..position = start +
              vm.Vector3(
                math.sin(time * 1.6 + phase * 9) * 0.5,
                -t * height,
                math.cos(time * 1.1 + phase * 5) * 0.3,
              )
          ..rotation = vm.Quaternion.axisAngle(
            vm.Vector3(1, 0.3, 0.2)..normalize(),
            time * 2.2 + phase * 6,
          );
      });
    }
  }

  /// Fish (or dolphins, at [size] 2) leaping out of the water at [spots]
  /// now and then.
  void _leapers(
    Node parent,
    List<vm.Vector3> spots,
    Color color, {
    double size = 1,
    double waterline = 0,
  }) {
    for (final (i, spot) in spots.indexed) {
      final fish = Node()
        ..add(
          meshNode(
            reshaped(
              SphereGeometry(radius: 0.1 * size, segments: 12, rings: 8),
              vm.Vector3(0.6, 0.8, 2),
            ),
            matte(color, roughness: 0.4),
          ),
        )
        ..add(
          meshNode(
            reshaped(
              CuboidGeometry(vm.Vector3.all(1)),
              vm.Vector3(0.02, 0.14 * size, 0.1 * size),
            ),
            matte(color, roughness: 0.4),
            position: vm.Vector3(0, 0, -0.22 * size),
          ),
        );
      final splash = meshNode(
        RingGeometry(innerRadius: 0.2 * size, outerRadius: 0.28 * size),
        matte(const Color(0xFFE8F4FF), roughness: 0.4),
        position: spot + vm.Vector3(0, waterline + 0.02, 0),
      );
      final turn = _random.nextDouble() * math.pi * 2;
      final period = 3.5 + i * 0.9;
      parent
        ..add(fish)
        ..add(splash);
      _animations.add((time, _) {
        final t = (time + i * 1.7) % period / 1.1;
        final out = t < 1;
        fish.visible = out;
        if (out) {
          final along = vm.Vector3(math.cos(turn), 0, math.sin(turn));
          fish
            ..position = spot +
                along * ((t - 0.5) * 1.2 * size) +
                vm.Vector3(0, waterline + math.sin(t * math.pi) * 0.7 * size, 0)
            ..rotation = vm.Quaternion.fromTwoVectors(
                  vm.Vector3(0, 0, 1),
                  along,
                ) *
                vm.Quaternion.axisAngle(
                  vm.Vector3(1, 0, 0),
                  (t - 0.5) * 2.2,
                );
        }
        // A ring spreading where it went in.
        final ring = ((t - 1) / 1.2).clamp(0.0, 1.0);
        splash
          ..visible = ring > 0 && ring < 1
          ..scale = vm.Vector3(1 + ring * 2.5, 1, 1 + ring * 2.5);
      });
    }
  }

  /// Smoke or steam puffing up from [at], growing as it rises.
  void _smoke(
    Node parent,
    vm.Vector3 at, {
    int count = 6,
    double height = 5,
    double size = 0.5,
    Color color = const Color(0xFF8C7F7D),
  }) =>
      _risers(
        parent,
        count: count,
        build: () => meshNode(
          IcosphereGeometry(radius: size, subdivisions: 1),
          matte(color, roughness: 1),
        ),
        from: () => at.clone(),
        height: height,
        speed: 0.7,
        grow: 1.8,
      );

  /// Glowing specks hovering about between [low] and [high], fading in and
  /// out: fireflies, embers or dust in a sunbeam.
  void _motes(
    Node parent, {
    required int count,
    required Color color,
    required double spread,
    double low = 0.3,
    double high = 2,
    double size = 0.03,
    vm.Vector3? center,
  }) {
    final middle = center ?? vm.Vector3(0, 0, -1);
    for (var i = 0; i < count; i++) {
      final home = middle +
          vm.Vector3(
            (_random.nextDouble() - 0.5) * spread,
            low + _random.nextDouble() * (high - low),
            (_random.nextDouble() - 0.5) * spread,
          );
      final mote = _unlit(
        IcosphereGeometry(radius: size, subdivisions: 0),
        color,
        at: home,
      );
      final phase = _random.nextDouble() * 9;
      parent.add(mote);
      _animations.add((time, _) {
        mote
          ..position = home +
              vm.Vector3(
                math.sin(time * 0.6 + phase) * 0.5,
                math.sin(time * 0.9 + phase * 2) * 0.25,
                math.cos(time * 0.5 + phase) * 0.4,
              )
          ..scale = vm.Vector3.all(
            0.3 + 0.8 * math.sin(time * 2.5 + phase).abs(),
          );
      });
    }
  }

  /// Something sliding along [from] → [to] and back over [period] seconds,
  /// bobbing as it goes (a boat, a balloon, a crab).
  void _shuttle(
    Node parent,
    Node node, {
    required vm.Vector3 from,
    required vm.Vector3 to,
    required double period,
    double bob = 0.05,
    double bobSpeed = 1.3,
    bool turn = true,
  }) {
    parent.add(node);
    final phase = _random.nextDouble() * period;
    final forward = (to - from)..y = 0;
    _animations.add((time, _) {
      final cycle = ((time + phase) / period) % 1;
      final there = cycle < 0.5;
      final along = there ? cycle * 2 : 2 - cycle * 2;
      final t = 0.5 - math.cos(along * math.pi) / 2;
      node.position = from +
          (to - from) * t +
          vm.Vector3(0, math.sin(time * bobSpeed + phase) * bob, 0);
      if (turn) {
        node.rotation = vm.Quaternion.fromTwoVectors(
          vm.Vector3(0, 0, 1),
          (there ? forward : -forward).normalized(),
        );
      }
    });
  }

  /// A tall, sharp rock.
  Node _spire(math.Random random, Color color, {double height = 4}) => meshNode(
        CylinderGeometry(
          bottomRadius: height * (0.22 + random.nextDouble() * 0.1),
          topRadius: height * 0.03,
          height: height,
          radialSegments: 5 + random.nextInt(3),
        ),
        matte(color, roughness: 0.95),
        position: vm.Vector3(0, height / 2 - 0.1, 0),
        rotation: vm.Quaternion.axisAngle(
          vm.Vector3(1, 0, 0.4)..normalize(),
          (random.nextDouble() - 0.5) * 0.25,
        ),
      );

  /// A bare, crooked tree.
  Node _deadTree(math.Random random, Color color, {double height = 3}) {
    final material = matte(color, roughness: 0.95);
    final bend = (random.nextDouble() - 0.5) * 0.8;
    final tree = Node(name: 'dead-tree')
      ..add(
        meshNode(
          TubeGeometry(
            CatmullRomPath([
              vm.Vector3.zero(),
              vm.Vector3(bend * 0.4, height * 0.5, 0),
              vm.Vector3(bend, height, 0.1),
            ]),
            radius: height * 0.05,
            radialSegments: 8,
            stations: 14,
          ),
          material,
        ),
      );
    for (final side in [-1.0, 1.0]) {
      final from = vm.Vector3(bend * 0.24, height * 0.6, 0);
      tree.add(
        meshNode(
          TubeGeometry(
            CatmullRomPath([
              from,
              from + vm.Vector3(side * height * 0.2, height * 0.12, 0),
              from + vm.Vector3(side * height * 0.32, height * 0.3, 0.05),
            ]),
            radius: height * 0.018,
            radialSegments: 5,
            stations: 8,
          ),
          material,
        ),
      );
    }

    return tree;
  }

  /// A cone of a volcano [height] tall, glowing at the top, smoking.
  Node _volcanoPeak(Node parent, vm.Vector3 at, double height) {
    final peak = Node(name: 'peak')
      ..position = at
      ..add(
        meshNode(
          CylinderGeometry(
            bottomRadius: height * 1.1,
            topRadius: height * 0.25,
            height: height,
            radialSegments: 28,
          ),
          matte(const Color(0xFF4A3634), roughness: 0.9),
          position: vm.Vector3(0, height / 2, 0),
        ),
      )
      ..add(
        _unlit(
          CylinderGeometry(
            bottomRadius: height * 0.23,
            topRadius: height * 0.23,
            height: 0.08,
          ),
          const Color(0xFFFF7A2F),
          at: vm.Vector3(0, height + 0.01, 0),
        ),
      );
    for (final turn in [0.3, 2.4]) {
      peak.add(
        _unlit(
          TubeGeometry(
            CatmullRomPath([
              for (var s = 0; s <= 4; s++)
                vm.Vector3(
                  math.cos(turn + s * 0.08) * height * (0.25 + s * 0.2),
                  height * (1 - s / 4),
                  math.sin(turn + s * 0.08) * height * (0.25 + s * 0.2),
                ),
            ]),
            radius: height * 0.03,
            radialSegments: 6,
            stations: 16,
          ),
          const Color(0xFFFF7A2F),
        ),
      );
    }
    parent.add(peak);
    _smoke(
      parent,
      at + vm.Vector3(0, height, 0),
      height: height * 1.2,
      size: height * 0.12,
      count: 5,
    );

    return peak;
  }

  void _volcanoLife(Node scene) {
    final random = math.Random(21);
    _around(
      scene,
      random,
      count: 18,
      near: 8,
      far: 13,
      build: (i) => _spire(
        random,
        i.isEven ? const Color(0xFF3F302F) : const Color(0xFF55403C),
        height: 2 + random.nextDouble() * 4,
      ),
    );
    _around(
      scene,
      random,
      count: 9,
      near: 5,
      far: 9,
      offset: 0.3,
      build: (i) => _deadTree(random, const Color(0xFF2A2020), height: 2.4),
    );
    // More volcanoes on every side, one of them rumbling close.
    _volcanoPeak(scene, vm.Vector3(13, 0, -13), 5);
    _volcanoPeak(scene, vm.Vector3(-17, 0, -9), 4);
    _volcanoPeak(scene, vm.Vector3(-13, 0, 13), 6);
    _volcanoPeak(scene, vm.Vector3(15, 0, 9), 3.5);
    // Bubbling lava pools.
    for (final (x, z, r) in [
      (4.5, -4.0, 0.9),
      (-5.0, -2.5, 0.7),
      (-4.0, 3.5, 1.0),
      (5.0, 3.0, 0.6),
      (1.5, -7.0, 1.2),
    ]) {
      final glow = _unlit(
        CylinderGeometry(
          bottomRadius: r * 0.7,
          topRadius: r * 0.7,
          height: 0.02,
        ),
        const Color(0xFFFFD36B),
        at: vm.Vector3(x, 0.03, z),
      );
      scene
        ..add(
          meshNode(
            CylinderGeometry(
              bottomRadius: r * 1.2,
              topRadius: r * 1.15,
              height: 0.06,
            ),
            matte(const Color(0xFF2A2020)),
            position: vm.Vector3(x, 0, z),
          ),
        )
        ..add(
          _unlit(
            CylinderGeometry(bottomRadius: r, topRadius: r, height: 0.04),
            const Color(0xFFFF7A2F),
            at: vm.Vector3(x, 0.02, z),
          ),
        )
        ..add(glow);
      _animations.add((time, _) {
        final s = 0.75 + math.sin(time * 2.1 + x) * 0.2;
        glow.scale = vm.Vector3(s, 1, s);
      });
      _risers(
        scene,
        count: 3,
        build: () => _unlit(
          IcosphereGeometry(radius: 0.06, subdivisions: 0),
          const Color(0xFFFFB347),
        ),
        from: () => vm.Vector3(
          x + (_random.nextDouble() - 0.5) * r,
          0,
          z + (_random.nextDouble() - 0.5) * r,
        ),
        height: 1.4,
        speed: 0.9,
      );
    }
    // Steam hissing out of cracks.
    for (final at in [
      vm.Vector3(-3, 0, -6),
      vm.Vector3(6.5, 0, -1),
      vm.Vector3(-6.5, 0, 0.5),
      vm.Vector3(2, 0, 5),
    ]) {
      _smoke(
        scene,
        at,
        count: 4,
        height: 2.5,
        size: 0.2,
        color: const Color(0xFFB8AFAD),
      );
    }
    // Bats circling in the glow.
    _flock(
      scene,
      count: 7,
      center: vm.Vector3(0, 4.5, -2),
      radius: 7,
      body: const Color(0xFF2A2024),
      wings: const Color(0xFF3B2A30),
      size: 1.4,
      flap: 16,
    );
  }

  void _moonBeachLife(Node scene) {
    final random = math.Random(22);
    // Palms and bushes all round the sand.
    _around(
      scene,
      random,
      count: 9,
      near: 4.6,
      far: 5.6,
      offset: 0.6,
      build: (i) => i % 3 == 2
          ? bush(size: 1.2, color: const Color(0xFF3F7A58))
          : palmTree(
              lean: random.nextDouble() * 6,
              height: 1.8 + random.nextDouble(),
            ),
    );
    // Little islands out at sea, all the way round.
    _around(
      scene,
      random,
      count: 7,
      near: 22,
      far: 34,
      build: (i) {
        final r = 2.5 + random.nextDouble() * 2.5;
        final isle = Node(name: 'isle')
          ..add(
            meshNode(
              plateau(
                radius: (a) => r * (1 + 0.12 * math.sin(3 * a + i)),
                top: 0.4,
                bottom: -0.3,
                bottomScale: 1.15,
                segments: 24,
              ),
              matte(const Color(0xFF2B3A5E), roughness: 1),
            ),
          );
        for (var p = 0; p < 2; p++) {
          isle.add(
            palmTree(lean: p * 3.0 + i, height: 2.6 + p * 0.5)
              ..position = vm.Vector3((p - 0.5) * r * 0.7, 0.4, 0),
          );
        }

        return isle;
      },
    );
    // A lighthouse on a rock, its beam sweeping the sea.
    const lighthouseAt = (x: 18.0, z: -16.0);
    final beam = _unlit(
      reshaped(
        CylinderGeometry(topRadius: 0.06, height: 16),
        vm.Vector3.all(1),
        rotation: vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), -math.pi / 2),
      ),
      const Color(0xFF4A5296),
    );
    final beamPivot = Node()
      ..position = vm.Vector3(lighthouseAt.x, 5.2, lighthouseAt.z)
      ..add(beam..position = vm.Vector3(0, 0, 8));
    scene
      ..add(
        rock(2, turn: 1, color: const Color(0xFF3A4566))
          ..position = vm.Vector3(lighthouseAt.x, -0.3, lighthouseAt.z),
      )
      ..addAll([
        for (var s = 0; s < 4; s++)
          meshNode(
            CylinderGeometry(
              bottomRadius: 0.62 - s * 0.06,
              topRadius: 0.56 - s * 0.06,
              radialSegments: 16,
            ),
            matte(s.isEven ? const Color(0xFFF2F2F2) : const Color(0xFFE5534B)),
            position: vm.Vector3(lighthouseAt.x, 1.0 + s, lighthouseAt.z),
          ),
      ])
      ..add(
        _unlit(
          IcosphereGeometry(radius: 0.4, subdivisions: 1),
          const Color(0xFFFFF3B0),
          at: vm.Vector3(lighthouseAt.x, 5.2, lighthouseAt.z),
        ),
      )
      ..add(beamPivot);
    _animations.add((time, _) => beamPivot.rotation = yaw(time * 0.6));
    // Dolphins playing in the moonlight.
    _leapers(
      scene,
      [
        vm.Vector3(8, 0, -12),
        vm.Vector3(-10, 0, -9),
        vm.Vector3(-9, 0, 8),
        vm.Vector3(11, 0, 6),
      ],
      const Color(0xFF6E7FB8),
      size: 2.2,
      waterline: -0.05,
    );
    // Glowing jellyfish bobbing near the shore.
    for (var i = 0; i < 10; i++) {
      final a = random.nextDouble() * math.pi * 2;
      final r = 7.5 + random.nextDouble() * 5;
      final jelly = _unlit(
        reshaped(
          IcosphereGeometry(radius: 0.18, subdivisions: 1),
          vm.Vector3(1, 0.5, 1),
        ),
        i.isEven ? const Color(0xFFE59BF2) : const Color(0xFF8FE3F2),
      );
      final home = vm.Vector3(math.cos(a) * r, -0.02, math.sin(a) * r);
      scene.add(jelly);
      _animations.add((time, _) {
        jelly
          ..position = home + vm.Vector3(0, math.sin(time * 1.5 + i) * 0.04, 0)
          ..scale = vm.Vector3.all(0.8 + math.sin(time * 3 + i) * 0.2);
      });
    }
    // Crabs scuttling sideways on the sand.
    for (final (from, to) in [
      (vm.Vector3(-3.8, 0, -1.2), vm.Vector3(-2.2, 0, 1.6)),
      (vm.Vector3(2.4, 0, 1.8), vm.Vector3(3.9, 0, -0.6)),
      (vm.Vector3(-1.2, 0, -4.2), vm.Vector3(1.5, 0, -4.6)),
    ]) {
      _shuttle(
        scene,
        _crab(),
        from: from,
        to: to,
        period: 7 + random.nextDouble() * 3,
        bob: 0.01,
        bobSpeed: 22,
      );
    }
    // A campfire, sparks rising.
    final fire = _unlit(
      CylinderGeometry(bottomRadius: 0.18, topRadius: 0, height: 0.42),
      const Color(0xFFFF9F43),
      at: vm.Vector3(-2.8, 0.25, -3.2),
    );
    scene.add(fire);
    for (var i = 0; i < 4; i++) {
      final a = i / 4 * math.pi;
      scene.add(
        meshNode(
          CylinderGeometry(bottomRadius: 0.05, topRadius: 0.05, height: 0.6),
          matte(const Color(0xFF6E4A33)),
          position: vm.Vector3(-2.8, 0.05, -3.2),
          rotation: yaw(a) *
              vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), math.pi / 2),
        ),
      );
    }
    _animations.add((time, _) {
      fire.scale = vm.Vector3(
        1 + math.sin(time * 11) * 0.12,
        1 + math.sin(time * 17) * 0.25,
        1,
      );
    });
    _risers(
      scene,
      count: 8,
      build: () => _unlit(
        IcosphereGeometry(radius: 0.025, subdivisions: 0),
        const Color(0xFFFFC46B),
      ),
      from: () => vm.Vector3(-2.8, 0.3, -3.2),
      height: 2,
      speed: 0.8,
    );
    // A shooting star now and then.
    final star = _unlit(
      reshaped(
        CylinderGeometry(bottomRadius: 0.03, topRadius: 0.15, height: 5),
        vm.Vector3.all(1),
        rotation: vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), 1.9),
      ),
      const Color(0xFFFFFFFF),
    );
    scene.add(star);
    _animations.add((time, _) {
      final t = (time % 6) / 0.9;
      star
        ..visible = t < 1
        ..position = vm.Vector3(-20 + t * 30, 26 - t * 9, -45);
    });
  }

  Node _crab() {
    final shell = matte(const Color(0xFFE5534B), roughness: 0.5);

    return Node(name: 'crab')
      ..add(
        meshNode(
          reshaped(
            SphereGeometry(radius: 0.12, segments: 12, rings: 8),
            vm.Vector3(1.4, 0.6, 1),
          ),
          shell,
          position: vm.Vector3(0, 0.08, 0),
        ),
      )
      ..addAll([
        for (final side in [-1.0, 1.0]) ...[
          meshNode(
            SphereGeometry(radius: 0.05, segments: 8, rings: 6),
            shell,
            position: vm.Vector3(side * 0.14, 0.1, 0.14),
          ),
          meshNode(
            SphereGeometry(radius: 0.025, segments: 8, rings: 6),
            matte(const Color(0xFF1E1E24)),
            position: vm.Vector3(side * 0.05, 0.16, 0.1),
          ),
        ],
      ]);
  }

  /// Ferns, flowers, bushes and tall trees in a ring around a jungle place.
  void _jungleRing(
    Node scene,
    math.Random random, {
    required double near,
    required double far,
    int trees = 16,
  }) {
    _around(
      scene,
      random,
      count: trees,
      near: near,
      far: far,
      build: (i) => i % 3 == 0
          ? umbrellaTree(random, height: 4 + random.nextDouble() * 2)
          : broadleafTree(random, height: 2.4 + random.nextDouble() * 1.6),
    );
    _around(
      scene,
      random,
      count: trees,
      near: near - 3,
      far: near - 0.5,
      offset: 0.2,
      build: (i) => switch (i % 4) {
        0 => fern(random, size: 1.4),
        1 => bush(size: 1.1),
        2 => flowers(random),
        _ => mushroom(size: 1.2),
      },
    );
  }

  void _templeLife(Node scene) {
    final random = math.Random(23);
    _jungleRing(scene, random, near: 9, far: 13, trees: 18);
    final stone = matte(const Color(0xFF9A9586), roughness: 0.9);
    // Ruins scattered about: broken pillars and fallen blocks.
    _around(
      scene,
      random,
      count: 8,
      near: 5.5,
      far: 7.5,
      offset: 0.4,
      build: (i) {
        final h = 0.6 + random.nextDouble() * 1.6;
        return i.isEven
            ? (Node(name: 'stump')
              ..add(
                meshNode(
                  CylinderGeometry(
                    bottomRadius: 0.34,
                    topRadius: 0.3,
                    height: h,
                    radialSegments: 14,
                  ),
                  stone,
                  position: vm.Vector3(0, h / 2, 0),
                ),
              ))
            : (Node(name: 'block')
              ..add(
                meshNode(
                  reshaped(
                    CuboidGeometry(vm.Vector3.all(1)),
                    vm.Vector3(0.9, 0.5, 0.6),
                    rotation: yaw(random.nextDouble()),
                  ),
                  stone,
                  position: vm.Vector3(0, 0.25, 0),
                ),
              ));
      },
    );
    // Giant stone monkey heads watching from the trees.
    for (final (x, z, turn) in [
      (8.0, -7.0, -0.8),
      (-8.5, -5.5, 0.9),
      (-7.5, 7.0, 2.3),
    ]) {
      scene.add(
        _stoneHead(stone)
          ..position = vm.Vector3(x, 0, z)
          ..rotation = yaw(turn),
      );
    }
    _butterflies(scene, [
      for (var i = 0; i < 7; i++)
        vm.Vector3(
          math.cos(i * 0.9) * (3 + i * 0.4),
          0.7 + (i % 3) * 0.3,
          math.sin(i * 0.9) * (3 + i * 0.4) - 1,
        ),
    ]);
    _flock(
      scene,
      count: 4,
      center: vm.Vector3(0, 5.5, -4),
      radius: 7,
      body: const Color(0xFFE5534B),
      wings: const Color(0xFF3F7DE0),
      size: 1.6,
      speed: 0.5,
    );
    _fallingLeaves(scene, count: 10, height: 5, spread: 14);
    _motes(
      scene,
      count: 14,
      color: const Color(0xFFFFE9A8),
      spread: 6,
      low: 1,
      high: 4,
      center: vm.Vector3(0, 0, -6),
    );
  }

  Node _stoneHead(Material stone) {
    final dark = matte(const Color(0xFF6F6A5E));

    return Node(name: 'stone-head')
      ..add(
        meshNode(
          reshaped(
            CuboidGeometry(vm.Vector3.all(1)),
            vm.Vector3(1.6, 1.8, 1.4),
          ),
          stone,
          position: vm.Vector3(0, 0.9, 0),
        ),
      )
      ..add(
        meshNode(
          reshaped(
            CuboidGeometry(vm.Vector3.all(1)),
            vm.Vector3(1.1, 0.6, 0.3),
          ),
          stone,
          position: vm.Vector3(0, 0.55, 0.78),
        ),
      )
      ..addAll([
        for (final side in [-1.0, 1.0]) ...[
          meshNode(
            reshaped(
              CuboidGeometry(vm.Vector3.all(1)),
              vm.Vector3(0.36, 0.26, 0.1),
            ),
            dark,
            position: vm.Vector3(side * 0.38, 1.25, 0.71),
          ),
          meshNode(
            reshaped(
              CuboidGeometry(vm.Vector3.all(1)),
              vm.Vector3(0.3, 0.5, 0.4),
            ),
            stone,
            position: vm.Vector3(side * 0.95, 1.1, 0),
          ),
        ],
        meshNode(
          reshaped(
            CuboidGeometry(vm.Vector3.all(1)),
            vm.Vector3(1.7, 0.25, 1.5),
          ),
          matte(moss),
          position: vm.Vector3(0, 1.85, 0),
        ),
      ]);
  }

  void _skyIslandLife(Node scene) {
    final random = math.Random(24);
    // Floating islands all round, some with a waterfall pouring off.
    for (var i = 0; i < 9; i++) {
      final a = i / 9 * math.pi * 2 + random.nextDouble() * 0.4;
      final r = 9 + random.nextDouble() * 7;
      final size = 0.9 + random.nextDouble() * 1.4;
      final home = vm.Vector3(
        math.cos(a) * r,
        -2.5 + random.nextDouble() * 6,
        math.sin(a) * r,
      );
      final isle = Node(name: 'floating-isle')
        ..add(
          meshNode(
            CylinderGeometry(
              bottomRadius: 0.1,
              topRadius: size,
              height: size * 1.4,
              radialSegments: 14,
            ),
            matte(const Color(0xFF9A6B47)),
            position: vm.Vector3(0, -size * 0.7, 0),
          ),
        )
        ..add(
          meshNode(
            CylinderGeometry(
              bottomRadius: size,
              topRadius: size,
              height: 0.14,
              radialSegments: 14,
            ),
            matte(const Color(0xFF8CCB6E)),
          ),
        )
        ..add(
          (i.isEven
              ? broadleafTree(random, height: 1.2 + size * 0.5)
              : bush(size: size * 0.8))
            ..position = vm.Vector3(size * 0.2, 0.05, 0),
        );
      if (i % 3 == 0) {
        isle.add(
          _unlit(
            reshaped(
              CylinderGeometry(bottomRadius: 0.05, topRadius: 0.14, height: 4),
              vm.Vector3(1, 1, 0.4),
            ),
            const Color(0xFFBFE6FF),
            at: vm.Vector3(-size * 0.95, -2, 0),
          ),
        );
      }
      scene.add(isle);
      final phase = random.nextDouble() * 6;
      _animations.add((time, _) {
        isle.position =
            home + vm.Vector3(0, math.sin(time * 0.6 + phase) * 0.3, 0);
      });
    }
    // Clouds slowly circling on every side.
    for (var i = 0; i < 12; i++) {
      final cloud = Node(name: 'cloud');
      final puffs = 3 + random.nextInt(3);
      for (var p = 0; p < puffs; p++) {
        cloud.add(
          meshNode(
            IcosphereGeometry(radius: 0.8 + random.nextDouble() * 0.8),
            matte(const Color(0xFFFFFFFF), roughness: 1),
            position: vm.Vector3(
              p * 1.1 - puffs * 0.55,
              random.nextDouble() * 0.4,
              0,
            ),
          ),
        );
      }
      final orbit = 14 + random.nextDouble() * 10;
      final height = -5 + random.nextDouble() * 12;
      final phase = i / 12 * math.pi * 2;
      scene.add(cloud);
      _animations.add((time, _) {
        final a = phase + time * 0.012;
        cloud
          ..position =
              vm.Vector3(math.cos(a) * orbit, height, math.sin(a) * orbit)
          ..rotation = yaw(-a);
      });
    }
    // Hot air balloons drifting by.
    for (final (i, color) in [
      const Color(0xFFF26B5B),
      const Color(0xFF5E9EFF),
      const Color(0xFFF5C343),
    ].indexed) {
      final balloon = Node(name: 'balloon')
        ..add(
          meshNode(
            reshaped(IcosphereGeometry(radius: 0.9), vm.Vector3(1, 1.15, 1)),
            matte(color, roughness: 0.6),
            position: vm.Vector3(0, 1.4, 0),
          ),
        )
        ..add(
          meshNode(
            reshaped(CuboidGeometry(vm.Vector3.all(1)), vm.Vector3.all(0.35)),
            matte(const Color(0xFF9A6B47)),
          ),
        );
      final a = i * 2.1 + 0.6;
      final r = 11.0 + i * 3;
      _shuttle(
        scene,
        balloon,
        from: vm.Vector3(math.cos(a) * r, 2.0 + i, math.sin(a) * r),
        to: vm.Vector3(math.cos(a + 0.7) * r, 3.0 + i, math.sin(a + 0.7) * r),
        period: 40,
        bob: 0.3,
        bobSpeed: 0.7,
        turn: false,
      );
    }
    _flock(
      scene,
      count: 6,
      center: vm.Vector3(0, 6, -4),
      radius: 10,
      body: const Color(0xFFFFFFFF),
      wings: const Color(0xFFE8EEF5),
      size: 1.5,
      speed: 0.6,
    );
    _butterflies(scene, [
      vm.Vector3(-2.5, 0.8, -1.5),
      vm.Vector3(2.6, 0.9, -2),
      vm.Vector3(-1.8, 0.7, 2),
      vm.Vector3(2.2, 1, 1.5),
    ]);
  }

  void _fernTrailLife(Node scene) {
    final random = math.Random(25);
    _jungleRing(scene, random, near: 10, far: 15, trees: 20);
    _butterflies(scene, [
      for (var i = 0; i < 8; i++)
        vm.Vector3(
          math.cos(i * 0.8 + 0.4) * (3.2 + i * 0.5),
          0.6 + (i % 3) * 0.35,
          math.sin(i * 0.8 + 0.4) * (3.2 + i * 0.5) - 1,
        ),
    ]);
    _flock(
      scene,
      count: 5,
      center: vm.Vector3(0, 6, -3),
      radius: 8,
      body: const Color(0xFF44B37A),
      wings: const Color(0xFFF5C343),
      size: 1.6,
      speed: 0.5,
    );
    _fallingLeaves(scene, count: 14, height: 6, spread: 16);
    _motes(
      scene,
      count: 16,
      color: const Color(0xFFFFF4C2),
      spread: 10,
      low: 0.8,
      high: 4,
    );
  }

  void _canopyLife(Node scene) {
    final random = math.Random(26);
    // Giant trunks on every side.
    _around(
      scene,
      random,
      count: 10,
      near: 7,
      far: 14,
      offset: 0.5,
      y: -8,
      build: (i) {
        final trunk = Node(name: 'trunk')
          ..add(
            meshNode(
              CylinderGeometry(
                bottomRadius: 1.2,
                topRadius: 0.8,
                height: 22,
                radialSegments: 18,
              ),
              matte(const Color(0xFF7A5238), roughness: 0.9),
            ),
          );
        for (var c = 0; c < 4; c++) {
          trunk.add(
            meshNode(
              IcosphereGeometry(
                radius: 1.6 + random.nextDouble(),
                subdivisions: 1,
              ),
              matte(leafGreens[random.nextInt(leafGreens.length)]),
              position: vm.Vector3(
                (random.nextDouble() - 0.5) * 2.6,
                11 + random.nextDouble() * 1.5,
                (random.nextDouble() - 0.5) * 2.6,
              ),
            ),
          );
        }
        // A bracket fungus shelf on the trunk.
        trunk.add(
          meshNode(
            reshaped(
              CylinderGeometry(bottomRadius: 0.6, topRadius: 0.6, height: 0.1),
              vm.Vector3(1, 1, 0.6),
            ),
            matte(const Color(0xFFE8B86A)),
            position: vm.Vector3(0, 7 + random.nextDouble() * 2, 0.9),
          ),
        );

        return trunk;
      },
    );
    // A floor of treetops far below, all round.
    _around(
      scene,
      random,
      count: 26,
      near: 6,
      far: 22,
      y: -9.5,
      build: (_) => meshNode(
        IcosphereGeometry(
          radius: 2.2 + random.nextDouble() * 1.4,
          subdivisions: 1,
        ),
        matte(leafGreens[random.nextInt(leafGreens.length)]),
      ),
    );
    // Vines hanging down, swaying in the breeze.
    for (var i = 0; i < 12; i++) {
      final a = i / 12 * math.pi * 2;
      final r = 6 + random.nextDouble() * 4;
      final length = 2.5 + random.nextDouble() * 3;
      final vine = Node(name: 'vine')
        ..position = vm.Vector3(math.cos(a) * r, 5, math.sin(a) * r - 2)
        ..add(
          meshNode(
            CylinderGeometry(
              bottomRadius: 0.03,
              topRadius: 0.03,
              height: length,
              radialSegments: 5,
            ),
            matte(const Color(0xFF3E7D3A)),
            position: vm.Vector3(0, -length / 2, 0),
          ),
        )
        ..addAll([
          for (var l = 1; l < 4; l++)
            meshNode(
              reshaped(
                IcosphereGeometry(radius: 0.12, subdivisions: 0),
                vm.Vector3(1, 0.4, 1.4),
              ),
              matte(leafGreens[l % leafGreens.length]),
              position: vm.Vector3(0.06, -length * l / 4, 0),
            ),
        ]);
      scene.add(vine);
      _animations.add((time, _) {
        vine.rotation = vm.Quaternion.axisAngle(
          vm.Vector3(1, 0, 0.3)..normalize(),
          math.sin(time * 0.8 + i) * 0.08,
        );
      });
    }
    _flock(
      scene,
      count: 5,
      center: vm.Vector3(0, 2.5, -3),
      radius: 7,
      body: const Color(0xFFE5534B),
      wings: const Color(0xFFF5C343),
      size: 1.7,
      speed: 0.6,
    );
    _flock(
      scene,
      count: 4,
      center: vm.Vector3(0, -3, -2),
      radius: 9,
      body: const Color(0xFF3F7DE0),
      wings: const Color(0xFF44B37A),
      size: 1.7,
      speed: 0.45,
    );
    _fallingLeaves(scene, count: 16, height: 7, spread: 14);
  }

  void _swampLife(Node scene) {
    final random = math.Random(27);
    _around(
      scene,
      random,
      count: 14,
      near: 7,
      far: 15,
      y: -0.1,
      build: (i) => _deadTree(
        random,
        i.isEven ? const Color(0xFF4A3A30) : const Color(0xFF3A3028),
        height: 3 + random.nextDouble() * 3,
      ),
    );
    // Reeds and cattails around the island.
    final reed = matte(const Color(0xFF6E8A3A));
    final cattail = matte(const Color(0xFF6E4A33));
    _around(
      scene,
      random,
      count: 16,
      near: 6.5,
      far: 9,
      y: -0.05,
      build: (i) => Node(name: 'reeds')
        ..addAll([
          for (var r = 0; r < 4; r++) ...[
            meshNode(
              CylinderGeometry(
                bottomRadius: 0.02,
                topRadius: 0.012,
                height: 0.9 + r * 0.15,
                radialSegments: 4,
              ),
              reed,
              position: vm.Vector3(
                r * 0.09 - 0.14,
                0.45 + r * 0.07,
                r.isEven ? 0.05 : -0.05,
              ),
            ),
            if (r.isOdd)
              meshNode(
                CapsuleGeometry(radius: 0.035, height: 0.14),
                cattail,
                position: vm.Vector3(
                  r * 0.09 - 0.14,
                  0.95 + r * 0.15,
                  r.isEven ? 0.05 : -0.05,
                ),
              ),
          ],
        ]),
    );
    // Glowing mushrooms on the island's edge.
    for (var i = 0; i < 7; i++) {
      final a = i / 7 * math.pi * 2 + 0.3;
      scene.add(
        mushroom(size: 0.9)
          ..position =
              vm.Vector3(math.cos(a) * 2.7, 0, math.sin(a) * 2.5 - 0.6),
      );
    }
    _motes(
      scene,
      count: 34,
      color: const Color(0xFFD8FF7A),
      spread: 14,
      high: 2.4,
    );
    // Bubbles popping up out of the murk.
    _risers(
      scene,
      count: 12,
      build: () => meshNode(
        IcosphereGeometry(radius: 0.05, subdivisions: 1),
        matte(const Color(0xFF8FB8A0), roughness: 0.2),
      ),
      from: () {
        final a = _random.nextDouble() * math.pi * 2;
        final r = 4 + _random.nextDouble() * 5;
        return vm.Vector3(math.cos(a) * r, -0.06, math.sin(a) * r);
      },
      height: 0.25,
      speed: 0.2,
    );
    // Frogs hopping from pad to pad.
    for (var i = 0; i < 3; i++) {
      final a = i * 2.2 + 0.5;
      final frog = Node(name: 'frog')
        ..add(
          meshNode(
            reshaped(
              SphereGeometry(radius: 0.1, segments: 10, rings: 8),
              vm.Vector3(1.2, 0.8, 1.3),
            ),
            matte(const Color(0xFF5DBB4E), roughness: 0.4),
          ),
        )
        ..addAll([
          for (final side in [-1.0, 1.0])
            meshNode(
              SphereGeometry(radius: 0.035, segments: 8, rings: 6),
              matte(const Color(0xFFF5F0D8)),
              position: vm.Vector3(side * 0.06, 0.08, 0.06),
            ),
        ]);
      final from = vm.Vector3(math.cos(a) * 4.2, 0, math.sin(a) * 4.2 - 1);
      final to =
          vm.Vector3(math.cos(a + 0.5) * 5.4, 0, math.sin(a + 0.5) * 5.4 - 1);
      scene.add(frog);
      _animations.add((time, _) {
        // Sit, hop over, sit, hop back.
        final cycle = (time * 0.25 + i * 0.3) % 1;
        final hop = (cycle % 0.5 - 0.35) / 0.15;
        final going = cycle < 0.5;
        final t = hop.clamp(0.0, 1.0);
        final a = going ? from : to;
        final b = going ? to : from;
        frog
          ..position =
              a + (b - a) * t + vm.Vector3(0, math.sin(t * math.pi) * 0.5, 0)
          ..rotation = vm.Quaternion.fromTwoVectors(
            vm.Vector3(0, 0, 1),
            ((b - a)..y = 0).normalized(),
          );
      });
    }
    // Mist drifting all round.
    final fog = matte(const Color(0xFFC9DCD2), roughness: 1);
    for (var i = 0; i < 10; i++) {
      final puff = meshNode(
        reshaped(IcosphereGeometry(radius: 1.4), vm.Vector3(2.4, 0.3, 1)),
        fog,
      );
      final orbit = 6 + random.nextDouble() * 8;
      final phase = i / 10 * math.pi * 2;
      final height = 0.05 + random.nextDouble() * 0.3;
      scene.add(puff);
      _animations.add((time, _) {
        final a = phase + time * 0.03;
        puff
          ..position =
              vm.Vector3(math.cos(a) * orbit, height, math.sin(a) * orbit)
          ..rotation = yaw(-a);
      });
    }
  }

  void _lakeLife(Node scene) {
    final random = math.Random(28);
    // Shores all the way round, with palms, bushes and rocks.
    _around(
      scene,
      random,
      count: 9,
      near: 16,
      far: 24,
      offset: 0.3,
      build: (i) {
        final r = 4 + random.nextDouble() * 3;
        final shore = Node(name: 'shore')
          ..add(
            meshNode(
              plateau(
                radius: (a) => r * (1 + 0.12 * math.sin(3 * a + i)),
                top: 0.3,
                bottom: -0.3,
                bottomScale: 1.1,
                segments: 28,
              ),
              matte(const Color(0xFF6FB05A)),
            ),
          )
          ..add(
            meshNode(
              RingGeometry(innerRadius: r, outerRadius: r * 1.12, segments: 28),
              matte(const Color(0xFFE9D6A8)),
              position: vm.Vector3(0, 0.01, 0),
            ),
          );
        for (var p = 0; p < 3; p++) {
          shore.add(
            (p == 1
                ? broadleafTree(random, height: 2.6)
                : palmTree(lean: random.nextDouble() * 6, height: 2.4))
              ..position = vm.Vector3((p - 1) * r * 0.4, 0.3, r * 0.2),
          );
        }

        return shore;
      },
    );
    // Mountains beyond, all round.
    _around(
      scene,
      random,
      count: 8,
      near: 45,
      far: 60,
      build: (i) {
        final h = 12 + random.nextDouble() * 10;
        return Node(name: 'mountain')
          ..add(
            meshNode(
              CylinderGeometry(
                bottomRadius: h * 0.8,
                height: h,
                radialSegments: 20,
              ),
              matte(const Color(0xFF7C8FA8), roughness: 1),
              position: vm.Vector3(0, h / 2, 0),
            ),
          )
          ..add(
            meshNode(
              CylinderGeometry(
                bottomRadius: h * 0.22,
                height: h * 0.28,
                radialSegments: 20,
              ),
              matte(const Color(0xFFF2F4F8), roughness: 1),
              position: vm.Vector3(0, h * 0.86 + 0.05, 0),
            ),
          );
      },
    );
    // Lily pads and reeds near the raft.
    _around(
      scene,
      random,
      count: 12,
      near: 4,
      far: 9,
      build: (i) => meshNode(
        CylinderGeometry(
          bottomRadius: 0.35,
          topRadius: 0.35,
          height: 0.02,
          radialSegments: 14,
        ),
        matte(const Color(0xFF4E9A48), roughness: 0.6),
        position: vm.Vector3(0, -0.01, 0),
      ),
    );
    // A sailboat far out, and a fisher's canoe.
    final boat = Node(name: 'sailboat')
      ..add(
        meshNode(
          reshaped(
            SphereGeometry(radius: 1, segments: 16, rings: 8),
            vm.Vector3(0.5, 0.25, 1.4),
          ),
          matte(const Color(0xFFA77B4F)),
        ),
      )
      ..add(
        meshNode(
          CylinderGeometry(bottomRadius: 0.05, topRadius: 0.05, height: 3),
          matte(const Color(0xFF7A5238)),
          position: vm.Vector3(0, 1.5, 0),
        ),
      )
      ..add(
        meshNode(
          reshaped(
            CylinderGeometry(
              bottomRadius: 0.9,
              topRadius: 0,
              height: 2.4,
              radialSegments: 3,
            ),
            vm.Vector3(0.05, 1, 1),
          ),
          matte(const Color(0xFFFFFFFF)),
          position: vm.Vector3(0, 1.6, -0.2),
        ),
      );
    _shuttle(
      scene,
      boat,
      from: vm.Vector3(-14, 0, -12),
      to: vm.Vector3(-4, 0, -18),
      period: 60,
      bob: 0.08,
    );
    _shuttle(
      scene,
      Node(name: 'boat2')
        ..add(
          meshNode(
            reshaped(
              SphereGeometry(radius: 1, segments: 16, rings: 8),
              vm.Vector3(0.4, 0.2, 1.2),
            ),
            matte(const Color(0xFFE5534B)),
          ),
        )
        ..add(
          meshNode(
            reshaped(
              CylinderGeometry(
                bottomRadius: 0.7,
                topRadius: 0,
                height: 1.8,
                radialSegments: 3,
              ),
              vm.Vector3(0.05, 1, 1),
            ),
            matte(const Color(0xFFF5C343)),
            position: vm.Vector3(0, 1.2, 0),
          ),
        ),
      from: vm.Vector3(9, 0, 4),
      to: vm.Vector3(13, 0, -6),
      period: 50,
      bob: 0.08,
    );
    _leapers(
      scene,
      [
        vm.Vector3(5, 0, -6),
        vm.Vector3(-6, 0, -4),
        vm.Vector3(-5, 0, 5),
        vm.Vector3(6, 0, 5),
        vm.Vector3(0, 0, -10),
      ],
      const Color(0xFFE8A33D),
      size: 1.4,
    );
    _flock(
      scene,
      count: 6,
      center: vm.Vector3(0, 4, -3),
      radius: 9,
      body: const Color(0xFFFFFFFF),
      wings: const Color(0xFFDCE3EA),
      size: 1.8,
      speed: 0.5,
    );
  }

  void _gorgeLife(Node scene) {
    final random = math.Random(29);
    final rockMaterial = matte(const Color(0xFFB4654A), roughness: 0.95);
    // The walls carry on behind, and close the gorge off at the far end.
    for (final side in [-1.0, 1.0]) {
      for (var z = 8.6; z < 20; z += 2.6) {
        final w = 2.5 + random.nextDouble() * 1.5;
        final h = 5 + random.nextDouble() * 5;
        scene.add(
          meshNode(
            reshaped(
              IcosphereGeometry(radius: 1, subdivisions: 1),
              vm.Vector3(w, h, 2.2),
              rotation: yaw(random.nextDouble()),
            ),
            rockMaterial,
            position:
                vm.Vector3(side * (4.6 + random.nextDouble()), h * 0.4, z),
          ),
        );
      }
    }
    // Layered stripes on the walls, and vines hanging over them.
    for (final side in [-1.0, 1.0]) {
      for (var z = 6.0; z > -20; z -= 4.2) {
        final length = 1.5 + random.nextDouble() * 2.5;
        final vine = Node(name: 'vine')
          ..position = vm.Vector3(side * 3.6, 4.5 + random.nextDouble(), z)
          ..add(
            meshNode(
              CylinderGeometry(
                bottomRadius: 0.03,
                topRadius: 0.03,
                height: length,
                radialSegments: 5,
              ),
              matte(const Color(0xFF4E8A3A)),
              position: vm.Vector3(0, -length / 2, 0),
            ),
          );
        scene.add(vine);
        _animations.add((time, _) {
          vine.rotation = vm.Quaternion.axisAngle(
            vm.Vector3(0, 0, 1),
            math.sin(time * 0.7 + z) * 0.06,
          );
        });
      }
    }
    // Cacti dotted about.
    final cactus = matte(const Color(0xFF5E9A4E));
    _around(
      scene,
      random,
      count: 7,
      near: 2.6,
      far: 3.6,
      offset: 0.4,
      build: (i) {
        final h = 0.7 + random.nextDouble() * 0.7;
        return Node(name: 'cactus')
          ..add(
            meshNode(
              CapsuleGeometry(radius: 0.13, height: h),
              cactus,
              position: vm.Vector3(0, h / 2 + 0.1, 0),
            ),
          )
          ..add(
            meshNode(
              CapsuleGeometry(radius: 0.08, height: 0.3),
              cactus,
              position: vm.Vector3(0.2, h * 0.6, 0),
            ),
          );
      },
    );
    // A thin waterfall trickling down the wall into a pool.
    scene
      ..add(
        _unlit(
          reshaped(
            CylinderGeometry(bottomRadius: 0.2, topRadius: 0.12, height: 6),
            vm.Vector3(1, 1, 0.3),
          ),
          const Color(0xFFBFE6FF),
          at: vm.Vector3(-3.7, 3, -7),
        ),
      )
      ..add(
        meshNode(
          CylinderGeometry(bottomRadius: 0.9, topRadius: 0.9, height: 0.03),
          matte(const Color(0xFF5FA8D8), roughness: 0.1),
          position: vm.Vector3(-3.2, 0.01, -7),
        ),
      );
    _risers(
      scene,
      count: 5,
      build: () => meshNode(
        IcosphereGeometry(radius: 0.12, subdivisions: 1),
        matte(const Color(0xFFFFFFFF), roughness: 1),
      ),
      from: () => vm.Vector3(-3.4, 0, -7),
      height: 0.8,
      speed: 0.5,
      grow: 1,
    );
    // Vultures circling high above.
    _flock(
      scene,
      count: 4,
      center: vm.Vector3(0, 9, -5),
      radius: 6,
      body: const Color(0xFF3A2E2A),
      wings: const Color(0xFF2A2220),
      size: 3,
      speed: 0.4,
      flap: 4,
    );
    // Dust swirling along the floor.
    for (final center in [vm.Vector3(2.2, 0, -5), vm.Vector3(-1.8, 0, 3)]) {
      for (var i = 0; i < 10; i++) {
        final speck = meshNode(
          IcosphereGeometry(radius: 0.05, subdivisions: 0),
          matte(const Color(0xFFE8C08A), roughness: 1),
        );
        final phase = i / 10;
        scene.add(speck);
        _animations.add((time, _) {
          final t = (time * 0.35 + phase) % 1;
          final a = time * 4 + phase * 12;
          final r = 0.15 + t * 0.6;
          speck
            ..position = center +
                vm.Vector3(
                  math.cos(a) * r + math.sin(time * 0.3) * 1.5,
                  t * 2.2,
                  math.sin(a) * r,
                )
            ..scale = vm.Vector3.all(1 - t * 0.7);
        });
      }
    }
    // A tumbleweed rolling past.
    final tumbleweed = meshNode(
      IcosphereGeometry(radius: 0.3, subdivisions: 1),
      matte(const Color(0xFFB8925A), roughness: 1)..doubleSided = true,
    );
    scene.add(tumbleweed);
    _animations.add((time, _) {
      final t = (time * 0.08) % 1;
      tumbleweed
        ..position = vm.Vector3(
          -4 + t * 8,
          0.3 + math.sin(t * math.pi * 10).abs() * 0.25,
          -3 + t * 1.5,
        )
        ..rotation = vm.Quaternion.axisAngle(vm.Vector3(0, 0, 1), -t * 30);
    });
  }

  void _throneLife(Node scene) {
    final wall = matte(const Color(0xFF3E4450), roughness: 0.9);
    final trim = matte(const Color(0xFF5E6672), roughness: 0.9);
    final gold = matte(const Color(0xFFE8B83A), roughness: 0.3)
      ..metallicFactor = 0.85;
    // Walls all round the hall, with tall moonlit windows.
    const left = -6.0;
    const right = 6.0;
    const back = -13.0;
    const front = 7.0;
    const height = 7.0;
    void wallPiece(vm.Vector3 center, vm.Vector3 size) => scene.add(
          meshNode(
            reshaped(CuboidGeometry(vm.Vector3.all(1)), size),
            wall,
            position: center,
          ),
        );
    wallPiece(
      vm.Vector3(0, height / 2, back),
      vm.Vector3(right - left, height, 0.5),
    );
    wallPiece(
      vm.Vector3(0, height / 2, front),
      vm.Vector3(right - left, height, 0.5),
    );
    for (final x in [left, right]) {
      wallPiece(
        vm.Vector3(x, height / 2, (back + front) / 2),
        vm.Vector3(0.5, height, front - back),
      );
      for (var z = back + 2.5; z < front - 1; z += 4) {
        scene
          ..add(
            _unlit(
              reshaped(
                CuboidGeometry(vm.Vector3.all(1)),
                vm.Vector3(0.05, 2.6, 1.1),
              ),
              const Color(0xFF8E86C8),
              at: vm.Vector3(x - x.sign * 0.27, 4, z),
            ),
          )
          ..add(
            meshNode(
              reshaped(
                CuboidGeometry(vm.Vector3.all(1)),
                vm.Vector3(0.12, 0.12, 1.4),
              ),
              trim,
              position: vm.Vector3(x - x.sign * 0.3, 5.35, z),
            ),
          );
      }
    }
    // Moonbeams falling through the windows, with dust drifting in them.
    _motes(
      scene,
      count: 30,
      color: const Color(0xFFD9D2FF),
      spread: 10,
      low: 0.5,
      high: 5,
      size: 0.02,
      center: vm.Vector3(0, 0, -3),
    );
    // Big round banners behind the throne and over the doors.
    for (final z in [back + 0.3, front - 0.3]) {
      for (final x in [-3.2, 3.2]) {
        scene
          ..add(
            meshNode(
              reshaped(
                CuboidGeometry(vm.Vector3.all(1)),
                vm.Vector3(1.2, 3.2, 0.05),
              ),
              matte(const Color(0xFF2F8443)),
              position: vm.Vector3(x, 4, z),
            ),
          )
          ..add(
            meshNode(
              starPrism(0.35, 0.06),
              gold,
              position: vm.Vector3(x, 4.6, z + (z < 0 ? 0.06 : -0.06)),
            ),
          );
      }
    }
    // Lizard statues guarding the throne, and piles of gold.
    const statue = Color(0xFF8C8778);
    for (final x in [-2.2, 2.2]) {
      final guard = Iguana(statue);
      scene
        ..add(
          meshNode(
            reshaped(CuboidGeometry(vm.Vector3.all(1)), vm.Vector3(1, 0.6, 1)),
            trim,
            position: vm.Vector3(x, 0.3, -9.4),
          ),
        )
        ..add(
          guard.root
            ..position = vm.Vector3(x, 0.6, -9.4)
            ..rotation = yaw(x > 0 ? -0.4 : 0.4),
        );
    }
    final coin = matte(const Color(0xFFF5C343), roughness: 0.3)
      ..metallicFactor = 0.9;
    final random = math.Random(30);
    for (final (x, z) in [(-4.2, -10.5), (4.3, -10.8), (-4.6, -6.0)]) {
      scene.add(
        meshNode(
          reshaped(IcosphereGeometry(radius: 0.6), vm.Vector3(1, 0.5, 1)),
          coin,
          position: vm.Vector3(x, 0.1, z),
        ),
      );
      for (var i = 0; i < 5; i++) {
        scene.add(
          meshNode(
            CylinderGeometry(bottomRadius: 0.1, topRadius: 0.1, height: 0.02),
            coin,
            position: vm.Vector3(
              x + (random.nextDouble() - 0.5) * 1.6,
              0.02,
              z + (random.nextDouble() - 0.5) * 1.6,
            ),
          ),
        );
      }
    }
    // Chandeliers swinging gently overhead.
    for (final z in [-7.0, -1.0, 4.0]) {
      final chandelier = Node(name: 'chandelier')
        ..position = vm.Vector3(0, height, z)
        ..add(
          meshNode(
            CylinderGeometry(bottomRadius: 0.02, topRadius: 0.02, height: 1.6),
            gold,
            position: vm.Vector3(0, -0.8, 0),
          ),
        )
        ..add(
          meshNode(
            TorusGeometry(radius: 0.6, tubeRadius: 0.05),
            gold,
            position: vm.Vector3(0, -1.6, 0),
            rotation: vm.Quaternion.axisAngle(vm.Vector3(1, 0, 0), math.pi / 2),
          ),
        );
      final flames = <Node>[];
      for (var i = 0; i < 6; i++) {
        final a = i / 6 * math.pi * 2;
        final flame = _unlit(
          IcosphereGeometry(radius: 0.07, subdivisions: 1),
          const Color(0xFFFFC46B),
          at: vm.Vector3(math.cos(a) * 0.6, -1.48, math.sin(a) * 0.6),
        );
        flames.add(flame);
        chandelier.add(flame);
      }
      scene.add(chandelier);
      _animations.add((time, _) {
        chandelier.rotation = vm.Quaternion.axisAngle(
          vm.Vector3(1, 0, 0),
          math.sin(time * 0.7 + z) * 0.03,
        );
        for (final (i, flame) in flames.indexed) {
          flame.scale = vm.Vector3(1, 1.2 + math.sin(time * 13 + i) * 0.3, 1);
        }
      });
    }
    // Bats under the ceiling.
    _flock(
      scene,
      count: 5,
      center: vm.Vector3(0, 5.2, -3),
      radius: 3.5,
      body: const Color(0xFF2A2024),
      wings: const Color(0xFF3B2A30),
      size: 1.3,
      flap: 16,
      speed: 0.4,
    );
  }
}
