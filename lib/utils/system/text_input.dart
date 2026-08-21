import 'dart:io';

import 'package:flutter/widgets.dart';

import '../emoji.dart';
import '../logger.dart';

// remove this once https://github.com/flutter/flutter/issues/111113 is fixed.
class TextInputActionHandler extends StatefulWidget {
  const TextInputActionHandler({required this.child, super.key});

  final Widget child;

  @override
  State<TextInputActionHandler> createState() => _TextInputActionHandlerState();
}

class _TextInputActionHandlerState extends State<TextInputActionHandler> {
  late final _actions = <Type, Action<Intent>>{
    DeleteCharacterIntent: makeAction(context),
    ExtendSelectionByCharacterIntent: makeAction(context),
    ExtendSelectionVerticallyToAdjacentLineIntent: makeAction(context),
    SelectAllTextIntent: makeAction(context),
    PasteTextIntent: makeAction(context),
    RedoTextIntent: makeAction(context),
    UndoTextIntent: makeAction(context),
  };

  @override
  Widget build(BuildContext context) {
    if (!Platform.isMacOS) {
      return widget.child;
    }
    return Actions(actions: _actions, child: widget.child);
  }
}

Action<Intent> makeAction(BuildContext context) => Action<Intent>.overridable(
  defaultAction: _CallbackContextAction(),
  context: context,
);

class _CallbackContextAction extends ContextAction<Intent> {
  _CallbackContextAction();

  bool? _consumeKey;

  @override
  bool consumesKey(Intent intent) {
    final consumeKey = _consumeKey;
    _consumeKey = null;
    if (consumeKey != null) {
      return consumeKey;
    }
    return callingAction?.consumesKey(intent) ?? true;
  }

  @override
  Object? invoke(Intent intent, [BuildContext? context]) {
    if (context == null) {
      e('No context provided to _CallbackContextAction');
      return callingAction?.invoke(intent);
    }
    final state = context.findAncestorStateOfType<EditableTextState>();
    if (state == null) {
      e('failed to find EditableTextState');
      return callingAction?.invoke(intent);
    }

    final composingRange = state.textEditingValue.composing;

    if (composingRange.isValid && !composingRange.isCollapsed) {
      _consumeKey = false;
      return null;
    }
    return callingAction?.invoke(intent);
  }
}

/// A [TextEditingController] that supports emojis.
class EmojiTextEditingController extends TextEditingController {
  EmojiTextEditingController({super.text});

  TextSpan _buildSpan({required String text, TextStyle? style}) {
    final children = <TextSpan>[];
    text.splitEmoji(
      onEmoji: (text) {
        children.add(
          TextSpan(
            text: text,
            style:
                style?.copyWith(fontFamily: kEmojiFontFamily) ??
                TextStyle(fontFamily: kEmojiFontFamily),
          ),
        );
      },
      onText: (text) {
        children.add(TextSpan(text: text, style: style));
      },
    );
    return TextSpan(children: children, style: style);
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    required bool withComposing,
    TextStyle? style,
  }) {
    assert(
      !value.composing.isValid || !withComposing || value.isComposingRangeValid,
    );
    // If the composing range is out of range for the current text, ignore it to
    // preserve the tree integrity, otherwise in release mode a RangeError will
    // be thrown and this EditableText will be built with a broken subtree.
    final composingRegionOutOfRange =
        !value.isComposingRangeValid || !withComposing;

    if (composingRegionOutOfRange) {
      return _buildSpan(text: value.text, style: style);
    }

    final composingStyle =
        style?.merge(const TextStyle(decoration: TextDecoration.underline)) ??
        const TextStyle(decoration: TextDecoration.underline);
    return TextSpan(
      style: style,
      children: <TextSpan>[
        _buildSpan(text: value.composing.textBefore(value.text)),
        _buildSpan(
          style: composingStyle,
          text: value.composing.textInside(value.text),
        ),
        _buildSpan(text: value.composing.textAfter(value.text)),
      ],
    );
  }
}
