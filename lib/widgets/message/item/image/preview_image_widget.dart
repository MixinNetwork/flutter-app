import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

class TransformImageController extends ChangeNotifier {
  _ImagPreviewWidgetState? _state;

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

  void zoomIn() {
    _state?._animateScale(1.2);
  }

  void zoomOut() {
    _state?._animateScale(0.8);
  }
}

// TODO extract as plugin.
class ImagPreviewWidget extends StatefulWidget {
  const ImagPreviewWidget({
    Key? key,
    required this.image,
    this.scale = 1,
    this.maxScale = 2.0,
    this.minScale = 0.5,
    this.controller,
  })  : assert(maxScale > scale),
        assert(minScale < scale),
        assert(maxScale > minScale),
        super(key: key);

  final Widget image;

  final double scale;
  final double maxScale;
  final double minScale;

  final TransformImageController? controller;

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

// Used as the coefficient of friction in the inertial translation animation.
// This value was eyeballed to give a feel similar to Google Photos.
const double _kDrag = 0.0000135;

class _ImagPreviewWidgetState extends State<ImagPreviewWidget>
    with TickerProviderStateMixin {
  final GlobalKey _childKey = GlobalKey();

  late TransformImageController _transformationController;

  late AnimationController _controller;

  Animation<Offset>? _animation;

  late AnimationController _scaleAnimationController;
  Animation<double>? _scaleAnimation;

  @override
  void initState() {
    super.initState();
    assert(widget.controller?._state == null);
    _transformationController = widget.controller ?? TransformImageController();
    _transformationController
      .._state = this
      ..scale = widget.scale
      ..addListener(_onTransformationControllerChange);
    _controller = AnimationController(vsync: this);
    _scaleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void didUpdateWidget(covariant ImagPreviewWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != null &&
        widget.controller != _transformationController) {
      assert(widget.controller?._state == null);
      _transformationController
        .._state = null
        ..removeListener(_onTransformationControllerChange);
      _transformationController = widget.controller!;
      _transformationController
        .._state = this
        ..scale = widget.scale
        ..addListener(_onTransformationControllerChange);
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scaleAnimationController.dispose();
    _transformationController
      .._state = null
      ..removeListener(_onTransformationControllerChange)
      ..dispose();
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
        // ignore rotate action.
        break;
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    _scaleStart = null;
    _focalPoint = null;

    _animation?.removeListener(_onTranslationAnimated);
    _controller.reset();

    if (_gestureType != _GestureType.pan ||
        details.velocity.pixelsPerSecond.distance < kMinFlingVelocity) {
      return;
    }

    final translation = _transformationController.translate;
    final fmx = FrictionSimulation(
        _kDrag, translation.dx, details.velocity.pixelsPerSecond.dx);
    final fmy = FrictionSimulation(
        _kDrag, translation.dy, details.velocity.pixelsPerSecond.dy);

    final toFinal = _getFinalTime(
      details.velocity.pixelsPerSecond.distance,
      _kDrag,
    );

    var deltaTranslation =
        Offset(fmx.finalX, fmy.finalX) - _transformationController.translate;
    deltaTranslation = _transformedChildRect.ensureEdgeNotInViewport(
        _viewport, deltaTranslation);
    if (deltaTranslation.distanceSquared == 0) {
      // no translation.
      return;
    }
    _animation = Tween<Offset>(
      begin: translation,
      end: _transformationController.translate + deltaTranslation,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.decelerate,
    ));
    _controller.duration = Duration(milliseconds: (toFinal * 1000).round());
    _animation!.addListener(_onTranslationAnimated);
    _controller.forward();
  }

  void _onTranslationAnimated() {
    if (!_controller.isAnimating) {
      _animation?.removeListener(_onTranslationAnimated);
      _animation = null;
      _controller.reset();
      return;
    }
    _transformationController.translate = _animation!.value;
  }

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

  void _onTransformationControllerChange() {
    // A change to the TransformationController's value is a change to the
    // state.
    setState(() {});
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

    _applyScale(scaleChange, event.localPosition);
  }

  void _applyScale(double scaleChange, Offset point) {
    final viewport = _viewport;
    final childRect = _childRect;

    final targetScale = (_transformationController.scale * scaleChange)
        .clamp(widget.minScale, widget.maxScale);

    // Zoom out, but has translation. we need check if scaled child rect should
    // be centering in the viewport.
    if (scaleChange < 1 &&
        _transformationController.translate.distanceSquared > 0) {
      final nextRect = _calculateTransformedChildRect(
        childRect: childRect,
        translate: _transformationController.translate,
        scale: targetScale,
      );

      final focusPoint = _toScene(point);
      if (childRect.contains(focusPoint)) {
        final next = _toScene(point, scale: targetScale);
        final offset = (next - focusPoint) * _transformationController.scale;
        _transformationController.translate += offset;
      }

      // NOTE: can not replace with nextRect.size <= viewport.size,
      // because:
      // Size(10, 9) <= Size(11, 8)  false
      // Size(10, 9) >= Size(11, 8)  false
      if (!(nextRect.size > viewport.size)) {
        _transformationController.translate = Offset.zero;
      } else {
        assert(nextRect.size > viewport.size);
        final offset = nextRect.offsetToContain(viewport);
        if (offset.distanceSquared > 0) {
          _transformationController.translate +=
              offset * _transformationController.scale;
        }
      }
    }

    if (scaleChange > 1) {
      final nextRect = _calculateTransformedChildRect(
        childRect: childRect,
        translate: _transformationController.translate,
        scale: targetScale,
      );

      if (!(nextRect.size > viewport.size)) {
        _transformationController.translate = Offset.zero;
      } else {
        final focusPoint = _toScene(point);
        if (childRect.contains(focusPoint)) {
          final next = _toScene(point, scale: targetScale);
          final offset = (next - focusPoint) * _transformationController.scale;
          _transformationController.translate += offset;
        }
      }
    }

    _transformationController.scale = targetScale;
  }

  void _onScaleAnimated() {
    if (!_scaleAnimationController.isAnimating) {
      _scaleAnimation?.removeListener(_onScaleAnimated);
      _scaleAnimationController.reset();
      return;
    }
    final scale = _scaleAnimation!.value;
    _applyScale(scale / _transformationController.scale, _viewport.center);
  }

  void _animateScale(double scaleChange) {
    assert(scaleChange > 0);

    final targetScale = (_transformationController.scale * scaleChange)
        .clamp(widget.minScale, widget.maxScale);

    _scaleAnimation?.removeListener(_onScaleAnimated);
    _scaleAnimationController.reset();

    _scaleAnimation = Tween<double>(
      begin: _transformationController.scale,
      end: targetScale,
    ).animate(CurvedAnimation(
      parent: _scaleAnimationController,
      curve: Curves.easeInOut,
    ));
    _scaleAnimation!.addListener(_onScaleAnimated);
    _scaleAnimationController.forward();
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
              child: KeyedSubtree(
                key: _childKey,
                child: widget.image,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

extension _RectExtension on Rect {
  Offset offsetToContain(Rect viewport) {
    assert(size > viewport.size);
    final double dx;
    if (left > viewport.left) {
      dx = viewport.left - left;
    } else if (right < viewport.right) {
      dx = viewport.right - right;
    } else {
      dx = 0;
    }
    final double dy;
    if (top > viewport.top) {
      dy = viewport.top - top;
    } else if (bottom < viewport.bottom) {
      dy = viewport.bottom - bottom;
    } else {
      dy = 0;
    }
    return Offset(dx, dy);
  }

  Offset ensureEdgeNotInViewport(Rect viewport, Offset offset) {
    var computedOffset = Offset.zero;

    // The left part of child is not fully displayed and move child to right.
    if (left <= viewport.left && offset.dx > 0) {
      // move to right
      computedOffset = Offset(
        math.min(viewport.left - left, offset.dx),
        computedOffset.dy,
      );
    }

    // The right part of child is not fully displayed and move child to left.
    if (right >= viewport.right && offset.dx < 0) {
      computedOffset = Offset(
        math.max(viewport.right - right, offset.dx),
        computedOffset.dy,
      );
    }

    // The top part of child is not fully displayed and move child to bottom.
    if (top <= viewport.top && offset.dy > 0) {
      computedOffset = Offset(
        computedOffset.dx,
        math.min(viewport.top - top, offset.dy),
      );
    }

    // The bottom part of child is not fully displayed and move child to top.
    if (bottom >= viewport.bottom && offset.dy < 0) {
      computedOffset = Offset(
        computedOffset.dx,
        math.max(viewport.bottom - bottom, offset.dy),
      );
    }
    return computedOffset;
  }
}

// calculate the scale to a, so a can fit in b.
double _fitScale(Size a, Size b) =>
    math.min(b.width / a.width, b.height / b.height);

// Given a velocity and drag, calculate the time at which motion will come to
// a stop, within the margin of effectivelyMotionless.
double _getFinalTime(double velocity, double drag) {
  const effectivelyMotionless = 10.0;
  return math.log(effectivelyMotionless / velocity) / math.log(drag / 100);
}
