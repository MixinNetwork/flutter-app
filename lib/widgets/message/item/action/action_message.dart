import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../../constants/resources.dart';
import '../../../../ui/provider/conversation_provider.dart';
import '../../../../utils/color_utils.dart';
import '../../../../utils/extension/extension.dart';
import '../../../../utils/logger.dart';
import '../../../../utils/uri_utils.dart';
import '../../../interactive_decorated_box.dart';
import '../../message.dart';
import '../../message_bubble.dart';
import '../../message_style.dart';
import '../unknown_message.dart';
import 'action_data.dart';

class ActionMessage extends HookConsumerWidget {
  const ActionMessage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actionDataList = useMessageConverter(converter: (state) {
      try {
        final list = jsonDecode(state.content!) as List<dynamic>;
        return list.map((e) => ActionData.fromJson(e as Map<String, dynamic>));
      } catch (error) {
        e('ActionData decode error: $error');
        return null;
      }
    });

    if (actionDataList == null) return const UnknownMessage();

    return MessageBubble(
      showBubble: false,
      padding: EdgeInsets.zero,
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: actionDataList
            .map(
              (e) => ActionMessageButton(action: e),
            )
            .toList(),
      ),
    );
  }
}

class ActionMessageButton extends ConsumerWidget {
  const ActionMessageButton({
    required this.action,
    super.key,
  });

  final ActionData action;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bubbleClipper = BubbleClipper(
      currentUser: false,
      showNip: false,
      nipPadding: false,
    );
    return InteractiveDecoratedBox.color(
      cursor: SystemMouseCursors.click,
      onTap: () {
        if (context.openAction(action.action)) return;
        openUriWithWebView(
          context,
          action.action,
          title: action.label,
          conversationId: ref.read(currentConversationIdProvider),
        );
      },
      child: CustomPaint(
        painter: BubblePainter(
          color: context.theme.primary,
          clipper: bubbleClipper,
        ),
        child: IntrinsicWidth(
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  action.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: context.messageStyle.secondaryFontSize,
                    color: colorHex(action.color) ?? Colors.black,
                    height: 1,
                  ),
                ),
              ),
              if (action.isExternalLink)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: SvgPicture.asset(
                      Resources.assetsImagesExternalLinkSvg,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ActionButtonLayout extends MultiChildRenderObjectWidget {
  const ActionButtonLayout({
    required super.children,
    this.verticalSpacing = 8,
    this.horizontalSpacing = 8,
    super.key,
  });

  final double horizontalSpacing;
  final double verticalSpacing;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderActionButtonLayout(
        horizontalSpacing: horizontalSpacing,
        verticalSpacing: verticalSpacing,
      );

  @override
  void updateRenderObject(
      BuildContext context, RenderActionButtonLayout renderObject) {
    renderObject
      ..horizontalSpacing = horizontalSpacing
      ..verticalSpacing = verticalSpacing;
  }
}

class _ParentData extends ContainerBoxParentData<RenderBox> {
  int _row = 0;
  double height = 0;
}

class RenderActionButtonLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ParentData> {
  RenderActionButtonLayout({
    required double horizontalSpacing,
    required double verticalSpacing,
  })  : _horizontalSpacing = horizontalSpacing,
        _verticalSpacing = verticalSpacing;

  double get horizontalSpacing => _horizontalSpacing;
  double _horizontalSpacing;

  set horizontalSpacing(double value) {
    if (_horizontalSpacing == value) {
      return;
    }
    _horizontalSpacing = value;
    markNeedsLayout();
  }

  double get verticalSpacing => _verticalSpacing;
  double _verticalSpacing;

  set verticalSpacing(double value) {
    if (_verticalSpacing == value) {
      return;
    }
    _verticalSpacing = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(covariant RenderObject child) {
    if (child.parentData is! _ParentData) {
      child.parentData = _ParentData();
    }
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    assert(constraints.hasBoundedWidth);

    var height = 0.0;
    final childWidths = [
      (constraints.maxWidth - horizontalSpacing * 2) / 3,
      (constraints.maxWidth - horizontalSpacing) / 2,
    ];

    var child = firstChild;
    var rowItems = 0;
    var maxRowHeight = 0.0;
    var row = 0;
    final childConstraints = BoxConstraints(
      maxWidth: constraints.maxWidth,
      maxHeight: constraints.maxHeight,
    );
    while (child != null) {
      final parentData = child.parentData! as _ParentData;

      final size = child.getDryLayout(childConstraints);
      maxRowHeight = math.max(size.height, maxRowHeight);

      parentData
        .._row = row
        ..height = maxRowHeight;

      if (size.width < childWidths[0] && rowItems < 3) {
        rowItems += 1;
      } else if (size.width < childWidths[1] && rowItems < 2) {
        rowItems += 2;
      } else {
        rowItems += 3;
      }
      if (rowItems >= 3) {
        rowItems = 0;
        height += maxRowHeight + verticalSpacing;
        maxRowHeight = 0;
        row += 1;
      }

      child = parentData.nextSibling;
    }

    if (maxRowHeight != 0) {
      height += maxRowHeight + verticalSpacing;
    }

    if (child != null) {
      height -= verticalSpacing;
    }
    return Size(constraints.maxWidth, height);
  }

  @override
  void performLayout() {
    assert(constraints.hasBoundedWidth);

    size = computeDryLayout(constraints);

    final rows = <int, List<RenderBox>>{};
    var child = firstChild;
    while (child != null) {
      final parentData = child.parentData! as _ParentData;
      if (rows[parentData._row] == null) {
        rows[parentData._row] = [];
      }
      rows[parentData._row]!.add(child);
      child = parentData.nextSibling;
    }

    var offsetY = 0.0;
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i]!;
      final childWidth =
          (constraints.maxWidth - (row.length - 1) * horizontalSpacing) /
              row.length;

      final rowHeight = row.fold<double>(0,
          (value, b) => math.max(value, (b.parentData! as _ParentData).height));
      final childConstraints =
          BoxConstraints.expand(width: childWidth, height: rowHeight);
      var offsetX = 0.0;
      for (final item in row) {
        item.layout(childConstraints);
        (item.parentData! as _ParentData).offset = Offset(offsetX, offsetY);
        offsetX += childWidth + horizontalSpacing;
      }
      offsetY += rowHeight + verticalSpacing;
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
