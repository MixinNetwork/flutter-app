import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class ScrollerScrollController extends ScrollController {
  ScrollerScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
  });

  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics,
          ScrollContext context, ScrollPosition? oldPosition) =>
      _ScrollerScrollPosition(
        physics: physics,
        context: context,
        initialPixels: initialScrollOffset,
        keepScrollOffset: keepScrollOffset,
        oldPosition: oldPosition,
        debugLabel: debugLabel,
      );
}

class _ScrollerScrollPosition extends ScrollPositionWithSingleContext {
  _ScrollerScrollPosition({
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
  });

  @override
  void pointerScroll(double delta) {
    final double scrollerScale;
    if (defaultTargetPlatform == TargetPlatform.linux) {
      scrollerScale = window.devicePixelRatio;
    } else {
      scrollerScale = 1;
    }
    super.pointerScroll(delta * scrollerScale);
  }
}
