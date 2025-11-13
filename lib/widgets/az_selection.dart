import 'dart:collection';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

typedef OnSelection = void Function(String char);

/// Custom render for vertical A_Z list.
class AZSelection extends SingleChildRenderObjectWidget {
  const AZSelection({super.key, this.onSelection, this.textStyle});

  final OnSelection? onSelection;
  final TextStyle? textStyle;

  @override
  RenderObject createRenderObject(BuildContext context) => AZRender()
    ..onSelection = onSelection
    ..textStyle = textStyle ?? Theme.of(context).textTheme.bodyLarge;

  @override
  void updateRenderObject(
    BuildContext context,
    covariant AZRender renderObject,
  ) {
    renderObject
      ..onSelection = onSelection
      ..textStyle = textStyle ?? Theme.of(context).textTheme.bodyLarge;
  }
}

class AZRender extends RenderBox {
  static final _chars = 'abcdefghijklmnopqrstuvwxyz'
      .toUpperCase()
      .characters
      .toList();

  final _offsets = HashMap<TextPainter, Offset>();

  OnSelection? onSelection;

  final double width = 20;
  TextStyle? _textStyle = const TextStyle();

  set textStyle(TextStyle? value) {
    _textStyle = value;
    markNeedsLayout();
  }

  TextStyle? get textStyle => _textStyle;

  @override
  void performLayout() {
    super.performLayout();
    assert(() {
      if (!hasSize) {
        throw FlutterError('RenderBox was not laid out: ${toString()}');
      }
      return true;
    }());
    final lineHeight = constraints.maxHeight / _chars.length;
    _offsets.clear();
    for (var i = 0; i < _chars.length; i++) {
      final item = _chars[i];

      final painter = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        text: TextSpan(text: item, style: _textStyle),
      )..layout(minWidth: width);
      _offsets[painter] = Offset(
        constraints.maxWidth - painter.width,
        lineHeight * i,
      );
    }
  }

  @override
  bool get sizedByParent => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    _offsets.forEach((painter, value) {
      painter.paint(context.canvas, value + offset);
    });
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      Size(width, constraints.maxHeight);

  @override
  void handleEvent(PointerEvent event, covariant BoxHitTestEntry entry) {
    super.handleEvent(event, entry);

    if (event.kind == PointerDeviceKind.mouse && !event.down) {
      return;
    }

    final position = event.localPosition;
    final index = ((position.dy / constraints.maxHeight) * _chars.length)
        .round()
        .clamp(0, _chars.length - 1);
    onSelection?.call(_chars[index]);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    super.hitTest(result, position: position);
    if (onSelection == null) {
      return false;
    }
    final rect = Rect.fromLTWH(
      constraints.maxWidth - width,
      0,
      width,
      constraints.maxHeight,
    );
    if (rect.contains(position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}
