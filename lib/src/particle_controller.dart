import 'package:flutter/material.dart';

import '../particle_field.dart';

/// The ParticleController is passed as a parameter to `onTick` and `onInit` and provides access
/// to all of the run-time properties used to render the field, including the
/// sprite sheet, list of particles, global opacity, blendmode, origin, and anchor.
///
/// These properties can be changed to modify the behavior of a running
/// particle field.
class ParticleController with ChangeNotifier {
  ParticleController({
    required this.onTick,
    required this.spriteSheet,
    this.onInit,
    required this.blendMode,
    required this.origin,
    required this.anchor,
  }) {
    if (onInit != null) onInit!(this);
  }

  /// See [ParticleField.spriteSheet].
  ImageFrameProvider spriteSheet;

  /// See [ParticleField.onTick].
  ParticleFieldTick onTick;

  /// See [ParticleField.onInit].
  ParticleFieldInit? onInit;

  /// See [ParticleField.blendMode].
  BlendMode blendMode;

  /// See [ParticleField.origin].
  Alignment origin;

  /// See [ParticleField.anchor].
  Alignment anchor;

  /// The list of [Particle] instances being managed and displayed.
  List<Particle> particles = [];

  /// Global opacity for the particle field. For example, this could be used
  /// to fade all of the particles in or out.
  double opacity = 1.0;

  Duration _lastElapsed = Duration.zero;

  void tick(Duration elapsed) {
    // called by ParticleField's Ticker. Save the elapsed time, and notify the painter.
    // the painter then calls back to executeOnTick, providing the size
    _lastElapsed = elapsed;
    notifyListeners();
  }

  void executeOnTick(Size size) {
    onTick(this, _lastElapsed, size);
  }
}
