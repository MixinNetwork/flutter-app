import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class ClampingViewport extends Viewport {
  ClampingViewport({
    super.key,
    super.axisDirection,
    super.crossAxisDirection,
    double anchor = 0.0,
    required super.offset,
    super.center,
    super.cacheExtent,
    super.slivers,
  }) : _anchor = anchor;

  final double _anchor;

  @override
  double get anchor => _anchor;

  @override
  RenderViewport createRenderObject(BuildContext context) =>
      ClampingRenderViewport(
        axisDirection: axisDirection,
        crossAxisDirection: crossAxisDirection ??
            Viewport.getDefaultCrossAxisDirection(context, axisDirection),
        anchor: anchor,
        offset: offset,
        cacheExtent: cacheExtent,
        cacheExtentStyle: cacheExtentStyle,
        clipBehavior: clipBehavior,
      );

  @override
  void updateRenderObject(BuildContext context, RenderViewport renderObject) {
    renderObject
      ..axisDirection = axisDirection
      ..crossAxisDirection = crossAxisDirection ??
          Viewport.getDefaultCrossAxisDirection(context, axisDirection)
      ..anchor = anchor
      ..offset = offset
      ..cacheExtent = cacheExtent
      ..cacheExtentStyle = cacheExtentStyle
      ..clipBehavior = clipBehavior;
  }
}

// Differences from [RenderViewport] are marked with a //***** Differences
// comment.
class ClampingRenderViewport extends RenderViewport {
  /// Creates a viewport for [RenderSliver] objects.
  ///
  /// If the [center] is not specified, then the first child in the `children`
  /// list, if any, is used.
  ///
  /// The [offset] must be specified. For testing purposes, consider passing a
  /// [ViewportOffset.zero] or [ViewportOffset.fixed].
  ClampingRenderViewport({
    super.axisDirection,
    required super.crossAxisDirection,
    required super.offset,
    double anchor = 0.0,
    List<RenderSliver>? children,
    RenderSliver? center,
    super.cacheExtent,
    super.cacheExtentStyle,
    super.clipBehavior = Clip.antiAlias,
  })  : assert(anchor >= 0.0 && anchor <= 1.0),
        assert(cacheExtentStyle != CacheExtentStyle.viewport ||
            cacheExtent != null),
        _anchor = anchor,
        _center = center {
    addAll(children);
    if (center == null && firstChild != null) _center = firstChild;
  }

  double? _calculatedCacheExtent;

  // diff start
  double _correctedOffset = 0;
  double? _lastMainAxisExtent;
  bool _isMaxScrollPixel = false;

  // diff end

  /// If a [RenderAbstractViewport] overrides
  /// [RenderObject.describeSemanticsConfiguration] to add the [SemanticsTag]
  /// [useTwoPaneSemantics] to its [SemanticsConfiguration], two semantics nodes
  /// will be used to represent the viewport with its associated scrolling
  /// actions in the semantics tree.
  ///
  /// Two semantics nodes (an inner and an outer node) are necessary to exclude
  /// certain child nodes (via the [excludeFromScrolling] tag) from the
  /// scrollable area for semantic purposes: The [SemanticsNode]s of children
  /// that should be excluded from scrolling will be attached to the outer node.
  /// The semantic scrolling actions and the [SemanticsNode]s of scrollable
  /// children will be attached to the inner node, which itself is a child of
  /// the outer node.
  ///
  /// See also:
  ///
  /// * [RenderViewportBase.describeSemanticsConfiguration], which adds this
  ///   tag to its [SemanticsConfiguration].
  static const SemanticsTag useTwoPaneSemantics =
      SemanticsTag('RenderViewport.twoPane');

  /// When a top-level [SemanticsNode] below a [RenderAbstractViewport] is
  /// tagged with [excludeFromScrolling] it will not be part of the scrolling
  /// area for semantic purposes.
  ///
  /// This behavior is only active if the [RenderAbstractViewport]
  /// tagged its [SemanticsConfiguration] with [useTwoPaneSemantics].
  /// Otherwise, the [excludeFromScrolling] tag is ignored.
  ///
  /// As an example, a [RenderSliver] that stays on the screen within a
  /// [Scrollable] even though the user has scrolled past it (e.g. a pinned app
  /// bar) can tag its [SemanticsNode] with [excludeFromScrolling] to indicate
  /// that it should no longer be considered for semantic actions related to
  /// scrolling.
  static const SemanticsTag excludeFromScrolling =
      SemanticsTag('RenderViewport.excludeFromScrolling');

  @override
  void setupParentData(RenderObject child) {
    if (child.parentData is! SliverPhysicalContainerParentData) {
      child.parentData = SliverPhysicalContainerParentData();
    }
  }

  /// The relative position of the zero scroll offset.
  ///
  /// For example, if [anchor] is 0.5 and the [axisDirection] is
  /// [AxisDirection.down] or [AxisDirection.up], then the zero scroll offset is
  /// vertically centered within the viewport. If the [anchor] is 1.0, and the
  /// [axisDirection] is [AxisDirection.right], then the zero scroll offset is
  /// on the left edge of the viewport.
  @override
  double get anchor => _anchor;
  double _anchor;

  @override
  set anchor(double value) {
    assert(value >= 0.0 && value <= 1.0);
    if (value == _anchor) return;
    _anchor = value;
    markNeedsLayout();
  }

  /// The first child in the [GrowthDirection.forward] growth direction.
  ///
  /// This child that will be at the position defined by [anchor] when the
  /// [ViewportOffset.pixels] of [offset] is `0`.
  ///
  /// Children after [center] will be placed in the [axisDirection] relative to
  /// the [center]. Children before [center] will be placed in the opposite of
  /// the [axisDirection] relative to the [center].
  ///
  /// The [center] must be a child of the viewport.
  @override
  RenderSliver? get center => _center;
  RenderSliver? _center;

  @override
  set center(RenderSliver? value) {
    if (value == _center) return;
    _center = value;
    markNeedsLayout();
  }

  @override
  bool get sizedByParent => true;

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    assert(() {
      if (!constraints.hasBoundedHeight || !constraints.hasBoundedWidth) {
        switch (axis) {
          case Axis.vertical:
            if (!constraints.hasBoundedHeight) {
              throw FlutterError.fromParts(<DiagnosticsNode>[
                ErrorSummary('Vertical viewport was given unbounded height.'),
                ErrorDescription(
                  'Viewports expand in the scrolling direction to fill their container. '
                  'In this case, a vertical viewport was given an unlimited amount of '
                  'vertical space in which to expand. This situation typically happens '
                  'when a scrollable widget is nested inside another scrollable widget.',
                ),
                ErrorHint(
                  'If this widget is always nested in a scrollable widget there '
                  'is no need to use a viewport because there will always be enough '
                  'vertical space for the children. In this case, consider using a '
                  'Column instead. Otherwise, consider using the "shrinkWrap" property '
                  '(or a ShrinkWrappingViewport) to size the height of the viewport '
                  'to the sum of the heights of its children.',
                ),
              ]);
            }
            if (!constraints.hasBoundedWidth) {
              throw FlutterError(
                'Vertical viewport was given unbounded width.\n'
                'Viewports expand in the cross axis to fill their container and '
                'constrain their children to match their extent in the cross axis. '
                'In this case, a vertical viewport was given an unlimited amount of '
                'horizontal space in which to expand.',
              );
            }
            break;
          case Axis.horizontal:
            if (!constraints.hasBoundedWidth) {
              throw FlutterError.fromParts(<DiagnosticsNode>[
                ErrorSummary('Horizontal viewport was given unbounded width.'),
                ErrorDescription(
                  'Viewports expand in the scrolling direction to fill their container. '
                  'In this case, a horizontal viewport was given an unlimited amount of '
                  'horizontal space in which to expand. This situation typically happens '
                  'when a scrollable widget is nested inside another scrollable widget.',
                ),
                ErrorHint(
                  'If this widget is always nested in a scrollable widget there '
                  'is no need to use a viewport because there will always be enough '
                  'horizontal space for the children. In this case, consider using a '
                  'Row instead. Otherwise, consider using the "shrinkWrap" property '
                  '(or a ShrinkWrappingViewport) to size the width of the viewport '
                  'to the sum of the widths of its children.',
                ),
              ]);
            }
            if (!constraints.hasBoundedHeight) {
              throw FlutterError(
                'Horizontal viewport was given unbounded height.\n'
                'Viewports expand in the cross axis to fill their container and '
                'constrain their children to match their extent in the cross axis. '
                'In this case, a horizontal viewport was given an unlimited amount of '
                'vertical space in which to expand.',
              );
            }
            break;
        }
      }
      return true;
    }());
    return constraints.biggest;
  }

  static const int _maxLayoutCycles = 10;

  // Out-of-band data computed during layout.
  late double _minScrollExtent;
  late double _maxScrollExtent;
  bool _hasVisualOverflow = false;

  @override
  void performLayout() {
    // Ignore the return value of applyViewportDimension because we are
    // doing a layout regardless.
    switch (axis) {
      case Axis.vertical:
        offset.applyViewportDimension(size.height);
        break;
      case Axis.horizontal:
        offset.applyViewportDimension(size.width);
        break;
    }

    if (center == null) {
      assert(firstChild == null);
      _minScrollExtent = 0.0;
      _maxScrollExtent = 0.0;
      _hasVisualOverflow = false;
      offset.applyContentDimensions(0, 0);
      return;
    }
    assert(center!.parent == this);

    final double mainAxisExtent;
    final double crossAxisExtent;
    switch (axis) {
      case Axis.vertical:
        mainAxisExtent = size.height;
        crossAxisExtent = size.width;
        break;
      case Axis.horizontal:
        mainAxisExtent = size.width;
        crossAxisExtent = size.height;
        break;
    }

    final centerOffsetAdjustment = center!.centerOffsetAdjustment;

    double correction;
    var count = 0;
    do {
      correction = _attemptLayout(mainAxisExtent, crossAxisExtent,
          offset.pixels + centerOffsetAdjustment + _correctedOffset);
      if (correction != 0.0) {
        offset.correctBy(correction);
      } else {
        // diff start
        count += 1;

        final top =
            _minScrollExtent + mainAxisExtent * anchor - _correctedOffset;
        final bottom = _maxScrollExtent -
            mainAxisExtent * (1.0 - anchor) -
            _correctedOffset;
        final minScrollExtent = math.min(0, top).toDouble();
        final maxScrollExtent = math.max(0, bottom).toDouble();

        if (top > 0.0) {
          _correctedOffset = (mainAxisExtent * anchor) + _minScrollExtent;
          continue;
        }

        final scrollExtent = _maxScrollExtent - _minScrollExtent;

        if (mainAxisExtent > scrollExtent) {
          if (((mainAxisExtent - scrollExtent) - (-bottom - offset.pixels)) <
              0) {
            _correctedOffset = bottom;
            continue;
          }
        } else {
          if (bottom != 0 && bottom - offset.pixels < 0) {
            _correctedOffset += bottom;
            continue;
          }
        }

        if (_isMaxScrollPixel &&
            _lastMainAxisExtent != null &&
            _lastMainAxisExtent != mainAxisExtent) {
          offset.correctBy(maxScrollExtent - offset.pixels);
          _isMaxScrollPixel = offset.pixels == maxScrollExtent;
          _lastMainAxisExtent = mainAxisExtent;
          continue;
        }

        if (offset.applyContentDimensions(
          minScrollExtent,
          maxScrollExtent,
        )) {
          _isMaxScrollPixel = offset.pixels == maxScrollExtent;
          _lastMainAxisExtent = mainAxisExtent;
          break;
        }
        // diff end
      }
    } while (count < _maxLayoutCycles);
    assert(() {
      if (count >= _maxLayoutCycles) {
        assert(count != 1);
        throw FlutterError(
          'A RenderViewport exceeded its maximum number of layout cycles.\n'
          'RenderViewport render objects, during layout, can retry if either their '
          'slivers or their ViewportOffset decide that the offset should be corrected '
          'to take into account information collected during that layout.\n'
          'In the case of this RenderViewport object, however, this happened $count '
          'times and still there was no consensus on the scroll offset. This usually '
          'indicates a bug. Specifically, it means that one of the following three '
          'problems is being experienced by the RenderViewport object:\n'
          ' * One of the RenderSliver children or the ViewportOffset have a bug such'
          ' that they always think that they need to correct the offset regardless.\n'
          ' * Some combination of the RenderSliver children and the ViewportOffset'
          ' have a bad interaction such that one applies a correction then another'
          ' applies a reverse correction, leading to an infinite loop of corrections.\n'
          ' * There is a pathological case that would eventually resolve, but it is'
          ' so complicated that it cannot be resolved in any reasonable number of'
          ' layout passes.',
        );
      }
      return true;
    }());
  }

  double _attemptLayout(
      double mainAxisExtent, double crossAxisExtent, double correctedOffset) {
    assert(!mainAxisExtent.isNaN);
    assert(mainAxisExtent >= 0.0);
    assert(crossAxisExtent.isFinite);
    assert(crossAxisExtent >= 0.0);
    assert(correctedOffset.isFinite);
    _minScrollExtent = 0.0;
    _maxScrollExtent = 0.0;
    _hasVisualOverflow = false;

    // centerOffset is the offset from the leading edge of the RenderViewport
    // to the zero scroll offset (the line between the forward slivers and the
    // reverse slivers).
    final centerOffset = mainAxisExtent * anchor - correctedOffset;
    final reverseDirectionRemainingPaintExtent =
        centerOffset.clamp(0.0, mainAxisExtent);
    final forwardDirectionRemainingPaintExtent =
        (mainAxisExtent - centerOffset).clamp(0.0, mainAxisExtent);

    switch (cacheExtentStyle) {
      case CacheExtentStyle.pixel:
        _calculatedCacheExtent = cacheExtent;
        break;
      case CacheExtentStyle.viewport:
        _calculatedCacheExtent = mainAxisExtent * cacheExtent!;
        break;
    }

    final fullCacheExtent = mainAxisExtent + 2 * _calculatedCacheExtent!;
    final centerCacheOffset = centerOffset + _calculatedCacheExtent!;
    final reverseDirectionRemainingCacheExtent =
        centerCacheOffset.clamp(0.0, fullCacheExtent);
    final forwardDirectionRemainingCacheExtent =
        (fullCacheExtent - centerCacheOffset).clamp(0.0, fullCacheExtent);

    final leadingNegativeChild = childBefore(center!);

    if (leadingNegativeChild != null) {
      // negative scroll offsets
      final result = layoutChildSequence(
        child: leadingNegativeChild,
        scrollOffset: math.max(mainAxisExtent, centerOffset) - mainAxisExtent,
        overlap: 0,
        layoutOffset: forwardDirectionRemainingPaintExtent,
        remainingPaintExtent: reverseDirectionRemainingPaintExtent,
        mainAxisExtent: mainAxisExtent,
        crossAxisExtent: crossAxisExtent,
        growthDirection: GrowthDirection.reverse,
        advance: childBefore,
        remainingCacheExtent: reverseDirectionRemainingCacheExtent,
        cacheOrigin: (mainAxisExtent - centerOffset)
            .clamp(-_calculatedCacheExtent!, 0.0),
      );
      if (result != 0.0) return -result;
    }

    // positive scroll offsets
    return layoutChildSequence(
      child: center,
      scrollOffset: math.max(0, -centerOffset),
      overlap: leadingNegativeChild == null ? math.min(0, -centerOffset) : 0.0,
      layoutOffset: centerOffset >= mainAxisExtent
          ? centerOffset
          : reverseDirectionRemainingPaintExtent,
      remainingPaintExtent: forwardDirectionRemainingPaintExtent,
      mainAxisExtent: mainAxisExtent,
      crossAxisExtent: crossAxisExtent,
      growthDirection: GrowthDirection.forward,
      advance: childAfter,
      remainingCacheExtent: forwardDirectionRemainingCacheExtent,
      cacheOrigin: centerOffset.clamp(-_calculatedCacheExtent!, 0.0),
    );
  }

  @override
  bool get hasVisualOverflow => _hasVisualOverflow;

  @override
  void updateOutOfBandData(
      GrowthDirection growthDirection, SliverGeometry childLayoutGeometry) {
    switch (growthDirection) {
      case GrowthDirection.forward:
        _maxScrollExtent += childLayoutGeometry.scrollExtent;
        break;
      case GrowthDirection.reverse:
        _minScrollExtent -= childLayoutGeometry.scrollExtent;
        break;
    }
    if (childLayoutGeometry.hasVisualOverflow) _hasVisualOverflow = true;
  }

  @override
  void showOnScreen({
    RenderObject? descendant,
    Rect? rect,
    Duration duration = Duration.zero,
    Curve curve = Curves.ease,
  }) {
    if (parent is RenderObject) {
      (parent! as RenderObject).showOnScreen(
        descendant: descendant ?? this,
        rect: rect,
        duration: duration,
        curve: curve,
      );
    }
  }
}
