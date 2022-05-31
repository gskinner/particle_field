import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'particle.dart';
import 'particle_field_painter.dart';
import 'sprite_sheet.dart';

export 'particle.dart';
export 'sprite_sheet.dart';

/// ParticleField lets you add custom particle effects anywhere in your Flutter
/// application easily. Simply provide a [SpriteSheet] (or [ImageFrameProvider])
/// and an `onTick` handler that manages your [Particle] list.
///
/// ```
/// TODO: simple example
/// ```
class ParticleField extends StatefulWidget {
  const ParticleField({
    required this.spriteSheet,
    required this.onTick,
    this.onInit,
    this.blendMode = BlendMode.srcIn,
    this.origin = Alignment.center,
    Key? key,
  }) : super(key: key);

  /// Provides the image frames for this particle system. See [SpriteSheet].
  final ImageFrameProvider spriteSheet;

  /// Called each frame immediately before [ParticleFieldPainter] renders the
  /// particles. This is where logic to add, remove, and update your particles
  /// will normally live.
  ///
  /// The `onTick` handler is passed a [ParticleController] which provides
  /// access to the list of particles. It also receives the `elapsed` time,
  /// and the `size` (ie. pixel dimensions) of the canvas.
  ///
  /// See also [Particle.update].
  final ParticleFieldTick onTick;

  /// Called when the [ParticleController] first initializes. This provides an
  /// opportunity to perform setup functions, like pre-populating the particle
  /// list with initial particles.
  final ParticleFieldInit? onInit;

  /// The [BlendMode] to use when compositing [Particle.color] with the particle
  /// frame image. Defaults to [BlendMode.srcIn].
  final BlendMode blendMode;

  /// Specifies to origin point (ie. where `x=0, y=0`) of the particle field's coordinate
  /// system. For example, [Alignment.center] would position the origin in the
  /// middle of the field, [Alignment.topLeft] would set the origin at the top
  /// left. TODO: Test.
  final Alignment origin;

  @override
  State<ParticleField> createState() => _ParticleFieldState();
}

class _ParticleFieldState extends State<ParticleField>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final ParticleController _controller;
  late final ParticleFieldPainter _painter;

  @override
  void initState() {
    _controller = ParticleController(
      spriteSheet: widget.spriteSheet,
      onTick: widget.onTick,
      onInit: widget.onInit,
      blendMode: widget.blendMode,
      origin: widget.origin,
    );
    _painter = ParticleFieldPainter(controller: _controller);
    _ticker = createTicker(_controller.tick)..start();
    super.initState();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _painter);
  }
}

/// The ParticleController is an intermediary between [ParticleField],
/// [ParticleFieldPainter], and the `onTick` (and `onInit`) handlers.
///
/// It is passed as a parameter to `onTick` and `onInit` and provides access
/// to all of the run-time properties used to render the field, including the
/// sprite sheet, list of particles, global opacity, blendmode, and origin.
///
/// The `onTick` handler can even be swapped dynamically to change behaviors
/// on the fly.
class ParticleController with ChangeNotifier {
  ParticleController({
    required this.onTick,
    required this.spriteSheet,
    this.onInit,
    required this.blendMode,
    required this.origin,
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

/// Defines the signature for the function responsible for updating the particles
/// each tick in a [ParticleField].
typedef ParticleFieldTick = void Function(
  ParticleController controller,
  Duration elapsed,
  Size size,
);

/// Defines the signature for the function called when the ParticleField initializes.
typedef ParticleFieldInit = void Function(
  ParticleController controller,
);