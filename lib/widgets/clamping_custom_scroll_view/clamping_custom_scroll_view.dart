// Copyright 2019 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'clamping_viewport.dart';

/// A version of [CustomScrollView], which uses anchor without the blank
/// distance behavior like over scroll.
class ClampingCustomScrollView extends CustomScrollView {
  const ClampingCustomScrollView({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.center,
    double anchor = 0.0,
    super.cacheExtent,
    super.slivers,
    super.semanticChildCount,
    super.dragStartBehavior,
  }) : _anchor = anchor;

  // [CustomScrollView] enforces constraints on [CustomScrollView.anchor], so
  // we need our own version.
  final double _anchor;

  @override
  double get anchor => _anchor;

  /// Build the viewport.
  @override
  @protected
  Widget buildViewport(
    BuildContext context,
    ViewportOffset offset,
    AxisDirection axisDirection,
    List<Widget> slivers,
  ) {
    if (shrinkWrap) {
      return ShrinkWrappingViewport(
        axisDirection: axisDirection,
        offset: offset,
        slivers: slivers,
      );
    }
    return ClampingViewport(
      axisDirection: axisDirection,
      offset: offset,
      slivers: slivers,
      cacheExtent: cacheExtent,
      center: center,
      anchor: anchor,
    );
  }
}
