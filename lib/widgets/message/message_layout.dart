import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class MessageLayout extends MultiChildRenderObjectWidget {
  MessageLayout({
    super.key,
    this.spacing = 0.0,
    this.clipBehavior = Clip.none,
    required Widget content,
    required Widget dateAndStatus,
  }) : super(children: [content, dateAndStatus]);

  final double spacing;
  final Clip clipBehavior;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderMessageLayout(
        spacing: spacing,
        clipBehavior: clipBehavior,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    // ignore: library_private_types_in_public_api
    _RenderMessageLayout renderObject,
  ) {
    renderObject
      ..spacing = spacing
      ..clipBehavior = clipBehavior;
  }
}

class _RenderMessageLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {
  _RenderMessageLayout({
    List<RenderBox>? children,
    double spacing = 0.0,
    Clip clipBehavior = Clip.none,
  })  : _spacing = spacing,
        _clipBehavior = clipBehavior {
    addAll(children);
  }

  double get spacing => _spacing;
  double _spacing;

  set spacing(double value) {
    if (_spacing == value) return;
    _spacing = value;
    markNeedsLayout();
  }

  Clip get clipBehavior => _clipBehavior;
  Clip _clipBehavior = Clip.none;

  set clipBehavior(Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  RenderBox get contentChild => firstChild!;

  RenderBox get statusChild => lastChild!;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MultiChildLayoutParentData) {
      child.parentData = MultiChildLayoutParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    var width = math.max(childCount - 1, 0) * spacing;
    var child = firstChild;
    while (child != null) {
      width = math.max(width, child.getMinIntrinsicWidth(double.infinity));
      child = childAfter(child);
    }
    return width;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    var width = math.max(childCount - 1, 0) * spacing;
    var child = firstChild;
    while (child != null) {
      width += child.getMaxIntrinsicWidth(double.infinity);
      child = childAfter(child);
    }
    return width;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      computeDryLayout(BoxConstraints(maxWidth: width)).height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeDryLayout(BoxConstraints(maxWidth: width)).height;

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) =>
      defaultComputeDistanceToHighestActualBaseline(baseline);

  final bool _hasVisualOverflow = false;

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _computeDryLayout(constraints);

  Size _computeDryLayout(BoxConstraints constraints,
      [ChildLayouter layoutChild = ChildLayoutHelper.dryLayoutChild]) {
    final childConstraints = BoxConstraints(maxWidth: constraints.maxWidth);
    final widthLimit = constraints.maxWidth;

    final contentSize = layoutChild(contentChild, childConstraints);
    final statusSize = layoutChild(statusChild, childConstraints);

    final size = _calculateSize(widthLimit, contentSize, statusSize);

    return constraints.constrain(size);
  }

  Size _calculateSize(
    double widthLimit,
    Size contentSize,
    Size statusSize, {
    bool lastLineHasSpace = false,
  }) {
    if (widthLimit.isInfinite) {
      return Size(
        contentSize.width + spacing + statusSize.width,
        contentSize.height + statusSize.height,
      );
    } else if ((contentSize.width + spacing + statusSize.width) <= widthLimit) {
      return Size(
        contentSize.width + spacing + statusSize.width,
        contentSize.height,
      );
    } else {
      return Size(
        contentSize.width,
        contentSize.height + (lastLineHasSpace ? 0 : statusSize.height),
      );
    }
  }

  double _calculateWidth(
    double widthLimit,
    double contentWidth,
    double statusWidth,
  ) {
    if (widthLimit.isInfinite) {
      return contentWidth + spacing + statusWidth;
    } else if ((contentWidth + spacing + statusWidth) <= widthLimit) {
      return contentWidth + spacing + statusWidth;
    } else {
      return contentWidth;
    }
  }

  @override
  void performLayout() {
    final constraints = this.constraints;

    final widthLimit = constraints.maxWidth;

    final childConstraints = BoxConstraints(maxWidth: widthLimit);

    contentChild.layout(childConstraints, parentUsesSize: true);
    statusChild.layout(childConstraints, parentUsesSize: true);

    final boxWidth = _calculateWidth(
        widthLimit, contentChild.size.width, statusChild.size.width);
    final lastLineHasSpace =
        _calculateRenderParagraphLastLineHasSpace(boxWidth) ||
            _calculateRenderEditableLastLineHasSpace(boxWidth);

    size = constraints.constrain(
      _calculateSize(
        widthLimit,
        contentChild.size,
        statusChild.size,
        lastLineHasSpace: lastLineHasSpace,
      ),
    );

    (contentChild.parentData! as MultiChildLayoutParentData).offset =
        Offset.zero;
    (statusChild.parentData! as MultiChildLayoutParentData).offset = Offset(
      size.width - statusChild.size.width,
      size.height - statusChild.size.height,
    );
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_hasVisualOverflow && clipBehavior != Clip.none) {
      _clipRectLayer = context.pushClipRect(
        needsCompositing,
        offset,
        Offset.zero & size,
        defaultPaint,
        clipBehavior: clipBehavior,
        oldLayer: _clipRectLayer,
      );
    } else {
      _clipRectLayer = null;
      defaultPaint(context, offset);
    }
  }

  ClipRectLayer? _clipRectLayer;

  bool _calculateRenderParagraphLastLineHasSpace(double widthLimit) {
    final renderParagraph = contentChild.findRenderObject<RenderParagraph>();
    if (renderParagraph == null) return false;

    final statusX = widthLimit - statusChild.size.width - spacing;

    // Get the last text position.
    final positionForOffset = renderParagraph
        .getPositionForOffset(contentChild.paintBounds.bottomRight);

    final boxesForSelection =
        renderParagraph.getBoxesForSelection(TextSelection(
      baseOffset: positionForOffset.offset - 1,
      extentOffset: positionForOffset.offset,
    ));

    return boxesForSelection.isNotEmpty &&
        boxesForSelection.first.right.ceil() <= statusX;
  }

  bool _calculateRenderEditableLastLineHasSpace(double widthLimit) {
    final renderEditable = contentChild.findRenderObject<RenderEditable>();
    if (renderEditable == null) return false;

    final statusX = widthLimit - statusChild.size.width - spacing;

    final length =
        renderEditable.textSelectionDelegate.textEditingValue.text.length;

    final endpointsForSelection = renderEditable
        .getEndpointsForSelection(TextSelection.collapsed(offset: length));

    // RenderEditable._kCaretGap = 1;
    return endpointsForSelection.isNotEmpty &&
        endpointsForSelection.first.point.dx.ceil() +
                renderEditable.cursorWidth +
                1 <=
            statusX;
  }
}

extension _Finder on RenderObject {
  T? findRenderObject<T>() {
    if (this is T) return this as T?;
    if (this is! RenderObjectWithChildMixin<RenderBox>) return null;
    T? result;
    visitChildren((RenderObject child) {
      if (result != null) return;

      if (child is T) {
        result = child as T?;
        return;
      }

      final findRenderObject = child.findRenderObject<T>();
      if (findRenderObject != null) {
        result = findRenderObject;
        return;
      }
    });

    return result;
  }
}
