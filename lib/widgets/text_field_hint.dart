import 'package:material_ui/material_ui.dart';

/// The placeholder of an empty [TextField], moved right so that the caret at
/// the start of the field does not cover the first glyph.
class TextFieldHint extends StatelessWidget {
  const TextFieldHint(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) => Padding(
    // RenderEditable paints the caret at offset 0 from x = 0 to x =
    // cursorWidth, and TextField's default cursorWidth is 2.
    padding: const EdgeInsetsDirectional.only(start: 2),
    child: Text(text, style: style, maxLines: maxLines, overflow: overflow),
  );
}
