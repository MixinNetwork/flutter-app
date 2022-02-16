import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

import '../../../bloc/subscribe_mixin.dart';
import '../../../constants/resources.dart';
import '../../../utils/extension/extension.dart';
import '../../../utils/hook.dart';
import '../../../widgets/action_button.dart';

Future<void> showImageEditor(
  BuildContext context, {
  required String path,
}) async {
  await showDialog(
    context: context,
    builder: (context) => _ImageEditorDialog(path: path),
  );
}

class _ImageEditorDialog extends HookWidget {
  const _ImageEditorDialog({
    Key? key,
    required this.path,
  }) : super(key: key);

  final String path;

  @override
  Widget build(BuildContext context) {
    final boundaryKey = useMemoized(() => GlobalKey());
    return BlocProvider<_ImageEditorBloc>(
      create: (BuildContext context) => _ImageEditorBloc(path: path),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          color: context.theme.background.withOpacity(0.5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => _Preview(
                      path: path,
                      viewPortSize: constraints.biggest,
                      boundaryKey: boundaryKey,
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
  const CustomDrawLine(this.path, this.color, this.width);

  final Path path;
  final Color color;
  final double width;

  @override
  List<Object?> get props => [path, color, width];
}

class _ImageEditorState extends Equatable with EquatableMixin {
  const _ImageEditorState({
    required this.rotate,
    required this.flip,
    required this.customDrawing,
    required this.drawLines,
    required this.drawColor,
  });

  final _ImageRotate rotate;

  final bool flip;

  final bool customDrawing;

  final List<CustomDrawLine> drawLines;

  final Color drawColor;

  bool get canReset => rotate != _ImageRotate.none;

  @override
  List<Object?> get props => [
        rotate,
        flip,
        customDrawing,
        drawLines,
        drawColor,
      ];

  _ImageEditorState copyWith({
    _ImageRotate? rotate,
    bool? flip,
    bool? customDrawing,
    List<CustomDrawLine>? drawLines,
    Color? drawColor,
  }) =>
      _ImageEditorState(
        rotate: rotate ?? this.rotate,
        flip: flip ?? this.flip,
        customDrawing: customDrawing ?? this.customDrawing,
        drawLines: drawLines ?? this.drawLines,
        drawColor: drawColor ?? this.drawColor,
      );
}

class _ImageEditorBloc extends Cubit<_ImageEditorState> with SubscribeMixin {
  _ImageEditorBloc({
    required this.path,
  }) : super(const _ImageEditorState(
          rotate: _ImageRotate.none,
          flip: false,
          customDrawing: false,
          drawLines: [],
          drawColor: _kDefaultDrawColor,
        ));

  final String path;

  Path? _currentDrawingLine;

  final List<CustomDrawLine> _customDrawLines = [];

  final double _drawStrokeWidth = 11;

  void rotate() {
    _ImageRotate next() {
      switch (state.rotate) {
        case _ImageRotate.none:
          return _ImageRotate.quarter;
        case _ImageRotate.quarter:
          return _ImageRotate.half;
        case _ImageRotate.half:
          return _ImageRotate.threeQuarter;
        case _ImageRotate.threeQuarter:
          return _ImageRotate.none;
      }
    }

    emit(state.copyWith(rotate: next()));
  }

  void flip() {
    emit(state.copyWith(flip: !state.flip));
  }

  void enterDrawMode() {
    emit(state.copyWith(customDrawing: true));
  }

  void exitDrawingMode() {
    emit(state.copyWith(customDrawing: false));
  }

  void startDraw(Offset position) {
    _currentDrawingLine = Path()..moveTo(position.dx, position.dy);
    _notifyCustomDrawUpdated();
  }

  void updateDraw(Offset position) {
    assert(_currentDrawingLine != null, 'Drawing line is null');
    if (_currentDrawingLine == null) {
      return;
    }
    _currentDrawingLine!.lineTo(position.dx, position.dy);
    _notifyCustomDrawUpdated();
  }

  void endDraw() {
    final path = _currentDrawingLine;
    assert(path != null, 'Drawing line is null');
    if (path == null) {
      return;
    }
    final line = CustomDrawLine(
      path,
      state.drawColor,
      _drawStrokeWidth,
    );
    _currentDrawingLine = null;
    _customDrawLines.add(line);
    _notifyCustomDrawUpdated();
  }

  void _notifyCustomDrawUpdated() {
    if (_currentDrawingLine == null) {
      emit(state.copyWith(drawLines: _customDrawLines));
      return;
    }
    emit(state.copyWith(
      drawLines: [
        ..._customDrawLines,
        CustomDrawLine(
          Path.from(_currentDrawingLine!),
          state.drawColor,
          _drawStrokeWidth,
        )
      ],
    ));
  }

  void setCustomDrawColor(Color color) {
    emit(state.copyWith(drawColor: color));
  }
}

class _Preview extends HookWidget {
  const _Preview({
    Key? key,
    required this.path,
    required this.viewPortSize,
    required this.boundaryKey,
  }) : super(key: key);

  final String path;

  final Size viewPortSize;

  final Key boundaryKey;

  @override
  Widget build(BuildContext context) {
    final image = useMemoizedFuture<ui.Image?>(() async {
      final bytes = File(path).readAsBytesSync();
      final codec = await PaintingBinding.instance.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    }, null, keys: [path]);

    final editorState = useBlocState<_ImageEditorBloc, _ImageEditorState>();
    if (image.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }
    final imageData = image.data;
    if (imageData == null) {
      assert(false, 'imageData is null');
      return const SizedBox();
    }
    return SizedBox(
      width: viewPortSize.width,
      height: viewPortSize.height,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: viewPortSize.width,
            maxHeight: viewPortSize.height,
          ),
          child: RepaintBoundary(
            key: boundaryKey,
            child: AnimatedCrossFade(
              firstChild: CustomPaint(
                size: viewPortSize,
                painter: _PreviewPainter(
                  image: imageData,
                  editorState: editorState,
                ),
              ),
              secondChild: _CustomDrawingWidget(
                viewPortSize: viewPortSize,
                image: imageData,
              ),
              duration: const Duration(milliseconds: 200),
              crossFadeState: editorState.customDrawing
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
            ),
          ),
        ),
      ),
    );
  }
}

class _CustomDrawingWidget extends HookWidget {
  const _CustomDrawingWidget({
    Key? key,
    required this.viewPortSize,
    required this.image,
  }) : super(key: key);

  final ui.Size viewPortSize;
  final ui.Image image;

  @override
  Widget build(BuildContext context) {
    final scale = math.min<double>(
        math.min(viewPortSize.width / image.width,
            viewPortSize.height / image.height),
        1);

    final imageRect = useMemoized(() {
      final center = viewPortSize.center(Offset.zero);
      return Rect.fromCenter(
        center: center,
        width: image.width * scale,
        height: image.height * scale,
      );
    }, [viewPortSize, image]);

    final editorBloc = context.read<_ImageEditorBloc>();

    final lines = useBlocStateConverter<_ImageEditorBloc, _ImageEditorState,
        List<CustomDrawLine>>(
      bloc: editorBloc,
      converter: (state) => state.drawLines,
    );

    return GestureDetector(
      onPanStart: (details) {
        final relative = (details.localPosition - imageRect.topLeft) * scale;
        editorBloc.startDraw(relative);
      },
      onPanUpdate: (details) {
        final relative = (details.localPosition - imageRect.topLeft) * scale;
        editorBloc.updateDraw(relative);
      },
      onPanEnd: (details) => editorBloc.endDraw(),
      child: CustomPaint(
        size: viewPortSize,
        painter: _DrawerPainter(
          image: image,
          imageRect: imageRect,
          lines: lines,
          scale: scale,
        ),
      ),
    );
  }
}

enum _ImageRotate {
  none,
  quarter,
  half,
  threeQuarter,
}

class _DrawerPainter extends CustomPainter {
  _DrawerPainter({
    required this.image,
    required this.imageRect,
    required this.lines,
    required this.scale,
  });

  final ui.Image image;

  final Rect imageRect;

  final List<CustomDrawLine> lines;

  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    paintImage(canvas: canvas, rect: imageRect, image: image);

    canvas
      ..save()
      ..clipRect(imageRect)
      ..translate(imageRect.left, imageRect.top);
    for (final line in lines) {
      final paint = Paint()
        ..color = line.color
        ..strokeWidth = line.width * scale
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..isAntiAlias = true;
      canvas.drawPath(line.path, paint);
    }
    canvas.restore();
  }

  @override
  bool? hitTest(ui.Offset position) => imageRect.contains(position);

  @override
  bool shouldRepaint(covariant _DrawerPainter oldDelegate) =>
      oldDelegate.image != image ||
      oldDelegate.imageRect != imageRect ||
      oldDelegate.lines != lines ||
      oldDelegate.scale != scale;
}

class _PreviewPainter extends CustomPainter {
  _PreviewPainter({
    required this.image,
    required this.editorState,
  });

  final ui.Image image;

  final _ImageEditorState editorState;

  double get _canvasRadians {
    switch (editorState.rotate) {
      case _ImageRotate.none:
        return 0;
      case _ImageRotate.quarter:
        return math.pi / 2;
      case _ImageRotate.half:
        return math.pi;
      case _ImageRotate.threeQuarter:
        return 3 * math.pi / 2;
    }
  }

  bool get _imageRectRotated {
    switch (editorState.rotate) {
      case _ImageRotate.none:
        return false;
      case _ImageRotate.quarter:
      case _ImageRotate.threeQuarter:
        return true;
      case _ImageRotate.half:
        return false;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final imageWidth = _imageRectRotated ? image.height : image.width;
    final imageHeight = _imageRectRotated ? image.width : image.height;

    final scale = math.min<double>(
        math.min(size.width / imageWidth, size.height / imageHeight), 1);

    final imageOffset = Offset(
      (-image.width) / 2,
      (-image.height) / 2,
    );

    final center = size.center(Offset.zero);
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(_canvasRadians)
      ..scale(scale);
    if (editorState.flip) {
      canvas.scale(-1, 1);
    }
    canvas
      ..drawImage(image, imageOffset, Paint())
      ..translate(-center.dx, -center.dy)
      ..restore();
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter oldDelegate) =>
      oldDelegate.image != image || oldDelegate.editorState != editorState;
}

class _DrawColorSelector extends StatelessWidget {
  const _DrawColorSelector({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 38,
        child: Material(
          color: context.theme.chatBackground,
          borderRadius: BorderRadius.circular(62),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 2),
              // TODO custom color selector
              for (final color in _kPresetColors) _ColorTile(color: color),
              const SizedBox(width: 2),
            ],
          ),
        ),
      );
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

class _ColorTile extends HookWidget {
  const _ColorTile({Key? key, required this.color}) : super(key: key);

  final Color color;

  @override
  Widget build(BuildContext context) {
    final currentColor =
        useBlocStateConverter<_ImageEditorBloc, _ImageEditorState, Color>(
      converter: (state) => state.drawColor,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkResponse(
        radius: 24,
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

class _OperationButtons extends HookWidget {
  const _OperationButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final editorState = useBlocState<_ImageEditorBloc, _ImageEditorState>();
    final isDrawing =
        useBlocStateConverter<_ImageEditorBloc, _ImageEditorState, bool>(
      converter: (state) => state.customDrawing,
    );
    return Column(
      children: [
        if (isDrawing)
          const _DrawColorSelector()
        else
          const SizedBox(height: 38),
        const SizedBox(height: 8),
        Material(
          borderRadius: BorderRadius.circular(8),
          color: context.theme.chatBackground,
          child: SizedBox(
            height: 40,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.maybePop(context);
                  },
                  child: Text(context.l10n.cancel),
                ),
                ActionButton(
                  color: editorState.rotate != _ImageRotate.none
                      ? context.theme.accent
                      : context.theme.secondaryText,
                  name: Resources.assetsImagesEditImageRotateSvg,
                  onTap: () => context.read<_ImageEditorBloc>().rotate(),
                ),
                const SizedBox(width: 4),
                ActionButton(
                  color: editorState.flip
                      ? context.theme.accent
                      : context.theme.secondaryText,
                  name: Resources.assetsImagesEditImageFlipSvg,
                  onTap: () => context.read<_ImageEditorBloc>().flip(),
                ),
                const SizedBox(width: 4),
                ActionButton(
                  color: editorState.flip
                      ? context.theme.accent
                      : context.theme.secondaryText,
                  name: Resources.assetsImagesEditImageClipSvg,
                  onTap: () {},
                ),
                ActionButton(
                  color: editorState.flip
                      ? context.theme.accent
                      : context.theme.secondaryText,
                  name: Resources.assetsImagesEditImageDrawSvg,
                  onTap: () {
                    context.read<_ImageEditorBloc>().enterDrawMode();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
