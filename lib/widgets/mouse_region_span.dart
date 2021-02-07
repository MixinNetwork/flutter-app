import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class MouseRegionSpan extends WidgetSpan {
  MouseRegionSpan({
    @required MouseCursor mouseCursor,
    @required Widget child,
  }) : super(
    child: MouseRegion(
      cursor: mouseCursor,
      child: child,
    ),
  );
}
