import 'package:flutter/rendering.dart';
import 'particle_field.dart';

/// [CustomPainter] that renders a [ParticleField].
class ParticleFieldPainter extends CustomPainter {
  // ParticleFieldController is a ChangeNotifier, so it is the repaint notifier.
  ParticleFieldPainter({
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
        anchorX: frameRect.width / 2,
        anchorY: frameRect.height / 2,
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
