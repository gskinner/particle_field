import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// An [ImageFrameProvider] that works with basic sprite sheets or single frame
/// images. It can accept an unloaded [ImageProvider], and toggle `isReady` when
/// it successfully loads.
///
/// ### Single frame images
/// Simply pass in the `image`. The frame width/height will be calculated automatically,
/// and length will be set to 1.
///
/// ### Image strips
/// For a horizontal strip of frames, specify the `image` and a `frameWidth`.
/// The image's intrinsic height will be used for `frameHeight`, and `length` will
/// be calculated by dividing the image width by the frame width. Vertical strips
/// can specify a `frameHeight` instead of width.
///
/// ### Image grid
/// Specify the `image`, `frameWidth`, and `frameHeight`. The `length` can be
/// calculated automatically with this information from the image's intrinsic
/// dimensions, but you can also provide a length to limit it (ex. if the grid
/// is not totally filled, such as 13 frames in a 3x5 grid).
///
/// ### Texture packing
/// Variable sized frames aren't currently supported by this class, but an
/// implementation could be written that implements [ImageFrameProvider].
///
/// ### Example
/// For example, the sparkle sprite sheet included with the example, is a
/// horizontal strip of 13 frames at 21x23px (273px wide in total):
///
/// ```
/// SpriteSheet(
///   image: AssetImage('sparkles.png'),
///   frameWidth: 21,
/// )
/// ```
/// The frame height and length aren't necessary because they are calculated
/// from the image's intrinsic dimensions.
class SpriteSheet with ImageFrameProvider {
  SpriteSheet({
    required ImageProvider image,
    int frameWidth = 0,
    int frameHeight = 0,
    int length = 0,
    double scale = 1.0,
  }) {
    _frameWidth = frameWidth + 0.0;
    _frameHeight = frameHeight + 0.0;
    _length = length;
    _scale = scale;

    // Resolve the provider into a stream, then listen for it to complete.
    // This will happen synchronously if it's already loaded into memory.
    ImageStream stream = image.resolve(const ImageConfiguration());
    stream.addListener(ImageStreamListener((info, _) {
      _onImageLoaded(info.image);
    }));
  }

  ui.Image? _image; // null until the ImageProvide finishes loading.
  late double _frameWidth; // if 0, will use image width
  late double _frameHeight; // if 0, will use image height
  late int _length; // if 0, will be calculated from image size
  late double _scale;
  late int _cols; // precalculated

  @override
  ui.Image get image {
    if (_image == null) throw ('SpriteSheet.image called before isReady');
    return _image!;
  }

  @override
  bool get isReady => _image != null;

  @override
  int get length => _length;

  @override
  double get scale => _scale;

  @override
  Rect getFrame(int index) {
    // Given a frame index, return the rect that describes that frame in the image.
    if (_image == null) throw ('SpriteSheet.getFrame called before isReady');
    if (index < 0) throw ('Bad index passed to SpriteSheet.getFrame');

    index = index % length;
    int x = index % _cols;
    int y = (index / _cols).floor();

    return Rect.fromLTWH(
      x * _frameWidth,
      y * _frameHeight,
      _frameWidth,
      _frameHeight,
    );
  }

  void _onImageLoaded(ui.Image img) {
    _image = img;
    // pre-calculate frame info:
    if (_frameWidth == 0) _frameWidth = img.width + 0.0;
    if (_frameHeight == 0) _frameHeight = img.height + 0.0;
    _cols = (img.width / _frameWidth).floor();
    if (_length == 0) _length = _cols * (img.height / _frameHeight).floor();
  }
}

/// Generic interface for fetching frames of an image sequence such as a sprite
/// sheet. Can be implemented to provide alternative sprite sheet implementations.
mixin ImageFrameProvider {
  /// Returns the image to use when drawing frames.
  ui.Image get image => throw (UnimplementedError());

  /// Returns when the image is loaded and ready to be used.
  bool get isReady => throw (UnimplementedError());

  /// The number of frames in this provider.
  int get length => throw (UnimplementedError());

  /// A scale to render the frames of this provider at.
  double get scale => 1;

  /// Returns the [Rect] that defines the boundaries of the frame specified by the `index`.
  Rect getFrame(int index) => throw (UnimplementedError());
}
