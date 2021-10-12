import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app/utils/logger.dart';

class _TransformImageController extends ChangeNotifier {
  double _scale = 1;

  double get scale => _scale;

  set scale(double scale) {
    if (_scale == scale) {
      return;
    }
    _scale = scale;
    notifyListeners();
  }

  Offset _translate = Offset.zero;

  Offset get translate => _translate;

  set translate(Offset translate) {
    if (_translate == translate) {
      return;
    }
    _translate = translate;
    notifyListeners();
  }
}

// TODO extract as plugin.
class ImagPreviewWidget extends StatefulWidget {
  const ImagPreviewWidget({
    Key? key,
    required this.image,
    this.initialScale,
  }) : super(key: key);

  final Widget image;

  final double? initialScale;

  @override
  State<ImagPreviewWidget> createState() => _ImagPreviewWidgetState();
}

// A classification of relevant user gestures. Each contiguous user gesture is
// represented by exactly one _GestureType.
enum _GestureType {
  pan,
  scale,
  rotate,
}

const _rotateEnabled = false;
const _scaleEnabled = true;

class _ImagPreviewWidgetState extends State<ImagPreviewWidget>
    with TickerProviderStateMixin {
  final GlobalKey _childKey = GlobalKey();

  final _transformationController = _TransformImageController();

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    if (widget.initialScale != null) {
      debugPrint('initialScale: ${widget.initialScale}');
      _transformationController.scale = widget.initialScale!;
    }
    _transformationController.addListener(_onTransformationControllerChange);
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationControllerChange);
    super.dispose();
  }

  // The Rect representing the child's parent.
  Rect get _viewport {
    final parentRenderBox = context.findRenderObject()! as RenderBox;
    return Offset.zero & parentRenderBox.size;
  }

  // The rect of child
  Rect get _childRect {
    assert(_childKey.currentContext != null);
    final childRenderBox =
        _childKey.currentContext!.findRenderObject()! as RenderBox;
    return Offset.zero & childRenderBox.size;
  }

  Rect get _transformedChildRect => _calculateTransformedChildRect(
        childRect: _childRect,
        translate: _transformationController.translate,
        scale: _transformationController.scale,
      );

  Rect _calculateTransformedChildRect({
    required Rect childRect,
    required Offset translate,
    required double scale,
  }) {
    final size = childRect.size * scale;
    return Rect.fromCenter(
            center: _viewport.center, width: size.width, height: size.height)
        .shift(translate);
  }

  Offset _calculateToScene(
      Offset viewportPoint, Offset translate, double scale) {
    final scaledPoint = (viewportPoint - _viewport.center - translate) / scale;
    return scaledPoint + _childRect.center;
  }

  // convert point in viewport to Scene.
  Offset _toScene(Offset viewportPoint, {Offset? translate, double? scale}) =>
      _calculateToScene(
        viewportPoint,
        translate ?? _transformationController.translate,
        scale ?? _transformationController.scale,
      );

  // Point where the current gesture began.
  Offset? _focalPoint;

  double? _scaleStart; // Scale value at start of scaling gesture.
  _GestureType? _gestureType;

  void _onScaleStart(ScaleStartDetails details) {
    _scaleStart = _transformationController.scale;
    _gestureType = null;
    _focalPoint = details.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final scale = _transformationController.scale;
    if (_gestureType == _GestureType.pan) {
      _gestureType = _getGestureType(details);
    } else {
      _gestureType ??= _getGestureType(details);
    }

    final focalPoint = details.localFocalPoint;

    switch (_gestureType!) {
      case _GestureType.pan:
        final offset = focalPoint - _focalPoint!;
        _focalPoint = focalPoint;

        final childRect = _transformedChildRect;
        final viewport = _viewport;

        var computedOffset = Offset.zero;

        // The left part of child is not fully displayed and move child to right.
        if (childRect.left <= viewport.left && offset.dx > 0) {
          // move to right
          computedOffset = Offset(
            math.min(viewport.left - childRect.left, offset.dx),
            computedOffset.dy,
          );
        }

        // The right part of child is not fully displayed and move child to left.
        if (childRect.right >= viewport.right && offset.dx < 0) {
          computedOffset = Offset(
            math.max(viewport.right - childRect.right, offset.dx),
            computedOffset.dy,
          );
        }

        // The top part of child is not fully displayed and move child to bottom.
        if (childRect.top <= viewport.top && offset.dy > 0) {
          computedOffset = Offset(
            computedOffset.dx,
            math.min(viewport.top - childRect.top, offset.dy),
          );
        }

        // The bottom part of child is not fully displayed and move child to top.
        if (childRect.bottom >= viewport.bottom && offset.dy < 0) {
          computedOffset = Offset(
            computedOffset.dx,
            math.max(viewport.bottom - childRect.bottom, offset.dy),
          );
        }

        _transformationController.translate += computedOffset;
        break;
      case _GestureType.scale:
        break;
      case _GestureType.rotate:
        break;
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {}

  // Decide which type of gesture this is by comparing the amount of scale
  // and rotation in the gesture, if any. Scale starts at 1 and rotation
  // starts at 0. Pan will have no scale and no rotation because it uses only one
  // finger.
  _GestureType _getGestureType(ScaleUpdateDetails details) {
    final scale = _scaleEnabled ? details.scale : 1.0;
    final rotation = !_rotateEnabled ? 0.0 : details.rotation;
    if ((scale - 1).abs() > rotation.abs()) {
      return _GestureType.scale;
    } else if (rotation != 0.0) {
      return _GestureType.rotate;
    } else {
      return _GestureType.pan;
    }
  }

  Offset? _centerTest;

  void _onTransformationControllerChange() {
    // A change to the TransformationController's value is a change to the
    // state.
    setState(() {});
    _centerTest = _toScene(_viewport.center);
  }

  // Handle mousewheel scroll events.
  void _receivedPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) {
      return;
    }
    // Ignore left and right scroll.
    if (event.scrollDelta.dy == 0.0) {
      return;
    }

    // In the Flutter engine, the mousewheel scrollDelta is hardcoded to 20
    // per scroll, while a trackpad scroll can be any amount. The calculation
    // for scaleChange here was arbitrarily chosen to feel natural for both
    // trackpads and mousewheels on all platforms.
    final scaleChange = math.exp(-event.scrollDelta.dy / 200);

    final viewport = _viewport;
    final childRect = _childRect;

    final scaleToFit = _fitScale(childRect.size, viewport.size) /
        _transformationController.scale;

    //  ensure child rect in center when scaling down.
    if (scaleChange < 1 &&
        _transformationController.translate.distanceSquared > 0) {
      var translateChange = math.log(scaleChange) / math.log(scaleToFit);

      if (translateChange >= 0.1) {
        if (scaleChange > scaleToFit) {
          d('translateChange = $translateChange');
          translateChange = math.sqrt(translateChange);
          _transformationController.translate -=
              _transformationController.translate *
                  math.min<double>(translateChange, 1);
        } else {
          _transformationController.translate = Offset.zero;
        }
      } else {
        var focusPoint = _toScene(event.localPosition);
        if (childRect.contains(focusPoint)) {
          final next = _toScene(
            event.localPosition,
            scale: _transformationController.scale * scaleChange,
          );
          final offset = (next - focusPoint) * _transformationController.scale;
          _transformationController.translate += offset;
        }
      }
    }

    if (scaleChange > 1) {
      final focusPoint = _toScene(event.localPosition);
      if (childRect.contains(focusPoint)) {
        final next = _toScene(
          event.localPosition,
          scale: _transformationController.scale * scaleChange,
        );
        final offset = (next - focusPoint) * _transformationController.scale;
        _transformationController.translate += offset;
      }
    }

    _transformationController.scale *= scaleChange;
  }

  @override
  Widget build(BuildContext context) {
    final matrix = Matrix4.identity()
      ..leftTranslate(
        _transformationController.translate.dx,
        _transformationController.translate.dy,
      )
      ..scale(_transformationController.scale);

    return RepaintBoundary(
      child: Listener(
        onPointerSignal: _receivedPointerSignal,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: _onScaleStart,
          onScaleUpdate: _onScaleUpdate,
          onScaleEnd: _onScaleEnd,
          child: Transform(
            transform: matrix,
            alignment: Alignment.center,
            child: OverflowBox(
              minWidth: 0,
              minHeight: 0,
              maxWidth: double.infinity,
              maxHeight: double.infinity,
              child: Stack(
                children: [
                  KeyedSubtree(
                    key: _childKey,
                    child: widget.image,
                  ),
                  // if (_centerTest != null)
                  //   Padding(
                  //     padding: EdgeInsets.only(
                  //         left: _centerTest!.dx, top: _centerTest!.dy),
                  //     child: Container(
                  //       width: 10,
                  //       height: 10,
                  //       color: Colors.redAccent,
                  //     ),
                  //   )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// calculate the scale to a, so a can fit in b.
double _fitScale(Size a, Size b) =>
    math.min(b.width / a.width, b.height / b.height);

Offset _nearestPointInRect(Rect rect, Offset point) => Offset(
    point.dx.clamp(rect.left, rect.right),
    point.dy.clamp(rect.top, rect.bottom));
