import 'package:flutter/material.dart';
import 'package:pin_input_text_field/pin_input_text_field.dart';

extension NumListExtension<T extends num> on Iterable<T> {
  /// Return the sum of the list even the list is empty.
  T sumList() {
    if (T == int) {
      var sum = 0;
      forEach((n) => sum += n as int);
      return sum as T;
    } else if (T == double) {
      var sum = 0.0;
      forEach((n) => sum += n);
      return sum as T;
    }
    throw AssertionError('not support type:${T.runtimeType}');
  }
}

@immutable
class CirclePinDecoration extends PinDecoration implements SupportGap {
  const CirclePinDecoration({
    this.gapSpace = 16,
    this.gapSpaces,
    required this.strokeColorBuilder,
    this.strokeWidth = 1,
  }) : super(
          baseBgColorBuilder: strokeColorBuilder,
        );

  /// The box border width.
  final double strokeWidth;

  /// The adjacent box gap.
  final double gapSpace;

  /// The gaps between every two adjacent box, higher priority than [gapSpace].
  final List<double>? gapSpaces;

  /// The box border color of index character.
  final ColorBuilder strokeColorBuilder;

  @override
  PinDecoration copyWith({
    TextStyle? textStyle,
    ObscureStyle? obscureStyle,
    String? errorText,
    TextStyle? errorTextStyle,
    String? hintText,
    TextStyle? hintTextStyle,
    ColorBuilder? bgColorBuilder,
  }) =>
      CirclePinDecoration(
        strokeColorBuilder: strokeColorBuilder,
        strokeWidth: strokeWidth,
        gapSpace: gapSpace,
        gapSpaces: gapSpaces,
      );

  @override
  PinEntryType get pinEntryType => PinEntryType.circle;

  @override
  void notifyChange(String? pin) {
    strokeColorBuilder.notifyChange(pin!);
  }

  @override
  void drawPin(
    Canvas canvas,
    Size size,
    String text,
    int pinLength,
    Cursor? cursor,
    TextDirection textDirection,
  ) {
    /// Calculate the height of paint area for drawing the pin field.
    /// it should honor the error text (if any) drawn by
    /// the actual texfield behind.
    /// but, since we can access the drawn textfield behind from here,
    /// we use a simple logic to calculate it.
    double mainHeight;
    if (errorText != null && errorText!.isNotEmpty) {
      mainHeight = size.height - (errorTextStyle?.fontSize ?? 0 + 8.0);
    } else {
      mainHeight = size.height;
    }

    final borderPaint = Paint()
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;

    final insidePaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final gapTotalLength = gapSpaces?.sumList() ?? (pinLength - 1) * gapSpace;

    /// Calculate the width of each digit include stroke.
    final singleWidth = (size.width - strokeWidth - gapTotalLength) / pinLength;

    double radius; // include strokeWidth
    List<double> actualGapSpaces;
    if (singleWidth / 2 < mainHeight / 2 - strokeWidth / 2) {
      radius = singleWidth / 2;
      actualGapSpaces =
          gapSpaces == null ? List.filled(pinLength - 1, gapSpace) : gapSpaces!;
    } else {
      radius = mainHeight / 2 - strokeWidth / 2;
      actualGapSpaces = List.filled(
          pinLength - 1,
          (size.width - strokeWidth - radius * 2 * pinLength) /
              (pinLength - 1));
    }

    var startX = strokeWidth / 2;
    final startY = mainHeight / 2;

    final centerPoints = List<double>.filled(pinLength, 0);

    /// Draw the each shape of pin.
    for (var i = 0; i < pinLength; i++) {
      borderPaint.color = strokeColorBuilder.indexProperty(i);
      insidePaint.color = borderPaint.color;

      centerPoints[i] = startX + radius;

      canvas.drawCircle(
        Offset(centerPoints[i], startY),
        radius,
        borderPaint,
      );

      if (i < text.runes.length) {
        canvas.drawCircle(
          Offset(startX + radius, startY),
          radius - strokeWidth / 2,
          insidePaint,
        );
      }
      startX += radius * 2 + (i == pinLength - 1 ? 0 : actualGapSpaces[i]);
    }
  }

  @override
  double get getGapWidth => gapSpace;

  @override
  List<double>? get getGapWidthList => gapSpaces;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      super == other &&
          other is CirclePinDecoration &&
          runtimeType == other.runtimeType &&
          strokeWidth == other.strokeWidth &&
          gapSpace == other.gapSpace &&
          gapSpaces == other.gapSpaces &&
          strokeColorBuilder == other.strokeColorBuilder;

  @override
  int get hashCode =>
      super.hashCode ^
      strokeWidth.hashCode ^
      gapSpace.hashCode ^
      gapSpaces.hashCode ^
      strokeColorBuilder.hashCode;

  @override
  String toString() =>
      'CirclePinDecoration{strokeWidth: $strokeWidth, gapSpace: $gapSpace, gapSpaces: $gapSpaces, strokeColorBuilder: $strokeColorBuilder}';
}
