part of 'image_editor.dart';

class CustomDrawLine extends Equatable {
  const CustomDrawLine(this.path, this.color, this.width, this.eraser);

  final Path path;
  final Color color;
  final double width;
  final bool eraser;

  @override
  List<Object?> get props => [path, color, width, eraser];
}

enum DrawMode { none, brush, eraser }

class ImageEditorSnapshot {
  ImageEditorSnapshot({
    required this.imageRotate,
    required this.flip,
    required this.customDrawLines,
    required this.cropRect,
    required this.rawImagePath,
    required this.imagePath,
  });

  final ImageRotate imageRotate;
  final bool flip;
  final List<CustomDrawLine> customDrawLines;
  final Rect cropRect;
  final String rawImagePath;
  final String imagePath;
}

class _ImageEditorState extends Equatable with EquatableMixin {
  const _ImageEditorState({
    required this.rotate,
    required this.flip,
    required this.drawLines,
    required this.drawColor,
    required this.drawMode,
    required this.canRedo,
    required this.cropRect,
    required this.image,
  });

  final ImageRotate rotate;
  final bool flip;
  final DrawMode drawMode;
  final List<CustomDrawLine> drawLines;
  final Rect cropRect;
  final Color drawColor;
  final bool canRedo;
  final ui.Image image;

  bool get canReset =>
      rotate != ImageRotate.none ||
      drawLines.isNotEmpty ||
      flip ||
      cropRect.width.round() != image.width ||
      cropRect.height.round() != image.height;

  @override
  List<Object?> get props => [
    rotate,
    flip,
    drawLines,
    drawColor,
    drawMode,
    canRedo,
    cropRect,
    image,
  ];

  _ImageEditorState copyWith({
    ImageRotate? rotate,
    bool? flip,
    List<CustomDrawLine>? drawLines,
    Color? drawColor,
    DrawMode? drawMode,
    bool? canRedo,
    Rect? cropRect,
  }) => _ImageEditorState(
    rotate: rotate ?? this.rotate,
    flip: flip ?? this.flip,
    drawLines: drawLines ?? this.drawLines,
    drawColor: drawColor ?? this.drawColor,
    drawMode: drawMode ?? this.drawMode,
    canRedo: canRedo ?? this.canRedo,
    cropRect: cropRect ?? this.cropRect,
    image: image,
  );
}

enum ImageRotate { none, quarter, half, threeQuarter }

extension _ImageRotateExt on ImageRotate {
  double get radius {
    switch (this) {
      case ImageRotate.none:
        return 0;
      case ImageRotate.quarter:
        return math.pi / 2;
      case ImageRotate.half:
        return math.pi;
      case ImageRotate.threeQuarter:
        return math.pi * 3 / 2;
    }
  }

  double get degree {
    switch (this) {
      case ImageRotate.none:
        return 0;
      case ImageRotate.quarter:
        return 90;
      case ImageRotate.half:
        return 180;
      case ImageRotate.threeQuarter:
        return 270;
    }
  }

  Size apply(Size size) {
    if (!_boundRotated) {
      return size;
    }
    return Size(size.height, size.width);
  }

  bool get _boundRotated {
    switch (this) {
      case ImageRotate.none:
        return false;
      case ImageRotate.quarter:
      case ImageRotate.threeQuarter:
        return true;
      case ImageRotate.half:
        return false;
    }
  }
}
