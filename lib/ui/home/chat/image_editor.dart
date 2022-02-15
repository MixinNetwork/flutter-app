import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
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

class _ImageEditorState extends Equatable with EquatableMixin {
  const _ImageEditorState({
    required this.rotate,
    required this.flip,
  });

  final _ImageRotate rotate;

  final bool flip;

  bool get canReset => rotate != _ImageRotate.none;

  @override
  List<Object?> get props => [rotate, flip];

  _ImageEditorState copyWith({
    _ImageRotate? rotate,
    bool? flip,
  }) =>
      _ImageEditorState(
        rotate: rotate ?? this.rotate,
        flip: flip ?? this.flip,
      );
}

class _ImageEditorBloc extends Cubit<_ImageEditorState> with SubscribeMixin {
  _ImageEditorBloc({
    required this.path,
  }) : super(const _ImageEditorState(
          rotate: _ImageRotate.none,
          flip: false,
        ));

  final String path;

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
            child: CustomPaint(
              size: viewPortSize,
              painter: _PreviewPainter(
                image: imageData,
                editorState: editorState,
              ),
            ),
          ),
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

class _OperationButtons extends HookWidget {
  const _OperationButtons({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final editorState = useBlocState<_ImageEditorBloc, _ImageEditorState>();
    return Material(
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
            ActionButton(
              color: editorState.flip
                  ? context.theme.accent
                  : context.theme.secondaryText,
              name: Resources.assetsImagesEditImageFlipSvg,
              onTap: () => context.read<_ImageEditorBloc>().flip(),
            ),
          ],
        ),
      ),
    );
  }
}
