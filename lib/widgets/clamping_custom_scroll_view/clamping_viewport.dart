// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A render object that is bigger on the inside.
///
/// Version of [Viewport] with some modifications to how extents are
/// computed to allow scroll extents outside 0 to 1.  See [Viewport]
/// for more information.
class ClampingViewport extends Viewport {
  ClampingViewport({
    required super.offset,
    super.key,
    super.axisDirection,
    super.crossAxisDirection,
    double anchor = 0.0,
    super.center,
    super.cacheExtent,
    super.slivers,
  }) : _anchor = anchor;

  // [Viewport] enforces constraints on [Viewport.anchor], so we need our own
  // version.
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
      );
}

/// A render object that is bigger on the inside.
///
/// Version of [RenderViewport] with some modifications to how extents are
/// computed to allow scroll extents outside 0 to 1.  See [RenderViewport]
/// for more information.
///
// Differences from [RenderViewport] are marked with a //***** Differences
// comment.
class ClampingRenderViewport extends RenderViewport {
  /// Creates a viewport for [RenderSliver] objects.
  ClampingRenderViewport({
    required super.crossAxisDirection,
    required super.offset,
    super.axisDirection,
    double anchor = 0.0,
    super.children,
    super.center,
    super.cacheExtent,
  }) : _anchor = anchor;

  static const int _maxLayoutCycles = 10;

  double _anchor;

  // Out-of-band data computed during layout.
  late double _minScrollExtent;
  late double _maxScrollExtent;
  bool _hasVisualOverflow = false;

  /// This value is set during layout based on the [CacheExtentStyle].
  ///
  /// When the style is [CacheExtentStyle.viewport], it is the main axis extent
  /// of the viewport multiplied by the requested cache extent, which is still
  /// expressed in pixels.
  double? _calculatedCacheExtent;

  @override
  double get anchor => _anchor;

  @override
  set anchor(double value) {
    if (value == _anchor) return;
    _anchor = value;
    markNeedsLayout();
  }

  @override
  void performResize() {
    super.performResize();
    // TODO: Figure out why this override is needed as a result of
    // https://github.com/flutter/flutter/pull/61973 and see if it can be
    // removed somehow.
    switch (axis) {
      case Axis.vertical:
        offset.applyViewportDimension(size.height);
      case Axis.horizontal:
        offset.applyViewportDimension(size.width);
    }
  }

  @override
  Rect describeSemanticsClip(RenderSliver? child) {
    if (_calculatedCacheExtent == null) {
      return semanticBounds;
    }

    switch (axis) {
      case Axis.vertical:
        return Rect.fromLTRB(
          semanticBounds.left,
          semanticBounds.top - _calculatedCacheExtent!,
          semanticBounds.right,
          semanticBounds.bottom + _calculatedCacheExtent!,
        );
      case Axis.horizontal:
      // nothing.
    }
    return Rect.fromLTRB(
      semanticBounds.left - _calculatedCacheExtent!,
      semanticBounds.top,
      semanticBounds.right + _calculatedCacheExtent!,
      semanticBounds.bottom,
    );
  }

  double _correctedOffset = 0;
  bool _lastPositionIsBottom = false;
  num? _lastMaxScrollOffset;

  @override
  void performLayout() {
    if (center == null) {
      assert(firstChild == null);
      _minScrollExtent = 0.0;
      _maxScrollExtent = 0.0;
      _hasVisualOverflow = false;
      offset.applyContentDimensions(0, 0);
      return;
    }
    assert(center!.parent == this);

    late double mainAxisExtent;
    late double crossAxisExtent;
    switch (axis) {
      case Axis.vertical:
        mainAxisExtent = size.height;
        crossAxisExtent = size.width;
      case Axis.horizontal:
        mainAxisExtent = size.width;
        crossAxisExtent = size.height;
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
        // *** Difference from [RenderViewport].
        final top =
            _minScrollExtent + (mainAxisExtent * anchor) - _correctedOffset;
        final bottom = _maxScrollExtent -
            (mainAxisExtent * (1.0 - anchor)) -
            _correctedOffset;
        final maxScrollOffset = math.max(math.min(0, top), bottom);
        final minScrollOffset = math.min(top, maxScrollOffset);

        // *** If overscroll ***
        if (offset.pixels > maxScrollOffset) {
          offset.correctBy(maxScrollOffset - offset.pixels);
          count += 1;
          continue;
        }
        if (offset.pixels < minScrollOffset) {
          count += 1;
          offset.correctBy(minScrollOffset - offset.pixels);
          continue;
        }

        // *** If the center widget's position is not near the bottom ***
        if (bottom - offset.pixels < 0) {
          _correctedOffset += bottom;
          count += 1;
          continue;
        }

        // *** If max scroll offset changed, and the positions is bottom ***
        final maxScrollOffsetChanged = _lastMaxScrollOffset != null &&
            _lastMaxScrollOffset != maxScrollOffset;
        final positionIsBottom = offset.pixels == maxScrollOffset;
        final correction = maxScrollOffset - offset.pixels;
        try {
          if (maxScrollOffsetChanged &&
              _lastPositionIsBottom &&
              correction > 0) {
            offset.correctBy(correction);
            continue;
          }
        } finally {
          _lastPositionIsBottom = positionIsBottom;
          _lastMaxScrollOffset = maxScrollOffset;
        }

        if (offset.applyContentDimensions(
            minScrollOffset.toDouble(), maxScrollOffset.toDouble())) {
          break;
        }
        // *** End of difference from [RenderViewport].
      }
      count += 1;
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
            ' layout passes.');
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
      case CacheExtentStyle.viewport:
        _calculatedCacheExtent = mainAxisExtent * cacheExtent!;
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
      case GrowthDirection.reverse:
        _minScrollExtent -= childLayoutGeometry.scrollExtent;
    }
    if (childLayoutGeometry.hasVisualOverflow) _hasVisualOverflow = true;
  }
}
