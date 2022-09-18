import 'package:flutter/material.dart';

/// The basic particle used by [ParticleField]. It includes properties
/// common to most particle effects.
///
/// This class can be extended to add additional data or methods.
class Particle {
  /// Constructs a Particle instance.
  Particle({
    this.x = 0.0,
    this.y = 0.0,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.frame = 0,
    this.color = Colors.black,
    this.vx = 0.0,
    this.vy = 0.0,
    this.lifespan = 0.0,
    this.age = 0.0,
  });

  // Properties used by ParticleFieldPainter:

  /// The horizontal position of this particle.
  double x;

  /// The vertical position of this particle.
  double y;

  /// The scale of this particle. Defaults to 1.
  double scale;

  /// The rotation of this particle in radians.
  double rotation;

  /// The index of the frame to display from the particle field's [ImageFrameProvider].
  /// For [SpriteSheet] this can exceed `length`, and will loop.
  int frame;

  /// A color that can be composited with the image frame via [ParticleField.blendMode].
  /// For example, you could modify the opacity of particles by using [BlendMode.srcIn]
  /// (the default) and adjusting the opacity of the particle `color`:
  ///
  /// ```
  /// // in onTick handler:
  /// particle.color = Colors.black.withOpacity(0.2)
  /// ```
  Color color;

  // Optional extra properties:

  /// Horizontal velocity. By default [update] adds this value to [x].
  double vx;

  /// Vertical velocity. By default [update] adds this value to [y].
  double vy;

  /// Value that can be useful for managing particle lifecycles.
  double lifespan;

  /// Value that can be useful for managing particle lifecycles.
  /// By default [update] adds `1` to this value.
  double age;

  /// Sets any values passed, and runs basic logic:
  ///
  /// * if `x` or `y` are not specified, adds `vx` / `vy`
  /// * if `age` is not specified, increments it by one
  ///
  /// This is provided for convenience, and does not need to be used.
  void update({
    double? x,
    double? y,
    double? scale,
    double? rotation,
    int? frame,
    Color? color,
    double? vx,
    double? vy,
    double? lifespan,
    double? age,
  }) {
    if (x != null) this.x = x;
    if (y != null) this.y = y;
    if (scale != null) this.scale = scale;
    if (rotation != null) this.rotation = rotation;
    if (frame != null) this.frame = frame;
    if (color != null) this.color = color;

    if (vx != null) this.vx = vx;
    if (vy != null) this.vy = vy;
    if (lifespan != null) this.lifespan = lifespan;
    this.age = age ?? this.age + 1;

    if (x == null) this.x += this.vx;
    if (y == null) this.y += this.vy;
  }

  /// Returns an offset representing this particle's position, optionally
  /// with a transformation applied.
  Offset toOffset([Matrix4? transform]) {
    Offset o = Offset(x, y);
    if (transform == null) return o;
    return MatrixUtils.transformPoint(transform, o);
  }
}
