import 'dart:math' as math;
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../../db/mixin_database.dart' hide Offset;
import 'item/quote_message.dart';
import 'message.dart';
import 'message_bubble.dart';
import 'message_name.dart';

class MessageLayout extends MultiChildRenderObjectWidget {
  MessageLayout({
    Key? key,
    this.spacing = 6.0,
    this.clipBehavior = Clip.none,
    required Widget content,
    required Widget dateAndStatus,
  }) : super(key: key, children: [content, dateAndStatus]);

  final double spacing;
  final Clip clipBehavior;

  @override
  _RenderMessageLayout createRenderObject(BuildContext context) =>
      _RenderMessageLayout(
        spacing: spacing,
        clipBehavior: clipBehavior,
      );

  @override
  void updateRenderObject(
      BuildContext context, _RenderMessageLayout renderObject) {
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
    required double spacing,
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

  @override
  void performLayout() {
    final constraints = this.constraints;

    final widthLimit = constraints.maxWidth;

    final childConstraints = BoxConstraints(maxWidth: widthLimit);

    contentChild.layout(childConstraints, parentUsesSize: true);
    statusChild.layout(childConstraints, parentUsesSize: true);

    final lastLineHasSpace =
        _calculateRenderParagraphLastLineHasSpace(widthLimit) ||
            _calculateRenderEditableLastLineHasSpace(widthLimit);

    size = constraints.constrain(
      _calculateSize(
        widthLimit,
        contentChild.size,
        statusChild.size,
        lastLineHasSpace: lastLineHasSpace,
      ),
    );

    contentChild.multiChildLayoutParentData!.offset = Offset.zero;
    statusChild.multiChildLayoutParentData!.offset = Offset(
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

    final positionForOffset = renderParagraph.getPositionForOffset(Offset(
      statusX,
      contentChild.size.height,
    ));

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

enum DateAndStatusPosition {
  textOverflow,
  inside,
  outside,
}

class MessageBubbleWrapper extends StatelessWidget {
  const MessageBubbleWrapper({
    Key? key,
    this.spacing = 6.0,
    this.bubblePadding = const EdgeInsets.all(8),
    this.nipPadding = true,
    this.includeNip = false,
    this.showBubble = true,
    this.clip = false,
    required this.showNip,
    required this.dateAndStatusPosition,
    required this.isCurrentUser,
    required this.content,
    required this.dateAndStatus,
    required this.message,
  }) : super(key: key);

  final double spacing;
  final bool showNip;
  final bool nipPadding;
  final bool isCurrentUser;
  final DateAndStatusPosition dateAndStatusPosition;
  final EdgeInsets bubblePadding;
  final Widget content;
  final Widget dateAndStatus;
  final MessageItem message;
  final bool includeNip;
  final bool showBubble;
  final bool clip;

  @override
  Widget build(BuildContext context) => MessageBubbleLayout(
        color: showBubble
            ? context.messageBubbleColor(isCurrentUser)
            : Colors.transparent,
        spacing: spacing,
        clipBehavior: clip ? Clip.antiAlias : Clip.none,
        bubblePadding: bubblePadding,
        nipPadding: nipPadding,
        showNip: showNip,
        includeNip: includeNip,
        dateAndStatusPosition: dateAndStatusPosition,
        isCurrentUser: isCurrentUser,
        content: content,
        dateAndStatus: dateAndStatus,
        userName: MessageName(
          userName: context.read<MessageContextData>().userName,
          userId: context.read<MessageContextData>().userId,
        ),
        quoteMessage: QuoteMessage(
          messageId: message.messageId,
          quoteMessageId: message.quoteId,
          content: message.quoteContent,
        ),
      );
}

class MessageBubbleLayout extends MultiChildRenderObjectWidget {
  MessageBubbleLayout({
    Key? key,
    this.spacing = 6.0,
    this.clipBehavior = Clip.none,
    this.bubblePadding = const EdgeInsets.all(8),
    this.nipPadding = true,
    this.includeNip = false,
    required this.color,
    required this.showNip,
    required this.dateAndStatusPosition,
    required this.isCurrentUser,
    required Widget content,
    required Widget dateAndStatus,
    required Widget userName,
    required Widget quoteMessage,
  }) : super(key: key, children: [
          content,
          dateAndStatus,
          userName,
          quoteMessage,
        ]);

  final Color color;
  final double spacing;
  final Clip clipBehavior;
  final bool showNip;
  final bool nipPadding;
  final bool isCurrentUser;
  final DateAndStatusPosition dateAndStatusPosition;
  final EdgeInsets bubblePadding;
  final bool includeNip;

  @override
  _RenderMessageBubbleLayout createRenderObject(BuildContext context) =>
      _RenderMessageBubbleLayout(
        color: color,
        showNip: showNip,
        includeNip: includeNip,
        nipPadding: nipPadding,
        spacing: spacing,
        clipBehavior: clipBehavior,
        bubblePadding: bubblePadding,
        isCurrentUser: isCurrentUser,
        dateAndStatusPosition: dateAndStatusPosition,
      );

  @override
  void updateRenderObject(
      BuildContext context, _RenderMessageBubbleLayout renderObject) {
    renderObject
      ..color = color
      ..showNip = showNip
      ..includeNip = includeNip
      ..nipPadding = nipPadding
      ..bubblePadding = bubblePadding
      ..isCurrentUser = isCurrentUser
      ..dateAndStatusPosition = dateAndStatusPosition
      ..spacing = spacing
      ..clipBehavior = clipBehavior;
  }
}

class _RenderMessageBubbleLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, MultiChildLayoutParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, MultiChildLayoutParentData> {
  _RenderMessageBubbleLayout({
    List<RenderBox>? children,
    required bool nipPadding,
    required Color color,
    required bool showNip,
    required bool includeNip,
    required EdgeInsets bubblePadding,
    required double spacing,
    required bool isCurrentUser,
    required DateAndStatusPosition dateAndStatusPosition,
    Clip clipBehavior = Clip.none,
  })  : _bubbleClipper = BubbleClipper(
          currentUser: isCurrentUser,
          showNip: showNip,
          nipPadding: nipPadding,
        ),
        _paint = Paint()
          ..color = color
          ..style = PaintingStyle.fill,
        _bubblePadding = bubblePadding,
        _isCurrentUser = isCurrentUser,
        _includeNip = includeNip,
        _dateAndStatusPosition = dateAndStatusPosition,
        _spacing = spacing,
        _clipBehavior = clipBehavior {
    _update();
    addAll(children);
  }

  bool get includeNip => _includeNip;

  set includeNip(bool value) {
    if (_includeNip == value) return;
    _includeNip = value;
    markNeedsLayout();
  }

  bool _includeNip;

  Paint _paint;

  set color(Color color) {
    if (_paint.color == color) return;
    _paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    markNeedsPaint();
  }

  set nipPadding(bool value) {
    if (bubbleClipper.nipPadding == value) return;
    bubbleClipper = bubbleClipper.copyWith(
      nipPadding: value,
    );
  }

  set showNip(bool value) {
    if (bubbleClipper.showNip == value) return;
    bubbleClipper = bubbleClipper.copyWith(
      showNip: value,
    );
  }

  BubbleClipper get bubbleClipper => _bubbleClipper;

  set bubbleClipper(BubbleClipper value) {
    if (_bubbleClipper == value) return;
    _bubbleClipper = value;
    _update();
    markNeedsLayout();
  }

  BubbleClipper _bubbleClipper;

  EdgeInsets get bubblePadding => _bubblePadding;

  set bubblePadding(EdgeInsets value) {
    if (_bubblePadding == value) return;
    _bubblePadding = value;
    _update();
    markNeedsLayout();
  }

  EdgeInsets _bubblePadding;

  bool get isCurrentUser => _isCurrentUser;

  set isCurrentUser(bool value) {
    if (_isCurrentUser == value) return;
    _isCurrentUser = value;
    _update();
    markNeedsLayout();
  }

  bool _isCurrentUser;
  late EdgeInsets _nipPadding;
  late EdgeInsets _bubbleMargin;
  late EdgeInsets _padding;

  void _update() {
    _nipPadding = EdgeInsets.only(
      left: _isCurrentUser ? 0 : _bubbleClipper.nipWidth,
      right: _isCurrentUser ? _bubbleClipper.nipWidth : 0,
    );
    _bubbleMargin = EdgeInsets.only(
      left: _isCurrentUser ? 65 : 16,
      right: _isCurrentUser ? 16 : 65,
      top: 2,
      bottom: 2,
    );
    _padding = _nipPadding + bubblePadding + _bubbleMargin;
  }

  DateAndStatusPosition get dateAndStatusPosition => _dateAndStatusPosition;

  double get dateAndStatusMargin =>
      dateAndStatusPosition == DateAndStatusPosition.inside ? 4 : 0;

  set dateAndStatusPosition(DateAndStatusPosition value) {
    if (_dateAndStatusPosition == value) return;
    _dateAndStatusPosition = value;
    markNeedsLayout();
  }

  DateAndStatusPosition _dateAndStatusPosition;

  double get spacing => _spacing;

  set spacing(double value) {
    if (_spacing == value) return;
    _spacing = value;
    markNeedsLayout();
  }

  double _spacing;

  Clip get clipBehavior => _clipBehavior;

  set clipBehavior(Clip value) {
    if (value != _clipBehavior) {
      _clipBehavior = value;
      markNeedsPaint();
      markNeedsSemanticsUpdate();
    }
  }

  Clip _clipBehavior = Clip.none;

  RenderBox get contentChild => firstChild!;

  RenderBox get statusChild =>
      contentChild.multiChildLayoutParentData!.nextSibling!;

  RenderBox get userNameChild =>
      statusChild.multiChildLayoutParentData!.nextSibling!;

  RenderBox get quoteMessageChild =>
      userNameChild.multiChildLayoutParentData!.nextSibling!;

  Path? _clip;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! MultiChildLayoutParentData) {
      child.parentData = MultiChildLayoutParentData();
    }
  }

  Size _calculateSize(
    double widthLimit,
    Size contentSize,
    Size statusSize, {
    bool lastLineHasSpace = false,
  }) {
    if (dateAndStatusPosition == DateAndStatusPosition.textOverflow) {
      if (widthLimit.isInfinite) {
        return Size(
          contentSize.width + spacing + statusSize.width,
          contentSize.height + statusSize.height,
        );
      }
      if ((contentSize.width + spacing + statusSize.width) <= widthLimit) {
        return Size(
          contentSize.width + spacing + statusSize.width,
          contentSize.height,
        );
      }
      return Size(
        contentSize.width,
        contentSize.height + (lastLineHasSpace ? 0 : statusSize.height),
      );
    }

    return contentSize;
  }

  @override
  void performLayout() {
    final widthLimit = constraints.maxWidth - _padding.horizontal;

    final childConstraints = BoxConstraints(maxWidth: widthLimit);

    contentChild.layout(childConstraints, parentUsesSize: true);
    statusChild.layout(childConstraints, parentUsesSize: true);
    userNameChild.layout(childConstraints, parentUsesSize: true);
    quoteMessageChild.layout(childConstraints, parentUsesSize: true);

    final lastLineHasSpace =
        dateAndStatusPosition == DateAndStatusPosition.textOverflow &&
                _calculateRenderParagraphLastLineHasSpace(widthLimit) ||
            _calculateRenderEditableLastLineHasSpace(widthLimit);

    var contentSize = constraints.constrain(
      _calculateSize(
        widthLimit,
        contentChild.size,
        statusChild.size,
        lastLineHasSpace: lastLineHasSpace,
      ),
    );

    contentSize = Size(
      max(contentSize.width, quoteMessageChild.size.width),
      contentSize.height + quoteMessageChild.size.height,
    );

    if (includeNip) {
      contentSize = contentSize - Offset(bubbleClipper.nipWidth, 0) as Size;
    }

    // relayout for quote message background
    quoteMessageChild.layout(
      BoxConstraints.tightFor(
          // todo if (quoteMessageChild.size.width - contentChild.size.width) > _bubblePadding.horizontal
          width: contentSize.width + _bubblePadding.horizontal),
      parentUsesSize: true,
    );

    var _size = contentSize;

    final userNameHeight = userNameChild.size.height;
    final statusHeight = statusChild.size.height;
    final quoteMessageHeight = quoteMessageChild.size.height;

    if (userNameHeight > 0) {
      _size = _size + Offset(0, userNameHeight);
    }

    if (dateAndStatusPosition == DateAndStatusPosition.outside) {
      _size = _size + Offset(0, statusHeight);
    }

    size = Size(constraints.maxWidth, _padding.inflateSize(_size).height);

    double contextDx;

    final quoteMessageDy = userNameHeight + _bubbleMargin.top;
    final contentDy = quoteMessageDy + quoteMessageHeight + _bubblePadding.top;
    double statusDy;
    statusDy = size.height - statusHeight - _padding.bottom;

    if (dateAndStatusPosition == DateAndStatusPosition.outside) {
      statusDy = size.height - statusHeight;
    } else {
      statusDy =
          size.height - statusHeight - _padding.bottom - dateAndStatusMargin;
    }

    if (!isCurrentUser) {
      contextDx = _padding.left;
      if (includeNip) {
        contextDx = contextDx - bubbleClipper.nipWidth;
      }
      contentChild.multiChildLayoutParentData!.offset = Offset(
        contextDx,
        contentDy,
      );
      quoteMessageChild.multiChildLayoutParentData!.offset = Offset(
        contextDx - _bubblePadding.left,
        quoteMessageDy,
      );
      statusChild.multiChildLayoutParentData!.offset = Offset(
        _padding.left +
            contentSize.width -
            statusChild.size.width -
            dateAndStatusMargin,
        statusDy,
      );
      userNameChild.multiChildLayoutParentData!.offset = Offset(
        _bubbleMargin.left,
        0,
      );
    } else {
      contextDx = size.width - contentSize.width - _padding.right;
      contentChild.multiChildLayoutParentData!.offset = Offset(
        contextDx,
        contentDy,
      );
      quoteMessageChild.multiChildLayoutParentData!.offset = Offset(
        contextDx - _bubblePadding.right,
        quoteMessageDy,
      );
      statusChild.multiChildLayoutParentData!.offset = Offset(
        size.width -
            statusChild.size.width -
            _padding.right -
            dateAndStatusMargin,
        statusDy,
      );
    }

    // todo hard code nipWidth
    final bubbleSize =
        _bubblePadding.inflateSize(contentSize + const Offset(9.0, 0.0));
    _clip = bubbleClipper.getClip(bubbleSize);

    final bubbleDy = userNameHeight + _bubbleMargin.top;

    if (!isCurrentUser) {
      _clip = _clip?.shift(Offset(
        _bubbleMargin.left,
        bubbleDy,
      ));
    } else {
      _clip = _clip?.shift(Offset(
        size.width - bubbleSize.width - _bubbleMargin.right,
        bubbleDy,
      ));
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  bool get isRepaintBoundary => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_clip != null && _paint.color != Colors.transparent) {
      context.canvas.save();
      context.canvas.translate(offset.dx, offset.dy);
      context.canvas.drawPath(_clip!, _paint);
      context.canvas.restore();
    }

    if (_clip != null && clipBehavior != Clip.none) {
      _clipRectLayer = context.pushClipPath(
        needsCompositing,
        offset,
        Offset.zero & size,
        _clip!,
        contentPaint,
        clipBehavior: clipBehavior,
        oldLayer: _clipRectLayer,
      );
    } else {
      _clipRectLayer = null;
      contentPaint(context, offset);
    }
    defaultPaintWithoutContent(context, offset);
  }

  void contentPaint(PaintingContext context, Offset offset) =>
      context.paintChild(contentChild,
          contentChild.multiChildLayoutParentData!.offset + offset);

  void defaultPaintWithoutContent(PaintingContext context, Offset offset) {
    RenderBox? child = statusChild;
    while (child != null) {
      final childParentData = child.multiChildLayoutParentData!;
      context.paintChild(child, childParentData.offset + offset);
      child = childParentData.nextSibling;
    }
  }

  ClipPathLayer? _clipRectLayer;

  bool _calculateRenderParagraphLastLineHasSpace(double widthLimit) {
    final renderParagraph = contentChild.findRenderObject<RenderParagraph>();
    if (renderParagraph == null) return false;

    final statusX = widthLimit - statusChild.size.width - spacing;

    final positionForOffset = renderParagraph.getPositionForOffset(Offset(
      statusX,
      contentChild.size.height,
    ));

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

extension _FinderExtension on RenderObject {
  MultiChildLayoutParentData? get multiChildLayoutParentData =>
      parentData as MultiChildLayoutParentData?;

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
