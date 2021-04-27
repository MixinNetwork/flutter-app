import 'dart:math';

import 'package:flutter/widgets.dart';

class SizePolicyRow extends StatelessWidget {
  const SizePolicyRow({
    Key? key,
    required this.children,
  }) : super(key: key);

  final List<SizePolicyData> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, boxConstraints) {
      final maxWidth = boxConstraints.maxWidth;
      final minWidth = children.fold<double>(
          0, (previousValue, element) => previousValue + element.minWidth);
      assert(maxWidth >= minWidth);
      var stretchWidth = maxWidth - minWidth;
      children.toList()
        ..sort((a, b) {
          if (b.sizePolicyOrder == null) return -1;
          if (a.sizePolicyOrder == null) return 0;
          return a.sizePolicyOrder!.compareTo(b.sizePolicyOrder!);
        })
        ..forEach((element) {
          if (element.maxWidth != null) {
            final widgetStretchWidth =
                min(stretchWidth, element.maxWidth! - element.minWidth);
            children.firstWhere((e) => identical(e, element))._width =
                (element.minWidth + widgetStretchWidth);
            stretchWidth -= widgetStretchWidth;
          }
        });

      return Row(
        children: children.map((e) {
          if (e._width != null)
            return SizedBox(
              width: e._width,
              child: e.child,
            );
          return Expanded(child: e.child);
        }).toList(),
      );
    });
  }
}

class SizePolicyData {
  SizePolicyData({
    required this.minWidth,
    this.maxWidth,
    this.sizePolicyOrder,
    required this.child,
  });

  final double minWidth;
  final double? maxWidth;
  final int? sizePolicyOrder;
  final Widget child;

  double? _width;
}
