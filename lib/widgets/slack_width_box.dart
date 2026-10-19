import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Lays out [child] [slack] wider than this box, at its start, and clips the
/// part that does not fit.
///
/// A panel beside a page animates its width. When the page gets the width
/// that is left, every frame lays out the page and all of its text again. With
/// [slack] set to the width the page is short of its widest width in the
/// animation, the page keeps one layout width for the whole animation, and the
/// panel only reveals or covers its edge.
class SlackWidthBox extends SingleChildRenderObjectWidget {
  const SlackWidthBox({required this.slack, super.key, super.child});

  final double slack;

  @override
  RenderSlackWidthBox createRenderObject(BuildContext context) =>
      RenderSlackWidthBox(slack: slack);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSlackWidthBox renderObject,
  ) => renderObject.slack = slack;
}

class RenderSlackWidthBox extends RenderProxyBox {
  RenderSlackWidthBox({required double slack}) : _slack = slack;

  double get slack => _slack;
  double _slack;
  set slack(double value) {
    if (value == _slack) return;
    _slack = value;
    markNeedsLayout();
  }

  final _clipLayer = LayerHandle<ClipRectLayer>();

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    final width = constraints.maxWidth + _slack;
    // The same constraints in every frame of an animation skip the child's
    // layout.
    child.layout(
      constraints.copyWith(minWidth: width, maxWidth: width),
      parentUsesSize: true,
    );
    size = constraints.constrain(
      Size(constraints.maxWidth, child.size.height),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    if (_slack <= 0) {
      _clipLayer.layer = null;
      super.paint(context, offset);
      return;
    }
    _clipLayer.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      super.paint,
      oldLayer: _clipLayer.layer,
    );
  }

  @override
  void dispose() {
    _clipLayer.layer = null;
    super.dispose();
  }
}
