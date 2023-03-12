import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../particle_field.dart';

/// ParticleField lets you add custom particle effects anywhere in your Flutter
/// application easily. Simply provide a [SpriteSheet] (or [ImageFrameProvider])
/// and an `onTick` handler that manages your [Particle] list.
///
/// ```
/// ParticleField field = ParticleField(
///   spriteSheet: sparkleSpriteSheet,
///   // top left will be 0,0:
///   origin: Alignment.topLeft,
///   // onTick is where all the magic happens:
///   onTick: (controller, elapsed, size) {
///     List<Particle> particles = controller.particles;
///     // add a new particle each frame:
///     particles.add(Particle(x: rnd(size.width), vx: rnd(-1, 1)));
///     // update existing particles:
///     for (int i = particles.length - 1; i >= 0; i--) {
///       Particle particle = particles[i];
///       // call update, which automatically adds vx/vy to x/y
///       // add some gravity (ie. increase vertical velocity)
///       // and increment the frame
///       particle.update(vy: particle.vy + 0.1, frame: particle.frame + 1);
///       // remove particle if it's out of bounds:
///       if (!size.contains(particle.toOffset())) particles.removeAt(i);
///     }
///   },
/// )
/// ```
class ParticleField extends StatefulWidget {
  const ParticleField({
    required this.spriteSheet,
    required this.onTick,
    this.onInit,
    this.blendMode = BlendMode.srcIn,
    this.origin = Alignment.center,
    this.anchor = Alignment.center,
    Key? key,
  }) : super(key: key);

  /// Provides the image frames for this particle system. See [SpriteSheet].
  final ImageFrameProvider spriteSheet;

  /// Called each frame immediately before [_ParticleFieldPainter] renders the
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

  /// Specifies the origin point (ie. where `x=0, y=0`) of the particle field's coordinate
  /// system. For example, [Alignment.center] would position the origin in the
  /// middle of the field, [Alignment.topLeft] would set the origin at the top
  /// left.
  final Alignment origin;

  /// Specifies the anchor point (ie. where `x=0, y=0`) for the particles. This
  /// is the point around which the particle rotates, and from which it is drawn.
  final Alignment anchor;

  @override
  State<ParticleField> createState() => _ParticleFieldState();

  /// A convenience function that layers this [ParticleField] behind the specified
  /// child, sizes it to match, and optionally scales it (this can be useful
  /// for providing an "overscan" region).
  Widget stackBelow({double scale = 1.0, required Widget child}) {
    return Stack(children: [_stackPrep(scale), child]);
  }

  /// A convenience function that layers this [ParticleField] in front of the specified
  /// child, sizes it to match, and optionally scales it (this can be useful
  /// for providing an "overscan" region).
  Widget stackAbove({double scale = 1.0, required Widget child}) {
    return Stack(children: [child, _stackPrep(scale)]);
  }

  Widget _stackPrep(double scale) {
    Widget o = this;
    if (scale != 1.0) o = Transform.scale(scale: scale, child: o);
    return Positioned.fill(child: o);
  }
}

class _ParticleFieldState extends State<ParticleField>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late final ParticleController _controller;
  late final _ParticleFieldPainter _painter;

  @override
  void initState() {
    _initController();
    _painter = _ParticleFieldPainter(controller: _controller);
    _ticker = createTicker(_controller.tick)..start();
    super.initState();
  }

  @override
  void didUpdateWidget(ParticleField old) {
    _updateController();
    super.didUpdateWidget(old);
  }

  void _initController() {
    // keep synced with _updateController
    _controller = ParticleController(
      spriteSheet: widget.spriteSheet,
      onTick: widget.onTick,
      onInit: widget.onInit,
      blendMode: widget.blendMode,
      origin: widget.origin,
      anchor: widget.anchor,
    );
  }

  void _updateController() {
    // keep synced with _initController
    _controller.spriteSheet = widget.spriteSheet;
    _controller.onTick = widget.onTick;
    _controller.onInit = widget.onInit;
    _controller.blendMode = widget.blendMode;
    _controller.origin = widget.origin;
    _controller.anchor = widget.anchor;
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

/// [CustomPainter] that renders a [ParticleField].
class _ParticleFieldPainter extends CustomPainter {
  // ParticleFieldController is a ChangeNotifier, so it is the repaint notifier.
  _ParticleFieldPainter({
    required this.controller,
  }) : super(repaint: controller);

  final ParticleController controller;

  @override
  void paint(Canvas canvas, Size size) {
    List<Particle> particles = controller.particles;
    controller.executeOnTick(size);
    int l = particles.length;
    if (l == 0) return; // no particles

    ImageFrameProvider frameProvider = controller.spriteSheet;
    if (!frameProvider.isReady) return; // image hasn't loaded

    Paint fill = Paint();
    List<RSTransform> transforms = [];
    List<Rect> rects = [];
    List<Color> colors = [];

    Alignment origin = controller.origin;
    double xOffset = size.width / 2 * (origin.x + 1);
    double yOffset = size.height / 2 * (origin.y + 1);
    double spriteScale = frameProvider.scale;

    Alignment anchor = controller.anchor;
    double opacity = controller.opacity;

    for (int i = 0; i < l; i++) {
      Particle o = particles[i];

      // Add a rect entry, which describes the portion (frame) of the sprite sheet image to use as the source.
      Rect frameRect = frameProvider.getFrame(o.frame);
      rects.add(frameRect);

      // Each particle has a transformation entry, which tells drawAtlas where to draw it.
      transforms.add(RSTransform.fromComponents(
        translateX: o.x + xOffset,
        translateY: o.y + yOffset,
        rotation: o.rotation,
        scale: o.scale * spriteScale,
        anchorX: frameRect.width / 2 * (anchor.x + 1),
        anchorY: frameRect.height / 2 * (anchor.y + 1),
      ));

      // Add a color entry, which is composited with the frame via the blend mode.
      colors.add(o.color.withOpacity(o.color.opacity * opacity));
    }

    // Draw all of the particles based on the data entries.
    canvas.drawAtlas(
      frameProvider.image,
      transforms,
      rects,
      colors,
      controller.blendMode,
      Rect.fromLTWH(0.0, 0.0, size.width, size.height),
      fill,
    );
  }

  @override
  bool shouldRepaint(oldDelegate) => true;
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
