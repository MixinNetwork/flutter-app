import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_ui/material_ui.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

/// A [PinInputController] over a caller-owned [textController] and
/// [focusNode]; disposing it leaves both of them alive.
PinInputController usePinInputController({
  required TextEditingController textController,
  FocusNode? focusNode,
}) {
  final controller = useMemoized(
    () => PinInputController(
      textController: textController,
      focusNode: focusNode,
    ),
    [textController, focusNode],
  );
  useEffect(() => controller.dispose, [controller]);
  return controller;
}

/// Pin cells drawn with borders only: no fill and no cursor.
MaterialPinTheme borderPinTheme({
  required Color borderColor,
  required Color focusedBorderColor,
  required Color filledBorderColor,
  required double borderWidth,
  required double spacing,
  MaterialPinShape shape = MaterialPinShape.underlined,
  Size cellSize = const Size(15, 50),
  TextStyle? textStyle,
}) => MaterialPinTheme(
  shape: shape,
  cellSize: cellSize,
  spacing: spacing,
  borderWidth: borderWidth,
  focusedBorderWidth: borderWidth,
  fillColor: Colors.transparent,
  focusedFillColor: Colors.transparent,
  filledFillColor: Colors.transparent,
  followingFillColor: Colors.transparent,
  completeFillColor: Colors.transparent,
  borderColor: borderColor,
  focusedBorderColor: focusedBorderColor,
  filledBorderColor: filledBorderColor,
  followingBorderColor: borderColor,
  completeBorderColor: filledBorderColor,
  textStyle: textStyle,
  showCursor: false,
  entryAnimation: MaterialPinAnimation.slide,
);
