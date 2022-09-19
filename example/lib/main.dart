import 'dart:math';

import 'package:flutter/material.dart';
import 'package:particle_field/particle_field.dart';
import 'package:rnd/rnd.dart';

// TODO: Add additional examples, including interactive ones

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Particle Field Demo',
      debugShowCheckedModeBanner: false,
      home: ParticleFieldExample(),
    );
  }
}

// this is a very quick and dirty example.
class ParticleFieldExample extends StatelessWidget {
  const ParticleFieldExample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final SpriteSheet sparkleSpriteSheet = SpriteSheet(
      image: const AssetImage('assets/particle-21x23.png'),
      frameWidth: 21,
    );

    // simple "star" particle field.
    final ParticleField starField = ParticleField(
      spriteSheet: sparkleSpriteSheet,
      // use the sprite alpha, with the particle color:
      blendMode: BlendMode.dstIn,
      // top left will be 0,0:
      origin: Alignment.topLeft,
      // onTick is where all the magic happens:
      onTick: (controller, elapsed, size) {
        List<Particle> particles = controller.particles;
        // add a new particle each frame:
        particles.add(Particle(
          color: Colors.white,
          // set a random x position along the width:
          x: rnd(size.width),
          // set a random size:
          scale: rnd(0.2, 0.5),
          // show a random frame:
          frame: rnd(sparkleSpriteSheet.length * 1.0).floor(),
          // set a y velocity:
          vy: rnd(6, 20),
        ));
        // update existing particles:
        for (int i = particles.length - 1; i >= 0; i--) {
          Particle particle = particles[i];
          // call update, which automatically adds vx/vy to x/y
          particle.update();
          // remove particle if it's out of bounds:
          if (!size.contains(particle.toOffset())) particles.removeAt(i);
        }
      },
    );

    // more complex "comet" particle effect
    final ParticleField cometParticles = ParticleField(
      // start out the same:
      spriteSheet: sparkleSpriteSheet,
      blendMode: BlendMode.dstIn,
      origin: Alignment.topCenter,
      // but with a different onTick handler:
      onTick: (controller, elapsed, size) {
        List<Particle> particles = controller.particles;
        // add 10 particles each tick:
        for (int i = 10; i > 0; i--) {
          particles.add(Particle(
            // assign a random blue-ish color:
            color: HSLColor.fromAHSL(1, rnd(180, 290), 1, 0.5).toColor(),
            // set a starting location:
            x: rnd(size.width / 2) * rnd.getSign(),
            y: rnd(-10, size.height),
            // add a tiny bit of initial x & y velocity
            vx: rnd(-2, 2),
            vy: rnd(-1, 1),
            // start on a random frame, with some random rotation:
            frame: rnd.getInt(0, 10000),
            rotation: rnd(pi),
            // give it a random lifespan (in ticks):
            lifespan: rnd(30, 80),
          ));
        }
        for (int i = particles.length - 1; i >= 0; i--) {
          Particle particle = particles[i];
          // calculate ratio of age vs lifespan:
          double ratio = particle.age / particle.lifespan;
          // update the particle (remember, it automatically applies vx/vy):
          particle.update(
            // accelerate, by adding to velocity y each frame:
            vy: particle.vy + 0.15,
            // update x, with some math to move toward the center:
            x: particle.x * sqrt(1 - ratio * 0.15) + particle.vx,
            // scale down as the particle approaches its lifespan:
            scale: sqrt((1 - ratio) * 4),
            // advance the spritesheet frame:
            frame: particle.frame + 1,
          );
          // remove particle if its age exceeds its lifespan:
          if (particle.age > particle.lifespan) particles.removeAt(i);
        }
      },
    );

    return Scaffold(
      body: DefaultTextStyle(
        style: const TextStyle(
          color: Color(0xFF110018),
          fontSize: 60,
          fontWeight: FontWeight.w900,
          letterSpacing: -6,
          height: 1,
          shadows: [Shadow(blurRadius: 8, color: Color(0xAA4400FF))],
        ),
        child: ColoredBox(
          color: const Color(0xFF110018),
          child: starField.stackBelow(
            child: Align(
              alignment: const Alignment(0, -0.67),
              child: cometParticles.stackBelow(
                child: const Text("PARTICLES"),
                scale: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
