import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:image/image.dart' as img;

import '../../../bloc/subscribe_mixin.dart';
import '../../../constants/resources.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/file.dart';
import '../../../utils/hook.dart';
import '../../../utils/logger.dart';
import '../../../widgets/action_button.dart';
import '../../../widgets/dialog.dart';
import '../../../widgets/menu.dart';
import '../../../widgets/toast.dart';

Future<ImageEditorSnapshot?> showImageEditor(
  BuildContext context, {
  required String path,
  ImageEditorSnapshot? snapshot,
}) =>
    showDialog<ImageEditorSnapshot?>(
      context: context,
      builder: (context) => _ImageEditorDialog(
        path: path,
        snapshot: snapshot,
      ),
    );

class _ImageEditorDialog extends HookConsumerWidget {
  const _ImageEditorDialog({
    required this.path,
    this.snapshot,
  });

  final String path;

  final ImageEditorSnapshot? snapshot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boundaryKey = useMemoized(GlobalKey.new);
    final image = useMemoizedFuture<ui.Image?>(() async {
      final bytes = File(path).readAsBytesSync();
      final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      final codec =
          await PaintingBinding.instance.instantiateImageCodecWithSize(buffer);
      final frame = await codec.getNextFrame();
      return frame.image;
    }, null, keys: [path]);
    if (image.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }
    final uiImage = image.data;
    if (uiImage == null) {
      assert(false, 'image is null');
      return const SizedBox();
    }
    return BlocProvider<_ImageEditorBloc>(
      create: (BuildContext context) =>
          _ImageEditorBloc(path: path, image: uiImage, snapshot: snapshot),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: ColoredBox(
          color: context.theme.background.withOpacity(0.8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 56),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => _Preview(
                      path: path,
                      viewPortSize: constraints.biggest,
                      boundaryKey: boundaryKey,
                      image: uiImage,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const _OperationButtons(),
                const SizedBox(height: 56),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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

  /// Crop area of the image. zero means no crop.
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
  }) =>
      _ImageEditorState(
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

class _ImageEditorBloc extends Cubit<_ImageEditorState> with SubscribeMixin {
  _ImageEditorBloc({
    required this.path,
    required this.image,
    ImageEditorSnapshot? snapshot,
  }) : super(_ImageEditorState(
          rotate: ImageRotate.none,
          flip: false,
          drawLines: const [],
          drawColor: _kDefaultDrawColor,
          drawMode: DrawMode.none,
          canRedo: false,
          cropRect: Rect.fromLTWH(
            0,
            0,
            image.width.toDouble(),
            image.height.toDouble(),
          ),
          image: image,
        )) {
    if (snapshot != null) {
      _customDrawLines.addAll(snapshot.customDrawLines);
      setCropRect(snapshot.cropRect);
      _notifyCustomDrawUpdated();
      emit(state.copyWith(
        rotate: snapshot.imageRotate,
        flip: snapshot.flip,
      ));
    }
  }

  final String path;

  final ui.Image image;

  Path? _currentDrawingLine;

  final List<CustomDrawLine> _customDrawLines = [];

  // backup for cancel when clicked "cancel" button instead of "done"
  final List<CustomDrawLine> _backupDrawLines = [];

  //backup for redo.
  final List<CustomDrawLine> _redoDrawLines = [];

  final double _drawStrokeWidth = 11;

  void rotate() {
    ImageRotate next() {
      switch (state.rotate) {
        case ImageRotate.none:
          return ImageRotate.quarter;
        case ImageRotate.quarter:
          return ImageRotate.half;
        case ImageRotate.half:
          return ImageRotate.threeQuarter;
        case ImageRotate.threeQuarter:
          return ImageRotate.none;
      }
    }

    emit(state.copyWith(rotate: next()));
  }

  void flip() {
    emit(state.copyWith(flip: !state.flip));
  }

  void enterDrawMode(DrawMode mode) {
    _backupDrawLines
      ..clear()
      ..addAll(_customDrawLines);
    emit(state.copyWith(drawMode: mode));
  }

  void exitDrawingMode({bool applyTempDraw = false}) {
    if (applyTempDraw) {
      _backupDrawLines.clear();
    } else {
      _customDrawLines
        ..clear()
        ..addAll(_backupDrawLines);
      _backupDrawLines.clear();
      _notifyCustomDrawUpdated();
    }
    emit(state.copyWith(drawMode: DrawMode.none));
  }

  void startDrawEvent(Offset position) {
    if (state.drawMode == DrawMode.none) {
      return;
    }
    _redoDrawLines.clear();
    _currentDrawingLine = Path()..moveTo(position.dx, position.dy);
    _notifyCustomDrawUpdated();
  }

  void updateDrawEvent(Offset position) {
    if (state.drawMode == DrawMode.none) {
      return;
    }
    assert(_currentDrawingLine != null, 'Drawing line is null');
    if (_currentDrawingLine == null) {
      return;
    }
    _currentDrawingLine!.lineTo(position.dx, position.dy);
    _notifyCustomDrawUpdated();
  }

  void endDrawEvent() {
    if (state.drawMode == DrawMode.none) {
      return;
    }
    final path = _currentDrawingLine;
    assert(path != null, 'Drawing line is null');
    if (path == null) {
      return;
    }
    final line = CustomDrawLine(
      path,
      state.drawColor,
      _drawStrokeWidth,
      state.drawMode == DrawMode.eraser,
    );
    _currentDrawingLine = null;
    _customDrawLines.add(line);
    _notifyCustomDrawUpdated();
  }

  void _notifyCustomDrawUpdated() {
    emit(state.copyWith(
      drawLines: [
        ..._customDrawLines,
        if (_currentDrawingLine != null)
          CustomDrawLine(
            Path.from(_currentDrawingLine!),
            state.drawColor,
            _drawStrokeWidth,
            state.drawMode == DrawMode.eraser,
          ),
      ],
      canRedo: _redoDrawLines.isNotEmpty,
    ));
  }

  void setCustomDrawColor(Color color) {
    emit(state.copyWith(drawColor: color));
  }

  void redoDraw() {
    if (state.drawMode == DrawMode.none) {
      return;
    }
    if (_redoDrawLines.isEmpty) {
      return;
    }
    final line = _redoDrawLines.removeLast();
    _customDrawLines.add(line);
    _notifyCustomDrawUpdated();
  }

  void undoDraw() {
    if (state.drawMode == DrawMode.none) {
      return;
    }
    if (_customDrawLines.isEmpty) {
      return;
    }
    final line = _customDrawLines.removeLast();
    _redoDrawLines.add(line);
    _notifyCustomDrawUpdated();
  }

  void setCropRatio(double? ratio) {
    if (ratio == null) {
      emit(state.copyWith(
        cropRect: Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        ),
      ));
      return;
    }
    final width =
        math.min(image.width.toDouble(), image.height.toDouble() * ratio);
    final height = width / ratio;
    final x = (image.width.toDouble() - width) / 2;
    final y = (image.height.toDouble() - height) / 2;
    emit(state.copyWith(
      cropRect: Rect.fromLTWH(x, y, width, height),
    ));
  }

  Future<Uint8List?> _flipAndRotateImage(ui.Image image) async {
    final bytes = await image.toBytes();
    if (bytes == null) {
      return null;
    }
    var imgImage = img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: bytes.buffer,
      order: img.ChannelOrder.rgba,
    );

    if (state.flip) {
      img.flipHorizontal(imgImage);
    }
    if (state.rotate != ImageRotate.none) {
      imgImage = img.copyRotate(imgImage, angle: 360 - state.rotate.degree);
    }
    final data = img.encodePng(imgImage);
    return Uint8List.fromList(data);
  }

  Future<ImageEditorSnapshot?> takeSnapshot() async {
    final recorder = ui.PictureRecorder();

    final cropRect = !state.cropRect.isEmpty && !state.cropRect.isInfinite
        ? state.cropRect
        : null;

    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final center = imageSize.center(Offset.zero);

    final canvas = Canvas(recorder)
      ..clipRect(Rect.fromLTWH(0, 0, imageSize.width, imageSize.height));

    if (cropRect != null) {
      canvas.translate(-cropRect.left, -cropRect.top);
    }

    final imageRect = Rect.fromCenter(
      center: center,
      width: image.width.toDouble(),
      height: image.height.toDouble(),
    );
    paintImage(
      canvas: canvas,
      rect: Rect.fromCenter(
        center: center,
        width: image.width.toDouble(),
        height: image.height.toDouble(),
      ),
      image: image,
    );

    canvas
      ..saveLayer(imageRect, Paint())
      ..translate(imageRect.left, imageRect.top);
    for (final line in _customDrawLines) {
      final paint = Paint()
        ..color = line.eraser ? Colors.white : line.color
        ..strokeWidth = line.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..blendMode = line.eraser ? BlendMode.clear : BlendMode.srcOver
        ..isAntiAlias = true;
      canvas.drawPath(line.path, paint);
    }
    canvas.restore();

    final picture = recorder.endRecording();
    final snapshotImage = cropRect != null
        ? await picture.toImage(cropRect.width.round(), cropRect.height.round())
        : await picture.toImage(
            imageSize.width.round(), imageSize.height.round());

    final bytes = !state.flip && state.rotate == ImageRotate.none
        ? await snapshotImage.toBytes(format: ui.ImageByteFormat.png)
        : await _flipAndRotateImage(snapshotImage);
    if (bytes == null) {
      e('failed to convert image to bytes');
      return null;
    }
    // Save the image to the device's local storage.
    final file = await saveBytesToTempFile(bytes, TempFileType.editImage);
    if (file == null) {
      e('failed to save image to file');
      return null;
    }
    d('save editor snapshot image to file: $file');
    return ImageEditorSnapshot(
      customDrawLines: _customDrawLines,
      imageRotate: state.rotate,
      flip: state.flip,
      cropRect: state.cropRect,
      rawImagePath: path,
      imagePath: file.path,
    );
  }

  void setCropRect(Rect cropRect) {
    emit(state.copyWith(cropRect: cropRect));
  }

  void reset() {
    _redoDrawLines.addAll(_customDrawLines);
    _customDrawLines.clear();
    _notifyCustomDrawUpdated();
    emit(
      state.copyWith(
        cropRect: Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        ),
        flip: false,
        rotate: ImageRotate.none,
      ),
    );
  }
}

class _Preview extends HookConsumerWidget {
  const _Preview({
    required this.path,
    required this.viewPortSize,
    required this.boundaryKey,
    required this.image,
  });

  final String path;

  final Size viewPortSize;

  final Key boundaryKey;

  final ui.Image image;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFlip =
        useBlocStateConverter<_ImageEditorBloc, _ImageEditorState, bool>(
      converter: (state) => state.flip,
    );

    final rotate =
        useBlocStateConverter<_ImageEditorBloc, _ImageEditorState, ImageRotate>(
      converter: (state) => state.rotate,
    );

    final drawMode =
        useBlocStateConverter<_ImageEditorBloc, _ImageEditorState, DrawMode>(
      converter: (state) => state.drawMode,
    );

    final transformedViewPortSize = rotate.apply(viewPortSize);
    final scale = math.min<double>(
        math.min(transformedViewPortSize.width / image.width,
            transformedViewPortSize.height / image.height),
        1);

    final scaledImageSize = Size(image.width * scale, image.height * scale);

    return SizedBox(
      width: viewPortSize.width,
      height: viewPortSize.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Transform.rotate(
              transformHitTests: false,
              angle: -rotate.radius,
              child: RepaintBoundary(
                key: boundaryKey,
                child: Transform(
                  alignment: Alignment.center,
                  transform:
                      isFlip ? Matrix4.rotationY(math.pi) : Matrix4.identity(),
                  transformHitTests: false,
                  child: RepaintBoundary(
                    child: _CustomDrawingWidget(
                      viewPortSize: viewPortSize,
                      image: image,
                      rotate: rotate,
                      flip: isFlip,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (drawMode == DrawMode.none)
            Center(
              child: SizedBox.fromSize(
                size: rotate.apply(scaledImageSize),
                child: _CropRectWidget(
                  scaledImageSize: scaledImageSize,
                  isFlip: isFlip,
                  rotate: rotate,
                  scale: scale,
                ),
              ),
            )
        ],
      ),
    );
  }
}

extension _RectExt on Rect {
  Rect ensureInside(Rect rect) => Rect.fromLTRB(
        math.max(rect.left, left),
        math.max(rect.top, top),
        math.min(rect.right, right),
        math.min(rect.bottom, bottom),
      );

  Rect ensureShiftInside(Rect rect) {
    assert(width <= rect.width, 'width is greater than rect width');
    assert(height <= rect.height, 'height is greater than rect height');

    var offsetX = 0.0;
    if (left < rect.left) {
      offsetX = rect.left - left;
    } else if (right > rect.right) {
      offsetX = rect.right - right;
    }
    var offsetY = 0.0;
    if (top < rect.top) {
      offsetY = rect.top - top;
    } else if (bottom > rect.bottom) {
      offsetY = rect.bottom - bottom;
    }
    return translate(offsetX, offsetY);
  }

  Rect scaled(double scale) => Rect.fromLTRB(
        left * scale,
        top * scale,
        right * scale,
        bottom * scale,
      );

  Rect flipHorizontalInParent(Rect parent, bool flip) {
    if (!flip) {
      return this;
    }
    return Rect.fromLTRB(
        parent.width - right, top, parent.width - left, bottom);
  }
}

Rect transformInsideRect(Rect rect, Rect parent, double radius) {
  final center = parent.center;
  final rotateImageRect = Rect.fromPoints(
    _rotate(parent.topLeft, center, radius),
    _rotate(parent.bottomRight, center, radius),
  );

  final topLeft = _rotate(rect.topLeft, center, radius);
  final bottomRight = _rotate(rect.bottomRight, center, radius);
  final transformed = Rect.fromPoints(topLeft, bottomRight);
  return transformed.translate(-rotateImageRect.left, -rotateImageRect.top);
}

class _CropRectWidget extends HookConsumerWidget {
  const _CropRectWidget({
    required this.scaledImageSize,
    required this.isFlip,
    required this.rotate,
    required this.scale,
  });

  final Size scaledImageSize;
  final bool isFlip;
  final ImageRotate rotate;
  final double scale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cropRect =
        useBlocStateConverter<_ImageEditorBloc, _ImageEditorState, Rect>(
      converter: (state) => state.cropRect,
    );

    final transformedRect = useMemoized(() {
      if (cropRect.isEmpty || cropRect.isInfinite) {
        return Rect.fromLTRB(
            0, 0, scaledImageSize.width, scaledImageSize.height);
      }
      final rawImageRect = Offset.zero & (scaledImageSize / scale);
      return transformInsideRect(
        cropRect.flipHorizontalInParent(rawImageRect, isFlip),
        rawImageRect,
        -rotate.radius,
      ).scaled(scale);
    }, [cropRect, scale, scaledImageSize, rotate, isFlip]);

    final trackingRectCorner = useRef<_ImageDragArea?>(null);

    final cacheTransformedRect = useState(transformedRect);
    useEffect(() {
      cacheTransformedRect.value = transformedRect;
    }, [transformedRect]);

    return Stack(
      fit: StackFit.expand,
      children: [
        GestureDetector(
          onPanStart: (details) {
            final offset = details.localPosition;
            const cornerSize = 30.0;

            if (!transformedRect.contains(offset)) {
              trackingRectCorner.value = null;
              return;
            }
            if (offset.dx < transformedRect.left + cornerSize &&
                offset.dy < transformedRect.top + cornerSize) {
              trackingRectCorner.value = _ImageDragArea.topLeft;
            } else if (offset.dx > transformedRect.right - cornerSize &&
                offset.dy < transformedRect.top + cornerSize) {
              trackingRectCorner.value = _ImageDragArea.topRight;
            } else if (offset.dx < transformedRect.left + cornerSize &&
                offset.dy > transformedRect.bottom - cornerSize) {
              trackingRectCorner.value = _ImageDragArea.bottomLeft;
            } else if (offset.dx > transformedRect.right - cornerSize &&
                offset.dy > transformedRect.bottom - cornerSize) {
              trackingRectCorner.value = _ImageDragArea.bottomRight;
            } else {
              trackingRectCorner.value = _ImageDragArea.center;
            }
          },
          onPanUpdate: (details) {
            final corner = trackingRectCorner.value;
            if (corner == null) {
              return;
            }
            final delta = details.delta;
            final imageRect = Offset.zero & rotate.apply(scaledImageSize);
            // Use cacheTransformedRect to track mouse/gesture change.
            // Cannot use transformedRect because transformedRect update by build method
            // which may slow than gesture update.
            final currentCropRect = cacheTransformedRect.value;
            Rect cropRect;
            switch (corner) {
              case _ImageDragArea.topLeft:
                cropRect = Rect.fromPoints(
                  currentCropRect.topLeft + delta,
                  currentCropRect.bottomRight,
                ).ensureInside(imageRect);
                break;
              case _ImageDragArea.topRight:
                cropRect = Rect.fromPoints(
                  currentCropRect.bottomLeft,
                  currentCropRect.topRight + delta,
                ).ensureInside(imageRect);
                break;
              case _ImageDragArea.bottomLeft:
                cropRect = Rect.fromPoints(
                  currentCropRect.bottomLeft + delta,
                  currentCropRect.topRight,
                ).ensureInside(imageRect);
                break;
              case _ImageDragArea.bottomRight:
                cropRect = Rect.fromPoints(
                  currentCropRect.topLeft,
                  currentCropRect.bottomRight + delta,
                ).ensureInside(imageRect);
                break;
              case _ImageDragArea.center:
                cropRect =
                    currentCropRect.shift(delta).ensureShiftInside(imageRect);
                break;
            }

            if (cropRect.isEmpty) {
              return;
            }
            cacheTransformedRect.value = cropRect;
            final rect = transformInsideRect(
                    cropRect.flipHorizontalInParent(imageRect, isFlip),
                    imageRect,
                    rotate.radius)
                .scaled(1 / scale);
            context.read<_ImageEditorBloc>().setCropRect(rect);
          },
          onPanEnd: (details) {
            trackingRectCorner.value = null;
          },
          child: CustomPaint(
            painter: _CropShadowOverlayPainter(
              cropRect: cacheTransformedRect.value,
              overlayColor: Colors.black.withOpacity(0.4),
              lineColor: Colors.white,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }
}

class _CropShadowOverlayPainter extends CustomPainter {
  _CropShadowOverlayPainter({
    required this.cropRect,
    required this.overlayColor,
    required this.lineColor,
  });

  final Rect cropRect;
  final Color overlayColor;
  final Color lineColor;
  final double lineWidth = 1;

  final double cornerHandleWidth = 4;
  final double cornerHandleSize = 30;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Offset.zero & size, Paint());
    final paint = Paint()
      ..color = overlayColor
      ..style = PaintingStyle.fill;
    canvas
      ..drawRect(Offset.zero & size, paint)
      ..drawRect(cropRect, paint..blendMode = BlendMode.clear)
      ..restore();

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke;
    canvas
      ..drawRect(cropRect, linePaint)
      ..drawLine(
        Offset(cropRect.left + cropRect.width / 3, cropRect.top),
        Offset(cropRect.left + cropRect.width / 3, cropRect.bottom),
        linePaint,
      )
      ..drawLine(
        Offset(cropRect.left, cropRect.top + cropRect.height / 3),
        Offset(cropRect.right, cropRect.top + cropRect.height / 3),
        linePaint,
      )
      ..drawLine(
        Offset(cropRect.left, cropRect.top + cropRect.height * 2 / 3),
        Offset(cropRect.right, cropRect.top + cropRect.height * 2 / 3),
        linePaint,
      )
      ..drawLine(
        Offset(cropRect.left + cropRect.width * 2 / 3, cropRect.top),
        Offset(cropRect.left + cropRect.width * 2 / 3, cropRect.bottom),
        linePaint,
      );

    final cornerHandlePaint = Paint()
      ..color = lineColor
      ..strokeWidth = cornerHandleWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.fill;
    canvas
      // left top
      ..drawLine(
        cropRect.topLeft,
        cropRect.topLeft.translate(0, cornerHandleSize),
        cornerHandlePaint,
      )
      ..drawLine(
        cropRect.topLeft,
        cropRect.topLeft.translate(cornerHandleSize, 0),
        cornerHandlePaint,
      )
      // right top
      ..drawLine(
        cropRect.topRight,
        cropRect.topRight.translate(0, cornerHandleSize),
        cornerHandlePaint,
      )
      ..drawLine(
        cropRect.topRight,
        cropRect.topRight.translate(-cornerHandleSize, 0),
        cornerHandlePaint,
      )
      // left bottom
      ..drawLine(
        cropRect.bottomLeft,
        cropRect.bottomLeft.translate(0, -cornerHandleSize),
        cornerHandlePaint,
      )
      ..drawLine(
        cropRect.bottomLeft,
        cropRect.bottomLeft.translate(cornerHandleSize, 0),
        cornerHandlePaint,
      )
      // right bottom
      ..drawLine(
        cropRect.bottomRight,
        cropRect.bottomRight.translate(0, -cornerHandleSize),
        cornerHandlePaint,
      )
      ..drawLine(
        cropRect.bottomRight,
        cropRect.bottomRight.translate(-cornerHandleSize, 0),
        cornerHandlePaint,
      );
  }

  @override
  bool shouldRepaint(covariant _CropShadowOverlayPainter oldDelegate) =>
      oldDelegate.cropRect != cropRect ||
      oldDelegate.overlayColor != overlayColor ||
      oldDelegate.lineColor != lineColor;
}

class _CustomDrawingWidget extends HookConsumerWidget {
  const _CustomDrawingWidget({
    required this.viewPortSize,
    required this.image,
    required this.rotate,
    required this.flip,
  });

  final ui.Size viewPortSize;
  final ui.Image image;
  final ImageRotate rotate;
  final bool flip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transformedViewPortSize = rotate.apply(viewPortSize);
    final scale = math.min<double>(
        math.min(transformedViewPortSize.width / image.width,
            transformedViewPortSize.height / image.height),
        1);

    final scaledImageSize = Size(image.width * scale, image.height * scale);

    final editorBloc = context.read<_ImageEditorBloc>();

    final lines = useBlocStateConverter<_ImageEditorBloc, _ImageEditorState,
        List<CustomDrawLine>>(
      bloc: editorBloc,
      converter: (state) => state.drawLines,
    );

    Offset screenToImage(Offset position) {
      final center = viewPortSize.center(Offset.zero);
      final radius = rotate.radius;
      var transformedX = (position.dx - center.dx) * math.cos(radius) -
          (position.dy - center.dy) * math.sin(radius) +
          center.dx;
      final transformedY = (position.dx - center.dx) * math.sin(radius) +
          (position.dy - center.dy) * math.cos(radius) +
          center.dy;

      if (flip) {
        transformedX = viewPortSize.width - transformedX;
      }
      final imageTopLeft = center.translate(
          -scaledImageSize.width / 2, -scaledImageSize.height / 2);

      final transformed = Offset(
          transformedX - imageTopLeft.dx, transformedY - imageTopLeft.dy);
      return transformed / scale;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) {
        editorBloc.startDrawEvent(screenToImage(details.localPosition));
      },
      onPanUpdate: (details) {
        editorBloc.updateDrawEvent(screenToImage(details.localPosition));
      },
      onPanEnd: (details) => editorBloc.endDrawEvent(),
      child: OverflowBox(
        maxWidth: scaledImageSize.width,
        maxHeight: scaledImageSize.height,
        child: CustomPaint(
          size: scaledImageSize,
          painter: _DrawerPainter(
            image: image,
            lines: lines,
            scale: scale,
          ),
        ),
      ),
    );
  }
}

enum _ImageDragArea {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  center,
}

enum ImageRotate {
  none,
  quarter,
  half,
  threeQuarter,
}

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

Offset _rotate(Offset position, Offset center, double radius) => Offset(
      (position.dx - center.dx) * math.cos(radius) -
          (position.dy - center.dy) * math.sin(radius) +
          center.dx,
      (position.dx - center.dx) * math.sin(radius) +
          (position.dy - center.dy) * math.cos(radius) +
          center.dy,
    );

class _DrawerPainter extends CustomPainter {
  _DrawerPainter({
    required this.image,
    required this.lines,
    required this.scale,
  });

  final ui.Image image;

  final List<CustomDrawLine> lines;

  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    paintImage(canvas: canvas, rect: Offset.zero & size, image: image);

    canvas
      ..saveLayer(Offset.zero & size, Paint())
      ..clipRect(Offset.zero & size)
      ..translate(0, 0)
      ..scale(scale);
    for (final line in lines) {
      final paint = Paint()
        ..color = line.eraser ? Colors.white : line.color
        ..strokeWidth = line.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..blendMode = line.eraser ? BlendMode.clear : BlendMode.srcOver
        ..isAntiAlias = true;
      canvas.drawPath(line.path, paint);
    }
    canvas.restore();
  }

  @override
  bool? hitTest(ui.Offset position) => true;

  @override
  bool shouldRepaint(covariant _DrawerPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.lines != lines ||
      oldDelegate.scale != scale;
}

class _DrawColorSelector extends HookConsumerWidget {
  const _DrawColorSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCustomColor = useState(false);
    return SizedBox(
      height: 38,
      child: Material(
        color: context.theme.chatBackground,
        borderRadius: const BorderRadius.all(Radius.circular(62)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 2),
            _CustomColorTile(
              onTap: () => isCustomColor.value = !isCustomColor.value,
              selected: isCustomColor.value,
            ),
            if (!isCustomColor.value)
              for (final color in _kPresetColors) _NormalColorTile(color: color)
            else
              _CustomColorBar(onColorSelected: (Color color) {}),
            const SizedBox(width: 2),
          ],
        ),
      ),
    );
  }
}

const _kPresetColors = [
  Color(0xFFFFFFFF),
  Color(0xFF000000),
  Color(0xFF8E8E93),
  Color(0xFFE84D3D),
  Color(0xFFF8CD3E),
  Color(0xFF64D34F),
  Color(0xFF3077FF),
  Color(0xFFAC68DE),
];

const _kDefaultDrawColor = Color(0xFFE84D3D);

class _NormalColorTile extends HookConsumerWidget {
  const _NormalColorTile({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentColor =
        useBlocStateConverter<_ImageEditorBloc, _ImageEditorState, Color>(
      converter: (state) => state.drawColor,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkResponse(
        radius: 18,
        onTap: () {
          context.read<_ImageEditorBloc>().setCustomDrawColor(color);
        },
        child: SizedBox(
          width: 28,
          height: 28,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (currentColor == color)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: context.theme.accent, width: 2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              Center(
                child: SizedBox.square(
                  dimension: 21,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomColorTile extends StatelessWidget {
  const _CustomColorTile({
    required this.selected,
    required this.onTap,
  });

  final bool selected;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InkResponse(
          radius: 18,
          onTap: onTap,
          child: SizedBox(
            width: 28,
            height: 28,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (selected)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: context.theme.accent, width: 2),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                const Center(
                  child: SizedBox.square(
                    dimension: 21,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // background: conic-gradient(from 180deg at 50% 50%, #FF0000 0deg, #FF0000 4.38deg, #FC8700 30.55deg, #FAFF00 60.44deg, #BDFF00 97.21deg, #24FF00 124.99deg, #00F0FF 148.32deg, #00C2FF 176.19deg, #0047FF 216.25deg, #2400FF 254.25deg, #BD00FF 293.63deg, #FF007A 326.08deg, #FF0000 359.12deg, #FF0000 360deg, #FF0000 360deg);
                        gradient: SweepGradient(
                          transform: GradientRotation(math.pi / 2),
                          colors: [
                            Color(0xFFFF0000),
                            Color(0xFFFC8700),
                            Color(0xFFFAFF00),
                            Color(0xFFBDFF00),
                            Color(0xFF24FF00),
                            Color(0xFF00F0FF),
                            Color(0xFF00C2FF),
                            Color(0xFF0047FF),
                            Color(0xFF2400FF),
                            Color(0xFFBD00FF),
                            Color(0xFFFF007A),
                            Color(0xFFFF0000),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      );
}

class _CustomColorBar extends HookConsumerWidget {
  const _CustomColorBar({
    required this.onColorSelected,
  });

  final void Function(Color color) onColorSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initialHue = useMemoized(() {
      final color = context.read<_ImageEditorBloc>().state.drawColor;
      return HSLColor.fromColor(color).hue;
    });
    const maxSlideOffset = 256.0 - 12 - 9.0;
    final sliderOffset = useState<double>(initialHue / 360 * maxSlideOffset);

    Color sliderOffsetToColor(double offset) {
      final hue = (offset / maxSlideOffset) * 360;
      return HSLColor.fromAHSL(1, hue, 1, 0.5).toColor();
    }

    return Container(
      width: 256,
      padding: const EdgeInsets.only(left: 4, right: 8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            top: 8,
            bottom: 8,
            child: DecoratedBox(
                decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  for (var i = 0; i < 360; i++)
                    HSVColor.fromAHSV(1, i.toDouble(), 1, 1).toColor(),
                ],
              ),
              borderRadius: const BorderRadius.all(Radius.circular(22)),
            )),
          ),
          Positioned(
            left: sliderOffset.value,
            top: 4,
            width: 9,
            bottom: 4,
            child: GestureDetector(
              onPanUpdate: (details) {
                sliderOffset.value += details.delta.dx;
                if (sliderOffset.value < 0) {
                  sliderOffset.value = 0;
                } else if (sliderOffset.value > maxSlideOffset) {
                  sliderOffset.value = maxSlideOffset;
                }
                final color = sliderOffsetToColor(sliderOffset.value);
                onColorSelected(color);
                context.read<_ImageEditorBloc>().setCustomDrawColor(color);
              },
              child: Material(
                color: Colors.white,
                shadowColor: Colors.black.withOpacity(0.2),
                borderRadius: const BorderRadius.all(Radius.circular(58)),
                elevation: 4,
                child: const SizedBox(width: 9, height: 30),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _ResetButton extends HookConsumerWidget {
  const _ResetButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canReset =
        useBlocStateConverter<_ImageEditorBloc, _ImageEditorState, bool>(
      converter: (state) => state.canReset,
    );
    return SizedBox(
      height: 38,
      child: canReset
          ? TextButton(
              child: Text(context.l10n.reset),
              onPressed: () {
                context.read<_ImageEditorBloc>().reset();
              },
            )
          : null,
    );
  }
}

class _OperationButtons extends HookConsumerWidget {
  const _OperationButtons();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawMode =
        useBlocStateConverter<_ImageEditorBloc, _ImageEditorState, DrawMode>(
      converter: (state) => state.drawMode,
    );
    return Column(
      children: [
        if (drawMode != DrawMode.none)
          const _DrawColorSelector()
        else
          const _ResetButton(),
        const SizedBox(height: 8),
        if (drawMode != DrawMode.none)
          const _DrawOperationBar()
        else
          const _NormalOperationBar(),
      ],
    );
  }
}

class _NormalOperationBar extends HookConsumerWidget {
  const _NormalOperationBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imageEditorBloc = context.read<_ImageEditorBloc>();

    final rotated =
        useBlocStateConverter<_ImageEditorBloc, _ImageEditorState, bool>(
      converter: (state) => state.rotate != ImageRotate.none,
    );
    final flipped =
        useBlocStateConverter<_ImageEditorBloc, _ImageEditorState, bool>(
      converter: (state) => state.flip,
    );
    final hasCustomDraw =
        useBlocStateConverter<_ImageEditorBloc, _ImageEditorState, bool>(
      converter: (state) => state.drawLines.isNotEmpty,
    );
    final hasCrop =
        useBlocStateConverter<_ImageEditorBloc, _ImageEditorState, bool>(
            converter: (state) {
      final width = imageEditorBloc.image.width;
      final height = imageEditorBloc.image.height;
      return state.cropRect.width.round() != width ||
          state.cropRect.height.round() != height;
    });
    return Material(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      color: context.theme.stickerPlaceholderColor,
      child: SizedBox(
        height: 40,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () async {
                if (imageEditorBloc.state.canReset) {
                  final result = await showConfirmMixinDialog(
                    context,
                    context.l10n.editImageClearWarning,
                  );
                  if (result == null) return;
                }
                await Navigator.maybePop(context);
              },
              child: Text(
                context.l10n.cancel,
                style: TextStyle(color: context.theme.text),
              ),
            ),
            ActionButton(
              color: rotated ? context.theme.accent : context.theme.icon,
              name: Resources.assetsImagesEditImageRotateSvg,
              onTap: imageEditorBloc.rotate,
            ),
            const SizedBox(width: 4),
            ActionButton(
              color: flipped ? context.theme.accent : context.theme.icon,
              name: Resources.assetsImagesEditImageFlipSvg,
              onTap: imageEditorBloc.flip,
            ),
            const SizedBox(width: 4),
            PopupMenuPageButton(
              itemBuilder: (context) => [
                createPopupMenuItem(
                  title: context.l10n.originalImage,
                  value: null,
                  context: context,
                ),
                createPopupMenuItem(
                  title: '1:1',
                  value: 1,
                  context: context,
                ),
                createPopupMenuItem(
                  title: '2:3',
                  value: 2 / 3,
                  context: context,
                ),
                createPopupMenuItem(
                  title: '3:2',
                  value: 3 / 2,
                  context: context,
                ),
                createPopupMenuItem(
                  title: '3:4',
                  value: 3 / 4,
                  context: context,
                ),
                createPopupMenuItem(
                  title: '4:3',
                  value: 4 / 3,
                  context: context,
                ),
                createPopupMenuItem(
                  title: '9:16',
                  value: 9 / 16,
                  context: context,
                ),
                createPopupMenuItem(
                  title: '16:9',
                  value: 16 / 9,
                  context: context,
                ),
              ],
              onSelected: (value) {
                imageEditorBloc.setCropRatio(null);
              },
              icon: SvgPicture.asset(
                Resources.assetsImagesEditImageClipSvg,
                height: 24,
                width: 24,
                colorFilter: ColorFilter.mode(
                  hasCrop ? context.theme.accent : context.theme.icon,
                  BlendMode.srcIn,
                ),
              ),
            ),
            const SizedBox(width: 4),
            ActionButton(
              color: hasCustomDraw ? context.theme.accent : context.theme.icon,
              name: Resources.assetsImagesEditImageDrawSvg,
              onTap: () {
                context.read<_ImageEditorBloc>().enterDrawMode(DrawMode.brush);
              },
            ),
            TextButton(
              onPressed: () async {
                showToastLoading();
                final snapshot =
                    await context.read<_ImageEditorBloc>().takeSnapshot();
                if (snapshot == null) {
                  showToastFailed(null);
                  return;
                }
                Toast.dismiss();
                await Navigator.maybePop(context, snapshot);
              },
              child: Text(context.l10n.done),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawOperationBar extends HookConsumerWidget {
  const _DrawOperationBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawMode =
        useBlocStateConverter<_ImageEditorBloc, _ImageEditorState, DrawMode>(
      converter: (state) => state.drawMode,
    );
    final canRedo =
        useBlocStateConverter<_ImageEditorBloc, _ImageEditorState, bool>(
      converter: (state) => state.canRedo,
    );
    final canUndo =
        useBlocStateConverter<_ImageEditorBloc, _ImageEditorState, bool>(
      converter: (state) => state.drawLines.isNotEmpty,
    );
    return Material(
      borderRadius: const BorderRadius.all(Radius.circular(8)),
      color: context.theme.stickerPlaceholderColor,
      child: SizedBox(
        height: 40,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () {
                context.read<_ImageEditorBloc>().exitDrawingMode();
              },
              child: Text(
                context.l10n.cancel,
                style: TextStyle(color: context.theme.text),
              ),
            ),
            ActionButton(
              color: canUndo
                  ? context.theme.icon
                  : context.theme.icon.withOpacity(0.2),
              name: Resources.assetsImagesEditImageUndoSvg,
              onTap: () {
                context.read<_ImageEditorBloc>().undoDraw();
              },
            ),
            const SizedBox(width: 4),
            ActionButton(
              color: canRedo
                  ? context.theme.icon
                  : context.theme.icon.withOpacity(0.2),
              name: Resources.assetsImagesEditImageRedoSvg,
              onTap: () {
                context.read<_ImageEditorBloc>().redoDraw();
              },
            ),
            const SizedBox(width: 4),
            ActionButton(
              color: drawMode == DrawMode.brush
                  ? context.theme.accent
                  : context.theme.icon,
              name: Resources.assetsImagesEditImageDrawSvg,
              onTap: () {
                context.read<_ImageEditorBloc>().enterDrawMode(DrawMode.brush);
              },
            ),
            ActionButton(
              color: drawMode == DrawMode.eraser
                  ? context.theme.accent
                  : context.theme.icon,
              name: Resources.assetsImagesEditImageEraseSvg,
              onTap: () {
                context.read<_ImageEditorBloc>().enterDrawMode(DrawMode.eraser);
              },
            ),
            TextButton(
              onPressed: () {
                context
                    .read<_ImageEditorBloc>()
                    .exitDrawingMode(applyTempDraw: true);
              },
              child: Text(context.l10n.done),
            ),
          ],
        ),
      ),
    );
  }
}
